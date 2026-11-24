import os, sys, io
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
sys.path.insert(0, '.')
import utils, numpy as np
from PIL import Image, ImageFilter, ImageDraw
import random

utils._model = None
model = utils.load_model()
print('Model loaded!')

def make_leaf(r_base, g_base, b_base, n_spots=15):
    img = np.random.normal(0, 15, (224, 224, 3)).astype('int32')
    img[:,:,0] += r_base
    img[:,:,1] += g_base
    img[:,:,2] += b_base
    img = np.clip(img, 0, 255).astype('uint8')
    pil = Image.fromarray(img)
    draw = ImageDraw.Draw(pil)
    for _ in range(n_spots):
        x, y = random.randint(10,214), random.randint(10,214)
        r = random.randint(3, 12)
        c = (random.randint(100,180), random.randint(40,80), random.randint(0,40))
        draw.ellipse([x-r, y-r, x+r, y+r], fill=c)
    pil = pil.filter(ImageFilter.SMOOTH)
    return pil

def test_img(pil_img, name):
    buf = io.BytesIO()
    pil_img.save(buf, format='JPEG')
    r = utils.predict(buf.getvalue())
    print(f'  {name}: {r["crop"]} / {r["disease"]} ({r["confidence"]}%)')

test_img(make_leaf(60, 120, 40, n_spots=20), 'Tomato leaf + dark spots')
test_img(make_leaf(50, 100, 30, n_spots=30), 'Potato leaf + many spots')
test_img(make_leaf(100, 130, 20, n_spots=5), 'Healthy green leaf')
test_img(make_leaf(160, 130, 20, n_spots=40), 'Yellow diseased leaf')
test_img(make_leaf(80, 60, 30, n_spots=50), 'Brown diseased leaf')
print('Done')
