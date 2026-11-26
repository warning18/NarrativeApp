"""Version C of the 14 Tower backgrounds: init = today's plate (B, 180 x 320), the cut-paper treatment in the prompt, the five tones forced. python3 art/pixellab-cutpaper/tower-v3/gen.py [ids] [strength] [seed]"""
import sys,json,io,base64,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
from PIL import Image
CP="a dark moody scene, mostly black and dark navy with only a few cream lit areas and one deep red spot, cut paper, shapes cut from black paper on cream paper, layered paper, strong hard shadows, bold silhouettes, very simple bold shapes, very few details, flat colours of black, dark navy, paper shadow beige and cream with one deep red as the only spot colour, no text, no people, "
S={
'band1':"a round stone tower room with an arched window in the wall, wall torches and a stone floor",
'band2':"a stone spiral stair curving up along a tower wall with a torch and two small windows",
'band3':"a round battlement tower with an arched doorway and a cauldron with a column of smoke at the base",
'bargain':"a stone alcove with a desk, scales and an open ledger, a hanging lamp",
'boss10':"a vaulted domed stone hall with columns, a dark doorway and one long red banner",
'boss20':"a round tower hall with hanging red banners on the walls and a stone table",
'boss30':"a tall stone tower under a night sky with stars, crenellations at the top",
'lose':"a round stone tower room with a hearth and a cauldron of fire at the base",
'parley':"a stone arch gate with an iron grille door and two lanterns at the sides",
'shop':"the inside of a tall round tower with a stair, shelves and a lit doorway in the wall",
'ward5':"a round stone chamber with a low door, a black stone bench and a lamp",
'ward15':"a tall round tower chamber with one huge bell hanging on chains and a low arched door",
'ward25':"a ruined cathedral hall with tall arched windows, pews and a round window above",
'win':"a crenellated battlement tower against a pale sky, a stone wall and a door",
}
only=[x for x in sys.argv[1].split(',') if x] if len(sys.argv)>1 else list(S);only=only or list(S)
stg=int(sys.argv[2]) if len(sys.argv)>2 else 75;seed=int(sys.argv[3]) if len(sys.argv)>3 else 41
def b64(im):
    b=io.BytesIO();im.save(b,'PNG');return base64.b64encode(b.getvalue()).decode()
pal=Image.open('art/pixellab-inkkit/five_forced.png').convert('RGBA')
jf='art/pixellab-cutpaper/tower-v3/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k in only:
    init=Image.open(f'art/pixellab-cutpaper/tower-v3/B/{k}.png').convert('RGBA')
    r=A.call('create_image_pixflux',{"description":CP+S[k],"width":180,"height":320,"no_background":False,"init_image_base64":b64(init),"init_image_strength":stg,"color_image_base64":b64(pal),"outline":"lineless","shading":"flat shading","detail":"low detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
