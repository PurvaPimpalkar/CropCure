import re

# Read the file
with open("d:/cropcure_final/backend/main.py", "r", encoding="utf-8") as f:
    text = f.read()

# Add imports correctly at the top, if not already there
import_str = "from pydantic import BaseModel"
new_import_str = """from pydantic import BaseModel

import utils
from database import register_user, authenticate_user, save_scan, get_user_history"""

if "from database import" not in text:
    text = text.replace("from pydantic import BaseModel\n\nimport utils", new_import_str)
    # the existing text is actually:
    # from pydantic import BaseModel
    # 
    # import utils
    # So handle potential whitespace:
    text = re.sub(r"from pydantic import BaseModel\n+import utils", new_import_str, text)


# Add models
old_endpoints_comment = "# ── Endpoints ──────────────────────────────────────────────────────────────────"
models_str = """class UserSignup(BaseModel):
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

# ── Endpoints ──────────────────────────────────────────────────────────────────"""

if "class ScanHistoryIn" not in text:
    text = text.replace(old_endpoints_comment, models_str)


# Add the endpoints
routes = """
@app.post("/signup", tags=["Auth"])
async def signup(user: UserSignup):
    result = register_user(user.name, user.email, user.password)
    if result is None:
        raise HTTPException(status_code=400, detail="User with this email already exists.")
    return {"message": "User created successfully", "user": result}

@app.post("/login", tags=["Auth"])
async def login(user: UserLogin):
    result = authenticate_user(user.email, user.password)
    if result is None:
        raise HTTPException(status_code=401, detail="Invalid email or password.")
    return {"message": "Login successful", "user": result}

@app.post("/history", tags=["History"])
async def add_history(scan: ScanHistoryIn):
    try:
        save_scan(scan.user_id, scan.crop, scan.disease, scan.confidence, scan.treatment_shown, scan.image_path)
        return {"message": "Scan saved successfully"}
    except Exception as e:
        logger.error("Failed to save scan history: %s", e)
        raise HTTPException(status_code=500, detail="Failed to save scan.")

@app.get("/history/{user_id}", tags=["History"])
async def get_history(user_id: int):
    try:
        history = get_user_history(user_id)
        return {"total": len(history), "history": history}
    except Exception as e:
        logger.error("Failed to load history: %s", e)
        raise HTTPException(status_code=500, detail="Failed to load scan history.")

if __name__ == "__main__":
"""

if "/history" not in text:
    text = text.replace("if __name__ == \"__main__\":", routes.strip() + "\n")

with open("d:/cropcure_final/backend/main.py", "w", encoding="utf-8") as f:
    f.write(text)
