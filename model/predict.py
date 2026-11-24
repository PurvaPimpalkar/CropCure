"""
CropCure - Model Inference Script
Run prediction on a single image using the trained CropCure CNN model.

Usage:
    python predict.py --image path/to/leaf.jpg
    python predict.py --image path/to/leaf.jpg --model ./saved_model/cropcure_model.h5
"""

import os
import sys
import json
import argparse
import numpy as np

import tensorflow as tf
from preprocess import preprocess_image_from_path

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH   = os.path.join(SCRIPT_DIR, "saved_model", "cropcure_model.h5")
CLASSES_PATH = os.path.join(SCRIPT_DIR, "classes.json")


# ── Load Class Labels ─────────────────────────────────────────────────────────
def load_class_labels(classes_path: str) -> list:
    with open(classes_path, "r") as f:
        data = json.load(f)
    return data["classes"]


# ── Load Model ────────────────────────────────────────────────────────────────
_model_cache = None

def load_model(model_path: str = MODEL_PATH) -> tf.keras.Model:
    """Load and cache the trained Keras model."""
    global _model_cache
    if _model_cache is None:
        print(f"[INFO] Loading model from: {model_path}")
        _model_cache = tf.keras.models.load_model(model_path)
        print("[INFO] Model loaded successfully.")
    return _model_cache


# ── Prediction ────────────────────────────────────────────────────────────────
def predict_from_path(image_path: str, model_path: str = MODEL_PATH) -> dict:
    """
    Run inference on an image file.

    Args:
        image_path: Path to the crop leaf image.
        model_path: Path to the saved Keras model (.h5).

    Returns:
        dict with keys: crop, disease, healthy, confidence, class_id, label
    """
    model   = load_model(model_path)
    classes = load_class_labels(CLASSES_PATH)

    img_array = preprocess_image_from_path(image_path)
    predictions = model.predict(img_array, verbose=0)

    class_id   = int(np.argmax(predictions[0]))
    confidence = float(np.max(predictions[0]))
    class_info = classes[class_id]

    # Build top-3 predictions
    top3_indices = np.argsort(predictions[0])[::-1][:3]
    top3 = [
        {
            "class_id":   int(i),
            "label":      classes[i]["label"],
            "crop":       classes[i]["crop"],
            "disease":    classes[i]["disease"],
            "confidence": float(predictions[0][i]),
        }
        for i in top3_indices
    ]

    return {
        "class_id":   class_id,
        "label":      class_info["label"],
        "crop":       class_info["crop"],
        "disease":    class_info["disease"],
        "healthy":    class_info["healthy"],
        "confidence": round(confidence * 100, 2),
        "top3":       top3,
    }


def predict_from_bytes(image_bytes: bytes, model_path: str = MODEL_PATH) -> dict:
    """
    Run inference on raw image bytes (used by FastAPI backend).

    Args:
        image_bytes: Raw bytes of the uploaded image.
        model_path:  Path to the saved Keras model (.h5).

    Returns:
        dict with keys: crop, disease, healthy, confidence, class_id, label, top3
    """
    from preprocess import preprocess_image_from_bytes

    model   = load_model(model_path)
    classes = load_class_labels(CLASSES_PATH)

    img_array   = preprocess_image_from_bytes(image_bytes)
    predictions = model.predict(img_array, verbose=0)

    class_id   = int(np.argmax(predictions[0]))
    confidence = float(np.max(predictions[0]))
    class_info = classes[class_id]

    top3_indices = np.argsort(predictions[0])[::-1][:3]
    top3 = [
        {
            "class_id":   int(i),
            "label":      classes[i]["label"],
            "crop":       classes[i]["crop"],
            "disease":    classes[i]["disease"],
            "confidence": float(predictions[0][i]),
        }
        for i in top3_indices
    ]

    return {
        "class_id":   class_id,
        "label":      class_info["label"],
        "crop":       class_info["crop"],
        "disease":    class_info["disease"],
        "healthy":    class_info["healthy"],
        "confidence": round(confidence * 100, 2),
        "top3":       top3,
    }


# ── Main CLI ──────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="CropCure - Crop Disease Prediction")
    parser.add_argument("--image", type=str, required=True, help="Path to leaf image")
    parser.add_argument("--model", type=str, default=MODEL_PATH,  help="Path to model .h5 file")
    args = parser.parse_args()

    if not os.path.exists(args.image):
        print(f"[ERROR] Image file not found: {args.image}")
        sys.exit(1)
    if not os.path.exists(args.model):
        print(f"[ERROR] Model file not found: {args.model}")
        print("       → Run train.py first to generate the model, or download pretrained weights.")
        sys.exit(1)

    result = predict_from_path(args.image, args.model)
    print("\n" + "═" * 50)
    print("        CropCure - Prediction Result")
    print("═" * 50)
    print(f"  Crop      : {result['crop']}")
    print(f"  Disease   : {result['disease']}")
    print(f"  Status    : {'✅ Healthy' if result['healthy'] else '⚠️  Diseased'}")
    print(f"  Confidence: {result['confidence']}%")
    print("\n  Top-3 Predictions:")
    for i, p in enumerate(result["top3"], 1):
        pct = round(p["confidence"] * 100, 2)
        print(f"    {i}. {p['crop']} - {p['disease']}  ({pct}%)")
    print("═" * 50 + "\n")
