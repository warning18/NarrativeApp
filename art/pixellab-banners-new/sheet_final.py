"""Remap the final banners to Apollo + 2 core brights and build the sheet: today | final (Apollo), 3x on the dark Tower background, game size on dark and parchment.
python3 art/pixellab-banners-new/sheet_final.py <sheet.png> id1,id2,...   (ids = file stems, e.g. clan_dominion or heirloom_shroud)"""
import sys, os; sys.path.insert(0,'tool')
from apollo_remap import remap, PALETTES
import numpy as np
from PIL import Image, ImageDraw, ImageFont
def banner_remap(im):
    """Apollo + 2 brights, banner rules: the cream emblem stays one tone family (FFF6E0 main, E7D5B3 shade, D7B594 deep), the dark cloth folds go to the cool near-blacks (10141F, 151D28, 202E37) and the ink to 090A14; everything else nearest colour."""
    base=remap(im,pal='apollo+cores'); a=np.array(im.convert('RGBA')); o=np.array(base)
    H=lambda h:[int(h[i:i+2],16) for i in (0,2,4)]
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            p=a[y,x]
            if not p[3]: continue
            lum=.299*p[0]+.587*p[1]+.114*p[2]; sat=int(max(p[:3]))-int(min(p[:3]))
            if p[0]>=190 and p[1]>=170 and p[2]>=130 and sat<=70: o[y,x,:3]=H('FFF6E0') if lum>=226 else H('E7D5B3') if lum>=190 else H('D7B594')
            elif lum<56 and sat<=28: o[y,x,:3]=H('090A14') if lum<14 else H('10141F') if lum<24 else H('151D28') if lum<34 else H('202E37')
    return __import__('PIL.Image',fromlist=['Image']).fromarray(o,'RGBA')
R='art/pixellab-banners-new/'; out=sys.argv[1]; ids=sys.argv[2].split(',')
os.makedirs(R+'apollo',exist_ok=True)
F=ImageFont.load_default(size=12); DARK=(31,28,35); PARCH=(228,215,182)
pairs=[]
for i in ids:
    today=Image.open(f'assets/visuals/banners/{i}.png').convert('RGBA'); fin=Image.open(f'{R}final/{i}.png').convert('RGBA'); ap=banner_remap(fin); ap.save(f'{R}apollo/{i}.png'); pairs.append((i,today,ap))
per=5 if len(ids)>5 else len(ids); S=3; cw=2*(64*S)+30; rows=(len(ids)+per-1)//per
rh=128*S+34+2*(128+8)+26
sh=Image.new('RGB',(per*cw+10,rows*rh+10),DARK); d=ImageDraw.Draw(sh)
for n,(i,t,a) in enumerate(pairs):
    cx=10+(n%per)*cw; cy=6+(n//per)*rh
    d.text((cx,cy),i.replace('clan_',''),font=F,fill=(233,224,201))
    for j,im in enumerate((t,a)):
        b=im.resize((64*S,128*S),Image.NEAREST); sh.paste(b,(cx+j*(64*S+6),cy+16),b)
    y=cy+16+128*S+8
    for bg in (DARK,PARCH):
        d.rectangle((cx-4,y-2,cx+2*64+14,y+130),fill=bg)
        for j,im in enumerate((t,a)): sh.paste(im,(cx+j*72,y),im)
        y+=136
sh.save(out); print(sh.size)
