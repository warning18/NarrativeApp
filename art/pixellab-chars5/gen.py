"""5 look-alike Inquisition bosses redesigned (dark recipe): pro mode, style_character_id = Starter_basic_hero, dark palette, 48 px, side view, 8 directions: 10 gens each. python3 art/pixellab-chars5/gen.py [id,id]"""
import sys,json
sys.path.insert(0,'art/pixellab-backgrounds');sys.path.insert(0,'art/pixellab-icons-v2');import batchA_gen as A
import palette_dark as PD
HERO='de5e44f4-1c9d-4043-96cf-eed8d324a086'
M="grim dark fantasy chibi, worn and weathered, ominous, muted desaturated colours, deep shadows, "
D={
'kroll_the_branded':M+"a gaunt inquisitor in a long black coat with a white collar and a blue sash, short grey hair, a glowing red brand mark scar on his cheek, a branding iron with a red-hot tip in one hand, a thin cruel smile, chibi",
'hollow_court_zealot':M+"a hunched zealot in a ragged dark violet hooded robe, a white porcelain half mask over the face, hands clasped around a glowing violet crystal shard, chibi",
'hollow_court_inquisitor':M+"a tall inquisitor in a long violet coat with a high collar and a tall pointed black hat, a pale narrow face, holding a long black staff topped with a round seal, chibi",
'inquisition_penitent':M+"a barefoot penitent with a bandaged bare torso and a torn grey skirt, a violet hood, scourge scars, holding a rope scourge with barbs, chibi",
'purifier_vell':M+"a purifier in a soot-black leather apron and a hood with round glass goggles, a lit torch with an orange flame in each hand, a belt of oil flasks, chibi",
}
only=[x for x in sys.argv[1].split(',') if x] if len(sys.argv)>1 else list(D);only=only or list(D)
jf='art/pixellab-chars5/jobs.json'
try: jobs=json.load(open(jf))
except Exception: jobs={}
for k in only:
    r=A.call('create_character',{"description":D[k],"name":k,"mode":"pro","style_character_id":HERO,"size":48,"view":"side","palette":['#%02X%02X%02X'%c for c in PD.PAL]})
    print(k,r[:150].replace('\n',' | '),flush=True);jobs.setdefault(k,[]).append(r);json.dump(jobs,open(jf,'w'))
