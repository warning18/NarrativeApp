"""Zero-generation palette remaps for the user's choice (wave 2): Apollo and the ink palette. Hard pixels, alpha kept.
as a module: apollo(im) -> RGBA; ink(im) -> RGBA"""
import sys, colorsys, numpy as np
sys.path.insert(0,'tool'); import apollo_remap as AR
from PIL import Image
GREYS=np.array([[int(h[i:i+2],16) for i in (0,2,4)] for h in '090A14 10141F 151D28 202E37 394A50 577277 819796 A8B5B2 C7CFCC EBEDE9'.split()],float)
REDS=np.array([[int(h[i:i+2],16) for i in (0,2,4)] for h in '411D31 752438 A53030'.split()],float)
def apollo(im): return AR.remap(im,pal='apollo+cores')
def ink(im):
    a=np.array(im.convert('RGBA'));rgb=a[...,:3].astype(float)/255;out=a.copy()
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y,x,3]==0: continue
            r,g,b=rgb[y,x];h,s,v=colorsys.rgb_to_hsv(r,g,b);L=.3*r+.59*g+.11*b
            if s>0.45 and (h<0.05 or h>0.93) and v>0.25:
                out[y,x,:3]=REDS[min(2,int(v*3.2))]
            else:
                out[y,x,:3]=GREYS[min(9,int(L**0.9*10))]
    return Image.fromarray(out,'RGBA')
