"""Pieces PixelLab could not do, drawn in code: frost corners (crystal branches growing from the top-left corner) and the ash dusting (dark grey specks and a thin soot line). python3 art/pixellab-weather/code_pieces.py"""
import random, math, sys, os
sys.path.insert(0,'art/pixellab-cards'); import build as CB
from PIL import Image
W_=(235,237,233,255);C1=(199,207,204,255);C2=(168,181,178,255);C3=(129,151,150,255)
def frost(seed,S=48):
    r=random.Random(seed);im=Image.new('RGBA',(S,S),(0,0,0,0));px=im.load()
    def put(x,y,c):
        if 0<=x<S and 0<=y<S: px[x,y]=c
    def branch(x,y,ang,ln,depth):
        for i in range(ln):
            x+=math.cos(ang);y+=math.sin(ang);put(int(x),int(y),W_ if depth==0 else C1)
            if depth<2 and i>3 and i%4==0 and r.random()<.8:
                for sgn in (-1,1): branch(x,y,ang+sgn*math.radians(r.choice((50,60,70))),max(3,ln//3),depth+1)
    branch(0,0,math.radians(45),int(S*1.2),0)
    branch(0,0,math.radians(15),int(S*.7),1);branch(0,0,math.radians(75),int(S*.7),1)
    for _ in range(14): put(r.randrange(S),r.randrange(S),C2) if r.random()<.5 and False else None
    for y in range(S):                                 # frosted fill near the corner
        for x in range(S):
            if x+y<S*.5 and r.random()<.75: px[x,y]=C1 if r.random()<.6 else C2
            elif x+y<S*.8 and r.random()<.12: px[x,y]=C2
    return im
def ash(stage,w,seed):
    r=random.Random(seed);h=8 if stage=='dusting' else 16;im=Image.new('RGBA',(w,h),(0,0,0,0));px=im.load()
    dens=0.12 if stage=='dusting' else 0.35
    for x in range(w):
        edge=int(h*(0.35+0.25*math.sin(x/9.0)+0.2*math.sin(x/3.7)))
        for y in range(h-1,max(-1,h-1-edge),-1):
            if r.random()<dens*(1-(h-1-y)/max(edge,1)*0.6): px[x,y]=r.choice(((57,74,80,255),(32,46,55,255),(87,114,119,255),(21,29,40,255)))
    for _ in range(w//10): px[r.randrange(w),r.randrange(max(1,h//2))]=(87,114,119,255)
    return im
if __name__=='__main__':
    F='art/pixellab-weather/final/'
    for i,s in enumerate((11,23)): CB.png8(frost(s),f'{F}frost_corner_{"ab"[i]}.png')
    for st in ('dusting','heavy'):
        for w in (340,300,90): CB.png8(ash(st,w,{'dusting':5,'heavy':9}[st]),f'{F}ash_{st}_{w}.png')
