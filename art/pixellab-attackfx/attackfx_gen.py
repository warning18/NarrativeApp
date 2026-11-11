"""Pilot: rawer die-landing and basic-hit strips, hand-drawn in code (0 generations).
die_* strips: 40x40 x 8 frames (20-cell grid x2), same slot as assets/visuals/pixel_fx/die_*.png.
hit_slash: 48x48 x 8 frames (24-cell grid x2), a basic attack hit on the target.
5 colours + ink, hard edges, no glow. Run from the repo root."""
import math, os
from PIL import Image, ImageDraw
import numpy as np
from scipy import ndimage
INK=(10,8,7,255)
def H(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))+(255,)
PAL={'ember':[H('#A84E12'),H('#E0762B'),H('#F2C14E'),H('#FAF2DA')],
 'tide':[H('#226565'),H('#4FB0B0'),H('#CFE6F2'),H('#FFFFFF')],
 'heal':[H('#3D7A2C'),H('#7DBE6A'),H('#C8EE9A'),H('#FAF2DA')],
 'steel':[H('#6B6356'),H('#A8A194'),H('#E9DFC4'),H('#FFFFFF')]}
def grid(n): return Image.new('RGBA',(n,n),(0,0,0,0))
def ring_px(g,cx,cy,r,col,w=1):
    px=g.load(); n=g.width
    for y in range(n):
        for x in range(n):
            d=math.hypot(x+.5-cx,y+.5-cy)
            if r-w/2<=d<=r+w/2: px[x,y]=col
def disc(g,cx,cy,r,col):
    px=g.load(); n=g.width
    for y in range(n):
        for x in range(n):
            if math.hypot(x+.5-cx,y+.5-cy)<=r: px[x,y]=col
def line(g,x0,y0,x1,y1,col):
    ImageDraw.Draw(g).line([(x0,y0),(x1,y1)],fill=col,width=1)
def finish(g,scale=2,ring_min=6):
    a=np.array(g); m=a[...,3]>0
    lab,k=ndimage.label(m); big=np.isin(lab,[j for j in range(1,k+1) if (lab==j).sum()>=ring_min])
    ring=ndimage.binary_dilation(big)&~m
    a[ring]=INK
    return Image.fromarray(np.kron(a,np.ones((scale,scale,1),np.uint8)))
def strip(frames): 
    w=frames[0].width; s=Image.new('RGBA',(w*len(frames),frames[0].height),(0,0,0,0))
    for i,f in enumerate(frames): s.paste(f,(i*w,0))
    return s
def strike():
    c=PAL['ember']; out=[]
    for t in range(8):
        g=grid(20); cx=cy=10
        fade=t>=5
        if t<=4: disc(g,cx,cy,[1.5,3,4,3.5,2.5][t],c[3 if t<3 else 2])
        if t<=5:
            L=[2,5,7,8,8,8][t]
            for a in range(8):
                ang=a*math.pi/4; l0=2+t*.6; 
                for s in range(int(l0),int(L)+1):
                    x=int(round(cx+math.cos(ang)*s)); y=int(round(cy+math.sin(ang)*s))
                    if 0<=x<20 and 0<=y<20: g.putpixel((x,y),c[2 if s<L-1 else 1])
        if 1<=t<=7: ring_px(g,cx,cy,2+t*1.2,c[1] if t<6 else c[0],w=1.6 if t<5 else 1)
        if fade:
            a=np.array(g); a[(np.indices(a.shape[:2]).sum(0)+t)%(2 if t==5 else 3)!=0]=0; g=Image.fromarray(a)
        out.append(finish(g))
    return strip(out)
def ward():
    c=PAL['tide']; out=[]
    for t in range(8):
        g=grid(20); cx=cy=10; r=[2,4,6,7.5,8,8,8,8][t]
        pts=[(cx+math.cos(math.radians(60*i+30))*r,cy+math.sin(math.radians(60*i+30))*r) for i in range(6)]
        d=ImageDraw.Draw(g)
        if t<=3: d.polygon(pts,fill=c[1] if t<2 else c[0])
        if t<=3 and t>=1: d.polygon([(cx+(x-cx)*.55,cy+(y-cy)*.55) for x,y in pts],fill=c[2])
        if t<=4: d.line(pts+[pts[0]],fill=c[3] if t<3 else c[2],width=1)
        else:
            a=np.array(g)
            for i in range(6):
                if (i+t)%2==0 or t<6: d.line([pts[i],pts[(i+1)%6]],fill=c[2] if t<7 else c[1],width=1)
        if t>=3:
            for (x,y) in pts[::2]: g.putpixel((int(x)%20,int(y)%20),c[3])
        out.append(finish(g))
    return strip(out)
def bloom():
    c=PAL['heal']; out=[]
    sp=[(4,0.0),(10,0.3),(16,0.6)]
    for t in range(8):
        g=grid(20)
        if t<=5: disc(g,10,12,[3,5,7,7,6,4][t],c[1]); 
        if 1<=t<=4: disc(g,10,12,[0,3,4,5,3][t],c[3])
        for x,ph in sp:
            tt=t-ph*8*.6
            if tt<0: continue
            y=int(11-tt*2.2)
            if y<1 or tt>6: continue
            col=c[3] if tt<3 else c[2]
            for dx,dy in ((0,0),(1,0),(-1,0),(0,1),(0,-1)):
                if 0<=x+dx<20 and 0<=y+dy<20: g.putpixel((x+dx,y+dy),col)
        out.append(finish(g,ring_min=5))
    return strip(out)
def hit_slash():
    c=PAL['steel']; out=[]
    for t in range(8):
        g=grid(24); px=g.load()
        head=min(1.0,(t+1)/3.0); tail=max(0.0,(t-2.5)/4.5)
        for y in range(24):
            for x in range(24):
                dx=x+.5-12; dy=y+.5-12
                if math.hypot(dx,dy)>11.2: continue
                if math.hypot(x+.5-8.5,y+.5-15.5)<=10.2: continue      # the inner circle cuts the crescent
                ang=(math.degrees(math.atan2(-dy,dx))+360)%360        # 0 = right, 90 = up
                u=(ang-20)/(200-20)                                    # sweep from the lower right round the top to the left
                if u<0 or u>1 or u>head or u<tail: continue
                edge=11.2-math.hypot(dx,dy)
                col=c[3] if (edge<1.6 and u>head-.35) else c[2] if edge<3 else c[1] if edge<5 else c[0]
                px[x,y]=col
        if 1<=t<=4:
            for ang in (200,240,160):
                x=int(12+math.cos(math.radians(ang))*(6+t*1.5)); y=int(12-math.sin(math.radians(ang))*(6+t*1.5))
                if 0<=x<24 and 0<=y<24: g.putpixel((x,y),c[2])
        out.append(finish(g,ring_min=4))
    return strip(out)
OUT={'die_strike':strike,'die_ward':ward,'die_bloom':bloom,'hit_slash':hit_slash}
def png8(im):
    a=im.convert('RGBA'); cols={}; pal=[0,0,0]; q=Image.new('P',a.size,0); px=a.load(); qp=q.load()
    for y in range(a.height):
        for x in range(a.width):
            r,g,b,al=px[x,y]
            if al<128: continue
            k=(r,g,b)
            if k not in cols: cols[k]=len(cols)+1; pal+=list(k)
            qp[x,y]=cols[k]
    q.putpalette(pal+[0]*(768-len(pal))); q.info['transparency']=0; return q
if __name__=='__main__':
    R='art/pixellab-attackfx'
    for k,fn in OUT.items():
        im=fn(); png8(im).save(f'{R}/strips/{k}.png',optimize=True)
        w=im.height; fr=[]
        for i in range(im.width//w):
            bg=Image.new('RGBA',(w*3,w*3),(31,28,35,255)); f=im.crop((i*w,0,i*w+w,w)).resize((w*3,w*3),Image.NEAREST); bg.alpha_composite(f); fr.append(bg.convert('RGB'))
        fr[0].save(f'{R}/gif/{k}.gif',save_all=True,append_images=fr[1:],duration=90,loop=0)
    LIGHT=(31,28,35)
    sh=Image.new('RGB',(120+8*(48*2+4),len(OUT)*2*104+10),LIGHT)
    from PIL import ImageDraw as ID; d=ID.Draw(sh); y=5
    for k in OUT:
        new=Image.open(f'{R}/strips/{k}.png').convert('RGBA')
        todayp=f'assets/visuals/pixel_fx/{k}.png'
        today=Image.open(todayp).convert('RGBA') if os.path.exists(todayp) else (Image.open('assets/visuals/pixel_fx/vfx_claw.png').convert('RGBA') if k=='hit_slash' else None)
        for lab,im in (('today',today),('proposal',new)):
            d.text((5,y+40),f'{k}\n{lab}',fill=(234,224,201))
            if im is not None:
                w=im.height; sc=2 if w==48 else 2.4
                for i in range(im.width//w):
                    f=im.crop((i*w,0,i*w+w,w)).resize((int(w*sc),int(w*sc)),Image.NEAREST); sh.paste(f,(120+i*100,y),f)
            y+=104
    sh.save('docs/art/boards/attack-fx-pilot.png'); print(sh.size)
