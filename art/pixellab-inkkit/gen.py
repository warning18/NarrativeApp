"""Ink kit pieces (cut paper, five tones + red forced), small pixflux calls, text only: python3 art/pixellab-inkkit/gen.py [ids] [seeds]"""
import sys,json,io,base64,os
sys.path.insert(0,'art/pixellab-backgrounds');import batchA_gen as A
from PIL import Image
CP="cut paper, flat shapes cut from black and cream paper, very simple, thick near-black outline, flat colours of black, dark navy, cream and one deep red only, no text, no icons, no shading, front view, plain and empty inside, "
P={ # id: (w,h, text)
'panel':(48,48,CP+"a game UI panel frame: a cream paper card with a thick black border, slightly rounded corners, a flat plain cream centre"),
'button':(48,24,CP+"a game UI button: a flat deep red paper rectangle with a thick black outline, rounded corners, a slightly lighter top edge"),
'chip':(48,24,CP+"a small pill shaped UI chip label: cream with a thin black outline, fully rounded ends, plain"),
'tab':(48,24,CP+"a UI tab: a cream paper tab with rounded top corners, black outline, a flat bottom edge, plain"),
'bar':(64,16,CP+"a thin horizontal progress bar frame: a black outline and a dark navy empty inside, rounded ends, no fill"),
'seal':(32,32,CP+"a round red wax seal button: a deep red disc with a thick black ring around it and a darker inner ring, plain, no emblem"),
}
P.update({
'chip2':(48,24,CP+"a small badge: a short rounded rectangle, solid plain cream colour everywhere, with a thin black outline, nothing inside"),
'tab2':(48,24,CP+"a folder tab shape like a menu tab handle: a cream paper shape with a rounded top, a black outline, wider at the bottom than the top, one flat solid cream colour"),
'bar2':(64,16,CP+"a long thin rounded rectangle frame: a thick black outline and a solid dark navy inside, completely empty, no red, no fill, no highlight"),
})
only=[x for x in sys.argv[1].split(',') if x] if len(sys.argv)>1 else list(P);only=only or list(P)
seeds=[int(s) for s in sys.argv[2].split(',')] if len(sys.argv)>2 else [1,2]
def b64(im):
    b=io.BytesIO();im.save(b,'PNG');return base64.b64encode(b.getvalue()).decode()
pal=Image.open('art/pixellab-inkkit/five_forced.png').convert('RGBA')
jf='art/pixellab-inkkit/jobs.json';jobs=json.load(open(jf)) if os.path.exists(jf) else {}
for k in only:
    w,h,t=P[k]
    for s in seeds:
        r=A.call('create_image_pixflux',{"description":t,"width":w,"height":h,"no_background":True,"color_image_base64":b64(pal),"outline":"single color black outline","shading":"flat shading","detail":"low detail","seed":s})
        jobs.setdefault(k,[]).append(A.field(r,'job_id'));print(k,s,jobs[k][-1],flush=True);json.dump(jobs,open(jf,'w'))
