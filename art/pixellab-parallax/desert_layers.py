"""Desert parallax pilot, hand work on the generated strips (0 generations): fix the sky's baked ridge, make the far / mid / near strips seamless, compose the sheet.
python3 art/pixellab-parallax/desert_layers.py   (repo root)"""
import numpy as np
from PIL import Image, ImageDraw, ImageFont
R='art/pixellab-parallax/raw/'; O='art/pixellab-parallax/desert/'
def load(k): return np.array(Image.open(R+k+'/get_image_0.png').convert('RGBA'))
def save(a,n): Image.fromarray(a,'RGBA').save(O+n)
# sky (the user's option B, a richer sky): the second sky (forced palette = today's code sky colours, seed 21) with its baked ground cut off: rows 0 to 29 kept (the baked sun dome sits below), the horizon
# row continued down (the code ground sits under it anyway); then a checkerboard dither across every band edge, as the code sky does
sky=load('desert_sky2_s21')
for y in range(30,52): sky[y]=sky[29]
for y in range(10,51):
    for x in range(sky.shape[1]):
        if (x+y)%2==0 and not (sky[y,x,:3]==sky[y+1,x,:3]).all() and (sky[y,x,:3]==sky[y,max(x-1,0),:3]).all() and (sky[y,x,:3]==sky[y,min(x+1,sky.shape[1]-1),:3]).all():
            sky[y,x,:3]=sky[y+1,x,:3]
save(sky,'desert_sky.png')
# far: window starting and ending on flat ground, then mirrored so the tile wraps seamlessly
far=load('desert_far2_s6'); A=far[:,88:192]; farT=np.concatenate([A,A[:,::-1]],axis=1); save(farT,'desert_far.png')
# mid: smooth dunes: the ends differ by 2 rows, so shift each column vertically by a linear ramp
mid=load('desert_mid_s5'); h,w,_=mid.shape
top=lambda col:int(np.argmax(col[:,3]>0)); d=top(mid[:,0])-top(mid[:,w-1]); out=np.zeros_like(mid)
for x in range(w):
    dy=int(round(-d*x/w)); col=mid[:,x]
    out[:,x]=np.roll(col,dy,axis=0)
    if dy>0: out[:dy,x]=0
    if dy<0: out[dy:,x,3]=255; out[dy:,x,:3]=col[-1,:3]
# hand grade: the generated mid dunes are too pale against the sky (they melt into it): warm and darken them, keeping the lit top edge
g=out.astype(float); m=g[...,3]>0
g[m,0]*=0.93; g[m,1]*=0.76; g[m,2]*=0.58
out=np.clip(g,0,255).astype(np.uint8); save(out,'desert_mid.png')
# near: window on flat ground at both ends, mirrored
near=load('desert_near_s5'); A=near[:,30:160]; nearT=np.concatenate([A,A[:,::-1]],axis=1); save(nearT,'desert_near.png')
print({n:Image.open(O+n).size for n in ('desert_sky.png','desert_far.png','desert_mid.png','desert_near.png')})
# ---- the composition ----
UNIT=190/72; W=412; GW=int(round(W/UNIT))+1   # scene pixels across
LAY={'far':(Image.open(O+'desert_far.png'),28,0.15),'mid':(Image.open(O+'desert_mid.png'),38,0.4),'near':(Image.open(O+'desert_near.png'),48,0.8)}
sk=Image.open(O+'desert_sky.png'); ronin=Image.open('assets/visuals/walker/ronin_walk_east.png').convert('RGBA').crop((0,0,42,47))
sandfill=tuple(int(v) for v in np.array(Image.open(O+'desert_mid.png').convert('RGBA'))[10,5,:3])
def scene(scroll_px,dusk=False):
    g=Image.new('RGBA',(GW,72),(0,0,0,255)); g.paste(sk,(0,0))
    if sk.width<GW: g.paste(sk.crop((sk.width-(GW-sk.width),0,sk.width,52)),(sk.width,0))
    d=ImageDraw.Draw(g)
    cx,cy=int(GW*0.72),30                                         # the sun disc stays code
    for y in range(-9,10):
        for x in range(-9,10):
            if x*x+y*y<=25: g.putpixel((cx+x,cy+y),(255,240,184,255))
    d.rectangle((0,52,GW,71),fill=(*sandfill,255))                # the code's ground colour under the layers
    for k in ('far','mid','near'):
        im,y0,sp=LAY[k]; off=int(scroll_px*sp/UNIT)%im.width
        x=-off
        while x<GW:
            g.alpha_composite(im,(x,y0)); x+=im.width
    d.rectangle((0,64,GW,71),fill=(142,90,50,255)); d.line((0,64,GW,64),fill=(176,120,69,255))   # the path stays code (an approximation here)
    big=g.resize((W,190),Image.NEAREST).convert('RGBA')
    rs=ronin.resize((int(42*1.15),int(47*1.15)),Image.NEAREST); big.alpha_composite(rs,(int(96*UNIT)-rs.width//2,int(66*UNIT)-rs.height+2))
    if dusk:
        wash=Image.new('RGBA',big.size,(0x7A,0x4A,0x7C,int(255*0.20))); big=Image.alpha_composite(big,wash)
        dd=ImageDraw.Draw(big)
        for i in range(8):
            sx=int((np.sin(i*12.9898+78.233)*43758.5453)%1*W); sy=int(6+((np.sin(i*12.9898+2*78.233)*43758.5453)%1)*70); dd.rectangle((sx,sy,sx+2,sy+2),fill=(255,255,255,200))
    return big.convert('RGB')
F=ImageFont.load_default(size=13)
today=Image.open('docs/ux-shots/backdrops-crossing-desert-versions.png').convert('RGB').crop((8,54,408,238)).resize((412,190),Image.NEAREST)
rows=[('day',False),('dusk (kit_hour wash)',True)]
sh=Image.new('RGB',(412*4+50,(190+26)*2+30),(20,17,26)); d=ImageDraw.Draw(sh)
d.text((10,4),'Road crossing, desert: today | painted layers at three scroll positions (0, 160 and 320 px), at 412 x 190, the ronin on the code path',font=F,fill=(233,224,201))
for r,(lab,dusk) in enumerate(rows):
    y=24+r*216; d.text((10,y),lab,font=F,fill=(233,224,201))
    if r==0: sh.paste(today,(10,y+18))
    else:
        t=today.convert('RGBA'); wash=Image.new('RGBA',t.size,(0x7A,0x4A,0x7C,int(255*0.20))); sh.paste(Image.alpha_composite(t,wash).convert('RGB'),(10,y+18))
    for i,sc in enumerate((0,160,320)): sh.paste(scene(sc,dusk),(10+(i+1)*(412+10),y+18))
sh.save('docs/art/boards/crossing-parallax-desert-pilot-b.png'); print(sh.size)
