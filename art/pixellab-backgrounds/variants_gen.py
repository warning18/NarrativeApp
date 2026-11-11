"""Stage variants for places whose band clashes with the shared stage plate (6 generations, one seed each, 180x320 like the cityRoad variants).
python3 art/pixellab-backgrounds/variants_gen.py <state.json> [seed]"""
import json, subprocess, time, sys
sys.path.insert(0,'art/pixellab-backgrounds')
import batchA_gen as A
S=A.S
V={
 'fight_glass_greyhithe':"pixel art, a field of fused glass on grey sand at brown-orange dusk, glassy shards in warm amber and brown, a flat mirror-like ground reflecting an orange dusk sky, a dark thin rift far away, "+S,
 'fight_ash_emberwick':"pixel art, an ash plain lit by a warm orange kiln glow, grey ash drifts with orange light on them, dark kiln chimney silhouettes far away, black dead stumps, flat ground in the lower half, "+S,
 'fight_terraces_akagiri':"pixel art, stepped terraces on a mountainside in a red steam haze, red-brown earth, rust-red mist drifting between the steps, flat ground in the lower half, "+S,
 'fight_waves_crossing':"pixel art, open dark sea at night, long dark swells with pale moonlit crests, a low horizon, stars, calm flat water in the lower half, "+S,
 'fight_hall_wet':"pixel art, a vaulted stone hall flooded with black water, wet dark stone arches, candles on ledges above the waterline, shallow dark water on the floor, "+S,
 'fight_cityroad_whiteanchorage':"pixel art, a harbour road of hulls hauled up the sand and roofed with patched sails, a harbour wall of rusted anchors, grey sand road, an empty road in front, "+S,
}
if __name__=='__main__':
    st=sys.argv[1]; seed=int(sys.argv[2]) if len(sys.argv)>2 else 11
    keys=sys.argv[3].split(',') if len(sys.argv)>3 else list(V)
    active=[]; done=[]
    for k in keys:
        r=A.call('create_image_pixen',{"description":V[k],"width":180,"height":320,"no_background":False,"view":"side","outline":"single color black outline","detail":"medium detail","seed":seed})
        active.append(dict(k=k,s=seed,job=A.field(r,'job_id'),raw='' if A.field(r,'job_id') else r[:200]))
    json.dump(dict(done=done,active=active),open(st,'w'),indent=1)
    while active:
        time.sleep(20)
        for a in list(active):
            if not a['job']: print('FAILED',a); active.remove(a); continue
            if A.field(A.call('get_image',{"job_id":a['job']}),'status')=='completed':
                subprocess.run(A.CLI+['get_image',json.dumps({"job_id":a['job']}),'--save',f"art/pixellab-backgrounds/redos/raw/{a['k']}_s{a['s']}"],capture_output=True,text=True)
                done.append((a['k'],a['s'])); active.remove(a)
    print('ALL DONE',done)
