"""Read-only inventory of the user's four PixelLab character groups (0 generations): list_characters, get_character per status, one front frame per status via the free workbench inspect.
python3 art/pixellab-npc-inventory/inventory_gen.py   (repo root)"""
import json, re, subprocess, os, sys, glob
CLI=['python3','tool/pixellab_client.py','call']
GROUPS=['Male - Peasant','Hero','Young peasant with a straw hat','Paysant woman']
def call(tool,args,save=None):
    c=CLI+[tool,json.dumps(args)]+(['--save',save] if save else []); return subprocess.run(c,capture_output=True,text=True).stdout
ents=[]
for o in range(0,200,50):
    for l in call('list_characters',{"limit":50,"offset":o}).splitlines():
        m=re.match(r'\s+([0-9a-f-]{36}) \| (.*?) \| (.*)',l)
        if m and any(m.group(2)==g for g in GROUPS): ents.append((m.group(1),m.group(2),m.group(3)))
print(len(ents),'entries'); out=[]
for i,(cid,name,rest) in enumerate(ents):
    t=call('get_character',{"character_id":cid})
    f=lambda k,d='': (re.search(r'^'+k+r': (.*)$',t,re.M) or [None,d])[1]
    anims=[(m.group(1).strip(),m.group(2).strip(),m.group(3)) for m in re.finditer(r'^  (.+?) — (\d+) dir \(([^)]*)\), (\d+)f',t,re.M)]
    anims=[(m.group(1).strip(),int(m.group(2)),m.group(3),int(m.group(4))) for m in re.finditer(r'^  (.+?) — (\d+) dir \(([^)]*)\), (\d+)f',t,re.M)]
    d=f'art/pixellab-npc-inventory/frames/{i:02d}'; os.makedirs(d,exist_ok=True)
    call('pixelart_workbench',{"argv":["inspect",f"character:{cid}:south"]},save=d)
    png=sorted(glob.glob(d+'/*.png'))
    rec=dict(i=i,id=cid,group=name,state=f('state_name'),size=f('size'),view=f('view'),directions=f('directions')[:1],anims=[dict(name=a[0],dirs=a[1],where=a[2],frames=a[3]) for a in anims],frame=png[0] if png else None)
    out.append(rec); print(i,name,'|',rec['state'],'|',rec['size'],rec['view'],'|',[a['name'] for a in rec['anims']])
json.dump(out,open('art/pixellab-npc-inventory/inventory.json','w'),indent=1)
