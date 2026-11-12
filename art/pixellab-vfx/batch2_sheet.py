"""Stage batch 1's ten in Apollo + 2 core brights (shadow hand-walked through Apollo's purples) next to the six and batch 2, and build docs/art/boards/skill-effects-batch2.png
(all 26 effects, own colours above, Apollo below). python3 art/pixellab-vfx/batch2_sheet.py"""
import sys, os
sys.path.insert(0,'tool'); sys.path.insert(0,'.')
from apollo_remap import remap
from apollo_skills import ramp
from PIL import Image, ImageDraw, ImageFont
OUT='art/pixellab-apollo-skills/vfx/'
SIX=['flame','frost','lightning','heal','void_rift','shield']
B1=['radiance','shout','stone_shield','arrow','shadow','pierce','heavy_slash','poison','splash','impact']
B2=['holy_fire','quake','drain','fireball','wind','whirl','smoke','volley','claw','slash']
src={**{s:f'art/pixellab-vfx/final/vfx_{s}.png' for s in SIX},**{s:f'art/pixellab-vfx/batch1/final/vfx_{s}.png' for s in B1},**{s:f'art/pixellab-vfx/batch2/final/vfx_{s}.png' for s in B2}}
for s in B1:
    im=Image.open(src[s]).convert('RGBA')
    new=ramp(im,None) if s=='shadow' else remap(im,pal='apollo+cores')
    new.save(OUT+f'vfx_{s}.png')
S=2; fw=48*S; lab=84; F=ImageFont.load_default(size=11); allst=SIX+B1+B2; per=13
rowh=2*(fw+3)+6
sh=Image.new('RGB',(2*(lab+9*fw+14),per*rowh+22),(20,17,26)); d=ImageDraw.Draw(sh)
d.text((6,3),'26 skill effects in Apollo 46 + 2 core brights: own colours (top) | Apollo (bottom). Six pilot, batch 1 (10), batch 2 (10).',font=F,fill=(233,224,201))
for i,s in enumerate(allst):
    col,row=divmod(i,per); x0=col*(lab+9*fw+14); y=22+row*rowh
    tag=' (b2)' if s in B2 else ' (b1)' if s in B1 else ''
    d.text((x0+4,y+fw-6),s+tag,font=F,fill=(233,224,201))
    for j,pth in enumerate((src[s],OUT+f'vfx_{s}.png')):
        im=Image.open(pth).convert('RGBA'); a=im.resize((im.width*S,im.height*S),Image.NEAREST); sh.paste(a,(x0+lab,y+j*(fw+3)),a)
sh.save('docs/art/boards/skill-effects-batch2.png'); print(sh.size)
