"""Parallax pilot, desert: four layers (sky 160x52 opaque; far 192x24, mid 192x20, near 192x24 transparent strips), pixflux with the dunes fight plate as the forced palette.
python3 art/pixellab-parallax/desert_gen.py <state.json> [seed]   (repo root)"""
import json, subprocess, time, sys, base64
sys.path.insert(0,'art/pixellab-backgrounds')
import round3_gen as R
END=", flat colour, hand-drawn pixel art, muted warm palette, dark ink outline only on the top edge, no characters, no text, no sun"
L={
 'sky':("pixel art, a warm desert sky at late afternoon, soft horizontal bands from deep violet-brown at the top to pale cream-gold at the horizon, a few thin streaks of cloud, nothing else"+END,160,52,False),
 'far':("pixel art, a seamless horizontal strip of distant flat-topped red-brown mesas and rocky buttes along a low hazy horizon, transparent sky above, nothing below the ridge line, tileable left to right"+END,192,24,True),
 'far2':("pixel art, a seamless horizontal strip of tall red-brown flat-topped mesas and sandstone buttes with steep sides and shaded cliffs filling most of the strip height, hazy, transparent sky above, tileable left to right"+END,192,24,True),
 'mid':("pixel art, a seamless horizontal strip of rolling warm sand dunes with soft ridges and light on the top edge, transparent above the ridge, tileable left to right"+END,192,20,True),
 'mid2':("pixel art, a seamless horizontal strip of rolling orange-ochre sand dunes, each dune with a bright lit top edge and a deep shaded orange-brown side, strong contrast, transparent above the ridge, tileable left to right"+END,192,20,True),
 'near':("pixel art, a seamless horizontal strip of darker foreground sand dunes with a few small rocks and dry grass tufts on the ridge, transparent above the ridge, tileable left to right"+END,192,24,True),
}
if __name__=='__main__':
    st=sys.argv[1]; seed=int(sys.argv[2]) if len(sys.argv)>2 else 5
    keys=sys.argv[3].split(',') if len(sys.argv)>3 else list(L)
    pal=base64.b64encode(open('assets/visuals/fight_plates/dunes.png','rb').read()).decode(); active=[]
    for k in keys:
        d,w,h,nb=L[k]
        r=R.call('create_image_pixflux',{"description":d,"width":w,"height":h,"no_background":nb,"view":"side","outline":"selective outline","detail":"medium detail","color_image_base64":pal,"seed":seed})
        active.append(dict(k=k,job=R.field(r,'job_id'),raw=r[:200] if not R.field(r,'job_id') else ''))
    json.dump(active,open(st,'w'),indent=1); done=[]
    while active:
        time.sleep(15)
        for a in list(active):
            if not a['job']: print('FAILED',a); active.remove(a); continue
            if R.field(R.call('get_image',{"job_id":a['job']}),'status')=='completed':
                subprocess.run(R.CLI+['get_image',json.dumps({"job_id":a['job']}),'--save',f"art/pixellab-parallax/raw/desert_{a['k']}_s{seed}"],capture_output=True,text=True)
                done.append(a['k']); active.remove(a)
    print('DONE',done)
