"""The 33 Journey glyphs (lib/widgets/journey_glyph.dart: Material today) as original-style world icons, 16x16, hand-drawn; and the final gap set
(5 elements, 5 skills, 2 items) staged as drop-ins. 0 generations. Run from the repo root: python3 art/pixellab-journey/journey_gen.py"""
import sys, json, os, shutil
sys.path.insert(0,'art/pixellab-pilots/icons')
import icons_gen as I
from icons_gen import PAL, canvas, finish, P, R, L, E, H
from PIL import Image, ImageDraw, ImageFont
PAL['ink']=H('#0A0807'); PAL['cream']=H('#FAF2DA')
O='art/pixellab-journey/'; M='art/pixellab-pilots/icons/mix/'
def cv(): return canvas(14)
def o(im): return finish(im)
G={}
def g(key,material):
    def w(fn): G[key]=(fn,material); return fn
    return w
@g('story','auto_stories_outlined')
def _(): im,d=cv(); P(d,[(0,3),(6,5),(6,13),(0,11)],'bone'); P(d,[(13,3),(7,5),(7,13),(13,11)],'bone'); R(d,6,5,7,13,'wood_d'); [L(d,[(1,5+i*2),(5,6+i*2)],'steel') for i in range(3)]; return o(im)
@g('mainquest','flag_outlined')
def _(): im,d=cv(); R(d,1,0,2,13,'wood'); P(d,[(3,1),(12,1),(9,4),(12,7),(3,7)],'blood'); return o(im)
@g('cave','landscape_outlined')
def _(): return Image.open(M+'new_mountains.png').convert('RGBA')
@g('ruin','account_balance_outlined')
def _(): im,d=cv(); P(d,[(6,0),(13,4),(0,4)],'bone'); [R(d,x,5,x+1,10,'bone') for x in (1,5,9)]; R(d,0,11,13,13,'steel'); return o(im)
@g('forest','park_outlined')
def _(): return Image.open(M+'new_tree.png').convert('RGBA')
@g('sea','waves')
def _(): return Image.open(M+'new_waves.png').convert('RGBA')
@g('desert','wb_sunny_outlined')
def _():
    im,d=cv(); E(d,3,3,10,10,'gold'); R(d,5,5,6,6,'cream')
    for x,y in ((6,0),(6,12),(0,6),(12,6)): R(d,x,y,x+1,y+1,'gold_d')
    for x,y in ((2,2),(10,2),(2,10),(10,10)): R(d,x,y,x,y,'gold_d')
    return o(im)
@g('compass','explore_outlined')
def _(): return Image.open(M+'new_compass.png').convert('RGBA')
@g('shipfight','directions_boat_filled_outlined')
def _(): im,d=cv(); P(d,[(0,8),(13,8),(10,13),(3,13)],'wood'); R(d,6,1,7,8,'wood_d'); P(d,[(8,1),(13,7),(8,7)],'blood'); return o(im)
@g('beast','pets')
def _(): return Image.open(M+'new_paw.png').convert('RGBA')
@g('wisp','blur_on')
def _(): im,d=cv(); E(d,3,3,10,10,'void'); E(d,5,5,8,8,'cream'); [R(d,x,y,x+1,y+1,'void_d') for x,y in ((0,1),(11,0),(12,10),(1,11))]; return o(im)
@g('warden','shield_outlined')
def _(): im,d=cv(); P(d,[(2,1),(11,1),(11,7),(6,13),(2,7)],'steel'); R(d,6,2,7,10,'gold'); R(d,3,4,10,5,'gold'); return o(im)
@g('archer','gps_fixed')
def _(): im,d=cv(); E(d,1,1,12,12,'blood'); E(d,3,3,10,10,'cream'); E(d,5,5,8,8,'blood'); R(d,6,0,7,13,'ink'); R(d,0,6,13,7,'ink'); R(d,6,5,7,8,'blood'); return o(im)
@g('fighter','sports_martial_arts')
def _(): im,d=cv(); R(d,2,4,10,11,'bone'); [R(d,x,2,x+1,5,'bone') for x in (2,4,6,8)]; R(d,10,6,12,9,'bone'); R(d,2,10,10,12,'ash'); L(d,[(5,5),(5,8)],'steel'); return o(im)
@g('challenge','casino')
def _():
    im,d=cv(); R(d,1,1,12,12,'bone')
    for x,y in ((3,3),(9,3),(6,6),(3,9),(9,9)): R(d,x,y,x+1,y+1,'ink')
    return o(im)
@g('check_default','casino_outlined')
def _(): return G['challenge'][0]()
@g('strength','fitness_center')
def _(): im,d=cv(); R(d,5,5,8,8,'steel'); R(d,1,2,3,11,'steel_d'); R(d,10,2,12,11,'steel_d'); R(d,3,3,4,10,'steel'); R(d,9,3,10,10,'steel'); return o(im)
@g('dexterity','sports_gymnastics')
def _(): im,d=cv(); E(d,5,0,8,3,'bone'); L(d,[(6,4),(6,8)],'bone',2); L(d,[(1,2),(6,5),(12,3)],'bone'); L(d,[(6,8),(2,12)],'bone'); L(d,[(6,8),(11,12)],'bone'); return o(im)
@g('constitution','favorite_border')
def _(): im,d=cv(); E(d,1,1,7,7,'blood'); E(d,6,1,12,7,'blood'); P(d,[(1,5),(12,5),(6,12)],'blood'); R(d,4,4,5,5,'ember'); return o(im)
@g('intelligence','psychology_outlined')
def _(): im,d=cv(); P(d,[(3,12),(2,6),(5,1),(10,1),(12,5),(10,8),(10,12)],'bone'); E(d,5,3,9,7,'void'); R(d,7,4,8,5,'cream'); return o(im)
@g('wisdom','visibility_outlined')
def _(): return Image.open(M+'new_eye.png').convert('RGBA')
@g('charisma','record_voice_over_outlined')
def _(): im,d=cv(); E(d,1,2,6,8,'bone'); P(d,[(1,9),(6,9),(7,13),(0,13)],'steel'); L(d,[(8,3),(9,4),(8,6)],'gold'); L(d,[(10,2),(12,4),(10,7)],'gold'); return o(im)
@g('perception','search')
def _(): im,d=cv(); E(d,0,0,8,8,'ice'); E(d,2,2,6,6,'tide'); L(d,[(8,8),(12,12)],'wood',2); return o(im)
@g('forge','hardware_outlined')
def _(): im,d=cv(); R(d,5,5,7,13,'wood'); R(d,1,1,11,5,'steel'); R(d,1,1,11,1,'bone'); return o(im)
@g('apothecary','science_outlined')
def _(): im,d=cv(); R(d,5,0,8,4,'bone'); P(d,[(5,4),(8,4),(12,12),(1,12)],'ice'); P(d,[(4,8),(9,8),(12,12),(1,12)],'heal'); return o(im)
@g('arcane','auto_awesome')
def _(): im,d=cv(); P(d,[(5,0),(7,5),(12,6),(7,8),(5,13),(3,8),(0,6),(3,5)],'gold'); R(d,10,0,11,1,'cream'); R(d,11,10,12,11,'cream'); return o(im)
@g('harbor','anchor')
def _(): return I.anchor()
@g('shop','storefront_outlined')
def _():
    im,d=cv(); R(d,1,6,12,12,'bone'); [R(d,x,1,x+1,5,'blood' if (x//2)%2==0 else 'cream') for x in range(0,12,2)]; R(d,1,1,12,1,'blood'); R(d,5,8,8,12,'wood_d'); return o(im)
@g('signpost','signpost_outlined')
def _(): im,d=cv(); R(d,6,0,7,13,'wood'); P(d,[(1,2),(10,2),(12,4),(10,6),(1,6)],'wood_d'); P(d,[(3,7),(12,7),(12,10),(3,10),(1,8)],'wood'); return o(im)
@g('camp','local_fire_department_outlined')
def _(): return I.flame()
@g('rest','bedtime_outlined')
def _(): im,d=cv(); E(d,2,0,13,11,'ice'); d.ellipse((6,-2,16,8),fill=(0,0,0,0)); return o(im)
@g('talk','chat_bubble_outline')
def _(): im,d=cv(); P(d,[(1,1),(12,1),(12,8),(7,8),(3,12),(4,8),(1,8)],'bone'); [R(d,x,4,x+1,5,'steel_d') for x in (3,6,9)]; return o(im)
@g('sailing','sailing_outlined')
def _(): im,d=cv(); R(d,6,0,7,11,'wood_d'); P(d,[(8,1),(13,10),(8,10)],'bone'); P(d,[(5,2),(5,10),(0,10)],'ash'); P(d,[(0,11),(13,11),(11,13),(2,13)],'wood'); return o(im)
def p8(im,path):
    cols=sorted({p for p in im.getdata()}); idx={c:j for j,c in enumerate(cols)}
    q=Image.new('P',im.size); q.putpalette(sum([list(c[:3]) for c in cols],[])+[0]*(768-3*len(cols))); q.putdata([idx[p] for p in im.getdata()]); q.save(path,optimize=True,transparency=bytes(c[3] for c in cols))
if __name__=='__main__':
    idx={}
    for k,(fn,mat) in G.items():
        im=fn(); assert im.size==(16,16),(k,im.size); p8(im,f'{O}png/{k}.png'); idx[k]=f'Icons.{mat}'
    json.dump(idx,open(O+'material_map.json','w'),indent=1)
    # the final gap set, staged as drop-ins
    for s in ('edict_of_silence','glass_reflection','hex_of_ill_luck','rotting_mark','shroud_reflection'): shutil.copy(f'{M}skill_{s}.png',f'art/pixellab-gap/skills/{s}.png')
    for i in ('boss_trophy','fate_coin'): shutil.copy(f'{M}new_{i}.png',f'art/pixellab-gap/items/{i}.png')
    for e in ('lightning','ice','holy','dark','none'): shutil.copy(f'{M}element_{e}.png',f'art/pixellab-gap/elements/{e}.png')
    LIGHT=(233,224,201); DARK=(31,28,35); cell=72; cols=11
    items=[(k,Image.open(f'{O}png/{k}.png').convert('RGBA')) for k in G]
    gap=[(f'skill {n}',Image.open(f'art/pixellab-gap/skills/{n}.png').convert('RGBA')) for n in ('edict_of_silence','glass_reflection','hex_of_ill_luck','rotting_mark','shroud_reflection')]+[(f'item {n}',Image.open(f'art/pixellab-gap/items/{n}.png').convert('RGBA')) for n in ('boss_trophy','fate_coin')]+[(f'el {n}',Image.open(f'art/pixellab-gap/elements/{n}.png').convert('RGBA')) for n in ('lightning','ice','holy','dark','none')]
    F=ImageFont.load_default(size=11)
    rows=(len(items)+cols-1)//cols+(len(gap)+cols-1)//cols
    sh=Image.new('RGB',(2*cols*cell+30,rows*cell+60),LIGHT); d=ImageDraw.Draw(sh)
    for half,bg in enumerate((LIGHT,DARK)):
        x0=10+half*(cols*cell+10); d.rectangle((x0-5,0,x0+cols*cell+5,sh.height),fill=bg); y=22
        d.text((x0,4),'33 journey glyphs (4x)',font=F,fill=(35,31,26) if half==0 else (233,224,201))
        for n,(k,im) in enumerate(items):
            cx=x0+(n%cols)*cell; cy=y+(n//cols)*cell; big=im.resize((64,64),Image.NEAREST); sh.paste(big,(cx,cy),big); d.text((cx,cy+62),k[:11],font=F,fill=(110,102,90))
        y2=y+((len(items)+cols-1)//cols)*cell+14; d.text((x0,y2-12),'gap set: 5 skills, 2 items, 5 elements',font=F,fill=(35,31,26) if half==0 else (233,224,201))
        for n,(k,im) in enumerate(gap):
            cx=x0+(n%cols)*cell; cy=y2+(n//cols)*cell; big=im.resize((64,64),Image.NEAREST); sh.paste(big,(cx,cy),big); d.text((cx,cy+62),k[:12],font=F,fill=(110,102,90))
    sh.save('docs/art/boards/journey-gap-icons.png'); print(len(G),sh.size)
