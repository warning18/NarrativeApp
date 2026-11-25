"""3 boss characters (dark recipe): pro mode, style_character_id = Starter_basic_hero, dark palette, 48 px, side view, 8 directions: 10 gens each."""
import sys,json
sys.path.insert(0,'art/pixellab-backgrounds');sys.path.insert(0,'art/pixellab-icons-v2');import batchA_gen as A
import palette_dark as PD
HERO='de5e44f4-1c9d-4043-96cf-eed8d324a086'
M="grim dark fantasy chibi, worn and weathered, ominous, muted desaturated colours, deep shadows, "
D={
'inquisition_legate':M+"a heavy champion in battered white and blue plate armour with a closed visor helm and a plume, a blue cloak, a great sword held low, a faint violet glow in the visor, chibi",
'knell_keeper':M+"an undead servant of the Hollow Court in a long dark violet robe and a pointed hood, a pale skull face, a belt hung with forty bell tongues, a small tarnished bell in one hand, chibi",
'glass_shepherd':M+"a tall thin figure made of fused teal glass and pale sand, a faceless smooth head, long limbs, a long crook staff of fused sand in one hand, glowing white pinpoints for eyes, chibi",
}
only=[x for x in sys.argv[1].split(',') if x] if len(sys.argv)>1 else list(D);only=only or list(D)
jf='art/pixellab-chars3/jobs.json'
try: jobs=json.load(open(jf))
except Exception: jobs={}
for k in only:
    r=A.call('create_character',{"description":D[k],"name":k,"mode":"pro","style_character_id":HERO,"size":48,"view":"side","palette":['#%02X%02X%02X'%c for c in PD.PAL]})
    print(k,r[:160].replace('\n',' | '),flush=True);jobs.setdefault(k,[]).append(r);json.dump(jobs,open(jf,'w'))
