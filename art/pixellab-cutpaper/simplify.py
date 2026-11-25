"""Detail-level pass in code (0 generations): merge small regions into their surroundings and drop isolated pixels, for the cut-paper pieces.
simplify(img, min_area) -> RGBA. A 'region' is a connected set of one colour; any region smaller than min_area takes the most common colour around it."""
import numpy as np
from PIL import Image
from scipy import ndimage
def simplify(im,min_area,passes=2):
    a=np.array(im.convert('RGBA'));rgb=a[...,:3].copy();h,w=rgb.shape[:2]
    key=(rgb[...,0].astype(int)<<16)|(rgb[...,1].astype(int)<<8)|rgb[...,2].astype(int)
    for _ in range(passes):
        out=key.copy()
        for c in np.unique(key):
            lab,n=ndimage.label(key==c)
            if n==0: continue
            sizes=ndimage.sum(np.ones_like(lab),lab,index=np.arange(1,n+1))
            for i in np.where(sizes<min_area)[0]+1:
                m=lab==i;ring=ndimage.binary_dilation(m,iterations=1)&~m
                nb=key[ring]
                if len(nb): vals,cnt=np.unique(nb,return_counts=True);out[m]=vals[cnt.argmax()]
        key=out
    rgb2=np.dstack([(key>>16)&255,(key>>8)&255,key&255]).astype(np.uint8)
    a[...,:3]=rgb2;return Image.fromarray(a,'RGBA')
