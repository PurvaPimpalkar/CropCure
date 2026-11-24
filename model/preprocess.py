"""
CropCure - Image Preprocessing Utilities
Handles image loading, resizing, normalization for CNN inference.
"""

import numpy as np
from PIL import Image
import io

# Model expects 224x224 RGB images, pixel values normalized to [0, 1]
IMG_SIZE = (224, 224)


def preprocess_image_from_path(image_path: str) -> np.ndarray:
    """
    Load an image from disk, resize it, and normalize pixel values.

    Args:
        image_path: Path to the image file.

    Returns:
        numpy array of shape (1, 224, 224, 3) ready for model inference.
    """
    img = Image.open(image_path).convert("RGB")
    return _process_pil_image(img)


def preprocess_image_from_bytes(image_bytes: bytes) -> np.ndarray:
    """
    Load an image from raw bytes (e.g., an HTTP upload), resize and normalize.

    Args:
        image_bytes: Raw image bytes.

    Returns:
        numpy array of shape (1, 224, 224, 3) ready for model inference.
    """
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    return _process_pil_image(img)


def _process_pil_image(img: Image.Image) -> np.ndarray:
    """
    Internal helper: resize and normalize a PIL image.

    Args:
        img: PIL Image object.

    Returns:
        numpy array of shape (1, 224, 224, 3), float32, values in [0, 1].
    """
    img = img.resize(IMG_SIZE, Image.LANCZOS)
    arr = np.array(img, dtype=np.float32)
    arr = arr / 255.0                        # Normalize to [0, 1]
    arr = np.expand_dims(arr, axis=0)        # Add batch dimension → (1, 224, 224, 3)
    return arr


def load_image_for_display(image_path: str, size: tuple = (256, 256)) -> Image.Image:
    """
    Load and resize an image for display purposes (not for model inference).

    Args:
        image_path: Path to the image file.
        size: Desired output image size.

    Returns:
        PIL Image resized to requested dimensions.
    """
    img = Image.open(image_path).convert("RGB")
    return img.resize(size, Image.LANCZOS)
