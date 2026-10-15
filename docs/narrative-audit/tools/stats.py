import json,collections
T=json.load(open('roads50.json')); R=json.load(open('runs50.json'))
D=json.load(open('/home/user/NarrativeApp/assets/Cleaned_Narrative_DAG.json'))
L=lambda n: D.get(n,{}).get('location')
tot=dict(det=0,nodes=0,same=0)
levels=collections.Counter(); kinds=collections.Counter(); sh=collections.Counter(); chdet=collections.Counter()
blocked=collections.Counter(); spinech=collections.Counter(); atrest=collections.Counter(); ev=collections.Counter(); evch=collections.Counter()
cove=0; enemyN=0; enemyDart=0; tin=0; rows=[]
for r,t in zip(R,T):
    dc=0; nodes=0; rep=collections.Counter(); dart=0; zero=0; per=collections.Counter(); adj=0; last=None; city_tr=0; samec=0
    tr=t['trans']
    for x in tr:
        if x['spine'] and x['ch']>=2:
            spinech[x['ch']]+=1
            if not x['atRest']: blocked[x['ch']]+=1
            else: atrest[x['ch']]+=1
        if x.get('roadEvent'): ev[x['roadEvent']]+=1; evch[x['ch']]+=1
        if x.get('detour'):
            dc+=1; chdet[x['ch']]+=1; per[x['ch']]+=1
            same = L(x['from'])==L(x['to'])
            tot['same']+=same; samec+=same
            if last is not None and x['i']-last<=2: adj+=1
            last=x['i']
            for n in x['detour']:
                nodes+=1; levels[n['level'].split(':')[0]]+=1; kinds[n['kind']]+=1
                rep[n['text']]+=1
                if n['level'].startswith('dart'): dart+=1
                if n['kind']=='enemy':
                    enemyN+=1; enemyDart+= n['level'].startswith('dart')
                if x['locFrom']=='cove_camp': cove+=1
                for s in n['shop']: sh[s]+=1
                if n['kind']=='treasure' and x['locFrom']=='saltmouth': tin+=1
    dry=[c for c in range(2,9) if atrest_c if False] if False else []
    chapters_dry=sum(1 for c in range(2,9) if c in (2,3,5,6,7,8) and per[c]==0)
    repeats=sum(v-1 for v in rep.values() if v>1)
    issues=dart+repeats+adj+samec+(per[8]) 
    rows.append((r['run'],r['strategy'],r['race'],r['profession'],r['chapter'],dc,nodes,len([x for x in tr if x.get('roadEvent')]),dart,repeats,adj,samec,chapters_dry,issues))
    tot['det']+=dc; tot['nodes']+=nodes
print(tot,levels,kinds,sh,chdet)
print('spine ch>=2',sorted(spinech.items()),'blocked',sorted(blocked.items()),'atrest',sorted(atrest.items()))
print('ev',ev,sorted(evch.items()))
print('cove',cove,'enemy',enemyN,enemyDart,'treasure-in-saltmouth',tin)
json.dump(rows,open('rows.json','w'))
dc=[r[5] for r in rows]; print('detours/run mean',sum(dc)/50,min(dc),max(dc))
