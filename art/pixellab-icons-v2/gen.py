"""Icons V2 chibi colour: python3 art/pixellab-icons-v2/gen.py wave2 [id,id,...] (repo root). 1 generation per id; hero palette forced."""
import sys,json,io,base64,os
sys.path.insert(0,'art/pixellab-backgrounds');sys.path.insert(0,'art/pixellab-icons-v2');import batchA_gen as A
from PIL import Image
wave=sys.argv[1];ids=__import__(f'{wave}_ids').IDS
RET=os.environ.get('RETRY');ids={**ids,**getattr(__import__(f'{wave}_ids'),{'2':'RETRY2','3':'RETRY3'}.get(RET,'RETRY'),{})} if RET else ids
only=[x for x in sys.argv[2].split(',') if x] if len(sys.argv)>2 else []
only=only or list(ids)
seed=int(sys.argv[3]) if len(sys.argv)>3 else None
pal=io.BytesIO();Image.open(os.environ.get('PALFILE','art/pixellab-icons-v2/palette_forced.png')).convert('RGBA').save(pal,'PNG');PAL=base64.b64encode(pal.getvalue()).decode()
T="chibi game item pixel art, chunky rounded squat shape, thick dark outline, small flat colour palette, one light highlight, one dark inner shadow, "
T=getattr(__import__(f"{wave}_ids"),"T",T)
jf=f'art/pixellab-icons-v2/jobs_{wave}.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k in only:
    a={"description":T+ids[k]+getattr(__import__(f"{wave}_ids"),"SUFFIX",", a single object only, no character, no hands, game icon, no text, centred"),"width":32,"height":32,"no_background":True,"outline":"single color black outline","shading":"basic shading","detail":"medium detail","color_image_base64":PAL}
    if seed is not None:a["seed"]=seed
    r=A.call('create_image_pixflux',a);jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True)
    json.dump(jobs,open(jf,'w'))
