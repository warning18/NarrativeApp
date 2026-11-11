"""UI item 4: fight HUD set, 58 glyphs at 16 px (14 drawn + 1 px ink), the originals' outlined two-tone style.
dice kinds 8, rule words 6, spell effects 5, elements 9, condition chips 30. 0 generations.
Run from the repo root: python3 art/pixellab-hud16/hud16_gen.py"""
import sys, os, json
sys.path.insert(0, 'art/pixellab-pilots/icons')
import icons_gen as I
from icons_gen import PAL, canvas, finish, P, R, L, E, H
from PIL import Image, ImageDraw
PAL['ink'] = H('#0A0807'); PAL['cream'] = H('#FAF2DA')
def cv(): return canvas(14)
def o(im): return finish(im)
def px(d,pts,c):
    for x,y in pts: R(d,x,y,x,y,c)
G={}   # family -> [(key, fn)]
def reg(fam):
    def w(fn): G.setdefault(fam,[]).append((fn.__name__.lstrip('_'),fn)); return fn
    return w
# ---------------- die kinds (8) ----------------
@reg('die')
def _attack(): im,d=cv(); P(d,[(11,0),(13,0),(13,2),(6,9),(4,7)],'steel'); P(d,[(2,6),(7,11),(8,10),(3,5)],'gold'); L(d,[(3,10),(1,12)],'wood',2); return o(im)
@reg('die')
def _defend(): im,d=cv(); P(d,[(2,1),(11,1),(11,7),(6,13),(2,7)],'steel'); R(d,6,2,7,10,'gold'); R(d,3,4,10,5,'gold'); return o(im)
@reg('die')
def _heal(): im,d=cv(); R(d,5,1,8,12,'heal'); R(d,1,5,12,8,'heal'); R(d,6,2,7,11,'heal_d') if False else None; return o(im)
@reg('die')
def _mana(): im,d=cv(); P(d,[(6,0),(12,5),(6,13),(1,5)],'void_d'); P(d,[(6,0),(12,5),(6,6),(1,5)],'void'); R(d,4,3,5,4,'cream'); return o(im)
@reg('die')
def _skill(): im,d=cv(); P(d,[(6,0),(8,5),(13,6),(8,8),(6,13),(4,8),(0,6),(4,5)],'gold'); return o(im)
@reg('die')
def _curse(): im,d=cv(); E(d,1,0,12,9,'void'); R(d,2,8,11,11,'void'); R(d,3,4,5,6,'ink'); R(d,8,4,10,6,'ink'); R(d,5,10,5,12,'ink'); R(d,8,10,8,12,'ink'); return o(im)
@reg('die')
def _drain(): im,d=cv(); P(d,[(6,0),(10,7),(10,9),(6,13),(2,9),(2,7)],'blood'); P(d,[(6,4),(8,8),(6,11),(4,8)],'void_d'); return o(im)
@reg('die')
def _blank(): im,d=cv(); R(d,1,1,12,12,'steel_d'); R(d,2,2,11,11,'steel'); L(d,[(3,3),(10,10)],'ink'); L(d,[(10,3),(3,10)],'ink'); return o(im)
# ---------------- rule words (6) ----------------
@reg('rule')
def _cleave(): im,d=cv(); P(d,[(0,12),(0,9),(9,0),(13,0),(13,3)],'steel'); L(d,[(1,11),(11,1)],'bone'); R(d,9,9,12,12,'blood'); return o(im)
@reg('rule')
def _echo(): im,d=cv(); E(d,0,2,8,10,'tide_d'); E(d,5,2,13,10,'tide'); E(d,2,4,6,8,'ink'); E(d,7,4,11,8,'ice'); return o(im)
@reg('rule')
def _pierce(): im,d=cv(); R(d,0,6,11,7,'steel'); P(d,[(9,3),(13,6),(13,7),(9,10)],'bone'); R(d,0,4,2,9,'wood'); return o(im)
@reg('rule')
def _growth(): im,d=cv(); R(d,6,5,7,13,'heal_d'); P(d,[(6,6),(1,2),(1,6)],'heal'); P(d,[(7,4),(12,0),(12,5)],'heal'); return o(im)
@reg('rule')
def _pain(): im,d=cv(); P(d,[(6,0),(8,4),(13,3),(9,7),(12,13),(6,9),(1,13),(4,7),(0,3),(4,4)],'blood'); R(d,5,5,8,8,'ember'); return o(im)
@reg('rule')
def _steady(): im,d=cv(); R(d,1,9,12,12,'steel'); R(d,3,5,10,8,'steel_d'); R(d,5,1,8,4,'bone'); return o(im)
# ---------------- spell effects (5) ----------------
@reg('spell')
def _damage(): im,d=cv(); P(d,[(8,0),(3,8),(6,8),(5,13),(11,5),(7,5)],'ember'); return o(im)
@reg('spell')
def _block(): im,d=cv(); E(d,0,0,13,13,'tide_d'); E(d,2,2,11,11,'tide'); R(d,6,3,7,10,'ice'); return o(im)
@reg('spell')
def _sheal(): im,d=cv(); E(d,1,1,12,12,'heal_d'); R(d,5,3,8,10,'cream'); R(d,3,5,10,8,'cream'); return o(im)
@reg('spell')
def _status(): im,d=cv(); E(d,1,1,12,12,'void_d'); E(d,4,4,9,9,'void'); R(d,6,6,7,7,'ink'); return o(im)
@reg('spell')
def _cleanse(): im,d=cv(); P(d,[(6,0),(7,0),(12,6),(13,9),(7,13),(2,9),(1,6)],'ice'); L(d,[(4,7),(6,10),(10,4)],'tide_d',1); return o(im)
# ---------------- elements (9) ----------------
@reg('element')
def _fire(): im,d=cv(); P(d,[(7,0),(9,3),(11,6),(11,9),(9,13),(5,13),(3,9),(3,6),(5,4),(6,2)],'ember'); P(d,[(7,6),(9,8),(9,11),(7,12),(5,11),(5,8)],'gold'); return o(im)
@reg('element')
def _water(): im,d=cv(); P(d,[(6,0),(10,7),(10,9),(6,13),(2,9),(2,7)],'tide'); R(d,4,8,5,9,'ice'); return o(im)
@reg('element')
def _earth(): im,d=cv(); P(d,[(0,12),(2,5),(6,1),(11,4),(13,12)],'wood'); P(d,[(4,12),(5,7),(8,4),(10,12)],'wood_d'); R(d,5,3,7,4,'ash'); return o(im)
@reg('element')
def _wind(): im,d=cv(); L(d,[(0,3),(9,3)],'ash',2); E(d,8,0,12,4,'ash'); E(d,9,1,11,3,(0,0,0,0)) if False else None; L(d,[(0,7),(11,7)],'bone',2); L(d,[(0,11),(7,11)],'ash',2); R(d,10,5,12,9,'bone'); return o(im)
@reg('element')
def _lightning(): im,d=cv(); P(d,[(8,0),(3,8),(6,8),(5,13),(11,5),(7,5)],'gold'); return o(im)
@reg('element')
def _ice(): im,d=cv(); P(d,[(6,0),(8,5),(13,6),(8,8),(6,13),(4,8),(0,6),(4,5)],'ice'); R(d,5,5,8,8,'tide'); return o(im)
@reg('element')
def _light():
    im,d=cv(); E(d,3,3,10,10,'gold'); E(d,5,5,8,8,'cream')
    for x,y in ((6,0),(6,12),(0,6),(12,6)): R(d,x,y,x+1,y+1,'gold_d')
    return o(im)
@reg('element')
def _void(): im,d=cv(); E(d,0,0,13,13,'void_d'); E(d,3,3,10,10,'void'); E(d,5,5,8,8,'ink'); return o(im)
@reg('element')
def _none(): im,d=cv(); E(d,1,1,12,12,'steel'); d.ellipse((3,3,10,10),fill=(0,0,0,0)); L(d,[(3,10),(10,3)],'steel_d',2); return o(im)

# ---------------- condition chips (30) ----------------
def C(fam):
    return reg(fam)
@C('chip')
def _poison(): im,d=cv(); P(d,[(6,0),(10,7),(10,9),(6,13),(2,9),(2,7)],'heal_d'); R(d,4,8,5,9,'heal'); R(d,7,5,8,6,'heal'); return o(im)
@C('chip')
def _stun():
    im,d=cv()
    for x,y in ((6,0),(0,7),(11,7),(5,11)): P(d,[(x+1,y),(x+2,y+2),(x+3,y+2),(x+2,y+3),(x+2,y+4),(x+1,y+3),(x,y+4),(x,y+2),(x+1,y+2)] if False else [(x+1,y),(x+3,y+2),(x+1,y+4),(x-1,y+2)],'gold')
    return o(im)
@C('chip')
def _weaken(): im,d=cv(); R(d,5,0,8,7,'blood'); P(d,[(0,6),(13,6),(6,13)],'blood'); return o(im)
@C('chip')
def _braced(): im,d=cv(); P(d,[(2,1),(11,1),(11,7),(6,13),(2,7)],'tide'); R(d,6,3,7,9,'ice'); return o(im)
@C('chip')
def _broken(): im,d=cv(); P(d,[(2,1),(11,1),(11,7),(6,13),(2,7)],'steel_d'); L(d,[(6,1),(4,5),(8,8),(6,12)],'ink'); return o(im)
@C('chip')
def _ambush(): im,d=cv(); P(d,[(0,6),(8,3),(8,9)],'blood'); R(d,8,5,13,7,'steel'); R(d,10,3,11,9,'wood') ; return o(im)
@C('chip')
def _dark(): im,d=cv(); E(d,0,0,13,13,'steel_d'); E(d,4,0,17,13,'ink'); R(d,9,3,10,4,'steel'); return o(im)
@C('chip')
def _cramped(): im,d=cv(); R(d,0,0,2,13,'steel_d'); R(d,11,0,13,13,'steel_d'); P(d,[(3,6),(6,3),(6,9)],'gold'); P(d,[(10,6),(7,3),(7,9)],'gold'); return o(im)
@C('chip')
def _high_ground(): im,d=cv(); P(d,[(0,13),(5,3),(8,8),(10,5),(13,13)],'steel'); P(d,[(5,3),(6,5),(4,5)],'bone'); P(d,[(11,0),(13,3),(9,3)],'gold'); return o(im)
@C('chip')
def _shrine(): im,d=cv(); R(d,1,12,12,13,'steel_d'); R(d,2,5,3,12,'bone'); R(d,10,5,11,12,'bone'); R(d,1,3,12,5,'bone'); E(d,5,6,8,10,'gold'); return o(im)
@C('chip')
def _conduct(): im,d=cv(); P(d,[(4,0),(8,5),(8,9),(4,13),(0,9),(0,5)],'tide'); P(d,[(11,0),(7,7),(10,7),(9,13),(13,5),(10,5)],'gold'); return o(im)
@C('chip')
def _shatter(): im,d=cv(); P(d,[(0,3),(6,0),(6,13),(0,10)],'ice'); P(d,[(8,1),(13,4),(13,13),(8,10)],'ice'); L(d,[(6,0),(6,13)],'ink'); R(d,9,5,10,6,'ember'); return o(im)
@C('chip')
def _firestorm(): im,d=cv(); P(d,[(7,0),(9,3),(11,6),(11,9),(9,13),(5,13),(3,9),(3,6),(5,4),(6,2)],'ember'); L(d,[(0,4),(5,2),(13,2)],'ash'); L(d,[(0,10),(9,12)],'ash'); return o(im)
@C('chip')
def _freeze(): im,d=cv(); R(d,1,1,12,12,'ice'); R(d,3,3,10,10,'tide'); R(d,4,4,6,6,'cream'); return o(im)
@C('chip')
def _sandblast(): im,d=cv(); L(d,[(0,4),(10,4)],'ash',2); L(d,[(0,9),(8,9)],'ash',2); px(d,[(11,3),(12,6),(10,8),(12,11),(9,6)],'wood'); return o(im)
@C('chip')
def _eclipse(): im,d=cv(); E(d,0,0,13,13,'gold'); E(d,2,2,11,11,'ink'); R(d,6,0,7,1,'gold'); R(d,6,12,7,13,'gold'); return o(im)
@C('chip')
def _venomous(): im,d=cv(); P(d,[(1,1),(5,1),(3,12)],'bone'); P(d,[(8,1),(12,1),(10,12)],'bone'); R(d,2,3,3,4,'heal'); R(d,9,3,10,4,'heal'); return o(im)
@C('chip')
def _armored(): im,d=cv(); P(d,[(1,13),(1,5),(4,1),(9,1),(12,5),(12,13)],'steel'); R(d,3,6,10,7,'ink'); R(d,6,1,7,5,'steel_d'); return o(im)
@C('chip')
def _skittish(): im,d=cv(); P(d,[(0,6),(7,1),(7,5),(13,5),(13,8),(7,8),(7,12)],'ash'); return o(im)
@C('chip')
def _frenzied(): im,d=cv(); P(d,[(6,0),(8,4),(13,3),(9,7),(12,13),(6,9),(1,13),(4,7),(0,3),(4,4)],'blood'); E(d,5,5,8,8,'gold'); return o(im)
@C('chip')
def _pack_leader(): im,d=cv(); P(d,[(0,12),(0,3),(4,7),(7,1),(10,7),(13,3),(13,12)],'gold'); R(d,0,10,13,12,'gold_d'); R(d,6,5,7,6,'blood'); return o(im)
@C('chip')
def _storm(): im,d=cv(); E(d,0,1,8,8,'steel'); E(d,5,0,13,7,'steel'); R(d,2,5,11,8,'steel'); P(d,[(8,6),(5,10),(7,10),(6,13),(10,8),(8,8)],'gold'); return o(im)
@C('chip')
def _ground(): im,d=cv(); P(d,[(0,12),(2,4),(7,2),(12,5),(13,12)],'wood'); L(d,[(7,2),(6,6),(8,9),(7,12)],'ink'); return o(im)
@C('chip')
def _cold(): im,d=cv(); L(d,[(6,0),(6,13)],'ice',2); L(d,[(0,6),(13,6)],'ice',2); L(d,[(1,1),(12,12)],'tide'); L(d,[(12,1),(1,12)],'tide'); return o(im)
@C('chip')
def _heat(): im,d=cv(); E(d,3,0,10,6,'gold'); L(d,[(0,9),(2,8),(4,10),(6,8),(8,10),(10,8),(13,9)],'ember',2); L(d,[(0,12),(13,12)],'ember_d'); return o(im)
@C('chip')
def _water_a(): im,d=cv(); L(d,[(0,4),(2,2),(4,4),(6,2),(8,4),(10,2),(13,4)],'tide',2); L(d,[(0,9),(2,7),(4,9),(6,7),(8,9),(10,7),(13,9)],'tide_d',2); return o(im)
@C('chip')
def _light_a(): im,d=cv(); P(d,[(6,0),(8,13),(4,13)],'gold'); R(d,5,4,8,8,'cream'); return o(im)
@C('chip')
def _boon(): im,d=cv(); P(d,[(6,0),(12,5),(6,13),(1,5)],'heal'); R(d,5,4,8,9,'cream'); R(d,3,5,10,8,'cream'); return o(im)
@C('chip')
def _hazard(): im,d=cv(); P(d,[(6,0),(13,12),(0,12)],'gold'); R(d,6,4,7,8,'ink'); R(d,6,10,7,11,'ink'); return o(im)
@C('chip')
def _omen(): im,d=cv(); P(d,[(0,6),(6,1),(13,6),(6,12)],'bone'); E(d,4,3,9,9,'void'); R(d,6,5,7,7,'ink'); return o(im)

# chip keys that clash with other families get a prefix by family when saved
RENAME={'chip':{'water_a':'anomaly_water','light_a':'anomaly_light','storm':'anomaly_storm','ground':'anomaly_ground','cold':'anomaly_cold','heat':'anomaly_heat'}}
if __name__=='__main__':
    idx={}; fams=list(G)
    for fam in fams:
        for k,fn in G[fam]:
            im=fn()
            if im is None: print('NONE',fam,k); continue
            assert im.size==(16,16),(fam,k,im.size)
            name=RENAME.get(fam,{}).get(k,k)
            im.save(f'art/pixellab-hud16/png/{fam}_{name}.png',optimize=True); idx.setdefault(fam,[]).append(name)
    json.dump(idx,open('art/pixellab-hud16/index.json','w'),indent=1)
    print({f:len(v) for f,v in idx.items()}, sum(len(v) for v in idx.values()))
    LIGHT=(233,224,201,255); DARK=(31,28,35,255)
    sc=4; cell=16*sc+14; per=14
    rows=sum((len(v)+per-1)//per for v in idx.values())
    sh=Image.new('RGBA',(per*cell+20,rows*(cell+34)+60),LIGHT); d=ImageDraw.Draw(sh); y=8
    for fam,keys in idx.items():
        d.text((8,y),fam,fill=(35,31,26)); y+=14
        for r in range(0,len(keys),per):
            for i,k in enumerate(keys[r:r+per]):
                x=8+i*cell; d.rectangle((x,y,x+cell-6,y+cell-6),fill=DARK if i%2 else (210,198,166,255))
                im=Image.open(f'art/pixellab-hud16/png/{fam}_{k}.png').convert('RGBA'); sh.alpha_composite(im.resize((16*sc,16*sc),Image.NEAREST),(x+4,y+4)); sh.alpha_composite(im,(x+4,y+cell-2)) if False else None
                d.text((x,y+cell-4),k[:11],fill=(110,102,90))
            y+=cell+20
    sh.crop((0,0,sh.width,y+8)).convert('RGB').save('docs/art/boards/hud16-fight-set.png')
