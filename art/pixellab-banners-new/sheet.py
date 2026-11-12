"""Stage the pilot (a = s9 at strength 100, b = s7) and build docs/art/boards/banners-new-style-pilot.png. python3 art/pixellab-banners-new/sheet.py"""
import sys; sys.path.insert(0,'tool')
from apollo_remap import remap
from PIL import Image, ImageDraw, ImageFont
R='art/pixellab-banners-new/'; ks=['dominion','oni','crows','mire']; PICK={'a':9,'b':7}
F=ImageFont.load_default(size=13); FS=ImageFont.load_default(size=11)
VER=[('today',None)]+[(v,v) for v in 'ab']
def load(k,v):
    if v is None: return Image.open(f'assets/visuals/banners/clan_{k}.png').convert('RGBA')
    im=Image.open(f'{R}raw/clan_{k}_{v}_s{PICK[v]}/get_image_0.png').convert('RGBA'); im.save(f'{R}staged/clan_{k}_{v}.png'); return im
IM={(k,v):load(k,v) for k in ks for _,v in VER}
PALS=[('own colours',None),('Apollo + 2 brights','apollo+cores'),('muted palette','muted')]
def get(k,v,p): im=IM[(k,v)]; return im if p is None else remap(im,pal=p)
DARK=(31,28,35); PARCH=(228,215,182); cols=[(k,v) for k in ks for _,v in VER]
S=3; cw=64*S+10; W=len(cols)*cw+110
H=30+len(PALS)*(128*S+22)+30+len(PALS)*2*(128+10)+30
sh=Image.new('RGB',(W,H),DARK); d=ImageDraw.Draw(sh); y=6
d.text((6,y),'3x on the dark Tower background; per clan: today | (a) faithful redraw | (b) bolder (iron rod, torn weighted hem, stitched emblem)',font=F,fill=(233,224,201)); y+=22
for lab,p in PALS:
    d.text((6,y+150),lab,font=FS,fill=(233,224,201))
    for i,(k,v) in enumerate(cols):
        a=get(k,v,p).resize((64*S,128*S),Image.NEAREST); sh.paste(a,(110+i*cw,y),a)
    y+=128*S+6
y+=10
d.text((6,y),'game size (64x128), dark Tower | parchment panel',font=F,fill=(233,224,201)); y+=22
for lab,p in PALS:
    for bi,bg in enumerate((DARK,PARCH)):
        d.rectangle((105,y-4,W,y+128+4),fill=bg)
        if bi==0: d.text((6,y+60),lab,font=FS,fill=(233,224,201))
        for i,(k,v) in enumerate(cols):
            a=get(k,v,p); sh.paste(a,(110+i*cw,y),a)
        y+=128+10
sh.crop((0,0,W,y+4)).save('docs/art/boards/banners-new-style-pilot.png'); print(sh.size)
