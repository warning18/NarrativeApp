"""Final banner recipe: the (a) redraw (frame: coloured header band, stitched border, hem) with the vertical folds of today's cloth composited under it, by hand, 0 generations.
Dominion's emblem is redrawn as a lantern, Mire's leaf simplified (hand-drawn). python3 art/pixellab-banners-new/final_gen.py   (repo root)"""
import sys, os
import numpy as np
from PIL import Image, ImageDraw
INK=(11,9,8,255); CREAM=(241,231,203,255); CREAM_D=(214,201,168,255); CREAM_L=(250,244,226,255)
def lum(p): return .299*p[0]+.587*p[1]+.114*p[2]
def folds(today):
    t=np.array(today.convert('RGBA')); cols={}
    for x in range(64):
        c=[tuple(int(v) for v in t[y,x,:3]) for y in range(16,112) if t[y,x,3] and 14<=lum(t[y,x])<=48]
        if c: c.sort(key=lum); cols[x]=c[len(c)//2]
    return cols
def cloth_modal(a):
    from collections import Counter
    c=Counter(tuple(int(v) for v in a[y,x,:3]) for y in range(16,110) for x in range(6,58) if a[y,x,3] and 16<=lum(a[y,x])<=48); return c.most_common(1)[0][0]
def erase(a,box,M):
    x0,y0,x1,y1=box
    for y in range(y0,y1+1):
        for x in range(x0,x1+1): a[y,x]=(*M,255)
def lantern(im):
    d=ImageDraw.Draw(im); X=31
    def r(x0,y0,x1,y1,c): d.rectangle((x0,y0,x1,y1),fill=c)
    # hanging ring
    r(X-5,18,X+5,19,INK); r(X-5,18,X-4,26,INK); r(X+4,18,X+5,26,INK)
    r(X-4,19,X+4,20,CREAM); r(X-4,19,X-3,25,CREAM); r(X+3,19,X+4,25,CREAM_D)
    # domed cap: stepped trapezoid, wider than the body
    for (w,y) in ((6,25),(9,27),(12,29),(15,31)): r(X-w-1,y,X+w,y+1,INK)
    for (w,y) in ((5,26),(8,28),(11,30),(14,32)): r(X-w,y,X+w-1,y+1,CREAM); r(X+w-2,y,X+w-1,y+1,CREAM_D)
    # body: posts either side, tall glass with a big blue flame
    r(X-14,33,X+13,57,INK); r(X-13,33,X+12,56,CREAM)
    r(X-10,35,X+9,54,INK); r(X-9,36,X+8,53,(21,32,56,255))
    fl=[(38,0,0),(39,-1,0),(40,-1,1),(41,-2,1),(42,-2,2),(43,-3,2),(44,-3,3),(45,-4,3),(46,-4,4),(47,-4,4),(48,-4,4),(49,-4,4),(50,-3,3),(51,-3,2)]
    for y,a,b in fl:
        for x in range(X+a,X+b+1): im.putpixel((x,y),(79,143,186,255))
    for y in range(43,51):
        for x in range(X-2,X+2): im.putpixel((x,y),(115,190,211,255))
    for y in range(45,50):
        for x in range(X-1,X+1): im.putpixel((x,y),(235,237,233,255))
    for y in (36,37): im.putpixel((X,y),(165,221,219,255))
    r(X-13,33,X-11,56,CREAM); r(X+10,33,X+12,56,CREAM_D); r(X-13,33,X-13,55,CREAM_L); r(X-1,36,X-1,36,(21,32,56,255))
    # base with two small feet
    r(X-12,56,X+11,59,INK); r(X-11,56,X+10,58,CREAM); r(X-11,58,X+10,58,CREAM_D)
    r(X-10,59,X-6,61,INK); r(X-9,59,X-7,60,CREAM); r(X+5,59,X+9,61,INK); r(X+6,59,X+8,60,CREAM)
def leaf(im):
    cx,cy=34,44; L=22.0; ang=np.radians(-52); ux,uy=np.cos(ang),np.sin(ang)   # axis from the bottom-left stem to the top-right tip
    W=11.5; mask=np.zeros((128,64),bool)
    for y in range(128):
        for x in range(64):
            dx,dy=x-cx,y-cy; s_=dx*ux+dy*uy; t=-dx*uy+dy*ux; u=s_/L
            if -1<=u<=1:
                w=W*(np.sin(np.pi*(u+1)/2))**1.25*(1.15-0.25*u); mask[y,x]=abs(t)<=w
    ring=np.zeros_like(mask)
    for y in range(1,127):
        for x in range(1,63):
            if not mask[y,x] and mask[y-1:y+2,x-1:x+2].any(): ring[y,x]=True
    for y in range(128):
        for x in range(64):
            if ring[y,x]: im.putpixel((x,y),INK)
            elif mask[y,x]:
                dx,dy=x-cx,y-cy; t=-dx*uy+dy*ux
                im.putpixel((x,y),CREAM_D if t>W*.5 else CREAM_L if t<-W*.55 else CREAM)
    for k in range(int(-L-5),int(L-4)):                                       # one clear vein and a short stem
        x=round(cx+ux*k); y=round(cy+uy*k)
        im.putpixel((x,y),(120,100,70,255) if k>-L+1 else INK)
    for k in range(int(-L-7),int(-L)): 
        x=round(cx+ux*k); y=round(cy+uy*k); im.putpixel((x,y),(120,100,70,255)); im.putpixel((x-1,y),INK)
def gem(im,x,y,c=(63,143,90,255),h=(165,221,219,255)):
    d=ImageDraw.Draw(im); d.rectangle((x-2,y-3,x+2,y+3),fill=INK); d.rectangle((x-3,y-2,x+3,y+2),fill=INK); d.rectangle((x-2,y-2,x+2,y+2),fill=c); d.rectangle((x-3,y-1,x+3,y+1),fill=c); im.putpixel((x-1,y-1),h); im.putpixel((x,y-2),h)
def build(k):
    today=Image.open(f'assets/visuals/banners/clan_{k}.png').convert('RGBA'); a=Image.open(f'art/pixellab-banners-new/staged/clan_{k}_a.png').convert('RGBA')
    arr=np.array(a); M=cloth_modal(arr)
    if k=='dominion': erase(arr,(12,17,54,64),M)
    if k=='mire': erase(arr,(10,17,56,70),M)
    im=Image.fromarray(arr)
    if k=='dominion': lantern(im)
    if k=='mire': leaf(im); gem(im,49,50)
    arr=np.array(im); F=folds(today)
    for y in range(14,112):
        for x in range(5,59):
            p=arr[y,x]
            if p[3] and x in F and max(abs(int(p[i])-M[i]) for i in range(3))<=10: arr[y,x,:3]=F[x]
    return Image.fromarray(arr), today, a
if __name__=='__main__':
    os.makedirs('art/pixellab-banners-new/final',exist_ok=True)
    ks=sys.argv[1].split(',') if len(sys.argv)>1 else ['dominion','oni','crows','mire']
    sh=Image.new('RGB',(len(ks)*3*140,276),(24,20,26)); x=6
    for k in ks:
        fin,today,a=build(k); fin.save(f'art/pixellab-banners-new/final/clan_{k}.png')
        for im in (today,a,fin): im=im.resize((128,256),Image.NEAREST); sh.paste(im,(x,10),im); x+=140
    sh.save('/tmp/claude-0/s/fin.png')
