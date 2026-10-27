#!/usr/bin/env python3
"""Reads the story graph (assets/Cleaned_Narrative_DAG.json) and the game data
around it, and lists what can block or detour a player at a fight or a test.
No simulator runs: the graph is read as data.

    python3 docs/qa/blocking_nodes.py [--json out.json]

What it models (see docs/qa/blocking-nodes.md for the rules):
- a choice is open when its showIfFlags are all set, none of its hideIfFlags
  is, and the node it leads to has its reqFlags (reqGold, reqAlignment* are
  reported apart: they depend on the player's purse and nature);
- a fight, once lost, goes to loseNextId, else the fight is retried (never a
  block by itself); a failed check goes to failNextId, else on to nextId;
- flags come from flagsToAdd of the choice taken (the winner's effects, so
  nothing from a lost fight or a failed check), and from game systems
  (EXTERNAL below: companions, the Host, zone clears, ship repairs, the
  throne), which are taken as obtainable.
"""
import collections, json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
G = json.load(open(f'{ROOT}/assets/Cleaned_Narrative_DAG.json'))
def table(name): return json.load(open(f'{ROOT}/assets/gamedata/{name}.json'))

END = {'END', 'EXIT'}
EXTERNAL_PREFIX = ('ally_', 'devoted_', 'host_')
EXTERNAL = {'changeling_fen_cleared', 'exorcists_road_cleared', 'frost_quarry_cleared',
            'scaffold_yards_cleared', 'hull_patched', 'sail_mended', 'throne_filled'}
def external(f): return f in EXTERNAL or f.startswith(EXTERNAL_PREFIX)

def chapter_of(nid):
    d = ''.join(ch for ch in nid.split('_')[0] if ch.isdigit())
    if not d: return 0
    n = int(d)
    if n < 100: return 0
    if n < 1000: return 1
    return n // 1000 if n // 1000 <= 8 else 8

def choices(n): return G[n]['choices']
def is_fight(c): return bool(c.get('triggerEnemyId') or c.get('triggerEnemyIds') or c.get('shipBattleId'))
def is_check(c): return bool(c.get('checkAbility'))

def outcomes(n, c):
    """(target, flags_added, kind) for each way a choice can end."""
    nxt, flags = c.get('next_id', ''), tuple(c.get('flagsToAdd', []))
    out = []
    if c.get('returnToCamp'):
        out.append(('@camp', flags, 'camp'))
    if nxt:
        out.append((nxt, flags, 'win' if is_fight(c) or is_check(c) else 'go'))
    if is_check(c):
        out.append((c.get('failNextId') or nxt, (), 'fail'))
    if is_fight(c) and c.get('loseNextId'):
        out.append((c['loseNextId'], (), 'lose'))
    return [o for o in out if o[0]]

def gate_ok_static(c):
    return True

CAMPS = [k for k, v in G.items() if (v.get('settlement') or {}).get('kind') == 'camp']
ERRANDS = [k for k, v in G.items() if v.get('campErrand')]
PLACES = {k: v['settlement'] for k, v in G.items()
          if v.get('settlement') and v['settlement'].get('kind') != 'camp'
          and v['settlement'].get('chapter') is not None}

def edges_from(n):
    """All (choice, target, flags, kind) from node n, including camp links."""
    res = []
    for c in choices(n):
        for (t, fl, kind) in outcomes(n, c):
            if t == '@camp':
                for camp in CAMPS: res.append((c, camp, fl, 'camp'))
            elif t in END: res.append((c, t, fl, kind))
            else: res.append((c, t, fl, kind))
    st = G[n].get('settlement') or {}
    if st and st.get('kind') != 'camp' and st.get('chapter') is not None:
        # a place's hub always offers the way back to the camp (camp_state.dart,
        # canReturnToCampFrom), with what the party did there
        for camp in CAMPS: res.append((None, camp, (), 'back'))
    if (G[n].get('settlement') or {}).get('kind') == 'camp':
        ch = G[n]['settlement'].get('chapter') or 0
        for e in ERRANDS: res.append((None, e, (), 'errand'))
        for p, s in PLACES.items():
            if (s.get('chapter') or 0) <= ch:
                res.append((None, p, (), 'place'))
                a = s.get('arrivalNodeId')
                if a in G: res.append((None, a, (), 'place'))
    return res

def gate_open(c, may_set, must_set):
    """Over-approximate: can this choice be open in some state?"""
    if c is None: return True
    for f in c.get('showIfFlags', []):
        if not external(f) and f not in may_set: return False
    for f in c.get('hideIfFlags', []):
        if not external(f) and f in must_set: return False
    return True

def target_req_open(t, may_set, must_set):
    if t in END or t not in G: return True
    for f in G[t].get('reqFlags', []):
        if not external(f) and f not in may_set: return False
    return True

def dataflow():
    """P(n): flags possibly set when n is entered; D(n): flags surely set;
    reach: nodes enterable under the flag gates."""
    ALL = frozenset(f for n in G.values() for c in n['choices'] for f in c.get('flagsToAdd', []))
    P = {k: set() for k in G}; D = {k: None for k in G}; reach = {'0'}; D['0'] = set()
    changed = True
    while changed:
        changed = False
        for n in list(reach):
            for (c, t, fl, kind) in edges_from(n):
                if t in END or t not in G: continue
                if not gate_open(c, P[n], D[n] or set()): continue
                if not target_req_open(t, P[n] | set(fl), (D[n] or set()) | set(fl)): continue
                newP = P[n] | set(fl); newD = (D[n] or set()) | set(fl)
                if t not in reach:
                    reach.add(t); D[t] = set(newD); P[t] = set(newP); changed = True
                else:
                    if not newP <= P[t]: P[t] |= newP; changed = True
                    if not D[t] <= newD: D[t] &= newD; changed = True
    return P, D, reach

def sources_of_flags():
    """Every flag something can set: choices, quests (flagToAdd), zones
    (rewardFlag), the coast's events (flags), plus the game's own prefixes."""
    def walk(o, key, acc):
        if isinstance(o, dict):
            for k, v in o.items():
                if k == key:
                    for x in (v if isinstance(v, list) else [v]):
                        if isinstance(x, str) and x: acc.add(x)
                walk(v, key, acc)
        elif isinstance(o, list):
            for v in o: walk(v, key, acc)
    acc = set(f for v in G.values() for c in v['choices'] for f in c.get('flagsToAdd', []))
    for fn, key in (('quests', 'flagToAdd'), ('zones', 'rewardFlag'),
                    ('politics_events', 'flags'), ('detour_scenes', 'flag')):
        walk(table(fn), key, acc)
    return acc

def main():
    out = collections.OrderedDict()
    P, D, reach = dataflow()
    structural = set(['0']); q = collections.deque(['0'])
    while q:
        n = q.popleft()
        for (c, t, fl, kind) in edges_from(n):
            if t in G and t not in structural: structural.add(t); q.append(t)
    out['unreachable_structural'] = sorted(n for n in G if n not in structural)
    out['unreachable_by_flags'] = sorted(n for n in structural if n not in reach)
    out['dead_ends'] = sorted(n for n in reach if not choices(n))
    # every gate flag has a setter
    setters = sources_of_flags()
    gates = set()
    for v in G.values():
        for c in v['choices']:
            gates.update(c.get('showIfFlags', [])); gates.update(c.get('hideIfFlags', []))
        gates.update(v.get('reqFlags', []))
    out['gate_flags_set_nowhere'] = sorted(f for f in gates if f not in setters and not external(f)
                                           and not f.startswith('found_'))
    # nodes whose every choice can be closed at once, then the exact check
    closable = []
    for n in sorted(reach):
        cs = choices(n)
        if not cs: continue
        if any(c.get('isEnding') or c.get('next_id', '') in END or c.get('next_id', '') == '' for c in cs): continue
        if not any(gate_open_always(c, P[n], D[n] or set()) for c in cs): closable.append(n)
    st = lambda n: G[n].get('settlement') or {}
    blocked = []
    for n in closable:
        r = exact_blocked(n)
        if r is None: continue
        if st(n) and (st(n).get('kind') == 'camp' or st(n).get('chapter') is not None):
            continue  # a place hub or a camp: the way back / the errands are always there
        blocked.append((n, r[1]))
    out['closable_under_flags'] = closable
    out['all_closed_states_not_hubs'] = blocked
    # gold and alignment: every gated target has an ungated way at its predecessors
    pred = collections.defaultdict(list)
    for n in G:
        for c in G[n]['choices']:
            if c.get('next_id') in G: pred[c['next_id']].append((n, c))
    gated = []
    for k, v in G.items():
        gate = {x: v[x] for x in ('reqGold', 'reqAlignmentScore', 'reqAlignmentMax') if x in v}
        if not gate: continue
        for (pn, c) in pred[k]:
            free = [cc for cc in G[pn]['choices'] if cc.get('next_id') in G and 'reqGold' not in G[cc['next_id']]
                    and 'reqAlignmentScore' not in G[cc['next_id']] and 'reqAlignmentMax' not in G[cc['next_id']]
                    and not cc.get('pays')]
            if not free: gated.append((k, gate, pn))
    out['gated_target_without_free_alternative'] = gated
    out['pays_without_free_alternative'] = [
        (k, c['next_id']) for k, v in G.items() for c in v['choices']
        if c.get('pays') and not [cc for cc in v['choices'] if not cc.get('pays')]]
    # checks and fights
    def succ(x, camp=False):
        return [t for (c, t, fl, kd) in edges_from(x)
                if t in G and (camp or kd not in ('camp', 'errand', 'place', 'back'))]
    def dists(src):
        d = {src: 0}; q = collections.deque([src])
        while q:
            x = q.popleft()
            for t in succ(x):
                if t not in d: d[t] = d[x] + 1; q.append(t)
        return d
    no_fail, branches = [], []
    for k, v in G.items():
        for c in v['choices']:
            if c.get('challengeSuccessesNeeded') and not c.get('failNextId'): no_fail.append(k)
            for key in ('failNextId', 'loseNextId'):
                f, ok = c.get(key), c.get('next_id')
                if not f or f in END or f not in G or ok not in G: continue
                df, ds = dists(f), dists(ok)
                common = [x for x in df if x in ds]
                if not common: branches.append((k, key, f, None, None)); continue
                x = min(common, key=lambda y: df[y])
                branches.append((k, key, f, x, df[x] - ds[x]))
    out['skill_challenges_without_fail_branch'] = no_fail
    out['branches_total'] = len(branches)
    out['branches_never_converge'] = [b for b in branches if b[3] is None]
    out['branches_longer_by_4_or_more'] = [b for b in branches if b[3] is not None and b[4] >= 4]
    # every node can reach an ending
    ends = set(k for k, v in G.items() if any(c.get('next_id') in END or c.get('isEnding') for c in v['choices']))
    rev = collections.defaultdict(set)
    for n in G:
        for t in succ(n, True): rev[t].add(n)
    good = set(ends); q = collections.deque(ends)
    while q:
        x = q.popleft()
        for p in rev[x]:
            if p not in good: good.add(p); q.append(p)
    out['cannot_reach_an_ending'] = sorted(n for n in G if n not in good)
    # forced fights: no defeat branch and no way round at the node
    forced = collections.OrderedDict()
    for k, v in G.items():
        for c in v['choices']:
            if is_fight(c) and not c.get('loseNextId'):
                alts = [cc for cc in v['choices'] if cc is not c and not is_fight(cc)]
                if not alts:
                    e = c.get('triggerEnemyId') or c.get('triggerEnemyIds') or c.get('shipBattleId')
                    forced.setdefault(k, set()).add(json.dumps(e))
    out['forced_fights_retry_only'] = {k: sorted(v) for k, v in forced.items()}
    # choices waiting for the coast, nodes where every way on does
    out['coast_gated_nodes_without_ungated_way'] = [
        n for n, v in G.items() if any(c.get('politicsIf') for c in v['choices'])
        and not [c for c in v['choices'] if not c.get('politicsIf') and not c.get('showIfFlags')]]
    json.dump(out, sys.stdout, indent=1)
    print()

def gate_open_always(c, may_set, must_set):
    """True when this choice is open whatever the player did before: no
    showIf flag that may be unset, no hideIf flag that may be set."""
    for f in c.get('showIfFlags', []):
        if not external(f) and f not in must_set: return False
    for f in c.get('hideIfFlags', []):
        if not external(f) and f in may_set: return False
    if c.get('lockedText') and False: return False
    return True



def exact_blocked(n, limit=400000):
    """Is there a way to enter n with every one of its choices closed? A search
    over (node, the flags that gate n's choices), exact for those flags and
    optimistic for every other gate. Returns a path of nodes or None."""
    R = set()
    for c in choices(n):
        R.update(f for f in c.get('showIfFlags', []) if not external(f))
        R.update(f for f in c.get('hideIfFlags', []) if not external(f))
        t = c.get('next_id', '')
        if t in G: R.update(f for f in G[t].get('reqFlags', []) if not external(f))
    R = frozenset(R)
    def closed(state):
        for c in choices(n):
            if all(external(f) or f in state for f in c.get('showIfFlags', [])) and \
               not any((not external(f)) and f in state for f in c.get('hideIfFlags', [])):
                return False
        return True
    def open_edge(c, state):
        if c is None: return True
        if not all(external(f) or f not in R or f in state for f in c.get('showIfFlags', [])): return False
        if any((not external(f)) and f in R and f in state for f in c.get('hideIfFlags', [])): return False
        return True
    start = ('0', frozenset())
    seen = {start: None}; q = collections.deque([start])
    while q and len(seen) < limit:
        cur = q.popleft(); node, st = cur
        if node == n and closed(st) and choices(n):
            path = []; x = cur
            while x is not None: path.append(x[0]); x = seen[x]
            return path[::-1], sorted(st)
        for (c, t, fl, kind) in edges_from(node):
            if t in END or t not in G: continue
            if not open_edge(c, st): continue
            if any((not external(f)) and f in R and f not in st for f in G[t].get('reqFlags', [])): continue
            nst = st | (frozenset(fl) & R)
            nxt = (t, nst)
            if nxt not in seen: seen[nxt] = cur; q.append(nxt)
    return None


if __name__ == '__main__':
    main()
