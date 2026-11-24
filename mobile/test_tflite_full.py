import numpy as np
import tensorflow as tf

interpreter = tf.lite.Interpreter(model_path="assets/model/model_unquant.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()

print("Dtype:", input_details[0]['dtype'])
print("Shape:", input_details[0]['shape'])
