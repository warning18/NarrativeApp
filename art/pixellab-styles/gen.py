"""Two dark style tests on four subjects, 1 gen per piece: python3 art/pixellab-styles/gen.py [seeds]"""
import sys, json, io, base64
sys.path.insert(0,'art/pixellab-backgrounds'); import batchA_gen as A
from PIL import Image
S1="pixel art in the style of a woodcut ink wash, near black and white and grey only, harsh black ink shadows, hatching, only one small part in blood red or gold, "
S2="pixel art, very dark low-key moody palette, deep black-blue shadows, muted blue moonlight and warm amber lantern glow, high contrast darkness, "
SUB={ # key: (init, w, h, no_bg, strength, text)
 'panel':('art/pixellab-styles/skel/panel.png',104,72,True,150,"a game UI panel frame with studded corners, dark inside, "),
 'button':('art/pixellab-styles/skel/button.png',64,24,True,150,"a game UI button, plain, no text, "),
 'plate':('art/pixellab-styles/skel/plate.png',40,40,True,150,"a small square icon plate with a thin rim, dark inside, "),
 'd6':('assets/visuals/dice/die_d6_bone_44.png',44,44,True,200,"a six sided die with readable pips, "),
 'd12':('assets/visuals/dice/die_d12_bone_44.png',44,44,True,200,"a twelve sided die with readable face numbers, "),
 'combat':('assets/visuals/fight_plates/quay.png',180,320,False,200,"a fight backdrop, a harbour quay at night with moored boats and posts, empty ground in front, "),
 'hero':('art/pixellab-styles/skel/hero.png',44,48,True,200,"a side view ronin swordsman hero standing idle facing right, "),
}
EXTRA={'style1':{'hero':"black coat and white sash, only the sash edge in blood red, ",'d6':"white die, black pips, one pip in blood red, ",'d12':"white die, black engraved numbers, ",'panel':"black and grey metal, only the corner gems in blood red, ",'button':"black and grey, a thin blood red line, ",'plate':"black and grey rim, one red gem, ",'combat':"all in black and grey, only a lantern flame in gold, "},
       'style2':{'hero':"dark clothes, warm amber lantern light on one side, ",'d6':"dark bone die with amber pips, ",'d12':"dark die with faint amber numbers, ",'panel':"dark iron with a dim amber gem, ",'button':"dark iron with a dim amber glow, ",'plate':"dark iron rim with a dim blue gem, ",'combat':"deep shadows, moonlight on the water and a warm amber lantern, "}}
STY={'style1':S1,'style2':S2}
def b64(p): b=io.BytesIO(); Image.open(p).convert('RGBA').save(b,'PNG'); return base64.b64encode(b.getvalue()).decode()
if __name__=='__main__':
    seeds=[int(s) for s in sys.argv[1].split(',')]; jobs=[]
    for st in STY:
        for k,(init,w,h,nb,stg,txt) in SUB.items():
            for s in seeds:
                r=A.call('create_image_pixflux',{"description":STY[st]+txt+EXTRA[st][k]+"no text","width":w,"height":h,"no_background":nb,"init_image_base64":b64(init),"init_image_strength":stg,"color_image_base64":b64(f'art/pixellab-styles/skel/{st}_pal.png'),"outline":"single color black outline","shading":"medium shading","detail":"medium detail","seed":s})
                jobs.append((st,k,s,A.field(r,'job_id'))); print(st,k,s,r[:50].replace('\n',' '))
    json.dump(jobs,open('art/pixellab-styles/jobs.json','w'))
