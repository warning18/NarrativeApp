"""Cut the weather overlays from the PixelLab masters: keep the snow (light pixels) or sand (warm pixels) only, drop the dark ground the model drew under it, seat the pile on a flat base, and make the 300 and 90 px widths by a centred crop with the ends tapered. python3 art/pixellab-weather/build.py"""
import numpy as np, sys, os
sys.path.insert(0,'art/pixellab-cards'); import build as CB
from PIL import Image
R='art/pixellab-weather/raw/';F='art/pixellab-weather/final/'
def lum(rgb): return rgb@np.array([.3,.59,.11])
def extract(kind,im):
    a=np.array(im.convert('RGBA'));rgb=a[...,:3].astype(float);al=a[...,3]>0;L=lum(rgb)
    mx=rgb.max(2);mn=rgb.min(2);sat=(mx-mn)/np.maximum(mx,1)
    if kind=='snow': keep=al&(L>120)&(sat<0.35)
    elif kind=='sand': keep=al&(rgb[...,0]>=rgb[...,2]*1.25)&(L>90)
    else: keep=al&(L<130)
    a[...,3]=np.where(keep,255,0);ys=np.where(keep.any(1))[0]
    if len(ys): a=a[ys.min():]            # drop empty rows on top
    return Image.fromarray(a,'RGBA')
def seat(im):
    """flat base: crop the bottom empty rows, then cut the lowest row to a straight line"""
    a=np.array(im);op=a[...,3]>0;ys=np.where(op.any(1))[0]
    if not len(ys): return im
    return Image.fromarray(a[ys.min():ys.max()+1],'RGBA')
def taper(im,w,edge):
    a=np.array(im);h,W=a.shape[:2];x0=(W-w)//2;a=a[:,x0:x0+w].copy()
    op=a[...,3]>0
    for x in range(w):
        d=min(x,w-1-x)
        if d<edge:
            keep_h=max(1,int(round(h*(d+1)/edge)))                     # thin at the ends
            a[:h-keep_h,x,3]=0
    return Image.fromarray(a,'RGBA')
def stage_files(kind,stage,s,sc=1):
    im=Image.open(f'{R}{kind}_{stage}_s{s}/get_image_0.png').convert('RGBA')
    m=seat(extract(kind,im));return m
if __name__=='__main__':
    os.makedirs(F,exist_ok=True)
    PICK=dict(json_pick=0)
    import json
    pick=json.load(open('art/pixellab-weather/pick.json')) if os.path.exists('art/pixellab-weather/pick.json') else {}
    for kind,stages in (('snow',('dusting','light','medium','heavy')),('sand',('dusting','light','medium','heavy')),('ash',('dusting','heavy'))):
        for st in stages:
            s=pick.get(f'{kind}_{st}',1);m=stage_files(kind,st,s)
            for w,e in ((340,30),(300,40),(90,26)):
                o=taper(m,w,e) if w<m.width else taper(m,min(w,m.width),e)
                CB.png8(o,f'{F}{kind}_{st}_{w}.png')
