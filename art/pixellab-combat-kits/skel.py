"""Code skeletons for the combat-screen kits (stage strip, table, card frame, nine-slice panel, slot, kit card), in two palettes.
python3 art/pixellab-combat-kits/skel.py"""
import io, urllib.request, zipfile
from PIL import Image, ImageDraw
H=lambda s:tuple(int(s[i:i+2],16) for i in (0,2,4))+(255,)
INK=H('090A14')
PAL={'apollo':dict(d=H('151D28'),m=H('202E37'),l=H('394A50'),hi=H('819796'),fl=H('253A5E'),w1=H('602C2C'),w2=H('884B2B'),w3=H('AD7757'),acc=H('73BED3')),
     'b':dict(d=H('151D28'),m=H('202E37'),l=H('394A50'),hi=H('EBEDE9'),fl=H('202E37'),w1=H('202E37'),w2=H('394A50'),w3=H('8B9BA0'),acc=H('A53030'))}
def stage(p,W=180,Hh=100):
    c=PAL[p];im=Image.new('RGBA',(W,Hh),c['w1']);g=ImageDraw.Draw(im)
    for y in range(0,40):                                   # the ground the fighters stand on, lit from the top left
        g.line([(0,y),(W,y)],fill=c['w2'] if (y//5)%2==0 else c['w1'])
    for x in range(0,W,22): g.line([(x,0),(x-8,40)],fill=c['w3'])
    g.rectangle([0,40,W,44],fill=INK); g.rectangle([0,41,W,42],fill=c['hi'])   # the ledge into the tray
    g.rectangle([0,45,W,Hh],fill=c['d'])
    for y in range(50,Hh,10): g.line([(0,y),(W,y)],fill=c['m'])
    g.rectangle([6,50,W-7,Hh-3],outline=c['l'])
    return im
def table(p,W=180,Hh=100):
    c=PAL[p];im=Image.new('RGBA',(W,Hh),INK);g=ImageDraw.Draw(im)
    g.rectangle([1,1,W-2,Hh-2],fill=c['w2']); g.rectangle([1,1,W-2,2],fill=c['w3']); g.rectangle([1,1,2,Hh-2],fill=c['w3'])
    g.rectangle([8,8,W-9,Hh-9],fill=INK); g.rectangle([9,9,W-10,Hh-10],fill=c['fl'])
    g.ellipse([W//2-34,Hh//2-30,W//2+34,Hh//2+30],outline=c['l'],width=2)
    return im
def cardframe(p,W=56,Hh=80,studs=False):
    c=PAL[p];im=Image.new('RGBA',(W,Hh),(0,0,0,0));g=ImageDraw.Draw(im)
    g.rectangle([0,0,W-1,Hh-1],fill=INK);g.rectangle([1,1,W-2,Hh-2],fill=c['l']);g.rectangle([1,1,W-2,2],fill=c['hi']);g.rectangle([1,1,2,Hh-2],fill=c['hi'])
    g.rectangle([4,4,W-5,Hh-5],fill=INK);g.rectangle([5,5,W-6,Hh-6],fill=c['d'])
    for x,y in [(0,0),(W-1,0),(0,Hh-1),(W-1,Hh-1)]: g.point((x,y),fill=(0,0,0,0))
    if studs:
        for cx,cy in [(4,4),(W-5,4),(4,Hh-5),(W-5,Hh-5)]: g.rectangle([cx-1,cy-1,cx+1,cy+1],fill=c['acc'])
    return im
def panel(p,S=48):
    im=cardframe(p,S,S,True);return im
def slot(p,S=32):
    c=PAL[p];im=Image.new('RGBA',(S,S),(0,0,0,0));g=ImageDraw.Draw(im)
    g.rectangle([0,0,S-1,S-1],fill=INK);g.rectangle([1,1,S-2,S-2],fill=c['m']);g.rectangle([2,2,S-3,S-3],fill=INK);g.rectangle([3,3,S-4,S-4],fill=c['d'])
    g.line([(S-3,3),(S-3,S-3)],fill=c['l']);g.line([(3,S-3),(S-3,S-3)],fill=c['l'])
    return im
def starter_hero():
    hid='de5e44f4-1c9d-4043-96cf-eed8d324a086'
    z=zipfile.ZipFile(io.BytesIO(urllib.request.urlopen(f'https://api.pixellab.ai/mcp/characters/{hid}/download?states={hid}').read()))
    nm=[x for x in z.namelist() if x.endswith('rotations/east.png')][0]; return Image.open(io.BytesIO(z.read(nm))).convert('RGBA')
if __name__=='__main__':
    for p in PAL:
        stage(p).save(f'art/pixellab-combat-kits/skel/{p}_stage.png');table(p).save(f'art/pixellab-combat-kits/skel/{p}_table.png')
        cardframe(p).save(f'art/pixellab-combat-kits/skel/{p}_cardframe.png');panel(p).save(f'art/pixellab-combat-kits/skel/{p}_panel.png')
        slot(p).save(f'art/pixellab-combat-kits/skel/{p}_slot.png');cardframe(p,studs=True).save(f'art/pixellab-combat-kits/skel/{p}_kitcard.png')
    starter_hero().save('art/pixellab-combat-kits/skel/hero.png')
    Image.open('assets/visuals/fighters/inquisition_warden_idle_west.png').convert('RGBA').save('art/pixellab-combat-kits/skel/foe.png')
