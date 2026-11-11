"""Locked / empty states: star, 6 empty-slot masks, block glyph (16 px), small lock (8 px). 0 generations.
Run from the repo root: python3 art/pixellab-locked/locked_gen.py"""
import sys, json
sys.path.insert(0, 'art/pixellab-pilots/icons')
import icons_gen as I
from icons_gen import PAL, canvas, finish, P, R, L, E, H
from PIL import Image, ImageDraw
PAL['ink'] = H('#0A0807')
O='art/pixellab-locked/'
def star():
    im,d=canvas(14); P(d,[(6,0),(8,4),(13,5),(9,8),(10,13),(6,10),(3,13),(4,8),(0,5),(5,4)],'gold'); R(d,5,5,7,7,'cream') if 'cream' in PAL else None; return finish(im)
def block():
    im,d=canvas(14); E(d,0,0,13,13,'blood_d'); E(d,2,2,11,11,'ink'); E(d,2,2,11,11,'blood'); E(d,4,4,9,9,'ink'); L(d,[(2,11),(11,2)],'blood_d',2); return finish(im)
def lock8():
    im,d=canvas(6); R(d,0,2,5,5,'gold'); R(d,0,2,5,2,'gold_d'); R(d,1,0,1,2,'steel'); R(d,4,0,4,2,'steel'); R(d,1,0,4,0,'steel'); return finish(im,light=False)
def star_big_fix(): pass
W=(255,255,255,255)
def mk(f):
    im=Image.new('RGBA',(16,16),(0,0,0,0)); d=ImageDraw.Draw(im); f(d); return im
def pl(pts): return lambda d: d.polygon(pts,fill=W)
SLOTS={
 'head': lambda d:(d.polygon([(3,13),(3,6),(5,2),(10,2),(12,6),(12,13),(10,13),(10,10),(5,10),(5,13)],fill=W)),
 'body': pl([(1,3),(5,1),(10,1),(14,3),(13,7),(11,6),(11,14),(4,14),(4,6),(2,7)]),
 'weapon': lambda d:(d.polygon([(13,1),(14,1),(14,3),(7,10),(5,8)],fill=W),d.polygon([(3,7),(8,12),(9,11),(4,6)],fill=W),d.line([(3,11),(1,14)],fill=W,width=2)),
 'legs': lambda d:(d.rectangle((3,1,12,4),fill=W),d.polygon([(3,5),(7,5),(7,14),(4,14)],fill=W),d.polygon([(8,5),(12,5),(11,14),(8,14)],fill=W)),
 'feet': pl([(3,2),(8,2),(8,8),(14,10),(14,14),(3,14)]),
 'bag': lambda d:(d.ellipse((2,5,13,15),fill=W),d.rectangle((5,2,10,5),fill=W),d.rectangle((4,5,11,6),fill=W)),
}
if __name__=='__main__':
    out={'star':star(),'block':block(),'lock8':lock8()}
    for k,im in out.items(): im.save(f'{O}png/{k}.png',optimize=True); print(k,im.size)
    for k,f in SLOTS.items(): mk(f).save(f'{O}masks/slot_{k}.png',optimize=True)
    json.dump({'png':list(out),'masks_16px':['slot_'+k for k in SLOTS]},open(O+'index.json','w'),indent=1)
    LIGHT=(233,224,201,255); DARK=(31,28,35,255); sc=6
    sh=Image.new('RGBA',(760,470),LIGHT); d=ImageDraw.Draw(sh)
    d.text((8,6),'star | block | lock 8x8 at 6x on parchment and dark; below: the six empty-slot masks faded to 35% (tint in code)',fill=(35,31,26))
    x=8
    for k,im in out.items():
        for bg,yy in ((LIGHT,24),(DARK,134)):
            d.rectangle((x,yy,x+100,yy+100),fill=bg,outline=(180,168,140)); sh.alpha_composite(im.resize((im.width*sc,im.height*sc),Image.NEAREST),(x+(100-im.width*sc)//2,yy+(100-im.height*sc)//2))
        x+=112
    for row,(bg,col) in enumerate(((LIGHT,(35,31,26)),(DARK,(233,224,201)))):
        x=8; yy=250+row*110
        for k in SLOTS:
            m=Image.open(f'{O}masks/slot_{k}.png'); t=Image.new('RGBA',m.size,col+(255,)); t.putalpha(m.getchannel('A').point(lambda v:int(v*0.35)))
            d.rectangle((x,yy,x+100,yy+100),fill=bg,outline=(180,168,140)); sh.alpha_composite(t.resize((96,96),Image.NEAREST),(x+2,yy+2)); d.text((x+2,yy+88),k,fill=(110,102,90)); x+=112
    sh.convert('RGB').save('docs/art/boards/locked-states.png')
