"""Remap pixel art to the 46-colour Apollo palette (nearest colour, hard pixels, alpha kept). No assets are changed.
python3 tool/apollo_remap.py            # builds docs/art/boards/skills-apollo-palette-sample.png
as a module: remap(img, dither=False) -> RGBA image"""
import numpy as np
from PIL import Image, ImageDraw, ImageFont
HEX="""172038 253A5E 3C5E8B 4F8FBA 73BED3 A4DDDB 19332D 25562E 468232 75A743 A8CA58 D0DA91 4D2B32 7A4841 AD7757 C09473 D7B594 E7D5B3
341C27 602C2C 884B2B BE772B DE9E41 E8C170 241527 411D31 752438 A53030 CF573C DA863E 1E1D39 402751 7A367B A23E8C C65197 DF84A5
090A14 10141F 151D28 202E37 394A50 577277 819796 A8B5B2 C7CFCC EBEDE9""".split()
MUTED="""A6884A 906C30 825337 83473D 66352E 562923 612638 46332C 323230 3E4055 382D35 323B42 1F2D36 141F25 0B1016 245273 4E7499 5E7E8B 798A92 879EA3
E3DDD1 BDBBAE AF9E94 907C75 A29F7E 969372 78735D 696353 4F493B 212528 595C55 4B4E4F 57562A 675F30 727234 73804B 5F7B53 3B6D62 32534A""".split()
ACCENTS=['F2C14E','FFF6E0','A987EA']          # hot yellow, near white, one violet (kept from today's art)
def mk(hs): return np.array([[int(h[i:i+2],16) for i in (0,2,4)] for h in hs],float)
CORES=['F2C14E','FFF6E0']             # hot yellow + near white, kept for the hot cores of skills
PALETTES={'apollo+cores':mk(HEX+CORES),'apollo':mk(HEX),'muted':mk(MUTED),'muted+accents':mk(MUTED+ACCENTS)}
PAL=PALETTES['apollo']
def _dist(px,PAL=None):
    PAL=PALETTES['apollo'] if PAL is None else PAL                      # redmean-weighted distance (closer to how colours look than plain RGB)
    out=[]
    for p in PAL:
        rm=(px[:,0]+p[0])/2; d=px-p
        out.append((2+rm/256)*d[:,0]**2+4*d[:,1]**2+(2+(255-rm)/256)*d[:,2]**2)
    return np.stack(out,1)
def remap(im,dither=False,pal='apollo'):
    im=im.convert('RGBA'); a=np.array(im); h,w=a.shape[:2]; rgb=a[...,:3].reshape(-1,3).astype(float)
    if dither:                      # 4x4 ordered dither, small amplitude
        B=np.array([[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]])/16-.5; rgb=rgb+(np.tile(B,(h//4+1,w//4+1))[:h,:w].reshape(-1,1)*24)
    PL=PALETTES[pal]; idx=_dist(rgb,PL).argmin(1); a[...,:3]=PL[idx].reshape(h,w,3).astype(np.uint8); return Image.fromarray(a,'RGBA')
def key_frame(path,n=9):
    s=Image.open(path).convert('RGBA'); fw=s.width//n; fr=[s.crop((i*fw,0,(i+1)*fw,s.height)) for i in range(n)]
    return max(fr[2:7],key=lambda f:int((np.array(f)[...,3]>0).sum()))
FX=[('fire','art/pixellab-vfx/final/vfx_flame.png'),('frost','art/pixellab-vfx/final/vfx_frost.png'),('poison','art/pixellab-vfx/batch1/final/vfx_poison.png'),
    ('holy','art/pixellab-vfx/batch1/final/vfx_radiance.png'),('void/shadow','art/pixellab-vfx/batch1/final/vfx_shadow.png'),('steel hit','art/pixellab-vfx/batch1/final/vfx_heavy_slash.png')]
IC=[('improvised_strike','common'),('frigid_grip','common'),('radiant_judgment','common'),('mage_arcane_missile','uncommon'),('dwarf_stoneskin','uncommon'),('fireball','rare'),
    ('mage_frost_nova','rare'),('voidkin_starless_gaze','rare'),('void_blast','epic'),('mage_meteor','epic'),('cleric_second_dawn','legendary'),('wrath_of_dawn','legendary')]
def strip(name):
    P=PALETTES[name]; im=Image.new('RGB',(len(P)*12,14))
    for i,c in enumerate(P): ImageDraw.Draw(im).rectangle((i*12,0,i*12+11,13),fill=tuple(int(v) for v in c))
    return im
def compare():
    """docs/art/boards/skills-palettes-compare.png: today / Apollo / muted (and muted + 3 accents) for 6 effects and 12 icons"""
    BG=(20,17,26); F=ImageFont.load_default(size=13); FS=ImageFont.load_default(size=11); W=(233,224,201); S=3; cw=48*S+12
    rows=[('today',None),('Apollo','apollo'),('muted palette','muted')]
    H=14*3+40+3*(48*S+8)+30+(48*S+8)+30+3*(48+6)+30
    sh=Image.new('RGB',(80+6*(48*3+12)+10,H+60),BG); d=ImageDraw.Draw(sh); y=8
    for n in ('apollo','muted'):
        d.text((10,y),f'{n} strip',font=FS,fill=W); sh.paste(strip(n),(110,y)); y+=18
    d.text((10,y),'Skill effects, key frame at 3x: rows today / Apollo / muted palette',font=F,fill=W); y+=20
    kf=[key_frame(p) for _,p in FX]
    for lab,pn in rows:
        d.text((10,y+60),lab,font=FS,fill=W)
        for i,k in enumerate(kf):
            im=k if pn is None else remap(k,pal=pn); a=im.resize((48*S,48*S),Image.NEAREST); sh.paste(a,(80+i*cw,y),a)
        y+=48*S+8
    d.text((10,y),'Muted palette + 3 accents kept from today (hot yellow F2C14E, near white FFF6E0, violet A987EA)',font=F,fill=W); y+=20
    for i,k in enumerate(kf):
        a=remap(k,pal='muted+accents').resize((48*S,48*S),Image.NEAREST); sh.paste(a,(80+i*cw,y),a)
    y+=48*S+14
    d.text((10,y),'Skill icons at 3x: rows today / Apollo / muted palette',font=F,fill=W); y+=20
    for lab,pn in rows:
        d.text((10,y+20),lab,font=FS,fill=W)
        for i,(n,r) in enumerate(IC):
            im=Image.open(f'assets/icons/skills/{n}.png').convert('RGBA'); im=im if pn is None else remap(im,pal=pn)
            a=im.resize((48,48),Image.NEAREST); sh.paste(a,(80+i*62,y),a)
        y+=48+6
    for i,(n,r) in enumerate(IC): d.text((80+i*62,y),r[:4],font=FS,fill=W)
    sh.crop((0,0,sh.width,y+18)).save('docs/art/boards/skills-palettes-compare.png'); print('ok compare')
def first_sheet():
    BG=(20,17,26); F=ImageFont.load_default(size=13); FS=ImageFont.load_default(size=11); W=(233,224,201)
    fx=[('fire','art/pixellab-vfx/final/vfx_flame.png'),('frost','art/pixellab-vfx/final/vfx_frost.png'),('poison','art/pixellab-vfx/batch1/final/vfx_poison.png'),
        ('holy','art/pixellab-vfx/batch1/final/vfx_radiance.png'),('void/shadow','art/pixellab-vfx/batch1/final/vfx_shadow.png'),('steel hit','art/pixellab-vfx/batch1/final/vfx_heavy_slash.png')]
    ic=[('improvised_strike','common'),('frigid_grip','common'),('radiant_judgment','common'),('mage_arcane_missile','uncommon'),('dwarf_stoneskin','uncommon'),('fireball','rare'),
        ('mage_frost_nova','rare'),('voidkin_starless_gaze','rare'),('void_blast','epic'),('mage_meteor','epic'),('cleric_second_dawn','legendary'),('wrath_of_dawn','legendary')]
    pal=Image.new('RGB',(46*20,24)); 
    for i,c in enumerate(PAL): ImageDraw.Draw(pal).rectangle((i*20,0,i*20+19,23),fill=tuple(int(v) for v in c))
    S=3; cell=48*S+12; Wd=max(6*cell,12*(16*3+14))+20
    sh=Image.new('RGB',(Wd,24+30+2*(48*S+22)+30+16*2+16*3*2+120+30+30),BG); d=ImageDraw.Draw(sh); y=8
    sh.paste(pal,(10,y)); y+=30
    d.text((10,y),'Skill effects, one key frame each at 3x: today (top) | Apollo remap (bottom)',font=F,fill=W); y+=22
    for i,(n,p) in enumerate(fx):
        k=key_frame(p); r=remap(k); x=10+i*cell
        for j,im in enumerate((k,r)):
            im2=im.resize((48*S,48*S),Image.NEAREST); sh.paste(im2,(x,y+j*(48*S+6)),im2)
        d.text((x,y+2*(48*S+6)),n,font=FS,fill=W)
    y+=2*(48*S+6)+22
    d.text((10,y),'Skill icons: today (top) | Apollo remap (bottom); at 2x (32 px, a typical in-game size) and 3x',font=F,fill=W); y+=22
    for i,(n,rar) in enumerate(ic):
        im=Image.open(f'assets/icons/skills/{n}.png').convert('RGBA'); r=remap(im); x=10+i*(16*3+14)
        for j,t in enumerate((im,r)):
            a=t.resize((32,32),Image.NEAREST); sh.paste(a,(x,y+j*38),a)
            b=t.resize((48,48),Image.NEAREST); sh.paste(b,(x,y+2*38+j*54),b)
        d.text((x,y+2*38+108),rar[:4],font=FS,fill=W)
    sh.crop((0,0,sh.width,y+2*38+126)).save('docs/art/boards/skills-apollo-palette-sample.png'); print('ok')

if __name__=='__main__':
    import sys
    if 'first' in sys.argv: first_sheet()
    else: compare()
