"""Skills in Apollo 46 + two core brights (F2C14E, FFF6E0): remaps every skill icon and the six merged effect strips into art/pixellab-apollo-skills/ (staged, not wired),
builds docs/art/boards/skills-apollo-icons.png and skills-apollo-effects.png, and reports the element tints. python3 tool/apollo_skills.py"""
import sys, os, json, glob
sys.path.insert(0,'tool')
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from apollo_remap import remap, PALETTES, HEX
PN='apollo+cores'; OUT='art/pixellab-apollo-skills/'
BG=(20,17,26); W=(233,224,201); F=ImageFont.load_default(size=13); FS=ImageFont.load_default(size=10)
def icons():
    sk=json.load(open('assets/gamedata/skills.json')); rar={}
    for i,s in sk.items(): rar[i]=s.get('rarity','other')
    files=sorted(glob.glob('assets/icons/skills/*.png')); groups={}
    for f in files:
        i=os.path.basename(f)[:-4]; im=Image.open(f).convert('RGBA'); new=remap(im,pal=PN); new.save(OUT+'icons/'+i+'.png')
        groups.setdefault(rar.get(i,'other'),[]).append((i,im,new))
    order=[r for r in ('common','uncommon','rare','epic','legendary','other') if r in groups]
    cols=26; cw=36; ch=92; y=8; rows=sum((len(groups[r])+cols-1)//cols for r in order)
    sh=Image.new('RGB',(cols*cw+16,rows*ch+len(order)*24+16),BG); d=ImageDraw.Draw(sh)
    for r in order:
        d.text((8,y),f'{r} ({len(groups[r])}): 1x today | new, then 2x today, 2x new',font=F,fill=W); y+=20
        for n,(i,im,new) in enumerate(groups[r]):
            x=8+(n%cols)*cw; yy=y+(n//cols)*ch
            sh.paste(im,(x,yy),im); sh.paste(new,(x+18,yy),new)
            a=im.resize((32,32),Image.NEAREST); b=new.resize((32,32),Image.NEAREST); sh.paste(a,(x,yy+20),a); sh.paste(b,(x,yy+56),b)
        y+=((len(groups[r])+cols-1)//cols)*ch+4
    sh.save('docs/art/boards/skills-apollo-icons.png'); print('icons',len(files),sh.size)
ELEM={'None':(0xFFFFFF,0xB0BEC5),'Fire':(0xFF7043,0xFFD54F),'Ice':(0xB3E5FC,0xFFFFFF),'Water':(0x4FC3F7,0xB2EBF2),'Earth':(0xA1887F,0xD7CCC8),'Wind':(0xC5E1A5,0xE0F7FA),
      'Void':(0x7E57C2,0xCE93D8),'Light':(0xFFF176,0xFFFDE7),'Electricity':(0x80D8FF,0xFFEB3B)}
def lerp(a,b,t): return tuple(round(a[k]+(b[k]-a[k])*t) for k in range(3))
def rgb(h): return ((h>>16)&255,(h>>8)&255,h&255)
def tones(el):
    p,sec=ELEM[el]
    if p==0xFFFFFF: return None
    mid=rgb(p); hi=lerp(rgb(sec),(255,255,255),.4); lo=lerp(mid,(0,0,0),.5); deep=lerp(mid,(0,0,0),.78); return [hi,mid,lo,deep]
def tint(im,el):
    T=tones(el)
    if T is None: return im
    a=np.array(im.convert('RGBA')); m=a[...,3]>0; cols=sorted({tuple(c) for c in a[m][:,:3]},key=lambda c:-(.299*c[0]+.587*c[1]+.114*c[2])); n=len(cols)
    rank={c:(0 if n<=1 else min(3,max(0,(r*4)//n))) for r,c in enumerate(cols)}
    out=a.copy()
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y,x,3]: out[y,x,:3]=T[rank[tuple(a[y,x,:3])]]
    return Image.fromarray(out,'RGBA')
VOID_RAMP=['241527','402751','752438','7A367B','A23E8C','C65197']  # dark ... light (752438 only if needed)
def ramp(im,hexes):
    a=np.array(im.convert('RGBA')); m=a[...,3]>0
    cols=sorted({tuple(c) for c in a[m][:,:3]},key=lambda c:.299*c[0]+.587*c[1]+.114*c[2])
    use=['090A14','241527','402751','7A367B','A23E8C','C65197']; n=len(cols)
    tbl={}
    for r,c in enumerate(cols):
        k=0 if r==0 else min(len(use)-1,1+round((r-1)*(len(use)-2)/max(n-2,1))); h=use[k]; tbl[c]=tuple(int(h[i:i+2],16) for i in (0,2,4))
    out=a.copy()
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y,x,3]: out[y,x,:3]=tbl[tuple(a[y,x,:3])]
    return Image.fromarray(out,'RGBA')
def effects():
    names=['flame','frost','lightning','heal','void_rift','shield']; S=2
    for n in names:
        im=Image.open(f'art/pixellab-vfx/final/vfx_{n}.png').convert('RGBA'); new=remap(im,pal=PN)
        if n=='void_rift': new=ramp(im,VOID_RAMP)       # hand fix: the nearest colour turns the violets grey-pink, so walk Apollo's purples by brightness
        new.save(OUT+f'vfx/vfx_{n}.png')
    sh=Image.new('RGB',(9*48*S+80,len(names)*2*(48*S+4)+40+len(names)*(48*S*3+30)+60),BG); d=ImageDraw.Draw(sh); y=8
    d.text((8,y),'Effects, all 9 frames at 2x: today (top) | Apollo 46 + 2 core brights (bottom)',font=F,fill=W); y+=20
    for n in names:
        for j,pth in enumerate((f'art/pixellab-vfx/final/vfx_{n}.png',OUT+f'vfx/vfx_{n}.png')):
            im=Image.open(pth).convert('RGBA'); a=im.resize((im.width*S,im.height*S),Image.NEAREST); sh.paste(a,(70,y),a)
            d.text((6,y+30),n if j==0 else 'new',font=FS,fill=W); y+=48*S+4
    sh.crop((0,0,sh.width,y+4)).save('docs/art/boards/skills-apollo-effects.png')
    # element tints: frame 4 of each strip under every element, today vs new
    els=list(ELEM); cw=48*2+6; sh2=Image.new('RGB',(70+len(els)*cw,len(names)*2*(48*2+4)+40),BG); d2=ImageDraw.Draw(sh2); y=8
    d2.text((6,y),'Under the element tints the game uses (key frame at 2x): per strip, today (top) | new (bottom)',font=F,fill=W); y+=20
    for i,e in enumerate(els): d2.text((70+i*cw,y),e,font=FS,fill=W)
    y+=14
    for n in names:
        for j,pth in enumerate((f'art/pixellab-vfx/final/vfx_{n}.png',OUT+f'vfx/vfx_{n}.png')):
            st=Image.open(pth).convert('RGBA'); k=st.crop((4*48,0,5*48,48))
            d2.text((6,y+30),n if j==0 else 'new',font=FS,fill=W)
            for i,e in enumerate(els):
                t=tint(k,e).resize((96,96),Image.NEAREST); sh2.paste(t,(70+i*cw,y),t)
            y+=48*2+4
    sh2.crop((0,0,sh2.width,y+4)).save('docs/art/boards/skills-apollo-tints.png')
    P=PALETTES[PN]; print('tone check (nearest palette colour distance; >=40 per channel noted):')
    for e in els:
        T=tones(e)
        if not T: continue
        for nm,c in zip(('hi','mid','lo','deep'),T):
            dist=((P-np.array(c))**2).sum(1)**.5; k=int(dist.argmin()); inpal=dist[k]<30
            print(f'  {e:11s} {nm:4s} #{c[0]:02X}{c[1]:02X}{c[2]:02X} -> nearest #{int(P[k][0]):02X}{int(P[k][1]):02X}{int(P[k][2]):02X} d={dist[k]:.0f} {"in" if inpal else "OUT"}')
if __name__=='__main__': icons(); effects()
