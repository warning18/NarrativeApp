"""Lighter treatments of the 'form' icons, in code (0 generations).
V1 light ink: black outline, a paper-white body, the old highlights become ink lines, the spot colour kept.
V2 two-tone: black outline, a mid body colour (paper shadow), paper highlights, the spot colour kept.
V3 colour-tinted: black outline, a flat light object colour (glass, steel, brass), paper highlights, the spot colour kept."""
import numpy as np, colorsys
from PIL import Image
from scipy import ndimage
PAPER=np.array([231,225,205]);SHADOW=np.array([201,194,166]);INK=np.array([9,10,20])
def parts(im):
    a=np.array(im.convert('RGBA'));al=a[...,3]>0;rgb=a[...,:3].astype(float)
    pad=np.pad(al,1);edge=al&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:])
    L=rgb@np.array([.3,.59,.11]);mx=rgb.max(2);mn=rgb.min(2);sat=(mx-mn)/np.maximum(mx,1)
    spot=al&(sat>0.4)&(mx>60);inside=al&~edge&~spot
    return a,al,edge,spot,inside,L
def v1(im):
    a,al,edge,spot,inside,L=parts(im);o=a.copy()
    dark=inside&(L<110);light=inside&(L>=110)
    o[dark,:3]=PAPER;o[light,:3]=INK;o[edge&~spot,:3]=INK;return Image.fromarray(o,'RGBA')
def v2(im,body=SHADOW):
    a,al,edge,spot,inside,L=parts(im);o=a.copy()
    dark=inside&(L<110);light=inside&(L>=110)
    o[dark,:3]=body;o[light,:3]=PAPER;o[edge&~spot,:3]=INK;return Image.fromarray(o,'RGBA')
def v3(im,tint):
    return v2(im,np.array(tint))

# ---- tokenised: snap to the Ashen Ink tokens and merge regions under 3 px (the design system's icon rule) ----
import sys
sys.path.insert(0,'art/pixellab-cutpaper')
def tokenise(im,spot_hex,extra=()):
    from simplify import simplify
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>0
    pal=[INK,PAPER,SHADOW,np.array([int(spot_hex[i:i+2],16) for i in (0,2,4)])]+[np.array(e) for e in extra]
    pal=np.array(pal,float);rgb=a[...,:3]
    d=((rgb[:,:,None,:]-pal[None,None])**2*np.array([2,4,3])).sum(3);idx=d.argmin(2)
    a[...,:3]=pal[idx];out=Image.fromarray(a.astype(np.uint8),'RGBA')
    return simplify(out,3)
