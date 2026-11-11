"""Option 2 (B12): create_image_pixflux, init = the A12 plate (324x364), forced palette = the 12 colours; 3 tries. python3 art/pixellab-casino/b12_gen.py <state.json>"""
import json, subprocess, time, base64, sys, re
CLI=['python3','tool/pixellab_client.py','call']
D="top-down pixel art plan of a gilded gambling house, restrained palette, dark wood plank floor, a deep red carpet runner to a brass roulette wheel, round card tables with one green felt, candle light, a long dark wood bar, small rooms with deep red rugs and brass strongboxes, thick uniform 1 px black ink outline on walls and furniture, clean flat colour, light from the top-left, no noise, no text, no glow, chibi dark medieval fantasy"
def call(tool,args):
    for _ in range(40):
        r=subprocess.run(CLI+[tool,json.dumps(args)],capture_output=True,text=True).stdout
        if 'rate limit' in r: time.sleep(20); continue
        return r
    return r
def field(r,k):
    m=re.search(r'^'+k+r': (\S+)',r,re.M); return m.group(1) if m else None
if __name__=='__main__':
    st=sys.argv[1]; b=base64.b64encode(open('art/pixellab-casino/raw/A12_small_rgb.png','rb').read()).decode(); pal=base64.b64encode(open('art/pixellab-casino/raw/palette12.png','rb').read()).decode()
    jobs=[]
    for v,strength in ((1,90),(2,130),(3,170)):
        r=call('create_image_pixflux',{"description":D,"width":324,"height":364,"no_background":False,"view":"high top-down","outline":"single color black outline","detail":"medium detail","shading":"flat shading","init_image_base64":b,"init_image_strength":strength,"color_image_base64":pal,"seed":70+v})
        jobs.append(dict(v=v,strength=strength,job=field(r,'job_id'),raw='' if field(r,'job_id') else r[:300])); json.dump(jobs,open(st,'w'),indent=1)
    pend=[j for j in jobs if j['job']]
    while pend:
        time.sleep(20)
        for j in list(pend):
            if field(call('get_image',{"job_id":j['job']}),'status')=='completed':
                subprocess.run(CLI+['get_image',json.dumps({"job_id":j['job']}),'--save',f"art/pixellab-casino/raw/b12_v{j['v']}"],capture_output=True,text=True); pend.remove(j)
    print('ALL DONE')
