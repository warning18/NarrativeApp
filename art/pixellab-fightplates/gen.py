"""Fight backgrounds in cut paper, TEST of 3 (band floor, warden, boss): 180 x 320, text only, room for the fighter panels. python3 art/pixellab-fightplates/gen.py [seed]"""
import sys,json,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
CP="cut paper, shapes cut from black paper on cream paper, layered paper, strong hard shadows, very simple bold shapes, very few details, flat colours of black, dark navy, cream and one deep red only, no text, no characters, a wide empty floor in the lower two thirds and calm open space in the middle for two fighters facing each other, tall narrow format, "
P={
'band':CP+"the inside of a tall stone tower hall: black columns and a high arch at the top, a shaft of cream light falling from above, an empty stone floor",
'warden':CP+"a cellar chamber with a heavy iron gate and hanging chains at the top, a single red lantern glowing, an empty stone floor",
'boss':CP+"a vast dark throne hall: torn red banners hanging from tall black pillars, a dark doorway at the top, an empty cream floor with a thin red carpet",
}
seed=int(sys.argv[1]) if len(sys.argv)>1 else 31;jf='art/pixellab-fightplates/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k,t in P.items():
    r=A.call('create_image_pixflux',{"description":t,"width":180,"height":320,"no_background":False,"outline":"lineless","shading":"flat shading","detail":"low detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
