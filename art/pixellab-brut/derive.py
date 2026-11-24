"""Style exploration 'brut' (zero generations): three directions derived in code from existing art.
A cut paper: flat black silhouettes on paper, one clan colour as the only hue.
B woodcut: two values with hard edges, one accent.
C one light source: big shadow shapes, almost no interior detail, one accent.
python3 art/pixellab-brut/derive.py"""
import numpy as np, colorsys
from PIL import Image
from scipy import ndimage
INK=np.array([9,10,20]);PAPER=np.array([231,225,205]);DEEP=np.array([21,29,40]);MID=np.array([57,74,80])
CLAN={'dominion':'2F6FE0','crows':'E0479E','compact':'E8782A','mire':'3FB06A','vigil':'E8C21A','penitents':'9B5DE5'}
def hexrgb(h): return np.array([int(h[i:i+2],16) for i in (0,2,4)])
def lum(a): return a[...,:3]@np.array([.3,.59,.11])
def accent_mask(a):
    rgb=a[...,:3]/255.;mx=rgb.max(2);mn=rgb.min(2);sat=(mx-mn)/np.maximum(mx,1e-3)
    return (sat>0.45)&(mx>0.3)
def finish(out,alpha):
    r=np.dstack([out.astype(np.uint8),alpha]);return Image.fromarray(r,'RGBA')
def cut_paper(im,acc):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3].astype(np.uint8);L=lum(a);am=accent_mask(a)
    L=ndimage.median_filter(L,3);t=np.percentile(L[al>0],42)
    out=np.where((L>t)[...,None],PAPER,INK).astype(float)
    am=ndimage.binary_closing(am,iterations=1)&(al>0)
    out[am]=acc;return finish(out,al)
def woodcut(im,acc):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3].astype(np.uint8);L=lum(a)
    loc=ndimage.gaussian_filter(L,2.2);m=L>(loc-4)                                   # local threshold: hard edges that follow the forms
    hi=L>np.percentile(L[al>0],72)                                                   # the brightest parts stay light
    light=m&(L>np.percentile(L[al>0],38))|hi
    out=np.where(light[...,None],PAPER,DEEP).astype(float)
    am=accent_mask(a)&(al>0);out[am]=acc;return finish(out,al)
def one_light(im,acc):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3].astype(np.uint8);L=lum(a)
    S=ndimage.gaussian_filter(L,1.6);S=ndimage.median_filter(S,5)                    # big shapes, no interior detail
    h,w=L.shape;yy,xx=np.mgrid[:h,:w];ramp=1-((xx/w)*.5+(yy/h)*.5)                   # the light comes from the top left
    S=S*(.7+.6*ramp)
    q=np.percentile(S[al>0],[35,65,90])
    out=np.where((S<q[0])[...,None],INK,np.where((S<q[1])[...,None],DEEP,np.where((S<q[2])[...,None],MID,acc*0.55+PAPER*0.45))).astype(float)
    glow=S>=np.percentile(S[al>0],96);out[glow&(al>0)]=acc;return finish(out,al)
