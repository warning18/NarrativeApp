"""Skeletons and 'today' references for the two dark style tests (UX panel, button, plate; the others start from today's assets).
python3 art/pixellab-styles/skel.py"""
from PIL import Image, ImageDraw
H=lambda s:tuple(int(s[i:i+2],16) for i in (0,2,4))+(255,)
INK,D1,D2,M1,L1,HI=H('090A14'),H('151D28'),H('202E37'),H('394A50'),H('577277'),H('819796')
def panel(W=104,Hh=72):
    im=Image.new('RGBA',(W,Hh),(0,0,0,0));g=ImageDraw.Draw(im)
    g.rectangle([0,0,W-1,Hh-1],fill=INK);g.rectangle([1,1,W-2,Hh-2],fill=M1);g.rectangle([3,3,W-4,Hh-4],fill=INK);g.rectangle([4,4,W-5,Hh-5],fill=D2)
    g.line([(1,1),(W-2,1)],fill=L1);g.line([(1,1),(1,Hh-2)],fill=L1)
    for x,y in [(0,0),(W-1,0),(0,Hh-1),(W-1,Hh-1)]: g.point((x,y),fill=(0,0,0,0))
    for cx,cy in [(6,6),(W-7,6),(6,Hh-7),(W-7,Hh-7)]: g.rectangle([cx-2,cy-2,cx+2,cy+2],fill=INK);g.rectangle([cx-1,cy-1,cx+1,cy+1],fill=HI)
    return im
def button(W=64,Hh=24):
    im=Image.new('RGBA',(W,Hh),(0,0,0,0));g=ImageDraw.Draw(im)
    g.rectangle([0,0,W-1,Hh-1],fill=INK);g.rectangle([1,1,W-2,Hh-2],fill=L1);g.rectangle([2,2,W-3,Hh-3],fill=M1);g.rectangle([2,Hh//2,W-3,Hh-3],fill=D2)
    g.line([(1,1),(W-2,1)],fill=HI)
    for x,y in [(0,0),(W-1,0),(0,Hh-1),(W-1,Hh-1)]: g.point((x,y),fill=(0,0,0,0))
    return im
def plate(S=40):
    return Image.open('art/pixellab-cards/skel/plate_common.png').convert('RGBA')
if __name__=='__main__':
    panel().save('art/pixellab-styles/skel/panel.png');button().save('art/pixellab-styles/skel/button.png');plate().save('art/pixellab-styles/skel/plate.png')
    # padded hero and swatches
    h=Image.open('assets/visuals/walker/ronin_idle_east.png').convert('RGBA');c=Image.new('RGBA',(44,48),(0,0,0,0));c.paste(h,(1,1),h);c.save('art/pixellab-styles/skel/hero.png')
    for n,cols in {'style1':'090A14 202E37 394A50 577277 A8B5B2 EBEDE9 A53030 F2C14E','style2':'090A14 151D28 202E37 3C5E8B 577277 884B2B DE9E41 E8C170'}.items():
        s=Image.new('RGB',(len(cols.split())*8,8))
        for i,x in enumerate(cols.split()): s.paste(tuple(int(x[j:j+2],16) for j in (0,2,4)),(i*8,0,i*8+8,8))
        s.save(f'art/pixellab-styles/skel/{n}_pal.png')
