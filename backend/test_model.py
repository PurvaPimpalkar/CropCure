import os, sys
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
sys.path.insert(0, '.')
import utils, numpy as np, io
from PIL import Image

# Force reload fresh model
utils._model = None

model = utils.load_model()
if model is None:
    print('ERROR: model is None')
    exit(1)
print('Model loaded successfully!')

def test_color(rgb, name):
    img = np.zeros((224, 224, 3), dtype='uint8')
    img[:, :, 0] = rgb[0]
    img[:, :, 1] = rgb[1]
    img[:, :, 2] = rgb[2]
    buf = io.BytesIO()
    Image.fromarray(img).save(buf, format='JPEG')
    r = utils.predict(buf.getvalue())
    top3 = [(t['crop'], t['confidence']) for t in r['top3']]
    print(f'  {name}: {r["crop"]} / {r["disease"]} ({r["confidence"]}%)  | top3: {top3}')

print('\nDiversity test (different colors should give different results):')
test_color([200, 50, 50], 'Red')
test_color([50, 180, 50], 'Green')
test_color([128, 128, 128], 'Gray')
test_color([220, 220, 100], 'Yellow')
test_color([50, 50, 200], 'Blue')
test_color([180, 120, 60], 'Brown')

print('\nDone')
