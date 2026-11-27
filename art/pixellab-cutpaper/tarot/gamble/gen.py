"""Gamble outcomes (8) and the Stat point card, cut-paper tarot vignettes 96 x 64, text only, objects fill the frame: python3 art/pixellab-cutpaper/tarot/gamble/gen.py [ids] [seed]"""
import sys,json,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
CP="cut paper, shapes cut from black paper on cream paper, strong hard shadows, very simple bold flat shapes, flat colours of black, dark navy, cream, beige shadow and one deep red only, no text, no letters, no people, no animals, no creatures, exactly the objects named and nothing else, an extreme close-up, the objects very large and cropped by the frame edges so they fill the whole frame edge to edge, "
GOOD="mostly bright cream and beige with black outlines, "
BAD="mostly black and dark navy with red accents, "
P={
'gilded':GOOD+CP+"a huge gilded breastplate armour piece with a bright cream rim and a shining beige highlight, radiating short light rays",
'twin':GOOD+CP+"two identical playing cards side by side, slightly overlapping, one cream and one beige, each with a black diamond on it",
'hoard':GOOD+CP+"a huge heap of round beige and cream coins piled high with a few spilling, shining",
'dud':BAD+CP+"a huge empty open hand palm up, black silhouette on dark navy, with nothing in it and a faint red dust",
'wound':BAD+CP+"a huge cracked black heart with a jagged red crack across it and one red drop",
'spill':BAD+CP+"a huge broken glass flask lying on its side with jagged glass pieces and a big red liquid puddle spilling out",
'bright':GOOD+CP+"a huge bright cream star with long pointed rays on a black field, a few small sparks",
'hex':BAD+CP+"a huge black eye with a glowing red pupil inside a circle of hex sigil marks, dark navy background",
'stat':CP+"a huge pentagon radar chart: a cream pentagon web with spokes from the centre and a bold filled red star-shaped polygon inside, black outline, on a dark navy field",
}
only=[x for x in sys.argv[1].split(',') if x] if len(sys.argv)>1 else list(P);only=only or list(P)
seed=int(sys.argv[2]) if len(sys.argv)>2 else 61;jf='art/pixellab-cutpaper/tarot/gamble/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k in only:
    r=A.call('create_image_pixflux',{"description":P[k],"width":96,"height":64,"no_background":False,"outline":"lineless","shading":"flat shading","detail":"low detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
