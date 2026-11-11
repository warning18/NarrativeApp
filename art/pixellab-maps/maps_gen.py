"""Map plates, hand-drawn in code from the game's own data so pins and taps line up (0 generations):
(a) the Ashen Quarter town plan (assets/gamedata/city_plans.json 'ashen_quarter', 1000x1000 plan units)
(b) the Gilded Casino room plan (lib/data/room_plan.dart _casino, same units).
Per map: 'today' (flat reconstruction of the code's painting from the same data), version 1 (dark chibi ink plate), version 2 (warm lantern-lit plate).
Run from the repo root: python3 art/pixellab-maps/maps_gen.py"""
import json, math, random, os
from PIL import Image, ImageDraw, ImageFont
def H(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))
INK=H('#0A0807')
O='art/pixellab-maps/'
os.makedirs(O,exist_ok=True)
class Cv:
    def __init__(s,box,scale):
        s.x0,s.y0,s.x1,s.y1=box; s.sc=scale; s.w=int((s.x1-s.x0)*scale); s.h=int((s.y1-s.y0)*scale)
        s.im=Image.new('RGB',(s.w,s.h),(0,0,0)); s.d=ImageDraw.Draw(s.im)
    def p(s,pt): return ((pt[0]-s.x0)*s.sc,(pt[1]-s.y0)*s.sc)
    def poly(s,pts,fill,outline=None): s.d.polygon([s.p(q) for q in pts],fill=fill,outline=outline)
    def line(s,pts,col,w): 
        q=[s.p(x) for x in pts]; s.d.line(q,fill=col,width=max(1,int(round(w*s.sc))),joint='curve')
        r=max(1,int(round(w*s.sc)))/2
        if r>1:
            for x,y in q: s.d.ellipse((x-r+.5,y-r+.5,x+r-.5,y+r-.5),fill=col)
    def rect(s,x0,y0,x1,y1,fill,outline=None):
        a=s.p((x0,y0)); b=s.p((x1,y1)); s.d.rectangle((a[0],a[1],max(a[0],b[0]-1),max(a[1],b[1]-1)),fill=fill,outline=outline)
    def ell(s,cx,cy,rx,ry,fill,outline=None):
        a=s.p((cx-rx,cy-ry)); b=s.p((cx+rx,cy+ry)); s.d.ellipse((a[0],a[1],max(a[0]+1,b[0]-1),max(a[1]+1,b[1]-1)),fill=fill,outline=outline)
    def dot(s,pt,col):
        x,y=s.p(pt); s.d.point((int(x),int(y)),fill=col)
def lighten(c,t): return tuple(int(v+(255-v)*t) for v in c)
def darken(c,t): return tuple(int(v*(1-t)) for v in c)
# ================= (a) Ashen Quarter =================
CITY=json.load(open('assets/gamedata/city_plans.json'))['ashen_quarter']
def centroid(pts): return (sum(p[0] for p in pts)/len(pts),sum(p[1] for p in pts)/len(pts))
def bbox_poly(pts): xs=[p[0] for p in pts]; ys=[p[1] for p in pts]; return min(xs),min(ys),max(xs),max(ys)
def city(style):
    c=Cv((150,170,870,880),0.5)
    P={'today':dict(ground=H('#E9DFC4'),out=H('#D6C9A6'),wall=H('#8A7E68'),av=H('#CFC4AE'),st=H('#DCD2B8'),sq=H('#BDB098'),roof={'house':H('#B7A98C'),'hall':H('#A5302A'),'temple':H('#6A4FB0'),'stall':H('#E0762B')}),
       'v1':dict(ground=H('#3A3340'),out=H('#241F29'),wall=H('#8A8497'),av=H('#6B6356'),st=H('#51495A'),sq=H('#7A7264'),roof={'house':H('#6E4A3A'),'hall':H('#8A2E2A'),'temple':H('#4A3C80'),'stall':H('#B5601C'),}),
       'v2':dict(ground=H('#C9B48A'),out=H('#A8946A'),wall=H('#6B5A3A'),av=H('#E4D7B6'),st=H('#D6C79F'),sq=H('#EEDFB4'),roof={'house':H('#9C4A2E'),'hall':H('#7A2A2A'),'temple':H('#3E5A80'),'stall':H('#C9A25A')})}[style]
    d=c.d; c.im.paste(P['out'],(0,0,c.w,c.h))
    # the ground inside the wall: union of the district shapes
    for k,dist in CITY['districts'].items():
        tint=P['ground']
        if style!='today':
            j=list(CITY['districts']).index(k); tint=lighten(P['ground'],[0,.05,.1,0.03,.07][j%5]) if style=='v1' else darken(P['ground'],[0,.04,.08,.02,.06][j%5])
        c.poly(dist['shape'],tint)
    if style!='today':
        rnd=random.Random(3)
        for _ in range(900): 
            x,y=rnd.randrange(c.w),rnd.randrange(c.h)
            if c.im.getpixel((x,y))==P['ground'] or True: 
                px=c.im.getpixel((x,y))
                if px!=P['out']: c.d.point((x,y),fill=darken(px,.08) if rnd.random()<.6 else lighten(px,.06))
    for av in CITY['avenues']:
        pts=av['path']; 
        if style!='today': c.line(pts,INK,av['width']+3)
        c.line(pts,P['av'],av['width'])
    for st in CITY['streets']:
        if style!='today': c.line(st['path'],INK,st['width']+2)
        c.line(st['path'],P['st'],st['width'])
    for sq in CITY['squares']:
        c.poly(sq['shape'],P['sq'],INK if style!='today' else None)
    for b in CITY['buildings']:
        col=P['roof'][b['kind']]; pts=b['shape']
        c.poly(pts,col,INK if style!='today' else darken(col,.25))
        if style!='today':
            cx,cy=centroid(pts)
            for i in range(len(pts)):
                a,bb=pts[i],pts[(i+1)%len(pts)]; mx,my=(a[0]+bb[0])/2,(a[1]+bb[1])/2
                if my<cy-1 or mx<cx-1: c.line([a,bb],lighten(col,.35),1.5)
            if b['kind']=='temple':
                x0,y0,x1,y1=bbox_poly(pts); c.rect((x0+x1)/2-2,(y0+y1)/2-2,(x0+x1)/2+2,(y0+y1)/2+2,H('#F2C14E'))
    # the wall, towers, gates
    for run in CITY['wall']['runs']:
        if style!='today': c.line(run,INK,12)
        c.line(run,P['wall'],8 if style!='today' else 5)
        if style!='today': c.line([(x-1,y-1) for x,y in run],lighten(P['wall'],.3),2)
    for t in CITY['wall']['towers']:
        c.ell(t[0],t[1],11,11,INK if style!='today' else P['wall']); c.ell(t[0],t[1],7,7,P['wall']); c.ell(t[0]-2,t[1]-2,3,3,lighten(P['wall'],.35))
    for g in CITY['wall']['gates']:
        x,y=g['at']; c.rect(x-9,y-9,x+9,y+9,H('#5A3A1C'),INK); c.rect(x-3,y-3,x+3,y+9,INK)
        c.rect(x-12,y-12,x-6,y-6,H('#F2C14E'))
    if style!='today':
        rnd=random.Random(9)   # ash heaps and dead trees outside the wall
        for _ in range(70):
            x,y=rnd.randrange(c.w),rnd.randrange(c.h)
            if c.im.getpixel((x,y))==P['out']:
                if rnd.random()<.5: c.d.rectangle((x,y,x+1,y+1),fill=darken(P['out'],.25))
                else: c.d.line([(x,y),(x,y-4)],fill=INK); c.d.point((x-1,y-3),fill=INK); c.d.point((x+1,y-5),fill=INK)
    return c.im
# ================= (b) the Gilded Casino =================
BOX=(140,90,860,910)
ROOMS={'floor':(140,330,860,910),'cashier':(140,90,340,330),'vip1':(340,90,520,330),'vip2':(520,90,700,330),'vault':(700,90,860,330)}
DOORS=[('door',500,910,'h',70),('back',240,90,'h',50),('cashier',250,330,'h',60),('vip1',430,330,'h',60),('vip2',610,330,'h',60),('vault',780,330,'h',50)]
HW=[(330,140,860,[(250,60),(430,60),(610,60),(780,50)])]
TABLES=[(500+math.cos(i*math.pi/3)*270,560+math.sin(i*math.pi/3)*130) for i in range(6)]+[(430,205),(610,205)]
BOXES=[(305,130,44,32),(740,130,44,32),(820,130,44,32),(780,205,44,32)]
def casino(style):
    fr=(92,42,908,958); c=Cv(fr,0.4)
    P={'today':dict(bg=H('#E9DFC4'),floor=H('#D6C9A6'),room=H('#CFC4AE'),wall=H('#6B6356'),furn=H('#A8A194'),door=H('#8A5A2B'),felt=H('#A8A194'),gold=H('#B8862A')),
       'v1':dict(bg=H('#17121C'),floor=H('#4A3A2E'),room=H('#3B2F4A'),wall=H('#7A7264'),furn=H('#6B4A2E'),door=H('#B5601C'),felt=H('#2F6B3C'),gold=H('#F2C14E')),
       'v2':dict(bg=H('#1E1618'),floor=H('#2A2226'),room=H('#6E2A2E'),wall=H('#B8862A'),furn=H('#8A5A2B'),door=H('#F2C14E'),felt=H('#3D5A3A'),gold=H('#FFE08A'))}[style]
    d=c.d; c.im.paste(P['bg'],(0,0,c.w,c.h))
    for name,(x0,y0,x1,y1) in ROOMS.items(): c.rect(x0,y0,x1,y1,P['floor'] if name=='floor' else P['room'])
    if style!='today':
        # floor pattern: planks (v1) or black-and-gold tiles (v2) in the hall; plush rugs in the rooms
        x0,y0,x1,y1=ROOMS['floor']
        for yy in range(int(y0),int(y1),40):
            for xx in range(int(x0),int(x1),40):
                if style=='v2' and ((xx//40)+(yy//40))%2==0: c.rect(xx,yy,min(xx+40,x1),min(yy+40,y1),H('#3A2F34'))
                if style=='v1': c.rect(xx,yy,xx+40,yy+1,darken(P['floor'],.25)); 
        if style=='v1':
            rnd=random.Random(5)
            for _ in range(160):
                x=rnd.randrange(int(x0),int(x1)); y=rnd.randrange(int(y0),int(y1)); c.rect(x,y,x+12,y+1,darken(P['floor'],.2))
        # a red carpet from the door to the wheel
        c.rect(465,640,535,910,H('#8A2E2A') if style=='v1' else H('#6E1F24')); c.rect(465,640,468,910,H('#D9544D')); c.rect(532,640,535,910,H('#5A1B18'))
        for name in ('cashier','vip1','vip2','vault'):
            x0,y0,x1,y1=ROOMS[name]; c.rect(x0+25,y0+25,x1-25,y1-25,lighten(P['room'],.08) if name!='vault' else H('#51495A'))
    # walls
    def wall(pts):
        for col,w in ((INK,16),(P['wall'],9)): c.line(pts,col,w)
        c.line([(x-1,y-1) for x,y in pts],lighten(P['wall'],.3),2)
    x0,y0,x1,y1=BOX; wall([(x0,y0),(x1,y0),(x1,y1),(x0,y1),(x0,y0)])
    for y,xa,xb,gaps in HW:
        xs=[xa]; segs=[]; cur=xa
        for gx,gw in sorted(gaps): segs.append(((cur,y),(gx-gw/2,y))); cur=gx+gw/2
        segs.append(((cur,y),(xb,y)))
        for a,b in segs: wall([a,b])
    for x in (340,520,700): wall([(x,90),(x,330)])
    for name,x,y,o,w in DOORS:
        c.rect(x-w/2,y-9,x+w/2,y+9,P['door'],INK); c.rect(x-w/2+4,y-4,x+w/2-4,y+4,lighten(P['door'],.25))
        if name in ('door','back'): c.rect(x-6,y-14,x+6,y-8,P['gold']) if name=='back' else None
    # furniture
    for tx,ty in TABLES:
        c.ell(tx,ty,40,40,INK); c.ell(tx,ty,34,34,P['furn'] if style=='today' else H('#5A3A1C')); c.ell(tx,ty,27,27,P['felt']); c.ell(tx-6,ty-6,9,9,lighten(P['felt'],.2))
        for k in range(4):
            a=k*math.pi/2+.4; c.ell(tx+math.cos(a)*47,ty+math.sin(a)*47,7,7,INK); c.ell(tx+math.cos(a)*47,ty+math.sin(a)*47,5,5,P['furn'])
    c.ell(500,560,75,75,INK); c.ell(500,560,68,68,P['gold'] if style!='today' else P['furn']); c.ell(500,560,52,52,H('#2A1F1A')); 
    for k in range(12):
        a=k*math.pi/6; c.ell(500+math.cos(a)*40,560+math.sin(a)*40,6,6,H('#D9544D') if k%2 else H('#0A0807'))
    c.ell(500,560,16,16,P['gold']); c.ell(497,557,5,5,lighten(P['gold'],.4))
    def blk(cx,cy,w,h,fill): c.rect(cx-w/2-3,cy-h/2-3,cx+w/2+3,cy+h/2+3,INK); c.rect(cx-w/2,cy-h/2,cx+w/2,cy+h/2,fill); c.rect(cx-w/2,cy-h/2,cx+w/2,cy-h/2+4,lighten(fill,.3))
    blk(180,780,50,160,P['furn']); blk(235,200,130,26,P['furn']); blk(680,868,150,26,P['furn'])
    for cx,cy,_w,_h in BOXES: blk(cx,cy,44,32,P['gold'] if style!='today' else P['furn'])
    for cx in (430,610): blk(cx,298,100,24,H('#7A4A8A') if style!='today' else P['furn'])
    c.rect(780-30,740-0,780+30,850,INK); c.rect(780-26,744,780+26,846,darken(P['wall'],.1))
    for k in range(8): c.rect(780-26,744+k*13,780+26,746+k*13,lighten(P['wall'],.2))
    if style=='v2':
        for (cx,cy) in ((200,380),(800,380),(200,880),(800,880)): c.ell(cx,cy,26,26,lighten(P['gold'],.1)); c.ell(cx,cy,12,12,H('#FFF3C4'))   # chandeliers
    return c.im
def labelled(ims,titles,path,upscale=2):
    F=ImageFont.load_default(size=14)
    W=sum(i.width*upscale for i in ims)+20*(len(ims)+1); Hh=max(i.height*upscale for i in ims)+50
    sh=Image.new('RGB',(W,Hh),(31,28,35)); d=ImageDraw.Draw(sh); x=20
    for im,t in zip(ims,titles):
        sh.paste(im.resize((im.width*upscale,im.height*upscale),Image.NEAREST),(x,36)); d.text((x,10),t,font=F,fill=(233,224,201)); x+=im.width*upscale+20
    sh.save(path)
if __name__=='__main__':
    for s in ('today','v1','v2'):
        city(s).save(f'{O}ashen_quarter_{s}.png'); casino(s).save(f'{O}casino_{s}.png')
    labelled([Image.open(f'{O}ashen_quarter_{s}.png') for s in ('today','v1','v2')],['today (rebuilt from the same plan data)','version 1: dark ink plate','version 2: warm lantern plate'],'docs/art/boards/map-ashen-quarter.png',2)
    labelled([Image.open(f'{O}casino_{s}.png') for s in ('today','v1','v2')],['today (rebuilt from room_plan.dart)','version 1: dark ink plate','version 2: gilded plate'],'docs/art/boards/map-casino.png',2)
    print('ok')
