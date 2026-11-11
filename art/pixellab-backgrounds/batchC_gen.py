"""Backgrounds batch C: the last 27 story bands (240x100, seed 3, 1 generation each). python3 art/pixellab-backgrounds/batchC_gen.py <state.json>"""
import json, subprocess, time, sys
sys.path.insert(0,'art/pixellab-backgrounds')
import batchA_gen as A
B=A.B
STORY={
 'dead_heart':"pixel art, a hollow cavern in the heart of a dead city, a pulsing dark core of violet light on the floor, broken pillars, ",
 'reliquary_hammer_chapel':"pixel art, a ruined forge-chapel, broken hammers hung on the walls, one empty hook for the master hammer, cold anvil, ",
 'alster_stone_bridge':"pixel art, a stone bridge over a fast river, white cloth armbands knotted on the rail, a barricade of crates on the bridge, ",
 'ashen_quarter_cinder_row':"pixel art, a street of dark forges, one forge relit with orange glow, cold anvils, soot-black walls, ",
 'emberwick_cold_forge':"pixel art, an unlit forge, a cold anvil, a stool beside it, tools hanging in order, a smoke hole in the roof, ",
 'emberwick_widows_house':"pixel art, a small slag-block house, a hammer hung on the lintel, a hearth with a low fire, a quiet table, ",
 'akagiri_tetsu_forge':"pixel art, a forge in a hot-spring village, a glowing furnace, horn-shaped tools, red steam, wooden beams, ",
 'rimewell_road_keepers_house':"pixel art, a road keeper's house at night, an open back window, frost on the roof, a lamp in the doorway, ",
 'rimewell_chapel':"pixel art, a small chapel with a bell tower, frost on the stones, a bell hung in the open, a carved list of names on the wall, ",
 'white_anchorage_stern':"pixel art, a wrecked flagship's stern on a glass-like strand, off a point, grey light, broken gilded rails, ",
 'reliquary_muniment_room':"pixel art, an underground records room behind a seal with a skull burning in it, stacked chests and ledgers, ",
 'drowned_cloister_cache':"pixel art, a dry cell behind a drowned door, oilcloth bundles on shelves, a heavy lock, a single lantern, ",
 'white_anchorage_impound':"pixel art, a hull hauled above the tide line roofed with its own sail, a sealed hatch, a wooden deck, grey sea, ",
 'saltmouth_green_door':"pixel art, a bare room with a single chair facing a green door, a folded note on the chair, plain whitewashed walls, ",
 'the_crossing':"pixel art, open sea at night after leaving a harbour, a ship's wake, the lights of a town fading in the distance, ",
 'spire_of_judgment':"pixel art, slate roofs of a gothic cloister with tall spires in a wind, a night sky, ",
 'saltmouth_landward_warehouse':"pixel art, the inside of a warehouse, crates and barrels in shadow, a lantern, a long table, ",
 'reliquary_tribunal_chapel':"pixel art, a chapel with a bench of judges in violet drapes, a chained prisoner's stool, tall candles, ",
 'reliquary_parish_chapel':"pixel art, a chapel with shattered stained glass, coloured shards on the floor, torn pews, ",
 'beyond_the_tear':"pixel art, a vast dark void with a great pale rift, floating shards, a violet glow, a stone ledge in front, ",
 'wracks_end_lamp_room':"pixel art, a lighthouse lamp room, a wick lamp, a green-tinted mirror, a log book on a table, fog at the window, ",
 'white_anchorage_vault':"pixel art, a hidden cellar vault under a chandlery, stacked crates, a heavy door, hanging lamps, ",
 'white_anchorage_chandlery':"pixel art, a chandlery shop in a harbour, shelves of salves in flasks, reforged blades on racks, rope coils, ",
 'white_fleet_grave':"pixel art, a flagship wreck settled into a glass-like sea floor, broken masts, dusk, a still sea, ",
 'candlehold_lantern_hall':"pixel art, the top of a grand stair leading to a hall with a great lantern hanging, an empty throne far back, ",
 'cove_sail_loft':"pixel art, a big sail loft, rafters hung with banners, a long table with maps, lanterns, ",
 'saltmouth_tide_cellar':"pixel art, a damp cellar by the tide, water lines on stone walls, barrels, a low lamp, a fence's counter, ",
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
                subprocess.run(A.CLI+['get_image',json.dumps({"job_id":a['job']}),'--save',f"art/pixellab-backgrounds/batchC/raw/{a['k']}_s{a['s']}"],capture_output=True,text=True)
                done.append((a['k'],a['s'])); active.remove(a)
        save()
    print('ALL DONE',len(done))
