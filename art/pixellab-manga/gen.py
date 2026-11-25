"""Manga ink icon test: 6 icons x 3 variants, 32x32 text only, 1 gen each: python3 art/pixellab-manga/gen.py [size]"""
import sys,json
sys.path.insert(0,'art/pixellab-backgrounds'); import batchA_gen as A
SIZE=int(sys.argv[1]) if len(sys.argv)>1 else 32
SUB={'antidote':"a small potion bottle with a cork",'dagger':"a straight dagger, pointing up",'key':"an old iron key with a round bow",'helm':"a knight's helmet seen from the front with a visor slit",'boots':"a single leather boot seen from the side",'shield':"a heater shield with a cross"}
VAR={'A':"manga ink drawing, clean thin pen line, white paper body, no tone, no shading, very few lines, one small spot of red, ",
 'B':"manga ink drawing, bold brush line with thick outer contour and thin inner strokes, solid black ink shadow shapes, white paper body, one small spot of red, ",
 'C':"manga ink drawing, clean pen line, white paper body, one flat screentone dot area on one side, no other shading, one small spot of red, "}
jobs={}
for v,vt in VAR.items():
    for k,t in SUB.items():
        r=A.call('create_image_pixflux',{"description":vt+t+", black and white with red, game icon, no text, centred","width":SIZE,"height":SIZE,"no_background":True,"outline":"single color black outline","shading":"flat shading","detail":"low detail"})
        jobs[f'{v}_{k}']=A.field(r,'job_id'); print(v,k,jobs[f'{v}_{k}'],r[:60].replace('\n',' '))
json.dump(jobs,open(f'art/pixellab-manga/jobs{SIZE}.json','w'))
