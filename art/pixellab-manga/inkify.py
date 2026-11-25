"""V1b chibi ink: V2 chibi colour icons -> ink look in code (0 gens). python3 art/pixellab-manga/inkify.py"""
import sys;sys.path.insert(0,'art/pixellab-cutpaper')
import numpy as np
from PIL import Image
from simplify import simplify
INK=(9,10,20);PAPER=(231,225,205);RED=(165,48,48)
def inkify(im):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>40;rgb=a[...,:3]
    L=rgb@np.array([.3,.59,.11]);sat=(rgb.max(2)-rgb.min(2))/np.maximum(rgb.max(2),1)
    spot=al&(sat>0.45)&(L>70)
    o=np.zeros_like(a);o[...,3]=al*255;o[...,:3]=np.where((L<85)[...,None],INK,PAPER);o[spot,:3]=RED
    pad=np.pad(al,1);edge=al&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:]);o[edge&~spot,:3]=INK
    return simplify(Image.fromarray(o.astype(np.uint8),'RGBA'),2)
if __name__=='__main__':
    for k in 'antidote dagger key helm boots shield'.split():
        inkify(Image.open(f'art/pixellab-manga/chibi/V2_{k}/get_image_0.png')).save(f'art/pixellab-manga/chibi_final/V1b_{k}32.png')
