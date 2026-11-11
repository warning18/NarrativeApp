"""Banners pilot in the new look: pixflux img2img from today's clan standard (64x128). python3 art/pixellab-banners-new/gen.py <state.json> [seed]"""
import json, subprocess, time, sys, base64, io
sys.path.insert(0,'art/pixellab-backgrounds')
import batchA_gen as A
from PIL import Image
BASE="pixel art hanging clan war standard, chunky dark medieval fantasy game style, 1 px black outline, flat colours with a lit top-left edge, hand-stitched look, "
KEEP={
 'clan_dominion':"black cloth with a cream padlock emblem with a blue eye in its keyhole above a cream square seal, blue top band and blue hem trim, ",
 'clan_oni':"black cloth with a cream horned oni demon mask with two curved horns, fangs and orange eyes above a cream bowl with an orange gem, orange top band and orange hem trim, ",
 'clan_crows':"black cloth with a cream anchor above a cream round shield with a red gem, red top band and red hem trim, ",
 'clan_mire':"black cloth with a cream leaf above cream curving wave shapes with a green gem, teal green top band and green hem trim, ",
}
DIR={'a':"faithful redraw, same layout and emblem, brass rod with two gold finials, zig-zag hem, no text",
     'b':"bolder: heavy rod and finials of dark old iron with rivets, a torn cloth hem weighted with small iron weights, the emblem looks stitched onto the cloth, no text"}
def b64(im): b=io.BytesIO(); im.save(b,'PNG'); return base64.b64encode(b.getvalue()).decode()
if __name__=='__main__':
    st=sys.argv[1]; seed=int(sys.argv[2]) if len(sys.argv)>2 else 7
    keys=sys.argv[3].split(',') if len(sys.argv)>3 else [f'{k}_{d}' for k in KEEP for d in DIR]
    active=[]
    for k in keys:
        base,d=k.rsplit('_',1)
        init=Image.open(f'assets/visuals/banners/{base}.png').convert('RGBA')
        r=A.call('create_image_pixflux',{"description":BASE+KEEP[base]+DIR[d],"width":64,"height":128,"no_background":True,"init_image_base64":b64(init),"init_image_strength":(int(sys.argv[4]) if len(sys.argv)>4 else (200 if d=="a" else 130)),"outline":"single color black outline","shading":"medium shading","detail":"medium detail","seed":seed})
        active.append(dict(k=k,s=seed,job=A.field(r,'job_id'),raw='' if A.field(r,'job_id') else r[:200]))
    json.dump(active,open(st,'w'),indent=1); done=[]
    while active:
        time.sleep(20)
        for a in list(active):
            if not a['job']: print('FAILED',a); active.remove(a); continue
            if A.field(A.call('get_image',{"job_id":a['job']}),'status')=='completed':
                subprocess.run(A.CLI+['get_image',json.dumps({"job_id":a['job']}),'--save',f"art/pixellab-banners-new/raw/{a['k']}_s{a['s']}"],capture_output=True,text=True)
                done.append(a['k']); active.remove(a)
    print('DONE',done)
