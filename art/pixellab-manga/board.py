import sys
from PIL import Image,ImageDraw
SIZE=sys.argv[1] if len(sys.argv)>1 else '32';D=f'art/pixellab-manga/raw{SIZE}/';N=int(SIZE)
K='antidote dagger key helm boots shield'.split();S=3
W=Image.new('RGBA',(3*(6*(N*S+8))+40,N*S+60),(26,28,38,255));g=ImageDraw.Draw(W)
for vi,v in enumerate('ABC'):
    for i,k in enumerate(K):
        im=Image.open(f'{D}{v}_{k}/get_image_0.png').convert('RGBA').resize((N,N),Image.NEAREST)
        bg=Image.new('RGBA',(N,N),(231,225,205,255));bg.alpha_composite(im)
        x=10+vi*(6*(N*S+8)+10)+i*(N*S+8);W.alpha_composite(bg.resize((N*S,N*S),Image.NEAREST),(x,24))
        W.alpha_composite(bg,(x,N*S+30))
    g.text((10+vi*(6*(N*S+8)+10),6),'ABC'[vi],fill=(235,237,233))
W.save(f'art/pixellab-manga/raw_board{SIZE}.png')
