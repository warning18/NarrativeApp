"""Race (5) and calling (5) icons WITHOUT a square plate, at 16, 32 and 48 px; two options. Hand-drawn from unit-coordinate shapes, rasterised without anti-aliasing
at each size, then a 1 px (16, 32) or 2 px (48) ink outline and a top-left light / bottom-right shade bevel. 0 generations. Repo root:
python3 art/pixellab-emblems/emblems_gen.py
A: free-standing emblems (no container).  B: races on a heater shield, callings on a hanging banner (non-square containers)."""
import os, json, math
from PIL import Image, ImageDraw, ImageFont
def H(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))+(255,)
INK=H('#0A0807'); C={'gold':H('#F2C14E'),'gold_d':H('#B8862A'),'red':H('#C23B33'),'red_d':H('#7A1F24'),'cream':H('#FAF2DA'),'bone':H('#E9DFC4'),'steel':H('#A8A194'),'steel_d':H('#6B6356'),
 'teal':H('#2B8A8A'),'teal_d':H('#1E5E5E'),'leaf':H('#5E9A3A'),'leaf_d':H('#2E5A1C'),'green':H('#4F7A36'),'green_d':H('#2F4A22'),'wood':H('#8A5A2B'),'wood_d':H('#5A3A1C'),'void':H('#A987EA'),'void_d':H('#4A3C80'),'white':H('#FFFFFF'),'blue':H('#3556A0'),'rust':H('#B5601C'),'char':H('#4A4558')}
O='art/pixellab-emblems/'
# ---- shapes in unit coordinates (0..1): ('poly',pts,col) ('rect',x0,y0,x1,y1,col) ('ell',cx,cy,rx,ry,col) ('line',x0,y0,x1,y1,w,col)
def S(name):
    c=lambda k:C[k]
    return {
 'human':[('rect',.40,.04,.60,.96,'gold'),('rect',.08,.30,.92,.50,'gold'),('poly',[(.36,.04),(.64,.04),(.6,.14),(.4,.14)],'gold'),('poly',[(.36,.96),(.64,.96),(.6,.86),(.4,.86)],'gold'),('poly',[(.08,.26),(.08,.54),(.18,.5),(.18,.3)],'gold'),('poly',[(.92,.26),(.92,.54),(.82,.5),(.82,.3)],'gold'),('poly',[(.5,.31),(.58,.4),(.5,.49),(.42,.4)],'red')],
 'elf':[('poly',[(.5,.03),(.84,.28),(.84,.62),(.5,.97),(.16,.62),(.16,.28)],'leaf'),('poly',[(.5,.03),(.84,.28),(.84,.62),(.5,.97)],'leaf_d'),('line',.5,.16,.5,.9,.06,'cream'),('line',.5,.4,.72,.28,.04,'cream'),('line',.5,.55,.28,.4,.04,'cream'),('line',.5,.7,.7,.58,.04,'cream')],
 'dwarf':[('poly',[(.0,.26),(.2,.26),(.2,.46),(.1,.46)],'steel'),('rect',.14,.26,.94,.48,'steel'),('rect',.14,.26,.94,.32,'bone'),('rect',.34,.48,.7,.72,'steel_d'),('rect',.2,.72,.84,.94,'steel'),('rect',.2,.88,.84,.94,'steel_d'),('ell',.78,.12,.06,.06,'gold'),('ell',.62,.06,.035,.035,'gold_d')],
 'orc':[('poly',[(.08,.08),(.42,.08),(.42,.5),(.3,.94),(.14,.56)],'cream'),('poly',[(.92,.08),(.58,.08),(.58,.5),(.7,.94),(.86,.56)],'cream'),('rect',.44,.08,.56,.62,'green'),('poly',[(.4,.62),(.6,.62),(.5,.82)],'red'),('rect',.44,.08,.56,.18,'green_d')],
 'voidkin':[('poly',[(.5,.02),(.72,.4),(.5,.98),(.28,.4)],'void'),('poly',[(.5,.02),(.72,.4),(.5,.5)],'void_d'),('poly',[(.5,.2),(.58,.4),(.5,.7),(.42,.4)],'white'),('poly',[(.1,.5),(.2,.4),(.24,.62)],'void'),('poly',[(.9,.5),(.8,.4),(.76,.62)],'void')],
 'warrior':[('line',.15,.85,.85,.15,.14,'steel'),('line',.15,.85,.85,.15,.05,'white'),('line',.22,.55,.45,.78,.1,'gold'),('line',.1,.9,.22,.78,.1,'wood'),('ell',.82,.18,.07,.07,'gold')],
 'mage':[('line',.12,.9,.62,.38,.1,'wood'),('poly',[(.62,.04),(.9,.3),(.62,.56),(.4,.3)],'void'),('poly',[(.62,.04),(.9,.3),(.62,.3)],'void_d'),('ell',.62,.28,.08,.08,'white'),('poly',[(.12,.12),(.17,.2),(.26,.22),(.17,.26),(.12,.34),(.07,.26),(.0,.22),(.07,.2)],'gold')],
 'ranger':[('line',.3,.06,.18,.5,.08,'wood_d'),('line',.18,.5,.3,.94,.08,'wood_d'),('line',.3,.06,.3,.94,.04,'bone'),('line',.18,.5,.92,.5,.06,'wood'),('poly',[(.92,.5),(.74,.36),(.74,.64)],'steel'),('poly',[(.2,.42),(.34,.5),(.2,.58)],'red')],
 'rogue':[('line',.14,.14,.86,.86,.12,'steel'),('line',.86,.14,.14,.86,.12,'steel'),('line',.14,.14,.86,.86,.04,'white'),('line',.86,.14,.14,.86,.04,'white'),('ell',.5,.5,.09,.09,'gold'),('line',.04,.96,.16,.84,.1,'char'),('line',.96,.96,.84,.84,.1,'char')],
 'cleric':[('poly',[(.5,.02),(.62,.38),(.98,.5),(.62,.62),(.5,.98),(.38,.62),(.02,.5),(.38,.38)],'gold'),('poly',[(.5,.02),(.62,.38),(.5,.5),(.38,.38)],'cream'),('ell',.5,.5,.1,.1,'cream')],
 }[name]
SHIELD=[('poly',[(.06,.04),(.94,.04),(.94,.52),(.5,.98),(.06,.52)],'#')]    # colour filled by the caller
BANNER=[('rect',.04,.02,.96,.12,'wood_d'),('poly',[(.1,.12),(.9,.12),(.9,.78),(.5,.98),(.1,.78)],'#')]
RACECOL={'human':('red','red_d'),'elf':('teal','teal_d'),'dwarf':('steel_d','char'),'orc':('green','green_d'),'voidkin':('void_d','char')}
CALLCOL={'warrior':('rust','red_d'),'mage':('blue','void_d'),'ranger':('wood','wood_d'),'rogue':('char','steel_d'),'cleric':('gold_d','wood_d')}
def draw(sp,N,tf=None,fillc=None,fill_dark=None):
    """rasterise shapes on an N x N canvas (unit coords through tf = (scale, ox, oy))"""
    im=Image.new('RGBA',(N,N),(0,0,0,0)); d=ImageDraw.Draw(im); s,ox,oy=tf or (1,0,0)
    P=lambda x,y:((ox+x*s)*(N-1),(oy+y*s)*(N-1))
    for it in sp:
        k=it[0]
        if k=='poly':
            col=fillc if it[2]=='#' else C[it[2]]; d.polygon([P(*p) for p in it[1]],fill=col)
        elif k=='rect': x0,y0,x1,y1,col=it[1:]; a=P(x0,y0); b=P(x1,y1); d.rectangle((a[0],a[1],b[0],b[1]),fill=C[col] if col!='#' else fillc)
        elif k=='ell': cx,cy,rx,ry,col=it[1:]; a=P(cx-rx,cy-ry); b=P(cx+rx,cy+ry); d.ellipse((a[0],a[1],b[0],b[1]),fill=C[col])
        elif k=='line': x0,y0,x1,y1,w,col=it[1:]; d.line([P(x0,y0),P(x1,y1)],fill=C[col],width=max(1,round(w*s*(N-1))))
    return im
def finish(im,ow):
    N=im.width; src=im.load(); b=1 if N<=32 else 2
    def op(x,y): return 0<=x<N and 0<=y<N and src[x,y][3]>0
    out=im.copy(); px=out.load()
    for y in range(N):
        for x in range(N):
            if src[x,y][3]>0 and src[x,y][:3]!=INK[:3]:
                tl=not op(x-b,y) or not op(x,y-b); br=not op(x+b,y) or not op(x,y+b); c=src[x,y]
                if tl and not br: c=tuple(int(v+(255-v)*.28) for v in c[:3])+(255,)
                elif br and not tl: c=tuple(int(v*.72) for v in c[:3])+(255,)
                px[x,y]=c
    big=Image.new('RGBA',(N+2*ow,N+2*ow),(0,0,0,0)); big.paste(out,(ow,ow)); bp=big.load()
    mask=[[bp[x,y][3]>0 for x in range(big.width)] for y in range(big.height)]
    res=big.copy(); rp=res.load()
    for _ in range(ow):
        m2=[row[:] for row in mask]
        for y in range(big.height):
            for x in range(big.width):
                if not mask[y][x] and any(0<=x+dx<big.width and 0<=y+dy<big.height and mask[y+dy][x+dx] for dx,dy in ((1,0),(-1,0),(0,1),(0,-1))): rp[x,y]=INK; m2[y][x]=True
        mask=m2
    return res
SIZES=(16,32,48)
def make(name,opt,N):
    ow=1 if N<48 else 2; inner=N-2*ow
    if opt=='A': return finish(draw(S(name),inner),ow)
    if name in RACECOL:
        f,fd=RACECOL[name]; base=draw(SHIELD,inner,fillc=C[f]); em=draw(S(name),inner,tf=(.56,.22,.14))
        # the emblem in cream/colour over the shield: keep its own colours
        base.alpha_composite(em); return finish(base,ow)
    f,fd=CALLCOL[name]; base=draw(BANNER,inner,fillc=C[f]); em=draw(S(name),inner,tf=(.52,.24,.2)); base.alpha_composite(em); return finish(base,ow)
if __name__=='__main__':
    names=['human','elf','dwarf','orc','voidkin','warrior','mage','ranger','rogue','cleric']
    for opt in 'AB':
        os.makedirs(f'{O}png/{opt}',exist_ok=True)
        for n in names:
            for N in SIZES: make(n,opt,N).save(f'{O}png/{opt}/{n}_{N}.png',optimize=True)
    # today
    def today(n,folder):
        im=Image.open(f'assets/visuals/{folder}/{n}.png').convert('RGBA'); return im
    LIGHT=(233,224,201); DARK=(31,28,35); F=ImageFont.load_default(size=12)
    rows=[('today',lambda n:(today(n,'races') if n in ('human','elf','dwarf','orc','voidkin') else today(n,'professions')).resize((48,48),Image.NEAREST)),
          ('option A: free-standing emblems',None),('option B: shield (races), hanging banner (callings)',None)]
    W=10*100+20; sh=Image.new('RGB',(W*2+30,3*215+30),LIGHT); d=ImageDraw.Draw(sh)
    for half,bg in enumerate((LIGHT,DARK)):
        x0=10+half*(W+10); d.rectangle((x0-5,0,x0+W+5,sh.height),fill=bg); y=8
        fg=(35,31,26) if half==0 else (233,224,201)
        for lab,fn in rows:
            d.text((x0,y),lab,font=F,fill=fg); y+=16
            for i,n in enumerate(names):
                x=x0+i*100
                if fn:   # today: only a 48 px stand-in at 3x and 1x
                    im=fn(n); sh.paste(im.resize((144,144),Image.NEAREST),(x-20,y),im.resize((144,144),Image.NEAREST)); sh.paste(im,(x+30,y+150),im)
                else:
                    opt='A' if 'A' in lab[:9] else 'B'
                    im=Image.open(f'{O}png/{opt}/{n}_48.png'); big=im.resize((im.width*2,im.height*2),Image.NEAREST); sh.paste(big,(x-8,y),big)      # 48 at 2x
                    i32=Image.open(f'{O}png/{opt}/{n}_32.png'); i16=Image.open(f'{O}png/{opt}/{n}_16.png'); sh.paste(i32,(x,y+112),i32); sh.paste(i16,(x+46,y+120),i16)
                    sh.paste(Image.open(f'{O}png/{opt}/{n}_32.png').resize((96,96),Image.NEAREST),(x-4,y+150) if False else (x,y+112+0),Image.open(f'{O}png/{opt}/{n}_32.png').resize((96,96),Image.NEAREST)) if False else None
                d.text((x,y+80 if fn is None else y+170),n,font=F,fill=(110,102,90))
            y+=215
    sh.save('docs/art/boards/emblems.png'); print(sh.size)
