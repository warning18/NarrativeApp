"""Batch 2 post: download the 9 frames of each finished animation, tile them into staged strips (432x48), reduce to the rawer look (rawer_gen.process), map to Apollo + 2 core brights.
python3 art/pixellab-vfx/batch2_post.py <state.json> [style,style,...]    (repo root; state.json = the generator's state with job ids)"""
import sys, os, json, subprocess
sys.path.insert(0,'art/pixellab-vfx'); sys.path.insert(0,'tool')
import rawer_gen as G
from apollo_remap import remap
from PIL import Image
B=os.environ.get('B','art/pixellab-vfx/batch2'); OUTD=os.environ.get('OUTD','art/pixellab-apollo-skills/vfx'); S=json.load(open(sys.argv[1])); jobs={a['k']:a['job'] for a in S['active']}
jobs.update(json.load(open(B+'/jobs.json')) if os.path.exists(B+'/jobs.json') else {})
styles=sys.argv[2].split(',') if len(sys.argv)>2 else list(jobs)
os.makedirs(B+'/staged',exist_ok=True); os.makedirs(B+'/final',exist_ok=True); os.makedirs(OUTD,exist_ok=True)
for s in styles:
    d=f'{B}/raw/{s}_anim9'; os.makedirs(d,exist_ok=True)
    for i in range(9):
        p=f'{d}/frame_{i}.png'
        if not os.path.exists(p): subprocess.run(['curl','-sS','-o',p,f'https://api.pixellab.ai/mcp/images/{jobs[s]}/download?index={i}'],check=True)
    strip=Image.new('RGBA',(432,48),(0,0,0,0))
    for i in range(9): strip.paste(Image.open(f'{d}/frame_{i}.png').convert('RGBA').resize((48,48),Image.NEAREST),(i*48,0))
    strip.save(f'{B}/staged/vfx_{s}.png')
    im=G.process(s,src_dir=f'{B}/staged'); G.png8(im).save(f'{B}/final/vfx_{s}.png',optimize=True)
    remap(Image.open(f'{B}/final/vfx_{s}.png').convert('RGBA'),pal='apollo+cores').save(f'{OUTD}/vfx_{s}.png')
    print('ok',s)
