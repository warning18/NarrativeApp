"""Banners pilot in the new look: pixflux img2img from today's clan standard (64x128). python3 art/pixellab-banners-new/gen.py <state.json> [seed]"""
import json, subprocess, time, sys, base64, io
sys.path.insert(0,'art/pixellab-backgrounds')
import batchA_gen as A
from PIL import Image
BASE="pixel art hanging clan war standard, chunky dark medieval fantasy game style, 1 px black outline, flat colours with a lit top-left edge, hand-stitched look, "
KEEP={
 'clan_choir':"black cloth with a cream sun with many rays and a gold gem centre above a cream square seal with two small gold gems, gold top band and gold hem trim, ",
 'clan_compact':"black cloth with a cream stack of bars ending in a pointed pen nib with an orange-brown gem above a cream cross-bar and post emblem with a brown gem, orange-brown top band and hem trim, ",
 'clan_giants':"black cloth with two cream mountain peaks with a steel-blue gem above a cream brazier with three steel-blue gems, steel-blue top band and hem trim, ",
 'clan_kindly':"black cloth with a cream leaf with an olive green gem above a cream ring with a clock hand and an olive gem, olive green top band and hem trim, ",
 'clan_open_hand':"black cloth with a cream open hand with a grey gem above a cream square spiral with a grey gem, grey top band and hem trim, ",
 'clan_penitents':"black cloth with a cream teardrop flame with an eye above a cream cross with small studs, grey-brown top band and hem trim, ",
 'clan_pit':"black cloth with two cream horizontal bars over a few thin lines with a purple gem above a cream crescent moon with a purple gem, purple top band and hem trim, ",
 'clan_tidekin':"black cloth with a cream fan shell with a cyan pearl above cream wave shapes with a cyan gem, cyan top band and hem trim, ",
 'clan_vigil':"black cloth with a cream eye with a grey pupil above a cream square seal with two grey gems, pale grey-white top band and hem trim, ",
 'heirloom_shroud':"black cloth with a cream arch with a red gem and a small post above a cream square seal with two red gems, red top band and red hem trim, ",
 'moon_shard_shroud':"black cloth with a cream crescent moon with a gold gem above a cream triangle shard with a gold gem, gold yellow top band and hem trim, ",
 'reliquary_thread':"black cloth with a cream S-shaped thread with an orange gem above a cream square spiral with an orange gem, orange top band and hem trim, ",
 'sovereign_mantle':"black cloth with three cream posts topped by three red gems over a cream bar, above a cream eye with a red pupil, red top band and red hem trim, ",
 'void_standard':"black cloth with a cream eye with a red pupil above a cream square spiral with a red gem, red top band and red hem trim, ",
 'warden_standard':"black cloth with a cream pillar frame with a green ring above a cream E-shaped bar emblem with green gems, green top band and green hem trim, ",
 'white_fleet_sail':"black cloth with a cream triangular sail with a white pearl above cream wave shapes, white silver top band and hem trim, ",
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
