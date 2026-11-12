"""The Tower's three peaceful floors, two seeds each (create_image_pixen 180x320, 1 generation each): parley, the Stair-Chandler's shop, the Tally-Clerk's bargain.
python3 art/pixellab-backgrounds/peaceful_gen.py <state.json>   (repo root)"""
import json, subprocess, time, sys
sys.path.insert(0,'art/pixellab-backgrounds')
import round3_gen as R
T="pixel art, inside a tall round stone tower, "
END=", muted palette, flat colour with a dark ink outline, light from the top-left, empty floor in the lower half where cards will sit, calm, no characters, no text, no glow"
P={
 'tower_parley':T+"a stair landing where the stone staircase going up is barred by a heavy iron gate with a lowered portcullis and a thick wooden bar, a worn flat landing in front with a faded rug where two people could stand and talk, iron lanterns on the walls"+END,
 'tower_shop':T+"a small landing with a lit wooden door set in the wall and warm light spilling out, shelves of candles, lamps and lanterns, bundles of wicks and blocks of wax on a counter, one hanging lamp, stacked crates"+END,
 'tower_bargain':T+"a cold stone alcove like a shrine with a high ledger desk, an open ledger book, an inkwell and quill, an abacus, a rack of tally sticks, a brass balance scale, a single pale candle, cold bluish light, something unwholesome about it"+END,
}
if __name__=='__main__':
    st=sys.argv[1]; active=[]; done=[]
    for k in P:
        for s in (11,12):
            r=R.call('create_image_pixen',{"description":P[k],"width":180,"height":320,"no_background":False,"view":"side","outline":"single color black outline","detail":"medium detail","seed":s})
            active.append(dict(k=k,s=s,job=R.field(r,'job_id')))
    json.dump(active,open(st,'w'))
    while active:
        time.sleep(20)
        for a in list(active):
            if not a['job']: print('FAILED',a); active.remove(a); continue
            if R.field(R.call('get_image',{"job_id":a['job']}),'status')=='completed':
                subprocess.run(R.CLI+['get_image',json.dumps({"job_id":a['job']}),'--save',f"art/pixellab-backgrounds/peaceful/raw/{a['k']}_s{a['s']}"],capture_output=True,text=True)
                done.append((a['k'],a['s'])); active.remove(a)
    print('DONE',done)
