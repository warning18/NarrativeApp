import sys,os,json; sys.path.insert(0,'/tmp/claude-0/-home-user-NarrativeApp/644fb7e7-6d1c-53db-86ff-44fea4844d60/scratchpad')
from icons import *
from PIL import ImageFont
O='art/pixellab-pilots/icons/'; os.makedirs(O+'world',exist_ok=True); os.makedirs(O+'chrome',exist_ok=True)
def p8(im,path):
    cols=sorted({p for p in im.getdata()}); idx={c:j for j,c in enumerate(cols)}; assert len(cols)<=256
    o=Image.new('P',im.size); o.putpalette(sum([list(c[:3]) for c in cols],[])+[0]*(768-3*len(cols))); o.putdata([idx[p] for p in im.getdata()]); o.save(path,optimize=True,transparency=bytes(c[3] for c in cols))
W={k:f() for k,f in WORLD.items()}; C={k:f() for k,f in CHROME.items()}
for k,v in W.items(): assert v.size==(16,16),(k,v.size); p8(v,O+f'world/{k}.png')
for k,v in C.items(): p8(v,O+f'chrome/{k}.png')
F=ImageFont.load_default(size=13); FB=ImageFont.load_default(size=20); FS=ImageFont.load_default(size=11)
INV='/tmp/claude-0/-home-user-NarrativeApp/644fb7e7-6d1c-53db-86ff-44fea4844d60/scratchpad/inv/'
m4=Image.open(INV+'4-material-die-faces-keywords-elements-spells.png').convert('RGBA')
def crop4(cx,cy,r=22): return m4.crop((cx-r,cy-r,cx+r,cy+r))
LIGHT=(233,224,201,255); DARK=(31,28,35,255)
def rgba(c): return tuple(c) if len(c)==4 else tuple(c)+(255,)
def recolor(im,col):
    out=im.copy(); px=out.load()
    for y in range(out.height):
        for x in range(out.width):
            p=px[x,y]
            if p[3]>0 and p[:3]!=PAL['ink'][:3]: px[x,y]=rgba(col)
    return out
def block(items,x,y,sheet,d,title,note):
    d.text((x,y),title,font=F,fill=(35,31,26)); d.text((x,y+17),note,font=FS,fill=(110,102,90))
    cx=x; y0=y+40
    for lab,today,new,tint_col in items:
        d.text((cx,y0),lab,font=FS,fill=(35,31,26))
        if today is not None: sheet.alpha_composite(today,(cx,y0+16))
        n1=new if tint_col is None else tint(new,tint_col)
        sheet.alpha_composite(n1,(cx+54,y0+22))
        for k,bg in enumerate((LIGHT,DARK)):
            src=n1 if (tint_col is None or k==0) else tint(new,(233,223,196))
            tile=Image.new('RGBA',(72,72),bg); tile.alpha_composite(src.resize((64,64),Image.NEAREST),(4,4)); sheet.alpha_composite(tile,(cx+80+k*76,y0+10))
        cx+=240
    return y0+90
sheet=Image.new('RGBA',(1480,2000),(250,246,236,255)); d=ImageDraw.Draw(sheet)
d.text((14,10),'ICON PILOT SHEET: today (left) | new at 1x | new at 4x on parchment and on dark; hand-drawn, the two style rules applied by code',font=FB,fill=(35,31,26))
y=44
PNG=lambda p:Image.open(p).convert('RGBA').resize((48,48),Image.NEAREST)
rows=[
 ('Die face kinds (8, Material today)','hand-drawn: shape tells the kind, colour confirms it',[('attack',crop4(68,110),W['sword'],None),('mana',crop4(356,110),W['drop'],None),('poison',crop4(452,110),W['skull'],None)]),
 ('Face rule words (6)','hand-drawn',[('steady',crop4(548,293),W['anchor'],None),('pain',crop4(452,293),recolor(W['drop'],PAL['blood']),None),('pierce',crop4(164,293),C['arrow_forward'],PAL['wood'])]),
 ('Elements: the 5 that draw an empty circle today (gap fix)','hand-drawn; fire/water/earth/wind follow the same way',[('lightning',crop4(260,475),W['bolt_tide'],None),('ice',crop4(548,475),W['ice'],None),('holy',crop4(644,475),W['holy'],None),('dark',crop4(740,475),W['dark'],None),('none',crop4(836,475),W['none'],None)]),
 ('Spell effects (5)','hand-drawn',[('heal',crop4(164,657),recolor(W['heart'],PAL['heal']),None),('block',crop4(260,657),W['shield'],None),('damage',crop4(68,657),W['flame'],None)]),
 ('Game lookups and journey glyphs (62 + 33)','hand-drawn',[('quest scroll',None,W['scroll'],None),('signpost way',None,W['signpost'],None),('sailing',None,W['ship'],None)]),
 ('Item and skill families (PNG today): 2 to 3 redrawn each','the PNGs already read as pixel art; here the same subject drawn to the guide',[('item: potion',PNG('assets/icons/items/potion_minor.png'),W['potion'],None),('skill: fireball',PNG('assets/icons/skills/fireball.png'),W['flame'],None),('skill: power_strike',PNG('assets/icons/skills/power_strike.png'),W['sword'],None)]),
]
for title,note,items in rows:
    for i in range(0,len(items),5):
        y=block(items[i:i+5],14,y,sheet,d,title if i==0 else title+' (cont.)',note if i==0 else '')+6
d.text((14,y),'Chrome glyphs (the Material top-10 replacements): single-colour masks tinted by the theme; 1x and 3x on parchment (ink) and on dark (bone)',font=F,fill=(35,31,26)); y+=26
ch=['chevron_right','lock','check','close','add','arrow_forward','flag','home','map','settings','person','more_horiz']
x=14
for k in ch:
    im=C[k]
    for j,(bg,col) in enumerate(((LIGHT,(35,31,26)),(DARK,(233,223,196)))):
        tile=Image.new('RGBA',(58,100),bg); tile.alpha_composite(tint(im,col).resize((48,48),Image.NEAREST),(5,4)); tile.alpha_composite(tint(im,col),(21,58)); sheet.alpha_composite(tile,(x+j*60,y))
    d.text((x,y+104),k[:11],font=FS,fill=(35,31,26)); x+=121
y+=130
d.text((14,y),'In context (mock on parchment): header, stats bar, nav bar and a button, 2x/3x pixel icons instead of Material',font=F,fill=(35,31,26)); y+=22
ctx=Image.new('RGBA',(1450,150),LIGHT); cd=ImageDraw.Draw(ctx)
def put(name,xx,yy,col,scale=2): ctx.alpha_composite(tint(C[name],col).resize((16*scale,16*scale),Image.NEAREST),(xx,yy))
ink=(94,87,75)
put('home',20,14,ink,3); put('map',1250,14,ink,3); put('settings',1370,14,ink,3)
cd.text((90,26),'CHAPTER 1   Story',font=F,fill=(168,78,18))
for xx,n,t in ((20,'shield','Lvl 1'),(140,'sparkle','D1'),(240,'heart','20/20'),(380,'drop','4/4')):
    ctx.alpha_composite(W[n].resize((32,32),Image.NEAREST),(xx,80)); cd.text((xx+40,88),t,font=F,fill=(35,31,26))
for i,(n,lab) in enumerate((('signpost','Journey'),('person','Character'),('flame','Camp'),('more_horiz','Other'))):
    xx=700+i*180
    if n in W: ctx.alpha_composite(W[n].resize((48,48),Image.NEAREST),(xx,70))
    else: ctx.alpha_composite(tint(C[n],ink).resize((48,48),Image.NEAREST),(xx,70))
    cd.text((xx-6,124),lab,font=F,fill=(35,31,26))
cd.rectangle((1180,70,1400,112),fill=PAL['gold'][:3],outline=(23,18,15)); cd.text((1196,82),'Continue',font=F,fill=(35,31,26)); ctx.alpha_composite(tint(C['chevron_right'],(35,31,26)).resize((32,32),Image.NEAREST),(1356,75))
sheet.alpha_composite(ctx,(14,y)); y+=170
d.text((14,y),'PixelLab option (pixen 32x32, 3 generations) vs the hand-drawn guide icons at 2x: model icons keep their own proportions/outline and need a clean-up pass to match',font=F,fill=(35,31,26)); y+=24
x=14
for k in ('flame','sword','shield'):
    pz=Image.open(O+f'pixen_raw/{k}/get_image_0.png').convert('RGBA')
    for im,lab in ((pz,'PixelLab 32'),(W[k].resize((32,32),Image.NEAREST),'hand-drawn')):
        t=Image.new('RGBA',(144,144),LIGHT); t.alpha_composite(im.resize((128,128),Image.NEAREST),(8,8)); sheet.alpha_composite(t,(x,y)); d.text((x,y+146),k+': '+lab,font=FS,fill=(35,31,26)); x+=156
sheet=sheet.crop((0,0,1480,y+175)); sheet.convert('RGB').save('docs/art/boards/icons-pilot.png'); print(sheet.size)
json.dump(dict(world=sorted(W),chrome=sorted(C)),open(O+'index.json','w'),indent=1)
