"""Enforce the limited palettes on the PixelLab outputs (hard pixels, alpha kept). python3 art/pixellab-styles/post.py
STYLE 1: five greys + blood red / gold kept only on small accent parts (components up to N px, or inside a box for the backdrop).
STYLE 2: 8 dark colours: every pixel darkened to 62 % and snapped to the palette."""
import numpy as np, colorsys, json
from PIL import Image
from scipy import ndimage
def hx(s): return np.array([int(s[i:i+2],16) for i in (0,2,4)],float)
G=[hx(x) for x in '090A14 202E37 394A50 8B9BA0 EBEDE9'.split()]; RED=hx('A53030'); GOLD=hx('F2C14E')
P2=np.array([hx(x) for x in '090A14 151D28 202E37 3C5E8B 577277 884B2B DE9E41 E8C170'.split()])
def snap(c,pal):
    d=((pal-c)**2*np.array([2,4,3])).sum(1); return pal[d.argmin()]
def style1(im,box=None,maxarea=40,stretch=True,red_ok=True):
    a=np.array(im.convert('RGBA'));rgb=a[...,:3].astype(float);al=a[...,3]
    mx=rgb.max(2);mn=rgb.min(2);sat=(mx-mn)/np.maximum(mx,1)
    red=(sat>0.45)&(rgb[...,0]>rgb[...,1]*1.5)&(rgb[...,0]>rgb[...,2]*1.5)&(rgb[...,0]<230)
    gold=(sat>0.5)&(rgb[...,0]>170)&(rgb[...,1]>120)&(rgb[...,2]<110)
    if not red_ok: red=red&False
    acc=(red|gold)&(al>0); lab,n=ndimage.label(acc|False)
    keep=np.zeros(acc.shape,bool)
    for i in range(1,n+1):
        m=lab==i
        if box is not None:
            ys,xs=np.where(m); inside=(xs.mean()>=box[0] and xs.mean()<=box[2] and ys.mean()>=box[1] and ys.mean()<=box[3])
            if inside and m.sum()<=400: keep|=m
        elif m.sum()<=maxarea: keep|=m
    L=(rgb@np.array([.3,.59,.11]))
    if not stretch: L=np.clip(L/255*1.0,0,1)
   
    if stretch and (al>0).any(): lo,hi=np.percentile(L[al>0],[2,98]); L=np.clip((L-lo)/max(hi-lo,1),0,1)
    out=np.zeros_like(rgb)
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if al[y,x]==0: continue
            if keep[y,x]: out[y,x]=RED if red[y,x] else GOLD
            else: out[y,x]=G[min(4,int(L[y,x]*5))]
    a[...,:3]=out.astype(np.uint8);return Image.fromarray(a,'RGBA')
def style2(im):
    a=np.array(im.convert('RGBA'));rgb=a[...,:3].astype(float)*0.62
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y,x,3]: a[y,x,:3]=snap(rgb[y,x],P2)
    return Image.fromarray(a,'RGBA')
