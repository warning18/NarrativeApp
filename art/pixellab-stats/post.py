"""Apollo snap (no region under 2 px) of the 32 px stat symbols, a 24 px version by code, and the sheet. python3 art/pixellab-stats/post.py"""
import sys,json,os,numpy as np
sys.path.insert(0,'art/pixellab-cutpaper')
from PIL import Image,ImageDraw
from simplify import simplify
H=lambda s:tuple(int(s[i:i+2],16) for i in (0,2,4))
PAL=[H(c) for c in '172038 253A5E 3C5E8B 4F8FBA 73BED3 A4DDDB 19332D 25562E 468232 75A743 A8CA58 D0DA91 4D2B32 7A4841 AD7757 C09473 D7B594 E7D5B3 341C27 602C2C 884B2B BE772B DE9E41 E8C170 241527 411D31 752438 A53030 CF573C DA863E 1E1D39 402751 7A367B A23E8C C65197 DF84A5 090A14 10141F 151D28 202E37 394A50 577277 819796 A8B5B2 C7CFCC EBEDE9 F2C14E FFF6E0'.split()]
def snap(im,ink=True):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>40;p=np.array(PAL,float);d=((a[...,None,:3]-p[None,None])**2*np.array([2,4,3])).sum(3);o=np.zeros_like(a);o[...,:3]=p[d.argmin(2)];o[...,3]=al*255
    if ink:
        pad=np.pad(al,1);ed=al&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:]);o[ed,:3]=H('090A14')
    return simplify(Image.fromarray(o.astype(np.uint8),'RGBA'),2)
j=json.load(open('art/pixellab-stats/jobs.json'));os.makedirs('art/pixellab-stats/final',exist_ok=True);ids=['str','dex','con','int','wis','per','luck','cha']
W=Image.new('RGBA',(8*108+10,2*108+70),(26,28,38,255));g=ImageDraw.Draw(W);PAPER=(231,225,205,255)
for i,k in enumerate(ids):
    t=snap(Image.open(f'art/pixellab-stats/raw/{k}_{len(j[k])-1}/get_image_0.png'));t.save(f'art/pixellab-stats/final/{k}32.png')
    # 24 px by code: box reduce the bbox-fitted 32 px symbol, then snap
    s=t.resize((24,24),Image.BOX);s24=snap(s);s24.save(f'art/pixellab-stats/final/{k}24.png')
    b=Image.new('RGBA',(32,32),PAPER);b.alpha_composite(t);W.alpha_composite(b.resize((96,96),Image.NEAREST),(8+i*108,16))
    b2=Image.new('RGBA',(24,24),PAPER);b2.alpha_composite(s24);W.alpha_composite(b2.resize((72,72),Image.NEAREST),(8+i*108,16+104));W.alpha_composite(b,(8+i*108+80,16+104+30));W.alpha_composite(b2,(8+i*108+80+34,16+104+36))
    g.text((8+i*108,16+104+78),k.upper(),fill=(150,150,170))
g.text((4,2),'32 px (top), 24 px made by code (bottom, with 1x of both)',fill=(235,237,233));W.save('docs/art/boards/stat-symbols.png')
