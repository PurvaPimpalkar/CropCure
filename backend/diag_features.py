"""
Direct bias and activation check - no intermediate Model needed
"""
import os, sys
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
sys.path.insert(0, '.')
import utils, numpy as np, io, h5py
from PIL import Image

utils._model = None
model = utils.load_model()
print('Model loaded!')

# Check Dense(27) bias
d1_bias   = model.layers[4].get_weights()[1]
d1_kernel = model.layers[4].get_weights()[0]
d0_bias   = model.layers[3].get_weights()[1]
print(f'\nDense(27) bias range: [{d1_bias.min():.3f}, {d1_bias.max():.3f}]')
print(f'Dense(27) kernel std: {d1_kernel.std():.4f}')
top5 = d1_bias.argsort()[::-1][:5]
print('Top 5 biased output classes:')
for i in top5:
    print(f'  Class {i}: bias={d1_bias[i]:.3f} -> {utils.CLASS_LABELS[i]}')

# Run model on two very different images and check raw logits
def get_predictions(arr, name):
    img = (arr.astype('float32') / 127.5) - 1.0
    raw = model.predict(np.expand_dims(img, 0), verbose=0)[0]
    print(f'\n{name} raw softmax (all 27):')
    for i in raw.argsort()[::-1][:5]:
        print(f'  [{i:2d}] {utils.CLASS_LABELS[i]}: {raw[i]*100:.4f}%')

img_green = np.zeros((224,224,3)); img_green[:,:,1]=120
img_red   = np.zeros((224,224,3)); img_red[:,:,0]=200

get_predictions(img_green, 'All-green')
get_predictions(img_red,   'All-red')

# Check base model output variance
print('\nChecking base model (MobileNetV2) output std:')
base = model.layers[0]
dummy_g = (img_green.astype('float32')/127.5 - 1.0)[None]
dummy_r = (img_red.astype('float32')/127.5 - 1.0)[None]
feat_g = base.predict(dummy_g, verbose=0)
feat_r = base.predict(dummy_r, verbose=0)
print(f'  Green base output: shape={feat_g.shape}, std={feat_g.std():.4f}, mean={feat_g.mean():.4f}')
print(f'  Red   base output: shape={feat_r.shape}, std={feat_r.std():.4f}, mean={feat_r.mean():.4f}')
print(f'  Correlation: {np.corrcoef(feat_g.flatten(), feat_r.flatten())[0,1]:.4f}')
