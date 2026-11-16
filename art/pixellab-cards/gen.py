"""PixelLab img2img of the card piece skeletons (1 gen each). python3 art/pixellab-cards/gen.py [kinds] [seeds]  e.g. frame,plate,backdrop 1,2"""
import sys, json, io, base64, os, subprocess, time
sys.path.insert(0,'art/pixellab-backgrounds'); import batchA_gen as A
from PIL import Image
CLI=A.CLI
BASE="pixel art, chunky dark medieval fantasy card game piece, 1 px black outline, flat colours with a lit top-left edge, hand-made look, no text, "
D={('frame','common'):BASE+"a plain worn iron card frame, riveted dark iron plates, the inside is flat magenta",
   ('frame','uncommon'):BASE+"a worked bronze card frame with raised bronze corner bosses and a beaded edge, the inside is flat magenta",
   ('frame','rare'):BASE+"an ornate silver card frame with engraved scrollwork, pointed corner brackets and a pale blue gem at the top centre, the inside is flat magenta",
   ('frame','epic'):BASE+"a gilded gold card frame with purple trim, two purple gems at the top and bottom centre and curled corner brackets, the inside is flat magenta",
   ('frame','legendary'):BASE+"a radiant bright gold card frame with a crown of sun rays and a gold gem at the top centre, pointed gold corner brackets, the inside is flat magenta",
   ('plate','epic'):BASE+"a small square icon plate, gilded gold rim with four purple gems on the sides, dark inside",
   ('plate','legendary'):BASE+"a small square icon plate, bright gold rim with four white-gold gems and tiny rays, dark inside",
   ('backdrop','epic'):BASE+"a dark purple card art background with a soft purple glow in the middle and small pink sparkles, no objects",
   ('backdrop','legendary'):BASE+"a dark card art background with a golden halo ring in the middle, soft gold light and white-gold sparkles, no objects",
   ('plate','common'):BASE+"a small square icon plate, plain dark iron rim, dark inside",
   ('plate','uncommon'):BASE+"a small square icon plate, bronze rim with four rivets, dark inside",
   ('plate','rare'):BASE+"a small square icon plate, silver rim with four pale blue gems on the sides, dark inside",
   ('backdrop','common'):BASE+"a plain dark slate-blue card art background, faint stitched cloth texture, no objects",
   ('backdrop','uncommon'):BASE+"a dark card art background with a faint bronze ring and a beaded bronze border line, no objects",
   ('backdrop','rare'):BASE+"a dark blue card art background with soft pale light rays from the top and small sparkles, no objects"}
S={'frame':(104,172,110,False),'plate':(40,40,110,True),'backdrop':(104,76,250,False)}
def b64(p): b=io.BytesIO(); Image.open(p).save(b,'PNG'); return base64.b64encode(b.getvalue()).decode()
if __name__=='__main__':
    kinds=sys.argv[1].split(',');seeds=[int(s) for s in sys.argv[2].split(',')]
    jobs=[]
    for k in kinds:
        for t in (sys.argv[3].split(',') if len(sys.argv)>3 else ('common','uncommon','rare')):
            w,h,st,nb=S[k]
            for s in seeds:
                r=A.call('create_image_pixflux',{"description":D[(k,t)],"width":w,"height":h,"no_background":nb,"init_image_base64":b64(f'art/pixellab-cards/skel/{k}_{t}.png'),"init_image_strength":st,"outline":"single color black outline","shading":"medium shading","detail":"medium detail","seed":s})
                jobs.append((k,t,s,A.field(r,'job_id') or A.field(r,'id'))); print(k,t,s,r[:150].replace('\n',' '))
    json.dump(jobs,open('art/pixellab-cards/jobs.json','w'))
