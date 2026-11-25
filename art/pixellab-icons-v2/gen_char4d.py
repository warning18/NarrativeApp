"""Dark foe icons FROM the darkened 7 characters (init = bust crop of the darkened west sprite): python3 art/pixellab-icons-v2/gen_char4d.py [strength]. 1 gen each."""
import sys,json,io,base64,os
sys.path.insert(0,'art/pixellab-backgrounds');sys.path.insert(0,'art/pixellab-icons-v2');import batchA_gen as A
import wave4d_ids as W,darksnap
from PIL import Image
STR=int(sys.argv[1]) if len(sys.argv)>1 else 110
IDS='horn_taker frost_kept_giant smuggler_captain strand_colossus void_wisp void_stalker void_manifestation'.split()
def b64(im):
    b=io.BytesIO();im.save(b,'PNG');return base64.b64encode(b.getvalue()).decode()
os.makedirs('art/pixellab-chars7/final_dark',exist_ok=True);os.makedirs('art/pixellab-icons-v2/init_w4d',exist_ok=True)
pal=Image.open('art/pixellab-icons-v2/palette_dark_forced.png').convert('RGBA')
jf='art/pixellab-icons-v2/jobs_wave4d.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k in IDS:
    os.makedirs(f'art/pixellab-chars7/final_dark/{k}',exist_ok=True)
    for d in ('west','east','south','north'):
        darksnap.snap(Image.open(f'art/pixellab-chars7/raw/{k}/Idle/rotations/{d}.png'),0,False).save(f'art/pixellab-chars7/final_dark/{k}/{d}.png')
    im=Image.open(f'art/pixellab-chars7/final_dark/{k}/west.png').convert('RGBA');bb=im.getbbox();im=im.crop(bb);im=im.crop((0,0,im.width,max(int(im.height*.55),8)))
    s=min(30/im.width,30/im.height);im=im.resize((max(1,round(im.width*s)),max(1,round(im.height*s))),Image.NEAREST)
    c=Image.new('RGBA',(32,32),(0,0,0,0));c.alpha_composite(im,((32-im.width)//2,(32-im.height)//2));c.save(f'art/pixellab-icons-v2/init_w4d/{k}.png')
    a={"description":W.IDS[k]+W.SUFFIX,"width":32,"height":32,"no_background":True,"init_image_base64":b64(c),"init_image_strength":STR,"color_image_base64":b64(pal),"outline":"single color black outline","shading":"basic shading","detail":"medium detail","seed":41}
    r=A.call('create_image_pixflux',a);jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
