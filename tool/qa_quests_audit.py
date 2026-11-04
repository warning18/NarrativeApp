#!/usr/bin/env python3
"""QA: can every quest be started and finished? (analysis only, no dependencies)

    python3 tool/qa_quests_audit.py

For each quest in assets/gamedata/quests.json:
  - it can be started: some scene unlocks it (`unlockQuestId`), or the quest
    before it leads to it (`nextQuestID`), or the chapter loop hands it out
    (chapters.json), or an NPC gives it (npcs.json);
  - every objective can be done: a Kill's enemy is met somewhere (a scene's
    fight, a zone, an expedition step, a land event, a detour, an adventure
    node), a Flag objective's flag is set by something, a Fetch's item can be
    had (a shop, a loot table, a scene's grant, a reward), a Talk's NPC exists;
  - its `requiredFlags` are set by something, its `nextQuestID` and rewards
    (item, die, ally, banner piece) exist.
A flag counts as settable when a scene choice adds it, a quest sets it, the
code names it (the engine sets it: `ally_*`, `devoted_*`, `host_*`, the
zones' clears), or it follows a pattern the engine builds.
"""
import json, os, re, sys, collections

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
J = lambda n: json.load(open(f'{ROOT}/assets/gamedata/{n}.json', encoding='utf-8'))
story = json.load(open(f'{ROOT}/assets/Cleaned_Narrative_DAG.json', encoding='utf-8'))
quests, enemies, items, npcs = J('quests'), J('enemies'), J('items'), J('npcs')
dice, companions = J('dice'), J('companions')
chapters = J('chapters')

code = ''
for dp, _, fs in os.walk(f'{ROOT}/lib'):
    for f in fs:
        if f.endswith('.dart'):
            code += open(os.path.join(dp, f), encoding='utf-8').read()

# --- what can be met, had, set --------------------------------------------
met = set()
raw_all = ''
for n in os.listdir(f'{ROOT}/assets/gamedata'):
    if n.endswith('.json') and n not in ('enemies.json', 'quests.json'):
        raw_all += open(f'{ROOT}/assets/gamedata/{n}', encoding='utf-8').read()
for e in enemies:
    if f'"{e}"' in raw_all:
        met.add(e)
for n in story.values():
    for c in n['choices']:
        for e in ([c['triggerEnemyId']] if c.get('triggerEnemyId') else []) + c.get('triggerEnemyIds', []):
            met.add(e)
flags_set = set()
for n in story.values():
    for c in n['choices']:
        flags_set.update(c.get('flagsToAdd', []))
for q in quests.values():
    for key in ('turnInChoices', 'questChoices'):
        for c in q.get(key, []):
            if c.get('flagToAdd'):
                flags_set.add(c['flagToAdd'])
# flags the engine sets: companions, the Host, zone clears, the nemesis trail (nemesis.dart), ship repairs
ENGINE = re.compile(r'^(ally_|devoted_|host_|found_|feat_|cleared_|zone_|expedition_|district_|nemesis_|nemq_|clan_|hub_|visited_|hull_patched|sail_mended)')
# quests and foes the engine hands out itself: the nemesis quests and champions
# (lib/data/nemesis.dart), the temptation quests and their angel and demon (lib/data/alignment_events.dart)
ENGINE_QUESTS = re.compile(r'^q_(nemesis|temptation)_')
ENGINE_FOES = re.compile(r'^(champion_|angel_|demon_)')


def flag_ok(f):
    return f in flags_set or ENGINE.match(f) or f"'{f}'" in code or f'"{f}"' in code


had = set()
for n in ('shops',):
    for s in J(n).values():
        for it in s.get('initialStock', []) if isinstance(s.get('initialStock'), list) else []:
            had.add(it if isinstance(it, str) else it.get('itemID', ''))
for e in enemies.values():
    for k in ('lootTable', 'drops', 'loot', 'guaranteedLoot'):
        v = e.get(k)
        if isinstance(v, list):
            for x in v:
                had.add(x if isinstance(x, str) else (x.get('itemID') or x.get('id') or ''))
for n in story.values():
    for c in n['choices']:
        if c.get('grantItemId'):
            had.add(c['grantItemId'])
for q in quests.values():
    if q.get('rewardItemID'):
        had.add(q['rewardItemID'])
raw_items_refs = {i for i in items if f'"{i}"' in raw_all}

unlock = set()
for n in story.values():
    for c in n['choices']:
        for k in ('unlockQuestId', 'questIDToProgress'):
            if c.get(k):
                unlock.add(c[k])
for q in quests.values():
    if q.get('nextQuestID'):
        unlock.add(q['nextQuestID'])
for c in chapters.values():
    for k, v in c.items():
        if isinstance(v, str) and v in quests:
            unlock.add(v)
        if isinstance(v, list):
            unlock.update(x for x in v if isinstance(x, str) and x in quests)
for npc in npcs.values():
    for v in npc.values():
        if isinstance(v, str) and v in quests:
            unlock.add(v)
        if isinstance(v, list):
            unlock.update(x for x in v if isinstance(x, str) and x in quests)
raw_q = json.dumps(list(J('companions').values())) + json.dumps(J('npcs')) + json.dumps(J('zones')) + json.dumps(J('adventure_nodes'))
for q in quests:
    if f'"{q}"' in raw_q or f"'{q}'" in code:
        unlock.add(q)

problems = collections.defaultdict(list)
for qid, q in quests.items():
    if qid not in unlock and not ENGINE_QUESTS.match(qid):
        problems['no way to start'].append(qid)
    for o in q.get('objectives', []):
        t = o.get('type')
        if t == 'Kill':
            targets = [o.get('targetEnemyID')] if o.get('targetEnemyID') else []
            targets += o.get('targetEnemyIDs', [])
            for e in targets:
                if e not in enemies:
                    problems['kill: no such enemy'].append(f'{qid}: {e}')
                elif e not in met and not ENGINE_FOES.match(e):
                    problems['kill: enemy met nowhere'].append(f'{qid}: {e}')
            if not targets:
                problems['kill: no target'].append(qid)
        elif t == 'Flag':
            f = o.get('targetFlag') or o.get('flag') or o.get('requiredFlag')
            fl = o.get('flags') or ([f] if f else [])
            for x in fl:
                if not flag_ok(x):
                    problems['flag objective: set by nothing'].append(f'{qid}: {x}')
        elif t == 'Fetch':
            it = o.get('targetItemID')
            if it not in items:
                problems['fetch: no such item'].append(f'{qid}: {it}')
            elif it not in had and it not in raw_items_refs:
                problems['fetch: item had nowhere'].append(f'{qid}: {it}')
        elif t == 'Talk':
            nid = o.get('targetNPCID') or o.get('targetNPCName')
            if nid and nid not in npcs and not any(v.get('npcName') == nid for v in npcs.values()) and nid.lower() not in companions:
                problems['talk: no such npc'].append(f'{qid}: {nid}')
    for f in q.get('requiredFlags', []):
        if not flag_ok(f):
            problems['required flag: set by nothing'].append(f'{qid}: {f}')
    if q.get('nextQuestID') and q['nextQuestID'] not in quests:
        problems['next quest missing'].append(f'{qid}: {q["nextQuestID"]}')
    for key, tab in (('rewardItemID', items), ('rewardDiceID', dice), ('rewardAllyId', companions)):
        if q.get(key) and q[key] not in tab:
            problems[f'reward {key} missing'].append(f'{qid}: {q[key]}')
    for i, o in enumerate(q.get('objectives', [])):
        if not o.get('description_fr'):
            problems['objective without French'].append(f'{qid}[{i}]')

print(f'{len(quests)} quests: ' + (f'{sum(len(v) for v in problems.values())} problems' if problems else '0 problems'))
for k, v in problems.items():
    print(f'\n== {k} ({len(v)})')
    for x in v[:30]:
        print('  ', x)
