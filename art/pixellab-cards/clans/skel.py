"""Skeletons for the clan backdrops, 104x76 art px: a dark gradient in the clan's colour and the clan's sign large and faint in the middle.
python3 art/pixellab-cards/clans/skel.py"""
import math
from PIL import Image, ImageDraw
CLANS={'dominion':'#2F62B5','crows':'#B0303F','compact':'#B86B3C','mire':'#3F8F5A','vigil':'#8A8F98','penitents':'#CBB68E','wayfarer':'#7A5A44'}
def rgb(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))
def mix(a,b,t): return tuple(int(x+(y-x)*t) for x,y in zip(a,b))
INK=(16,20,31)
def sign(g,k,c,w=3):
    cx,cy=52,38
    if k=='dominion':
        g.ellipse([cx-5,cy-24,cx+5,cy-16],outline=c,width=2); g.polygon([(cx-9,cy-14),(cx+9,cy-14),(cx+12,cy-8),(cx-12,cy-8)],fill=c)
        g.rectangle([cx-10,cy-8,cx+10,cy+16],outline=c,width=3); g.rectangle([cx-12,cy+16,cx+12,cy+22],fill=c); g.polygon([(cx,cy-2),(cx+4,cy+6),(cx,cy+11),(cx-4,cy+6)],fill=c)
    if k=='crows':
        g.ellipse([cx-26,cy-26,cx+26,cy+26],outline=c,width=3); g.ellipse([cx-14,cy-14,cx+14,cy+14],outline=c,width=2)
        g.line([(cx,cy-20),(cx,cy+20)],fill=c,width=4); g.ellipse([cx-4,cy-26,cx+4,cy-18],outline=c,width=2); g.line([(cx-9,cy-10),(cx+9,cy-10)],fill=c,width=3); g.arc([cx-18,cy-6,cx+18,cy+26],10,170,fill=c,width=4)
    if k=='compact':
        g.polygon([(cx-20,cy+4),(cx+22,cy+4),(cx+22,cy+10),(cx+12,cy+12),(cx+8,cy+22),(cx-8,cy+22),(cx-6,cy+12),(cx-20,cy+10)],fill=c); g.polygon([(cx+22,cy+4),(cx+30,cy+7),(cx+22,cy+8)],fill=c)
        g.line([(cx-14,cy-4),(cx+10,cy-24)],fill=c,width=4); g.rectangle([cx+4,cy-30,cx+22,cy-18],fill=c)
    if k=='mire':
        g.polygon([(cx,cy-26),(cx+12,cy-12),(cx+6,cy+2),(cx,cy+6),(cx-6,cy-6),(cx-10,cy-14)],fill=c); g.line([(cx,cy-24),(cx,cy+8)],fill=INK,width=1)
        for i,y in enumerate((cy+12,cy+19,cy+26)):
            pts=[(x,y+2.5*math.sin((x+i*5)/4)) for x in range(cx-26,cx+27,2)]; g.line(pts,fill=c,width=3)
    if k=='vigil':
        g.polygon([(cx-28,cy),(cx-14,cy-12),(cx,cy-16),(cx+14,cy-12),(cx+28,cy),(cx+14,cy+12),(cx,cy+16),(cx-14,cy+12)],outline=c,width=3)
        g.ellipse([cx-10,cy-10,cx+10,cy+10],fill=c); g.ellipse([cx-4,cy-4,cx+4,cy+4],fill=INK)
    if k=='penitents':
        g.polygon([(cx,cy-28),(cx+10,cy-14),(cx+8,cy-2),(cx,cy+2),(cx-8,cy-2),(cx-10,cy-14)],fill=c); g.ellipse([cx-3,cy-14,cx+3,cy-8],fill=INK)
        g.rectangle([cx-3,cy+4,cx+3,cy+26],fill=c); g.rectangle([cx-11,cy+10,cx+11,cy+16],fill=c)
    if k=='wayfarer':
        g.polygon([(cx-3,cy-14),(cx+3,cy-14),(cx+30,cy+30),(cx-30,cy+30)],fill=c)
        for y,wd in ((cy-4,1),(cy+8,2),(cy+20,4)): g.rectangle([cx-wd,y,cx+wd,y+3],fill=INK)
def backdrop(k):
    col=rgb(CLANS[k]); im=Image.new('RGBA',(104,76)); g=ImageDraw.Draw(im)
    for y in range(76):
        t=y/75; c=mix(mix(INK,col,0.42),mix(INK,col,0.10),t); g.line([(0,y),(104,y)],fill=c+(255,))
    sign(g,k,mix(mix(INK,col,0.22),col,0.2)+(255,)); return im
if __name__=='__main__':
    import os; os.makedirs('art/pixellab-cards/clans/skel',exist_ok=True)
    W=Image.new('RGBA',(7*212,160),(40,40,50))
    for i,k in enumerate(CLANS):
        im=backdrop(k); im.save(f'art/pixellab-cards/clans/skel/{k}.png'); W.paste(im.resize((208,152),0),(i*212+2,4))
    W.save('art/pixellab-cards/clans/skel/sheet.png')
