"""V2 code pass: hero-palette snap, silhouette edge = outline colour, no region under 2 px. python3 art/pixellab-icons-v2/post.py wave2 [pick.json]"""
import sys,json,os,numpy as np
sys.path.insert(0,'art/pixellab-cutpaper');from simplify import simplify
from PIL import Image
sys.path.insert(0,'art/pixellab-icons-v2')
from palette import H,PAL,RAMPS
PAL=PAL+[H('A53030'),H('4FB0B0')]
OUT=PAL[0]
# recolour a ramp of a snapped icon into another ramp by shade rank (user 25 Nov: more colour, same smooth range)
RECOLOUR={'potion_minor':('copper','red'),'potion_major':('copper','red'),'marks':('copper','ochre'),'fate_coin':('copper','ochre'),'shield_t10':('copper','ochre'),
 'circlet_radiance':('copper','ochre'),'saint_reliquary':('copper','ochre'),'sword_t5':('copper','ochre'),'sword_t10':('copper','ochre'),'spear_t10':('copper','ochre'),
 'phoenix_sigil':('copper','red'),'harborwatch_coat':('violet','blue'),'antidote':('linen','heal')}
def recolour(im,src,dst):
    a=np.array(im.convert('RGBA'));s=[H(c) for c in RAMPS[src]];t=[H(c) for c in RAMPS[dst]]
    for y,x in zip(*np.where(a[...,3]>0)):
        p=tuple(int(v) for v in a[y,x,:3])
        if p in s:a[y,x,:3]=t[s.index(p)]
    return Image.fromarray(a,'RGBA')
def snap(im):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>40;rgb=a[...,:3]
    p=np.array(PAL,float);d=((rgb[:,:,None,:]-p[None,None])**2*np.array([2,4,3])).sum(3);o=np.zeros_like(a);o[...,:3]=p[d.argmin(2)];o[...,3]=al*255
    pad=np.pad(al,1);edge=al&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:]);o[edge,:3]=OUT
    return simplify(Image.fromarray(o.astype(np.uint8),'RGBA'),2)
if __name__=='__main__':
    w=sys.argv[1];pick=json.load(open(sys.argv[2])) if len(sys.argv)>2 else {}
    j=json.load(open(f'art/pixellab-icons-v2/jobs_{w}.json'));os.makedirs(f'art/pixellab-icons-v2/final_{w}',exist_ok=True)
    for k,l in j.items():
        n=pick.get(k,len(l)-1);im=snap(Image.open(f'art/pixellab-icons-v2/raw_{w}/{k}_{n}/get_image_0.png'))
        if k in RECOLOUR:im=recolour(im,*RECOLOUR[k])
        im.save(f'art/pixellab-icons-v2/final_{w}/{k}32.png')
