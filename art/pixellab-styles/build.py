"""Stage the picked style-test pieces (PNG8, limited palettes) and build the sheets. python3 art/pixellab-styles/build.py"""
import sys, numpy as np; sys.path.insert(0,'art/pixellab-styles'); sys.path.insert(0,'art/pixellab-cards')
import post, build as CB
from PIL import Image, ImageDraw
R='art/pixellab-styles/raw/'; F='art/pixellab-styles/final/'
PICK={'style1':{'panel':2,'button':2,'plate':1,'d6':1,'d12':1,'hero':2,'combat':1},'style2':{'panel':2,'button':2,'plate':1,'d6':1,'d12':1,'hero':2,'combat':1}}
BOX=(8,120,44,165)
def proc(st,k,s):
    im=Image.open(f'{R}{st}_{k}_s{s}/get_image_0.png').convert('RGBA')
    return post.style1(im,box=BOX) if (st=='style1' and k=='combat') else post.style1(im) if st=='style1' else post.style2(im)
SUBJ=['panel','button','plate','d6','d12','hero','combat']
TODAY={'panel':'art/pixellab-styles/skel/panel.png','button':'art/pixellab-styles/skel/button.png','plate':'art/pixellab-styles/skel/plate.png','d6':'assets/visuals/dice/die_d6_bone_44.png','d12':'assets/visuals/dice/die_d12_bone_44.png','hero':'art/pixellab-styles/skel/hero.png','combat':'assets/visuals/fight_plates/quay.png'}
def get(col,k):
    if col=='today': return Image.open(TODAY[k]).convert('RGBA')
    return Image.open(f'{F}{col}_{k}.png').convert('RGBA')
def layout(cols,sc,out,labels=True):
    cw=190*sc; W=Image.new('RGBA',(len(cols)*cw+10*sc,(72+24+44+48+30)*sc+330*sc),(26,28,38,255)); g=ImageDraw.Draw(W)
    for c,col in enumerate(cols):
        x0=5*sc+c*cw
        if labels: g.text((x0,2*sc),col,fill=(235,237,233))
        y=14*sc
        for ks in (['panel'],['button','plate'],['d6','d12','hero']):
            x=x0;hh=0
            for k in ks:
                im=get(col,k);im=im.resize((im.width*sc,im.height*sc),0);W.alpha_composite(im,(x,y));x+=im.width+6*sc;hh=max(hh,im.height)
            y+=hh+6*sc
        im=get(col,'combat');im=im.resize((im.width*sc,im.height*sc),0);W.alpha_composite(im,(x0,y))
    W.save(out)
if __name__=='__main__':
    for st in PICK:
        for k in SUBJ:
            CB.png8(proc(st,k,PICK[st][k]),f'{F}{st}_{k}.png')
        # alternates
        for k in SUBJ:
            alt=3-PICK[st][k]; CB.png8(proc(st,k,alt),f'{F}alt_{st}_{k}.png')
    B='docs/art/boards/'
    for sc in (1,2):
        layout(['today','style1','style2'],sc,f'{B}style-test-compare-{sc}x.png')
        for st in PICK: layout([st],sc,f'{B}style-test-{st}-{sc}x.png')
