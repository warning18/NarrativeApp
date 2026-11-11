"""The Tower's decoration sets for the iron kit (the Tower floors' bands are night / stone / void): tower_night (hanging chains, candle wax),
tower_stone (cracked stone, dust, rubble), tower_void (violet cracks, a little void glow). Same format as the other environments (env/<name>_{top,bottom,corner}_<0..2>.png:
top 32x10, bottom 32x8, corner 16x16 L-piece, transparent, own ink). Hand-drawn in code, 0 generations. Repo root: python3 art/pixellab-iron-kit/tower_gen.py"""
import sys, json, random, math
sys.path.insert(0,'art/pixellab-iron-kit')
import iron_gen as K
from iron_gen import G, px, dec, outline, H, INK
from PIL import Image, ImageDraw, ImageFont
O='art/pixellab-iron-kit/'
# (colours are set per set below)
# ---------------- tower_night: a hanging chain and candle stubs (v2: heavy, few, large; top 32x16, bottom 32x12) ----------------
G.update(chain=H('#D2CCE0'),chain_d=H('#8A839F'),wax=H('#F7EFD6'),wax_d=H('#CDBF98'),flame=H('#F2A93A'),flame_l=H('#FFF1B0'),wick=H('#2A2326'))
INKC=INK
def rect(d,x0,y0,x1,y1,c): d.rectangle((x0,y0,x1,y1),fill=c)
def link_face(d,x,y):          # 5 wide x 5 tall ring, 1 px hole 3x... (hole stays transparent, the outline inks it)
    rect(d,x,y,x+4,y+4,G['chain']); rect(d,x+1,y+1,x+3,y+3,(0,0,0,0)); rect(d,x+1,y+1,x+3,y+3,INKC)
    rect(d,x,y+4,x+4,y+4,G['chain_d']); rect(d,x+4,y,x+4,y+4,G['chain_d'])
def link_edge(d,x,y):          # a link seen from the side: 2 wide x 5 tall
    rect(d,x,y,x+1,y+4,G['chain']); rect(d,x+1,y,x+1,y+4,G['chain_d'])

def chain(d,x,y0,n):
    y=y0
    for k in range(n):
        if k%2==0: link_face(d,x,y)
        else: link_edge(d,x+1,y)
        y+=4
def top_night(im,d,r,w,h):
    xs=(5,19) if r.random()<.5 else (9,23)
    for x,n in zip(xs,(4,3)): chain(d,x,0,n)
    for x in (2,15,28):                         # a fat wax drip on the edge between them
        L=r.randrange(4,7); rect(d,x,0,x+1,L-2,G['wax']); rect(d,x+1,0,x+1,L-2,G['wax_d']); rect(d,x,L-1,x+1,L-1,G['wax_d'])
def candle(d,x,h,top):
    body=h-top                                 # wax body 5 wide from y=top to the bottom
    rect(d,x,top,x+4,h-1,G['wax']); rect(d,x+4,top,x+4,h-1,G['wax_d']); rect(d,x,top,x+4,top,G['wax_d'] if False else G['wax'])
    rect(d,x,h-1,x+4,h-1,G['wax_d'])
    rect(d,x+1,top,x+1,top+2,G['wax_d'])      # a drip running down the side
    rect(d,x+2,top-2,x+2,top-1,G['wick'])
    rect(d,x+1,top-6,x+3,top-3,G['flame']); rect(d,x+2,top-8,x+2,top-6,G['flame']); rect(d,x+2,top-5,x+2,top-3,G['flame_l'])
def bottom_night(im,d,r,w,h):
    candle(d,5,h,r.randrange(7,9)); candle(d,21,h,r.randrange(8,10))
    rect(d,12,h-2,16,h-1,G['wax']); rect(d,16,h-2,16,h-1,G['wax_d'])
def corner_night(im,d,r,w,h):
    a=r.randrange(9,13); b=r.randrange(9,13)
    for x in range(a): px(d,x,0,G['chain_d']); px(d,x,1,G['chain'] if x%2==0 else G['chain_d'])
    for y in range(1,b): px(d,0,y,G['chain_d']); px(d,1,y,G['chain'] if y%2==0 else G['chain_d'])
    for k in range(3): px(d,3,2+k,G['wax'] if k<2 else G['wax_d'])
    px(d,2,2,G['chain_d'])
# ---------------- tower_stone: bold cracks that break the edge, rubble (v2) ----------------
G.update(stone=H('#B2ACBF'),stone_d=H('#6C6479'),stone_l=H('#DDD8E8'),crk=H('#14111A'),dust=H('#A8A194'))
def crack_pts(r,x,y,L,dirn=1):
    pts=[(x,y)]; sx=r.choice((-1,1))
    while y<L:
        y+=dirn*2; x+=sx
        if r.random()<.4: sx=-sx
        pts.append((x,y))
    return pts
def draw_crack(d,pts,w,h,core,fr,rad):
    cs=set()
    for (x,y) in pts:
        for dx in (0,1):
            for dy in (0,1): cs.add((x+dx,y+dy))
    for a,b in zip(pts,pts[1:]):                 # fill the steps between points
        for t in range(1,4):
            xx=round(a[0]+(b[0]-a[0])*t/4); yy=round(a[1]+(b[1]-a[1])*t/4)
            for dx in (0,1):
                for dy in (0,1): cs.add((xx+dx,yy+dy))
    ring={(x+dx,y+dy) for (x,y) in cs for dx in range(-rad,rad+1) for dy in range(-rad,rad+1)}-cs
    for p_ in ring:
        if 0<=p_[0]<w and 0<=p_[1]<h: px(d,p_[0],p_[1],fr)
    for p_ in cs:
        if 0<=p_[0]<w and 0<=p_[1]<h: px(d,p_[0],p_[1],core)
def top_stone(im,d,r,w,h):
    for x0,L in ((8,14),(23,12)):
        pts=crack_pts(r,x0,0,L); draw_crack(d,pts,w,h,G['crk'],G['stone_l'],1)
        mx,my=pts[len(pts)//2]; br=crack_pts(r,mx+2,my,my+4); draw_crack(d,br,w,h,G['crk'],G['stone_l'],1)
    for x in (2,13,25): rect(d,x,0,x+2,1,G['stone_l'])        # chips of lit stone on the edge
def chunk(d,x,y,wd,ht):
    rect(d,x,y,x+wd-1,y+ht-1,G['stone']); rect(d,x,y,x+wd-1,y,G['stone_l']); rect(d,x,y,x,y+ht-1,G['stone_l'])
    rect(d,x,y+ht-1,x+wd-1,y+ht-1,G['stone_d']); rect(d,x+wd-1,y+1,x+wd-1,y+ht-1,G['stone_d']); px(d,x+wd-1,y,(0,0,0,0)); px(d,x,y+ht-1,(0,0,0,0))
def bottom_stone(im,d,r,w,h):
    chunk(d,2,h-5,7,5); chunk(d,8,h-7,6,7); chunk(d,15,h-4,5,4); chunk(d,22,h-6,7,6); chunk(d,27,h-3,4,3)
    for x in (13,20,31): px(d,x,h-1,G['dust'])
def corner_stone(im,d,r,w,h):
    a=r.randrange(8,12); b=r.randrange(8,12)
    for x in range(a): px(d,x,0,G['stone_d']); px(d,x,1,G['stone'])
    for y in range(1,b): px(d,0,y,G['stone_d']); px(d,1,y,G['stone'])
    for p in ((3,2),(4,3),(4,4),(5,5)): px(d,*p,G['stone_d'])         # a crack running off the corner
    px(d,2,2,G['stone_l']); px(d,6,2,G['dust'])
# ---------------- tower_void: wide violet cracks with a flat halo, wisps (v2) ----------------
G.update(v=H('#A987EA'),v_d=H('#6A4FB0'),v_l=H('#F0E6FF'),v_k=H('#2A1A52'),v_h=H('#8E6BE0'))
def top_void(im,d,r,w,h):
    for x0,L in ((8,14),(24,12)):
        pts=crack_pts(r,x0,0,L); draw_crack(d,pts,w,h,G['v_l'],G['v_h'],2)
def wisp(d,x,top,h,r):
    x0=x
    for y in range(h-1,top-1,-1):
        for dx in (0,1): px(d,x+dx,y,G['v_l'])
        if (h-1-y)%3==2: x+=r.choice((-1,1))
def bottom_void(im,d,r,w,h):
    for x0,L in ((9,4),(23,5)):
        pts=crack_pts(r,x0,h,h-1,-1) if False else [(x0,h-2),(x0+1,h-4),(x0,h-6)]
        draw_crack(d,[(x0,h-3),(x0+1,h-5)],w,h,G['v_l'],G['v_h'],2)
    wisp(d,15,0,h,r); wisp(d,27,3,h,r)
    for x in range(w):
        if x%2==0: px(d,x,h-1,G['v_h'])
def corner_void(im,d,r,w,h):
    a=r.randrange(9,13); b=r.randrange(9,13)
    for x in range(a): px(d,x,0,G['v_d']); px(d,x,1,G['v'] if x%2==0 else G['v_k'])
    for y in range(1,b): px(d,0,y,G['v_d']); px(d,1,y,G['v'] if y%2==0 else G['v_k'])
    for p in ((3,2),(4,3),(5,4),(5,5),(6,6)): px(d,*p,G['v'])
    px(d,3,2,G['v_l']); px(d,5,5,G['v_l'])
SZ={'top':(32,16),'bottom':(32,12),'corner':(16,16)}
def MAKE(kind,fn,seed):
    w,h=SZ[kind]; return K.outline(K.dec(w,h,fn,seed))
SETS={'tower_night':(top_night,bottom_night,corner_night),'tower_stone':(top_stone,bottom_stone,corner_stone),'tower_void':(top_void,bottom_void,corner_void)}
if __name__=='__main__':
    anchors={}
    for name,(t,b,c) in SETS.items():
        for i in range(3):
            for kind,fn in (('top',t),('bottom',b),('corner',c)):
                seed=sum(map(ord,name))*31+i*17+len(kind)*5
                MAKE(kind,fn,seed).save(f'{O}env/{name}_{kind}_{i}.png',optimize=True)
        anchors[name]={'top':{'files':[f'{name}_top_{i}.png' for i in range(3)],'size':[32,16],'anchor':'top edge (hangs down); tile, cycle variants, overlap 4 px'},
                       'bottom':{'files':[f'{name}_bottom_{i}.png' for i in range(3)],'size':[32,12],'anchor':'bottom edge (rises)'},
                       'corner':{'files':[f'{name}_corner_{i}.png' for i in range(3)],'size':[16,16],'anchor':'top-left outer corner; mirror for the others; thin L, transparent elsewhere'},
                       'tower_band':{'tower_night':'night floors','tower_stone':'stone floors','tower_void':'void floors'}[name]}
    json.dump(anchors,open(O+'anchors_tower.json','w'),indent=1)
    # the sheet: each Tower set on iron, silver and gilt panels + HUD panel + buttons (corners only)
    sys.path.insert(0,O); import materials_gen as M
    LIGHT=(233,224,201); DARK=(24,22,28); F=ImageFont.load_default(size=12)
    def stack(mat,env):
        M.set_mat(mat); pan=K.stretch(M.load(mat,'panel_dark'),84,52,8); hud=K.stretch(M.load(mat,'hud_panel'),84,22,5); btn=K.stretch(M.load(mat,'button_secondary_normal'),56,18,6)
        pan=K.apply_env(pan,env); hud=K.apply_env(hud,env,2); btn=K.apply_env(btn,env,3,edges=False)
        return pan,hud,btn
    tiers=['iron','silver','gilt']; envs=list(SETS)
    cw=3*90+20; rh=3*(52+22+18+10)+30
    sh=Image.new('RGB',(2*len(envs)*cw+20,len(tiers)*rh+30),LIGHT); d=ImageDraw.Draw(sh)
    for half,bg in enumerate((LIGHT,DARK)):
        x0=10+half*len(envs)*cw; d.rectangle((x0-5,0,x0+len(envs)*cw,sh.height),fill=bg)
        for r_,t in enumerate(tiers):
            for j,env in enumerate(envs):
                pan,hud,btn=stack(t,env); x=x0+j*cw; y=8+r_*rh
                d.text((x,y),f'{env} on {t}',font=F,fill=(35,31,26) if half==0 else (233,224,201))
                cell=Image.new('RGB',(90,52+22+18+14),bg); cell.paste(pan,(2,2),pan); cell.paste(hud,(2,58),hud); cell.paste(btn,(2,84),btn)
                sh.paste(cell.resize((cell.width*3,cell.height*3),Image.NEAREST),(x,y+16))
    sh.save('docs/art/boards/tower-decorations.png'); print(sh.size)
