"""Draw a small lit lantern into the Stair-Chandler's frames by hand (0 generations): reads the raw RGBA rotations, draws the lantern, writes PNG8 (31 colours + transparent index 31, 64x64).
python3 art/pixellab-npc-export/lantern_gen.py   (repo root)"""
import numpy as np, os, sys
from PIL import Image, ImageDraw, ImageFont
O='art/pixellab-npc-export/'; RAW=O+'raw/stair_chandler/Fatter_with_bigger_b/rotations/'
K=(10,8,7,255); C=(79,90,96,255); Y=(232,193,112,255); W=(255,246,224,255); y_=(222,158,65,255); G=(242,193,78,255)
SPR=["...kkk...",
     "..k...k..",
     "kccccccck",
     "kcYYYYYck",
     "kcYWWWYck",
     "kcYWWWYck",
     "kcYWWWYck",
     "kcyYYYyck",
     "kccccccck",
     ".kkkkkkk."]
COL={'k':K,'c':C,'Y':Y,'W':W,'y':y_}
SKIN=(214,150,110,255); SLEEVE=(118,90,64,255)
def block(a,x0,y0,w,h,fill):                    # a hand / forearm block with a 1 px ink outline
    for y in range(y0-1,y0+h+1):
        for x in range(x0-1,x0+w+1):
            if 0<=y<64 and 0<=x<64: a[y,x]=K if (y in (y0-1,y0+h) or x in (x0-1,x0+w)) else fill
def draw(a,x0,y0,arm=None):
    if arm: ax0,ay0,aw,ah=arm; block(a,ax0,ay0,aw,ah,SLEEVE)           # the forearm out to the lantern
    for r,row in enumerate(SPR):
        for c,ch in enumerate(row):
            if ch in COL and 0<=y0+r<64 and 0<=x0+c<64: a[y0+r,x0+c]=COL[ch]
    if arm:                                                                # the hand around the ring
        hx=x0+3; block(a,hx,y0-1,3,2,SKIN)
    # a sparse warm glow beside the glass: a few pixels each side, on empty pixels only
    for r in (3,5,7):
        for x in (x0-1,x0+9):
            y=y0+r
            if 0<=y<64 and 0<=x<64 and a[y,x,3]==0: a[y,x]=(232,193,112,255)
def png8(a,dst):
    mask=a[...,3]<128
    q=Image.fromarray(a[...,:3]).quantize(colors=31,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE); arr=np.array(q); arr[mask]=31
    pal=q.getpalette()[:93]; pal=pal+[0]*(96-len(pal)); out=Image.fromarray(arr,'P'); out.putpalette(pal+[0]*(768-96)); out.save(dst,optimize=True,transparency=31)
POS={'south-west':(12,37,(18,36,5,3)),'south':(7,40,None),'west':(44,37,(41,36,4,3))}
if __name__=='__main__':
    dirs=sys.argv[1].split(',') if len(sys.argv)>1 else list(POS)
    for dname in dirs:
        a=np.array(Image.open(RAW+dname+'.png').convert('RGBA')); x0,y0,arm=POS[dname]; draw(a,x0,y0,arm)
        Image.fromarray(a).save(f'/tmp/claude-0/s/lantern_{dname}.png')
        png8(a,O+'stair_chandler_lantern_'+dname+'.png')
    print('ok')
