import sys,os,glob,numpy as np
sys.path.insert(0,'art/pixellab-cutpaper');sys.path.insert(0,'art/pixellab-manga')
from simplify import simplify
from PIL import Image,ImageDraw
INK=(9,10,20);PAPER=(231,225,205);RED=(165,48,48)
K='antidote dagger key helm boots shield'.split();os.makedirs('art/pixellab-manga/chibi_final',exist_ok=True)
def tok(im):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>40;rgb=a[...,:3]
    red=al&((rgb[...,0]-np.maximum(rgb[...,1],rgb[...,2]))>45);L=rgb@np.array([.3,.59,.11])
    o=np.zeros_like(a);o[...,3]=al*255;o[...,:3]=np.where((L<95)[...,None],INK,PAPER);o[red,:3]=RED
    pad=np.pad(al,1);edge=al&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:]);o[edge&~red,:3]=INK
    return simplify(Image.fromarray(o.astype(np.uint8),'RGBA'),2)
def get(v,k):
    im=Image.open(f'art/pixellab-manga/chibi/{v}_{k}/get_image_0.png').convert('RGBA')
    return Image.open(f'art/pixellab-manga/chibi_final/V1b_{k}32.png').convert('RGBA') if v=='V1' else simplify(im,2)  # V1 = V1b: ink look derived in code from the V2 shapes (the generated V1 came out as tiny characters)
cell=96;G=8;W=Image.new('RGBA',(2*(6*(cell+6))+60+330,2*(cell+6)+40+190),(26,28,38,255));g=ImageDraw.Draw(W)
for vi,v in enumerate(('V1','V2')):
    for i,k in enumerate(K):
        t=get(v,k);t.save(f'art/pixellab-manga/chibi_final/{v}_{k}32.png')
        bg=Image.new('RGBA',(32,32),PAPER+(255,));bg.alpha_composite(t)
        x=8+vi*(6*(cell+6)+20)+i*(cell+6);W.alpha_composite(bg.resize((cell,cell),Image.NEAREST),(x,22));W.alpha_composite(bg,(x,22+cell+6))
    g.text((8+vi*(6*(cell+6)+20),6),{'V1':'V1 chibi ink (from the V2 shapes, code)','V2':'V2 chibi colour (hero palette)'}[v],fill=(235,237,233))
hero=Image.open('art/pixellab-combat-kits/skel/hero.png').convert('RGBA');bgh=Image.new('RGBA',hero.size,PAPER+(255,));bgh.alpha_composite(hero)
x0=8+2*(6*(cell+6)+20);W.alpha_composite(bgh.resize((144,144),Image.NEAREST),(x0,22));g.text((x0,170),'chibi hero (reference), 3x',fill=(150,150,170))
y=22+cell+6+32+14
plate=Image.open(sorted(glob.glob('art/pixellab-cutpaper/tower/handoff/*.png'))[0]).convert('RGBA');W.alpha_composite(plate.resize((90,160),Image.NEAREST),(8,y))
for ci,v in enumerate(('V1','V2')):
    for cj,k in enumerate(('dagger','potion')):
        kk='dagger' if k=='dagger' else 'antidote';cx=110+(ci*2+cj)*140;card=Image.new('RGBA',(128,170),PAPER+(255,));d=ImageDraw.Draw(card)
        d.rectangle((0,0,127,169),outline=INK,width=3);d.rectangle((8,8,119,28),outline=INK);d.text((14,12),kk.capitalize(),fill=INK)
        card.alpha_composite(Image.open(f'art/pixellab-manga/chibi_final/{v}_{kk}32.png').resize((96,96),Image.NEAREST),(16,40));d.line((16,150,112,150),fill=INK)
        W.alpha_composite(card,(cx,y-5));g.text((cx,y+168),f'card, {v} {kk} 3x',fill=(150,150,170))
W.crop((0,0,W.width,y+185)).save('docs/art/boards/icons-chibi-test.png')
