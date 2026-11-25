"""Extended chibi object palette (user 25 Nov: more colour, same smooth range). Ramps are shadow/base/light; hero ramps first."""
import numpy as np
H=lambda s:tuple(int(s[i:i+2],16) for i in (0,2,4))
RAMPS={ # name: (shadow, base, light)
 'leather':('544443','6F5A4C','8F7665'),'stone':('3B4043','8D8278','B8ACA1'),'linen':('B6A48F','E1D7C0','FDFCFC'),'skin':('C9936F','EBBB9F','F6D8C2'),
 'copper':('A8582E','E99253','F5BE8C'),
 'moss':('3F5E3A','6E9A55','A8C888'),'heal':('3D7A2C','7DBE6A','B6E0A0'),
 'teal':('2F5A60','4F8E92','8EC4C0'),'blue':('38486E','5F78A8','9AB0D4'),
 'red':('7A2E2A','B8493D','E08A78'),'ochre':('8A6A22','C99A3A','EFCB78'),'violet':('3E1F4A','5E2D66','9A6BA0'),
}
FIXED=['010000','23252A']   # outline, night
PAL=[H(x) for x in FIXED]+[H(c) for r in RAMPS.values() for c in r]
def swatch(path):
    from PIL import Image,ImageDraw
    im=Image.new('RGB',(len(RAMPS)*34+8,3*30+60),(26,28,38));g=ImageDraw.Draw(im);g.text((6,2),'extended chibi object palette: shadow / base / light per ramp',fill=(235,237,233))
    for i,(n,r) in enumerate(RAMPS.items()):
        for j,c in enumerate(r): g.rectangle((6+i*34,18+j*30,6+i*34+30,18+j*30+26),fill=H(c))
        g.text((6+i*34,18+3*30+2),n[:6],fill=(150,150,170));g.text((6+i*34,18+3*30+14),r[1],fill=(150,150,170))
    im.save(path)
def forced(path):
    from PIL import Image
    n=len(PAL);im=Image.new('RGB',(n*4,4))
    for i,c in enumerate(PAL):
        for x in range(4):
            for y in range(4): im.putpixel((i*4+x,y),c)
    im.save(path)
if __name__=='__main__':
    swatch('docs/art/boards/chibi-palette-extended.png');forced('art/pixellab-icons-v2/palette_forced.png');print(len(PAL),'colours')
