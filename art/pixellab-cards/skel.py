"""Code skeletons for the tiered card pieces (art px, 1 art px = 2 dp). Card 104x172, plate 40x40, art-zone backdrop 104x76.
Tiers: common iron, uncommon bronze, rare silver with a gem. PixelLab redraws them (img2img) in its own style."""
from PIL import Image, ImageDraw
H=lambda s:tuple(int(s[i:i+2],16) for i in (0,2,4))+(255,)
INK=H('090A14'); KEY=H('FF00FF')
METAL={'common':[H('202E37'),H('394A50'),H('577277'),H('819796')],      # iron: dark, mid, light, highlight
       'uncommon':[H('602C2C'),H('884B2B'),H('BE772B'),H('E8C170')],    # bronze
       'rare':[H('394A50'),H('819796'),H('C7CFCC'),H('EBEDE9')],
       'epic':[H('884B2B'),H('DE9E41'),H('E8C170'),H('F2C14E')],        # gilded
       'legendary':[H('BE772B'),H('F2C14E'),H('FFF6E0'),H('FFF6E0')]}   # bright gold        # silver
def frame(tier,W=104,Hh=172,b=6):
    d,mid,lt,hi=METAL[tier]; im=Image.new('RGBA',(W,Hh),KEY); g=ImageDraw.Draw(im)
    g.rectangle([0,0,W-1,Hh-1],fill=INK); g.rectangle([1,1,W-2,Hh-2],fill=mid)
    g.rectangle([1,1,W-2,2],fill=lt); g.rectangle([1,1,2,Hh-2],fill=lt)           # lit top and left
    g.rectangle([W-3,1,W-2,Hh-2],fill=d); g.rectangle([1,Hh-3,W-2,Hh-2],fill=d)
    g.rectangle([b-1,b-1,W-b,Hh-b],fill=INK); g.rectangle([b,b,W-b-1,Hh-b-1],fill=KEY)
    for x,y in [(0,0),(W-1,0),(0,Hh-1),(W-1,Hh-1)]: g.point((x,y),fill=KEY)       # stepped outer corners
    if tier!='common':
        for cx,cy in [(7,7),(W-8,7),(7,Hh-8),(W-8,Hh-8)]:                          # corner studs
            g.rectangle([cx-3,cy-3,cx+3,cy+3],fill=INK); g.rectangle([cx-2,cy-2,cx+2,cy+2],fill=lt); g.point((cx-1,cy-1),fill=hi)
    if tier=='epic':
        for cx,cy in [(W//2,4),(W//2,Hh-5)]:
            g.polygon([(cx,cy-6),(cx+5,cy),(cx,cy+6),(cx-5,cy)],fill=INK); g.polygon([(cx,cy-4),(cx+3,cy),(cx,cy+4),(cx-3,cy)],fill=H('A23E8C')); g.point((cx-1,cy-1),fill=H('DF84A5'))
        for y in (40,Hh-41): g.rectangle([0,y,2,y+8],fill=lt); g.rectangle([W-3,y,W-1,y+8],fill=d)
    if tier=='legendary':
        cx=W//2
        for dx,hgt in ((-9,4),(-5,7),(0,10),(5,7),(9,4)): g.rectangle([cx+dx-1,0,cx+dx+1,hgt],fill=H('FFF6E0'))
        g.polygon([(cx,0),(cx+7,6),(cx,12),(cx-7,6)],fill=INK); g.polygon([(cx,2),(cx+5,6),(cx,10),(cx-5,6)],fill=H('F2C14E'))
        for y in (28,Hh-37): g.rectangle([0,y,2,y+8],fill=hi); g.rectangle([W-3,y,W-1,y+8],fill=hi)
    if tier=='rare':
        cx=W//2; g.polygon([(cx,0),(cx+6,5),(cx,11),(cx-6,5)],fill=INK); g.polygon([(cx,2),(cx+4,5),(cx,9),(cx-4,5)],fill=H('73BED3')); g.point((cx-1,4),fill=H('EBEDE9'))
        for y in (40,Hh-41): g.rectangle([0,y,2,y+8],fill=hi); g.rectangle([W-3,y,W-1,y+8],fill=d)
    return im
def plate(tier,S=40):
    d,mid,lt,hi=METAL[tier]; im=Image.new('RGBA',(S,S),(0,0,0,0)); g=ImageDraw.Draw(im)
    g.rounded_rectangle([0,0,S-1,S-1],4,fill=INK); g.rounded_rectangle([1,1,S-2,S-2],4,fill=mid)
    g.rectangle([3,3,S-4,S-4],fill=INK); g.rectangle([4,4,S-5,S-5],fill=H('151D28'))
    g.line([(2,2),(S-3,2)],fill=lt); g.line([(2,2),(2,S-3)],fill=lt)
    if tier!='common':
        for x,y in [(2,2),(S-3,2),(2,S-3),(S-3,S-3)]: g.rectangle([x-1,y-1,x+1,y+1],fill=hi)
    if tier in('epic','legendary'):
        for x,y in [(S//2,1),(S//2,S-2),(1,S//2),(S-2,S//2)]: g.polygon([(x,y-2),(x+2,y),(x,y+2),(x-2,y)],fill=H('A23E8C') if tier=='epic' else H('FFF6E0'),outline=INK)
    if tier=='rare':
        for x,y in [(S//2,1),(S//2,S-2),(1,S//2),(S-2,S//2)]: g.polygon([(x,y-2),(x+2,y),(x,y+2),(x-2,y)],fill=H('73BED3'),outline=INK)
    return im
def backdrop(tier,W=104,Hh=76):
    im=Image.new('RGBA',(W,Hh),H('151D28')); g=ImageDraw.Draw(im)
    for y in range(Hh): g.line([(0,y),(W,y)],fill=tuple(int(a+(b-a)*y/Hh) for a,b in zip(H('202E37')[:3],H('10141F')[:3]))+(255,))
    if tier=='uncommon':
        for x in range(4,W,8): g.point((x,4),fill=H('884B2B')); g.point((x,Hh-5),fill=H('884B2B'))
        g.ellipse([22,6,82,70],outline=H('602C2C'))
    if tier=='epic':
        g.ellipse([14,0,90,76],fill=H('402751')); g.ellipse([30,12,74,64],fill=H('7A367B'))
        for x,y in [(14,14),(90,24),(20,58),(88,60)]: g.point((x,y),fill=H('DF84A5')); g.point((x+1,y),fill=H('C65197'))
    if tier=='legendary':
        g.ellipse([20,2,84,74],outline=H('F2C14E'),width=3); g.ellipse([26,8,78,68],outline=H('884B2B'))
        for x,y in [(12,14),(92,18),(16,60),(90,58),(52,3)]: g.point((x,y),fill=H('FFF6E0')); g.point((x+1,y),fill=H('F2C14E')); g.point((x,y+1),fill=H('F2C14E'))
    if tier=='rare':
        g.polygon([(52,0),(30,Hh),(74,Hh)],fill=H('253A5E'))
        for x,y in [(14,12),(88,20),(20,56),(92,60),(50,8)]: g.point((x,y),fill=H('EBEDE9')); g.point((x+1,y),fill=H('A4DDDB')); g.point((x,y+1),fill=H('A4DDDB'))
    return im
if __name__=='__main__':
    for t in METAL:
        frame(t).save(f'art/pixellab-cards/skel/frame_{t}.png'); plate(t).save(f'art/pixellab-cards/skel/plate_{t}.png'); backdrop(t).save(f'art/pixellab-cards/skel/backdrop_{t}.png')
    from PIL import Image as I
    W=I.new('RGBA',(3*(104*2+10)+10,172*2+16),(60,70,60))
    for k,t in enumerate(METAL):
        f=frame(t).resize((208,344),0);W.paste(f,(10+k*218,8),f)
    W.save('art/pixellab-cards/skel/sheet.png')
