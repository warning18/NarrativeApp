"""Screen-background pilots (14 generations, create_image_pixen): life choices (2 bands 240x100), character choice (2 plates 180x320), expeditions (3 zone bands 240x72), 2 seeds each.
python3 art/pixellab-backgrounds/screens_gen.py <state.json> [key,key] [seed,seed]   (repo root)"""
import json, subprocess, time, sys
sys.path.insert(0,'art/pixellab-backgrounds')
import round3_gen as R
B="16-bit pixel art, flat colour with a dark ink outline, muted warm palette, wide low scene, no characters, no text, no letters, no UI"
PL=", muted palette, flat colour with a dark ink outline, light from the top-left, calm, a mostly empty centre where cards will sit, no characters, no people, no text, no glow"
P={
 'life_age6_sparrow':("pixel art, a rope-walk, a long covered yard where rope is made, long strands of rope stretched between posts under a low roof, rain falling outside, wet cobbles, a small stool, grey-brown evening light, "+B,240,100),
 'life_age16_board':("pixel art, the front of a small family house on a winter night, snow on the roof and the yard, one lit window with warm yellow light, a low wooden door, long blue shadows, "+B,240,100),
 'cc_race':("pixel art, the common room of a road-house at night, a long empty wooden table with five different empty chairs, a tall stool, a stone seat, a carved elegant chair, a heavy bench and a dark iron chair, candles and a fire in the hearth, stone walls"+PL,180,320),
 'cc_calling':("pixel art, an armoury and study wall, a rack of swords and a shield, a bow on a peg, a pair of daggers, a small altar with a holy symbol, a shelf of books and a staff, warm lamplight, flagstone floor"+PL,180,320),
 'exp_lantern_docks':("pixel art, a harbour dock at dusk, wooden piers and moored boats, many lit paper lanterns strung along posts, crates and barrels, dark water, a warm glow, "+B,240,72),
 'exp_cinder_row':("pixel art, a burnt street in an ash-covered quarter, charred timber houses, grey ash drifting, a hanging iron sign, embers glowing in a doorway, "+B,240,72),
 'exp_changeling_fen':("pixel art, a misty fen at dawn, still dark pools between reed beds, a crooked wooden boardwalk, a leaning bell post, pale mist, "+B,240,72),
}
if __name__=='__main__':
    st=sys.argv[1]; keys=sys.argv[2].split(',') if len(sys.argv)>2 and sys.argv[2] else list(P); seeds=[int(x) for x in sys.argv[3].split(',')] if len(sys.argv)>3 else [11,12]
    queue=[(k,s) for k in keys for s in seeds]; active=[]; done=[]
    def save(): json.dump(dict(done=done,active=active),open(st,'w'),indent=1)
    while queue or active:
        while queue and len(active)<6:
            k,s=queue.pop(0); d,w,h=P[k]
            r=R.call('create_image_pixen',{"description":d,"width":w,"height":h,"no_background":False,"view":"side","outline":"single color black outline","detail":"medium detail","seed":s})
            active.append(dict(k=k,s=s,job=R.field(r,'job_id'),raw='' if R.field(r,'job_id') else r[:200])); save()
        time.sleep(20)
        for a in list(active):
            if not a['job']: print('FAILED',a); active.remove(a); continue
            if R.field(R.call('get_image',{"job_id":a['job']}),'status')=='completed':
                subprocess.run(R.CLI+['get_image',json.dumps({"job_id":a['job']}),'--save',f"art/pixellab-backgrounds/screens/raw/{a['k']}_s{a['s']}"],capture_output=True,text=True)
                done.append((a['k'],a['s'])); active.remove(a)
        save()
    print('ALL DONE',len(done))
