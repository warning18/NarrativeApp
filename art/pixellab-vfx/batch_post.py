"""Post-process a PixelLab batch into rawer strips, GIFs and the comparison sheet.
usage: python3 art/pixellab-vfx/batch_post.py batch1 style1,style2,...   (repo root)"""
import sys, os
sys.path.insert(0, 'art/pixellab-vfx')
import rawer_gen as G, numpy as np
from PIL import Image, ImageDraw
name = sys.argv[1]; S = sys.argv[2].split(',')
B = f'art/pixellab-vfx/{name}'; os.makedirs(f'{B}/final/gif', exist_ok=True)
TODAY = {'arrow': 'arrow_proj', 'heavy_slash': 'heavy'}
RAMPS = {'Fire': [(110,24,12),(214,72,20),(250,160,40),(255,236,150)], 'Water': [(20,50,90),(30,110,170),(90,190,220),(220,245,255)], 'Void': [(40,14,70),(92,40,150),(160,100,220),(230,200,255)]}
def retint(im, ramp):
    a = np.array(im.convert('RGBA')); cols = sorted({tuple(p[:3]) for r in a for p in r if p[3] and tuple(p[:3]) != (10,8,7)}, key=lambda c: .3*c[0]+.59*c[1]+.11*c[2])
    m = {c: ramp[min(i*len(ramp)//max(len(cols),1), len(ramp)-1)] for i, c in enumerate(cols)}
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y,x,3] and tuple(a[y,x,:3]) in m: a[y,x,:3] = m[tuple(a[y,x,:3])]
    return Image.fromarray(a)
fw = 96; lab = 90; rows = ['today', 'rawer', 'Fire', 'Water', 'Void']
sh = Image.new('RGB', (lab+9*fw+10, len(S)*len(rows)*(fw+4)+10), (31,28,35)); d = ImageDraw.Draw(sh); y = 5
for s in S:
    im = G.process(s, src_dir=f'{B}/staged'); G.png8(im).save(f'{B}/final/vfx_{s}.png', optimize=True)
    fr = []
    for i in range(im.width//48):
        bg = Image.new('RGBA', (96,96), (31,28,35,255)); bg.alpha_composite(im.crop((i*48,0,i*48+48,48)).resize((96,96), Image.NEAREST)); fr.append(bg.convert('RGB'))
    fr[0].save(f'{B}/final/gif/{s}.gif', save_all=True, append_images=fr[1:], duration=90, loop=0)
    fin = Image.open(f'{B}/final/vfx_{s}.png').convert('RGBA'); tp = f'assets/visuals/pixel_fx/vfx_{TODAY.get(s, s)}.png'
    today = Image.open(tp).convert('RGBA') if os.path.exists(tp) else None
    for r in rows:
        t = today if r == 'today' else fin if r == 'rawer' else retint(fin, RAMPS[r])
        d.text((5,y+36), f'{s}\n{r}', fill=(234,224,201))
        if t is not None:
            for i in range(t.width//48):
                f = t.crop((i*48,0,i*48+48,48)).resize((fw,fw), Image.NEAREST); sh.paste(f, (lab+i*fw, y), f)
        y += fw+4
sh.save(f'docs/art/boards/skill-effects-{name}.png'); print(sh.size)
