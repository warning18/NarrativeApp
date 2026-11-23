"""Compose the three screen-pilot sheets (candidates with the pick boxed + the pick on the screen's layout) and stage the picks. python3 art/pixellab-backgrounds/screens_sheets.py"""
import numpy as np, shutil
from PIL import Image, ImageDraw, ImageFont
from collections import Counter
R='art/pixellab-backgrounds/screens/raw/'; P='art/pixellab-backgrounds/screens/picks/'
F=ImageFont.load_default(size=13); FS=ImageFont.load_default(size=11); W=(233,224,201); G=(120,220,120); BG=(20,17,26)
PICK={'life_age6_sparrow':11,'life_age16_board':12,'cc_race':11,'cc_calling':11,'exp_lantern_docks':11,'exp_cinder_row':12,'exp_changeling_fen':11}
def img(k,s): return Image.open(f'{R}{k}_s{s}/get_image_0.png').convert('RGB')
for k,s in PICK.items(): img(k,s).save(f'{P}{k}.png')
def cands(keys,w,h,sc,d,sh,x0,y0):
    x=x0
    for k in keys:
        for s in (11,12):
            im=img(k,s).resize((int(w*sc),int(h*sc)),Image.NEAREST); sh.paste(im,(x,y0+16)); d.text((x,y0),f'{k} s{s}'+('  PICK' if PICK[k]==s else ''),font=FS,fill=G if PICK[k]==s else W)
            if PICK[k]==s: d.rectangle((x-3,y0+13,x+im.width+2,y0+16+im.height+2),outline=G,width=3)
            x+=im.width+10
    return x
cap=Image.open('docs/ux-shots/life-redo-build/character-choice-and-life-412-dark.png').convert('RGB'); PW=cap.width//5
def panel(i): return cap.crop((i*PW,0,(i+1)*PW,cap.height))
def fade_header(band,w,h,page):
    b=band.resize((w,int(band.height*w/band.width)),Image.NEAREST).convert('RGBA'); out=Image.new('RGBA',(w,h),(*page,255)); out.paste(b,(0,0))
    px=np.array(out).astype(float)
    for y in range(h):
        t=min(1,max(0,(y/h-0.3)/(0.78-0.3))); px[y,:,:3]=px[y,:,:3]*(1-t)+np.array(page)*t
    return Image.fromarray(px.astype(np.uint8),'RGBA').convert('RGB')
# ---- life choices ----
p5=panel(4); page=Counter(map(tuple,np.array(p5)[300:330,5:40].reshape(-1,3).tolist())).most_common(1)[0][0]
HB=(52,200)   # the header picture rows in the capture
sh=Image.new('RGB',(1500,150+16+cap.height+60),BG); d=ImageDraw.Draw(sh)
d.text((8,4),'Life choices: candidates (240x100 bands, x2) with the pick boxed, and the pick in the header of the real screen (today | pick; age 6 text; age 16 band on the same layout)',font=F,fill=W)
cands(['life_age6_sparrow','life_age16_board'],240,100,1.5,d,sh,8,26)
y=26+16+150+20
for i,(k,lab) in enumerate((('life_age6_sparrow','age 6 pick'),('life_age16_board','age 16 pick'))):
    pass
sh.paste(p5,(8,y)); d.text((8,y-14),'today',font=FS,fill=W)
for i,k in enumerate(('life_age6_sparrow','life_age16_board')):
    new=p5.copy(); hdr=fade_header(img(k,PICK[k]),PW,HB[1]-HB[0],page); new.paste(hdr,(0,HB[0])); sh.paste(new,(8+(i+1)*(PW+10),y)); d.text((8+(i+1)*(PW+10),y-14),f'{k} pick',font=FS,fill=G)
sh.crop((0,0,1500,y+cap.height+8)).save('docs/art/boards/screen-pilot-life-choices.png')
# ---- character choice ----
sh=Image.new('RGB',(8+4*(PW+10)+10,cap.height+60+0),BG); d=ImageDraw.Draw(sh)
d.text((8,4),'Character choice: today | the pick laid full-bleed behind the cards under the page colour at 70% (the calling plate is busier than the race one: 58% leaves the swords across the text) (race step, calling step); the pick boxed in the candidates below',font=F,fill=W)
def under(pan,plate,page):
    pl=plate.resize((int(plate.width*pan.height/plate.height),pan.height),Image.NEAREST); ox=(pl.width-pan.width)//2; pl=pl.crop((ox,0,ox+pan.width,pan.height))
    veil=Image.new('RGB',pan.size,page); back=Image.blend(pl,veil,0.70)
    a=np.array(pan).astype(int); m=(np.abs(a-np.array(page)).sum(-1)<8)
    out=np.array(pan); out[m]=np.array(back)[m]; return Image.fromarray(out)
pg=Counter(map(tuple,np.array(panel(0))[160:176,0:6].reshape(-1,3).tolist())).most_common(1)[0][0]
for j,(pi,k) in enumerate(((0,'cc_race'),(2,'cc_calling'))):
    pan=panel(pi); sh.paste(pan,(8+j*2*(PW+10),24)); sh.paste(under(pan,img(k,PICK[k]),pg),(8+(j*2+1)*(PW+10),24))
d.text((8,24+cap.height+2),'candidates (180x320, x1): see the second row of the sheet',font=FS,fill=W)
full=Image.new('RGB',(sh.width,sh.height+340),BG); full.paste(sh,(0,0)); d=ImageDraw.Draw(full)
cands(['cc_race','cc_calling'],180,320,1,d,full,8,sh.height)
full.save('docs/art/boards/screen-pilot-character-choice.png')
# ---- expeditions (no capture of the screen exists: a layout mock with the real proportions: app bar 56, band 412x124 above the goal line, cards) ----
sh=Image.new('RGB',(1500,72+16+500),BG); d=ImageDraw.Draw(sh)
d.text((8,4),'Expeditions: candidates (240x72 bands, x2) with the pick boxed; below, the pick as the 412x124 header band of the expedition screen (layout mock: the screen has no capture)',font=F,fill=W)
x=8
for k in ('exp_lantern_docks','exp_cinder_row','exp_changeling_fen'):
    x=cands([k],240,72,1.0,d,sh,x,22)
names={'exp_lantern_docks':'Lantern Docks','exp_cinder_row':'Cinder Row','exp_changeling_fen':'The Changeling Fen'}
y=22+16+72+16; MF=ImageFont.load_default(size=14); pg=(18,18,18)
for i,k in enumerate(names):
    scr=Image.new('RGB',(412,380),pg); sd=ImageDraw.Draw(scr); sd.rectangle((0,0,412,56),fill=(26,24,28)); sd.text((16,20),names[k],font=MF,fill=W)
    scr.paste(img(k,PICK[k]).resize((412,124),Image.NEAREST),(0,56)); sd.text((16,190),'Goal: clear the zone, then the boss',font=MF,fill=W)
    for c in range(2): sd.rectangle((12,214+c*76,400,214+c*76+64),fill=(32,29,34),outline=(80,62,40)); sd.text((24,228+c*76),['Step 1: a patrol','Step 2: the boss'][c],font=MF,fill=W)
    sh.paste(scr,(8+(i%3)*(412+10) if False else 8+i*0,y)); break
sh2=Image.new('RGB',(1500,380+y+8),BG); sh2.paste(sh.crop((0,0,sh.width,y)),(0,0))
d=ImageDraw.Draw(sh2)
for i,k in enumerate(names):
    scr=Image.new('RGB',(412,380),pg); sd=ImageDraw.Draw(scr); sd.rectangle((0,0,412,56),fill=(26,24,28)); sd.text((16,20),names[k],font=MF,fill=W)
    scr.paste(img(k,PICK[k]).resize((412,124),Image.NEAREST),(0,56)); sd.text((16,190),'Goal: clear the zone, then the boss',font=MF,fill=W)
    for c in range(2): sd.rectangle((12,214+c*76,400,214+c*76+64),fill=(32,29,34),outline=(80,62,40)); sd.text((24,228+c*76),['Step 1: a patrol','Step 2: the boss'][c],font=MF,fill=W)
    sh2.paste(scr,(8+i*(412+10),y))
sh2.save('docs/art/boards/screen-pilot-expeditions.png'); print('ok',sh2.size)
