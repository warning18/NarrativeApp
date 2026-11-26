"""Snap to the five tones, paint out stray black figures, sheet. python3 art/pixellab-fightplates/post.py [pick.json]"""
import sys,json,os,numpy as np
sys.path.insert(0,'art/pixellab-cutpaper')
import snap as S
from PIL import Image,ImageDraw
from scipy import ndimage
PAPER=(231,225,205);INK=(9,10,20);DARKC=(40,40,58)
SHC=(201,194,166)
def paint_out(im):
    """Remove stray figures and their ghost shadows in the lower part: compact blobs of ink, dark or paper shadow, not touching the edge, sitting on paper or paper shadow."""
    a=np.array(im.convert('RGBA'));rgb=a[...,:3].astype(int);h,w=rgb.shape[:2];cnt=0
    near=lambda c,t=30:(np.abs(rgb-np.array(c)).sum(2)<t)
    paper_like=near(PAPER)|near(SHC)
    for kind in ('dark','shadow'):
        mask=(near(INK)|near(DARKC)) if kind=='dark' else near(SHC)
        lab,n=ndimage.label(mask,structure=np.ones((3,3)))
        for i in range(1,n+1):
            m=lab==i;ys,xs=np.where(m);area=m.sum()
            if area<10 or area>1400:continue
            if ys.min()<h*0.40 or xs.min()<=1 or xs.max()>=w-2 or ys.max()>=h-2:continue
            if (xs.max()-xs.min())>46 or (ys.max()-ys.min())>72:continue
            ring=ndimage.binary_dilation(m,iterations=3)&~m
            if kind=='dark' and paper_like[ring].mean()<0.7:continue
            if kind=='shadow' and near(PAPER)[ring].mean()<0.6:continue
            a[ndimage.binary_dilation(m,iterations=1),:3]=PAPER;cnt+=1
    return Image.fromarray(a,'RGBA'),cnt
if __name__=='__main__':
    pick=json.load(open(sys.argv[1])) if len(sys.argv)>1 else {}
    j=json.load(open('art/pixellab-fightplates/jobs.json'));os.makedirs('art/pixellab-fightplates/final',exist_ok=True);tot=0
    for k,l in j.items():
        n=pick.get(k,len(l)-1);r=Image.open(f'art/pixellab-fightplates/raw/{k}_{n}/get_image_0.png').convert('RGBA');s=S.snap(r);s,c=paint_out(s);tot+=c
        s.save(f'art/pixellab-fightplates/final/fight_{k}.png')
    print('stray blobs painted out',tot)
