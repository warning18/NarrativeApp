"""PixelLab img2img of the clan backdrops (1 gen each): python3 art/pixellab-cards/clans/gen.py [seeds] [strength]"""
import sys, json, io, base64
sys.path.insert(0,'art/pixellab-backgrounds'); import batchA_gen as A
from PIL import Image
BASE="pixel art, dark quiet card art background in a medieval fantasy game, 1 px dark outline on the sign only, smooth dark gradient with a faint texture, low contrast, no text, "
D={'dominion':"deep blue, a large faint iron lantern in the middle",'crows':"deep crimson, a large faint anchor inside a ring in the middle",
 'compact':"dark rust brown, a large faint hammer over an anvil in the middle",'mire':"dark green, a large faint reed leaf over waves in the middle",
 'vigil':"dark slate grey, a large faint open eye in the middle",'penitents':"dark ash sand, a large faint teardrop flame over a cross in the middle",
 'wayfarer':"dark neutral brown, a large faint road narrowing to the horizon in the middle"}
def b64(p): b=io.BytesIO(); Image.open(p).save(b,'PNG'); return base64.b64encode(b.getvalue()).decode()
if __name__=='__main__':
    seeds=[int(s) for s in sys.argv[1].split(',')]; st=int(sys.argv[2]) if len(sys.argv)>2 else 250; jobs=[]
    for k in D:
        for s in seeds:
            r=A.call('create_image_pixflux',{"description":BASE+D[k],"width":104,"height":76,"no_background":False,"init_image_base64":b64(f'art/pixellab-cards/clans/skel/{k}.png'),"init_image_strength":st,"outline":"single color black outline","shading":"medium shading","detail":"low detail","seed":s})
            jobs.append((k,s,A.field(r,'job_id'))); print(k,s,r[:60].replace('\n',' '))
    json.dump(jobs,open('art/pixellab-cards/clans/jobs.json','w'))
