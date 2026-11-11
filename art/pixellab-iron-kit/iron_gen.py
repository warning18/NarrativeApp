"""Old-iron UI kit + separate environment decoration sprites, hand-drawn in code (0 generations).
Run from the repo root: python3 art/pixellab-iron-kit/iron_gen.py
ui/: panel_dark, panel_parchment (24x24, slice 8), hud_panel (16x16, slice 5), button_{primary,secondary}_{normal,pressed,disabled} (24x16, slice 6),
     tab (20x14, slice 6), chip (16x12, slice 5), corner (12x12), divider (24x6, slice 8), dialog (32x32, slice 12)
env/: <env>_{top,bottom,corner}_<n>.png: transparent sprites, 3 variants per anchor; anchors in anchors.json"""
import json, os, random, math
from PIL import Image, ImageDraw
def H(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))+(255,)
INK=H('#0A0807')
IRON=dict(mid=H('#514C5A'),hi=H('#8A8497'),lo=H('#2E2A35'),rivet=H('#C9C3D3'),rust=[H('#7A3D1C'),H('#9A5428'),H('#B8702F')],pit=H('#1F1B24'))
INNER={'dark':H('#26202C'),'parchment':H('#E4D7B6')}
O='art/pixellab-iron-kit/'
def new(w,h): return Image.new('RGBA',(w,h),(0,0,0,0))
def iron_frame(w,h,inner,ink=2,band=3,chamfer=3,seed=1,rivets=True,rust=True,line_inner=True):
    rnd=random.Random(seed); im=new(w,h); d=ImageDraw.Draw(im)
    def box(inset,col):
        x0=inset; y0=inset; x1=w-1-inset; y1=h-1-inset; c=max(0,chamfer-inset)
        d.rectangle((x0+c,y0,x1-c,y1),fill=col); d.rectangle((x0,y0+c,x1,y1-c),fill=col)
    box(0,INK); box(ink,IRON['mid'])
    b0=ink; b1=ink+band
    # bevel on the band: light top-left edge, shade bottom-right edge
    d.line([(b0+chamfer-1,b0),(w-1-b0-chamfer+1,b0)],fill=IRON['hi']); d.line([(b0,b0+chamfer-1),(b0,h-1-b0-chamfer+1)],fill=IRON['hi'])
    d.line([(b0+chamfer-1,h-1-b0),(w-1-b0-chamfer+1,h-1-b0)],fill=IRON['lo']); d.line([(w-1-b0,b0+chamfer-1),(w-1-b0,h-1-b0-chamfer+1)],fill=IRON['lo'])
    # inner field
    ix0,iy0,ix1,iy1=b1,b1,w-1-b1,h-1-b1
    d.rectangle((ix0,iy0,ix1,iy1),fill=INK if line_inner else inner); d.rectangle((ix0+1,iy0+1,ix1-1,iy1-1),fill=inner)
    d.line([(ix0+1,iy0+1),(ix1-1,iy0+1)],fill=tuple(int(v*.7) for v in inner[:3])+(255,))
    if rust:   # old iron: rust patches and pits on the band only
        pix=im.load()
        for _ in range(int(w*h*.05)):
            x,y=rnd.randrange(w),rnd.randrange(h)
            if b0<=min(x,y,w-1-x,h-1-y)<b1 and pix[x,y][3]:
                pix[x,y]=rnd.choice(IRON['rust']) if rnd.random()<.6 else IRON['pit']
                if rnd.random()<.4 and x+1<w-b0: pix[x+1,y]=pix[x,y]
    if rivets:
        for x,y in ((b0+1,b0+1),(w-b0-3,b0+1),(b0+1,h-b0-3),(w-b0-3,h-b0-3)):
            d.rectangle((x,y,x+1,y+1),fill=IRON['rivet']); d.point((x+1,y+1),fill=IRON['lo'])
    return im
def stretch(im,w,h,m):
    s=im.size; out=new(w,h)
    xs=[(0,m,0,m),(m,s[0]-m,m,w-m),(s[0]-m,s[0],w-m,w)]; ys=[(0,m,0,m),(m,s[1]-m,m,h-m),(s[1]-m,s[1],h-m,h)]
    for sx0,sx1,dx0,dx1 in xs:
        for sy0,sy1,dy0,dy1 in ys:
            if dx1>dx0 and dy1>dy0: out.alpha_composite(im.crop((sx0,sy0,sx1,sy1)).resize((dx1-dx0,dy1-dy0),Image.NEAREST),(dx0,dy0))
    return out
# ---------------- UI pieces ----------------
def panel(kind): return iron_frame(24,24,INNER[kind],seed=3)
def hud_panel(): return iron_frame(16,16,H('#1B1620'),ink=1,band=2,chamfer=2,seed=4,rivets=False,line_inner=False)
def button(kind,state):
    base={'primary':(H('#8A5A2B'),H('#C98B4A'),H('#4F3016')),'secondary':(IRON['mid'],IRON['hi'],IRON['lo'])}[kind]
    f,hi,lo=base
    if state=='disabled': f,hi,lo=H('#3E3A44'),H('#4E4A56'),H('#2A2730')
    im=new(24,16); d=ImageDraw.Draw(im)
    for r in ((2,0,21,15),(0,2,23,13),(1,1,22,14)): d.rectangle(r,fill=INK)
    d.rectangle((2,2,21,13),fill=f); d.rectangle((1,3,22,12),fill=f)
    if state=='pressed':
        d.rectangle((2,2,21,13),fill=tuple(int(v*.85) for v in f[:3])+(255,)); d.line([(3,3),(20,3)],fill=lo)
    else:
        d.line([(3,2),(20,2)],fill=hi); d.line([(1,4),(1,11)],fill=hi); d.line([(3,13),(20,13)],fill=lo); d.line([(22,4),(22,11)],fill=lo)
    if state!='disabled':
        for x,y in ((3,4),(19,4),(3,10),(19,10)): d.point((x,y),fill=IRON['rivet'] if kind=='secondary' else H('#E8C48A'))
    else:
        rnd=random.Random(2)
        for _ in range(8): d.point((rnd.randrange(3,21),rnd.randrange(3,13)),fill=H('#2A2730'))
    return im
def tab():
    im=new(20,14); d=ImageDraw.Draw(im)
    d.rectangle((3,0,16,13),fill=INK); d.rectangle((0,3,19,13),fill=INK); d.rectangle((3,2,16,13),fill=IRON['mid']); d.rectangle((2,3,17,13),fill=IRON['mid'])
    d.line([(3,2),(16,2)],fill=IRON['hi']); d.line([(2,3),(2,13)],fill=IRON['hi']); d.line([(17,3),(17,13)],fill=IRON['lo']); d.point((5,6),fill=IRON['rivet']); d.point((14,6),fill=IRON['rivet']); return im
def chip():
    im=new(16,12); d=ImageDraw.Draw(im)
    d.rectangle((2,0,13,11),fill=INK); d.rectangle((0,2,15,9),fill=INK); d.rectangle((2,2,13,9),fill=IRON['mid']); d.rectangle((1,3,14,8),fill=IRON['mid'])
    d.line([(2,2),(13,2)],fill=IRON['hi']); d.line([(2,9),(13,9)],fill=IRON['lo']); return im
def corner():
    im=new(12,12); d=ImageDraw.Draw(im)
    d.rectangle((0,0,11,3),fill=INK); d.rectangle((0,0,3,11),fill=INK); d.rectangle((1,1,10,2),fill=IRON['mid']); d.rectangle((1,1,2,10),fill=IRON['mid'])
    d.line([(1,1),(10,1)],fill=IRON['hi']); d.line([(1,1),(1,10)],fill=IRON['hi']); d.rectangle((2,2,3,3),fill=IRON['rivet']); d.point((3,3),fill=IRON['lo'])
    d.point((6,2),fill=IRON['rust'][1]); d.point((2,7),fill=IRON['rust'][0]); return im
def divider():
    im=new(24,6); d=ImageDraw.Draw(im)
    d.rectangle((0,1,23,4),fill=INK); d.rectangle((0,2,23,3),fill=IRON['mid']); d.line([(0,2),(23,2)],fill=IRON['hi']); d.line([(0,3),(23,3)],fill=IRON['lo'])
    for x in (2,21): d.rectangle((x,1,x+1,4),fill=IRON['rivet']); d.point((x+1,4),fill=INK)
    d.point((12,2),fill=IRON['rust'][1]); d.point((9,3),fill=IRON['rust'][0]); return im
def dialog():
    im=iron_frame(32,32,INNER['parchment'],ink=2,band=4,chamfer=4,seed=7)
    d=ImageDraw.Draw(im)
    for x,y in ((2,2),(26,2),(2,26),(26,26)): d.rectangle((x,y,x+3,y+3),fill=INK); d.rectangle((x+1,y+1,x+2,y+2),fill=IRON['rivet'])
    return im
UI={'panel_dark':(lambda:panel('dark'),8),'panel_parchment':(lambda:panel('parchment'),8),'hud_panel':(hud_panel,5),'tab':(tab,6),'chip':(chip,5),'corner':(corner,None),'divider':(divider,8),'dialog':(dialog,12)}
for k in ('primary','secondary'):
    for st in ('normal','pressed','disabled'): UI[f'button_{k}_{st}']=((lambda k=k,st=st:button(k,st)),6)
# ---------------- environment decorations ----------------
def dec(w,h,fn,seed):
    im=new(w,h); d=ImageDraw.Draw(im); rnd=random.Random(seed); fn(im,d,rnd,w,h); return im
def px(d,x,y,c):
    d.point((int(x),int(y)),fill=c)
def outline(im):
    w,h=im.size; src=im.load(); out=new(w,h); o=out.load()
    for y in range(h):
        for x in range(w):
            if src[x,y][3]: o[x,y]=src[x,y]
            elif any(0<=x+dx<w and 0<=y+dy<h and src[x+dx,y+dy][3] for dx,dy in ((1,0),(-1,0),(0,1),(0,-1))): o[x,y]=INK
    return out
G=dict(leaf=H('#5E9A3A'),leaf_d=H('#2E5A1C'),moss=H('#7DBE6A'),
 sand=H('#D9BE82'),sand_d=H('#A8864A'),peb=H('#7A6A55'),
 snow=H('#F5F9FC'),snow_d=H('#B9D3E6'),ice=H('#9FD0E8'),
 salt=H('#E8E2D0'),barn=H('#A8A194'),rope=H('#B58A4A'),rope_d=H('#7A5A2B'),
 soot=H('#2A2326'),ember=H('#E0762B'),ember_l=H('#F2C14E'),
 stain=H('#3A3236'),hook=H('#6B6356'),lantern=H('#F2C14E'),
 wax=H('#F0E6C8'),wax_d=H('#C9BC96'),flame=H('#F2C14E'),crack=H('#A987EA'),crack_d=H('#6A4FB0'))
# every env: top(32x10, hangs from the top edge), bottom(32x8, grows from the bottom edge), corner(16x16, top-left; mirror for the others)
def top_wilds(im,d,r,w,h):
    for x in range(1,w,r.choice((3,4,5))):
        L=r.randrange(3,h-1)
        for y in range(L): px(d,x+(1 if y%3==2 else 0),y,G['leaf_d'] if y%2 else G['leaf'])
        if r.random()<.6: px(d,x+2,L-1,G['moss']); px(d,x+3,L-2,G['leaf'])
def bottom_wilds(im,d,r,w,h):
    for x in range(0,w):
        if r.random()<.7:
            for y in range(h-1,h-1-r.randrange(1,5),-1): px(d,x,y,G['moss'] if r.random()<.6 else G['leaf'])
    for _ in range(3): x=r.randrange(2,w-2); y=h-r.randrange(3,6); d.rectangle((x,y,x+1,y+1),fill=G['leaf']); px(d,x+1,y+1,G['leaf_d'])
def corner_wilds(im,d,r,w,h):
    x,y=1,1
    for i in range(14): 
        px(d,x,y,G['leaf_d']); x+=1 if r.random()<.6 else 0; y+=1 if r.random()<.7 else 0
        if i%3==1: d.rectangle((x+1,y,x+2,y+1),fill=G['leaf']); px(d,x+2,y+1,G['moss'])
    for k in range(w): px(d,k,0,G['moss']) if r.random()<.5 else None
def top_dunes(im,d,r,w,h):
    for x in range(w):
        for y in range(r.randrange(0,3) if (x//4)%2 else r.randrange(1,5)): px(d,x,y,G['sand'] if y<2 else G['sand_d'])
def bottom_dunes(im,d,r,w,h):
    for x in range(w):
        t=int(2+2*math.sin(x/5+r.random()*.3))
        for y in range(h-1,h-1-t,-1): px(d,x,y,G['sand_d'] if y>=h-1 else G['sand'])
    for _ in range(4): x=r.randrange(w-2); y=h-r.randrange(3,6); d.rectangle((x,y,x+1,y+1),fill=G['peb'])
def corner_dunes(im,d,r,w,h):
    for y in range(7):
        for x in range(7-y):
            px(d,x,y,G['sand'] if x+y<5 else G['sand_d'])
    for _ in range(3): px(d,r.randrange(1,8),r.randrange(1,8),G['peb'])
def top_frost(im,d,r,w,h):
    for x in range(w):
        for y in range(2): px(d,x,y,G['snow'] if y==0 else G['snow_d'])
    x=1
    while x<w-2:
        L=r.randrange(3,h-1)
        for y in range(2,2+L): px(d,x,y,G['ice']); 
        px(d,x,2+L,G['snow']); x+=r.choice((3,4,5))
def bottom_frost(im,d,r,w,h):
    for x in range(w):
        t=r.randrange(2,5)
        for y in range(h-1,h-1-t,-1): px(d,x,y,G['snow'] if y<h-1 else G['snow_d'])
def corner_frost(im,d,r,w,h):
    for y in range(6):
        for x in range(9-y): px(d,x,y,G['snow'] if x+y<7 else G['snow_d'])
    for k in range(3): px(d,3+k*2,6,G['ice']); px(d,3+k*2,7,G['ice']) if k%2==0 else None
def top_coast(im,d,r,w,h):
    x=1
    while x<w-3:
        if r.random()<.5: d.rectangle((x,0,x+2,2),fill=G['barn']); px(d,x+1,1,G['salt']); x+=4
        else:
            L=r.randrange(4,h-1)
            for y in range(L): px(d,x,y,G['rope'] if y%2 else G['rope_d'])
            x+=3
    for k in range(w): px(d,k,0,G['salt']) if r.random()<.4 else None
def bottom_coast(im,d,r,w,h):
    for x in range(w):
        if r.random()<.55: px(d,x,h-1,G['salt']); 
        if r.random()<.25: d.rectangle((x,h-3,x+1,h-2),fill=G['barn'])
    for _ in range(3): x=r.randrange(w-3); d.rectangle((x,h-4,x+2,h-2),fill=G['barn']); px(d,x+1,h-3,G['salt'])
def corner_coast(im,d,r,w,h):
    for i in range(8): px(d,i,i//2,G['rope'] if i%2 else G['rope_d']); px(d,i,i//2+1,G['rope_d'])
    for k in range(4): d.rectangle((1+k*3,6+(k%2),3+k*3,8+(k%2)),fill=G['barn']); px(d,2+k*3,7+(k%2),G['salt'])
def top_ash(im,d,r,w,h):
    for x in range(w):
        for y in range(r.randrange(1,4)): px(d,x,y,G['soot'])
    for _ in range(3): px(d,r.randrange(w),r.randrange(3,h),G['ember'] if r.random()<.5 else G['ember_l'])
def bottom_ash(im,d,r,w,h):
    for x in range(w):
        for y in range(h-1,h-1-r.randrange(1,4),-1): px(d,x,y,G['soot'])
    for _ in range(3): px(d,r.randrange(w),h-r.randrange(2,5),G['ember'])
def corner_ash(im,d,r,w,h):
    for y in range(8):
        for x in range(8-y): px(d,x,y,G['soot'])
    for _ in range(3): px(d,r.randrange(1,6),r.randrange(1,6),G['ember'])
    px(d,9,2,G['ember_l']); px(d,2,9,G['ember'])
def top_city(im,d,r,w,h):
    for _ in range(5):
        x=r.randrange(w-3); L=r.randrange(2,h)
        for y in range(L): px(d,x,y,G['stain']); px(d,x+1,y,G['stain']) if r.random()<.5 else None
    if r.random()<.7:   # a lantern hook with a lantern
        x=r.randrange(8,w-8); d.line([(x,0),(x,3)],fill=G['hook']); d.rectangle((x-1,4,x+1,7),fill=G['lantern']); d.rectangle((x-1,3,x+1,3),fill=G['hook']); px(d,x,8,G['hook'])
def bottom_city(im,d,r,w,h):
    for _ in range(4): x=r.randrange(w-5); d.rectangle((x,h-r.randrange(2,4),x+r.randrange(2,5),h-1),fill=G['stain'])
def corner_city(im,d,r,w,h):
    for _ in range(7): px(d,r.randrange(0,9),r.randrange(0,9),G['stain'])
    d.line([(2,1),(2,5)],fill=G['hook']); d.line([(2,5),(5,5)],fill=G['hook']); d.rectangle((5,5,6,7),fill=G['lantern'])
def top_sacred(im,d,r,w,h):
    x=1
    while x<w-2:
        L=r.randrange(2,h-1)
        for y in range(L): px(d,x,y,G['wax'] if y<L-1 else G['wax_d'])
        d.rectangle((x-1,L-1,x+1,L),fill=G['wax_d']) if r.random()<.4 else None; x+=r.choice((3,4,6))
def bottom_sacred(im,d,r,w,h):
    for x in range(w):
        if r.random()<.35: px(d,x,h-1,G['crack_d']); px(d,x+1,h-2,G['crack'])
    x=r.randrange(4,w-6); d.rectangle((x,h-4,x+1,h-2),fill=G['wax']); px(d,x,h-5,G['flame']); px(d,x,h-6,G['ember_l'])
def corner_sacred(im,d,r,w,h):
    pts=[(1,1),(2,2),(3,2),(4,3),(4,4),(5,5),(6,6),(7,6)]
    for p in pts: px(d,*p,G['crack'])
    for p in pts[::2]: px(d,p[0]+1,p[1]+1,G['crack_d'])
    for x in range(1,6): px(d,x,0,G['wax']) if r.random()<.7 else None
ENVS={'wilds':(top_wilds,bottom_wilds,corner_wilds),'dunes':(top_dunes,bottom_dunes,corner_dunes),'frost':(top_frost,bottom_frost,corner_frost),'coast':(top_coast,bottom_coast,corner_coast),'ash':(top_ash,bottom_ash,corner_ash),'city':(top_city,bottom_city,corner_city),'sacred_void':(top_sacred,bottom_sacred,corner_sacred)}
def make_env(name,i,kind,fn,seed):
    sizes={'top':(32,10),'bottom':(32,8),'corner':(16,16)}; w,h=sizes[kind]
    return outline(dec(w,h,fn,seed))
def apply_env(base,name,seed=1,edges=True):
    """layer an environment's separate sprites on a stretched frame: top, bottom edges (tiled, variants cycled) and the corners"""
    w,h=base.size; out=base.copy(); rnd=random.Random(seed)
    def tile(kind,y,anchor_bottom=False):
        x=0; i=0
        while x<w:
            s=Image.open(f'{O}env/{name}_{kind}_{i%3}.png'); yy=y if not anchor_bottom else y-s.height
            out.alpha_composite(s.crop((0,0,min(s.width,w-x),s.height)),(x,yy)); x+=s.width-4; i+=1
    if edges: tile('top',1); tile('bottom',h-1,True)
    for k,(flip_x,flip_y) in enumerate(((False,False),(True,False))):
        s=Image.open(f'{O}env/{name}_corner_{k}.png')
        if flip_x: s=s.transpose(Image.FLIP_LEFT_RIGHT)
        out.alpha_composite(s,(w-s.width-1 if flip_x else 1,1))
    return out
if __name__=='__main__':
    anchors={'ui':{},'env':{}}
    for k,(fn,m) in UI.items():
        im=fn(); im.save(f'{O}ui/{k}.png',optimize=True); anchors['ui'][k]={'size':list(im.size),'slice':m}
    for name,(t,b,c) in ENVS.items():
        for i in range(3):
            for kind,fn in (('top',t),('bottom',b),('corner',c)):
                im=make_env(name,i,kind,fn,seed=hash((name,kind,i))%9999+i*7 if False else (sum(map(ord,name))*31+i*17+len(kind)*5))
                im.save(f'{O}env/{name}_{kind}_{i}.png',optimize=True)
        anchors['env'][name]={'top':{'files':[f'{name}_top_{i}.png' for i in range(3)],'size':[32,10],'anchor':'top edge, sprite top = panel outer top; tile horizontally, cycle variants, overlap 4 px'},
                              'bottom':{'files':[f'{name}_bottom_{i}.png' for i in range(3)],'size':[32,8],'anchor':'bottom edge, sprite bottom = panel outer bottom; tile horizontally'},
                              'corner':{'files':[f'{name}_corner_{i}.png' for i in range(3)],'size':[16,16],'anchor':'top-left outer corner; mirror horizontally for top-right (and vertically for the bottom corners)'}}
    json.dump(anchors,open(O+'anchors.json','w'),indent=1)
    # ---------- sheet ----------
    LIGHT=(233,224,201); DARK=(31,28,35)
    def stage(bg,env,sc):
        pan=stretch(Image.open(f'{O}ui/panel_dark.png'),72,52,8); btn=stretch(Image.open(f'{O}ui/button_secondary_normal.png'),56,18,6)
        btp=stretch(Image.open(f'{O}ui/button_primary_normal.png'),56,18,6)
        if env: pan=apply_env(pan,env); btn=apply_env(btn,env,2,edges=False); btp=apply_env(btp,env,3,edges=False)
        tile=Image.new('RGB',(72+8+56+8,52+4),bg); tile.paste(pan,(0,2),pan); tile.paste(btn,(80,4),btn); tile.paste(btp,(80,28),btp)
        return tile.resize((tile.width*sc,tile.height*sc),Image.NEAREST)
    names=[None]+list(ENVS)
    from PIL import ImageFont
    F=ImageFont.load_default(size=13)
    rowh=52*3+12; sh=Image.new('RGB',(2*(150+450)+30,len(names)*rowh+20),LIGHT); d=ImageDraw.Draw(sh)
    for half,bg in enumerate((LIGHT,DARK)):
        x0=10+half*(600+10); d.rectangle((x0-5,0,x0+605,sh.height),fill=bg)
        for r,env in enumerate(names):
            y=10+r*rowh; d.text((x0,y),(env or 'plain old iron'),font=F,fill=(35,31,26) if half==0 else (233,224,201))
            one=stage(bg,env,1); sh.paste(one,(x0,y+20)); sh.paste(stage(bg,env,3),(x0+150,y))
    sh.save('docs/art/boards/iron-kit.png'); print(sh.size)
    # a second sheet with every UI piece, each in its own cell (stretched by its 9-slice, then 2x)
    pcs=['panel_dark','panel_parchment','hud_panel','dialog','tab','chip','divider','corner','button_primary_normal','button_primary_pressed','button_primary_disabled','button_secondary_normal','button_secondary_pressed','button_secondary_disabled']
    SZ={'panel_dark':(64,44),'panel_parchment':(64,44),'hud_panel':(64,28),'dialog':(64,52),'tab':(48,20),'chip':(44,16),'divider':(64,6),'corner':(12,12)}
    cw,chh=150,100; cols=5; rows=(len(pcs)+cols-1)//cols
    sh2=Image.new('RGB',(2*cols*cw//1,rows*chh+20),LIGHT)
    sh2=Image.new('RGB',(cols*cw*2+30,rows*chh+20),LIGHT); d2=ImageDraw.Draw(sh2)
    for half,bg in enumerate((LIGHT,DARK)):
        x0=10+half*(cols*cw+10); d2.rectangle((x0-5,0,x0+cols*cw+5,sh2.height),fill=bg)
        for n,k in enumerate(pcs):
            im=Image.open(f'{O}ui/{k}.png'); m=anchors['ui'][k]['slice']
            sz=SZ.get(k,(56,20)); v=stretch(im,sz[0],sz[1],m) if m else im
            v=v.resize((v.width*2,v.height*2),Image.NEAREST); cx=x0+(n%cols)*cw; cy=8+(n//cols)*chh
            sh2.paste(v,(cx,cy+14),v); d2.text((cx,cy),k,font=F,fill=(110,102,90))
    sh2.save('docs/art/boards/iron-kit-pieces.png')
