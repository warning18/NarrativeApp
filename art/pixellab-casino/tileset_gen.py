"""Approach A: an 8 px top-down TILESET drawn in code (0 generations) laid on the existing plans, so alignment is exact.
Tiles (3 variants each): cobble, ash ground, rubble, burnt roof (house / hall / temple / stall), stone wall, dark plank, red carpet, felt, vault slate.
Run from the repo root: python3 art/pixellab-casino/tileset_gen.py"""
import sys, math, random, os, json
sys.path.insert(0,'art/pixellab-casino')
import plan_geometry as G
from PIL import Image, ImageDraw, ImageFont
def H(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))
INK=H('#0A0807'); T=8
O='art/pixellab-casino/'
def lighten(c,t): return tuple(int(v+(255-v)*t) for v in c)
def darken(c,t): return tuple(int(v*(1-t)) for v in c)
# ---------------- the tiles ----------------
def t_cobble(r,base=H('#6B6356'),lo=H('#3A3340'),hi=H('#8A8497')):
    im=Image.new('RGB',(T,T),base); d=ImageDraw.Draw(im)
    for row in range(2):
        off=r.choice((0,2)) if row else 0; y=row*4
        d.line([(0,y),(T-1,y)],fill=lo)
        for x in range(off,T+4,4): d.line([(x%T,y),(x%T,y+3)],fill=lo)
    for _ in range(3): d.point((r.randrange(T),r.randrange(T)),fill=hi)
    return im
def t_ash(r,base=H('#3A3340')):
    im=Image.new('RGB',(T,T),base); d=ImageDraw.Draw(im)
    for _ in range(6): d.point((r.randrange(T),r.randrange(T)),fill=darken(base,.25) if r.random()<.6 else lighten(base,.12))
    return im
def t_rubble(r):
    im=t_ash(r); d=ImageDraw.Draw(im)
    for _ in range(2): x,y=r.randrange(T-2),r.randrange(T-2); d.rectangle((x,y,x+1,y+1),fill=H('#6B6356')); d.point((x,y),fill=H('#A8A194'))
    if r.random()<.5: y=r.randrange(T); d.line([(0,y),(r.randrange(3,T),y)],fill=H('#1F1B24'))
    if r.random()<.25: d.point((r.randrange(T),r.randrange(T)),fill=H('#E0762B'))
    return im
def t_roof(r,base):
    im=Image.new('RGB',(T,T),base); d=ImageDraw.Draw(im)
    for y in (0,3,6): d.line([(0,y),(T-1,y)],fill=darken(base,.35)); 
    for y in (1,4,7):
        for x in range(r.choice((0,2)),T,4): d.point((x,y),fill=darken(base,.2))
    for _ in range(3): d.point((r.randrange(T),r.randrange(T)),fill=H('#1F1B24'))      # soot
    if r.random()<.12: d.point((r.randrange(T),r.randrange(T)),fill=H('#E0762B'))        # an ember
    d.line([(0,0),(T-1,0)],fill=lighten(base,.18))
    return im
def t_wall(r):
    im=Image.new('RGB',(T,T),H('#6B6356')); d=ImageDraw.Draw(im)
    d.line([(0,3),(T-1,3)],fill=H('#1B1620')); d.line([(0,7),(T-1,7)],fill=H('#1B1620'))
    d.line([(r.choice((1,5)),0),(r.choice((1,5)),2)],fill=H('#1B1620')); d.line([(r.choice((2,6)),4),(r.choice((2,6)),6)],fill=H('#1B1620'))
    d.line([(0,0),(T-1,0)],fill=H('#FAF2DA')); return im
def t_plank(r,base=H('#4A3A2E')):
    im=Image.new('RGB',(T,T),base); d=ImageDraw.Draw(im)
    for y in (3,7): d.line([(0,y),(T-1,y)],fill=darken(base,.35))
    d.line([(r.randrange(T),0),(r.randrange(T),2)],fill=darken(base,.3)); d.line([(r.randrange(T),4),(r.randrange(T),6)],fill=darken(base,.3))
    if r.random()<.3: d.point((r.randrange(T),r.randrange(T)),fill=darken(base,.45))
    d.line([(0,0),(T-1,0)],fill=lighten(base,.08)); return im
def t_carpet(r):
    im=Image.new('RGB',(T,T),H('#8A2E2A')); d=ImageDraw.Draw(im)
    for _ in range(4): d.point((r.randrange(T),r.randrange(T)),fill=H('#A83B34'))
    for y in range(0,T,2): d.point(((y+r.randrange(2))%T,y),fill=H('#6E1F1B'))
    return im
def t_felt(r):
    im=Image.new('RGB',(T,T),H('#2F6B3C')); d=ImageDraw.Draw(im)
    for _ in range(5): d.point((r.randrange(T),r.randrange(T)),fill=H('#3C8A4C') if r.random()<.6 else H('#235530'))
    return im
def t_vault(r):
    im=Image.new('RGB',(T,T),H('#51495A')); d=ImageDraw.Draw(im); d.line([(0,0),(T-1,0)],fill=H('#6B6356')); d.line([(0,T-1),(T-1,T-1)],fill=H('#2E2A35')); d.line([(0,0),(0,T-1)],fill=H('#6B6356'))
    return im
def t_rug(r):
    im=Image.new('RGB',(T,T),H('#7A1F24')); d=ImageDraw.Draw(im)
    for _ in range(4): d.point((r.randrange(T),r.randrange(T)),fill=H('#A83B34'))
    return im
TILES={'cobble':t_cobble,'cobble_light':lambda r:t_cobble(r,H('#8A7E68'),H('#51495A'),H('#B9B3C6')),'ash':t_ash,'ash_dark':lambda r:t_ash(r,H('#241F29')),'rubble':t_rubble,
 'roof_house':lambda r:t_roof(r,H('#6E4A3A')),'roof_hall':lambda r:t_roof(r,H('#8A2E2A')),'roof_temple':lambda r:t_roof(r,H('#4A3C80')),'roof_stall':lambda r:t_roof(r,H('#C9A25A')),
 'wall':t_wall,'plank':t_plank,'plank_light':lambda r:t_plank(r,H('#5E4A38')),'carpet':t_carpet,'felt':t_felt,'vault':t_vault,'rug':t_rug}
TV={k:[fn(random.Random(i*13+sum(map(ord,k)))) for i in range(3)] for k,fn in TILES.items()}
def tex(name,w,h):
    im=Image.new('RGB',(w,h)); 
    for ty in range(0,h,T):
        for tx in range(0,w,T): im.paste(TV[name][((tx//T)*7+(ty//T)*13)%3],(tx,ty))
    return im
class Cv:
    def __init__(s,box,scale):
        s.x0,s.y0,s.x1,s.y1=box; s.sc=scale; s.w=int((s.x1-s.x0)*scale)//4*4; s.h=int((s.y1-s.y0)*scale)//4*4
        s.im=Image.new('RGB',(s.w,s.h),INK); s.d=ImageDraw.Draw(s.im)
    def p(s,pt): return ((pt[0]-s.x0)*s.sc,(pt[1]-s.y0)*s.sc)
    def mask(s): return Image.new('L',(s.w,s.h),0)
    def fill(s,m,name): s.im.paste(tex(name,s.w,s.h),(0,0),m)
    def poly(s,pts,name,outline=True,light=True):
        m=s.mask(); q=[s.p(x) for x in pts]; ImageDraw.Draw(m).polygon(q,fill=255); s.fill(m,name)
        if outline: s.d.polygon(q,outline=INK)
    def stroke(s,pts,w,name,edge=True):
        q=[s.p(x) for x in pts]; ww=max(1,int(round(w*s.sc)))
        if edge:
            m0=s.mask(); dd=ImageDraw.Draw(m0); dd.line(q,fill=255,width=ww+2,joint='curve')
            for x,y in q: dd.ellipse((x-ww/2-1,y-ww/2-1,x+ww/2+1,y+ww/2+1),fill=255)
            s.im.paste(INK,(0,0),m0)
        m=s.mask(); dd=ImageDraw.Draw(m); dd.line(q,fill=255,width=ww,joint='curve')
        for x,y in q: dd.ellipse((x-ww/2,y-ww/2,x+ww/2,y+ww/2),fill=255)
        s.fill(m,name)
    def disc(s,cx,cy,r,name,ink=True):
        x,y=s.p((cx,cy)); rr=r*s.sc
        if ink: s.d.ellipse((x-rr-1,y-rr-1,x+rr,y+rr),fill=INK)
        m=s.mask(); ImageDraw.Draw(m).ellipse((x-rr+1,y-rr+1,x+rr-1,y+rr-1),fill=255); s.fill(m,name)
    def rect(s,x0,y0,x1,y1,name,ink=True):
        a=s.p((x0,y0)); b=s.p((x1,y1))
        if ink: s.d.rectangle((a[0]-1,a[1]-1,b[0],b[1]),fill=INK)
        m=s.mask(); ImageDraw.Draw(m).rectangle((a[0],a[1],b[0]-1,b[1]-1),fill=255); s.fill(m,name)
    def pt(s,x,y,col): s.d.point((int(s.p((x,y))[0]),int(s.p((x,y))[1])),fill=col)
    def px(s,x,y,w,h,col): a=s.p((x,y)); s.d.rectangle((a[0],a[1],a[0]+w-1,a[1]+h-1),fill=col)
def centroid(pts): return (sum(p[0] for p in pts)/len(pts),sum(p[1] for p in pts)/len(pts))
def along(path,step):
    out=[]; acc=0
    for i in range(len(path)-1):
        (x0,y0),(x1,y1)=path[i],path[i+1]; L=math.hypot(x1-x0,y1-y0); t=0
        while t<L:
            if acc<=0: out.append((x0+(x1-x0)*t/L,y0+(y1-y0)*t/L)); acc=step
            t+=4; acc-=4
    return out
def city():
    c=Cv((150,170,870,880),0.5); C=G.CITY; rnd=random.Random(11)
    c.im.paste(tex('ash_dark',c.w,c.h),(0,0))
    for k,dist in C['districts'].items(): c.poly(dist['shape'],'ash',outline=False)
    for av in C['avenues']: c.stroke(av['path'],av['width'],'cobble')
    for st in C['streets']: c.stroke(st['path'],st['width'],'cobble_light' if False else 'cobble',edge=True)
    for sq in C['squares']: c.poly(sq['shape'],'cobble_light')
    # rubble heaps beside the roads
    for _ in range(150):
        x,y=rnd.uniform(190,830),rnd.uniform(210,840)
        px,py=c.p((x,y))
        if 0<px<c.w-8 and 0<py<c.h-8 and c.im.getpixel((int(px),int(py)))[0]<90 and rnd.random()<.5:
            c.im.paste(TV['rubble'][rnd.randrange(3)],(int(px)//T*T,int(py)//T*T))
    for b in C['buildings']:
        name={'house':'roof_house','hall':'roof_hall','temple':'roof_temple','stall':'roof_stall'}[b['kind']]
        c.poly(b['shape'],name)
        cx,cy=centroid(b['shape']); xs=[p[0] for p in b['shape']]; ys=[p[1] for p in b['shape']]
        wide=(max(xs)-min(xs))>=(max(ys)-min(ys))
        if b['kind']=='house':
            if wide: c.d.line([c.p((min(xs)+2,cy)),c.p((max(xs)-2,cy))],fill=lighten(H('#6E4A3A'),.3))
            else: c.d.line([c.p((cx,min(ys)+2)),c.p((cx,max(ys)-2))],fill=lighten(H('#6E4A3A'),.3))
            if rnd.random()<.15:   # a collapsed, burnt roof
                hole=[(cx+(x-cx)*.5,cy+(y-cy)*.5) for x,y in b['shape']]; c.poly(hole,'ash_dark',outline=False)
                q=[c.p(x) for x in hole]; c.d.polygon(q,outline=H('#E0762B'))
        if b['kind']=='temple':
            x,y=c.p((cx,cy)); c.d.rectangle((x-1,y-1,x+1,y+1),fill=H('#F2C14E'))
    for run in C['wall']['runs']: c.stroke(run,10,'wall')
    for t in C['wall']['towers']: c.disc(t[0],t[1],11,'wall'); c.disc(t[0]-2,t[1]-2,3,'cobble_light',ink=False)
    for g in C['wall']['gates']:
        x,y=g['at']; c.rect(x-9,y-9,x+9,y+9,'plank'); x2,y2=c.p((x,y)); c.d.rectangle((x2-1,y2-1,x2+1,y2+4),fill=INK)
    for av in C['avenues']:   # standing lanterns along the avenues
        for (x,y) in along(av['path'],110)[1:]:
            px,py=c.p((x+10,y-9)); px=int(px); py=int(py); c.d.line([(px,py),(px,py-5)],fill=INK); c.d.rectangle((px-1,py-8,px+1,py-5),fill=H('#F2C14E')); c.d.point((px,py-9),fill=INK)
    for k in range(40):     # embers and soot flecks
        x,y=rnd.randrange(c.w),rnd.randrange(c.h)
        if c.im.getpixel((x,y))[0]<110: c.d.point((x,y),fill=H('#E0762B') if rnd.random()<.5 else H('#F2C14E'))
    return c.im
def casino(scale=0.5):
    c=Cv((92,42,908,958),scale)
    c.im.paste(INK,(0,0,c.w,c.h))
    for name,(x0,y0,x1,y1) in G.ROOMS.items(): c.rect(x0,y0,x1,y1,'plank_light' if name=='floor' else ('vault' if name=='vault' else 'rug'),ink=False)
    c.rect(465,640,535,910,'carpet',ink=False)
    c.d.line([c.p((465,640)),c.p((465,910))],fill=H('#D9B25A')); c.d.line([c.p((535,640)),c.p((535,910))],fill=H('#D9B25A'))
    x0,y0,x1,y1=G.BOX
    def wall(pts): c.stroke(pts,16,'wall')
    wall([(x0,y0),(x1,y0),(x1,y1),(x0,y1),(x0,y0)])
    for y,xa,xb,gaps in G.HW:
        cur=xa
        for gx,gw in sorted(gaps): wall([(cur,y),(gx-gw/2,y)]); cur=gx+gw/2
        wall([(cur,y),(xb,y)])
    for x in (340,520,700): wall([(x,90),(x,330)])
    for name,x,y,o,w in G.DOORS: c.rect(x-w/2,y-9,x+w/2,y+9,'plank')
    for tx,ty in G.TABLES:
        c.disc(tx,ty,40,'plank'); c.disc(tx,ty,30,'felt',ink=True)
        for k in range(4): a=k*math.pi/2+.4; c.disc(tx+math.cos(a)*47,ty+math.sin(a)*47,7,'plank')
        c.px(tx-4,ty-4,2,2,H('#F2C14E')); c.px(tx+2,ty+1,2,2,H('#D9544D')); c.px(tx-1,ty+3,1,2,H('#FAF2DA'))      # chips and a candle
    c.disc(500,560,75,'plank'); c.disc(500,560,66,'cobble_light',ink=True)
    c.d.ellipse((c.p((500-52,560-52))[0],c.p((500-52,560-52))[1],c.p((500+52,560+52))[0],c.p((500+52,560+52))[1]),fill=H('#2A1F1A'))
    for k in range(12):
        a=k*math.pi/6; x,y=c.p((500+math.cos(a)*40,560+math.sin(a)*40)); c.d.rectangle((x-2,y-2,x+1,y+1),fill=H('#D9544D') if k%2 else INK)
    c.disc(500,560,16,'cobble_light'); x,y=c.p((500,560)); c.d.rectangle((x-2,y-2,x+1,y+1),fill=H('#F2C14E'))
    def blk(cx,cy,w,h,name): c.rect(cx-w/2,cy-h/2,cx+w/2,cy+h/2,name)
    blk(180,780,50,160,'plank'); blk(235,200,130,26,'plank'); blk(680,868,150,26,'plank')
    for cx,cy,_w,_h in G.BOXES: blk(cx,cy,44,32,'roof_stall')
    for cx in (430,610): blk(cx,298,100,24,'rug')
    c.rect(750,740,810,850,'vault')
    for k in range(8): y=c.p((0,744+k*13))[1]; c.d.line([(c.p((754,0))[0],y),(c.p((806,0))[0],y)],fill=H('#B9B3C6'))
    for (cx,cy) in ((200,380),(800,380),(200,880),(800,880),(500,420)):    # chandeliers: a ring of candles
        for k in range(8):
            a=k*math.pi/4; x,y=c.p((cx+math.cos(a)*22,cy+math.sin(a)*22)); c.d.rectangle((x-1,y-1,x,y),fill=H('#F2C14E')); c.d.point((x-1,y-2),fill=H('#FAF2DA'))
        x,y=c.p((cx,cy)); c.d.rectangle((x-1,y-1,x+1,y+1),fill=INK)
    for xx in range(190,820,60):   # wall candles along the hall's walls
        x,y=c.p((xx,345)); c.d.rectangle((x,y,x+1,y+2),fill=H('#F2C14E'))
    return c.im
if __name__=='__main__':
    os.makedirs(O+'a',exist_ok=True)
    city().save(O+'a/ashen_quarter_tileset.png'); casino().save(O+'a/casino_tileset.png')
    sheet=Image.new('RGB',(T*3*len(TILES)+10,T*2+34),(31,28,35)); d=ImageDraw.Draw(sheet); F=ImageFont.load_default(size=11)
    for i,(k,v) in enumerate(TV.items()):
        for j in range(3): sheet.paste(v[j],(5+i*T*3+j*T,18))
        d.text((5+i*T*3,4),k[:7],font=F,fill=(233,224,201))
    sheet=sheet.resize((sheet.width*3,sheet.height*3),Image.NEAREST); sheet.save(O+'a/tileset_sheet.png'); print('ok')
