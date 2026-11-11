"""Rawer version of the 6 piloted skill strips: 0 generations, pure PIL.
Each 48x48 frame -> 24x24 grid (box average, hard alpha), 5 luminance colours
(median-cut over the whole strip, sorted dark to light) + ink outline, specks
under 3 cells removed, then scaled x2 by whole pixels. Output PNG8 432x48."""
import sys, os
from PIL import Image
import numpy as np
from scipy import ndimage
R = os.path.dirname(os.path.abspath(__file__))
INK = (10, 8, 7)
STYLES = ['flame', 'frost', 'lightning', 'heal', 'void_rift', 'shield']
NCOL = 5

def lum(c): return 0.3*c[...,0]+0.59*c[...,1]+0.11*c[...,2]

def process(style, ncol=None, speck=3, athr=110):
    NCOL_ = ncol or NCOL
    src = Image.open(f'{R}/staged/vfx_{style}.png').convert('RGBA')
    n = src.width//48
    frames = [src.crop((i*48,0,i*48+48,48)) for i in range(n)]
    small = []
    for f in frames:
        a = np.asarray(f).astype(float)
        a = a.reshape(24,2,24,2,4)
        al = a[...,3].mean(axis=(1,3))
        w = a[...,3:4]/255.0+1e-6
        rgb = (a[...,:3]*w).sum(axis=(1,3))/w.sum(axis=(1,3))
        small.append((rgb, al))
    # palette: median cut on all opaque cells
    px = np.concatenate([rgb[al>max(athr,140)] for rgb,al in small])
    pal_im = Image.fromarray(px.astype(np.uint8).reshape(-1,1,3)).quantize(NCOL_, method=Image.Quantize.MEDIANCUT)
    p = np.array(pal_im.getpalette()[:NCOL_*3]).reshape(NCOL_,3)
    p = p[np.argsort(lum(p))]
    out = Image.new('RGBA',(48*n,48),(0,0,0,0))
    for i,(rgb,al) in enumerate(small):
        mask = al>athr
        lab,k = ndimage.label(mask)
        for j in range(1,k+1):
            if (lab==j).sum()<speck: mask[lab==j]=False
        d = ((rgb[:,:,None,:]-p[None,None])**2).sum(-1)
        idx = d.argmin(-1)
        g = np.zeros((24,24,4),np.uint8)
        for y in range(24):
            for x in range(24):
                if mask[y,x]: g[y,x]=(*p[idx[y,x]],255)
        # ink outline (4-neighbour) around the shape
        lab2,k2 = ndimage.label(mask)
        big_m = np.isin(lab2,[j for j in range(1,k2+1) if (lab2==j).sum()>=8])
        ring = ndimage.binary_dilation(big_m) & ~mask
        g[ring]=(*INK,255)
        big = np.kron(g, np.ones((2,2,1),np.uint8))
        out.paste(Image.fromarray(big,'RGBA'),(i*48,0))
    return out

def png8(im):
    a = im.convert('RGBA'); q = Image.new('P',a.size,0)
    cols = {}
    pal=[0,0,0]; px=a.load(); qp=q.load()
    for y in range(a.height):
        for x in range(a.width):
            r,g,b,al = px[x,y]
            if al<128: qp[x,y]=0; continue
            k=(r,g,b)
            if k not in cols: cols[k]=len(cols)+1; pal+=list(k)
            qp[x,y]=cols[k]
    q.putpalette(pal+[0]*(768-len(pal))); q.info['transparency']=0
    return q

if __name__=='__main__':
    os.makedirs(f'{R}/staged-rawer',exist_ok=True); os.makedirs(f'{R}/gif-rawer',exist_ok=True)
    OPT={'heal':dict(ncol=7,speck=1,athr=50)}
    for s in STYLES:
        im = process(s, **OPT.get(s,{}))
        png8(im).save(f'{R}/staged-rawer/vfx_{s}.png', optimize=True)
        fr=[]
        for i in range(im.width//48):
            bg=Image.new('RGBA',(96,96),(31,28,35,255)); f=im.crop((i*48,0,i*48+48,48)).resize((96,96),Image.NEAREST)
            bg.alpha_composite(f); fr.append(bg.convert('RGB'))
        fr[0].save(f'{R}/gif-rawer/{s}.gif',save_all=True,append_images=fr[1:],duration=90,loop=0)
        print(s, len(set(im.getdata())) if False else 'ok')
