"""
Test with realistic texture images (gradients, spots, etc.)
that better simulate real leaf photo features.
"""
import os, sys
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
sys.path.insert(0, '.')
import utils, numpy as np, io
from PIL import Image

utils._model = None
model = utils.load_model()
if model is None:
    print('ERROR: model None')
    exit(1)
print('Model loaded!')

def predict_img(arr, name):
    buf = io.BytesIO()
    Image.fromarray(arr.astype('uint8')).save(buf, format='JPEG')
    r = utils.predict(buf.getvalue())
    t3 = ', '.join([f'{t["crop"]}:{t["confidence"]}%' for t in r['top3'][:3]])
    print(f'  {name}: {r["crop"]} / {r["disease"]} ({r["confidence"]}%)')
    print(f'    top3: {t3}')

x, y = np.meshgrid(np.arange(224), np.arange(224))

# Spotted leaf (simulate disease spots)
spotted = np.zeros((224,224,3))
spotted[:,:,1] = 120  # green base
spots = ((x-80)**2 + (y-80)**2 < 400) | ((x-150)**2 + (y-140)**2 < 600)
spotted[spots, 0] = 180; spotted[spots, 1] = 90; spotted[spots, 2] = 30
predict_img(spotted, 'Spotted leaf (simulated disease)')

# Rusty leaf (brown-orange tones)
rusty = np.zeros((224,224,3))
rusty[:,:,0] = x * 0.6 + 80
rusty[:,:,1] = y * 0.3 + 50
rusty[:,:,2] = 30
predict_img(rusty, 'Rusty leaf pattern')

# White powdery texture
powdery = np.zeros((224,224,3))
powdery[:,:,1] = 90
powdery[::4,::4,:] = 220
predict_img(powdery, 'Powdery texture (mildew sim)')

# Yellow leaf (chlorosis)
yellow = np.zeros((224,224,3))
yellow[:,:,0] = 200; yellow[:,:,1] = 190; yellow[:,:,2] = 50
predict_img(yellow, 'Yellow leaf (chlorosis)')

# Dark brown lesion
dark = np.zeros((224,224,3))
dark[:,:,1] = 60
circle = (x-112)**2 + (y-112)**2 < 2000
dark[circle, 0] = 100; dark[circle, 1] = 40; dark[circle, 2] = 10
predict_img(dark, 'Dark lesion on leaf')

# Gradient across colors (simulates complex scene)
grad = np.zeros((224,224,3))
grad[:,:,0] = x * 0.8
grad[:,:,1] = (224-y) * 0.5 + 40
grad[:,:,2] = y * 0.4
predict_img(grad, 'Color gradient (complex)')

print('\nDone')
