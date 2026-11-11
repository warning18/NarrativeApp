"""The restrained casino palette (12 incl. the ink) and the cleanup: remap to the palette, remove stray pixels, keep the ink."""
import numpy as np
from PIL import Image
def H(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))
PAL12={'ink':H('#0A0807'),'shadow':H('#1B1620'),'wood_d':H('#3B2A20'),'wood_m':H('#5A4030'),'wood_l':H('#7A5A3C'),'red':H('#7A1F24'),'red_l':H('#A83B34'),
 'felt':H('#2F6B3C'),'stone':H('#6B6356'),'brass':H('#C9A25A'),'candle':H('#F2C14E'),'cream':H('#FAF2DA')}
P=np.array(list(PAL12.values()))
def remap(im):
    a=np.array(im.convert('RGB')).astype(int); d=((a[:,:,None,:]-P[None,None])**2).sum(-1); return d.argmin(-1)   # palette index per pixel
def despeckle(idx,passes=2):
    h,w=idx.shape
    for _ in range(passes):
        out=idx.copy()
        for y in range(1,h-1):
            for x in range(1,w-1):
                c=idx[y,x]; n=[idx[y-1,x],idx[y+1,x],idx[y,x-1],idx[y,x+1]]
                if c!=0 and n.count(c)==0:         # a pixel with no 4-neighbour of its colour (never the ink): take the commonest neighbour
                    out[y,x]=max(set(n),key=n.count)
        idx=out
    return idx
def to_image(idx): return Image.fromarray(P[idx].astype(np.uint8),'RGB')
def png8(idx,path):
    q=Image.fromarray(idx.astype(np.uint8),'P'); q.putpalette([v for c in P for v in c]+[0]*(768-3*len(P))); q.save(path,optimize=True)
def swatch(path):    # the palette as a small colour image (for pixflux's forced palette)
    im=Image.new('RGB',(len(P)*8,8)); 
    for i,c in enumerate(P): im.paste(tuple(int(v) for v in c),(i*8,0,i*8+8,8))
    im.save(path)
