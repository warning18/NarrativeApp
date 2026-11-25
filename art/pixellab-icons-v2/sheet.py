import sys,glob,os,json
sys.path.insert(0,'art/pixellab-icons-v2');from PIL import Image,ImageDraw
w=sys.argv[1];ids=list(__import__(f'{w}_ids').IDS);fs=[f'art/pixellab-icons-v2/final_{w}/{k}32.png' for k in ids];S=3;C=10;cw=32*S+10;lab=int(sys.argv[2]) if len(sys.argv)>2 else 0
FIX=os.environ.get('FIX','').split(',')
rows=(len(ids)+C-1)//C;PAPER=(231,225,205,255)
W=Image.new('RGBA',(C*cw+10,rows*(32*S+22)+10),(26,28,38,255));g=ImageDraw.Draw(W)
for i,(k,f) in enumerate(zip(ids,fs)):
    t=Image.open(f);bg=Image.new('RGBA',(32,32),PAPER);bg.alpha_composite(t);x=10+(i%C)*cw;y=6+(i//C)*(32*S+22)
    W.alpha_composite(bg.resize((32*S,32*S),Image.NEAREST),(x,y));g.text((x,y+32*S+2),('* ' if k in FIX else '')+k[:13],fill=(235,120,100) if k in FIX else (150,150,170))
W.save(f'docs/art/boards/icons-{w}-all.png')
