"""Palette snap for the cut-paper pieces: ink, dark, paper shadow, paper and one accent (any saturated pixel becomes the accent). python3 -c 'import snap'"""
import sys, numpy as np
sys.path.insert(0,'art/pixellab-brut'); import derive as D
from PIL import Image
def snap(im,accent=(165,48,48),levels=(30,55,80)):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>0;rgb=a[...,:3]/255.
    mx=rgb.max(2);mn=rgb.min(2);sat=(mx-mn)/np.maximum(mx,1e-3)
    L=a[...,:3]@np.array([.3,.59,.11]);lv=np.digitize(L,np.percentile(L[al],list(levels)))
    out=np.array([D.INK,[40,40,58],[201,194,166],D.PAPER],float)[lv]
    acc=(sat>0.55)&(mx>0.35);out[acc]=np.array(accent)
    return Image.fromarray(np.dstack([out.astype(np.uint8),a[...,3].astype(np.uint8)]),'RGBA')
