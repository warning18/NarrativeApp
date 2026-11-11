"""Race icons (one coherent set) and profession icons (harmonised): 0 generations. Run from the repo root.
Races: one rounded-square plate (the originals' 'uncommon' container) in the race's colour, an outlined cream glyph.
Professions: the originals snapped to the shared palette and one ink (harmonised); plus an optional diamond-plate variant."""
import sys, json, os
sys.path.insert(0,'art/pixellab-pilots/icons')
import icons_gen as I
from icons_gen import PAL, canvas, finish, P, R, L, E, H
import harmonise_gen as HG
from PIL import Image, ImageDraw
PAL['ink']=H('#0A0807'); PAL['cream']=H('#FAF2DA')
O='art/pixellab-race-icons/'
def plate(base):
    """flat rounded square in the race/calling colour; finish() adds the bevel (top-left light, bottom-right shade) and the ink ring, as on every other icon"""
    im,d=canvas(14)
    for box in ((0,1,13,12),(1,0,12,13)): d.rectangle(box,fill=base)
    return im,d
def diamond(base):
    im,d=canvas(14); d.polygon([(6,0),(13,6),(6,13),(0,6)],fill=base); return im,d
def human():
    im,d=plate(H('#B03A33')); R(d,6,3,7,10,'gold'); R(d,4,5,9,6,'gold'); return finish(im)
def elf():
    im,d=plate(H('#2B7A7A')); P(d,[(3,10),(3,6),(6,3),(10,3),(10,7),(7,10)],'cream'); L(d,[(3,10),(9,4)],'tide_d'); return finish(im)
def dwarf():
    im,d=plate(H('#7A7264')); R(d,3,4,10,6,'cream'); R(d,2,4,4,5,'cream'); R(d,5,7,8,8,'cream'); R(d,4,9,9,10,'cream'); return finish(im)
def orc():
    im,d=plate(H('#4F7A36')); P(d,[(3,3),(5,3),(5,7),(4,10),(3,7)],'cream'); P(d,[(8,3),(10,3),(10,7),(9,10),(8,7)],'cream'); return finish(im)
def voidkin():
    im,d=plate(H('#4A3C80')); P(d,[(6,2),(10,6),(6,11),(3,6)],'void'); R(d,6,4,7,8,'cream'); return finish(im)
RACES={'human':human,'elf':elf,'dwarf':dwarf,'orc':orc,'voidkin':voidkin}
CALL_COL={'warrior':'#B5601C','mage':'#3556A0','ranger':'#7A5230','rogue':'#4A4558','cleric':'#B8862A'}
def glyph(kind,d):
    if kind=='warrior':   # sword and shield
        P(d,[(2,3),(8,3),(8,8),(5,11),(2,8)],'cream'); R(d,4,4,5,8,'steel_d'); P(d,[(9,1),(11,1),(11,3),(6,8),(5,7)],'steel')
    elif kind=='mage':    # staff with a gem
        L(d,[(3,11),(9,5)],'cream',2); P(d,[(9,1),(12,4),(9,7),(7,4)],'void')
    elif kind=='ranger':  # bow and arrow
        d.arc((1,1,9,12),270,90,fill=PAL['cream'],width=2); L(d,[(5,1),(5,12)],'steel'); L(d,[(3,6),(12,6)],'cream'); P(d,[(10,4),(13,6),(10,8)],'cream')
    elif kind=='rogue':   # crossed daggers
        L(d,[(2,2),(11,11)],'cream',2); L(d,[(11,2),(2,11)],'cream',2); R(d,6,6,7,7,'steel')
    elif kind=='cleric':  # a four-pointed star
        P(d,[(6,0),(8,5),(13,6),(8,8),(6,13),(4,8),(0,6),(4,5)],'cream')
def calling(kind,shape):
    im,d=(plate if shape=='plate' else diamond)(H(CALL_COL[kind])); glyph(kind,d); return finish(im)
CALLS=('warrior','mage','ranger','rogue','cleric')
def native(path):
    im=Image.open(path).convert('RGBA'); return im.resize((16,16),Image.NEAREST)
if __name__=='__main__':
    pal,_=HG.build_palette(); out={'races':[],'callings_plate':[],'callings_diamond':[],'callings_glyph':[]}
    for k,fn in RACES.items(): fn().save(f'{O}png/race_{k}.png',optimize=True); out['races'].append(k)
    for k in CALLS:
        calling(k,'plate').save(f'{O}png/profession_{k}_plate.png',optimize=True); out['callings_plate'].append(k)
        calling(k,'diamond').save(f'{O}png/profession_{k}_diamond.png',optimize=True); out['callings_diamond'].append(k)
        HG.snap(native(f'assets/visuals/professions/{k}.png'),pal).save(f'{O}png/profession_{k}.png',optimize=True); out['callings_glyph'].append(k)
    json.dump(out,open(O+'index.json','w'),indent=1)
    comp=[('ui24 nav_character','art/pixellab-ui24/png/nav_character.png'),('ui24 stats_hp','art/pixellab-ui24/png/stats_hp.png'),('hud die_attack','art/pixellab-hud16/png/die_attack.png'),('hud element_fire','art/pixellab-hud16/png/element_fire.png'),('hud chip_poison','art/pixellab-hud16/png/chip_poison.png'),('locked star','art/pixellab-locked/png/star.png'),('skill (harmonised)','art/pixellab-icons/harmonised/skills/fireball.png')]
    LIGHT=(233,224,201); DARK=(31,28,35)
    rows=[('today: races',[native(f'assets/visuals/races/{k}.png') for k in RACES]),
          ('revised races',[Image.open(f'{O}png/race_{k}.png').convert('RGBA') for k in RACES]),
          ('today: callings',[native(f'assets/visuals/professions/{k}.png') for k in CALLS]),
          ('callings A: same plate',[Image.open(f'{O}png/profession_{k}_plate.png').convert('RGBA') for k in CALLS]),
          ('callings B: diamond plate',[Image.open(f'{O}png/profession_{k}_diamond.png').convert('RGBA') for k in CALLS]),
          ('callings C: symbols alone, harmonised',[Image.open(f'{O}png/profession_{k}.png').convert('RGBA') for k in CALLS]),
          ('new set for comparison (ui24, hud, locked, skill)',[Image.open(f).convert('RGBA') for _,f in comp])]
    cell=84; W=7*cell+20
    sh=Image.new('RGB',(2*W+20,len(rows)*(cell+30)+20),LIGHT); d=ImageDraw.Draw(sh)
    for half,bg in enumerate((LIGHT,DARK)):
        x0=10+half*(W+10); d.rectangle((x0-6,0,x0+W,sh.height),fill=bg)
        y=8
        for lab,ims in rows:
            d.text((x0,y),lab,fill=(35,31,26) if half==0 else (233,224,201)); y+=16
            for i,im in enumerate(ims):
                x=x0+i*cell
                big=im.resize((im.width*3,im.height*3),Image.NEAREST); sh.paste(big,(x,y),big)      # 3x
                sh.paste(im,(x+im.width*3+4,y+2),im)                                                  # real size
            y+=cell+14
    sh.save('docs/art/boards/race-profession-icons.png'); print(sh.size)
