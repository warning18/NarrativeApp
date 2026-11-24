"""Snap the Tower ink pieces to the ink palette: ten Apollo greys + three deep reds (no gold). python3 art/pixellab-ink/tower/snap.py"""
import sys, numpy as np; sys.path.insert(0,'art/pixellab-cards')
import build as CB
from PIL import Image
PAL=np.array([[int(h[i:i+2],16) for i in (0,2,4)] for h in '090A14 10141F 151D28 202E37 394A50 577277 819796 A8B5B2 C7CFCC EBEDE9 411D31 752438 A53030'.split()],float)
def snap(im):
    a=np.array(im.convert('RGBA'));rgb=a[...,:3].reshape(-1,3).astype(float)
    d=((rgb[:,None,:]-PAL[None])**2*np.array([2,4,3])).sum(2);a[...,:3]=PAL[d.argmin(1)].reshape(a.shape[:2]+(3,)).astype(np.uint8);return Image.fromarray(a,'RGBA')
R='art/pixellab-ink/tower/raw/';F='art/pixellab-ink/final/'
PICK={'band1_scene':(1,2),'band2_scene':(1,2),'band3_scene':(1,2),'band1_dice':(1,None),'band2_dice':(1,None),'band3_dice':(3,4)}
if __name__=='__main__':
    for n,(s,a) in PICK.items():
        name=n.replace('band','tower_band')
        CB.png8(snap(Image.open(f'{R}{n}_s{s}/get_image_0.png').convert('RGBA')),f'{F}ink_{name}.png')
        if a: CB.png8(snap(Image.open(f'{R}{n}_s{a}/get_image_0.png').convert('RGBA')),f'{F}alt_ink_{name}.png')
