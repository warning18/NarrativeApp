"""Backgrounds batch B: the next 30 story bands by use (240x100, seed 3, 1 generation each). python3 art/pixellab-backgrounds/batchB_gen.py <state.json>"""
import json, subprocess, time, sys, re
sys.path.insert(0,'art/pixellab-backgrounds')
import batchA_gen as A
B=A.B
STORY={
 'saltmouth_yard':"pixel art, a salt town's open yard between warehouses, barrels and crates, a well, whitewashed walls, white sun, a few awnings, ",
 'drowned_cloister_ossuary':"pixel art, an ossuary under a drowned cloister, walls of stacked skulls and bones in niches, shallow black water on the floor, candles, ",
 'highhearth':"pixel art, a giants' hall settlement, enormous stone houses and a well wide enough for a cart, huge doors, mountains behind, small figures absent, ",
 'blind_beggar':"pixel art, the back room of a tavern, four wooden tables, a cage for the house's money, a lantern, dark plank walls, no sign, ",
 'alster_high_quay':"pixel art, a high stone quay standing on stone legs over a harbour, long hulls moored to iron posts a man's height above the stones, dusk, ",
 'ashen_quarter_wall_of_names':"pixel art, a stretch of rubble wall at the edge of a ruined quarter, rows of names scratched as marks, six spears leaning, ash falling, the dark Spire beyond, ",
 'drowned_cloister_nave_hall':"pixel art, the nave of a drowned cloister, long reading tables with ledgers, tall candles, pillars standing in shallow black water, ",
 'emberwick':"pixel art, a hollow of kilns smoking beside old slag heaps, a well, a row of houses built from slag blocks, orange kiln glow, ",
 'akagiri':"pixel art, a hot-spring village on terraces in red steam, steaming pools, wooden bath houses, horned stone lanterns, red haze, ",
 'kindly_hill_long_room':"pixel art, a long warm hall inside a green hill, a long table set with bowls, round windows, earthen walls hung with herbs, ",
 'alster_family_house':"pixel art, a quiet narrow street at night with a house whose shutters glow with moving lamplight, an open door with a sack on the step, ",
 'white_wells':"pixel art, desert dunes at night under stars, an old stone well half buried in sand, a pale sand horizon, ",
 'spire_cathedral':"pixel art, the nave of a cathedral inside a tall spire, incense smoke, huge sealed doors behind, rows of iron lamps, dark stone, ",
 'reliquary_chair_chapel':"pixel art, a small chapel with a chair with straps, a porcelain mask on a hook, a bowl of white paint, chipped saints on the walls, ",
 'kindly_hill':"pixel art, a green hill rising out of a grey fen, three gnarled fever trees at its foot, a grey fence line where the green stops, ",
 'white_anchorage_hulls':"pixel art, a tide-line camp of beached hulls roofed with sails, a single lantern flame carried on a pole, grey sand, dusk, ",
 'sleepers_face':"pixel art, a huge weathered stone face half buried in desert sand, a white sky, glaring heat, one shade, ",
 'hollow_court_chamber':"pixel art, a carved stone chamber with a black altar, ash-ink spirals on the floor and walls, kneeling ring marked in the dust, cold light, ",
 'ashen_quarter_archive':"pixel art, a sealed archive door standing open on shelves of scrolls and ledgers, dust, a single lamp, ",
 'reliquary_chartkeeper_chapel':"pixel art, a chapel whose saints are chipped off the walls, a long table with rolled charts and maps, a lamp, ",
 'hollow_shore_battlefield':"pixel art, a grey sand shore with reflections on wet sand, a dark tear standing over the water, scattered broken weapons, ",
 'alster_undercroft':"pixel art, a flooded undercroft, waist-deep dark water, rot heaps, a chute opening in the ceiling, dim green light, ",
 'lark_wreck':"pixel art, a ship wrecked on rocks in a storm at dusk, a torn sail, bruise-coloured sky, big waves, ",
 'saltmouth_lantern_alleys':"pixel art, narrow alleys of a bazaar, strings of coloured lanterns, shuttered stalls, mysterious signs of symbols only, night, ",
 'ashen_quarter_spire_stair':"pixel art, an awning by a gate where three judges' chairs are set, a long stair going up to a dark spire, grey ash, ",
 'hollow_court':"pixel art, a stair that splits three ways inside a dark carved hall, braziers on the landings, ash smoke, ",
 'highhearth_great_hearth':"pixel art, a giants' moot-hall, an enormous hearth with a roaring fire, a huge table with high stools, ",
 'white_anchorage_chapel':"pixel art, a seaside chapel built from a ship's stern, a graveyard of white stones on a glass-like strand, dusk, ",
 'ashen_quarter_gate':"pixel art, the gate of a burnt town at the foot of a dark spire, ash-black walls, a flat plain of ash in front, ",
 'spire_hall_of_records':"pixel art, a hall of records, endless shelves of parchment receding into the dark, a long desk, a lamp, ",
}
if __name__=='__main__':
    st=sys.argv[1]; queue=[(k,3,240,100,STORY[k]+B) for k in STORY]; active=[]; done=[]
    def save(): json.dump(dict(done=done,active=active),open(st,'w'),indent=1)
    while queue or active:
        while queue and len(active)<6:
            k,s,w,h,desc=queue.pop(0)
            r=A.call('create_image_pixen',{"description":desc,"width":w,"height":h,"no_background":False,"view":"side","outline":"single color black outline","detail":"medium detail","seed":s})
            active.append(dict(k=k,s=s,job=A.field(r,'job_id'),raw='' if A.field(r,'job_id') else r[:200])); save()
        time.sleep(20)
        for a in list(active):
            if not a['job']: print('FAILED',a); active.remove(a); continue
            if A.field(A.call('get_image',{"job_id":a['job']}),'status')=='completed':
                subprocess.run(A.CLI+['get_image',json.dumps({"job_id":a['job']}),'--save',f"art/pixellab-backgrounds/batchB/raw/{a['k']}_s{a['s']}"],capture_output=True,text=True)
                done.append((a['k'],a['s'])); active.remove(a)
        save()
    print('ALL DONE',len(done))
