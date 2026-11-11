"""Redos (11 generations): 8 story bands redone and 3 cityRoad regional variants, each generated from its pair (the paired stage's materials, palette and hour in the words).
python3 art/pixellab-backgrounds/redos_gen.py <state.json>"""
import json, subprocess, time, sys
sys.path.insert(0,'art/pixellab-backgrounds')
import batchA_gen as A
B=A.B+", full bleed, no frame, no vignette, no rounded corners, no signs, no writing"
S=A.S
BANDS={
 'hollow_shore':"pixel art, a bleak grey sand shore with a wet mirror-like beach, grey water, across the water a tall narrow dark rift standing open in the sky like a door, a few glassy shards on the sand, ",
 'saltmouth_landward_gate':"pixel art, a sun-bleached whitewashed salt-port gate with square towers and flat roofs, dunes behind, a bright haze, an empty road in front, ",
 'hollow_shore_battlefield':"pixel art, a grey sand shore after a battle, broken spears and shields stuck in the sand, torn banners, wet reflections, a dark tear standing over the water, ",
 'saltmouth_lantern_alleys':"pixel art, narrow alleys of a night bazaar, strings of coloured paper lanterns, shuttered plain stalls, whitewashed walls, ",
 'spire_cathedral':"pixel art, the nave of a grey gothic cathedral inside a spire, thin incense smoke, rows of iron lamps, plain stone floor, huge sealed doors far back, ",
 'the_crossing':"pixel art, a sailing ship with white square sails and no funnel leaving a harbour at night, a wake on dark water, the lights of a whitewashed town fading behind, ",
 'white_anchorage_stern':"pixel art, only the stern of a wrecked flagship rising out of grey glass-like sand, a carved stern gallery with windows and a broken gilded rail, seen close, dusk, ",
 'rimewell_chapel':"pixel art, a small stone chapel with a bell tower in a frosted pilgrims' halt, frost on the stones, a bell hung in the open, cold pale light, ",
}
CITY={
 'fight_cityroad_saltmouth':"pixel art, a sun-bleached whitewashed salt-port street, flat-roofed white and sand-coloured houses with blue shutters, canvas awnings, bright white haze, an empty road in front, "+S,
 'fight_cityroad_frost':"pixel art, a cold grey stone street of a frosted holy quarter, steep grey houses, frost on the cobbles, pale smoke, a lantern with white light, an empty road in front, "+S,
 'fight_cityroad_candlehold':"pixel art, a stepped white stone street climbing a cliff city, white walls, tide-blue banners, a great lantern burning far above, an empty street in front, "+S,
}
if __name__=='__main__':
    st=sys.argv[1]
    queue=[(k,7,240,100,BANDS[k]+B) for k in BANDS]+[(k,11,180,320,CITY[k]) for k in CITY]; active=[]; done=[]
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
                subprocess.run(A.CLI+['get_image',json.dumps({"job_id":a['job']}),'--save',f"art/pixellab-backgrounds/redos/raw/{a['k']}_s{a['s']}"],capture_output=True,text=True)
                done.append((a['k'],a['s'])); active.remove(a)
        save()
    print('ALL DONE',len(done))
