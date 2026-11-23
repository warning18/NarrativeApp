"""Stage the picked combat-kit pieces (limited palettes, PNG8) and build the sheets. python3 art/pixellab-combat-kits/build.py"""
import sys; sys.path.insert(0,'art/pixellab-styles'); sys.path.insert(0,'art/pixellab-cards'); sys.path.insert(0,'tool')
import post, build as CB, apollo_remap as AR
from PIL import Image, ImageDraw
R='art/pixellab-combat-kits/raw/'; F='art/pixellab-combat-kits/final/'
PIECES=['stage','table','cardframe','panel','slot','kitcard']
PICK={('apollo',k):1 for k in PIECES}; PICK.update({('b',k):1 for k in PIECES+['hero','foe']})
def proc(st,k):
    im=Image.open(f'{R}{st}_{k}_s{PICK[(st,k)]}/get_image_0.png').convert('RGBA')
    return AR.remap(im) if st=='apollo' else post.style1(im,maxarea=60,stretch=(k in ('hero','foe')))
def nine(im,W,Hh,c=8):
    out=Image.new('RGBA',(W,Hh),(0,0,0,0));w,h=im.size
    def blit(box,dst):
        part=im.crop(box);out.alpha_composite(part.resize((dst[2]-dst[0],dst[3]-dst[1]),Image.NEAREST),(dst[0],dst[1]))
    xs=[0,c,w-c,w];ys=[0,c,h-c,h];dx=[0,c,W-c,W];dy=[0,c,Hh-c,Hh]
    for i in range(3):
        for j in range(3): blit((xs[i],ys[j],xs[i+1],ys[j+1]),(dx[i],dy[j],dx[i+1],dy[j+1]))
    return out
def mock(st):
    g=lambda k:Image.open(f'{F}{st}_{k}.png').convert('RGBA')
    hero=Image.open(f'{F}b_hero.png').convert('RGBA') if st=='b' else Image.open('art/pixellab-combat-kits/skel/hero.png').convert('RGBA')
    foe=Image.open(f'{F}b_foe.png').convert('RGBA') if st=='b' else Image.open('assets/visuals/fighters/inquisition_warden_idle_west.png').convert('RGBA')
    d6=Image.open(f'art/pixellab-styles/final/style1_d6.png' if st=='b' else 'assets/visuals/dice/die_d6_bone_44.png').convert('RGBA')
    d12=Image.open(f'art/pixellab-styles/final/style1_d12.png' if st=='b' else 'assets/visuals/dice/die_d12_bone_44.png').convert('RGBA')
    T=[Image.new('RGBA',(180,252),(14,16,24,255)) for _ in range(3)]
    s=g('stage');T[0].alpha_composite(s,(0,52));T[0].alpha_composite(hero,(20,46));T[0].alpha_composite(foe,(112,46))
    T[0].alpha_composite(d6.resize((30,30),Image.NEAREST),(50,110));T[0].alpha_composite(d12.resize((30,30),Image.NEAREST),(100,110))
    for i in range(3): T[0].alpha_composite(g('cardframe'),(i*60+2,166))
    t=g('table');T[1].alpha_composite(t,(0,52));T[1].alpha_composite(d6.resize((30,30),Image.NEAREST),(60,87));T[1].alpha_composite(d12.resize((30,30),Image.NEAREST),(95,92))
    for i in range(3): T[1].alpha_composite(g('cardframe'),(i*60+2,166))
    T[2].alpha_composite(nine(g('panel'),176,100),(2,54))
    for i in range(4): T[2].alpha_composite(g('slot'),(12+i*40,64))
    T[2].alpha_composite(nine(g('panel'),176,60),(2,50)) if False else None
    for i in range(3): T[2].alpha_composite(g('kitcard'),(i*60+2,166))
    return T
if __name__=='__main__':
    for st in ('apollo','b'):
        for k in PIECES+(['hero','foe'] if st=='b' else []): CB.png8(proc(st,k),f'{F}{st}_{k}.png')
    B='docs/art/boards/'
    for sc in (1,2):
        W=Image.new('RGBA',(2*3*190+10,252+10),(26,28,38,255))
        for r,st in enumerate(('apollo','b')):
            for i,t in enumerate(mock(st)): W.alpha_composite(t,(10+r*3*190+i*190,5))
        W=W.resize((W.width*sc,W.height*sc),Image.NEAREST);W.save(f'{B}combat-kits-{sc}x.png')
