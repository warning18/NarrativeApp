"""Dark grade (value x0.7, saturation x0.85, a vertical darkening toward the top) then snap to the dark palette. python3 art/pixellab-shopscenes/post.py"""
import sys,json,os,colorsys,numpy as np
sys.path.insert(0,'art/pixellab-icons-v2')
import darksnap
from PIL import Image,ImageDraw
j=json.load(open('art/pixellab-shopscenes/jobs.json'));os.makedirs('art/pixellab-shopscenes/final',exist_ok=True)
def grade(im):
    a=np.array(im.convert('RGB')).astype(float)/255;h,w,_=a.shape
    mx=a.max(2);mn=a.min(2);v=mx;s=np.where(mx>0,(mx-mn)/np.maximum(mx,1e-6),0)
    f=0.7*(0.78+0.22*np.linspace(0,1,h)[:,None])    # darker toward the top (the sky)
    v2=v*f;s2=s*.85
    # rebuild rgb keeping hue
    out=np.empty_like(a)
    for y in range(h):
        for x in range(w):
            hh,_,_=colorsys.rgb_to_hsv(*a[y,x]);out[y,x]=colorsys.hsv_to_rgb(hh,s2[y,x],v2[y,x])
    return Image.fromarray((out*255).astype(np.uint8),'RGB').convert('RGBA')
ids=list(j);PAPER=(26,28,38,255)
W=Image.new('RGBA',(2*(240*2+16)+10,7*(100+6)+10),(20,20,26,255));g=ImageDraw.Draw(W)
for i,k in enumerate(ids):
    raw=Image.open(f'art/pixellab-shopscenes/raw/{k}_{len(j[k])-1}/get_image_0.png').convert('RGBA')
    d=darksnap.snap(grade(raw),0,False);d.convert('RGB').save(f'art/pixellab-shopscenes/final/{k}_shop_dark.png')
    o=Image.open(f'assets/visuals/scenes/{k}.png').convert('RGBA');x=8+(i%2)*(240*2+16);y=4+(i//2)*106
    W.alpha_composite(o,(x,y));W.alpha_composite(d,(x+244,y))
W.save('docs/art/boards/shop-scenes-dark.png');print(len(ids))
