"""6 shop keepers: chibi, dark recipe, 64 x 64, standing front view (1 gen each; init = Starter_basic_hero south at low strength for the proportions). python3 art/pixellab-keepers/gen.py [ids] [seed] [strength]"""
import sys,json,io,base64,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
from PIL import Image
M="grim dark fantasy chibi pixel art, worn and weathered, ominous mood, muted desaturated colours, deep black shadows, thick dark outline, a chibi full body character standing straight, seen from the front, big head, small body, three heads tall, hands resting on a counter, one strong rim light of "
K={
'beggars_cellar_boy':M+"cold blue, a thin cellar boy in a ragged grey tunic and a flat cap, a tin bowl in one hand, a cheeky tired face",
'shieldwright':M+"cold blue, a broad shieldmaker in a leather apron and a bald head with a thick grey beard, strong arms, a small round shield on his arm",
'vault_keeper':M+"ember gold, a suspicious vault keeper in a dark hooded coat, a ring of keys at the belt, a lantern, a scarf over the mouth",
'needle_house_keeper':M+"void violet, a thin tailor in a dark violet waistcoat and round glasses, a measuring tape around the neck, a pincushion on the wrist",
'hammersmith':M+"ember gold, a huge bearded blacksmith in a soot-black leather apron, bare muscular arms, a big hammer resting on the shoulder",
'caravan_master':M+"ember gold, a weathered caravan master in a wide-brimmed hat and a long dusty travelling coat, a scarf, a water skin, a walking staff",
}
only=[x for x in sys.argv[1].split(',') if x] if len(sys.argv)>1 else list(K)
only=only or list(K);seed=int(sys.argv[2]) if len(sys.argv)>2 else 61;stg=int(sys.argv[3]) if len(sys.argv)>3 else 60
def b64(im):
    b=io.BytesIO();im.save(b,'PNG');return base64.b64encode(b.getvalue()).decode()
h=Image.open('art/pixellab-keepers/hero_south.png').convert('RGBA');h=h.crop(h.getbbox());s=56/h.height;h=h.resize((max(1,round(h.width*s)),56),Image.NEAREST)
init=Image.new('RGBA',(64,64),(0,0,0,0));init.alpha_composite(h,((64-h.width)//2,6))
pal=Image.open('art/pixellab-icons-v2/palette_dark_forced.png').convert('RGBA')
jf='art/pixellab-keepers/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k in only:
    r=A.call('create_image_pixflux',{"description":K[k]+", game sprite, no text","width":64,"height":64,"no_background":True,"init_image_base64":b64(init),"init_image_strength":stg,"color_image_base64":b64(pal),"outline":"single color black outline","shading":"basic shading","detail":"medium detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
