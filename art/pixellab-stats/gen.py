"""8 stat symbols for the Level Up screen: 32 px, Apollo palette forced, one spot colour each, bold silhouette (1 gen each). python3 art/pixellab-stats/gen.py [ids] [seed]"""
import sys,json,io,base64,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
from PIL import Image
B="pixel art game stat symbol, a bold simple silhouette, thick near-black outline, flat colours, few details, mostly dark ink and light paper tones with one strong spot colour of "
K={
'str':B+"red: a clenched fist raised, seen from the front, knuckles clear",
'dex':B+"green: a single long feather quill-shaped feather, swept diagonally, with a motion curve",
'con':B+"orange: a heart on a small round shield, solid and sturdy",
'int':B+"blue: an open book with a quill pen resting on it",
'wis':B+"purple: a perched owl seen from the front with big round eyes",
'per':B+"teal: a single large open eye with a round bright iris",
'luck':B+"gold: a four-leaf clover with a stem",
'cha':B+"pink: a theatre mask with a smile and a small crown above it",
}
only=[x for x in sys.argv[1].split(',') if x] if len(sys.argv)>1 else list(K);only=only or list(K);seed=int(sys.argv[2]) if len(sys.argv)>2 else 5
def b64(im):
    b=io.BytesIO();im.save(b,'PNG');return base64.b64encode(b.getvalue()).decode()
pal=Image.open('art/pixellab-stats/apollo_forced.png').convert('RGBA')
jf='art/pixellab-stats/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k in only:
    r=A.call('create_image_pixflux',{"description":K[k]+", game icon, no text, centred","width":32,"height":32,"no_background":True,"color_image_base64":b64(pal),"outline":"single color black outline","shading":"flat shading","detail":"medium detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
