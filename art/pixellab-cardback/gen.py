"""Gamble card back options (112 x 160, cut paper, text only, 1 gen each). python3 art/pixellab-cardback/gen.py [seed]"""
import sys,json,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
CP="cut paper, shapes cut from black paper on cream paper, strong hard shadows, very simple bold flat shapes, flat colours of black, dark navy, cream and one deep red only, no text, no letters, no people, the back of a playing card seen straight on, symmetrical, a thin cream border all round and rounded corners, a plain empty space in the exact centre, "
P={
'a':CP+"a black card with a big red sigil circle with spokes around the empty centre and small red corner marks",
'b':CP+"a dark navy card with a black silhouette of a tower with a red window above the empty centre and a repeating pattern of small cream diamonds",
'c':CP+"a black card with a diagonal lattice of thin cream lines and a red diamond frame around the empty centre",
}
seed=int(sys.argv[1]) if len(sys.argv)>1 else 13;jf='art/pixellab-cardback/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k,t in P.items():
    r=A.call('create_image_pixflux',{"description":t,"width":112,"height":160,"no_background":True,"outline":"lineless","shading":"flat shading","detail":"low detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
