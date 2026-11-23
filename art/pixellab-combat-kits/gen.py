"""Combat-screen kit pieces: 1 gen each. python3 art/pixellab-combat-kits/gen.py [seeds]"""
import sys, json, io, base64
sys.path.insert(0,'art/pixellab-backgrounds'); import batchA_gen as A
from PIL import Image
STY={'apollo':"pixel art, dark medieval fantasy game, muted palette, 1 px dark outline, light from the top left, flat colours with a lit top-left edge, hand-made look, ",
     'b':"pixel art in the style of a woodcut ink wash, near black and off-white and grey only, harsh black ink shadows, light from the top left, 1 px black outline, only one small part in blood red, "}
P={'stage':(180,100,170,False,"a stage floor strip: worn wooden ground lit from the top left that ends in a ledge and runs down into a darker dice tray surface, empty, "),
 'table':(180,100,170,False,"a tabletop seen from above with a wooden rim and a felt surface for tokens and dice, a faint circle, empty, "),
 'cardframe':(56,80,150,True,"a playing card frame, dark inside, bevelled rim, no picture, "),
 'panel':(48,48,150,True,"a square game UI panel frame with four corner studs, dark inside, "),
 'slot':(32,32,150,True,"a small inset square slot, dark inside, "),
 'kitcard':(56,80,150,True,"a playing card frame with four corner studs matching a UI panel kit, dark inside, ")}
EXTRA={'apollo':{},'b':{'stage':"all in black and grey, ",'table':"all in black and grey, one blood red stitch line, ",'cardframe':"black and grey, one blood red gem, ",'panel':"black and grey, red corner studs, ",'slot':"black and grey, ",'kitcard':"black and grey, one red gem, "}}
SPR={'hero':('art/pixellab-combat-kits/skel/hero.png',48,48,"a side view hero in a white shirt standing idle facing right, black ink, only the belt in blood red, "),
     'foe':('art/pixellab-combat-kits/skel/foe.png',48,48,"a hooded inquisition warden standing idle facing left, black ink and off-white, only the sash in blood red, ")}
def b64(p): b=io.BytesIO(); Image.open(p).convert('RGBA').save(b,'PNG'); return base64.b64encode(b.getvalue()).decode()
def go(args,st,k,s,jobs):
    r=A.call('create_image_pixflux',args); jobs.append((st,k,s,A.field(r,'job_id'))); print(st,k,s,r[:40].replace('\n',' '))
if __name__=='__main__':
    seeds=[int(s) for s in sys.argv[1].split(',')]; jobs=[]
    for st in STY:
        for k,(w,h,stg,nb,txt) in P.items():
            for s in seeds: go({"description":STY[st]+txt+EXTRA[st].get(k,'')+"no text","width":w,"height":h,"no_background":nb,"init_image_base64":b64(f'art/pixellab-combat-kits/skel/{st}_{k}.png'),"init_image_strength":stg,"outline":"single color black outline","shading":"medium shading","detail":"medium detail","seed":s},st,k,s,jobs)
    for k,(init,w,h,txt) in SPR.items():
        for s in seeds: go({"description":STY['b']+txt+"no text","width":w,"height":h,"no_background":True,"init_image_base64":b64(init),"init_image_strength":200,"outline":"single color black outline","shading":"medium shading","detail":"medium detail","seed":s},'b',k,s,jobs)
    json.dump(jobs,open('art/pixellab-combat-kits/jobs.json','w'))
