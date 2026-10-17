# Audit of the gamedata tables added since 1.285.0 (city_plans, detour_scenes, expedition_steps, spec_variants, specialisations, training_paths): references, French pairs, structure.
# Usage: python3 tool/qa_new_tables_audit.py [repo root]. Prints the counts and each table's problems (none when the tables are clean).
import json,sys,re,collections
R=sys.argv[1] if len(sys.argv)>1 else '.'
J=lambda p: json.load(open(f'{R}/assets/gamedata/{p}.json'))
geo=J('geography');enemies=J('enemies');items=J('items');profs=J('professions');races=J('races');facs=J('factions');subs=J('subclans');zones=J('zones');biomes=J('biomes')
quests=J('quests');shops=J('shops')
dag=json.load(open(f'{R}/assets/Cleaned_Narrative_DAG.json'))
ABIL={'strength','dexterity','constitution','intelligence','wisdom','charisma','luck','perception'}
problems=collections.defaultdict(list); counts=collections.Counter()
def bad(t,m): problems[t].append(m)
TEXT={'text','title','rumour','place','note','name','blurb','gift','voice','description'}
def fr_pairs(t,x,path):
    if isinstance(x,dict):
        for k,v in x.items():
            if isinstance(v,str) and k in TEXT and not k.endswith('_fr') and len(v)>=3 and not path.endswith('.where'):
                counts[t+':texts']+=1
                if not isinstance(x.get(k+'_fr'),str) or not x[k+'_fr'].strip(): bad(t,f'{path}.{k}: no French')
            fr_pairs(t,v,path+'.'+str(k))
    elif isinstance(x,list):
        for i,v in enumerate(x): fr_pairs(t,v,f'{path}[{i}]')
tables={t:J(t) for t in ['city_plans','detour_scenes','expedition_steps','spec_variants','specialisations','training_paths']}
for t,d in tables.items():
    if t=='city_plans': continue
    fr_pairs(t,d,t)
# specialisations
sp=tables['specialisations']
for k,v in sp.items():
    counts['spec']+=1
    if v['profession'] not in profs: bad('specialisations',f'{k}: profession {v["profession"]}')
    if v['faction'] not in facs: bad('specialisations',f'{k}: faction {v["faction"]}')
sv=tables['spec_variants']
perspec=collections.defaultdict(list)
for k,v in sv.items():
    counts['variant']+=1
    if v['spec'] not in sp: bad('spec_variants',f'{k}: spec {v["spec"]}')
    if v.get('subclan') and v['subclan'] not in subs and v['subclan']!='': bad('spec_variants',f'{k}: subclan {v["subclan"]}')
    perspec[v['spec']].append(v['kind'])
for s in sp:
    if s not in perspec and 'link' not in sp[s]: bad('spec_variants',f'spec {s} has no variants')
# training
for k,v in tables['training_paths'].items():
    counts['path']+=1
    for p in v['professions']:
        if p not in profs: bad('training_paths',f'{k}: profession {p}')
    for r in v['races']:
        if r not in races: bad('training_paths',f'{k}: race {r}')
    for a in v['gains']:
        if a not in ABIL and a not in ('maxHealth','damage','armor'): bad('training_paths',f'{k}: gain {a}')
    if not v.get('icon'): bad('training_paths',f'{k}: no icon')
# expedition steps
def refs(t,zone,obj,path):
    if isinstance(obj,dict):
        for k,v in obj.items():
            if k=='fight':
                ids=v if isinstance(v,list) else [v.get('enemy') if isinstance(v,dict) else v]
                for e in ids:
                    if isinstance(e,dict): e=e.get('enemy') or e.get('id')
                    counts[t+':fights']+=1
                    if e and e not in enemies: bad(t,f'{zone} {path}: enemy {e}')
            if k=='material':
                m=v if isinstance(v,str) else (v.get('id') if isinstance(v,dict) else None)
                counts[t+':materials']+=1
                if m and m not in items: bad(t,f'{zone} {path}: material {m}')
            if k=='check' and isinstance(v,str):
                counts[t+':checks']+=1
                if v not in ABIL: bad(t,f'{zone} {path}: ability {v}')
            refs(t,zone,v,path+'.'+str(k))
    elif isinstance(obj,list):
        for i,v in enumerate(obj): refs(t,zone,v,f'{path}[{i}]')
for z,v in tables['expedition_steps'].items():
    if z not in zones: bad('expedition_steps',f'zone {z} not in zones.json')
    ids=[s['id'] for s in v['steps']]
    if len(ids)!=len(set(ids)): bad('expedition_steps',f'{z}: duplicate step ids')
    for s in v['steps']:
        cids=[c['id'] for c in s.get('choices',[])]
        if len(cids)!=len(set(cids)): bad('expedition_steps',f'{z}/{s["id"]}: duplicate choice ids')
        if not s.get('choices'): bad('expedition_steps',f'{z}/{s["id"]}: no choices')
    refs('expedition_steps',z,v,'')
# detour scenes
ds=tables['detour_scenes']
placeids=set(geo)
for k,v in ds.items():
    counts['detour_scene']+=1
    w=v['where']
    for kk,vv in w.items():
        for one in (vv if isinstance(vv,list) else [vv]):
            if kk=='biome' and one not in biomes: bad('detour_scenes',f'{k}: biome {one}')
            if kk in('place','district','location') and one not in geo: bad('detour_scenes',f'{k}: {kk} {one}')
    if not (1<=v['minChapter']<=v['maxChapter']<=8): bad('detour_scenes',f'{k}: chapters {v["minChapter"]}-{v["maxChapter"]}')
    ids=[b['id'] for b in v['beats']]
    if len(ids)!=len(set(ids)): bad('detour_scenes',f'{k}: duplicate beat ids')
    for b in v['beats']:
        cids=[c['id'] for c in b.get('choices',[])]
        if b['type']!='rest' and not b.get('choices'): bad('detour_scenes',f'{k}/{b["id"]}: no choices')
        if len(cids)!=len(set(cids)): bad('detour_scenes',f'{k}/{b["id"]}: duplicate choice ids')
    refs('detour_scenes',k,v,'')
# city plans
cp=tables['city_plans']
for c,v in cp.items():
    counts['city']+=1
    if c not in geo: bad('city_plans',f'{c} not in geography')
    ds_=v.get('districts',{})
    for d in ds_:
        if d not in geo: bad('city_plans',f'{c}: district {d} not in geography')
        elif geo[d].get('level')!='district': bad('city_plans',f'{c}: {d} is not a district')
    gd=[k for k,g in geo.items() if g.get('level')=='district' and g.get('parent')==c]
    missing=[d for d in gd if d not in ds_]
    if missing: bad('city_plans',f'{c}: geography districts not on the plan: {missing}')
    for a in v.get('anchors',{}) if isinstance(v.get('anchors'),dict) else []:
        pass
print('counts',dict(counts))
for t in tables: print(t, len(problems[t]),'problems'); [print('  ',m) for m in problems[t][:15]]
