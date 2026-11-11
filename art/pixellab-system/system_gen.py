"""System glyphs, part 3: the remaining Material icons by use count, drawn in the original style (16 px coloured, or one-colour masks for plain controls).
Together with the packs already made (ui24, hud16, journey, locked, chrome) this covers about 60 system glyphs: coverage.json maps each Material icon to its file.
Run from the repo root: python3 art/pixellab-system/system_gen.py"""
import sys, json, os, math
sys.path.insert(0,'art/pixellab-pilots/icons')
import icons_gen as I
from icons_gen import PAL, canvas, finish, P, R, L, E, H
from PIL import Image, ImageDraw, ImageFont
PAL['ink']=H('#0A0807'); PAL['cream']=H('#FAF2DA')
O='art/pixellab-system/'
def cv(): return canvas(14)
def o(im): return finish(im)
G={}; MASKS={}
def g(name,material):
    def w(fn): G[name]=(fn,material); return fn
    return w
@g('check_circle','check_circle')
def _(): im,d=cv(); E(d,0,0,13,13,'heal_d'); E(d,1,1,12,12,'heal'); P(d,[(3,7),(4,6),(6,8),(10,3),(11,4),(6,10)],'cream'); return o(im)
@g('path','path')
def _(): im,d=cv(); P(d,[(5,13),(8,13),(8,9),(6,6),(8,2),(6,0),(3,3),(5,7),(5,9)],'steel'); R(d,6,10,7,11,'bone'); R(d,5,4,5,5,'bone'); return o(im)
@g('gavel','gavel')
def _(): im,d=cv(); P(d,[(2,4),(7,0),(10,3),(5,7)],'wood'); L(d,[(6,6),(12,12)],'wood_d',2); R(d,0,12,6,13,'steel'); return o(im)
@g('balance','balance')
def _(): im,d=cv(); R(d,6,1,7,12,'gold'); R(d,1,3,12,3,'gold'); R(d,3,12,10,13,'gold_d'); P(d,[(0,5),(4,5),(2,9)],'steel'); P(d,[(9,5),(13,5),(11,9)],'steel'); return o(im)
@g('walk','directions_walk')
def _(): im,d=cv(); E(d,5,0,8,3,'bone'); L(d,[(6,4),(6,8)],'bone',2); L(d,[(6,5),(3,8)],'bone'); L(d,[(7,5),(10,7)],'bone'); L(d,[(6,8),(3,13)],'bone'); L(d,[(6,8),(10,13)],'bone'); return o(im)
@g('run','directions_run')
def _(): im,d=cv(); E(d,8,0,11,3,'ember'); L(d,[(7,4),(5,8)],'ember',2); L(d,[(7,5),(11,6)],'ember'); L(d,[(7,5),(3,5)],'ember'); L(d,[(5,8),(2,12)],'ember'); L(d,[(5,8),(10,10)],'ember'); L(d,[(10,10),(11,13)],'ember'); return o(im)
@g('pin','place_outlined')
def _(): im,d=cv(); P(d,[(6,0),(11,3),(11,7),(6,13),(1,7),(1,3)],'blood'); E(d,4,3,8,7,'cream'); return o(im)
@g('groups','groups_2_outlined')
def _(): im,d=cv(); [ (E(d,x,y,x+3,y+3,'bone'), P(d,[(x-1,y+9),(x-1,y+6),(x+4,y+6),(x+4,y+9)],'steel')) for x,y in ((5,0),(0,3),(9,3)) ]; return o(im)
@g('error','error_outline')
def _(): im,d=cv(); E(d,0,0,13,13,'blood'); R(d,6,3,7,8,'cream'); R(d,6,10,7,11,'cream'); return o(im)
@g('edit','edit_outlined')
def _(): im,d=cv(); P(d,[(9,0),(13,4),(4,13),(0,13),(0,9)],'gold'); P(d,[(9,0),(13,4),(11,6),(7,2)],'blood'); R(d,0,12,2,13,'ink'); return o(im)
@g('wand','auto_fix_high')
def _(): im,d=cv(); L(d,[(1,12),(9,4)],'wood',2); P(d,[(10,0),(11,3),(13,4),(11,5),(10,8),(9,5),(7,4),(9,3)],'gold'); return o(im)
@g('healing','healing')
def _(): im,d=cv(); P(d,[(1,9),(9,1),(12,4),(4,12)],'bone'); R(d,6,5,7,8,'blood'); R(d,5,6,8,7,'blood'); return o(im)
@g('copy','copy_outlined')
def _(): im,d=cv(); R(d,4,0,12,9,'bone'); R(d,0,4,8,13,'steel'); R(d,1,5,7,12,'bone'); [L(d,[(2,y),(6,y)],'steel') for y in (7,9)]; return o(im)
@g('cloud','cloud_outlined')
def _(): im,d=cv(); E(d,0,5,6,11,'ice'); E(d,3,1,10,8,'ice'); E(d,7,5,13,11,'ice'); R(d,3,7,10,11,'ice'); return o(im)
@g('medal','workspace_premium')
def _(): im,d=cv(); P(d,[(3,0),(6,5),(4,8)],'blood'); P(d,[(10,0),(7,5),(9,8)],'blood'); E(d,3,5,10,12,'gold'); E(d,5,7,8,10,'gold_d'); return o(im)
@g('eye_off','visibility_off_outlined')
def _(): im,d=cv(); P(d,[(0,6),(6,2),(13,6),(6,11)],'bone'); E(d,4,4,9,9,'steel_d'); L(d,[(1,12),(12,1)],'blood',2); return o(im)
@g('shield_moon','shield_moon_outlined')
def _(): im,d=cv(); P(d,[(2,1),(11,1),(11,7),(6,13),(2,7)],'tide_d'); E(d,4,3,9,8,'ice'); E(d,6,2,11,7,'tide_d'); return o(im)
@g('globe','public')
def _(): im,d=cv(); E(d,0,0,13,13,'tide'); P(d,[(2,3),(6,2),(7,5),(4,8),(2,6)],'heal'); P(d,[(8,7),(12,6),(11,11),(8,10)],'heal'); return o(im)
@g('mic','mic_none')
def _(): im,d=cv(); d.rounded_rectangle((4,0,9,8),2,fill=PAL['steel']); L(d,[(2,6),(2,8),(6,11),(11,8),(11,6)],'steel_d'); R(d,6,11,7,13,'steel_d'); return o(im)
@g('door','logout')
def _(): im,d=cv(); R(d,2,0,10,13,'wood'); R(d,3,1,9,12,'wood_d'); R(d,8,6,9,7,'gold'); P(d,[(10,4),(13,7),(10,10)],'bone'); return o(im)
@g('share','ios_share_outlined')
def _(): im,d=cv(); R(d,1,5,12,13,'steel'); R(d,2,6,11,12,'bone'); L(d,[(6,0),(6,8)],'tide',2); P(d,[(3,3),(6,0),(9,3)],'tide'); return o(im)
@g('box','inventory_2_outlined')
def _(): im,d=cv(); R(d,0,1,13,4,'wood'); R(d,1,4,12,13,'wood_d'); R(d,5,6,8,7,'ink'); return o(im)
@g('hiker','hiking')
def _(): im,d=cv(); E(d,4,0,7,3,'bone'); L(d,[(5,4),(5,8)],'steel',2); R(d,6,5,8,9,'wood'); L(d,[(5,8),(3,13)],'steel'); L(d,[(5,8),(8,13)],'steel'); L(d,[(11,3),(11,13)],'wood_d'); return o(im)
@g('trash','delete_outline')
def _(): im,d=cv(); R(d,2,3,11,13,'steel'); R(d,3,4,10,12,'ash'); R(d,1,1,12,2,'steel_d'); R(d,5,0,8,0,'steel_d'); [L(d,[(x,5),(x,11)],'steel') for x in (4,6,8)]; return o(im)
@g('braces','data_object')
def _(): im,d=cv(); L(d,[(5,0),(3,1),(3,5),(1,7),(3,8),(3,12),(5,13)],'tide',2); L(d,[(8,0),(10,1),(10,5),(12,7),(10,8),(10,12),(8,13)],'tide',2); return o(im)
@g('cottage','cottage_outlined')
def _(): im,d=cv(); R(d,2,6,11,12,'bone'); P(d,[(6,0),(13,6),(0,6)],'wood'); R(d,5,8,7,12,'wood_d'); return o(im)
@g('comment','comment_outlined')
def _(): im,d=cv(); P(d,[(1,1),(12,1),(12,9),(6,9),(2,13),(3,9),(1,9)],'ash'); R(d,3,4,9,4,'steel_d'); R(d,3,6,7,6,'steel_d'); return o(im)
@g('trend_up','trending_up')
def _(): im,d=cv(); L(d,[(0,11),(4,6),(7,9),(12,2)],'heal',2); P(d,[(8,1),(13,1),(13,6)],'heal'); return o(im)
@g('trend_down','trending_down')
def _(): im,d=cv(); L(d,[(0,2),(4,7),(7,4),(12,11)],'blood',2); P(d,[(8,12),(13,12),(13,7)],'blood'); return o(im)
@g('sword_hand','sports_kabaddi')
def _(): im,d=cv(); P(d,[(11,0),(13,0),(13,2),(6,9),(4,7)],'steel'); P(d,[(2,6),(7,11),(8,10),(3,5)],'gold'); L(d,[(3,10),(1,12)],'wood',2); return o(im)
@g('globe_route','route_outlined')
def _(): im,d=cv(); E(d,0,8,4,12,'blood'); E(d,9,1,13,5,'tide'); L(d,[(3,8),(5,5),(9,7),(10,5)],'steel',2); return o(im)
@g('restart','restart_alt')
def _(): im,d=cv(); d.arc((1,1,12,12),40,320,fill=PAL['bone'],width=2); P(d,[(8,0),(13,3),(8,5)],'bone'); return o(im)
# one-colour masks (24 px white on transparent) for plain controls not in ui24
W=(255,255,255,255)
def mk(f):
    im=Image.new('RGBA',(24,24),(0,0,0,0)); d=ImageDraw.Draw(im); f(d); return im
MASKS={
 'radio_empty':lambda d:d.ellipse((3,3,20,20),outline=W,width=3),
 'radio_filled':lambda d:(d.ellipse((3,3,20,20),outline=W,width=3),d.ellipse((8,8,15,15),fill=W)),
 'double_chevron_down':lambda d:(d.polygon([(4,4),(4,7),(12,13),(20,7),(20,4),(12,10)],fill=W),d.polygon([(4,11),(4,14),(12,20),(20,14),(20,11),(12,17)],fill=W)),
 'history':lambda d:(d.arc((3,3,21,21),30,330,fill=W,width=3),d.polygon([(2,2),(2,10),(10,10)],fill=W),d.line([(12,7),(12,12),(16,14)],fill=W,width=2)),
 'refresh':lambda d:(d.arc((3,3,21,21),30,300,fill=W,width=3),d.polygon([(21,2),(21,10),(13,10)],fill=W)),
 'menu':lambda d:[d.rectangle((3,y,20,y+2),fill=W) for y in (5,11,17)],
 'more_vert':lambda d:[d.rectangle((10,y,13,y+3),fill=W) for y in (3,10,17)],
 'search':lambda d:(d.ellipse((3,3,15,15),outline=W,width=3),d.line([(14,14),(21,21)],fill=W,width=3)),
 'filter':lambda d:d.polygon([(2,4),(21,4),(14,12),(14,20),(9,17),(9,12)],fill=W),
 'sort':lambda d:(d.rectangle((3,5,20,7),fill=W),d.rectangle((3,11,15,13),fill=W),d.rectangle((3,17,10,19),fill=W)),
}
def p8(im,path):
    cols=sorted({p for p in im.getdata()}); idx={c:j for j,c in enumerate(cols)}
    q=Image.new('P',im.size); q.putpalette(sum([list(c[:3]) for c in cols],[])+[0]*(768-3*len(cols))); q.putdata([idx[p] for p in im.getdata()]); q.save(path,optimize=True,transparency=bytes(c[3] for c in cols))
if __name__=='__main__':
    cov={}
    for k,(fn,mat) in G.items():
        im=fn(); assert im.size==(16,16),(k,im.size); p8(im,f'{O}png/{k}.png'); cov[mat]=f'art/pixellab-system/png/{k}.png'
    for k,fn in MASKS.items(): mk(fn).save(f'{O}masks/{k}.png',optimize=True)
    # what the earlier packs already cover, by Material name
    has={'chevron_right':'ui24 mask','close':'ui24 mask','add':'ui24 mask','remove':'ui24 mask','check':'ui24 mask','arrow_forward':'ui24 mask','arrow_back':'ui24 mask','expand_more':'ui24 mask','expand_less':'ui24 mask',
     'lock_outline':'chrome lock / locked-state lock8','lock':'chrome lock','auto_awesome':'journey arcane','local_fire_department_outlined':'journey camp / ui24 nav_camp','local_fire_department':'journey camp','casino_outlined':'journey challenge','casino':'journey challenge',
     'shield':'ui24 stats_level / hud die_defend','shield_outlined':'journey warden','bolt':'hud element_lightning','anchor':'journey harbor','flag_outlined':'journey mainquest','flag':'journey mainquest','map_outlined':'ui24 header_map',
     'favorite':'ui24 stats_hp','sports_martial_arts':'journey fighter','sailing':'journey sailing','sailing_outlined':'journey sailing','waves':'journey sea','visibility_outlined':'journey wisdom','visibility':'journey wisdom','explore_outlined':'journey compass',
     'wb_sunny_outlined':'journey desert / ui24 time_day','water_drop':'ui24 stats_mana','star':'locked star','chat_bubble_outline':'journey talk','storefront_outlined':'journey shop','storefront':'journey shop','signpost_outlined':'journey signpost',
     'info_outline':'ui24 header_info','emoji_events_outlined':'gap boss_trophy','warning_amber_rounded':'hud chip_hazard','paid':'ui24 stats_gold','menu_book':'ui24 nav_story','menu_book_outlined':'ui24 nav_story','auto_stories_outlined':'journey story','blur_on':'journey wisp',
     'ac_unit':'hud chip_anomaly_cold','terrain':'journey cave','pets':'journey beast','person_outline':'ui24 nav_character','person':'ui24 nav_character','my_location':'journey archer','diversity_3':'race plates','alt_route':'ui24 nav_journey','assignment':'ui24 stats_quest','assignment_outlined':'ui24 stats_quest','play_arrow':'ui24 nav_play','military_tech':'system medal','thunderstorm_outlined':'hud chip_anomaly_storm','fitness_center':'journey strength','gps_fixed':'journey archer','hardware':'journey forge','science_outlined':'journey apothecary','search':'system mask search','settings':'ui24 header_settings','home':'ui24 header_home'}
    json.dump({'drawn_here':cov,'masks_here':list(MASKS),'already_made':has},open(O+'coverage.json','w'),indent=1)
    LIGHT=(233,224,201); DARK=(31,28,35); cell=72; cols=12
    items=[(k,Image.open(f'{O}png/{k}.png').convert('RGBA')) for k in G]+[('m:'+k,Image.open(f'{O}masks/{k}.png').convert('RGBA')) for k in MASKS]
    F=ImageFont.load_default(size=11); rows=(len(items)+cols-1)//cols
    sh=Image.new('RGB',(2*cols*cell+30,rows*cell+40),LIGHT); d=ImageDraw.Draw(sh)
    for half,bg in enumerate((LIGHT,DARK)):
        x0=10+half*(cols*cell+10); d.rectangle((x0-5,0,x0+cols*cell+5,sh.height),fill=bg); d.text((x0,4),'system glyphs, part 3 (4x; masks tinted, 3x)',font=F,fill=(35,31,26) if half==0 else (233,224,201))
        for n,(k,im) in enumerate(items):
            cx=x0+(n%cols)*cell; cy=22+(n//cols)*cell
            if k.startswith('m:'):
                t=Image.new('RGBA',im.size,(168,78,18,255) if half==0 else (233,224,201,255)); t.putalpha(im.getchannel('A')); big=t.resize((60,60),Image.NEAREST)
            else: big=im.resize((64,64),Image.NEAREST)
            sh.paste(big,(cx,cy),big); d.text((cx,cy+62),k[:11],font=F,fill=(110,102,90))
    sh.save('docs/art/boards/system-glyphs-3.png'); print(len(G),len(MASKS),len(has),sh.size)
