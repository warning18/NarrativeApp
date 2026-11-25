"""Darker chibi test: snap with the dark palette, make the stalls see-through behind the counter, build the sheet. python3 art/pixellab-icons-v2/dark_test.py"""
import sys,glob,os,numpy as np
sys.path.insert(0,'art/pixellab-icons-v2');sys.path.insert(0,'art/pixellab-cutpaper')
from PIL import Image,ImageDraw
from scipy import ndimage
from simplify import simplify
import palette_dark as PD
def snap(im,pal):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>40;rgb=a[...,:3];p=np.array(pal,float)
    d=((rgb[:,:,None,:]-p[None,None])**2*np.array([2,4,3])).sum(3);o=np.zeros_like(a);o[...,:3]=p[d.argmin(2)];o[...,3]=al*255
    pad=np.pad(al,1);edge=al&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:]);o[edge,:3]=pal[0]
    return simplify(Image.fromarray(o.astype(np.uint8),'RGBA'),2)
PAL=PD.PAL;R='art/pixellab-icons-v2/raw_wavedark/';OUT='art/pixellab-icons-v2/final_wavedark/';os.makedirs(OUT,exist_ok=True)
def hollow(im):   # the largest near-black region between the posts (above the counter) becomes see-through
    a=np.array(im);al=a[...,3]>0;L=a[...,:3]@np.array([.3,.59,.11]);dark=al&(L<30)
    zone=np.zeros_like(dark);zone[8:42,14:82]=True
    lab,n=ndimage.label(dark&zone)
    if n==0:return im
    sizes=ndimage.sum(np.ones_like(lab),lab,index=np.arange(1,n+1));k=int(np.argmax(sizes))+1
    a[lab==k,3]=0;return Image.fromarray(a,'RGBA')
fin={}
for f in sorted(glob.glob(R+'*_0/get_image_0.png')):
    k=f.split('/')[-2][:-2];im=Image.open(f).convert('RGBA')
    t=snap(im,PAL)
    if k.startswith('stall_'):t=hollow(t)
    t.save(f'{OUT}{k}.png');fin[k]=t
# the current (lighter) versions for comparison
cur={'inquisition_high_warden':'final_wave4','plague_hound':'final_wave4','bone_warden':'final_wave4','void_hound':'final_wave4','weaponsmith_forge':'final_wave5a','apothecary_row':'final_wave5a','iron_closed':'final_wave5a','iron_open':'final_wave5a'}
PAPER=(231,225,205,255);S=3;order=list(cur)
W=Image.new('RGBA',(1060,2*108+22+260+30),(26,28,38,255));g=ImageDraw.Draw(W);g.text((4,2),'current (top) / darker (bottom)',fill=(235,237,233))
for i,k in enumerate(order):
    for r,im in enumerate((Image.open(f'art/pixellab-icons-v2/{cur[k]}/{k}32.png').convert('RGBA'),fin[k])):
        bg=Image.new('RGBA',(32,32),PAPER);bg.alpha_composite(im);W.alpha_composite(bg.resize((96,96),Image.NEAREST),(8+i*108,16+r*108))
    g.text((8+i*108,16+2*108-2),k[:14],fill=(150,150,170))
for j,k in enumerate(('stall_forge_icon','stall_apothecary_icon')):
    bg=Image.new('RGBA',(32,32),PAPER);bg.alpha_composite(fin[k]);W.alpha_composite(bg.resize((96,96),Image.NEAREST),(878+j*84,16+108));g.text((878+j*84,16+2*108-2),k[:13],fill=(150,150,170))
# composites: each stall on 2 backgrounds with 2 NPCs behind (bg -> NPC -> stall), 2x
y0=16+2*108+10;g.text((4,y0-14),'stall as an element: background -> NPC behind the counter -> stall (2x)',fill=(235,237,233))
bgs=[Image.open('art/pixellab-cutpaper/tower/handoff/tower_shop.png').convert('RGBA'),Image.open('assets/visuals/fight_plates/cityroad.png').convert('RGBA')]
npcs=[Image.open('assets/visuals/heroes/cleric_stand_east.png').convert('RGBA'),Image.open('assets/visuals/heroes/mage_stand_west.png').convert('RGBA')]
def crop_npc(n):
    bb=n.getbbox();return n.crop(bb) if bb else n
x=8;n=0
for si,sk in enumerate(('stall_forge','stall_apothecary')):
    st=fin[sk]
    for bi,bgim in enumerate(bgs):
        panel=bgim.crop((0,bgim.height-128,bgim.width,bgim.height-32)).convert('RGBA')   # lower part of the plate: 180 x 96
        panel=panel.crop((40,0,40+124,96))
        pw,ph=panel.size
        c=panel.copy();sx=(pw-96)//2;sy=ph-64-4
        npc=crop_npc(npcs[(si+bi)%2]);nsc=npc.resize((int(npc.width*1.0),int(npc.height*1.0)),Image.NEAREST)
        c.alpha_composite(nsc,(sx+48-nsc.width//2,sy+52-nsc.height))   # NPC feet land behind the counter top
        c.alpha_composite(st,(sx,sy))
        W.alpha_composite(c.resize((pw*2,ph*2),Image.NEAREST),(x,y0));x+=pw*2+8;n+=1
W=W.crop((0,0,max(W.width,x),y0+200));W.save('docs/art/boards/icons-dark-test.png');print(W.size)
