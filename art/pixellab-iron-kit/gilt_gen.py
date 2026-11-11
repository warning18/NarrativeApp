"""A richer gilt tier (the reward for winning a climb): blackened steel with a heavy GOLD edge band, riveted, gold corner plates. Same files, sizes and 9-slice insets as the kit
(anchors.json): it overwrites materials/gilt/ui/ so UX-2 swaps files with no code change. Hand-drawn in code, 0 generations. Repo root: python3 art/pixellab-iron-kit/gilt_gen.py"""
import sys, os
sys.path.insert(0,'art/pixellab-iron-kit')
import iron_gen as K
from iron_gen import H, INK, new, stretch
from PIL import Image, ImageDraw, ImageFont
O='art/pixellab-iron-kit/materials/'
GOLD=dict(m=H('#D4A63A'),hi=H('#FFE08A'),lo=H('#8A6420'),dk=H('#5A400E'))
STEEL=dict(m=H('#2E2B36'),hi=H('#56506A'),lo=H('#141219'))
def gilt_frame(w,h,inner,ink=2,band=3,chamfer=3,plate=7,rivet_every=8,soft=False):
    im=new(w,h); d=ImageDraw.Draw(im); P=GOLD
    def box(inset,col):
        c=max(0,chamfer-inset); x0=y0=inset; x1=w-1-inset; y1=h-1-inset
        d.rectangle((x0+c,y0,x1-c,y1),fill=col); d.rectangle((x0,y0+c,x1,y1-c),fill=col)
    box(0,INK); box(ink,P['m'])
    b0=ink
    d.line([(b0+chamfer-1,b0),(w-1-b0-chamfer+1,b0)],fill=P['hi']); d.line([(b0,b0+chamfer-1),(b0,h-1-b0-chamfer+1)],fill=P['hi'])
    d.line([(b0+chamfer-1,h-1-b0),(w-1-b0-chamfer+1,h-1-b0)],fill=P['lo']); d.line([(w-1-b0,b0+chamfer-1),(w-1-b0,h-1-b0-chamfer+1)],fill=P['lo'])
    # the blackened steel inset between the gold band and the field
    i0=ink+band; d.rectangle((i0,i0,w-1-i0,h-1-i0),fill=STEEL['m']); d.rectangle((i0,i0,w-1-i0,i0),fill=STEEL['lo']); d.rectangle((i0,i0,i0,h-1-i0),fill=STEEL['lo'])
    f0=i0+1; d.rectangle((f0,f0,w-1-f0,h-1-f0),fill=INK); d.rectangle((f0+1,f0+1,w-2-f0,h-2-f0),fill=inner)
    # rivets on the edge middle (the tiled part): every rivet_every px, centred in the band
    mid=ink+band//2
    for x in range(plate+3,w-plate-3):
        if (x-plate-3)%rivet_every==rivet_every//2-1:
            for yy in (mid,h-1-mid): d.point((x,yy),fill=P['dk']); 
            d.point((x,mid-0),fill=P['dk']); d.point((x,h-1-mid),fill=P['dk'])
    for y in range(plate+3,h-plate-3):
        if (y-plate-3)%rivet_every==rivet_every//2-1:
            for xx in (mid,w-1-mid): d.point((xx,y),fill=P['dk'])
    # corner plates: gold squares with a rivet, over the band and a little into the field
    for cx,cy in ((0,0),(w-plate,0),(0,h-plate),(w-plate,h-plate)):
        d.rectangle((cx,cy,cx+plate-1,cy+plate-1),fill=INK); d.rectangle((cx+1,cy+1,cx+plate-2,cy+plate-2),fill=P['m'])
        d.line([(cx+1,cy+1),(cx+plate-2,cy+1)],fill=P['hi']); d.line([(cx+1,cy+1),(cx+1,cy+plate-2)],fill=P['hi'])
        d.line([(cx+1,cy+plate-2),(cx+plate-2,cy+plate-2)],fill=P['lo']); d.line([(cx+plate-2,cy+1),(cx+plate-2,cy+plate-2)],fill=P['lo'])
        r=plate//2; d.rectangle((cx+r-1,cy+r-1,cx+r,cy+r),fill=P['dk']); d.point((cx+r-1,cy+r-1),fill=P['hi'])
    # round off the outer corners of the plates (chamfer the three outer pixels)
    for (x,y) in ((0,0),(w-1,0),(0,h-1),(w-1,h-1)): im.putpixel((x,y),(0,0,0,0))
    return im
def button(kind,state):
    P=GOLD; f,hi,lo=(H('#34313E'),H('#56506A'),H('#17151D'))
    if kind=='primary': f,hi=H('#3B3748'),H('#6A6480')
    if state=='disabled': f,hi,lo=H('#2A2830'),H('#34323C'),H('#1A191F')
    im=new(24,16); d=ImageDraw.Draw(im)
    for r in ((2,0,21,15),(0,2,23,13),(1,1,22,14)): d.rectangle(r,fill=INK)
    gb=P if state!='disabled' else dict(m=H('#5A5238'),hi=H('#6A6244'),lo=H('#3A3524'),dk=H('#2A2518'))
    d.rectangle((2,2,21,13),fill=gb['m']); d.rectangle((1,3,22,12),fill=gb['m'])             # the gold border
    d.rectangle((4,4,19,11),fill=f); d.rectangle((3,5,20,10),fill=f)                            # the steel face
    d.line([(3,2),(20,2)],fill=gb['hi']); d.line([(1,4),(1,11)],fill=gb['hi']); d.line([(3,13),(20,13)],fill=gb['lo']); d.line([(22,4),(22,11)],fill=gb['lo'])
    if state=='pressed':
        d.rectangle((4,4,19,11),fill=tuple(int(v*.8) for v in f[:3])+(255,)); d.line([(4,4),(19,4)],fill=lo)
    else:
        d.line([(4,4),(19,4)],fill=hi)
    if state!='disabled':
        for x,y in ((2,3),(21,3),(2,12),(21,12)): d.point((x,y),fill=gb['dk'])               # corner rivets
        for x,y in ((3,3),(20,3),(3,12),(20,12)): d.point((x,y),fill=gb['hi'])
    return im
def tab():
    im=new(20,14); d=ImageDraw.Draw(im); P=GOLD
    d.rectangle((3,0,16,13),fill=INK); d.rectangle((0,3,19,13),fill=INK); d.rectangle((3,2,16,13),fill=STEEL['m']); d.rectangle((2,3,17,13),fill=STEEL['m'])
    d.line([(3,2),(16,2)],fill=P['m']); d.line([(2,3),(2,13)],fill=P['m']); d.line([(17,3),(17,13)],fill=P['lo']); d.line([(3,3),(16,3)],fill=P['hi']); d.point((5,7),fill=P['hi']); d.point((14,7),fill=P['hi']); return im
def chip():
    im=new(16,12); d=ImageDraw.Draw(im); P=GOLD
    d.rectangle((2,0,13,11),fill=INK); d.rectangle((0,2,15,9),fill=INK); d.rectangle((2,2,13,9),fill=STEEL['m']); d.rectangle((1,3,14,8),fill=STEEL['m'])
    d.line([(2,2),(13,2)],fill=P['m']); d.line([(2,9),(13,9)],fill=P['lo']); return im
def divider():
    im=new(24,6); d=ImageDraw.Draw(im); P=GOLD
    d.rectangle((0,1,23,4),fill=INK); d.rectangle((0,2,23,3),fill=P['m']); d.line([(0,2),(23,2)],fill=P['hi']); d.line([(0,3),(23,3)],fill=P['lo'])
    for x in (2,21): d.rectangle((x,1,x+1,4),fill=P['hi']); d.point((x+1,4),fill=INK)
    d.point((12,2),fill=P['dk']); return im
def corner():
    im=new(12,12); d=ImageDraw.Draw(im); P=GOLD
    d.rectangle((0,0,11,3),fill=INK); d.rectangle((0,0,3,11),fill=INK); d.rectangle((1,1,10,2),fill=P['m']); d.rectangle((1,1,2,10),fill=P['m'])
    d.line([(1,1),(10,1)],fill=P['hi']); d.line([(1,1),(1,10)],fill=P['hi']); d.rectangle((2,2,3,3),fill=P['hi']); d.point((3,3),fill=P['dk']); return im
if __name__=='__main__':
    out=O+'gilt/ui/'; os.makedirs(out,exist_ok=True)
    INNER={'dark':H('#26202C'),'parchment':H('#E4D7B6')}
    gilt_frame(24,24,INNER['dark'],plate=7).save(out+'panel_dark.png',optimize=True)
    gilt_frame(24,24,INNER['parchment'],plate=7).save(out+'panel_parchment.png',optimize=True)
    gilt_frame(16,16,H('#1B1620'),ink=1,band=2,chamfer=2,plate=5,rivet_every=99).save(out+'hud_panel.png',optimize=True)
    gilt_frame(32,32,INNER['parchment'],ink=2,band=4,chamfer=4,plate=10).save(out+'dialog.png',optimize=True)
    for k in ('primary','secondary'):
        for s in ('normal','pressed','disabled'): button(k,s).save(out+f'button_{k}_{s}.png',optimize=True)
    tab().save(out+'tab.png',optimize=True); chip().save(out+'chip.png',optimize=True); divider().save(out+'divider.png',optimize=True); corner().save(out+'corner.png',optimize=True)
    # ---------- the sheet: wood, iron, silver, gilt (panel + 2 buttons), light and dark, real size and 3x ----------
    tiers=['wood','iron','silver','gilt']; LIGHT=(233,224,201); DARK=(31,28,35); F=ImageFont.load_default(size=13)
    def load(t,k): return Image.open(f'{O}{t}/ui/{k}.png').convert('RGBA')
    def stage(t,bg,sc):
        pan=stretch(load(t,'panel_dark'),72,52,8); b1=stretch(load(t,'button_secondary_normal'),56,18,6); b2=stretch(load(t,'button_primary_normal'),56,18,6); b3=stretch(load(t,'button_primary_pressed'),56,18,6)
        tile=Image.new('RGB',(72+8+56+8,52+4+22),bg); tile.paste(pan,(0,2),pan); tile.paste(b1,(80,2),b1); tile.paste(b2,(80,22),b2); tile.paste(b3,(80,42),b3)
        return tile.resize((tile.width*sc,tile.height*sc),Image.NEAREST)
    rowh=(52+4+22)*3+16; sh=Image.new('RGB',(2*(150+450)+30,len(tiers)*rowh+20),LIGHT); d=ImageDraw.Draw(sh)
    for half,bg in enumerate((LIGHT,DARK)):
        x0=10+half*610; d.rectangle((x0-5,0,x0+605,sh.height),fill=bg)
        for r,t in enumerate(tiers):
            y=10+r*rowh; d.text((x0,y),t,font=F,fill=(35,31,26) if half==0 else (233,224,201)); sh.paste(stage(t,bg,1),(x0,y+20)); sh.paste(stage(t,bg,3),(x0+150,y))
    sh.save('docs/art/boards/gilt-tier.png')
    # the dialog and HUD panel of the four tiers (3x)
    lad=Image.new('RGB',(4*250+10,240),DARK); d2=ImageDraw.Draw(lad)
    for i,t in enumerate(tiers):
        x=10+i*250; d2.text((x,4),t,font=F,fill=(233,224,201)); dg=stretch(load(t,'dialog'),64,48,12); hd=stretch(load(t,'hud_panel'),64,20,5)
        lad.paste(dg.resize((192,144),Image.NEAREST),(x,24),dg.resize((192,144),Image.NEAREST)); lad.paste(hd.resize((192,60),Image.NEAREST),(x,172),hd.resize((192,60),Image.NEAREST))
    lad.save('docs/art/boards/gilt-tier-dialog-hud.png'); print('ok')
