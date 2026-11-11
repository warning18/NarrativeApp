"""Backgrounds batch A: 9 fight stages x 2 seeds (180x320) + the 12 most-used story bands x 1 seed (240x100). create_image_pixen, 1 generation each.
python3 art/pixellab-backgrounds/batchA_gen.py <state.json>   (repo root)"""
import json, subprocess, time, sys, re
CLI=['python3','tool/pixellab_client.py','call']
S="16-bit pixel art, chibi dark medieval fantasy, flat colour with a dark ink outline, muted warm palette, light from the top-left, empty ground in the lower half for fighters to stand on, mostly calm so UI text stays legible, no text, no characters, no UI, no glow"
B="16-bit pixel art, flat colour with a dark ink outline, muted warm palette, wide low scene, no characters, no text, no letters, no UI"
FIGHT={
 'fight_saltflats':"pixel art, white salt flats at dusk, cracked pale salt crust, a few dry dead shrubs, a distant low red mesa, hazy pink sky, flat ground in the lower half, "+S,
 'fight_waves':"pixel art, open grey-blue sea with long swells under an overcast sky, whitecaps, a low horizon, calm flat water in the lower half, "+S,
 'fight_ash':"pixel art, an ash plain, grey drifts of ash, black dead tree stumps, a red glow on the horizon, flat grey ground in the lower half, "+S,
 'fight_glass':"pixel art, a field of fused glass, shimmering green-blue glass shards, mirror-like flat ground reflecting a pale sky, "+S,
 'fight_cityroad':"pixel art, a cobbled town road between tall crooked houses at dusk, lantern posts, an empty road in front, "+S,
 'fight_shipdeck':"pixel art, the wooden deck of a ship seen from the side, planks, coiled ropes, masts and rigging, a night sea beyond the rail, empty deck in front, "+S,
 'fight_oasis':"pixel art, a desert oasis, a clear pool with palm trees, flat sand around it, warm hazy sky, "+S,
 'fight_caravanroad':"pixel art, a dusty caravan road through dry hills, wagon ruts, scrub bushes, flat packed earth in the lower half, "+S,
 'fight_pass':"pixel art, a mountain pass between rocky walls, patches of snow, flat stony ground in the lower half, a pale sky, "+S,
}
STORY={
 'reliquary_quarter':"pixel art, the gate of the Reliquary Quarter, an arch of ash-dark brick with only a stump of wall on each side, white paint marks, frost on the cobbles, pale smoke, cold grey light, "+B,
 'greyhithe':"pixel art, a fishing village on a grey shore, crooked houses on grey sand, nets drying on poles, grey water, a dark tear in the sky far across the water, "+B,
 'wracks_end':"pixel art, a wreckers' village clinging to a cliff above a stair down to the sea, wreck timbers, weed drying on racks, tarred huts, stormy light, "+B,
 'rimewell':"pixel art, a pilgrims' halt, a stone well covered in frost, a small chapel with a bell, pale frost on the stones, cold light, "+B,
 'hollow_shore':"pixel art, grey sand and grey water, a tall dark rift standing open across the water like a door, a bleak shore, "+B,
 'saltmouth_landward_gate':"pixel art, a salt town's landward gate where the desert meets the sea, whitewashed walls, dunes behind, a haze, "+B,
 'ashen_quarter_ash_market':"pixel art, an ash market square, burnt stalls, grey ash falling, hanging lanterns, a small shrine, "+B,
 'white_anchorage_quay':"pixel art, a harbour of hulls hauled up the sand and roofed with sails, a chapel made from a ship's stern, a harbour wall of anchors, "+B,
 'saltmouth_card_row':"pixel art, a dockside row, barrels used as card tables, lamps strung overhead, wooden planks, evening, "+B,
 'drowned_cloister_stair':"pixel art, a drowned cloister, vaulted arches knee-deep in black water, candles on every ledge above the tide line, "+B,
 'candlehold_gates':"pixel art, a white cliff city rising in steps from a harbour, white walls and towers, a great lantern burning at the top, tide-blue banners, "+B,
 'saltmouth_tern_row':"pixel art, a narrow salt-scoured quarter hung with lit paper boats, a footbridge over dark water, lanterns, dusk, "+B,
}
def call(tool,args):
    for _ in range(40):
        r=subprocess.run(CLI+[tool,json.dumps(args)],capture_output=True,text=True).stdout
        if 'rate limit' in r or 'concurrency' in r.lower(): time.sleep(20); continue
        return r
    return r
def field(r,k):
    m=re.search(r'^'+k+r': (\S+)',r,re.M); return m.group(1) if m else None
if __name__=='__main__':
    st=sys.argv[1]
    queue=[(k,s,180,320,FIGHT[k]) for k in FIGHT for s in (11,12)]+[(k,3,240,100,STORY[k]) for k in STORY]
    active=[]; done=[]
    def save(): json.dump(dict(done=done,active=active),open(st,'w'),indent=1)
    while queue or active:
        while queue and len(active)<6:
            k,s,w,h,desc=queue.pop(0)
            r=call('create_image_pixen',{"description":desc,"width":w,"height":h,"no_background":False,"view":"side","outline":"single color black outline","detail":"medium detail","seed":s})
            active.append(dict(k=k,s=s,job=field(r,'job_id'),raw='' if field(r,'job_id') else r[:200])); save()
        time.sleep(20)
        for a in list(active):
            if not a['job']: print('FAILED',a); active.remove(a); continue
            if field(call('get_image',{"job_id":a['job']}),'status')=='completed':
                subprocess.run(CLI+['get_image',json.dumps({"job_id":a['job']}),'--save',f"art/pixellab-backgrounds/batchA/raw/{a['k']}_s{a['s']}"],capture_output=True,text=True)
                done.append((a['k'],a['s'])); active.remove(a)
        save()
    print('ALL DONE',len(done))
