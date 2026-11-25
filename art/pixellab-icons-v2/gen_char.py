"""Foe icons FROM their full character (init from the sprite): python3 art/pixellab-icons-v2/gen_char.py [strength] (repo root). 1 gen each."""
import sys,json,io,base64,os
sys.path.insert(0,'art/pixellab-backgrounds');sys.path.insert(0,'art/pixellab-icons-v2');import batchA_gen as A
import wave4_ids as W
from PIL import Image
STR=int(sys.argv[1]) if len(sys.argv)>1 else 110
BEAST={'plague_hound','rat_matriarch'}
IDS=['inquisition_warden','iron_golem','plague_hound','rat_matriarch','street_bandit','void_sovereign','white_soldier']
def b64(im):
    b=io.BytesIO();im.save(b,'PNG');return base64.b64encode(b.getvalue()).decode()
def init(k):
    im=Image.open(f'assets/visuals/fighters/{k}_idle_west.png').convert('RGBA');bb=im.getbbox();im=im.crop(bb)
    if k not in BEAST: im=im.crop((0,0,im.width,max(int(im.height*.55),8)))   # the bust: head and shoulders
    s=min(30/im.width,30/im.height);im=im.resize((max(1,round(im.width*s)),max(1,round(im.height*s))),Image.NEAREST)
    c=Image.new('RGBA',(32,32),(0,0,0,0));c.alpha_composite(im,((32-im.width)//2,(32-im.height)//2));os.makedirs('art/pixellab-icons-v2/init_w4',exist_ok=True);c.save(f'art/pixellab-icons-v2/init_w4/{k}.png');return c
pal=Image.open('art/pixellab-icons-v2/palette_forced.png').convert('RGBA')
jf='art/pixellab-icons-v2/jobs_wave4.json';jobs=json.load(open(jf))
for k in IDS:
    c=init(k)
    a={"description":W.IDS[k]+W.SUFFIX,"width":32,"height":32,"no_background":True,"init_image_base64":b64(c),"init_image_strength":STR,"color_image_base64":b64(pal),"outline":"single color black outline","shading":"basic shading","detail":"medium detail","seed":41}
    r=A.call('create_image_pixflux',a);jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
