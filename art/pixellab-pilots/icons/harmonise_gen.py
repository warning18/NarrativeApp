import glob,collections,colorsys
from PIL import Image
import numpy as np
def H(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))
THEME=[H(x) for x in ('#A5302A','#A84E12','#226565','#3D7A2C','#6B6356','#A8A194','#CFC4AE','#D9544D','#E0762B','#F2C14E','#8A5A00','#7DBE6A','#3B3743','#4FB0B0','#A987EA','#6A4FB0')]
INK=H('#0A0807'); CREAM=H('#FAF2DA')
def load_all():
    return [(f,Image.open(f).convert('RGBA')) for f in sorted(glob.glob('assets/icons/skills/*.png')+glob.glob('assets/icons/items/*.png'))]
def hero_colours(n=10):
    im=Image.open('assets/visuals/walker/ronin_idle_west.png').convert('RGBA'); a=im.getchannel('A').point(lambda v:255 if v>127 else 0)
    rgb=Image.new('RGB',im.size,(0,0,0)); rgb.paste(im.convert('RGB'),mask=a); q=rgb.quantize(n+1,method=Image.MEDIANCUT,dither=Image.NONE)
    pal=q.getpalette()[:3*(n+1)]; return [tuple(pal[i*3:i*3+3]) for i in range(n+1)][1:]
def d2(a,b): return sum((x-y)**2 for x,y in zip(a,b))
def build_palette():
    allc=collections.Counter()
    for f,im in load_all():
        for p in im.getdata():
            if p[3]>0: allc[p[:3]]+=1
    # originals' clusters: weighted greedy merge within distance 26
    cents=[]
    for c,w in allc.most_common():
        for cc in cents:
            if d2(c,cc[0])<26*26: cc[1]+=w; break
        else: cents.append([c,w])
    cents.sort(key=lambda x:-x[1]); core=[c for c,w in cents[:40]]
    pal=[INK,CREAM]+THEME+hero_colours()+core
    out=[]
    for c in pal:
        if all(d2(c,o)>=14*14 for o in out): out.append(c)
    return out,allc
def snap(im,pal):
    out=im.copy(); px=out.load(); P=np.array(pal)
    cache={}
    for y in range(im.height):
        for x in range(im.width):
            p=px[x,y]
            if p[3]==0: continue
            c=p[:3]
            if c not in cache:
                if sum(c)<110 and max(c)<60: cache[c]=INK   # every near-black outline becomes the one ink
                else: cache[c]=tuple(P[((P-np.array(c))**2).sum(1).argmin()])
            px[x,y]=tuple(int(v) for v in cache[c])+(255,)
    return out
if __name__=='__main__':
    pal,allc=build_palette(); print(len(pal),'palette colours; original distinct',len(allc))
    errs=[];
    for f,im in load_all()[:60]:
        s=snap(im,pal); a=np.array(im).astype(int); b=np.array(s).astype(int); m=a[...,3]>0
        errs.append(np.abs(a[...,:3][m]-b[...,:3][m]).mean())
    print('mean abs colour change on 60 icons: %.1f'%np.mean(errs))
    import json; json.dump(['#%02X%02X%02X'%c for c in pal],open('art/pixellab-pilots/icons/shared_palette.json','w'))

# ---------- (b): original glyph in the rarity frame + element colour ----------
def depth_map(im):
    w,h=im.size; px=im.load(); INF=99; dep=[[INF]*w for _ in range(h)]
    from collections import deque
    q=deque()
    for y in range(h):
        for x in range(w):
            if px[x,y][3]==0: dep[y][x]=0; q.append((x,y))
    # treat outside the canvas as transparent for edge pixels
    for y in range(h):
        for x in range(w):
            if px[x,y][3]>0 and (x in (0,w-1) or y in (0,h-1)): dep[y][x]=1; q.append((x,y))
    while q:
        x,y=q.popleft()
        for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
            nx,ny=x+dx,y+dy
            if 0<=nx<w and 0<=ny<h and dep[ny][nx]>dep[y][x]+1: dep[ny][nx]=dep[y][x]+1; q.append((nx,ny))
    return dep
def extract_glyph(im):
    px=im.load(); w,h=im.size; dep=depth_map(im)
    ring=collections.Counter(px[x,y][:3] for y in range(h) for x in range(w) if px[x,y][3]>0 and dep[y][x]==2)
    inner=collections.Counter(px[x,y][:3] for y in range(h) for x in range(w) if px[x,y][3]>0 and dep[y][x]>=3)
    if not inner: return Image.new('RGBA',im.size,(0,0,0,0))
    F=inner.most_common(1)[0][0]
    cont={c for c,_ in ring.most_common(2)}|{F}
    out=Image.new('RGBA',im.size,(0,0,0,0)); op=out.load()
    for y in range(h):
        for x in range(w):
            p=px[x,y]
            if p[3]>0 and dep[y][x]>=2:
                c=p[:3]
                if c in cont or d2(c,F)<40*40: continue
                op[x,y]=p
    return out

def hsv(c): return colorsys.rgb_to_hsv(*(v/255 for v in c))
def extract_glyph(im):
    px=im.load(); w,h=im.size; dep=depth_map(im)
    ring=collections.Counter(px[x,y][:3] for y in range(h) for x in range(w) if px[x,y][3]>0 and dep[y][x]==2)
    if not ring: return Image.new('RGBA',im.size,(0,0,0,0))
    ref=ring.most_common(1)[0][0]; rh,rs,rv=hsv(ref)
    def in_family(c):
        hh,ss,vv=hsv(c)
        if rs>0.22:   # a coloured container: same hue family (any shade), saturated enough
            dh=min(abs(hh-rh),1-abs(hh-rh)); return ss>0.18 and dh<0.07
        return ss<0.22 and abs(vv-rv)<0.28 # a grey container: similar grey
    out=Image.new('RGBA',im.size,(0,0,0,0)); op=out.load()
    ringcols={ref}
    for y in range(h):
        for x in range(w):
            p=px[x,y]
            if p[3]>0 and dep[y][x]>=3:
                c=p[:3]
                if c in ringcols or in_family(c): continue
                op[x,y]=p
    return out
