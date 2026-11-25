"""Darker extended chibi palette (user 25 Nov: darker chibi, grim dark-fantasy mood, desaturated, deep shadows). Same hues as palette.py, saturation x0.7, value x0.8 (shadows x0.65), plus two deep tones."""
import colorsys
from palette import RAMPS,H
def dark(hexc,ks,kv):
    r,g,b=[v/255 for v in H(hexc)];h,s,v=colorsys.rgb_to_hsv(r,g,b);r,g,b=colorsys.hsv_to_rgb(h,s*ks,v*kv);return '%02X%02X%02X'%(round(r*255),round(g*255),round(b*255))
DRAMPS={n:(dark(r[0],.72,.62),dark(r[1],.7,.8),dark(r[2],.72,.9)) for n,r in RAMPS.items()}
FIXED=['010000','0E0F14','1A1B22']
PAL=[H(x) for x in FIXED]+[H(c) for r in DRAMPS.values() for c in r]
def swatch(path):
    from PIL import Image,ImageDraw
    im=Image.new('RGB',(len(DRAMPS)*34+8,3*30+60),(26,28,38));g=ImageDraw.Draw(im);g.text((6,2),'darker chibi palette: shadow / base / light',fill=(235,237,233))
    for i,(n,r) in enumerate(DRAMPS.items()):
        for j,c in enumerate(r): g.rectangle((6+i*34,18+j*30,6+i*34+30,18+j*30+26),fill=H(c))
        g.text((6+i*34,18+3*30+2),n[:6],fill=(150,150,170));g.text((6+i*34,18+3*30+14),r[1],fill=(150,150,170))
    im.save(path)
def forced(path):
    from PIL import Image
    im=Image.new('RGB',(len(PAL)*4,4))
    for i,c in enumerate(PAL):
        for x in range(4):
            for y in range(4): im.putpixel((i*4+x,y),c)
    im.save(path)
if __name__=='__main__':
    swatch('docs/art/boards/chibi-palette-dark.png');forced('art/pixellab-icons-v2/palette_dark_forced.png');print(len(PAL))
