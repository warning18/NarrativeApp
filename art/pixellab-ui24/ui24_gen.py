"""UI item 3: nav, stats-strip and header glyphs at 24 px (outlined, two-tone, original-icon style)
plus one-colour masks (white on transparent, tint in code). 0 generations, PIL only.
Run from the repo root: python3 art/pixellab-ui24/ui24_gen.py"""
import sys, os, json
sys.path.insert(0, 'art/pixellab-pilots/icons')
import icons_gen as I
from icons_gen import PAL, canvas, finish, P, R, L, E, H
from PIL import Image, ImageDraw
PAL['ink'] = H('#0A0807')
N = 22  # drawn area; finish() adds the 1 px ink ring -> 24
def cv(): return canvas(N)
def out(im): return finish(im)

# ---------------- nav bar (8) ----------------
def story():  # open book
    im,d=cv(); P(d,[(1,4),(10,6),(10,19),(1,17)],'bone'); P(d,[(21,4),(12,6),(12,19),(21,17)],'bone')
    R(d,10,6,11,19,'wood_d'); 
    for y in (8,11,14): L(d,[(3,y),(8,y+1)],'steel'); L(d,[(14,y+1),(19,y)],'steel')
    P(d,[(1,17),(10,19),(10,21),(1,19)],'wood'); P(d,[(21,17),(12,19),(12,21),(21,19)],'wood'); return out(im)
def journey():  # a road to the horizon, with a flag
    im,d=cv(); P(d,[(9,8),(13,8),(20,21),(2,21)],'steel'); P(d,[(9,8),(13,8),(12,10),(10,10)],'steel_d')
    for y,x in ((12,10),(15,10),(18,10)): R(d,x,y,x+1,y+1,'bone')
    R(d,17,0,18,10,'wood'); P(d,[(19,1),(22,3),(19,6)],'blood'); return out(im)
def character():
    im,d=cv(); E(d,6,1,15,10,'bone'); P(d,[(2,21),(2,16),(5,12),(16,12),(19,16),(19,21)],'steel'); R(d,9,12,12,14,'bone'); return out(im)
def camp():
    im,d=cv(); P(d,[(11,0),(15,6),(18,11),(18,16),(14,21),(8,21),(4,16),(4,11),(8,7),(9,3)],'ember')
    P(d,[(11,9),(14,13),(14,18),(11,20),(8,18),(8,13)],'gold'); L(d,[(1,21),(20,17)],'wood',2); L(d,[(1,17),(20,21)],'wood',2); return out(im)
def ship():
    im,d=cv(); R(d,10,0,11,15,'wood_d'); P(d,[(12,1),(20,13),(12,13)],'bone'); P(d,[(9,3),(9,13),(2,13)],'ash')
    P(d,[(0,15),(21,15),(17,21),(4,21)],'wood'); R(d,3,15,18,16,'wood_d'); return out(im)
def other():
    im,d=cv()
    for x in (1,8,15): R(d,x,8,x+4,12,'steel')
    return out(im)
def play():
    im,d=cv(); P(d,[(4,1),(19,11),(4,20)],'gold'); P(d,[(4,1),(19,11),(4,11)],'gold_d'); return out(im)
def data():
    im,d=cv()
    for y in (1,8,15): E(d,2,y,19,y+5,'steel'); R(d,2,y+3,19,y+4,'steel_d') if False else None
    for y in (1,8,15): R(d,2,y+2,19,y+4,'steel'); E(d,2,y,19,y+4,'steel')
    for y in (4,11,18): R(d,13,y,15,y+1,'tide')
    return out(im)
# ---------------- stats strip (11) ----------------
def level():
    im,d=cv(); P(d,[(2,1),(19,1),(19,12),(10,21),(2,12)],'steel'); R(d,9,3,11,16,'gold'); R(d,5,7,15,9,'gold'); return out(im)
def sun(c='gold',dc='gold_d'):
    im,d=cv(); E(d,5,5,16,16,c)
    for x,y in ((9,0),(9,18),(0,9),(18,9)): R(d,x,y,x+2,y+2,dc)
    for x,y in ((3,3),(15,3),(3,15),(15,15)): R(d,x,y,x+1,y+1,dc)
    return im
def day(): return out(sun())
def dawn():
    im,d=cv(); E(d,3,8,18,23,'gold')
    d.rectangle((0,15,21,21),fill=(0,0,0,0)); R(d,0,15,21,16,'ember_d')
    for x,y in ((9,1),(1,7),(18,7),(4,3),(15,3)): R(d,x,y,x+1,y+2,'gold_d'); 
    return out(im)
def dusk():
    im,d=cv(); E(d,3,8,18,23,'ember'); d.rectangle((0,15,21,21),fill=(0,0,0,0)); R(d,0,15,21,16,'blood_d')
    for x,y in ((9,1),(1,7),(18,7)): R(d,x,y,x+1,y+2,'ember_d')
    return out(im)
def night():
    im,d=cv(); E(d,2,1,19,18,'ice'); d.ellipse((8,0,24,15),fill=(0,0,0,0)); R(d,16,17,17,18,'ice'); return out(im)
def heart():
    im,d=cv(); E(d,1,2,11,12,'blood'); E(d,10,2,20,12,'blood'); P(d,[(1,9),(20,9),(10,20)],'blood'); R(d,4,4,6,6,'ember'); return out(im)
def mana():
    im,d=cv(); P(d,[(10,0),(17,11),(17,15),(10,21),(3,15),(3,11)],'tide'); R(d,6,12,8,15,'ice'); return out(im)
def gold():
    im,d=cv(); E(d,1,1,20,20,'gold'); E(d,4,4,17,17,'gold_d'); R(d,9,6,11,15,'gold'); R(d,7,8,13,9,'gold'); return out(im)
def rations():
    im,d=cv(); E(d,6,0,19,10,'ember_d'); P(d,[(2,19),(2,15),(8,8),(14,12)],'ember_d'); L(d,[(3,18),(10,11)],'wood',3); R(d,0,17,3,20,'bone'); E(d,8,2,16,7,'ember'); return out(im)
def quest():
    im,d=cv(); R(d,3,2,17,19,'bone'); E(d,0,0,5,4,'ash'); E(d,15,17,20,21,'ash')
    for y in (6,9,12,15): L(d,[(6,y),(14,y)],'steel_d'); 
    return out(im)
# ---------------- header (4) ----------------
def settings():
    im,d=cv(); E(d,3,3,18,18,'steel')
    for x,y in ((9,0),(9,18),(0,9),(18,9)): R(d,x,y,x+2,y+2,'steel')
    for x,y in ((2,2),(16,2),(2,16),(16,16)): R(d,x,y,x+2,y+2,'steel')
    E(d,7,7,14,14,'ink'); return out(im)
def home():
    im,d=cv(); R(d,3,10,18,20,'bone'); P(d,[(10,0),(21,10),(0,10)],'wood'); R(d,8,13,12,20,'wood_d'); return out(im)
def map_():
    im,d=cv(); P(d,[(0,3),(6,1),(14,4),(21,2),(21,18),(14,20),(6,17),(0,19)],'bone')
    L(d,[(6,1),(6,17)],'steel'); L(d,[(14,4),(14,20)],'steel'); R(d,9,8,11,10,'tide'); return out(im)
def info():
    im,d=cv(); E(d,1,1,20,20,'tide'); R(d,9,9,11,16,'ice'); R(d,9,5,11,7,'ice'); return out(im)

COLOUR = {'nav': [('story',story),('journey',journey),('character',character),('camp',camp),('ship',ship),('other',other),('play',play),('data',data)],
 'stats': [('level',level),('time_dawn',dawn),('time_day',day),('time_dusk',dusk),('time_night',night),('hp',heart),('mana',mana),('gold',gold),('rations',rations),('quest',quest)],
 'header': [('settings',settings),('home',home),('map',map_),('info',info)]}

# ---------------- one-colour masks (white on transparent, no outline) ----------------
def mk(fn):
    im=Image.new('RGBA',(24,24),(0,0,0,0)); d=ImageDraw.Draw(im); fn(d); return im
W=(255,255,255,255)
def poly(pts): return lambda d: d.polygon(pts,fill=W)
MASKS={
 'chevron_right': poly([(8,3),(11,3),(18,12),(11,21),(8,21),(14,12)]),
 'chevron_left': poly([(16,3),(13,3),(6,12),(13,21),(16,21),(10,12)]),
 'expand_more': poly([(3,8),(3,11),(12,18),(21,11),(21,8),(12,14)]),
 'expand_less': poly([(3,16),(3,13),(12,6),(21,13),(21,16),(12,10)]),
 'close': lambda d:(d.line([(5,5),(18,18)],fill=W,width=3),d.line([(18,5),(5,18)],fill=W,width=3)),
 'add': lambda d:(d.rectangle((10,4,13,19),fill=W),d.rectangle((4,10,19,13),fill=W)),
 'remove': lambda d:d.rectangle((4,10,19,13),fill=W),
 'check': poly([(3,12),(5,10),(9,14),(19,5),(21,7),(9,18)]),
 'arrow_back': lambda d:(d.rectangle((8,10,20,13),fill=W),d.polygon([(11,4),(2,11),(11,19)],fill=W)),
 'arrow_forward': lambda d:(d.rectangle((3,10,15,13),fill=W),d.polygon([(12,4),(21,11),(12,19)],fill=W)),
}
def p8(im,path):
    q=im.convert('RGBA').quantize(64,method=Image.Quantize.FASTOCTREE,dither=Image.NONE) if False else im
    im.save(path,optimize=True)
if __name__=='__main__':
    os.makedirs('art/pixellab-ui24/png',exist_ok=True); os.makedirs('art/pixellab-ui24/masks',exist_ok=True)
    idx={}
    for fam,lst in COLOUR.items():
        for k,fn in lst:
            im=fn(); assert im.size==(24,24),(k,im.size); im.save(f'art/pixellab-ui24/png/{fam}_{k}.png',optimize=True); idx.setdefault(fam,[]).append(k)
    for k,fn in MASKS.items(): mk(fn).save(f'art/pixellab-ui24/masks/{k}.png',optimize=True)
    json.dump({'colour_24px':idx,'masks_24px':list(MASKS)},open('art/pixellab-ui24/index.json','w'),indent=1)
    # sheet
    LIGHT=(233,224,201,255); DARK=(31,28,35,255)
    rows=[(f,[ (k,Image.open(f'art/pixellab-ui24/png/{f}_{k}.png')) for k,_ in l]) for f,l in COLOUR.items()]
    sh=Image.new('RGBA',(1350,660),LIGHT); d=ImageDraw.Draw(sh); y=8
    for fam,lst in rows:
        d.text((8,y),fam,fill=(35,31,26)); y+=16
        for bgi,bg in enumerate((LIGHT,DARK)):
            for i,(k,im) in enumerate(lst):
                x=8+i*96; d.rectangle((x,y,x+90,y+90),fill=bg); sh.alpha_composite(im.resize((72,72),Image.NEAREST),(x+9,y+9))
                x2=8+len(lst)*96+i*0
            sx=8+len(lst)*96+10
            for i,(k,im) in enumerate(lst): sh.alpha_composite(im,(sx+i*28,y+30))   # 1x as shipped
        y+=100
        for i,(k,im) in enumerate(lst): d.text((8+i*96,y-8),k,fill=(110,102,90))
        y+=14
    d.text((8,y),'one-colour masks (white, tint in code) at 1x and 3x on three tints',fill=(35,31,26)); y+=18
    for i,k in enumerate(MASKS):
        m=Image.open(f'art/pixellab-ui24/masks/{k}.png')
        for j,col in enumerate(((168,78,18),(34,101,101),(35,31,26))):
            t=Image.new('RGBA',m.size,col+(255,)); t.putalpha(m.getchannel('A')); sh.alpha_composite(t.resize((48,48),Image.NEAREST),(8+i*96,y+j*52))
    sh=sh.crop((0,0,1350,y+170)); sh.convert('RGB').save('docs/art/boards/ui24-nav-stats-header.png'); print(sh.size)
