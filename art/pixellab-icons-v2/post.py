"""V2 code pass: hero-palette snap, silhouette edge = outline colour, no region under 2 px. python3 art/pixellab-icons-v2/post.py wave2 [pick.json]"""
import sys,json,os,numpy as np
sys.path.insert(0,'art/pixellab-cutpaper');from simplify import simplify
from PIL import Image
H=lambda s:tuple(int(s[i:i+2],16) for i in (0,2,4))
PAL=[H(x) for x in '010000 23252A 3B4043 544443 6F5A4C 8F7665 8D8278 B8ACA1 B6A48F E1D7C0 FDFCFC EBBB9F C9936F E99253 5E2D66 A53030 7DBE6A 4FB0B0'.split()]
OUT=PAL[0]
def snap(im):
    a=np.array(im.convert('RGBA')).astype(float);al=a[...,3]>40;rgb=a[...,:3]
    p=np.array(PAL,float);d=((rgb[:,:,None,:]-p[None,None])**2*np.array([2,4,3])).sum(3);o=np.zeros_like(a);o[...,:3]=p[d.argmin(2)];o[...,3]=al*255
    pad=np.pad(al,1);edge=al&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:]);o[edge,:3]=OUT
    return simplify(Image.fromarray(o.astype(np.uint8),'RGBA'),2)
if __name__=='__main__':
    w=sys.argv[1];pick=json.load(open(sys.argv[2])) if len(sys.argv)>2 else {}
    j=json.load(open(f'art/pixellab-icons-v2/jobs_{w}.json'));os.makedirs(f'art/pixellab-icons-v2/final_{w}',exist_ok=True)
    for k,l in j.items():
        n=pick.get(k,len(l)-1);snap(Image.open(f'art/pixellab-icons-v2/raw_{w}/{k}_{n}/get_image_0.png')).save(f'art/pixellab-icons-v2/final_{w}/{k}32.png')
