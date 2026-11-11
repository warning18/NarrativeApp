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
def plate(base,dark,light):
    im,d=canvas(14)
    for box,c in (((0,1,13,12),dark),((1,0,12,13),dark),((1,1,12,12),base),((1,1,12,1),light),((1,1,1,12),light)): d.rectangle(box,fill=c)
    return im,d
def human():   # a banner with a cross, the people's crest
    im,d=plate(H('#A5302A'),H('#6E1F1B'),H('#D9544D')); R(d,6,3,7,10,'gold'); R(d,4,5,9,6,'gold'); return finish(im)
def elf():     # a leaf
    im,d=plate(H('#226565'),H('#143F3F'),H('#4FB0B0')); P(d,[(3,10),(3,6),(6,3),(10,3),(10,7),(7,10)],'cream'); L(d,[(3,10),(9,4)],'tide_d'); return finish(im)
def dwarf():   # an anvil
    im,d=plate(H('#6B6356'),H('#45403A'),H('#A8A194')); R(d,3,4,10,6,'cream'); R(d,2,4,4,5,'cream'); R(d,5,7,8,8,'cream'); R(d,4,9,9,10,'cream'); return finish(im)
def orc():     # a tusk pair
    im,d=plate(H('#4C6B34'),H('#2F4521'),H('#7DBE6A')); P(d,[(3,3),(5,3),(5,7),(4,10),(3,7)],'cream'); P(d,[(8,3),(10,3),(10,7),(9,10),(8,7)],'cream'); return finish(im)
def voidkin(): # a void gem
    im,d=plate(H('#3B2F63'),H('#221B3D'),H('#6A4FB0')); P(d,[(6,2),(10,6),(6,11),(3,6)],'void'); R(d,6,4,7,8,'cream'); return finish(im)
RACES={'human':human,'elf':elf,'dwarf':dwarf,'orc':orc,'voidkin':voidkin}
def native(path):
    im=Image.open(path).convert('RGBA'); return im.resize((16,16),Image.NEAREST)
if __name__=='__main__':
    pal,_=HG.build_palette()
    out={'races':[],'professions':[]}
    for k,fn in RACES.items(): fn().save(f'{O}png/race_{k}.png',optimize=True); out['races'].append(k)
    for k in ('cleric','mage','ranger','rogue','warrior'):
        im=HG.snap(native(f'assets/visuals/professions/{k}.png'),pal); im.save(f'{O}png/profession_{k}.png',optimize=True); out['professions'].append(k)
    json.dump(out,open(O+'index.json','w'),indent=1)
    LIGHT=(233,224,201); sc=8
    sh=Image.new('RGB',(5*150+10,4*150+60),LIGHT); d=ImageDraw.Draw(sh)
    rows=[('races today',[native(f'assets/visuals/races/{k}.png') for k in RACES]),('races proposal',[Image.open(f'{O}png/race_{k}.png').convert('RGBA') for k in RACES]),
          ('professions today',[native(f'assets/visuals/professions/{k}.png') for k in out['professions']]),('professions harmonised',[Image.open(f'{O}png/profession_{k}.png').convert('RGBA') for k in out['professions']])]
    y=8
    for lab,ims in rows:
        d.text((8,y),lab,fill=(35,31,26)); y+=16
        for i,im in enumerate(ims): sh.paste(im.resize((16*sc,16*sc),Image.NEAREST),(8+i*150,y),im.resize((16*sc,16*sc),Image.NEAREST))
        y+=134
    sh.save('docs/art/boards/race-profession-icons.png'); print(sh.size)
