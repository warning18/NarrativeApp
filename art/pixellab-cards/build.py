"""Stage the picked card pieces (Apollo+cores palette, PNG8, transparent index) and mock the cards. python3 art/pixellab-cards/build.py"""
import sys, numpy as np
sys.path.insert(0,'tool'); import apollo_remap as AR
from PIL import Image, ImageDraw, ImageFont
R='art/pixellab-cards/raw/'; F='art/pixellab-cards/final/'
PICK={'frame':{'common':2,'uncommon':1,'rare':1,'epic':1,'legendary':1},'plate':{'common':1,'uncommon':1,'rare':1,'epic':2,'legendary':2},'backdrop':{'common':1,'uncommon':1,'rare':1,'epic':1,'legendary':1}}
RAW={'backdrop':'art/pixellab-cards/raw/'}
def png8(im,path):
    a=np.array(im.convert('RGBA'));mk=a[...,3]<128
    q=Image.fromarray(a[...,:3]).quantize(63,Image.MEDIANCUT,dither=Image.NONE);p=np.array(q);p[mk]=63
    o=Image.fromarray(p,'P');o.putpalette(q.getpalette()[:189]+[0]*(768-189));o.save(path,transparency=63)
def load(k,t):
    im=Image.open(f'{R}{k}_{t}_s{PICK[k][t]}/get_image_0.png').convert('RGBA')
    if k=='frame':
        a=np.array(im);r,g,b=a[...,0].astype(int),a[...,1].astype(int),a[...,2].astype(int)
        key=(r>150)&(b>150)&(g<110)                         # magenta-ish key
        h,w=a.shape[:2];a[5:h-5,5:w-5][...,3]=np.where(True,0,0)   # the inside is the card: cut it
        a[key,3]=0
        for x,y in [(0,0),(1,0),(0,1),(w-1,0),(w-2,0),(w-1,1),(0,h-1),(1,h-1),(0,h-2),(w-1,h-1),(w-2,h-1),(w-1,h-2)]:
            if a[y,x,0]>200 and a[y,x,1]>200: a[y,x,3]=0
        im=Image.fromarray(a)
    return AR.remap(im,pal='apollo+cores')
def main():
    for k in PICK:
        for t in PICK[k]:
            im=load(k,t); png8(im,f'{F}{k}_{t}.png')
if __name__=='__main__': main()
