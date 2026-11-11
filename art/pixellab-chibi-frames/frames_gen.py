"""Chibi dark-medieval UI frame kits, three directions, hand-drawn in code (0 generations).
Per direction: panel 24x24 (9-slice, 8 px corners), button normal/pressed 24x16 (9-slice, 6 px corners),
corner ornament 12x12, tileable texture 16x16. Direction A also gets 6 environment accents (corner 12x12 + a stitch tint).
Run from the repo root: python3 art/pixellab-chibi-frames/frames_gen.py"""
import json, os, random
from PIL import Image, ImageDraw
def H(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))+(255,)
INK=H('#0A0807'); CREAM=H('#FAF2DA')
O='art/pixellab-chibi-frames/'
def new(w,h): return Image.new('RGBA',(w,h),(0,0,0,0))
def rr(d,box,fill,r=3):
    x0,y0,x1,y1=box; d.rectangle((x0+r,y0,x1-r,y1),fill=fill); d.rectangle((x0,y0+r,x1,y1-r),fill=fill)
    for cx,cy in ((x0+1,y0+1),(x1-1,y0+1),(x0+1,y1-1),(x1-1,y1-1)): pass
    d.rectangle((x0+1,y0+1,x1-1,y1-1),fill=fill)
def frame(w,h,fill,hi,lo,stitch=None,rivet=None,chamfer=2,border=INK):
    """2 px ink outline with chamfered corners, 1 px light top-left bevel, 1 px shade bottom-right, optional stitching and rivets"""
    im=new(w,h); d=ImageDraw.Draw(im)
    d.rectangle((chamfer,0,w-1-chamfer,h-1),fill=border); d.rectangle((0,chamfer,w-1,h-1-chamfer),fill=border)
    d.rectangle((chamfer,2,w-1-chamfer,h-3),fill=fill); d.rectangle((2,chamfer,w-3,h-3-chamfer+1),fill=fill)
    d.rectangle((2,2,w-3,h-3),fill=fill)
    d.line([(2+chamfer-1,2),(w-3-chamfer+1,2)],fill=hi); d.line([(2,2+chamfer-1),(2,h-3-chamfer+1)],fill=hi)
    d.line([(2+chamfer-1,h-3),(w-3-chamfer+1,h-3)],fill=lo); d.line([(w-3,2+chamfer-1),(w-3,h-3-chamfer+1)],fill=lo)
    if stitch:
        for x in range(5,w-5,2): im.putpixel((x,4),stitch); im.putpixel((x,h-5),stitch)
        for y in range(5,h-5,2): im.putpixel((4,y),stitch); im.putpixel((w-5,y),stitch)
    if rivet:
        for x,y in ((4,4),(w-5,4),(4,h-5),(w-5,h-5)):
            for dx,dy in ((0,0),(1,0),(0,1),(1,1)): im.putpixel((x-0+dx-0,y+dy),rivet)
    return im
# ---------------- direction A: stitched leather (dark, warm) ----------------
A=dict(fill=H('#2B2430'),hi=H('#4A3F52'),lo=H('#17121C'),stitch=H('#C9A25A'))
def a_panel(stitch=None): return frame(24,24,A['fill'],A['hi'],A['lo'],stitch=stitch or A['stitch'])
def a_button(pressed=False):
    f=H('#B5601C'); hi=H('#E0762B'); lo=H('#7A3D10')
    im=frame(24,16,f,hi,lo,chamfer=2)
    if pressed:
        im=frame(24,16,H('#9A4F16'),H('#B5601C'),H('#9A4F16'),chamfer=2)
        d=ImageDraw.Draw(im); d.line([(3,3),(20,3)],fill=H('#7A3D10'))
    return im
def a_corner(col=None):
    im=new(12,12); d=ImageDraw.Draw(im); c=col or H('#C9A25A')
    for x,y in ((0,0),(1,0),(2,0),(3,0),(0,1),(0,2),(0,3)): d.point((x,y),fill=INK)
    d.rectangle((1,1,6,2),fill=c); d.rectangle((1,1,2,6),fill=c); d.rectangle((3,3,4,4),fill=CREAM)
    for x,y in ((7,1),(8,1),(7,2),(1,7),(1,8),(2,7)): d.point((x,y),fill=INK)
    d.line([(7,3),(8,3)],fill=INK); d.line([(3,7),(3,8)],fill=INK)
    return im
def a_texture():
    random.seed(3); im=Image.new('RGBA',(16,16),A['fill']); d=ImageDraw.Draw(im)
    for _ in range(18): x,y=random.randrange(16),random.randrange(16); d.point((x,y),fill=A['hi'] if random.random()<.5 else A['lo'])
    for _ in range(3):
        x,y=random.randrange(2,13),random.randrange(2,13); d.line([(x,y),(x+2,y+1)],fill=A['lo'])
    return im
# ---------------- direction B: forged iron (cold, riveted) ----------------
B=dict(fill=H('#514C5A'),hi=H('#8A8497'),lo=H('#2E2A35'),rivet=H('#C9C3D3'))
def b_panel(): return frame(24,24,B['fill'],B['hi'],B['lo'],rivet=B['rivet'],chamfer=3)
def b_button(pressed=False):
    f,hi,lo=(H('#6B3A2A'),H('#A4604A'),H('#3F2018')) if not pressed else (H('#55301F'),H('#6B3A2A'),H('#55301F'))
    return frame(24,16,f,hi,lo,rivet=B['rivet'] if not pressed else None,chamfer=3)
def b_corner():
    im=new(12,12); d=ImageDraw.Draw(im)
    d.rectangle((0,0,9,3),fill=INK); d.rectangle((0,0,3,9),fill=INK); d.rectangle((1,1,8,2),fill=B['hi']); d.rectangle((1,1,2,8),fill=B['hi'])
    d.rectangle((2,2,3,3),fill=B['rivet']); d.point((7,2),fill=B['lo']); d.point((2,7),fill=B['lo']); return im
def b_texture():
    im=Image.new('RGBA',(16,16),B['fill']); d=ImageDraw.Draw(im)
    for k in range(-16,16,4): d.line([(k,0),(k+16,16)],fill=B['lo'])
    random.seed(5)
    for _ in range(10): d.point((random.randrange(16),random.randrange(16)),fill=B['hi'])
    return im
# ---------------- direction C: carved bone and parchment (light, notched) ----------------
C=dict(fill=H('#E4D7B6'),hi=H('#F5EDD4'),lo=H('#B9A77D'),edge=H('#5A3A1C'))
def c_panel():
    im=frame(24,24,C['fill'],C['hi'],C['lo'],chamfer=4,border=C['edge'])
    d=ImageDraw.Draw(im); d.rectangle((4,4,19,19),outline=C['lo']); return im
def c_button(pressed=False):
    f,hi,lo=(H('#6E8F3E'),H('#9CBF62'),H('#3F5A1E')) if not pressed else (H('#5C7B33'),H('#6E8F3E'),H('#5C7B33'))
    return frame(24,16,f,hi,lo,chamfer=3,border=H('#2A3A14'))
def c_corner():
    im=new(12,12); d=ImageDraw.Draw(im); e=C['edge']
    d.line([(0,0),(9,0)],fill=e); d.line([(0,0),(0,9)],fill=e); d.line([(1,1),(6,1)],fill=C['lo']); d.line([(1,1),(1,6)],fill=C['lo'])
    for x,y in ((7,1),(8,2),(1,7),(2,8)): d.point((x,y),fill=e)
    d.rectangle((2,2,3,3),fill=H('#B5601C')); return im
def c_texture():
    random.seed(9); im=Image.new('RGBA',(16,16),C['fill']); d=ImageDraw.Draw(im)
    for _ in range(14): d.point((random.randrange(16),random.randrange(16)),fill=C['lo'] if random.random()<.6 else C['hi'])
    return im
# ---------------- environment accents for direction A: corner 12x12 + stitch tint ----------------
def env_city():
    im=new(12,12); d=ImageDraw.Draw(im); k=H('#C9A25A')
    d.rectangle((1,5,10,10),fill=INK); d.rectangle((2,6,9,9),fill=H('#7A6A55')); 
    for x in (1,4,7,10): d.rectangle((x,2,x+1,5),fill=INK); d.rectangle((x,3,x,4),fill=H('#A89880'))
    d.rectangle((5,7,6,9),fill=INK); return im
def env_wilds():
    im=new(12,12); d=ImageDraw.Draw(im); g=H('#5E9A3A')
    for pts in (((1,9),(2,5),(5,2),(6,5),(3,8)),((5,10),(6,6),(9,3),(10,7),(7,9))): d.polygon(pts,fill=g,outline=INK)
    d.line([(2,8),(5,4)],fill=H('#2E5A1C')); d.line([(6,9),(9,5)],fill=H('#2E5A1C')); return im
def env_coast():
    im=new(12,12); d=ImageDraw.Draw(im); t=H('#4FB0B0')
    for y,off in ((3,0),(6,1),(9,0)):
        pts=[(0,y+((x+off)//2)%2) for x in range(0,12)]
        pts=[(x,y+(1 if ((x+off)//2)%2 else 0)) for x in range(12)]
        d.line(pts,fill=INK); d.line([(x,yy+1) for x,yy in pts],fill=t)
    return im
def env_ash():
    im=new(12,12); d=ImageDraw.Draw(im)
    d.polygon([(6,0),(8,3),(10,6),(10,8),(8,11),(4,11),(2,8),(2,6),(4,3)],fill=H('#E0762B'),outline=INK); d.polygon([(6,5),(8,7),(7,10),(5,10),(4,7)],fill=H('#F2C14E')); return im
def env_frost():
    im=new(12,12); d=ImageDraw.Draw(im); c=H('#CFE6F2')
    for a,b in (((6,0),(6,11)),((0,6),(11,6)),((1,1),(10,10)),((10,1),(1,10))): d.line([a,b],fill=INK,width=3)
    for a,b in (((6,1),(6,10)),((1,6),(10,6)),((2,2),(9,9)),((9,2),(2,9))): d.line([a,b],fill=c)
    d.point((6,6),fill=CREAM); return im
def env_sacred():
    im=new(12,12); d=ImageDraw.Draw(im)
    d.polygon([(6,0),(8,4),(12,6),(8,8),(6,12),(4,8),(0,6),(4,4)],fill=H('#F2C14E'),outline=INK); d.rectangle((5,5,6,6),fill=CREAM); return im
ENV={'city':(env_city,H('#C9A25A')),'wilds':(env_wilds,H('#7DBE6A')),'coast':(env_coast,H('#4FB0B0')),'ash':(env_ash,H('#E0762B')),'frost':(env_frost,H('#CFE6F2')),'sacred_void':(env_sacred,H('#A987EA'))}
def stretch(im,w,h,m):
    """9-slice a source image to w x h with margin m (nearest, edges repeated)"""
    s=im.size; out=new(w,h)
    xs=[(0,m,0,m),(m,s[0]-m,m,w-m),(s[0]-m,s[0],w-m,w)]; ys=[(0,m,0,m),(m,s[1]-m,m,h-m),(s[1]-m,s[1],h-m,h)]
    for sx0,sx1,dx0,dx1 in xs:
        for sy0,sy1,dy0,dy1 in ys:
            piece=im.crop((sx0,sy0,sx1,sy1)).resize((dx1-dx0,dy1-dy0),Image.NEAREST); out.alpha_composite(piece,(dx0,dy0))
    return out
if __name__=='__main__':
    for sub in ('A_leather','B_iron','C_bone','env'): os.makedirs(O+sub,exist_ok=True)
    kits={'A_leather':(a_panel,a_button,a_corner,a_texture),'B_iron':(b_panel,b_button,b_corner,b_texture),'C_bone':(c_panel,c_button,c_corner,c_texture)}
    for k,(p,b,c,t) in kits.items():
        p().save(f'{O}{k}/panel.png'); b(False).save(f'{O}{k}/button.png'); b(True).save(f'{O}{k}/button_pressed.png'); c().save(f'{O}{k}/corner.png'); t().save(f'{O}{k}/texture.png')
    for k,(fn,tint) in ENV.items():
        fn().save(f'{O}env/corner_{k}.png'); a_panel(tint).save(f'{O}env/panel_{k}.png')
    json.dump({'panel':{'size':[24,24],'slice':8},'button':{'size':[24,16],'slice':6},'corner':[12,12],'texture':[16,16],'env':list(ENV)},open(O+'nine_slice.json','w'),indent=1)
    LIGHT=(233,224,201); DARK=(31,28,35)
    def tile(t,w,h):
        o=Image.new('RGBA',(w,h)); 
        for y in range(0,h,16):
            for x in range(0,w,16): o.paste(t,(x,y))
        return o
    def kit_row(sh,x,y,k,bg):
        p=Image.open(f'{O}{k}/panel.png'); b=Image.open(f'{O}{k}/button.png'); bp=Image.open(f'{O}{k}/button_pressed.png'); c=Image.open(f'{O}{k}/corner.png'); t=Image.open(f'{O}{k}/texture.png')
        pan=stretch(p,72,56,8); sh.paste(pan,(x,y),pan)
        for i,im in enumerate((b,bp)):
            s=stretch(im,56,20,6); sh.paste(s,(x+80,y+i*26),s)
        sh.paste(c,(x+142,y),c); tx=tile(t,32,32); sh.paste(tx,(x+142,y+16))
    sc=3
    sh=Image.new('RGB',(2*(300+10),3*(70+10)+(6*70)+120),LIGHT); d=ImageDraw.Draw(sh)
    # real-size row and 3x row for each kit on light and dark
    big=Image.new('RGB',(2*330,3*(60*sc)+20+ 3*30),LIGHT)
    sheet=Image.new('RGB',(2*340,3*(64*sc+40)+70*sc+120),LIGHT); d=ImageDraw.Draw(sheet)
    for half,bg in enumerate((LIGHT,DARK)):
        x0=half*340; d.rectangle((x0,0,x0+339,sheet.height),fill=bg); y=8
        for k in kits:
            d.text((x0+8,y),k+' (real size, then 1.7x)',fill=(35,31,26) if half==0 else (233,224,201)); y+=14
            row=Image.new('RGBA',(190,64),(0,0,0,0)); kit_row_im=Image.new('RGBA',(190,64),(0,0,0,0))
            tmp=Image.new('RGB',(190,64),bg); kit_row(tmp,0,2,k,bg); sheet.paste(tmp,(x0+8,y)); 
            sheet.paste(tmp.resize((190*sc if 190*sc<320 else 320,64*sc),Image.NEAREST),(x0+8,y+70)) if False else None
            sheet.paste(tmp.resize((190*sc//2*2//2*1,64*sc//1)) if False else tmp.resize((int(190*1.7),int(64*1.7)),Image.NEAREST),(x0+8,y+68)); y+=68+110+14
        d.text((x0+8,y),'environment accents on direction A (stitch tint + corner), real size and 4x on the second panel',fill=(35,31,26) if half==0 else (233,224,201)); y+=16
        for i,(k,(fn,tint)) in enumerate(ENV.items()):
            p=Image.open(f'{O}env/panel_{k}.png'); cc=Image.open(f'{O}env/corner_{k}.png'); s=stretch(p,48,40,8)
            s.alpha_composite(cc,(4,4)); xx=x0+8+(i%3)*108; yy=y+(i//3)*120
            sheet.paste(s.resize((96,80),Image.NEAREST),(xx,yy),s.resize((96,80),Image.NEAREST)); sheet.paste(s,(xx+4,yy+84),s); d.text((xx,yy+104),k,fill=(110,102,90))
    sheet=sheet.crop((0,0,sheet.width,y+260)); sheet.save('docs/art/boards/chibi-frame-kits.png'); print(sheet.size)
