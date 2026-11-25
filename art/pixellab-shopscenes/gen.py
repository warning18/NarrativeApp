"""14 shop scenes, dark look (NEW files *_shop_dark, 240 x 100): init = the original scene, text = the scene in the dark mood, dark palette forced. python3 art/pixellab-shopscenes/gen.py [ids] [seed] [strength]"""
import sys,json,io,base64,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
from PIL import Image
D="grim dark fantasy pixel art, a wide low scene at night or deep dusk under a dark stormy sky, worn and weathered, ominous mood, muted desaturated colours, deep black shadows, one strong glow of light, no characters, no text, no UI, "
S={
'saltmouth_yard':"a salt town smithy yard at dusk, anvils, weapon racks and a glowing forge fire, ember gold glow",
'saltmouth_tern_row':"a narrow salt-scoured quarter hung with lit paper boats, a footbridge over dark water, lanterns, dusk, cold blue glow",
'drowned_cloister_ossuary':"a drowned cloister ossuary, stacked skulls and bones in niches, candles, knee-deep black water, sickly green glow",
'reliquary_quarter':"the gate of the Reliquary Quarter, an arch of ash-dark brick, white paint marks, frost on the cobbles, pale smoke, cold blue glow",
'white_anchorage_chandlery':"a harbour chandlery of hauled hulls roofed with sails, coiled ropes, a ship's lamp, tar barrels, cold blue glow",
'saltmouth_tide_cellar':"a tide cellar black market below the docks, barrels, crates, dripping water, a red lantern, ember gold glow",
'saltmouth_landward_warehouse':"a landward warehouse of a salt town, stacked crates and racks of round shields, dusty light, cold blue glow",
'white_anchorage_vault':"a harbour vault, a heavy iron-banded stone door in a wall of anchors, chains, a hooded lantern, ember gold glow",
'saltmouth_green_door':"a narrow salt town street with a faded green door, bolts of dark cloth hanging, a lamp, void violet glow",
'ashen_quarter_ash_market':"an ash market square, burnt stalls, grey ash falling, hanging lanterns, a small shrine, ember gold glow",
'spire_hall_of_records':"a tall dim hall of records, shelves of scrolls and ledgers, tall narrow windows, a reading lamp, cold blue glow",
'emberwick_cold_forge':"a cold dead forge, a cooled anvil, ash and slag, a few faint embers, ember gold glow",
'blind_beggar':"a beggar's corner in a dark alley, rags, a tin bowl, a crooked wall and a single dim lantern, cold blue glow",
'the_crossing':"a caravan crossing on a dusty road, a covered wagon, a lantern, dry hills, long shadows, ember gold glow",
}
only=[x for x in sys.argv[1].split(',') if x] if len(sys.argv)>1 else list(S);only=only or list(S)
seed=int(sys.argv[2]) if len(sys.argv)>2 else 71;stg=int(sys.argv[3]) if len(sys.argv)>3 else 110
def b64(im):
    b=io.BytesIO();im.save(b,'PNG');return base64.b64encode(b.getvalue()).decode()
pal=Image.open('art/pixellab-icons-v2/palette_dark_forced.png').convert('RGBA')
jf='art/pixellab-shopscenes/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k in only:
    init=Image.open(f'assets/visuals/scenes/{k}.png').convert('RGBA')
    r=A.call('create_image_pixflux',{"description":D+S[k],"width":240,"height":100,"no_background":False,"init_image_base64":b64(init),"init_image_strength":stg,"color_image_base64":b64(pal),"outline":"single color black outline","shading":"medium shading","detail":"medium detail","seed":seed})
    jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
