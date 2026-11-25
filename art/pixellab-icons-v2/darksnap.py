"""Snap an RGBA image to the dark chibi palette (ink edge kept, no region under 2 px)."""
import sys,numpy as np
sys.path.insert(0,'art/pixellab-icons-v2');sys.path.insert(0,'art/pixellab-cutpaper')
from PIL import Image
from simplify import simplify
import palette_dark as PD
PAL=PD.PAL
def snap(im,min_area=2,edge=True):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>40;rgb=a[...,:3];p=np.array(PAL,float)
    d=((rgb[:,:,None,:]-p[None,None])**2*np.array([2,4,3])).sum(3);o=np.zeros_like(a);o[...,:3]=p[d.argmin(2)];o[...,3]=al*255
    if edge:
        pad=np.pad(al,1);ed=al&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:]);o[ed,:3]=PAL[0]
    out=Image.fromarray(o.astype(np.uint8),'RGBA')
    return simplify(out,min_area) if min_area else out
