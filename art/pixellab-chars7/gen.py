"""Wave 5b: 7 full chibi characters (pro mode, style_character_id = Starter_basic_hero, extended palette, 48 px, side view): 10 gens each. python3 art/pixellab-chars7/gen.py [id,id] [suffix]"""
import sys,json
sys.path.insert(0,'art/pixellab-backgrounds');sys.path.insert(0,'art/pixellab-icons-v2');import batchA_gen as A
from palette import PAL
HERO='de5e44f4-1c9d-4043-96cf-eed8d324a086'
D={
'horn_taker':"a tall thin exorcist in a long dark grey robe with a white mask marked with a red line, carrying a big curved horn in one hand, a rope belt, chibi",
'frost_kept_giant':"a huge stocky giant with pale blue frosted skin and a thick white beard, a fur vest, a stone tally slab on his back, chibi",
'smuggler_captain':"a smuggler captain in a long dark coat with a pink sash, a tricorn hat with a feather, a lantern in one hand, chibi",
'strand_colossus':"a huge stocky humanoid made of two wooden ship keels and teal glass panels fused together, one glowing white eye in the chest, blocky arms, chibi",
'void_wisp':"a small humanoid figure made of pale blue-white cold flame, two tiny dark eyes, no clothes, a glowing flame head, chibi",
'void_stalker':"a thin tall humanoid hunter in black tattered cloth, a pale bone mask for a face, long thin limbs, glowing purple eyes, chibi",
'void_manifestation':"a humanoid shape of swirling dark purple smoke with several small pale faces on its body, glowing violet edges, chibi",
}
only=sys.argv[1].split(',') if len(sys.argv)>1 and sys.argv[1] else list(D)
jf='art/pixellab-chars7/jobs.json'
try: jobs=json.load(open(jf))
except Exception: jobs={}
for k in only:
    r=A.call('create_character',{"description":D[k],"name":k,"mode":"pro","style_character_id":HERO,"size":48,"view":"side","palette":['#%02X%02X%02X'%c for c in PAL]})
    print(k,r[:200].replace('\n',' | '),flush=True);jobs.setdefault(k,[]).append(r)
    json.dump(jobs,open(jf,'w'))
