"""The intro's die: a hand-drawn bone face set (32 px faces 1 to 6) for the Die3D cube, plus an isometric preview. 0 generations. Repo root."""
import math
from PIL import Image, ImageDraw, ImageFont
O='art/pixellab-intro-b/'
INK=(10,8,7,255); BONE=(233,223,196,255); HI=(250,242,218,255); LO=(184,168,134,255); RIM=(150,128,92,255); RED=(190,60,50,255); REDH=(230,120,110,255)
PIPS={1:[(1,1)],2:[(0,0),(2,2)],3:[(0,0),(1,1),(2,2)],4:[(0,0),(2,0),(0,2),(2,2)],5:[(0,0),(2,0),(1,1),(0,2),(2,2)],6:[(0,0),(2,0),(0,1),(2,1),(0,2),(2,2)]}
def face(n,S=32):
    im=Image.new('RGBA',(S,S),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.rectangle((0,0,S-1,S-1),fill=INK); d.rectangle((1,1,S-2,S-2),fill=RIM); d.rectangle((2,2,S-3,S-3),fill=BONE)
    d.line([(2,2),(S-3,2)],fill=HI); d.line([(2,2),(2,S-3)],fill=HI); d.line([(2,S-3),(S-3,S-3)],fill=LO); d.line([(S-3,2),(S-3,S-3)],fill=LO)
    for cx,cy in PIPS[n]:
        x=6+cx*8; y=6+cy*8; col=RED if n==1 else INK
        d.rectangle((x,y+1,x+4,y+3),fill=col); d.rectangle((x+1,y,x+3,y+4),fill=col)       # a rounded 5x5 pip
        d.point((x+1,y+1),fill=REDH if n==1 else (70,60,54,255))
    return im
def iso(faces3,S=32,scale=3):
    W=int(S*2.2); H=int(S*2.4); out=Image.new('RGBA',(W,H),(0,0,0,0)); px=out.load(); top,left,right=faces3
    k=S*0.866; h=S*0.5; ox=W/2; oy=H*0.12
    def draw(face,m):
        a,b,c,d_,e,f=m; det=a*d_-b*c
        for y in range(H):
            for x in range(W):
                xx=x-e; yy=y-f; u=(d_*xx-b*yy)/det; v=(-c*xx+a*yy)/det
                if 0<=u<S and 0<=v<S:
                    p=face.getpixel((int(u),int(v)))
                    if p[3]: px[x,y]=p
    draw(top,(k/S,-k/S,h/S,h/S,ox,oy)); draw(left,(k/S,0,h/S,1.0,ox-k,oy+h)); draw(right,(k/S,0,-h/S,1.0,ox,oy+2*h))
    return out.resize((W*scale,H*scale),Image.NEAREST)
if __name__=='__main__':
    faces={n:face(n) for n in range(1,7)}
    for n,f in faces.items(): f.save(O+f'die/face{n}.png',optimize=True)
    cube=iso((faces[1],faces[2],faces[3])); cube.save(O+'die/cube_preview.png')
    DARK=(31,28,35); F=ImageFont.load_default(size=13)
    sh=Image.new('RGB',(1100,330),DARK); d=ImageDraw.Draw(sh)
    d.text((10,8),"The intro die: today the big plain cube is drawn in code (Die3D); proposal: the game's bone skin",font=F,fill=(233,224,201))
    body=Image.open('art/pixellab-pilots/final/dice/die_d6_bone_48.png').convert('RGBA'); b=body.resize((192,192),Image.NEAREST); sh.paste(b,(20,50),b); d.text((20,248),"the game's bone d6 body (48 px)",font=F,fill=(233,224,201))
    for i in range(1,7): f=faces[i].resize((96,96),Image.NEAREST); sh.paste(f,(250+((i-1)%3)*108,50+((i-1)//3)*108),f)
    d.text((250,270),'proposed bone face set: 32 px faces 1 to 6 (hand-drawn, a red one)',font=F,fill=(233,224,201))
    sh.paste(cube,(650,40),cube); d.text((650,280),'preview: faces 1 (top), 2, 3',font=F,fill=(233,224,201))
    sh.save('docs/art/boards/intro-die-bone.png')
