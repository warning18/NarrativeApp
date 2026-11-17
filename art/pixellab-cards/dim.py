"""Deep re-tone of the five card frames (UX-2's table, remap_frames.py 'deep'): every light tone two steps down the Apollo ramps. 0 generations.
python3 art/pixellab-cards/dim.py"""
import sys; sys.path.insert(0,'art/pixellab-cards')
from PIL import Image
import build as B
def h(s): return tuple(int(s[i:i+2],16) for i in (0,2,4))
DEEP={'common':{'EBEDE9':'394A50','A8B5B2':'394A50','577277':'202E37','394A50':'151D28'},
 'uncommon':{'FFF6E0':'BE772B','DA863E':'884B2B','884B2B':'602C2C','602C2C':'411D31'},
 'rare':{'EBEDE9':'819796','C7CFCC':'577277','819796':'394A50','394A50':'202E37','73BED3':'3C5E8B'},
 'epic':{'EBEDE9':'819796','E8C170':'BE772B','DE9E41':'884B2B','884B2B':'602C2C','BE772B':'884B2B'},
 'legendary':{'FFF6E0':'DE9E41','EBEDE9':'BE772B','E8C170':'BE772B','BE772B':'884B2B','DE9E41':'BE772B'}}
F='art/pixellab-cards/final/'
for t,tab in DEEP.items():
    im=Image.open(f'{F}frame_{t}.png').convert('RGBA');m={h(k):h(v) for k,v in tab.items()};px=im.load();hit=0
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=px[x,y]
            if a and (r,g,b) in m: px[x,y]=(*m[(r,g,b)],a);hit+=1
    B.png8(im,f'{F}frame_{t}_dim.png');print(t,hit,Image.open(f'{F}frame_{t}_dim.png').size)
