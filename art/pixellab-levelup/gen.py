"""Level Up plates (3) and the header banner (2 tries), cut paper, text only. python3 art/pixellab-levelup/gen.py [seed]"""
import sys,json,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
CP="cut paper, shapes cut from black paper on cream paper, layered paper, strong hard shadows, very simple bold shapes, very few details, flat colours of black, dark navy, cream and one deep red only, no text, no characters, "
P={
'plate_shrine':CP+"a shrine seen from the front: a tall black arch with a small stone altar and a bold red sigil circle on the floor, empty cream floor in the middle and the bottom, tall narrow format",
'plate_anvil':CP+"a forge yard: a big black anvil on a stump to one side, a few red sparks, a stone wall and a hanging hammer, empty cream floor in the middle and the bottom, tall narrow format",
'plate_yard':CP+"a training yard: a wooden practice post and a weapon rack at the sides, a low wall, a red banner, empty cream ground in the middle and the bottom, tall narrow format",
}
Hd={
'header_a':CP+"a wide horizontal paper banner with torn ends, black ink border and a cream middle, a small red seal at the centre, blank, no letters",
'header_b':CP+"a wide horizontal ribbon banner with swallow-tail ends, black and cream with a thin red stripe, blank, no letters",
}
seed=int(sys.argv[1]) if len(sys.argv)>1 else 17;jf='art/pixellab-levelup/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k,t in P.items():
    r=A.call('create_image_pixflux',{"description":t,"width":180,"height":320,"no_background":False,"outline":"lineless","shading":"flat shading","detail":"low detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
for k,t in Hd.items():
    r=A.call('create_image_pixflux',{"description":t,"width":160,"height":40,"no_background":True,"outline":"single color black outline","shading":"flat shading","detail":"low detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
