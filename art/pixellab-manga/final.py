"""Token pass on the manga test + sheet. python3 art/pixellab-manga/final.py"""
import sys,numpy as np,os
sys.path.insert(0,'art/pixellab-cutpaper'); from simplify import simplify
from PIL import Image,ImageDraw
INK=(9,10,20);PAPER=(231,225,205);SH=(201,194,166);RED=(165,48,48)
K='antidote dagger key helm boots shield'.split();os.makedirs('art/pixellab-manga/final',exist_ok=True)
def tok(im,tone):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>40;rgb=a[...,:3]
    mx=rgb.max(2);mn=rgb.min(2);red=al&((rgb[...,0]-np.maximum(rgb[...,1],rgb[...,2]))>45)
    L=rgb@np.array([.3,.59,.11]);o=np.zeros_like(a);o[...,3]=al*255
    o[...,:3]=np.where((L<95)[...,None],INK,np.where((L<175)[...,None]&tone,SH,PAPER))
    o[red,:3]=RED
    pad=np.pad(al,1);edge=al&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:])
    o[edge&~red,:3]=INK   # the silhouette edge is always the ink contour (white blades vanish otherwise)
    out=Image.fromarray(o.astype(np.uint8),'RGBA');return simplify(out,2)
cell=96;W=Image.new('RGBA',(3*(6*(cell+6))+300,2*(cell+6)+40+130),(26,28,38,255));g=ImageDraw.Draw(W)
for vi,v in enumerate('ABC'):
    for i,k in enumerate(K):
        t=tok(Image.open(f'art/pixellab-manga/raw32/{v}_{k}/get_image_0.png'),v=='C');t.save(f'art/pixellab-manga/final/{v}_{k}32.png')
        bg=Image.new('RGBA',(32,32),PAPER+(255,));bg.alpha_composite(t)
        x=8+vi*(6*(cell+6)+8)+i*(cell+6);W.alpha_composite(bg.resize((cell,cell),Image.NEAREST),(x,22));W.alpha_composite(bg,(x,22+cell+6))
    g.text((8+vi*(6*(cell+6)+8),6),f'{v}: '+{'A':'clean pen line, no tone','B':'brush line, solid black shadows','C':'pen line, one flat tone area'}[v],fill=(235,237,233))
# Tower plate and design-A card approximation (cream card, black frame, name line) with the B dagger for scale
y=22+cell+6+32+14
plate=Image.open('art/pixellab-cutpaper/tower/handoff/tower_1.png') if os.path.exists('art/pixellab-cutpaper/tower/handoff/tower_1.png') else None
if plate is None:
    import glob;plate=Image.open(sorted(glob.glob('art/pixellab-cutpaper/tower/handoff/*.png'))[0])
plate=plate.convert('RGBA');W.alpha_composite(plate.resize((90,160),Image.NEAREST),(8,y))
for ci,v in enumerate('ABC'):
    cx=110+ci*140;card=Image.new('RGBA',(128,170),PAPER+(255,));d=ImageDraw.Draw(card)
    d.rectangle((0,0,127,169),outline=INK,width=3);d.rectangle((8,8,119,28),outline=INK);d.text((14,12),'Dagger',fill=INK)
    ic=Image.open(f'art/pixellab-manga/final/{v}_dagger32.png');card.alpha_composite(ic.resize((96,96),Image.NEAREST),(16,40));d.line((16,150,112,150),fill=INK)
    W.alpha_composite(card,(cx,y-5));g.text((cx,y+168),f'card, {v} dagger at 3x',fill=(150,150,170))
W.crop((0,0,W.width,y+185)).save('docs/art/boards/icons-manga-test.png')
