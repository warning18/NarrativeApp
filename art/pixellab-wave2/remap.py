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

# ---- ink + one spot hue (the user's choice for the icons) ----
FAM={'red':'411D31 752438 A53030','orange':'884B2B BE772B DE9E41','gold':'BE772B DE9E41 E8C170','green':'25562E 468232 75A743','blue':'253A5E 3C5E8B 4F8FBA','purple':'402751 7A367B A23E8C'}
RAMP={k:np.array([[int(h[i:i+2],16) for i in (0,2,4)] for h in v.split()],float) for k,v in FAM.items()}
def family(h,s,v):
    if s<0.4 or v<0.3: return None
    if h<0.04 or h>0.93: return 'red'
    if h<0.11: return None if (v<0.6) else 'orange'   # brown wood and leather stay neutral
    if h<0.2: return 'gold'
    if h<0.45: return 'green'
    if h<0.72: return 'blue'
    return 'purple'
def ink_spot(im):
    a=np.array(im.convert('RGBA'));rgb=a[...,:3].astype(float)/255;out=a.copy();fam={}
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y,x,3]==0: continue
            h,s,v=colorsys.rgb_to_hsv(*rgb[y,x]);f=family(h,s,v)
            if f: fam[f]=fam.get(f,0)+1
    keep=max(fam,key=fam.get) if fam and max(fam.values())>=3 else None
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y,x,3]==0: continue
            r,g,b=rgb[y,x];h,s,v=colorsys.rgb_to_hsv(r,g,b);L=.3*r+.59*g+.11*b
            if keep and family(h,s,v)==keep: out[y,x,:3]=RAMP[keep][min(2,int(v*3))]
            else: out[y,x,:3]=GREYS[min(9,int(L**0.9*10))]
    return Image.fromarray(out,'RGBA'),keep
