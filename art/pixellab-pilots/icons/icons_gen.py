from PIL import Image,ImageDraw
def H(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))+(255,)
# the icon palette: lib/theme/palette.dart tokens + the ronin's browns and greys
PAL={'ink':H('#17120F'),'bone':H('#E9DFC4'),'steel':H('#A8A194'),'steel_d':H('#6B6356'),'ash':H('#CFC4AE'),
 'gold':H('#F2C14E'),'gold_d':H('#B8862A'),'blood':H('#D9544D'),'blood_d':H('#A5302A'),'ember':H('#E0762B'),'ember_d':H('#A84E12'),
 'tide':H('#4FB0B0'),'tide_d':H('#226565'),'heal':H('#7DBE6A'),'heal_d':H('#3D7A2C'),'void':H('#A987EA'),'void_d':H('#6A4FB0'),
 'wood':H('#8A5A2B'),'wood_d':H('#5A3A1C'),'ice':H('#CFE6F2'),'white':H('#FFFFFF')}
def mix(a,b,t): return tuple(int(round(a[i]+(b[i]-a[i])*t)) for i in range(3))+(255,)
def canvas(n=16): 
    im=Image.new('RGBA',(n,n),(0,0,0,0)); return im,ImageDraw.Draw(im)
def finish(im,outline=True,light=True):
    """the style guide's two rules, applied by code: 1 px ink outline, light from the top-left"""
    n=im.width; src=im.load(); out=Image.new('RGBA',(n,n),(0,0,0,0)); px=out.load()
    ink=PAL['ink']
    def op(x,y): return 0<=x<n and 0<=y<n and src[x,y][3]>0
    for y in range(n):
        for x in range(n):
            if src[x,y][3]>0:
                c=src[x,y]
                if light and c[:3]!=ink[:3]:
                    tl=not op(x-1,y) or not op(x,y-1); br=not op(x+1,y) or not op(x,y+1)
                    if tl and not br: c=mix(c,(255,255,255,255),0.28)
                    elif br and not tl: c=mix(c,(0,0,0,255),0.28)
                px[x,y]=c
    if outline:
        big=Image.new('RGBA',(n+2,n+2),(0,0,0,0)); bp=big.load()
        for y in range(n):
            for x in range(n):
                if px[x,y][3]>0: bp[x+1,y+1]=px[x,y]
        res=big.copy(); rp=res.load()
        for y in range(n+2):
            for x in range(n+2):
                if bp[x,y][3]==0 and any(0<=x+dx<n+2 and 0<=y+dy<n+2 and bp[x+dx,y+dy][3]>0 for dx,dy in ((1,0),(-1,0),(0,1),(0,-1))): rp[x,y]=ink
        return res
    return out
def P(d,pts,c): d.polygon([tuple(p) for p in pts],fill=PAL[c])
def R(d,x0,y0,x1,y1,c): d.rectangle((x0,y0,x1,y1),fill=PAL[c])
def L(d,pts,c,w=1): d.line([tuple(p) for p in pts],fill=PAL[c],width=w)
def E(d,x0,y0,x1,y1,c): d.ellipse((x0,y0,x1,y1),fill=PAL[c])
# ---------- world icons (full colour, 14x14 drawn area -> 16x16 after the outline) ----------
def flame():
    im,d=canvas(14); P(d,[(7,0),(9,3),(11,6),(11,9),(9,13),(5,13),(3,9),(3,6),(5,4),(6,2)],'ember'); P(d,[(7,6),(9,8),(9,11),(7,12),(5,11),(5,8)],'gold'); return finish(im)
def die():
    im,d=canvas(14); R(d,1,1,12,12,'bone'); 
    for x,y in ((3,3),(9,3),(6,6),(3,9),(9,9)): R(d,x,y,x+1,y+1,'ink')
    return finish(im,light=True)
def shield():
    im,d=canvas(14); P(d,[(2,1),(11,1),(11,7),(6,13),(2,7)],'steel'); R(d,6,2,7,10,'gold'); R(d,3,4,10,5,'gold'); return finish(im)
def anchor():
    im,d=canvas(14); E(d,5,0,8,3,'steel'); E(d,6,1,7,2,'ink'); R(d,6,3,7,11,'steel'); R(d,3,4,10,5,'steel'); L(d,[(1,8),(3,11),(6,12)],'steel',2); L(d,[(12,8),(10,11),(7,12)],'steel',2); return finish(im)
def bolt(col='gold'):
    im,d=canvas(14); P(d,[(8,0),(3,8),(6,8),(5,13),(11,5),(7,5)],col); return finish(im)
def sparkle():
    im,d=canvas(14); P(d,[(6,0),(8,5),(13,6),(8,8),(6,13),(4,8),(0,6),(4,5)],'gold'); return finish(im)
def heart():
    im,d=canvas(14); E(d,1,1,7,7,'blood'); E(d,6,1,12,7,'blood'); P(d,[(1,5),(12,5),(6,12)],'blood'); return finish(im)
def sword():
    im,d=canvas(14); P(d,[(11,0),(13,0),(13,2),(6,9),(4,7)],'steel'); P(d,[(2,6),(7,11),(8,10),(3,5)],'gold'); L(d,[(3,10),(1,12)],'wood',2); return finish(im)
def drop():
    im,d=canvas(14); P(d,[(6,0),(10,7),(10,9),(6,13),(2,9),(2,7)],'tide'); R(d,4,8,5,9,'ice'); return finish(im)
def skull():
    im,d=canvas(14); E(d,1,0,11,9,'bone'); R(d,3,8,8,12,'bone'); R(d,3,4,4,6,'ink'); R(d,7,4,8,6,'ink'); R(d,5,7,6,7,'ink'); R(d,4,10,4,12,'ink'); R(d,7,10,7,12,'ink'); return finish(im)
def ice():
    im,d=canvas(14); 
    for a,b in (((6,0),(6,13)),((0,3),(12,10)),((0,10),(12,3))): L(d,[a,b],'ice',2)
    R(d,5,5,7,7,'tide'); return finish(im)
def holy():
    im,d=canvas(14); E(d,3,3,9,9,'gold'); 
    for a,b in (((6,0),(6,2)),((6,10),(6,12)),((0,6),(2,6)),((10,6),(12,6)),((1,1),(2,2)),((10,10),(11,11)),((10,1),(11,2)),((1,10),(2,11))): L(d,[a,b],'gold',1)
    return finish(im)
def dark():
    im,d=canvas(14); E(d,1,1,12,12,'void_d'); E(d,5,1,13,11,'ink'); E(d,2,2,6,8,'void'); return finish(im)
def none_():
    im,d=canvas(14); d.ellipse((1,1,12,12),outline=PAL['steel'],width=2); L(d,[(3,10),(10,3)],'steel',2); return finish(im)
def ship():
    im,d=canvas(14); P(d,[(0,9),(13,9),(10,13),(3,13)],'wood'); R(d,6,1,7,9,'wood_d'); P(d,[(7,1),(12,7),(7,7)],'bone'); return finish(im)
def signpost():
    im,d=canvas(14); R(d,6,1,7,13,'wood_d'); P(d,[(2,2),(10,2),(12,4),(10,6),(2,6)],'wood'); P(d,[(4,8),(11,8),(11,11),(4,11),(2,9)],'wood'); return finish(im)
def scroll():
    im,d=canvas(14); R(d,2,2,11,11,'bone'); E(d,0,0,13,3,'ash'); E(d,0,10,13,13,'ash'); L(d,[(4,5),(9,5)],'steel_d'); L(d,[(4,7),(9,7)],'steel_d'); return finish(im)
def potion():
    im,d=canvas(14); R(d,5,0,8,2,'wood'); R(d,5,3,8,5,'ash'); E(d,1,5,12,13,'heal'); R(d,3,8,4,9,'heal_d') ; return finish(im)
# ---------- chrome glyphs (tintable: white + alpha, no outline) ----------
def chrome(fn):
    im=fn(); return im
def chev():
    im,d=canvas(16); P(d,[(4,2),(7,2),(12,8),(7,14),(4,14),(9,8)],'white'); return im
def lock():
    im,d=canvas(16); R(d,3,7,12,14,'white'); R(d,5,2,6,7,'white'); R(d,9,2,10,7,'white'); R(d,5,2,10,3,'white'); R(d,7,10,8,12,'ink'); return im
def check():
    im,d=canvas(16); P(d,[(2,8),(4,6),(6,9),(12,3),(14,5),(6,13)],'white'); return im
def close():
    im,d=canvas(16); L(d,[(3,3),(12,12)],'white',2); L(d,[(12,3),(3,12)],'white',2); return im
def add():
    im,d=canvas(16); R(d,7,3,8,12,'white'); R(d,3,7,12,8,'white'); return im
def arrow():
    im,d=canvas(16); R(d,2,7,9,8,'white'); P(d,[(8,3),(14,8),(8,13)],'white'); return im
def flag():
    im,d=canvas(16); R(d,3,2,4,14,'white'); P(d,[(5,3),(13,3),(10,6),(13,9),(5,9)],'white'); return im
def home():
    im,d=canvas(16); P(d,[(8,1),(15,8),(13,8),(13,14),(3,14),(3,8),(1,8)],'white'); R(d,7,9,8,14,'ink'); return im
def mapg():
    im,d=canvas(16); P(d,[(1,3),(5,2),(10,4),(15,3),(15,13),(10,14),(5,12),(1,13)],'white'); L(d,[(5,2),(5,12)],'ink'); L(d,[(10,4),(10,14)],'ink'); return im
def gear():
    im,d=canvas(16); E(d,3,3,12,12,'white'); 
    for x,y in ((7,0),(7,13),(0,7),(13,7),(2,2),(11,2),(2,11),(11,11)): R(d,x,y,x+1,y+1,'white')
    E(d,6,6,9,9,'ink'); return im
def tint(im,col):
    out=Image.new('RGBA',im.size,(0,0,0,0)); sp=im.load(); op=out.load(); n=im.width
    for y in range(n):
        for x in range(n):
            if sp[x,y][3]>0:
                if sp[x,y][:3]==PAL['ink'][:3]: continue
                op[x,y]=col+(255,) if len(col)==3 else col
    return out
WORLD={'flame':flame,'die':die,'shield':shield,'anchor':anchor,'bolt_gold':lambda:bolt('gold'),'bolt_tide':lambda:bolt('tide'),'sparkle':sparkle,'heart':heart,'sword':sword,'drop':drop,'skull':skull,'ice':ice,'holy':holy,'dark':dark,'none':none_,'ship':ship,'signpost':signpost,'scroll':scroll,'potion':potion}
CHROME={'chevron_right':chev,'lock':lock,'check':check,'close':close,'add':add,'arrow_forward':arrow,'flag':flag,'home':home,'map':mapg,'settings':gear}
def person():
    im,d=canvas(16); E(d,5,1,10,6,'white'); P(d,[(2,14),(2,11),(5,8),(10,8),(13,11),(13,14)],'white'); return im
def dots():
    im,d=canvas(16); 
    for x in (2,7,12): R(d,x,7,x+2,9,'white')
    return im
CHROME['person']=person; CHROME['more_horiz']=dots
