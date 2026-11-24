"""
CropCure Backend - Utility Functions
Uses TensorFlow Lite (model_unquant.tflite) for inference.
Falls back to mock mode if model is unavailable.
"""

import os
import io
import json
import random
import logging
from typing import Optional

import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)

# ── Paths ─────────────────────────────────────────────────────────────────────
BACKEND_DIR  = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BACKEND_DIR)
# Model files live in mobile/assets/model/ (same files bundled into the Flutter app)
MODEL_DIR    = os.path.join(PROJECT_ROOT, "mobile", "assets", "model")

TFLITE_PATH         = os.path.join(MODEL_DIR, "model_unquant.tflite")
LABELS_PATH         = os.path.join(MODEL_DIR, "labels.txt")
TREATMENT_DATA_PATH = os.path.join(MODEL_DIR, "treatment_data.json")

# ── Image Settings ─────────────────────────────────────────────────────────────
IMG_SIZE = (224, 224)


def load_labels() -> list:
    """Load class labels from labels.txt."""
    if not os.path.exists(LABELS_PATH):
        logger.warning("labels.txt not found at %s", LABELS_PATH)
        return []

    with open(LABELS_PATH, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    raw_classes = []
    for line in lines:
        parts = line.split(" ", 1)
        idx   = int(parts[0]) if len(parts) == 2 else len(raw_classes)
        label = parts[1].strip() if len(parts) == 2 else line.strip()

        label_lower = label.lower()
        healthy = "health" in label_lower or "fresh" in label_lower

        # Special label parsing
        if label.startswith("Pepper_bell_"):
            crop    = "Pepper"
            disease = "Bell " + label.replace("Pepper_bell_", "").replace("_", " ").title()
        else:
            split_parts = label.split("_", 1)
            crop    = split_parts[0].title() if len(split_parts) > 1 else label
            disease = split_parts[1].replace("_", " ").title() if len(split_parts) > 1 else "Unknown"
            if healthy:
                disease = "Healthy"

        raw_classes.append({
            "id": idx, "label": label, "crop": crop,
            "disease": disease, "healthy": healthy
        })
    return raw_classes


_CLASSES_RAW   = load_labels()
NUM_CLASSES    = len(_CLASSES_RAW) if _CLASSES_RAW else 14
CLASS_LABELS   = [c["label"]   for c in _CLASSES_RAW]
CLASS_CROPS    = [c["crop"]    for c in _CLASSES_RAW]
CLASS_DISEASES = [c["disease"] for c in _CLASSES_RAW]
CLASS_HEALTHY  = [c["healthy"] for c in _CLASSES_RAW]

# ── Cached Resources ──────────────────────────────────────────────────────────
_interpreter    = None
_treatment_data = None


# =============================================================================
# Data Loading
# =============================================================================

def load_treatment_data() -> dict:
    """Load treatment database from treatment_data.json (cached)."""
    global _treatment_data
    if _treatment_data is None:
        try:
            with open(TREATMENT_DATA_PATH, "r") as f:
                _treatment_data = json.load(f)
        except FileNotFoundError:
            _treatment_data = {}
    return _treatment_data


def load_model():
    """
    Load TFLite model using tflite_runtime or tensorflow.lite.
    Returns the interpreter, or None if unavailable.
    """
    global _interpreter
    if _interpreter is not None:
        return _interpreter

    if not os.path.exists(TFLITE_PATH):
        logger.warning("⚠️  TFLite model not found at %s — MOCK MODE.", TFLITE_PATH)
        return None

    # Try tflite_runtime first (lighter), then fall back to tensorflow
    try:
        try:
            from tflite_runtime.interpreter import Interpreter
            logger.info("🔧 Using tflite_runtime")
        except ImportError:
            import tensorflow as tf
            Interpreter = tf.lite.Interpreter
            logger.info("🔧 Using tensorflow.lite")

        _interpreter = Interpreter(model_path=TFLITE_PATH)
        _interpreter.allocate_tensors()
        logger.info("✅ TFLite model ready! (%d classes)", NUM_CLASSES)
        return _interpreter

    except Exception as e:
        logger.error("❌ TFLite load failed: %s", e)
        logger.warning("⚠️  Falling back to MOCK MODE.")
        return None


# =============================================================================
# Image Preprocessing
# =============================================================================

def preprocess_image(image_bytes: bytes) -> np.ndarray:
    """
    Preprocess raw image bytes for Teachable Machine TFLite model.
    Resize to 224x224 RGB, normalize: (pixel - 127.5) / 127.5
    Returns ndarray of shape (1, 224, 224, 3).
    """
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((224, 224), Image.LANCZOS)
    image_array = np.asarray(img, dtype=np.float32)
    normalized  = (image_array - 127.5) / 127.5
    return np.expand_dims(normalized, axis=0)


# =============================================================================
# Prediction
# =============================================================================

def predict(image_bytes: bytes) -> dict:
    """Run prediction. Uses TFLite if loaded, else mock mode."""
    interpreter = load_model()
    return _real_predict(interpreter, image_bytes) if interpreter is not None else _mock_predict()


def _real_predict(interpreter, image_bytes: bytes) -> dict:
    """Run TFLite inference."""
    img_array = preprocess_image(image_bytes)  # (1, 224, 224, 3)

    input_details  = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()

    predictions = interpreter.get_tensor(output_details[0]['index'])[0]  # shape: (14,)

    class_id   = int(np.argmax(predictions))
    confidence = float(predictions[class_id])

    top3_indices = predictions.argsort()[::-1][:3]
    top3 = [
        {
            "class_id":   int(i),
            "label":      CLASS_LABELS[i],
            "crop":       CLASS_CROPS[i],
            "disease":    CLASS_DISEASES[i],
            "confidence": round(float(predictions[i]) * 100, 2),
        }
        for i in top3_indices
    ]

    return {
        "class_id":   class_id,
        "label":      CLASS_LABELS[class_id],
        "crop":       CLASS_CROPS[class_id],
        "disease":    CLASS_DISEASES[class_id],
        "healthy":    CLASS_HEALTHY[class_id],
        "confidence": round(confidence * 100, 2),
        "top3":       top3,
        "mock":       False,
    }


def _mock_predict() -> dict:
    """Realistic mock prediction when no model is available."""
    if not CLASS_LABELS:
        # Absolute fallback if labels.txt missing
        return {
            "class_id": 0, "label": "Tomato_Late_blight",
            "crop": "Tomato", "disease": "Late Blight",
            "healthy": False, "confidence": 85.0,
            "top3": [{"class_id": 0, "label": "Tomato_Late_blight", "crop": "Tomato", "disease": "Late Blight", "confidence": 85.0}],
            "mock": True,
        }
    diseased  = [i for i, h in enumerate(CLASS_HEALTHY) if not h]
    if not diseased:
        diseased = list(range(len(CLASS_LABELS)))
    class_id   = random.choice(diseased)
    confidence = round(random.uniform(72.0, 95.5), 2)

    others   = [i for i in range(NUM_CLASSES) if i != class_id]
    top3_ids = [class_id] + random.sample(others, min(2, len(others)))
    confs    = sorted([confidence, round(random.uniform(2.0, 12.0), 2),
                       round(random.uniform(0.5, 4.0),  2)],  reverse=True)

    top3 = [
        {
            "class_id":   top3_ids[i],
            "label":      CLASS_LABELS[top3_ids[i]],
            "crop":       CLASS_CROPS[top3_ids[i]],
            "disease":    CLASS_DISEASES[top3_ids[i]],
            "confidence": confs[i],
        }
        for i in range(len(top3_ids))
    ]

    return {
        "class_id":   class_id,
        "label":      CLASS_LABELS[class_id],
        "crop":       CLASS_CROPS[class_id],
        "disease":    CLASS_DISEASES[class_id],
        "healthy":    False,
        "confidence": confidence,
        "top3":       top3,
        "mock":       True,
    }


# =============================================================================
# Treatment Lookup
# =============================================================================

_HEALTHY_TREATMENT = {
    "description": "The crop appears healthy with no visible signs of disease.",
    "severity":    "None",
    "treatment":   "No treatment required. Continue regular monitoring and good agricultural practices.",
    "prevention":  "Maintain balanced fertilization, proper irrigation, and regular scouting.",
}


def get_treatment(label: str) -> dict:
    """
    Return treatment info for a predicted label.
    Checks treatment_data.json first, then a generic response.
    """
    # Healthy crops
    try:
        idx = CLASS_LABELS.index(label)
        if CLASS_HEALTHY[idx]:
            return _format_treatment(_HEALTHY_TREATMENT, label, healthy=True)
    except (ValueError, IndexError):
        pass

    # Try treatment_data.json
    td = load_treatment_data()
    if label in td:
        return _format_treatment(td[label], label)

    # Case-insensitive search
    label_lower = label.lower()
    for key, val in td.items():
        if key.lower() == label_lower:
            return _format_treatment(val, label)

    # Generic fallback — never raises, never returns 500
    return {
        "description":        "No specific treatment data available for this disease.",
        "severity":           "Unknown",
        "medicines":          [{"name": "Consult local agricultural extension office", "type": "Advisory"}],
        "dosage":             "Follow professional advice.",
        "application_method": "Seek guidance from a certified agronomist.",
        "precautions":        ["Monitor the crop closely", "Isolate affected plants"],
        "cultural_practices": "Practice good agricultural hygiene and crop rotation.",
    }


def _format_treatment(entry: dict, label: str, healthy: bool = False) -> dict:
    """Normalise a treatment entry into the format expected by the Flutter app."""
    treatment_text  = entry.get("treatment", entry.get("advice", ""))
    prevention_text = entry.get("prevention", "")
    description     = entry.get("description", entry.get("symptoms", ""))

    return {
        "description":        description,
        "severity":           "None" if healthy else entry.get("severity", "Moderate"),
        "medicines":          _parse_medicines(treatment_text),
        "dosage":             treatment_text or "No treatment required.",
        "application_method": treatment_text,
        "precautions":        [prevention_text] if prevention_text else [],
        "cultural_practices": entry.get("advice", prevention_text),
        # ── New enriched fields ──────────────────────────────────────────────
        "immediate_action":    entry.get("immediate_action",    ""),
        "chemical_treatment":  entry.get("chemical_treatment",  ""),
        "organic_alternative": entry.get("organic_alternative", ""),
        "farmer_tips":         entry.get("farmer_tips",         ""),
    }


def _parse_medicines(treatment_text: str) -> list:
    """Extract medicine names from a treatment text string."""
    import re
    if not treatment_text or "no treatment" in treatment_text.lower():
        return []
    parts = re.split(r",|;|\bor\b|\band\b", treatment_text, flags=re.IGNORECASE)
    medicines = []
    for part in parts:
        clean = part.strip()
        if len(clean) > 3 and not clean.lower().startswith(
                ("apply", "spray", "remove", "use", "avoid", "plant", "prune",
                 "water", "ensure", "follow", "practice", "consult")):
            medicines.append({"name": clean, "type": "Recommended Treatment"})
        elif len(clean) > 3:
            match = re.search(r'(?:apply|spray|use)\s+(.+)', clean, re.IGNORECASE)
            if match:
                medicines.append({"name": match.group(1).strip(), "type": "Recommended Treatment"})
    return medicines if medicines else [{"name": treatment_text, "type": "Recommended Treatment"}]


# =============================================================================
# Disease Catalogue (for /diseases endpoint)
# =============================================================================

def get_all_classes() -> list:
    """Return all supported class entries for the /diseases endpoint."""
    td = load_treatment_data()
    result = []
    for cls in _CLASSES_RAW:
        label     = cls["label"]
        entry     = td.get(label, {})
        result.append({
            "class_id":    cls["id"],
            "label":       label,
            "crop":        cls["crop"],
            "disease":     cls["disease"],
            "healthy":     cls["healthy"],
            "severity":    "None" if cls["healthy"] else entry.get("severity", "Moderate"),
            "description": entry.get("symptoms", entry.get("description", "")),
        })
    return result
