import numpy as np
import tensorflow as tf
from PIL import Image

interpreter = tf.lite.Interpreter(model_path="assets/model/model_unquant.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Create a dummy image (green-ish)
img_array = np.full((224, 224, 3), [10, 200, 10], dtype=np.float32)

t1 = (img_array / 127.5) - 1.0
t1 = np.expand_dims(t1, axis=0)
interpreter.set_tensor(input_details[0]['index'], t1)
interpreter.invoke()
out1 = interpreter.get_tensor(output_details[0]['index'])[0]

t2 = img_array / 255.0
t2 = np.expand_dims(t2, axis=0)
interpreter.set_tensor(input_details[0]['index'], t2)
interpreter.invoke()
out2 = interpreter.get_tensor(output_details[0]['index'])[0]

print("Output 1 (/127.5 - 1.0): Max =", np.max(out1), "Sum =", np.sum(out1))
print("Output 2 (/255.0): Max =", np.max(out2), "Sum =", np.sum(out2))
