"""Tower board look study: ladder pieces, snake pieces, stone steps per band, board markers, and a mock sheet of the 30-floor board (5 x 6, floor 1 bottom-left, winding).
Hand-drawn in code, one ink, light from the top-left, no glow, transparent backgrounds. 0 generations. Repo root: python3 art/pixellab-tower-board/board_gen.py"""
import os, sys, json, math
sys.path.insert(0,'art/pixellab-iron-kit')
from PIL import Image, ImageDraw, ImageFont
def H(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))+(255,)
INK=H('#0A0807'); O='art/pixellab-tower-board/'
def new(w,h): return Image.new('RGBA',(w,h),(0,0,0,0))
def outline(im,sides='lrtb'):
    w,h=im.size; s=im.load(); big=new(w+2,h+2); big.paste(im,(1,1)); b=big.load(); res=big.copy(); r=res.load()
    dirs=[]
    if 'l' in sides: dirs.append((1,0))     # pixel with solid to its right gets ink on its left
    if 'r' in sides: dirs.append((-1,0))
    if 't' in sides: dirs.append((0,1))
    if 'b' in sides: dirs.append((0,-1))
    for y in range(h+2):
        for x in range(w+2):
            if b[x,y][3]==0 and any(0<=x+dx<w+2 and 0<=y+dy<h+2 and b[x+dx,y+dy][3]>0 for dx,dy in dirs): r[x,y]=INK
    # crop the padding on the open sides
    x0=0 if 'l' in sides else 1; x1=w+2 if 'r' in sides else w+1; y0=0 if 't' in sides else 1; y1=h+2 if 'b' in sides else h+1
    return res.crop((x0,y0,x1,y1))
WOOD=dict(m=H('#8A5A2B'),hi=H('#B08050'),lo=H('#4A2E18')); IRONC=dict(m=H('#6B6578'),hi=H('#A8A2B8'),lo=H('#3A3644'))
# ---------------- ladder: 12 wide; top cap 8, tileable middle 8, bottom cap 8 ----------------
def ladder(kind):
    P=WOOD; out={}
    def rails(d,y0,y1):
        for x0 in (1,8): d.rectangle((x0,y0,x0+2,y1),fill=P['m']); d.line([(x0,y0),(x0,y1)],fill=P['hi']); d.line([(x0+2,y0),(x0+2,y1)],fill=P['lo'])
    def banded(d,y):
        if kind=='iron':
            for x0 in (1,8): d.rectangle((x0,y,x0+2,y+1),fill=IRONC['m']); d.point((x0,y),fill=IRONC['hi']); d.point((x0+1,y),fill=H('#E8E4F0')); d.point((x0+2,y+1),fill=IRONC['lo'])
    top=new(12,8); d=ImageDraw.Draw(top); rails(d,2,7); d.rectangle((1,1,3,1),fill=P['m']); d.rectangle((8,1,10,1),fill=P['m']); d.rectangle((3,4,8,5),fill=P['m']); d.line([(3,4),(8,4)],fill=P['hi']); banded(d,5)
    mid=new(12,8); d=ImageDraw.Draw(mid); rails(d,0,7); d.rectangle((3,3,8,4),fill=P['m']); d.line([(3,3),(8,3)],fill=P['hi']); d.line([(3,4),(8,4)],fill=P['lo']); banded(d,6)
    bot=new(12,8); d=ImageDraw.Draw(bot); rails(d,0,5); d.rectangle((3,2,8,3),fill=P['m']); d.line([(3,2),(8,2)],fill=P['hi']); d.rectangle((0,6,3,7),fill=P['lo']); d.rectangle((8,6,11,7),fill=P['lo']); banded(d,1)
    return outline(top,'lrt'),outline(mid,'lr'),outline(bot,'lrb')
# ---------------- snake: palettes ----------------
SN={'green':dict(m=H('#5E8A3A'),hi=H('#8AB05A'),lo=H('#2F4A22'),belly=H('#D8D2A0')),'night':dict(m=H('#4A5E86'),hi=H('#7A92BA'),lo=H('#222C44'),belly=H('#B8C4DA')),
    'stone':dict(m=H('#7A7A5E'),hi=H('#A8A888'),lo=H('#3F3F2E'),belly=H('#CFC9AE')),'void':dict(m=H('#6A4FB0'),hi=H('#A987EA'),lo=H('#2A1A52'),belly=H('#E6D6FF'))}
def snake(v):
    P=SN[v]
    def body_h(d,x0=0,x1=11):
        d.rectangle((x0,2,x1,9),fill=P['m']); d.line([(x0,2),(x1,2)],fill=P['hi']); d.rectangle((x0,8,x1,9),fill=P['belly'])
        for x in range(x0,x1+1,4): d.point((x+1,4),fill=P['lo']); d.point((x+2,5),fill=P['lo']); d.point((x+3,4),fill=P['lo'])
    straight=new(12,12); d=ImageDraw.Draw(straight); body_h(d)
    straight=outline(straight,'tb')
    curve=new(12,12); d=ImageDraw.Draw(curve)       # enters on the left, leaves at the bottom
    for y in range(12):
        for x in range(12):
            r=math.hypot(x-0.5,y-11.5+0)   # centre of the bend at the bottom-left corner of the tile
            if 3.0<=math.hypot(x+0.5-0,y+0.5-12)<=11.0 and x>=0: pass
    cx,cy=0,12
    for y in range(12):
        for x in range(12):
            rr=math.hypot(x+.5-cx,y+.5-cy)
            if 2<=rr<=10: curve.putpixel((x,y),P['m'])
            if 2<=rr<3.2: curve.putpixel((x,y),P['belly'])
            elif 9<=rr<=10: curve.putpixel((x,y),P['hi'])
    for p in ((5,5),(7,6),(6,8),(4,9)): curve.putpixel(p,P['lo'])
    curve=outline(curve,'tr')
    tail=new(12,12); d=ImageDraw.Draw(tail); d.polygon([(0,2),(8,4),(11,5),(11,6),(8,7),(0,9)],fill=P['m']); d.line([(0,2),(8,4)],fill=P['hi']); d.polygon([(0,8),(8,7),(0,9)],fill=P['belly'])
    for x in (2,5): d.point((x,4),fill=P['lo'])
    tail=outline(tail,'tb')
    head=new(16,12); d=ImageDraw.Draw(head); d.rectangle((0,2,5,9),fill=P['m']); d.ellipse((3,1,13,10),fill=P['m']); d.line([(1,2),(8,2)],fill=P['hi']); d.rectangle((2,8,9,9),fill=P['belly'])
    d.rectangle((9,4,10,5),fill=H('#F2C14E')); d.point((10,4),fill=INK)       # an eye
    d.line([(13,6),(15,6)],fill=H('#C23B33')); d.point((15,5),fill=H('#C23B33')); d.point((15,7),fill=H('#C23B33'))   # a forked tongue
    d.point((5,4),fill=P['lo']); d.point((6,6),fill=P['lo'])
    head=outline(head,'tb')
    return head,straight,curve,tail
# ---------------- stone steps per band ----------------
STEP={'night':dict(top=H('#6A7A9A'),face=H('#3E4A66'),lo=H('#222C44'),seam=H('#222C44')),'stone':dict(top=H('#A8A194'),face=H('#7A7264'),lo=H('#45403A'),seam=H('#45403A')),'void':dict(top=H('#9A7AE0'),face=H('#4A3A7A'),lo=H('#1A1030'),seam=H('#1A1030'))}
def step(band):
    P=STEP[band]; im=new(24,14); d=ImageDraw.Draw(im)
    d.rectangle((0,0,23,5),fill=P['top']); d.line([(0,0),(23,0)],fill=tuple(min(255,int(v*1.2)) for v in P['top'][:3])+(255,))
    d.rectangle((0,6,23,13),fill=P['face']); d.line([(0,13),(23,13)],fill=P['lo']); d.line([(0,6),(23,6)],fill=P['lo'])
    d.line([(8,7),(8,13)],fill=P['seam']); d.line([(17,7),(17,13)],fill=P['seam'])
    if band=='void': d.line([(4,1),(6,3),(5,5)],fill=H('#A987EA')); d.point((19,9),fill=H('#A987EA')); d.point((20,10),fill=H('#A987EA'))
    if band=='stone': d.point((12,2),fill=P['lo']); d.point((3,3),fill=P['lo'])
    return outline(im,'tb')
# ---------------- markers ----------------
def ring(n,inner,col,hi,lo):
    im=new(n,n); d=ImageDraw.Draw(im); d.ellipse((0,0,n-1,n-1),fill=col)
    h=(n-inner)//2; d.ellipse((h,h,n-1-h,n-1-h),fill=(0,0,0,0))
    d.arc((0,0,n-1,n-1),180,300,fill=hi,width=1); d.arc((0,0,n-1,n-1),0,120,fill=lo,width=1)
    return outline(im)
def shield_mark():
    im=new(14,14); d=ImageDraw.Draw(im); d.polygon([(1,0),(12,0),(12,7),(6,13),(1,7)],fill=H('#A8A194')); d.line([(1,0),(12,0)],fill=H('#E9DFC4')); d.polygon([(6,0),(12,0),(12,7),(6,13)],fill=H('#6B6356'))
    d.rectangle((5,3,7,5),fill=H('#F2C14E')); d.point((5,3),fill=H('#FFE08A')); return outline(im)
def boss_mark():
    im=new(14,14); d=ImageDraw.Draw(im); d.polygon([(0,1),(3,3),(3,5),(1,6)],fill=H('#C23B33')); d.polygon([(13,1),(10,3),(10,5),(12,6)],fill=H('#C23B33'))
    d.ellipse((2,3,11,11),fill=H('#E9DFC4')); d.rectangle((4,6,5,7),fill=INK); d.rectangle((8,6,9,7),fill=INK); d.rectangle((6,9,7,10),fill=INK); d.line([(3,4),(8,3)],fill=H('#FAF2DA')); return outline(im)
# ---------------- the 3x5 pixel digits for the mock ----------------
DG={'0':'111101101101111','1':'010110010010111','2':'111001111100111','3':'111001111001111','4':'101101111001001','5':'111100111001111','6':'111100111101111','7':'111001001001001','8':'111101111101111','9':'111101111001111'}
def digits(n,col=(220,214,200,255)):
    s=str(n); im=new(len(s)*4-1,5); p=im.load()
    for i,ch in enumerate(s):
        for k,b in enumerate(DG[ch]):
            if b=='1': p[i*4+k%3,k//3]=col
    return im
def place(dst,src,x,y,rot=0,flip=False):
    s=src.rotate(rot,expand=True) if rot else src
    if flip: s=s.transpose(Image.FLIP_LEFT_RIGHT)
    dst.alpha_composite(s,(int(x),int(y)))
if __name__=='__main__':
    for k in ('wood','iron'):
        t,m,b=ladder(k)
        for n,im in (('top',t),('mid',m),('bot',b)): im.save(f'{O}ladder/ladder_{k}_{n}.png',optimize=True)
    for v in SN:
        h,s_,c,t=snake(v)
        for n,im in (('head',h),('straight',s_),('curve',c),('tail',t)): im.save(f'{O}snake/snake_{v}_{n}.png',optimize=True)
    for b in STEP: step(b).save(f'{O}step/step_{b}.png',optimize=True)
    shield_mark().save(O+'markers/warden_shield.png'); boss_mark().save(O+'markers/boss_mark.png')
    ring(16,12,H('#F2C14E'),H('#FFE08A'),H('#B8862A')).save(O+'markers/climbed_ring.png'); ring(26,20,H('#F2C14E'),H('#FFE08A'),H('#B8862A')).save(O+'markers/hero_ring.png')
    json.dump({'ladder':{'width':12,'caps':'top 8, bottom 8, middle 8 tileable vertically; wood and iron-banded','span':'1 to 4 board rows: top + n x mid + bottom'},
      'snake':{'tiles':'head 16x12 (faces right), straight 12x12 (horizontal), curve 12x12 (left to bottom), tail 12x12; rotate 90 degrees to lay along a path; variants green, night, stone, void'},
      'step':{'size':[24,14],'tile':'horizontal','bands':{'night':'floors 1-10','stone':'floors 11-20','void':'floors 21-30'}},
      'markers':{'warden_shield':14,'boss_mark':14,'climbed_ring':16,'hero_ring':'26 outer, 20 inner (frames the head crop)'}},open(O+'anchors.json','w'),indent=1)
    # ---------- the mock: 5 x 6 board, 412 px wide, dark ----------
    CELL=36; GAP=3; M=7; W=5*CELL+4*GAP+2*M; Hh=6*CELL+5*GAP+2*M+60
    S=new(W,Hh); bg=Image.new('RGBA',(W,Hh),(18,17,24,255)); bg.alpha_composite(S)
    panel=Image.open('art/pixellab-iron-kit/ui/panel_dark.png').convert('RGBA')
    sys.path.insert(0,'art/pixellab-iron-kit'); import iron_gen as K
    def cell(band):
        pn=K.stretch(panel,CELL,CELL,8); px=pn.load(); tint={'night':(26,30,52),'stone':(38,36,42),'void':(44,28,60)}[band]
        for y in range(CELL):
            for x in range(CELL):
                if px[x,y][:3]==(38,32,44): px[x,y]=tint+(255,)
        return pn
    pos={}
    for f in range(1,31):
        r=(f-1)//5; c=(f-1)%5; col=c if r%2==0 else 4-c
        x=M+col*(CELL+GAP); y=M+(5-r)*(CELL+GAP)+0; pos[f]=(x,y)
        band='night' if f<=10 else 'stone' if f<=20 else 'void'
        bg.alpha_composite(cell(band),(x,y)); bg.alpha_composite(digits(f),(x+4,y+4))
        if f in (5,15,25): bg.alpha_composite(Image.open(O+'markers/warden_shield.png'),(x+CELL-18,y+CELL-18))
        if f in (10,20,30): bg.alpha_composite(Image.open(O+'markers/boss_mark.png'),(x+CELL-18,y+CELL-18))
        if f<=12: bg.alpha_composite(Image.open(O+'markers/climbed_ring.png'),(x+CELL-19,y+2))
    ctr=lambda f:(pos[f][0]+CELL//2,pos[f][1]+CELL//2)
    # a ladder from 3 to 8 (two rows), wood
    t,m,b=ladder('wood'); x,y3=ctr(3); _,y8=ctr(8); top=y8-6; bot=y3+8
    n=max(1,(bot-top-16)//8)
    x0=x-6+0; yy=top; bg.alpha_composite(t,(x0-1,yy-1)); yy+=7
    for i in range(n): bg.alpha_composite(m,(x0-1,yy)); yy+=8
    bg.alpha_composite(b,(x0-1,yy))
    # a snake from 17 to 12 (green): head at 17, left across to col 1, then down to 12
    h,s_,c,tl=snake('green'); hx,hy=ctr(17); tx,ty=ctr(12)
    ex=tx   # the column of 12
    # horizontal run from the head leftwards to the corner
    bg.alpha_composite(h.transpose(Image.FLIP_LEFT_RIGHT),(hx-12,hy-7)); x=hx-12
    while x-12>ex-6: x-=12; bg.alpha_composite(s_,(x,hy-7))
    # the corner: the body turns down
    cv=c.transpose(Image.FLIP_LEFT_RIGHT).rotate(0); bg.alpha_composite(cv,(ex-8,hy-7))
    yy=hy+4
    while yy+12<ty-4: bg.alpha_composite(s_.rotate(90,expand=True),(ex-7,yy)); yy+=12
    bg.alpha_composite(tl.rotate(-90,expand=True),(ex-7,yy))
    # the hero token on floor 13
    hero=Image.open('assets/visuals/heads/hero.png').convert('RGBA'); hero=hero.resize((20,int(20*hero.height/hero.width)),Image.NEAREST); cx,cy=ctr(13)
    tok=new(26,26); tok.alpha_composite(hero.crop((0,0,20,20)) if hero.height>=20 else hero,(3,3))
    # clip the crop to the ring's hole
    mask=Image.new('L',(26,26),0); ImageDraw.Draw(mask).ellipse((3,3,22,22),fill=255); tk=new(26,26); tk.paste(tok,(0,0),mask); tk.alpha_composite(Image.open(O+'markers/hero_ring.png'),(0,0)); bg.alpha_composite(tk,(cx-13,cy-13))
    # a stair strip below the board: the three band steps, as a stair of 4 steps each rising by 14
    sy=6*(CELL+GAP)+M+8
    for i,b_ in enumerate(('night','stone','void')):
        st=Image.open(f'{O}step/step_{b_}.png').convert('RGBA')
        for k in range(3): bg.alpha_composite(st,(M+i*130+k*14,sy+30-k*8))
    big=bg.resize((bg.width*2,bg.height*2),Image.NEAREST); big.convert('RGB').save('docs/art/boards/tower-board-look.png'); print(big.size)
    # a flat sheet of the pieces (real size and 3x)
    pcs=[]
    for k in ('wood','iron'): pcs+= [(f'ladder {k}',im) for im in ladder(k)]
    for v in SN: pcs+=[(f'snake {v}',im) for im in snake(v)]
    pcs+=[(f'step {b}',Image.open(f'{O}step/step_{b}.png')) for b in STEP]+[(n,Image.open(f'{O}markers/{n}.png')) for n in ('warden_shield','boss_mark','climbed_ring','hero_ring')]
    F=ImageFont.load_default(size=11); sh=Image.new('RGB',(1100,520),(18,17,24)); d=ImageDraw.Draw(sh); x=10; y=10
    for lab,im in pcs:
        im=im.convert('RGBA'); big=im.resize((im.width*3,im.height*3),Image.NEAREST)
        if x+big.width+10>1090: x=10; y+=90
        sh.paste(big,(x,y+14),big); d.text((x,y),lab[:16],font=F,fill=(233,224,201)); x+=max(big.width,60)+12
    sh.save('docs/art/boards/tower-board-pieces.png')
