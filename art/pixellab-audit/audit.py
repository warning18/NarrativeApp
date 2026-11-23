"""Visual consistency audit of the bundled art (0 generations). python3 art/pixellab-audit/audit.py -> art/pixellab-audit/audit.json"""
import glob, os, json, numpy as np, sys
sys.path.insert(0,'tool'); import apollo_remap as AR
from PIL import Image
def hx(s): return tuple(int(s[i:i+2],16) for i in (0,2,4))
APOLLO={hx(h) for h in AR.HEX+AR.CORES}; MUTED={hx(h) for h in AR.MUTED+AR.ACCENTS}
rows=[]
for p in sorted(glob.glob('assets/visuals/**/*.png',recursive=True)+glob.glob('assets/icons/**/*.png',recursive=True)):
    try: im=Image.open(p)
    except Exception as e: rows.append(dict(path=p,error=str(e))); continue
    a=np.array(im.convert('RGBA')); h,w=a.shape[:2]; op=a[...,3]>0
    n=int(op.sum()); rgb=a[...,:3][op]
    cols,cnt=np.unique(rgb,axis=0,return_counts=True)
    ct=[tuple(int(x) for x in c) for c in cols]
    inA=sum(c for t,c in zip(ct,cnt) if t in APOLLO); inM=sum(c for t,c in zip(ct,cnt) if t in MUTED)
    # upscale factor: largest k in 2..6 so that the image is made of k x k identical blocks
    up=1
    for k in (6,5,4,3,2):
        if w%k==0 and h%k==0:
            small=a[::k,::k]; big=np.repeat(np.repeat(small,k,0),k,1)
            if (big==a).all(): up=k;break
    # outline and light (sprites with transparency only)
    outline=None; light=None
    if (~op).any() and n>50:
        pad=np.pad(op,1);edge=op&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:])
        L=a[...,:3]@np.array([.3,.59,.11])
        if edge.sum()>10: outline=float((L[edge]<70).mean())
        ys,xs=np.where(op); cy,cx=(ys.min()+ys.max())/2,(xs.min()+xs.max())/2
        yy,xx=np.mgrid[:h,:w]; tl=op&(yy<cy)&(xx<cx); br=op&(yy>=cy)&(xx>=cx); tr=op&(yy<cy)&(xx>=cx); bl=op&(yy>=cy)&(xx<cx)
        if min(tl.sum(),br.sum(),tr.sum(),bl.sum())>10: light=dict(diag=float(L[tl].mean()-L[br].mean()),anti=float(L[tr].mean()-L[bl].mean()))
    rows.append(dict(path=p,w=w,h=h,bytes=os.path.getsize(p),mode=im.mode,colours=len(ct),opaque=n,apollo=round(inA/max(n,1),3),muted=round(inM/max(n,1),3),up=up,outline=None if outline is None else round(outline,3),light=light,bpp=round(os.path.getsize(p)/(w*h),3)))
json.dump(rows,open('art/pixellab-audit/audit.json','w'),indent=0)
print(len(rows))
