"""3 bookmark tab glyphs (24 px made from 32 px, Apollo palette forced, 1 gen each): stats radar, armour shield, die."""
import sys,json,io,base64,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
from PIL import Image
B="pixel art game icon glyph, a bold simple silhouette, thick near-black outline, flat colours, few details, mostly dark ink and light paper tones with one strong spot colour of "
K={
'stats':B+"teal: a hexagon radar chart with a filled shape inside and spokes",
'armour':B+"orange: a heater shield with a rivet boss and a cross band",
'die':B+"red: a six sided die seen from the front corner with five pips",
}
def b64(im):
    b=io.BytesIO();im.save(b,'PNG');return base64.b64encode(b.getvalue()).decode()
pal=Image.open('art/pixellab-stats/apollo_forced.png').convert('RGBA');seed=int(sys.argv[1]) if len(sys.argv)>1 else 7
jf='art/pixellab-bookmarks/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k,t in K.items():
    r=A.call('create_image_pixflux',{"description":t+", game icon, no text, centred","width":32,"height":32,"no_background":True,"color_image_base64":b64(pal),"outline":"single color black outline","shading":"flat shading","detail":"medium detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
