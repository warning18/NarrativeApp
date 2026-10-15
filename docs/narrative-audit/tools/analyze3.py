import json,collections,re
D=json.load(open('/home/user/NarrativeApp/assets/Cleaned_Narrative_DAG.json'))
R=json.load(open('runs50.json')); T=json.load(open('roads50.json'))
spine={1:[{'100'},{'105'},{'250'},{'400'},{'470'},{'891'},{'960'},{'1100'},{'1200'}],
2:[{'2001'},{'2005'},{'2010','2020','2050'},{'2030','2040','2070'},{'2900'}],
3:[{'3001'},{'3002'},{'3010','3020'},{'3030','3040','3050'},{'4999'}],
4:[{'4999_camp'},{'5003'},{'5004','5004b'},{'5004_altar'},{'5005'}],
5:[{'6001'},{'6002'},{'6002_camp'},{'6003'},{'6004'}],
6:[{'7001'},{'7300'}],
7:[{'7400'},{'7500'},{f'7510_{c}' for c in 'dominion vigil compact mire crows penitents open_hand'.split()},{'7520_vane','7520_morrow','7520_tallis'},{f'7590_{c}' for c in 'dominion vigil compact mire crows penitents open_hand'.split()}],
8:[{'7800'},{'7810'},{'7002_confront'},{'7003'},{'7004'},{'7005','7005_seeker','7005_dawn','7005_crown'}]}
def path(r):
    ch=r['choices']; p=[]
    for c in ch:
        a=c.split('|')[0]
        if not p or p[-1]!=a: p.append(a)
    p.append(ch[-1].split('|')[1]); return p
issues=collections.Counter(); ex=collections.defaultdict(list)
loops=collections.Counter()
for r in R:
    p=path(r); pos={}
    for i,n in enumerate(p): pos.setdefault(n,i)
    last=-1
    for ch,beats in spine.items():
        for bi,b in enumerate(beats):
            hit=[pos[n] for n in b if n in pos]
            if not hit: issues[('skipped',ch,bi)]+=1; ex[('skipped',ch,bi)].append(r['run']); continue
            h=min(hit)
            if h<last: issues[('out_of_order',ch,bi)]+=1; ex[('out_of_order',ch,bi)].append(r['run'])
            last=max(last,h)
    c=collections.Counter(p)
    for n,v in c.items():
        if v>=6: loops[n]+=1
print('beat issues',dict(issues)); print({k:v[:4] for k,v in ex.items()})
print('hub loops (node visited >=6x in a run):',loops.most_common(10))
# quests
acc=collections.Counter(); done=collections.Counter(); stuck=collections.Counter()
for r in R:
    for q in r['questRecords']:
        acc[q['id']]+=1
        if q['to'] is not None: done[q['id']]+=1
    for q,v in (r['questsStuck'] or {}).items(): stuck[q]+=1
print('quests accepted',sum(acc.values()),'completed',sum(done.values()))
print('stuck',stuck.most_common(10))
# the read/unread flag
added=set(); refs=set()
for k,n in D.items():
    for cb in n.get('flag_callbacks') or []: refs.add(cb['flag'])
    for f in n.get('reqFlags') or []: refs.add(f)
    for c in n.get('choices') or []:
        for f in c.get('flagsToAdd') or []: added.add(f)
        for key in('showIfFlags','hideIfFlags'):
            for f in c.get(key) or []: refs.add(f)
print('added-never-read:',[f for f in added if f not in refs])
# single-choice forced moves
forced=[k for k,n in D.items() if len(n.get('choices') or [])==1 and not (n['choices'][0].get('flagsToAdd') or n['choices'][0].get('goldMod') or n['choices'][0].get('politics'))]
print('nodes with one bare choice',len(forced))
# detours stats per chapter
elig=collections.Counter(); det=collections.Counter(); gaps=[]
for r,t in zip(R,T):
    since=0; mx=0
    for x in t['trans']:
        if x['spine'] and x['ch']>=2 and x['atRest']:
            elig[x['ch']]+=1
            if x.get('roadEvent'): pass
            if x.get('detour'): det[x['ch']]+=1; mx=max(mx,since); since=0
            else: since+=1
    mx=max(mx,since); gaps.append(mx)
print('at-rest spine transitions (50 runs)',sorted(elig.items()),'detours',sorted(det.items()))
print('longest dry stretch (at-rest transitions with no detour): mean',sum(gaps)/50,'max',max(gaps))
tc=0;cc=0;c8=0;hunts=0
for t in T:
    for x in t['trans']:
        for n in x.get('detour') or []:
            if n['kind']=='treasure' and (x['locFrom'] or '').startswith('saltmouth'): tc+=1
            if x['ch']==8: c8+=1
            if n['hunt']: hunts+=1
            if n['kind']=='treasure' and x['locFrom']=='saltmouth' and n['level'].startswith('biome'): cc+=1
print('treasure nodes in Saltmouth',tc,'from biome level',cc,'ch8 detour nodes',c8,'hunt trails',hunts)
