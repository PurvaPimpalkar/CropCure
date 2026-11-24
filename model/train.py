"""
CropCure - CNN Model Training Script
Uses MobileNetV2 transfer learning to classify 38 crop disease classes.

Dataset: PlantVillage (https://www.kaggle.com/datasets/emmarex/plantdisease)
         Organize as: dataset/train/<class_label>/*.jpg
                      dataset/val/<class_label>/*.jpg

Usage:
    python train.py --data_dir ./dataset --epochs 20 --batch_size 32
"""

import os
import argparse
import json
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, optimizers
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import (
    ModelCheckpoint, EarlyStopping, ReduceLROnPlateau, TensorBoard
)
import matplotlib.pyplot as plt

# ── Constants ────────────────────────────────────────────────────────────────
IMG_SIZE      = (224, 224)
NUM_CLASSES   = 38
SAVE_DIR      = "./saved_model"
MODEL_PATH    = os.path.join(SAVE_DIR, "cropcure_model.h5")
HISTORY_PATH  = os.path.join(SAVE_DIR, "training_history.json")


# ── Data Generators ──────────────────────────────────────────────────────────
def create_data_generators(data_dir: str, batch_size: int):
    """Create train and validation ImageDataGenerators with augmentation."""

    train_datagen = ImageDataGenerator(
        rescale=1.0 / 255,
        rotation_range=30,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        brightness_range=[0.8, 1.2],
        fill_mode="nearest",
    )

    val_datagen = ImageDataGenerator(rescale=1.0 / 255)

    train_gen = train_datagen.flow_from_directory(
        os.path.join(data_dir, "train"),
        target_size=IMG_SIZE,
        batch_size=batch_size,
        class_mode="categorical",
        shuffle=True,
    )

    val_gen = val_datagen.flow_from_directory(
        os.path.join(data_dir, "val"),
        target_size=IMG_SIZE,
        batch_size=batch_size,
        class_mode="categorical",
        shuffle=False,
    )

    return train_gen, val_gen


# ── Model Architecture ────────────────────────────────────────────────────────
def build_model(num_classes: int) -> tf.keras.Model:
    """
    Build a transfer-learning model using MobileNetV2 as the base encoder
    with a custom classification head for crop disease detection.
    """
    # Load MobileNetV2 pre-trained on ImageNet, exclude top layers
    base_model = MobileNetV2(
        input_shape=(*IMG_SIZE, 3),
        include_top=False,
        weights="imagenet",
    )

    # Phase 1: Freeze base model — only train the custom head
    base_model.trainable = False

    # Custom classification head
    inputs  = layers.Input(shape=(*IMG_SIZE, 3), name="input_layer")
    x       = base_model(inputs, training=False)
    x       = layers.GlobalAveragePooling2D(name="global_avg_pool")(x)
    x       = layers.BatchNormalization()(x)
    x       = layers.Dense(512, activation="relu", name="fc1")(x)
    x       = layers.Dropout(0.4, name="dropout1")(x)
    x       = layers.Dense(256, activation="relu", name="fc2")(x)
    x       = layers.Dropout(0.3, name="dropout2")(x)
    outputs = layers.Dense(num_classes, activation="softmax", name="predictions")(x)

    model = models.Model(inputs, outputs, name="CropCure_MobileNetV2")
    return model, base_model


# ── Training ──────────────────────────────────────────────────────────────────
def train(data_dir: str, epochs: int, batch_size: int, fine_tune_epochs: int = 10):
    """Train the CropCure model with two-phase training (frozen → fine-tuned)."""

    os.makedirs(SAVE_DIR, exist_ok=True)

    # Build generators
    train_gen, val_gen = create_data_generators(data_dir, batch_size)
    num_classes = train_gen.num_classes
    print(f"[INFO] Detected {num_classes} classes, {train_gen.samples} training samples")

    # Build model
    model, base_model = build_model(num_classes)
    model.summary()

    # ── Phase 1: Train only the classification head ──────────────────────────
    model.compile(
        optimizer=optimizers.Adam(learning_rate=1e-3),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )

    callbacks_phase1 = [
        ModelCheckpoint(MODEL_PATH, save_best_only=True, monitor="val_accuracy", verbose=1),
        EarlyStopping(patience=5, restore_best_weights=True, monitor="val_accuracy"),
        ReduceLROnPlateau(factor=0.5, patience=3, min_lr=1e-7, monitor="val_loss"),
        TensorBoard(log_dir=os.path.join(SAVE_DIR, "logs")),
    ]

    print("\n[PHASE 1] Training classification head (base model frozen)...")
    history1 = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=epochs,
        callbacks=callbacks_phase1,
    )

    # ── Phase 2: Fine-tune top layers of MobileNetV2 ────────────────────────
    print("\n[PHASE 2] Fine-tuning top 30 layers of MobileNetV2...")
    base_model.trainable = True

    # Freeze all but the last 30 layers
    for layer in base_model.layers[:-30]:
        layer.trainable = False

    model.compile(
        optimizer=optimizers.Adam(learning_rate=1e-5),  # Very low LR for fine-tuning
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )

    callbacks_phase2 = [
        ModelCheckpoint(MODEL_PATH, save_best_only=True, monitor="val_accuracy", verbose=1),
        EarlyStopping(patience=7, restore_best_weights=True, monitor="val_accuracy"),
        ReduceLROnPlateau(factor=0.5, patience=3, min_lr=1e-9, monitor="val_loss"),
    ]

    history2 = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=fine_tune_epochs,
        callbacks=callbacks_phase2,
    )

    # Save training history
    history_data = {
        "phase1": {
            "accuracy": history1.history.get("accuracy", []),
            "val_accuracy": history1.history.get("val_accuracy", []),
            "loss": history1.history.get("loss", []),
            "val_loss": history1.history.get("val_loss", []),
        },
        "phase2": {
            "accuracy": history2.history.get("accuracy", []),
            "val_accuracy": history2.history.get("val_accuracy", []),
            "loss": history2.history.get("loss", []),
            "val_loss": history2.history.get("val_loss", []),
        },
    }
    with open(HISTORY_PATH, "w") as f:
        json.dump(history_data, f, indent=2)

    print(f"\n[DONE] Model saved to: {MODEL_PATH}")
    _plot_training_history(history1, history2)


# ── Plotting ──────────────────────────────────────────────────────────────────
def _plot_training_history(history1, history2):
    """Plot combined accuracy and loss curves from both training phases."""
    acc    = history1.history["accuracy"]    + history2.history["accuracy"]
    val_acc= history1.history["val_accuracy"]+ history2.history["val_accuracy"]
    loss   = history1.history["loss"]        + history2.history["loss"]
    val_loss=history1.history["val_loss"]    + history2.history["val_loss"]

    epochs_range = range(len(acc))

    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    fig.suptitle("CropCure Training History", fontsize=14, fontweight="bold")

    axes[0].plot(epochs_range, acc,     label="Train Accuracy",   color="#2E7D32")
    axes[0].plot(epochs_range, val_acc, label="Val Accuracy",     color="#F9A825")
    axes[0].axvline(x=len(history1.history["accuracy"]) - 1,
                    color="gray", linestyle="--", label="Fine-tuning starts")
    axes[0].set_title("Accuracy")
    axes[0].legend()

    axes[1].plot(epochs_range, loss,     label="Train Loss",     color="#2E7D32")
    axes[1].plot(epochs_range, val_loss, label="Val Loss",       color="#F9A825")
    axes[1].axvline(x=len(history1.history["loss"]) - 1,
                    color="gray", linestyle="--", label="Fine-tuning starts")
    axes[1].set_title("Loss")
    axes[1].legend()

    plt.tight_layout()
    plot_path = os.path.join(SAVE_DIR, "training_history.png")
    plt.savefig(plot_path, dpi=150)
    print(f"[INFO] Training plot saved to: {plot_path}")
    plt.show()


# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train CropCure CNN model")
    parser.add_argument("--data_dir",         type=str, default="./dataset",
                        help="Root dataset directory (contains train/ and val/)")
    parser.add_argument("--epochs",           type=int, default=20,
                        help="Number of Phase-1 (head) training epochs")
    parser.add_argument("--batch_size",       type=int, default=32,
                        help="Batch size for training")
    parser.add_argument("--fine_tune_epochs", type=int, default=10,
                        help="Number of Phase-2 (fine-tuning) epochs")
    args = parser.parse_args()

    train(
        data_dir=args.data_dir,
        epochs=args.epochs,
        batch_size=args.batch_size,
        fine_tune_epochs=args.fine_tune_epochs,
    )
