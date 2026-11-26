"""Loot card vignettes in the cut-paper tarot style (96 x 64, text only): python3 art/pixellab-cutpaper/tarot/loot/gen.py [ids] [seed]"""
import sys,json,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
CP="cut paper, shapes cut from black paper on cream paper, layered paper, strong hard shadows, very simple bold shapes, very few details, flat colours of black, dark navy, cream and one deep red only, no text, no people, a single clear subject in the middle, "
P={
'equipment':CP+"a short sword lying across a round shield, with a helmet beside them",
'item':CP+"a round red potion bottle with a cork, a rolled scroll tied with a ribbon leaning against it",
'money':CP+"a heap of round coins with a small cloth purse tied at the neck beside it",
}
only=[x for x in sys.argv[1].split(',') if x] if len(sys.argv)>1 else list(P);only=only or list(P)
seed=int(sys.argv[2]) if len(sys.argv)>2 else 11;jf='art/pixellab-cutpaper/tarot/loot/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k in only:
    r=A.call('create_image_pixflux',{"description":P[k],"width":96,"height":64,"no_background":False,"outline":"lineless","shading":"flat shading","detail":"low detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
