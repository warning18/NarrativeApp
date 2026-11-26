"""The rest of the fight backgrounds (cut paper, text only, 180 x 320): python3 art/pixellab-fightplates/gen_rest.py [ids] [seed]"""
import sys,json,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
CP="cut paper, shapes cut from black paper on cream paper, layered paper, strong hard shadows, very simple bold shapes, very few details, flat colours of black, dark navy, cream and one deep red only, no text, no people, no characters, no figures, no silhouettes of people, a wide empty floor in the lower two thirds and calm open space in the middle for two fighters facing each other, tall narrow format, "
P={
# band floors (variants b and c of each band; variant a of band 1 is the test plate 'band')
'band1_b':CP+"a curved stone stair under a low arch in a tower, a few steps, a single cream light, an empty stone floor",
'band1_c':CP+"a low cellar passage in a tower with hanging black lamps and thick beams, an empty stone floor",
'band2_a':CP+"a long hall of tall black pillars and tall narrow windows letting in cream light, an empty stone floor",
'band2_b':CP+"a hall of tall black shelves of books and a thin red carpet down the middle, an empty floor",
'band2_c':CP+"a hall with a broken balcony and hanging chains and a high window, an empty stone floor",
'band3_a':CP+"a high round chamber at the top of a tower with a great circular cream window like a moon, an empty floor",
'band3_b':CP+"a dark chamber with floating cream shards of stone and a faint red glow high up, an empty floor",
'band3_c':CP+"a wide stair of black steps leading up to a red doorway at the top, an empty cream floor",
# wardens 15 and 25 (5 is the test 'warden')
'ward15':CP+"a hollow court chamber: a ring of empty black chairs on a low dais and a red sigil circle on the floor, tall arches",
'ward25':CP+"a hall strewn with cream glass shards, a jagged red tear in the wall like a wound, black pillars, an empty floor",
# bosses 20 and 30 (10 is the test 'boss')
'boss20':CP+"a great hall with a long red carpet to a dark empty throne under one huge red banner and black pillars",
'boss30':CP+"a vast black abyss hall with a huge jagged red rift in the sky and floating black shards, a thin cream floor",
# elites and the rival
'elite1':CP+"a stone chamber with two red glowing braziers on black stands and hanging chains, an empty floor",
'elite2':CP+"a hall with hanging red lanterns and black spikes along the walls, an empty floor",
'elite3':CP+"a chamber with a glowing red crack across the cream floor and black arches, empty",
'rival':CP+"a dueling circle: a round cream floor with a thick red ring painted on it inside a stone ring wall, two empty black chairs at the sides",
# the dice plates: the ground seen from above (cut paper), one per band
'dice1':"cut paper, flat top-down view of grey stone floor tiles with black cracks, cream and dark navy only, no text, no objects, very simple, tall narrow format",
'dice2':"cut paper, flat top-down view of wooden floor planks in cream with black gaps and a thin red line, no text, no objects, very simple, tall narrow format",
'dice3':"cut paper, flat top-down view of a black glass floor with cream cracks and a faint red crack, no text, no objects, very simple, tall narrow format",
}
only=[x for x in sys.argv[1].split(',') if x] if len(sys.argv)>1 else list(P);only=only or list(P)
seed=int(sys.argv[2]) if len(sys.argv)>2 else 31;jf='art/pixellab-fightplates/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k in only:
    r=A.call('create_image_pixflux',{"description":P[k],"width":180,"height":320,"no_background":False,"outline":"lineless","shading":"flat shading","detail":"low detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
