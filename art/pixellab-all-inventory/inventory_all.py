"""Read-only inventory of every PixelLab character OUTSIDE the four NPC groups (0 generations): list_characters, get_character, one south frame via the free workbench inspect.
python3 art/pixellab-all-inventory/inventory_all.py   (repo root)"""
import json, re, subprocess, os, glob
from concurrent.futures import ThreadPoolExecutor
CLI=['python3','tool/pixellab_client.py','call']
SKIP=['Male - Peasant','Hero','Young peasant with a straw hat','Paysant woman']
def call(tool,args,save=None):
    c=CLI+[tool,json.dumps(args)]+(['--save',save] if save else []); return subprocess.run(c,capture_output=True,text=True).stdout
rows=[]
for o in range(0,250,50):
    for l in call('list_characters',{"limit":50,"offset":o}).splitlines():
        m=re.match(r'\s+([0-9a-f-]{36}) \| (.*?) \| (.*)',l)
        if m and m.group(2).strip() not in SKIP: rows.append((m.group(1),m.group(2).strip()))
def one(a):
    i,(cid,name)=a
    t=call('get_character',{"character_id":cid})
    f=lambda k,d='': (re.search(r'^'+k+r': (.*)$',t,re.M) or [None,d])[1]
    anims=[dict(name=m.group(1).strip(),dirs=int(m.group(2)),where=m.group(3),frames=int(m.group(4))) for m in re.finditer(r'^  (.+?) — (\d+) dir \(([^)]*)\), (\d+)f',t,re.M)]
    d=f'art/pixellab-all-inventory/frames/{i:03d}'; os.makedirs(d,exist_ok=True)
    call('pixelart_workbench',{"argv":["inspect",f"character:{cid}:south"]},save=d)
    png=sorted(glob.glob(d+'/*.png'))
    return dict(i=i,id=cid,group=name,state=f('state_name'),size=f('size'),view=f('view'),directions=f('directions')[:2].strip(),anims=anims,frame=png[0] if png else None)
with ThreadPoolExecutor(6) as ex: out=list(ex.map(one,enumerate(rows)))
json.dump(out,open('art/pixellab-all-inventory/inventory.json','w'),indent=1)
print(len(out),'entries')
