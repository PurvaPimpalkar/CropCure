"""
CropCure - FastAPI Backend Server
Provides REST API endpoints for crop disease detection and treatment recommendations.

Endpoints:
    GET  /health          → Server health check
    POST /predict         → Upload leaf image → disease prediction + treatment
    GET  /diseases        → Full disease catalogue
    GET  /diseases/{label} → Single disease detail

Start with:
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""

import os
import logging
from typing import Optional
import datetime
import jwt

from fastapi import FastAPI, File, UploadFile, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

import utils
from database import register_user, authenticate_user, save_scan, get_user_history
from blog_router import router as blog_router, media_router

SECRET_KEY = "cropcure_super_secret_key"
ALGORITHM = "HS256"
security = HTTPBearer()

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.datetime.utcnow() + datetime.timedelta(days=7)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


# ── Logging Setup ─────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)

# ── FastAPI Application ───────────────────────────────────────────────────────
app = FastAPI(
    title="CropCure API",
    description=(
        "AI-powered crop disease detection API. "
        "Upload a crop leaf image to identify the disease and receive a treatment plan."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS Middleware (allows Flutter app to call from any origin) ──────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # In production, restrict to your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Blog Module Routers ───────────────────────────────────────────────────────
app.include_router(blog_router)
app.include_router(media_router)

# ── Pre-load Resources at Startup ─────────────────────────────────────────────
@app.on_event("startup")
async def startup_event():
    """Pre-load model, class labels, and disease database on server start."""
    logger.info("🌱 CropCure API starting up...")
    utils.load_treatment_data()
    model = utils.load_model()
    if model is None:
        logger.warning("🔶 Running in MOCK MODE — predictions will be simulated.")
    else:
        logger.info("✅ Model ready for inference.")
    logger.info("🚀 CropCure API is ready!")


# ── Response Models ───────────────────────────────────────────────────────────
class UserSignup(BaseModel):
    name: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class ScanHistoryIn(BaseModel):
    user_id: int
    crop: str
    disease: str
    confidence: float
    treatment_shown: str
    image_path: str = ""

class HealthResponse(BaseModel):
    status: str
    version: str
    model_loaded: bool
    mock_mode: bool


class Top3Prediction(BaseModel):
    class_id: int
    crop: str
    disease: str
    confidence: float


class MedicineInfo(BaseModel):
    name: str
    type: str


class TreatmentInfo(BaseModel):
    description: str
    severity: str
    medicines: list
    dosage: str
    application_method: str
    precautions: list
    cultural_practices: str


class PredictionResponse(BaseModel):
    class_id: int
    label: str
    crop: str
    disease: str
    healthy: bool
    confidence: float
    top3: list
    mock: bool
    treatment: dict


class DiseaseListItem(BaseModel):
    label: str
    crop: str
    disease: str
    healthy: bool
    class_id: int


# ── Endpoints ──────────────────────────────────────────────────────────────────

@app.get("/health", response_model=HealthResponse, tags=["System"])
async def health_check():
    """
    Server health check.
    Returns server status, version, and whether the AI model is loaded.
    """
    model_loaded = utils._model is not None
    return {
        "status":       "ok",
        "version":      "1.0.0",
        "model_loaded": model_loaded,
        "mock_mode":    not model_loaded,
    }


@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
async def predict_disease(file: UploadFile = File(...), token_payload: dict = Depends(verify_token)):
    """
    Analyze a crop leaf image and detect the disease.

    Upload a JPEG/PNG image of a crop leaf. The AI model will:
    1. Identify the crop type
    2. Detect the disease (or confirm healthy)
    3. Return a confidence score + detailed treatment plan

    **Supported crops:** Apple, Blueberry, Cherry, Corn, Grape, Orange,
    Peach, Bell Pepper, Potato, Raspberry, Soybean, Squash, Strawberry, Tomato

    Returns a prediction with treatment recommendations.
    """
    # Read image bytes first (needed for magic byte detection)
    try:
        image_bytes = await file.read()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to read uploaded file: {e}")

    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    if len(image_bytes) > 10 * 1024 * 1024:  # 10MB limit
        raise HTTPException(
            status_code=413,
            detail="Image file too large. Maximum size is 10MB."
        )

    # Validate using magic bytes (first few bytes of the file).
    # We do NOT rely on file.content_type because Flutter web / browsers may
    # send 'application/octet-stream' even for valid JPEG/PNG files.
    def _is_valid_image(data: bytes) -> bool:
        if data[:3] == b'\xff\xd8\xff':                    # JPEG
            return True
        if data[:8] == b'\x89PNG\r\n\x1a\n':              # PNG
            return True
        if data[:4] in (b'RIFF', ) and data[8:12] == b'WEBP':  # WebP
            return True
        if data[:6] in (b'GIF87a', b'GIF89a'):            # GIF
            return True
        return False

    if not _is_valid_image(image_bytes):
        # Fall back to MIME type check for edge cases
        allowed_types = {"image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"}
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Unsupported file format. Please upload a JPEG or PNG image. "
                    f"(Detected content-type: '{file.content_type}')"
                ),
            )

    # Run prediction
    try:
        result = utils.predict(image_bytes)
    except Exception as e:
        logger.error("Prediction failed: %s", e)
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

    # Get treatment plan
    try:
        treatment = utils.get_treatment(result["label"])
    except Exception as e:
        logger.error("Treatment lookup failed: %s", e)
        treatment = {"error": "Treatment information unavailable."}

    response = {**result, "treatment": treatment}
    logger.info(
        "Predicted: %s - %s (%.1f%%) | Mock: %s",
        result["crop"], result["disease"], result["confidence"], result["mock"]
    )
    return response


@app.get("/diseases", tags=["Diseases"])
async def get_all_diseases():
    """
    Get the full catalogue of supported crops and diseases.
    Returns all 9 crop-disease combinations the model can detect.
    """
    classes = utils.get_all_classes()
    return {"total": len(classes), "diseases": classes}


@app.get("/diseases/{label}", tags=["Diseases"])
async def get_disease_detail(label: str):
    """
    Get full details for a specific disease by its label.
    Example label: `Tomato_Early_blight`
    """
    label = label.replace("%20", " ").replace("-", "_")
    classes = utils.get_all_classes()
    class_info = next((c for c in classes if c["label"] == label), None)
    if class_info is None:
        raise HTTPException(
            status_code=404,
            detail=f"Disease '{label}' not found. Check /diseases for valid labels."
        )
    treatment = utils.get_treatment(label)
    return {**class_info, "treatment": treatment}


@app.get("/crops", tags=["Diseases"])
async def get_supported_crops():
    """Get the list of distinct crops supported by the system."""
    classes = utils.get_all_classes()
    crops   = sorted(set(c["crop"] for c in classes))
    return {"total": len(crops), "crops": crops}


@app.post("/signup", tags=["Auth"])
async def signup(user: UserSignup):
    result = register_user(user.name, user.email, user.password)
    if result is None:
        raise HTTPException(status_code=400, detail="User with this email already exists.")
    token = create_access_token({"sub": str(result["id"])})
    return {"message": "User created successfully", "user": result, "token": token}

@app.post("/login", tags=["Auth"])
async def login(user: UserLogin):
    result = authenticate_user(user.email, user.password)
    if result is None:
        raise HTTPException(status_code=401, detail="Invalid email or password.")
    token = create_access_token({"sub": str(result["id"])})
    return {"message": "Login successful", "user": result, "token": token}

@app.post("/history", tags=["History"])
async def add_history(scan: ScanHistoryIn, token_payload: dict = Depends(verify_token)):
    try:
        save_scan(scan.user_id, scan.crop, scan.disease, scan.confidence, scan.treatment_shown, scan.image_path)
        return {"message": "Scan saved successfully"}
    except Exception as e:
        logger.error("Failed to save scan history: %s", e)
        raise HTTPException(status_code=500, detail="Failed to save scan.")

@app.get("/history/{user_id}", tags=["History"])
async def get_history(user_id: int, token_payload: dict = Depends(verify_token)):
    try:
        history = get_user_history(user_id)
        return {"total": len(history), "history": history}
    except Exception as e:
        logger.error("Failed to load history: %s", e)
        raise HTTPException(status_code=500, detail="Failed to load scan history.")

# ── Run directly ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
