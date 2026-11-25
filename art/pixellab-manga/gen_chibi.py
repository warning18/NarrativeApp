"""Chibi icon test: 6 icons x 2 variants, 32x32, 1 gen each. V1 chibi ink (text only), V2 chibi colour (palette of the Starter_basic_hero sprite forced)."""
import sys,json,io,base64
sys.path.insert(0,'art/pixellab-backgrounds'); import batchA_gen as A
from PIL import Image
SUB={'antidote':"a chibi potion bottle with a huge round belly and a small cork",'dagger':"a chibi dagger, short stubby and fat, with a big round pommel",'key':"a chibi key with a huge round bow and a short stubby shaft",'helm':"a chibi round knight helmet, chunky, with a visor slit and a small crest",'boots':"a chibi leather boot, chunky and squat, rounded toe",'shield':"a chibi round-cornered shield, chunky, with a cross"}
VAR={'V1':"chibi ink drawing, chunky rounded squat shape, thick bold black brush outline, solid black ink shadow shape, paper white body, one small highlight, one strong spot of red, ",
 'V2':"chibi game item pixel art, chunky rounded squat shape, thick dark outline, small flat colour palette, one light highlight, one dark inner shadow, "}
pal=io.BytesIO();Image.open('art/pixellab-combat-kits/skel/hero.png').convert('RGBA').save(pal,'PNG');PAL=base64.b64encode(pal.getvalue()).decode()
jobs={}
for v,vt in VAR.items():
    for k,t in SUB.items():
        a={"description":vt+t+", game icon, no text, centred","width":32,"height":32,"no_background":True,"outline":"single color black outline","shading":"basic shading" if v=='V2' else "flat shading","detail":"medium detail"}
        if v=='V2': a["color_image_base64"]=PAL
        r=A.call('create_image_pixflux',a);jobs[f'{v}_{k}']=A.field(r,'job_id');print(v,k,jobs[f'{v}_{k}'])
json.dump(jobs,open('art/pixellab-manga/jobs_chibi.json','w'))
