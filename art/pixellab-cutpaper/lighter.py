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
