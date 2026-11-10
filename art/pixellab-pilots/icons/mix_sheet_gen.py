import sys,os,json; sys.path.insert(0,'/tmp/claude-0/-home-user-NarrativeApp/644fb7e7-6d1c-53db-86ff-44fea4844d60/scratchpad')
import icons as I
from icons import *
I.PAL['ink']=H('#0A0807'); PAL['ink']=I.PAL['ink']      # the originals' ink
from mix import snap,build_palette,extract_glyph,depth_map,d2,load_all
from PIL import ImageFont
pal,_=build_palette()
LIGHT=(233,224,201,255); DARK=(31,28,35,255)
F=ImageFont.load_default(size=13); FB=ImageFont.load_default(size=20); FS=ImageFont.load_default(size=11)
CREAM=H('#FAF2DA'); INK=PAL['ink']
O='art/pixellab-pilots/icons/mix/'; os.makedirs(O,exist_ok=True)
def p8(im,path):
    cols=sorted({p for p in im.getdata()}); idx={c:j for j,c in enumerate(cols)}; assert len(cols)<=256
    o=Image.new('P',im.size); o.putpalette(sum([list(c[:3]) for c in cols],[])+[0]*(768-3*len(cols))); o.putdata([idx[p] for p in im.getdata()]); o.save(path,optimize=True,transparency=bytes(c[3] for c in cols))
sk=json.load(open('assets/gamedata/skills.json'))
def orig(k): return Image.open(f'assets/icons/skills/{k}.png').convert('RGBA')
def is_container(im):
    px=im.load(); w,h=im.size; dep=depth_map(im); opaque=sum(1 for y in range(h) for x in range(w) if px[x,y][3]>0)
    ring=[px[x,y][:3] for y in range(h) for x in range(w) if px[x,y][3]>0 and dep[y][x]==2]
    if not ring: return False
    import collections
    top=collections.Counter(ring).most_common(1)[0][1]/len(ring)
    return opaque/(w*h)>0.4 and top>0.6
def elem_keys(element):
    dark=PAL[ELEM[element][1]]; PAL['f_'+element]=dark; PAL['r_'+element]=mix(dark,INK,0.45); return 'f_'+element,'r_'+element
def variant_b(k,rarity,element):
    a=snap(orig(k),pal)
    fk,rk=elem_keys(element); base=container2(rarity,fk,rk)
    if is_container(a):
        g=extract_glyph(a); cont=finish(base)   # 16x16
        out=cont.copy(); dep=depth_map(cont); cp=cont.load(); gp=g.load(); op=out.load()
        for y in range(16):
            for x in range(16):
                if gp[x,y][3]>0 and dep[y][x]>=2: op[x,y]=gp[x,y]
        return out,True
    # an object icon (no container): the plate behind it, the original drawing on top
    cont=finish(base); out=cont.copy(); out.alpha_composite(a); return out,False
def tile(im,bg,sc=4):
    t=Image.new('RGBA',(im.width*sc+8,im.height*sc+8),bg); t.alpha_composite(im.resize((im.width*sc,im.height*sc),Image.NEAREST),(4,4)); return t
sheet=Image.new('RGBA',(1500,2400),(250,246,236,255)); d=ImageDraw.Draw(sheet)
d.text((14,10),'MIX PILOT: keep the original pixel icons, harmonise them (shared palette, one ink), new pieces drawn in their style. 0 generations.',font=FB,fill=(35,31,26))
y=40
d.text((14,y),'1. SKILLS: today | (a) harmonised only (63-colour shared palette, one ink #0A0807) | (b) original glyph in the rarity frame + element colour. 1x, then 4x on parchment and dark',font=F,fill=(35,31,26)); y+=24
SK=['fireball','mage_frost_nova','void_blast','cleric_holy_light','second_wind','rogue_backstab','mage_meteor','power_strike','guard_break']
report=[]
for i,k in enumerate(SK):
    r=sk[k]['rarity']; e=sk[k]['element']; col=i%2; row=i//2; x=14+col*740; yy=y+row*102
    d.text((x,yy),f'{k} ({r}, {e})',font=FS,fill=(35,31,26))
    t=orig(k); a=snap(t,pal); b,iscont=variant_b(k,r,e); p8(a,O+f'{k}_a.png'); p8(b,O+f'{k}_b.png')
    report.append((k,iscont))
    cx=x
    for lab,im in (('today',t),('(a)',a),('(b)',b)):
        sheet.alpha_composite(im,(cx,yy+30)); 
        for j,bg in enumerate((LIGHT,DARK)): sheet.alpha_composite(tile(im,bg),(cx+20+j*76,yy+16))
        d.text((cx+30,yy+88),lab,font=FS,fill=(110,102,90)); cx+=240
y+=5*102+10
d.text((14,y),'   a 32 x 32 skill (e.g. mage_chain_lightning) keeps its 32 px frame; (b) there is the same frame drawn at 32 px (not piloted). Object-style icons (rogue_backstab) get the rarity/element plate behind the original drawing.',font=FS,fill=(110,102,90)); y+=26
# items
d.text((14,y),'2. ITEMS: today | harmonised only (palette + ink). The drawings are untouched.',font=F,fill=(35,31,26)); y+=24
for i,k in enumerate(['sword_t3','potion_minor','armor_leather','scroll_fireball']):
    x=14+i*370; t=Image.open(f'assets/icons/items/{k}.png').convert('RGBA'); a=snap(t,pal); p8(a,O+f'item_{k}_a.png')
    d.text((x,y),k,font=FS,fill=(35,31,26)); cx=x
    for lab,im in (('today',t),('harmonised',a)):
        sheet.alpha_composite(im,(cx,y+34)); 
        for j,bg in enumerate((LIGHT,DARK)): sheet.alpha_composite(tile(im,bg),(cx+20+j*76,y+16))
        d.text((cx+20,y+90),lab,font=FS,fill=(110,102,90)); cx+=180
y+=110

# ---------- 3. gaps drawn in the ORIGINAL style ----------
def cream(d_,fn): fn(d_)
def g_bolt(d): P(d,[(6,0),(1,6),(4,6),(3,9),(8,3),(5,3)],'cream')
def g_flake(d):
    for a,b in (((5,0),(5,9)),((0,2),(9,7)),((0,7),(9,2))): d.line([a,b],fill=PAL['cream'])
def g_sun(d):
    d.ellipse((3,3,6,6),fill=PAL['cream'])
    for a in ((4,0),(5,0),(4,9),(5,9),(0,4),(0,5),(9,4),(9,5)): d.point(a,fill=PAL['cream'])
def g_orb(d): d.ellipse((0,0,9,9),fill=PAL['ink']); d.ellipse((2,2,7,7),fill=PAL['cream']); d.ellipse((3,3,6,6),fill=PAL['ink'])
def g_none(d): d.ellipse((0,0,9,9),outline=PAL['cream']); d.line([(2,7),(7,2)],fill=PAL['cream'])
def g_lips(d): d.ellipse((0,2,9,7),fill=PAL['cream']); d.line([(1,5),(8,5)],fill=PAL['ink']); d.line([(2,3),(7,3)],fill=PAL['blood'])
def g_mirror(d): R(d,2,0,7,9,'cream'); R(d,3,1,6,8,'steel'); d.line([(3,7),(6,2)],fill=PAL['cream'])
def g_hexdie(d): R(d,1,1,8,8,'cream'); R(d,2,2,3,3,'ink'); R(d,6,2,7,3,'ink'); R(d,4,4,5,5,'ink'); R(d,2,6,3,7,'ink'); R(d,6,6,7,7,'ink'); d.line([(0,0),(9,9)],fill=PAL['blood'])
def g_rot(d): d.ellipse((1,0,8,6),fill=PAL['cream']); R(d,2,6,7,8,'cream'); R(d,2,3,3,4,'ink'); R(d,6,3,7,4,'ink'); R(d,4,7,5,8,'ink'); R(d,1,1,2,2,'heal_d')
def g_shroud(d): P(d,[(1,0),(8,0),(9,9),(7,7),(5,9),(3,7),(0,9)],'cream'); d.line([(3,2),(3,5)],fill=PAL['steel']); d.line([(6,2),(6,5)],fill=PAL['steel'])
PAL['cream']=CREAM
def gem(rarity,element,glyph_fn):
    fk,rk=elem_keys(element); base=container2(rarity,fk,rk); g,gd=canvas(10); glyph_fn(gd); base.alpha_composite(g,(2,2)); return finish(base)
def objicon(fn): return fn()
def trophy():
    im,d=canvas(14); d.ellipse((0,2,3,6),outline=PAL['gold_d']); d.ellipse((10,2,13,6),outline=PAL['gold_d']); P(d,[(2,0),(11,0),(10,7),(7,9),(4,7)],'gold'); R(d,6,9,7,11,'gold_d'); R(d,3,11,10,12,'wood'); R(d,4,2,5,5,'bone'); return finish(im)
def coin():
    im,d=canvas(14); E(d,0,0,13,13,'gold'); E(d,2,2,11,11,'gold_d'); d.pieslice((2,2,11,11),270,450,fill=PAL['gold']); R(d,6,5,6,7,'ink'); return finish(im)
d.text((14,y),'3. GAPS drawn in the ORIGINAL style (same 16 px gems and outlined objects as the neighbours), next to a neighbouring original',font=F,fill=(35,31,26)); y+=24
EL=[('lightning','Electricity',g_bolt),('ice','Ice',g_flake),('holy','Light',g_sun),('dark','Void',g_orb),('none','None',g_none)]
x=14
d.text((x,y),'5 elements (empty circles today); the neighbour is fireball',font=FS,fill=(35,31,26)); y+=16
sheet.alpha_composite(tile(snap(orig('fireball'),pal),LIGHT),(x,y))
for lab,el,fn in EL:
    x+=90; im=gem('common',el,fn); p8(im,O+f'element_{lab}.png')
    for j,bg in enumerate((LIGHT,DARK)): sheet.alpha_composite(tile(im,bg),(x+j*76-0,y))
    d.text((x,y+76),lab,font=FS,fill=(110,102,90)); x+=76
y+=100
x=14; d.text((x,y),'5 skills with no icon of their own (they borrow another\'s): drawn as the common gem, the same container the originals use',font=FS,fill=(35,31,26)); y+=16
for lab,el,fn in (('edict_of_silence','Light',g_lips),('glass_reflection','Void',g_mirror),('hex_of_ill_luck','Void',g_hexdie),('rotting_mark','Void',g_rot),('shroud_reflection','Void',g_shroud)):
    im=gem('common',el,fn); p8(im,O+f'skill_{lab}.png')
    for j,bg in enumerate((LIGHT,DARK)): sheet.alpha_composite(tile(im,bg),(x+j*76,y))
    d.text((x,y+76),lab,font=FS,fill=(110,102,90)); x+=170
y+=100
x=14; d.text((x,y),'2 items with no icon (boss_trophy, fate_coin), then 6 journey glyphs (tree, mountains, paw, waves, eye, compass) in the same outlined style; neighbour: potion_minor',font=FS,fill=(35,31,26)); y+=16
sheet.alpha_composite(tile(snap(Image.open('assets/icons/items/potion_minor.png').convert('RGBA'),pal),LIGHT),(x,y))
for lab,im in (('boss_trophy',trophy()),('fate_coin',coin()),('tree',tree()),('mountains',mountains()),('paw',paw()),('waves',waves()),('eye',eye()),('compass',compass())):
    x+=80; p8(im,O+f'new_{lab}.png')
    for j,bg in enumerate((LIGHT,DARK)): sheet.alpha_composite(tile(im,bg,4),(x+j*0,y+j*0)) if j==0 else None
    d.text((x,y+76),lab[:10],font=FS,fill=(110,102,90))
y+=100
# ---------- 4. Material replacements drawn to match the originals ----------
def m_chevron(): im,d=canvas(14); P(d,[(3,0),(6,0),(11,6),(6,12),(3,12),(8,6)],'bone'); return finish(im)
def m_lock(): im,d=canvas(14); R(d,2,5,11,12,'gold'); R(d,2,5,11,6,'gold_d'); R(d,4,0,5,5,'steel'); R(d,8,0,9,5,'steel'); R(d,4,0,9,1,'steel'); R(d,6,8,7,10,'ink'); return finish(im)
def m_check(): im,d=canvas(14); P(d,[(0,6),(2,4),(4,7),(10,1),(12,3),(4,11)],'heal'); return finish(im)
def m_close(): im,d=canvas(14); d.line([(2,2),(11,11)],fill=PAL['blood'],width=3); d.line([(11,2),(2,11)],fill=PAL['blood'],width=3); return finish(im)
def m_add(): im,d=canvas(14); R(d,5,1,8,12,'heal'); R(d,1,5,12,8,'heal'); return finish(im)
def m_arrow(): im,d=canvas(14); R(d,0,5,7,8,'bone'); P(d,[(6,1),(13,6),(6,12)],'bone'); return finish(im)
def m_flag(): im,d=canvas(14); R(d,1,0,2,13,'wood'); P(d,[(3,1),(12,1),(9,4),(12,7),(3,7)],'blood'); return finish(im)
def m_home(): im,d=canvas(14); R(d,2,6,11,12,'bone'); P(d,[(6,0),(13,6),(0,6)],'wood'); R(d,5,8,7,12,'wood_d'); return finish(im)
def m_map(): im,d=canvas(14); P(d,[(0,2),(4,1),(9,3),(13,2),(13,11),(9,12),(4,10),(0,11)],'bone'); d.line([(4,1),(4,10)],fill=PAL['steel']); d.line([(9,3),(9,12)],fill=PAL['steel']); R(d,6,5,7,6,'tide'); return finish(im)
def m_gear(): im,d=canvas(14); E(d,2,2,11,11,'steel'); 
for_x=((5,0),(5,11),(0,5),(11,5),(1,1),(10,1),(1,10),(10,10))
def m_gear():
    im,d=canvas(14); E(d,2,2,11,11,'steel')
    for x,yy in ((5,0),(5,11),(0,5),(11,5),(1,1),(10,1),(1,10),(10,10)): R(d,x,yy,x+2,yy+2,'steel')
    E(d,5,5,8,8,'ink'); return finish(im)
def m_person():
    im,d=canvas(14); E(d,4,0,9,5,'bone'); P(d,[(1,13),(1,10),(4,7),(9,7),(12,10),(12,13)],'bone'); return finish(im)
def m_dots():
    im,d=canvas(14)
    for x in (0,5,10): R(d,x,5,x+2,7,'steel')
    return finish(im)
MAT=[('chevron_right',m_chevron),('lock',m_lock),('check',m_check),('close',m_close),('add',m_add),('arrow_forward',m_arrow),('flag',m_flag),('home',m_home),('map',m_map),('settings',m_gear),('person',m_person),('more_horiz',m_dots)]
d.text((14,y),'4. TOP MATERIAL GLYPHS drawn to match the original icons (outlined, 2 tones, 16 px). Tintable one-colour masks (previous sheet) stay an option for plain chrome (chevron, close, add).',font=F,fill=(35,31,26)); y+=22
x=14
for lab,fn in MAT:
    im=fn(); p8(im,O+f'material_{lab}.png')
    for j,bg in enumerate((LIGHT,DARK)): sheet.alpha_composite(tile(im,bg,4),(x+j*76,y))
    sheet.alpha_composite(im,(x+152,y+10)); d.text((x,y+76),lab,font=FS,fill=(110,102,90)); x+=148
    if x>1350: x=14; y+=96
y+=100
d.text((14,y),'In context (parchment): header, stats bar, nav bar and a button with the original-style pixel glyphs at 2x/3x',font=F,fill=(35,31,26)); y+=22
ctx=Image.new('RGBA',(1450,150),LIGHT); cd=ImageDraw.Draw(ctx)
M={k:fn() for k,fn in MAT}
ctx.alpha_composite(M['home'].resize((48,48),Image.NEAREST),(20,14)); ctx.alpha_composite(M['map'].resize((48,48),Image.NEAREST),(1250,14)); ctx.alpha_composite(M['settings'].resize((48,48),Image.NEAREST),(1370,14))
cd.text((90,26),'CHAPTER 1   Story',font=F,fill=(168,78,18))
for xx,im,t in ((20,snap(Image.open('assets/icons/items/armor_leather.png').convert('RGBA'),pal),'Lvl 1'),(140,gem('common','Light',g_sun),'D1'),(240,heart(),'20/20'),(380,drop(),'4/4')):
    ctx.alpha_composite(im.resize((32,32),Image.NEAREST),(xx,80)); cd.text((xx+40,88),t,font=F,fill=(35,31,26))
for i,(im,lab) in enumerate(((M['flag'],'Journey'),(m_person(),'Character'),(flame(),'Camp'),(m_dots(),'Other'))):
    xx=700+i*180
    if im is not None: ctx.alpha_composite(im.resize((48,48),Image.NEAREST),(xx,70))
    cd.text((xx-6,124),lab,font=F,fill=(35,31,26))
cd.rectangle((1180,70,1400,112),fill=PAL['gold'][:3],outline=INK[:3]); cd.text((1196,82),'Continue',font=F,fill=(35,31,26)); ctx.alpha_composite(M['chevron_right'].resize((32,32),Image.NEAREST),(1352,75))
sheet.alpha_composite(ctx,(14,y)); y+=170
sheet=sheet.crop((0,0,1500,y+10)); sheet.convert('RGB').save('docs/art/boards/icons-pilot-mix.png'); print(sheet.size)
