"""The final emblems for UX-2: option A (free-standing, no box) everywhere, at 32 and 48 px, with a one-pixel LIGHT rim outside the ink so the emblem reads on the dark card
(its own light tone; cream for the orc). Names: races/<id>.png and professions/<id>.png in final/32 and final/48. 0 generations. Repo root."""
import os, sys
sys.path.insert(0,'art/pixellab-emblems')
import emblems_gen as E
from PIL import Image
O='art/pixellab-emblems/final/'
RIM={'human':E.C['gold'],'elf':(200,235,160,255),'dwarf':(220,215,205,255),'orc':E.C['cream'],'voidkin':(214,196,250,255),
     'warrior':(235,235,240,255),'mage':(214,196,250,255),'ranger':(235,215,170,255),'rogue':(235,235,240,255),'cleric':E.C['cream']}
RACES=('human','elf','dwarf','orc','voidkin'); CALLS=('warrior','mage','ranger','rogue','cleric')
def with_rim(im,col):
    w,h=im.size; src=im.load(); out=Image.new('RGBA',(w,h),(0,0,0,0)); op=out.load()
    for y in range(h):
        for x in range(w):
            if src[x,y][3]>0: op[x,y]=src[x,y]
    for y in range(h):
        for x in range(w):
            if src[x,y][3]==0 and any(0<=x+dx<w and 0<=y+dy<h and src[x+dx,y+dy][3]>0 for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,-1),(1,-1),(-1,1))): op[x,y]=col
    return out
def build(name,N):
    ow=1 if N<48 else 2; inner=N-2*ow-2
    em=E.finish(E.draw(E.S(name),inner),ow)            # inner + 2*ow
    canvas=Image.new('RGBA',(N,N),(0,0,0,0)); canvas.paste(em,((N-em.width)//2,(N-em.height)//2),em)
    return with_rim(canvas,RIM[name])
if __name__=='__main__':
    for N in (32,48):
        for grp,names in (('races',RACES),('professions',CALLS)):
            os.makedirs(f'{O}{N}/{grp}',exist_ok=True)
            for n in names: build(n,N).save(f'{O}{N}/{grp}/{n}.png',optimize=True)
    names=RACES+CALLS; sh=Image.new('RGB',(10*110+20,2*120+40),(31,28,35))
    from PIL import ImageDraw, ImageFont; d=ImageDraw.Draw(sh); F=ImageFont.load_default(size=12)
    for i,n in enumerate(names):
        for j,N in enumerate((48,32)):
            im=Image.open(f"{O}{N}/{'races' if n in RACES else 'professions'}/{n}.png").convert('RGBA'); big=im.resize((im.width*2,im.height*2),Image.NEAREST)
            sh.paste(big,(10+i*110,30+j*120),big)
        d.text((10+i*110,10),n,font=F,fill=(233,224,201))
    sh.save('docs/art/boards/emblems-final.png'); print('ok')
