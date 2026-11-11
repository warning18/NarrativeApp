"""The UI frame MATERIAL as a progression tier: wood, iron (#939), silver, and a top tier (blackened steel with gilt).
Same shapes, sizes, 9-slice margins and anchors as the iron kit (anchors.json), so UX-2 swaps one token. Hand-drawn in code, 0 generations.
Run from the repo root: python3 art/pixellab-iron-kit/materials_gen.py  -> art/pixellab-iron-kit/materials/<tier>/ui/*.png and the sheets."""
import sys, os, json, random
sys.path.insert(0,'art/pixellab-iron-kit')
import iron_gen as K
from iron_gen import H, INK, IRON, new, stretch, UI
from PIL import Image, ImageDraw, ImageFont
O='art/pixellab-iron-kit/materials/'
MATS={
 'wood':dict(mid=H('#7A5230'),hi=H('#B08050'),lo=H('#4A2E18'),rivet=H('#8A8478'),rust=[H('#5E3C20'),H('#6A4526'),H('#3A2412')],pit=H('#32200F'),
   prim=(H('#C08A4A'),H('#E0B070'),H('#7A4E24')),sec=(H('#7A5230'),H('#B08050'),H('#4A2E18')),dis=(H('#5A4636'),H('#6A5646'),H('#3A2C20'))),
 'iron':None,
 'silver':dict(mid=H('#A9B2BF'),hi=H('#EAF2FB'),lo=H('#5C6573'),rivet=H('#FFFFFF'),rust=[H('#7E8896'),H('#C8D2DE'),H('#8A94A2')],pit=H('#4A515C'),
   prim=(H('#5B86B8'),H('#9CC0E8'),H('#2E4C74')),sec=(H('#A9B2BF'),H('#EAF2FB'),H('#5C6573')),dis=(H('#6A7078'),H('#7A8088'),H('#4A4E56'))),
 'gilt':dict(mid=H('#2E2B36'),hi=H('#56506A'),lo=H('#141219'),rivet=H('#F2C14E'),rust=[H('#B8862A'),H('#F2C14E'),H('#8A6420')],pit=H('#0F0D14'),
   prim=(H('#D9A93A'),H('#FFE08A'),H('#8A6420')),sec=(H('#34313E'),H('#56506A'),H('#17151D')),dis=(H('#3A3844'),H('#46434F'),H('#25232D'))),
}
IRON0=dict(IRON); IRON0['rust']=list(IRON['rust'])
INNER0=dict(K.INNER)
def set_mat(name):
    src=IRON0 if MATS[name] is None else MATS[name]
    for k in ('mid','hi','lo','rivet','rust','pit'): IRON[k]=src[k]
    K.CURMAT=name
def mk_button(kind,state):
    name=K.CURMAT; m=MATS[name]
    if m is None:
        prim=(H('#8A5A2B'),H('#C98B4A'),H('#4F3016')); sec=(IRON0['mid'],IRON0['hi'],IRON0['lo']); dis=(H('#3E3A44'),H('#4E4A56'),H('#2A2730'))
    else: prim,sec,dis=m['prim'],m['sec'],m['dis']
    f,hi,lo=sec if kind=='secondary' else prim
    if state=='disabled': f,hi,lo=dis
    im=new(24,16); d=ImageDraw.Draw(im)
    for r in ((2,0,21,15),(0,2,23,13),(1,1,22,14)): d.rectangle(r,fill=INK)
    d.rectangle((2,2,21,13),fill=f); d.rectangle((1,3,22,12),fill=f)
    if state=='pressed':
        d.rectangle((2,2,21,13),fill=tuple(int(v*.85) for v in f[:3])+(255,)); d.line([(3,3),(20,3)],fill=lo)
    else:
        d.line([(3,2),(20,2)],fill=hi); d.line([(1,4),(1,11)],fill=hi); d.line([(3,13),(20,13)],fill=lo); d.line([(22,4),(22,11)],fill=lo)
    if state!='disabled':
        rv=IRON['rivet'] if kind=='secondary' else (H('#E8C48A') if name!='silver' else H('#FFFFFF'))
        for x,y in ((3,4),(19,4),(3,10),(19,10)): d.point((x,y),fill=rv)
        if name=='wood':      # grain on the plank button
            rnd=random.Random(4)
            for _ in range(6): x=rnd.randrange(5,18); y=rnd.randrange(4,12); d.line([(x,y),(x+2,y)],fill=lo)
        if name=='silver' and kind=='secondary': d.line([(5,7),(18,7)],fill=lo)           # an engraved line
        if name=='gilt': d.line([(4,3),(19,3)],fill=hi) if kind=='primary' else d.line([(4,12),(19,12)],fill=H('#B8862A'))
    else:
        rnd=random.Random(2)
        for _ in range(8): d.point((rnd.randrange(3,21),rnd.randrange(3,13)),fill=lo)
    return im
K.button=mk_button
BAND={'panel_dark':(2,3),'panel_parchment':(2,3),'hud_panel':(1,2),'dialog':(2,4),'tab':(2,2),'chip':(2,2),'divider':(1,2)}
def decorate(name,im):
    mat=K.CURMAT
    if mat=='iron' or name not in BAND: return im
    ink,band=BAND[name]; w,h=im.size; px=im.load(); rnd=random.Random(hash(name)%999)
    def inband(x,y): d_=min(x,y,w-1-x,h-1-y); return ink<=d_<ink+band
    if mat=='wood':
        for _ in range(w*h//9):                      # grain: short dark strokes along the band, a few knots
            x,y=rnd.randrange(w),rnd.randrange(h)
            if inband(x,y) and px[x,y][3]: 
                horiz=min(y,h-1-y)<min(x,w-1-x); col=IRON['lo']
                px[x,y]=col
                if horiz and x+1<w and inband(x+1,y): px[x+1,y]=col
                if not horiz and y+1<h and inband(x,y+1): px[x,y+1]=col
        if name in ('panel_dark','panel_parchment','dialog','hud_panel'):       # nail heads along the edges
            for x in range(6,w-6,6): px[x,ink+band//2]=(60,56,64,255) if px[x,ink+band//2][3] else px[x,ink+band//2]
    elif mat=='silver':
        d=min(1+ink,ink+band-1)
        for x in range(w):
            for y in range(h):
                if px[x,y][3] and min(x,y,w-1-x,h-1-y)==ink+band//2 and band>=3 and (x+y)%2==0 and min(x,y,w-1-x,h-1-y)<min(w,h)//2-2: px[x,y]=IRON['lo']      # engraved dotted line
        for _ in range(3):
            x,y=rnd.randrange(w),rnd.randrange(h)
            if inband(x,y) and px[x,y][3]: px[x,y]=(255,255,255,255)
    elif mat=='gilt':
        for x in range(w):
            for y in range(h):
                if px[x,y][3] and min(x,y,w-1-x,h-1-y)==ink+band-1 and band>=2: px[x,y]=H('#B8862A')      # a gilt inner edge
        for x in range(4,w-4,5):
            if band>=3 and px[x,ink+1][3]: px[x,ink+1]=H('#F2C14E')
    return im
def build(mat):
    set_mat(mat); out=O+mat+'/ui/'; os.makedirs(out,exist_ok=True)
    for k,(fn,m) in UI.items():
        im=decorate(k,fn()); im.save(out+k+'.png',optimize=True)
    return out
def load(mat,k): return Image.open(f'{O}{mat}/ui/{k}.png').convert('RGBA')
def apply_env(base,env,seed=1,edges=True):
    return K.apply_env(base,env,seed,edges)
if __name__=='__main__':
    tiers=['wood','iron','silver','gilt']
    for t in tiers: build(t)
    json.dump({'tiers':tiers,'note':'same file names, sizes and 9-slice margins as art/pixellab-iron-kit/anchors.json; env decorations (art/pixellab-iron-kit/env/) are separate and sit on every tier','order':['wood','iron','silver','gilt']},open(O+'tiers.json','w'),indent=1)
    LIGHT=(233,224,201); DARK=(31,28,35); F=ImageFont.load_default(size=13)
    def stage(mat,bg,sc,env=None):
        pan=stretch(load(mat,'panel_dark'),72,52,8); b1=stretch(load(mat,'button_secondary_normal'),56,18,6); b2=stretch(load(mat,'button_primary_normal'),56,18,6)
        if env: pan=apply_env(pan,env); b1=apply_env(b1,env,2,edges=False); b2=apply_env(b2,env,3,edges=False)
        t=Image.new('RGB',(72+8+56+8,56),bg); t.paste(pan,(0,2),pan); t.paste(b1,(80,4),b1); t.paste(b2,(80,28),b2); return t.resize((t.width*sc,t.height*sc),Image.NEAREST)
    rowh=56*3+14; sh=Image.new('RGB',(2*(150+450)+30,len(tiers)*rowh+20),LIGHT); d=ImageDraw.Draw(sh)
    for half,bg in enumerate((LIGHT,DARK)):
        x0=10+half*610; d.rectangle((x0-5,0,x0+605,sh.height),fill=bg)
        for r,t in enumerate(tiers):
            y=10+r*rowh; d.text((x0,y),t,font=F,fill=(35,31,26) if half==0 else (233,224,201)); sh.paste(stage(t,bg,1),(x0,y+20)); sh.paste(stage(t,bg,3),(x0+150,y))
    sh.save('docs/art/boards/materials-tiers.png')
    # the ladder: four tiers side by side, plus the dialog and HUD panel; and the environment decorations on every material
    lad=Image.new('RGB',(4*330+20,420),DARK); d2=ImageDraw.Draw(lad)
    for i,t in enumerate(tiers):
        x=10+i*330; d2.text((x,4),f'{i+1}. {t}',font=F,fill=(233,224,201)); lad.paste(stage(t,DARK,2) if False else stage(t,DARK,1).resize((152*2,56*2),Image.NEAREST),(x,24))
        dlg=stretch(load(t,'dialog'),72,56,12); hud=stretch(load(t,'hud_panel'),72,24,5)
        lad.paste(dlg.resize((144,112),Image.NEAREST),(x,24+130),dlg.resize((144,112),Image.NEAREST)); lad.paste(hud.resize((144,48),Image.NEAREST),(x,24+130+120),hud.resize((144,48),Image.NEAREST))
        for j,env in enumerate(('frost','wilds','ash')):
            if j<3: pass
        e=Image.new('RGB',(210,70),DARK)
        for j,env in enumerate(('frost','wilds','ash')):
            pn=stretch(load(t,'panel_dark'),64,44,8); pn=apply_env(pn,env); e.paste(pn,(j*68,4),pn)
        lad.paste(e.resize((420,140),Image.NEAREST).crop((0,0,300,140)),(x,24+130+180))
    lad.save('docs/art/boards/materials-ladder.png'); print(lad.size, sh.size)
