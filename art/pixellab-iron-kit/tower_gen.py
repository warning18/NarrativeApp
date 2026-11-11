"""The Tower's decoration sets for the iron kit (the Tower floors' bands are night / stone / void): tower_night (hanging chains, candle wax),
tower_stone (cracked stone, dust, rubble), tower_void (violet cracks, a little void glow). Same format as the other environments (env/<name>_{top,bottom,corner}_<0..2>.png:
top 32x10, bottom 32x8, corner 16x16 L-piece, transparent, own ink). Hand-drawn in code, 0 generations. Repo root: python3 art/pixellab-iron-kit/tower_gen.py"""
import sys, json, random, math
sys.path.insert(0,'art/pixellab-iron-kit')
import iron_gen as K
from iron_gen import G, px, dec, outline, H
from PIL import Image, ImageDraw, ImageFont
O='art/pixellab-iron-kit/'
G.update(chain=H('#9A94A8'),chain_d=H('#4F4A5C'),wax=H('#F0E6C8'),wax_d=H('#C9BC96'),flame=H('#F2C14E'),flame_l=H('#FFF1B0'),
 stone=H('#8A8497'),stone_d=H('#51495A'),stone_l=H('#B9B3C6'),dust=H('#A8A194'),
 v=H('#A987EA'),v_d=H('#6A4FB0'),v_l=H('#E6D6FF'),v_k=H('#2A1A52'))
# ---------------- tower_night: chains and candle wax ----------------
def top_night(im,d,r,w,h):
    xs=sorted(r.sample(range(3,w-5),2))
    for x in xs:
        n=r.choice((2,3))
        for k in range(n):       # a chain: open links 3 wide, 3 tall, one below the other (overlapping a row)
            y=k*2
            for dx in range(3): px(d,x+dx,y,G['chain'])
            px(d,x,y+1,G['chain_d']); px(d,x+2,y+1,G['chain_d'])
            for dx in range(3): px(d,x+dx,y+2,G['chain_d'])
        px(d,x+1,0,G['chain_d'])
    for _ in range(3):           # wax drips along the edge
        x=r.randrange(w-1)
        if all(abs(x-c)>3 for c in xs):
            L=r.randrange(2,5)
            for y in range(L): px(d,x,y,G['wax'] if y<L-1 else G['wax_d'])
def bottom_night(im,d,r,w,h):
    for _ in range(2):
        x=r.randrange(3,w-5); d.rectangle((x,h-4,x+2,h-1),fill=G['wax']); d.rectangle((x,h-4,x+2,h-4),fill=G['wax_d'])
        px(d,x+1,h-5,G['flame']); px(d,x+1,h-6,G['flame_l'])
    for x in range(w):
        if r.random()<.4: px(d,x,h-1,G['wax_d'])
def corner_night(im,d,r,w,h):
    a=r.randrange(9,13); b=r.randrange(9,13)
    for x in range(a): px(d,x,0,G['chain_d']); px(d,x,1,G['chain'] if x%2==0 else G['chain_d'])
    for y in range(1,b): px(d,0,y,G['chain_d']); px(d,1,y,G['chain'] if y%2==0 else G['chain_d'])
    for k in range(3): px(d,3,2+k,G['wax'] if k<2 else G['wax_d'])
    px(d,2,2,G['chain_d'])
# ---------------- tower_stone: cracks, dust, rubble ----------------
def top_stone(im,d,r,w,h):
    for _ in range(4):
        x=r.randrange(2,w-2); y=0
        while y<r.randrange(3,h):
            px(d,x,y,G['stone_d']); y+=1
            if r.random()<.5: x+=r.choice((-1,1)); px(d,x,y,G['stone_d'])
    for x in range(w):
        if r.random()<.35: px(d,x,0,G['dust'])
def bottom_stone(im,d,r,w,h):
    for x in range(w):
        for y in range(h-1,h-1-r.randrange(0,3),-1): px(d,x,y,G['stone'] if y<h-1 else G['stone_d'])
    for _ in range(4): x=r.randrange(w-2); y=h-r.randrange(3,6); d.rectangle((x,y,x+1,y+1),fill=G['stone_l']); px(d,x+1,y+1,G['stone_d'])
def corner_stone(im,d,r,w,h):
    a=r.randrange(8,12); b=r.randrange(8,12)
    for x in range(a): px(d,x,0,G['stone_d']); px(d,x,1,G['stone'])
    for y in range(1,b): px(d,0,y,G['stone_d']); px(d,1,y,G['stone'])
    for p in ((3,2),(4,3),(4,4),(5,5)): px(d,*p,G['stone_d'])         # a crack running off the corner
    px(d,2,2,G['stone_l']); px(d,6,2,G['dust'])
# ---------------- tower_void: violet cracks, a little glow ----------------
def top_void(im,d,r,w,h):
    for _ in range(4):
        x=r.randrange(2,w-2); y=0; L=r.randrange(3,h)
        while y<L:
            px(d,x,y,G['v']); 
            if y>1 and r.random()<.4: px(d,x,y-1,G['v_l'])
            y+=1
            if r.random()<.5: x+=r.choice((-1,1)); px(d,x,y,G['v_d'])
    for x in range(w):
        if r.random()<.3: px(d,x,0,G['v_k'])
def bottom_void(im,d,r,w,h):
    for x in range(w):
        if r.random()<.35: px(d,x,h-1,G['v_d'])
    for _ in range(4):
        x=r.randrange(1,w-1); y=h-r.randrange(2,6); px(d,x,y,G['v_l']); px(d,x,y+1,G['v'])       # wisps rising
    for _ in range(2): x=r.randrange(2,w-3); d.line([(x,h-1),(x+2,h-3)],fill=G['v'])
def corner_void(im,d,r,w,h):
    a=r.randrange(9,13); b=r.randrange(9,13)
    for x in range(a): px(d,x,0,G['v_d']); px(d,x,1,G['v'] if x%2==0 else G['v_k'])
    for y in range(1,b): px(d,0,y,G['v_d']); px(d,1,y,G['v'] if y%2==0 else G['v_k'])
    for p in ((3,2),(4,3),(5,4),(5,5),(6,6)): px(d,*p,G['v'])
    px(d,3,2,G['v_l']); px(d,5,5,G['v_l'])
SETS={'tower_night':(top_night,bottom_night,corner_night),'tower_stone':(top_stone,bottom_stone,corner_stone),'tower_void':(top_void,bottom_void,corner_void)}
if __name__=='__main__':
    anchors={}
    for name,(t,b,c) in SETS.items():
        for i in range(3):
            for kind,fn in (('top',t),('bottom',b),('corner',c)):
                seed=sum(map(ord,name))*31+i*17+len(kind)*5
                K.make_env(name,i,kind,fn,seed).save(f'{O}env/{name}_{kind}_{i}.png',optimize=True)
        anchors[name]={'top':{'files':[f'{name}_top_{i}.png' for i in range(3)],'size':[32,10],'anchor':'top edge (hangs down); tile, cycle variants, overlap 4 px'},
                       'bottom':{'files':[f'{name}_bottom_{i}.png' for i in range(3)],'size':[32,8],'anchor':'bottom edge (rises)'},
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
