"""Approach B: painted pixel plate, img2img from today's layout plate (create_image_pixflux, 1 generation each).
python3 art/pixellab-maps-pixel/b_gen.py <state.json>   (repo root)"""
import json, subprocess, time, base64, sys, os, re
CLI=['python3','tool/pixellab_client.py','call']
S="top-down pixel art map plate, chibi dark medieval fantasy, thick dark ink outlines, flat colour with raw pixel clusters, muted warm palette with one ember accent, light from the top-left, no text, no letters, no UI, no glow"
JOBS={
 'ashen':("guide_ashen_quarter_v1.png",(360,352),"top-down plan of a burnt walled town: burnt roofs with soot and charred beams, glowing embers, rubble and ash heaps on the ground, cobbled avenues, a few standing lanterns, a stone wall with round towers and gates, "+S),
 'casino':("guide_casino_v1.png",(324,364),"top-down plan of a gilded gambling house: dark wood plank floor, a red carpet runner to a gold roulette wheel, round card and dice tables with green felt and candles, chandeliers, a long bar, small rooms with plush rugs and gold strongboxes, stone walls, "+S)}
STR=[(1,120),(2,80),(3,170)]   # (variant, init_image_strength)
def call(tool,args):
    for _ in range(40):
        r=subprocess.run(CLI+[tool,json.dumps(args)],capture_output=True,text=True).stdout
        if 'rate limit' in r: time.sleep(20); continue
        return r
    return r
def field(r,k):
    m=re.search(r'^'+k+r': (\S+)',r,re.M); return m.group(1) if m else None
if __name__=='__main__':
    st=sys.argv[1]; jobs=[]
    for k,(guide,(w,h),desc) in JOBS.items():
        b=base64.b64encode(open('art/pixellab-maps-pixel/'+guide,'rb').read()).decode()
        for v,strength in STR:
            r=call('create_image_pixflux',{"description":desc,"width":w,"height":h,"no_background":False,"view":"high top-down","outline":"single color black outline","detail":"medium detail","init_image_base64":b,"init_image_strength":strength,"seed":40+v})
            jobs.append(dict(k=k,v=v,strength=strength,job=field(r,'job_id'),raw='' if field(r,'job_id') else r[:300])); json.dump(jobs,open(st,'w'),indent=1)
    pend=[j for j in jobs if j['job']]
    while pend:
        time.sleep(20)
        for j in list(pend):
            r=call('get_image',{"job_id":j['job']})
            if field(r,'status')=='completed':
                subprocess.run(CLI+['get_image',json.dumps({"job_id":j['job']}),'--save',f"art/pixellab-maps-pixel/b/raw/{j['k']}_v{j['v']}"],capture_output=True,text=True); pend.remove(j)
    print('ALL DONE',len(jobs))
