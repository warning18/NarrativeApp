"""Backgrounds round 3: the Tower's boss, warden and end plates and seven fight stages, two seeds each (create_image_pixen, 1 generation each).
python3 art/pixellab-backgrounds/round3_gen.py <state.json>   (repo root)"""
import json, subprocess, time, sys, re, os
CLI=['python3','tool/pixellab_client.py','call']
S="16-bit pixel art, chibi dark medieval fantasy, flat colour with a dark ink outline, muted warm palette, light from the top-left, empty ground in the lower half for fighters to stand on, mostly calm so UI text stays legible, no text, no characters, no UI, no glow"
T="pixel art, inside a tall round stone tower, "
PLATES={
 'tower_boss10':(T+"a grand hall of the Inquisition at the tenth floor, tall dark red banners hanging from stone pillars, a long red carpet, iron candelabra, cold light from high windows"),
 'tower_boss20':(T+"a war room at the twentieth floor, cracked stone walls, torn grey banners, a map table pushed aside, broken weapon racks, a brazier with ember glow"),
 'tower_boss30':(T+"the summit chamber at the thirtieth floor, black stone split by glowing violet fissures, shards floating in the dark air, a broken dome open to a starless sky"),
 'tower_ward5':(T+"a flooded lower cistern with grated drains, dripping green-stained walls, hanging lanterns, shallow dark water, planks as a floor"),
 'tower_ward15':(T+"a bell chamber with a great bronze bell on a thick wooden frame, iron chains, narrow arched openings, pale light, stone floor"),
 'tower_ward25':(T+"a ruined glass chapel, tall shattered stained glass windows with coloured shards, rows of broken pews pushed to the walls, cold moonlight, stone floor"),
 'tower_win':(T+"the open top of the tower at dawn, a wide broken parapet looking over a pink and gold sky, a faint far horizon, stone floor, calm and hopeful"),
 'tower_lose':(T+"a small bare stone cell, an extinguished brazier with grey ashes, one narrow dark window, cold dim light, bare floor, silent and final"),
 'fight_fields':("pixel art, open farmland horizon, golden fields and a low hedge line under a pale sky, flat earth in the lower half, a distant hill, "+S),
 'fight_ford':("pixel art, a shallow river ford crossing a country road, flat stones across the water, reeds on the banks, flat ground in the lower half, "+S),
 'fight_burnt':("pixel art, burnt fields after a fire, black stubble and grey ash, a few charred fence posts, smoke far away, flat dark ground, "+S),
 'fight_cliffs':("pixel art, a sea-cliff top, rocky edge dropping to grey sea far below, wind-bent grass, flat rocky ground in the lower half, "+S),
 'fight_terraces':("pixel art, stepped hillside terraces with stone walls and dry vines, a village roof far away, flat dirt ground in the lower half, "+S),
 'fight_reeds':("pixel art, a reed marsh, tall reeds and still dark water pools, mist, boardwalk planks as flat ground in the lower half, "+S),
 'fight_hall':("pixel art, inside a stone hall, tall pillars and a long dark wall with narrow windows, flagstone floor, hanging iron lamps, empty floor in front, "+S),
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
    st=sys.argv[1]; queue=[(k,s) for k in PLATES for s in (11,12)]; active=[]; done=[]
    def save(): json.dump(dict(done=done,active=active),open(st,'w'),indent=1)
    while queue or active:
        while queue and len(active)<6:
            k,s=queue.pop(0)
            r=call('create_image_pixen',{"description":PLATES[k],"width":180,"height":320,"no_background":False,"view":"side","outline":"single color black outline","detail":"medium detail","seed":s})
            active.append(dict(k=k,s=s,job=field(r,'job_id'),raw='' if field(r,'job_id') else r[:200])); save()
        time.sleep(20)
        for a in list(active):
            if not a['job']: print('FAILED',a); active.remove(a); continue
            if field(call('get_image',{"job_id":a['job']}),'status')=='completed':
                subprocess.run(CLI+['get_image',json.dumps({"job_id":a['job']}),'--save',f"art/pixellab-backgrounds/round3/raw/{a['k']}_s{a['s']}"],capture_output=True,text=True)
                done.append((a['k'],a['s'])); active.remove(a)
        save()
    print('ALL DONE',len(done))
