"""Stalls: dark snap, see-through gap, 32 px list icon in code, sheet with composites. python3 art/pixellab-icons-v2/stalls_post.py"""
import sys,glob,os,json,numpy as np
sys.path.insert(0,'art/pixellab-icons-v2');sys.path.insert(0,'art/pixellab-cutpaper')
from PIL import Image,ImageDraw
from scipy import ndimage
import darksnap,stalls_ids as ST
OUT='art/pixellab-icons-v2/final_stalls/';os.makedirs(OUT,exist_ok=True)
def hollow(im):
    a=np.array(im);al=a[...,3]>0;L=a[...,:3]@np.array([.3,.59,.11]);dark=al&(L<30)
    zone=np.zeros_like(dark);zone[8:42,14:82]=True;lab,n=ndimage.label(dark&zone)
    if n==0:return im,False
    sizes=ndimage.sum(np.ones_like(lab),lab,index=np.arange(1,n+1));k=int(np.argmax(sizes))+1
    a[lab==k,3]=0;return Image.fromarray(a,'RGBA'),sizes.max()
def icon(st):
    # list icon: the stall (interior opaque again) fitted into 32 px, box-averaged then snapped
    a=np.array(st);bg=Image.new('RGBA',st.size,(0,0,0,0));
    full=st.copy();arr=np.array(full);arr[...,3]=np.where(arr[...,3]==0,255,arr[...,3]);  # fill the gap with the near-black behind
    full=Image.fromarray(arr,'RGBA');bb=st.getbbox();full=full.crop(bb)
    s=min(32/full.width,30/full.height);sm=full.resize((max(1,round(full.width*s)),max(1,round(full.height*s))),Image.BOX)
    c=Image.new('RGBA',(32,32),(0,0,0,0));c.alpha_composite(sm,((32-sm.width)//2,32-sm.height-1));return darksnap.snap(c)
j=json.load(open('art/pixellab-icons-v2/jobs_stalls.json'));fin={}
for k in ST.IDS:
    if k in j:src=Image.open(f'art/pixellab-icons-v2/raw_stalls/{k}_{len(j[k])-1}/get_image_0.png')
    else:src=Image.open('art/pixellab-icons-v2/final_wavedark/'+{'weaponsmith_forge':'stall_forge','apothecary_row':'stall_apothecary'}[k]+'.png')
    t=darksnap.snap(src) if k in j else src.convert('RGBA')
    h=t;ok=True
    if k in j:h,ok=hollow(t)
    h.save(f'{OUT}{k}.png');fin[k]=h;ic=icon(h);ic.save(f'{OUT}{k}_icon32.png')
    print(k,'gap' if ok else 'NO GAP')
PAPER=(231,225,205,255);ids=list(ST.IDS);C=5;cw=96*2+12
rows=(len(ids)+C-1)//C
W=Image.new('RGBA',(C*cw+10,rows*(64*2+40)+10),(26,28,38,255));g=ImageDraw.Draw(W)
for i,k in enumerate(ids):
    x=10+(i%C)*cw;y=6+(i//C)*(64*2+40)
    bg=Image.new('RGBA',(96,64),(60,56,64,255));bg.alpha_composite(fin[k]);W.alpha_composite(bg.resize((192,128),Image.NEAREST),(x,y))
    ic=Image.open(f'{OUT}{k}_icon32.png');ib=Image.new('RGBA',(32,32),PAPER);ib.alpha_composite(ic);W.alpha_composite(ib.resize((64,64),Image.NEAREST),(x+192+4,y));g.text((x,y+130),k[:22],fill=(150,150,170))
W.save('docs/art/boards/stalls-all.png')
# composites: 6 stalls on 2 backgrounds with different NPCs
bgs=[Image.open('art/pixellab-cutpaper/tower/handoff/tower_shop.png').convert('RGBA'),Image.open('assets/visuals/fight_plates/cityroad.png').convert('RGBA')]
npcs=[Image.open(p).convert('RGBA') for p in ('assets/visuals/heroes/cleric_stand_east.png','assets/visuals/heroes/mage_stand_west.png','assets/visuals/heroes/dwarf_stand_west.png','assets/visuals/heroes/orc_stand_east.png')]
pick=['blind_beggar_stall','arcane_bazaar','ossuary_relics','shieldwrights_hall','last_lantern','sharpweave_den']
X=Image.new('RGBA',(3*258+10,2*210+10),(26,28,38,255));g=ImageDraw.Draw(X)
for i,k in enumerate(pick):
    bgim=bgs[i%2];panel=bgim.crop((0,bgim.height-128,bgim.width,bgim.height-32)).crop((20,0,144,96)).convert('RGBA');pw,ph=panel.size
    n=npcs[i%4];n=n.crop(n.getbbox());c=panel.copy();sx=(pw-96)//2;sy=ph-64-4
    c.alpha_composite(n,(sx+48-n.width//2,sy+52-n.height));c.alpha_composite(fin[k],(sx,sy))
    X.alpha_composite(c.resize((pw*2,ph*2),Image.NEAREST),(8+(i%3)*258,8+(i//3)*210));g.text((8+(i%3)*258,8+(i//3)*210+194),k,fill=(235,235,235))
X.save('docs/art/boards/stalls-composites.png')
