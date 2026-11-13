"""Export statuses of the user's NPC characters (free: the status download) as PNG8 frames, 8 directions each, transparent index 31, on a 64x64 canvas (a 48x48 status is centred, feet on the bottom row,
its native frames kept in native48/). python3 art/pixellab-npc-export/export_statuses.py 20,35,...   (repo root; ids are the inventory numbers)"""
import json, os, re, subprocess, sys, zipfile, glob
import numpy as np
from PIL import Image
D='art/pixellab-npc-export/'; DIRS=['south','south-east','east','north-east','north','north-west','west','south-west']; X='/tmp/claude-0/s/npcx/'
inv={r['i']:r for r in json.load(open('art/pixellab-npc-inventory/inventory.json'))}
def slug(s): return re.sub(r'[^a-z0-9]+','_',s.lower()).strip('_')
def png8(im,dst):
    a=np.array(im.convert('RGBA')); mask=a[...,3]<128
    q=Image.fromarray(a[...,:3]).quantize(colors=31,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE); arr=np.array(q); arr[mask]=31
    pal=q.getpalette()[:93]; pal=pal+[0]*(96-len(pal)); out=Image.fromarray(arr,'P'); out.putpalette(pal+[0]*(768-96)); out.save(dst,optimize=True,transparency=31)
res=json.load(open(D+'keepers_export.json')) if os.path.exists(D+'keepers_export.json') else {}; os.makedirs(X,exist_ok=True)
for n in [int(x) for x in sys.argv[1].split(',')]:
    r=inv[n]; name=f"{n:02d}_{slug(r['group'].split('|')[0].split(' with')[0])}_{slug(r['state'])}"; z=f'{X}{n}.zip'
    subprocess.run(['curl','-sS','-o',z,f"https://api.pixellab.ai/mcp/characters/{r['id']}/download?states={r['id']}"],check=True)
    zf=zipfile.ZipFile(z); tmp=f'{X}{n}'; zf.extractall(tmp); rot=glob.glob(tmp+'/*/rotations')[0]
    os.makedirs(f'{D}{name}',exist_ok=True)
    nat={dn:Image.open(f'{rot}/{dn}.png').convert('RGBA') for dn in DIRS}; off=0
    if nat['east'].size!=(64,64):                      # a 48x48 status: centred on 64x64, shifted so the feet stand on row 55 like the 64x64 statuses
        off=55-max(int(np.where(np.array(im)[...,3]>0)[0].max()) for im in nat.values())
    for dn in DIRS:
        im=nat[dn]
        if im.size!=(64,64):
            os.makedirs(f'{D}{name}/native{im.width}',exist_ok=True); png8(im,f'{D}{name}/native{im.width}/{dn}.png')
            c=Image.new('RGBA',(64,64),(0,0,0,0)); c.alpha_composite(im,((64-im.width)//2,off)); im=c
        png8(im,f'{D}{name}/{dn}.png')
    res[str(n)]=name; print(n,name,Image.open(f'{D}{name}/east.png').size)
json.dump(res,open(D+'keepers_export.json','w'),indent=1)
