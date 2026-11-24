"""
Deep diagnostic: check if MobileNetV2 weights are actually changing
by comparing initial random weights against loaded weights
"""
import os, sys, h5py
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
sys.path.insert(0, '.')
import tensorflow as tf
from tensorflow.keras import layers, Sequential
from tensorflow.keras.applications import MobileNetV2
import numpy as np

NUM_CLASSES = 27

# Build model
base = MobileNetV2(input_shape=(224,224,3), include_top=False, weights=None)
model = Sequential([
    base,
    layers.GlobalAveragePooling2D(),
    layers.BatchNormalization(),
    layers.Dense(256, activation='relu'),
    layers.Dense(NUM_CLASSES, activation='softmax'),
])
model.build((None, 224, 224, 3))

# Save a few initial (random) weights for comparison
conv1_before = base.get_layer('Conv1').get_weights()[0].copy()
bn1_before   = base.get_layer('bn_Conv1').get_weights()  # [gamma, beta, mean, var]

print("BEFORE loading (first 3 values of Conv1 kernel):", conv1_before.flatten()[:3])
print("BEFORE BN gamma (first 3):", bn1_before[0][:3])
print("BEFORE BN beta (first 3):", bn1_before[1][:3])

# Load weights from H5 using name-matching
with h5py.File('../model/cropcure_model.h5', 'r') as h5:
    def load_layer_by_name(sublayer, h5_group_path):
        if h5_group_path not in h5:
            return False
        grp = h5[h5_group_path]
        if not sublayer.weights:
            return True
        ordered_values = []
        for keras_var in sublayer.weights:
            short_name = keras_var.name.split('/')[-1].rstrip(':0')
            if short_name not in grp:
                print(f"  MISSING: {h5_group_path}/{short_name} (looking for {keras_var.name})")
                return False
            ordered_values.append(np.array(grp[short_name]))
        sublayer.set_weights(ordered_values)
        return True

    # Load Conv1
    ok = load_layer_by_name(base.get_layer('Conv1'), 'model_weights/mobilenetv2_1.00_224/Conv1')
    print(f"\nConv1 load returned: {ok}")
    
    # Load bn_Conv1
    ok2 = load_layer_by_name(base.get_layer('bn_Conv1'), 'model_weights/mobilenetv2_1.00_224/bn_Conv1')
    print(f"bn_Conv1 load returned: {ok2}")
    
    # Also check what h5 has for bn_Conv1
    grp = h5['model_weights/mobilenetv2_1.00_224/bn_Conv1']
    print(f"H5 bn_Conv1 keys: {list(grp.keys())}")
    print(f"H5 gamma values (first 3): {np.array(grp['gamma'])[:3]}")
    print(f"H5 beta values (first 3): {np.array(grp['beta'])[:3]}")
    
    # Check keras var names for bn_Conv1
    bn_layer = base.get_layer('bn_Conv1')
    print(f"Keras bn_Conv1 var names: {[w.name for w in bn_layer.weights]}")

conv1_after = base.get_layer('Conv1').get_weights()[0].copy()
bn1_after   = base.get_layer('bn_Conv1').get_weights()

print("\nAFTER loading (first 3 values of Conv1 kernel):", conv1_after.flatten()[:3])
print("AFTER BN gamma (first 3):", bn1_after[0][:3])
print("AFTER BN beta (first 3):", bn1_after[1][:3])

print("\nWeights changed?")
print(f"  Conv1: {not np.allclose(conv1_before, conv1_after)}")
print(f"  BN gamma: {not np.allclose(bn1_before[0], bn1_after[0])}")
print(f"  BN beta: {not np.allclose(bn1_before[1], bn1_after[1])}")
