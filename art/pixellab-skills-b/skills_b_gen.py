"""Epic (43) and legendary (9) skill icons in the (b) treatment: the ORIGINAL glyph kept, set in the rarity container filled with the element colour.
Drop-in: same names and sizes as assets/icons/skills (46 at 16 px, 6 at 32 px). 0 generations. Run from the repo root."""
import sys, json, os, collections
sys.path.insert(0,'art/pixellab-pilots/icons')
import icons_gen as I
from icons_gen import PAL, canvas, finish, P, R, L, E, H, mix
import harmonise_gen as HG
from PIL import Image, ImageDraw
INK=H('#0A0807'); PAL['ink']=INK
O='art/pixellab-skills-b/'
ELEM={'Fire':('ember','ember_d'),'Water':('tide','tide_d'),'Earth':('wood','wood_d'),'Wind':('ice','steel_d'),'Electricity':('gold','gold_d'),'Ice':('ice','tide_d'),'Light':('bone','gold_d'),'Void':('void','void_d'),'None':('steel','steel_d')}
def container2(rarity,fill,rim):
    im,d=canvas(14)
    if rarity=='epic': P(d,[(4,0),(9,0),(13,4),(13,9),(9,13),(4,13),(0,9),(0,4)],rim); P(d,[(4,1),(9,1),(12,4),(12,9),(9,12),(4,12),(1,9),(1,4)],fill)
    else: R(d,0,0,13,13,'gold'); R(d,1,1,12,12,'ink'); R(d,2,2,11,11,fill)      # legendary: gold frame
    return im
def elem_keys(element):
    dark=PAL[ELEM[element][1]]; PAL['f_'+element]=PAL[ELEM[element][0]]; PAL['r_'+element]=mix(dark,INK,0.45); return 'f_'+element,'r_'+element
def is_container(im):
    px=im.load(); w,h=im.size; dep=HG.depth_map(im); opaque=sum(1 for y in range(h) for x in range(w) if px[x,y][3]>0)
    ring=[px[x,y][:3] for y in range(h) for x in range(w) if px[x,y][3]>0 and dep[y][x]==2]
    if not ring: return False
    top=collections.Counter(ring).most_common(1)[0][1]/len(ring)
    return opaque/(w*h)>0.4 and top>0.6
def lum(c): return .3*c[0]+.59*c[1]+.11*c[2]
def badge_glyph(a):
    """the glyph of a badge-style original: interior pixels (inside the ring) that differ from the badge's fill colour; (glyph, fill) or None"""
    w,h=a.size; px=a.load(); dep=HG.depth_map(a); k=w//16; ring=2*k; inner=3*k
    ringc=collections.Counter(px[x,y][:3] for y in range(h) for x in range(w) if px[x,y][3]>0 and dep[y][x]<=ring)
    fillc=collections.Counter(px[x,y][:3] for y in range(h) for x in range(w) if px[x,y][3]>0 and dep[y][x]>=inner)
    if not fillc: return None
    opaque=sum(1 for y in range(h) for x in range(w) if px[x,y][3]>0)
    if opaque/(w*h)<0.5: return None
    fill=fillc.most_common(1)[0][0]
    # the fill family: the commonest interior colours that cover most of the interior
    tot=sum(fillc.values()); fam=set(); cum=0
    for c,n in fillc.most_common():
        fam.add(c); cum+=n
        if cum>=0.55*tot: break
    g=Image.new('RGBA',a.size,(0,0,0,0)); gp=g.load(); n=0
    for y in range(h):
        for x in range(w):
            if px[x,y][3]>0 and dep[y][x]>=inner-(k-1) and px[x,y][:3] not in fam and min(sum((px[x,y][i]-f[i])**2 for i in range(3)) for f in fam)>30**2: gp[x,y]=px[x,y]; n+=1
    return (g,fill,n)

def is_dark_badge(a):
    """a round badge with a dark fill and a coloured ring (the epic originals): the glyph is light on dark"""
    w,h=a.size; px=a.load(); dep=HG.depth_map(a)
    inner=[px[x,y][:3] for y in range(h) for x in range(w) if px[x,y][3]>0 and dep[y][x]>=3]
    if len(inner)<40: return False
    opaque=sum(1 for y in range(h) for x in range(w) if px[x,y][3]>0)
    if opaque/(w*h)<0.6: return False
    top=collections.Counter(inner).most_common(1)[0][0]
    return lum(top)<80 and collections.Counter(inner).most_common(1)[0][1]/len(inner)>0.45
def ring_recolour(a,rarity,element):
    """keep the badge and its glyph exactly; the ring takes the element's colour (light ring pixels the element's light tone, dark ones its dark tone)"""
    out=a.copy(); px=out.load(); w,h=a.size; dep=HG.depth_map(a)
    ringc=[px[x,y][:3] for y in range(h) for x in range(w) if px[x,y][3]>0 and dep[y][x]==2]
    fams=[c for c,_ in collections.Counter(ringc).most_common(2)]
    mid=PAL[ELEM[element][0]][:3]; dark=PAL[ELEM[element][1]][:3]
    lighter=max(fams,key=lum) if fams else None
    for y in range(h):
        for x in range(w):
            if px[x,y][3]>0 and dep[y][x]<=2 and px[x,y][:3] in fams and px[x,y][:3]!=INK[:3]:
                px[x,y]=(mid if px[x,y][:3]==lighter else dark)+(255,)
    if rarity=='legendary':     # a gold pip at the top: the legendary mark
        px[w//2,1]=(242,193,78,255); px[w//2-1,1]=(242,193,78,255)
    return out
def rarity_ring32(a,rarity,element):
    """the 32 px diamonds keep their glyph and element colour; the rarity is a ring (epic: the element's dark tone, legendary: gold) with the ink outside it"""
    w,h=a.size; src=a.load(); out=Image.new('RGBA',a.size,(0,0,0,0)); op=out.load()
    ring=(242,193,78,255) if rarity=='legendary' else PAL[ELEM[element][1]]
    def solid(x,y): return 0<=x<w and 0<=y<h and src[x,y][3]>0
    for y in range(h):
        for x in range(w):
            if src[x,y][3]>0: op[x,y]=src[x,y]
            elif any(solid(x+dx,y+dy) for dx in (-1,0,1) for dy in (-1,0,1)): op[x,y]=ring
    # then an ink outline around the ring
    res=out.copy(); rp=res.load(); ro=out.load()
    for y in range(h):
        for x in range(w):
            if ro[x,y][3]==0 and any(0<=x+dx<w and 0<=y+dy<h and ro[x+dx,y+dy][3]>0 for dx,dy in ((1,0),(-1,0),(0,1),(0,-1))): rp[x,y]=INK
    return res
def variant_b16(a,rarity,element):
    if is_dark_badge(a): return ring_recolour(a,rarity,element),'badge-ring'
    fk,rk=elem_keys(element); cont=finish(container2(rarity,fk,rk))
    if is_container(a):
        g=HG.extract_glyph(a)
        if sum(1 for q in g.getdata() if q[3]>0)<8:        # the glyph is the container's own colour: keep the whole original on the plate
            out=cont.copy(); out.alpha_composite(a); return out,'framed-original'
        out=cont.copy(); dep=HG.depth_map(cont); gp=g.load(); op=out.load()
        for y in range(16):
            for x in range(16):
                if gp[x,y][3]>0 and dep[y][x]>=2: op[x,y]=gp[x,y]
        return out,'glyph'
    out=cont.copy(); out.alpha_composite(a); return out,'object'         # a free-standing drawing: plate behind it
def variant_b32(a,rarity,element):
    return rarity_ring32(a,rarity,element),'ring32'
def p8(im,path):
    cols=sorted({p for p in im.getdata()}); idx={c:j for j,c in enumerate(cols)}; assert len(cols)<=256
    o=Image.new('P',im.size); o.putpalette(sum([list(c[:3]) for c in cols],[])+[0]*(768-3*len(cols))); o.putdata([idx[p] for p in im.getdata()]); o.save(path,optimize=True,transparency=bytes(c[3] for c in cols))
if __name__=='__main__':
    pal,_=HG.build_palette(); sk=json.load(open('assets/gamedata/skills.json')); sk=sk if isinstance(sk,list) else list(sk.values())
    ep=[v for v in sk if v['rarity'] in ('epic','legendary')]; rows=[]; mode=collections.Counter()
    for v in ep:
        k=v['id']; a=HG.snap(Image.open(f'assets/icons/skills/{k}.png').convert('RGBA'),pal)
        orig=Image.open(f'assets/icons/skills/{k}.png').convert('RGBA')
        a.save(f'{O}harmonised-epic/{k}.png',optimize=True)
        b,m=(variant_b32 if a.width==32 else variant_b16)(a,v['rarity'],v['element']); mode[m]+=1
        assert b.size==a.size,(k,b.size,a.size); p8(b,f'{O}b/{k}.png'); rows.append((k,v['rarity'],v['element'],orig,a,b,m))
    json.dump({r[0]:{'rarity':r[1],'element':r[2],'treatment':r[6],'size':list(r[5].size)} for r in rows},open(O+'index.json','w'),indent=1)
    print(len(rows),dict(mode))
    LIGHT=(233,224,201); DARK=(31,28,35); cell=60; cols=13
    n=(len(rows)+cols-1)//cols
    sh=Image.new('RGB',(cols*cell+20,n*3*cell+30),DARK); d=ImageDraw.Draw(sh)
    from PIL import ImageFont; F=ImageFont.load_default(size=11)
    d.text((10,6),'epic and legendary skills: today (top), harmonised (middle), (b) rarity frame + element colour (bottom); 3x',font=F,fill=(233,224,201))
    for i,(k,r,e,orig,a,b,m) in enumerate(rows):
        x=10+(i%cols)*cell; y=24+(i//cols)*3*cell
        for j,im in enumerate((orig,a,b)):
            sc=3 if im.width==16 else 1
            big=im.resize((im.width*sc,im.height*sc),Image.NEAREST)
            sh.paste(big,(x+(cell-4-big.width)//2,y+j*cell),big)
    sh.save('docs/art/boards/skills-epic-legendary-b.png'); print(sh.size)
