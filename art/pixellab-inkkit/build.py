"""Ink kit: pick the PixelLab pieces, snap to the five tones + red, derive the states and the chip/tab by code, 9-slice helpers, sheet and Tower mock. python3 art/pixellab-inkkit/build.py"""
import sys,json,os,numpy as np
from PIL import Image,ImageDraw
INK=(9,10,20);DARK=(40,40,58);SH=(201,194,166);PAPER=(231,225,205);RED=(165,48,48)
PAL=np.array([INK,DARK,SH,PAPER,RED],float)
def snap(im):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>40;d=((a[...,None,:3]-PAL[None,None])**2*np.array([2,4,3])).sum(3);o=np.zeros_like(a);o[...,:3]=PAL[d.argmin(2)];o[...,3]=al*255
    return Image.fromarray(o.astype(np.uint8),'RGBA')
j=json.load(open('art/pixellab-inkkit/jobs.json'))
def raw(k,n):return Image.open(f'art/pixellab-inkkit/raw/{k}_{n}/get_image_0.png').convert('RGBA')
def crop(im):bb=im.getbbox();return im.crop(bb)
def nine(im,m,size):
    l,t,r,b=m;w,h=size;W,H=im.size;out=Image.new('RGBA',size,(0,0,0,0))
    P=[(0,l,0,t),(l,W-r,0,t),(W-r,W,0,t),(0,l,t,H-b),(l,W-r,t,H-b),(W-r,W,t,H-b),(0,l,H-b,H),(l,W-r,H-b,H),(W-r,W,H-b,H)]
    D=[(0,l,0,t),(l,w-r,0,t),(w-r,w,0,t),(0,l,t,h-b),(l,w-r,t,h-b),(w-r,w,t,h-b),(0,l,h-b,h),(l,w-r,h-b,h),(w-r,w,h-b,h)]
    for (x0,x1,y0,y1),(X0,X1,Y0,Y1) in zip(P,D):
        if x1<=x0 or y1<=y0 or X1<=X0 or Y1<=Y0:continue
        out.alpha_composite(im.crop((x0,y0,x1,y1)).resize((X1-X0,Y1-Y0),Image.NEAREST),(X0,Y0))
    return out
os.makedirs('art/pixellab-inkkit/final',exist_ok=True);F='art/pixellab-inkkit/final/'
panel=snap(crop(raw('panel',1)));button=snap(crop(raw('button',0)));bar=snap(crop(raw('bar2',0)));seal=snap(crop(raw('seal',0)))
def shift(im,dy=1):
    o=Image.new('RGBA',im.size,(0,0,0,0));o.alpha_composite(im,(0,dy));return o
def dim(im):  # disabled: red -> paper shadow, ink -> dark
    a=np.array(im).copy();red=(a[...,0]==RED[0])&(a[...,1]==RED[1]);a[red,:3]=SH;pap=(a[...,0]==PAPER[0])&(a[...,1]==PAPER[1]);a[pap,:3]=SH;return Image.fromarray(a,'RGBA')
def press(im):  # pressed: the piece one pixel lower, its top light row dropped to red/dark
    a=np.array(shift(im,1)).copy();return Image.fromarray(a,'RGBA')
chip=nine(panel,(10,10,10,10),(48,20));  # the panel's own border at chip size
# tab: the panel with the bottom border cut off, so the sides run on into what is below
pt=nine(panel,(10,10,10,10),(48,34));tab=pt.crop((0,0,48,28))
pieces={'panel':(panel,(10,10,10,10)),'button':(button,(8,7,8,7)),'button_pressed':(press(button),(8,7,8,7)),'button_disabled':(dim(button),(8,7,8,7)),'chip':(chip,(8,8,8,8)),'tab':(tab,(10,10,10,0)),'bar':(bar,(5,4,5,4)),'seal':(seal,(0,0,0,0)),'seal_pressed':(press(seal),(0,0,0,0)),'seal_disabled':(dim(seal),(0,0,0,0))}
meta={}
for k,(im,m) in pieces.items():
    im.save(f'{F}{k}.png');meta[k]={'size':list(im.size),'slice_margins_ltrb':list(m)}
json.dump(meta,open(f'{F}nine_slice.json','w'),indent=1)
# sheet: each piece 1x and 3x, then a 9-slice stretched
S=3;W=Image.new('RGBA',(10*130+10,3*120+40),(26,28,38,255));g=ImageDraw.Draw(W);BG=(231,225,205,255)
for i,(k,(im,m)) in enumerate(pieces.items()):
    x=8+(i%5)*250;y=8+(i//5)*180
    b=Image.new('RGBA',im.size,BG);b.alpha_composite(im);W.alpha_composite(b.resize((im.width*S,im.height*S),Image.NEAREST),(x,y+14));W.alpha_composite(b,(x+im.width*S+8,y+14))
    g.text((x,y),k,fill=(235,235,235))
W=W.crop((0,0,5*250+10,2*180+20));W.save('docs/art/boards/inkkit-pieces.png')
# mock Tower screen 180 x 320 at 3x
plate=Image.open('art/pixellab-cutpaper/tower/handoff/tower_shop.png').convert('RGBA').resize((180,320));c=plate.copy();d=ImageDraw.Draw(c)
c.alpha_composite(nine(panel,(10,10,10,10),(164,120)),(8,40));d.text((22,52),'FLOOR 12  THE ASH STAIR',fill=INK);d.text((22,68),'Choose one reward',fill=DARK)
for i,t in enumerate(('Skill','Die','Spell')):
    c.alpha_composite(nine(tab,(10,10,10,0),(48,26)) if i==0 else nine(dim(tab),(10,10,10,0),(48,26)),(14+i*50,14));d.text((24+i*50,23),t,fill=INK)
c.alpha_composite(nine(chip,(8,8,8,8),(60,20)),(22,92));d.text((30,98),'HP 24/30',fill=INK);c.alpha_composite(nine(chip,(8,8,8,8),(60,20)),(90,92));d.text((98,98),'Marks 12',fill=INK)
c.alpha_composite(nine(bar,(5,4,5,4),(140,16)),(22,124));d.rectangle((26,128,26+70,135),fill=RED)
c.alpha_composite(nine(button,(8,7,8,7),(150,26)),(15,170));d.text((60,178),'TAKE',fill=(255,255,255))
c.alpha_composite(nine(button_pressed:=press(button),(8,7,8,7),(72,26)),(15,206));d.text((28,214),'PRESSED',fill=(255,255,255))
c.alpha_composite(nine(dim(button),(8,7,8,7),(72,26)),(93,206));d.text((104,214),'LOCKED',fill=DARK)
c.alpha_composite(seal,(74,248));c.alpha_composite(press(seal),(30,260));c.alpha_composite(dim(seal),(120,260))
Image.alpha_composite(Image.new('RGBA',(180,320),(0,0,0,255)),c).resize((540,960),Image.NEAREST).save('docs/art/boards/inkkit-mock.png');print('ok')
