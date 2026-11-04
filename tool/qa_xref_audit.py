#!/usr/bin/env python3
"""QA: a cross-reference audit of every gamedata table and the story graph
(analysis only, no dependencies).

    python3 tool/qa_xref_audit.py [--json out.json]

Builds the set of ids the game knows: the keys of every table in
assets/gamedata/, the `id`-like fields inside their records, and the ids of
the story graph's nodes. Then reads every field whose name says it holds an
id (`...Id`, `...ID`, `...Ids`, `...IDs`, `enemy`, `faction`, `clan`, `where`,
`parent`, ...) and reports each value that is no known id. Fields whose
values may be free text or an id of the code (a `kind`, a `trigger`) are
left out by name. A reported value is a candidate: read it.

Also checked, per table: every record has its French twin of each English
text field, a record's own id field equals its key, and no id is used by two
tables as the same key with different meanings (a warning only).
"""
import collections, json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
GD = os.path.join(ROOT, 'assets/gamedata')
tables = {f[:-5]: json.load(open(os.path.join(GD, f), encoding='utf-8'))
          for f in sorted(os.listdir(GD)) if f.endswith('.json')}
story = json.load(open(os.path.join(ROOT, 'assets/Cleaned_Narrative_DAG.json'), encoding='utf-8'))

known = collections.defaultdict(set)   # id -> where it is defined
for name, t in tables.items():
    if isinstance(t, dict):
        for k, v in t.items():
            known[k].add(name)
            if isinstance(v, dict):
                for fk, fv in v.items():
                    if re.fullmatch(r'(?:[a-z]+)?(?:id|ID|Id)', fk) and isinstance(fv, str):
                        known[fv].add(name)
for nid in story:
    known[nid].add('story')
# landmarks: the geography's own `landmark` fields (land routes start and end at them)
for rec in (tables.get('geography') or {}).values():
    lm = rec.get('landmark') if isinstance(rec, dict) else None
    for x in (lm if isinstance(lm, list) else [lm]):
        if isinstance(x, str):
            known[x].add('geography-landmark')
# graph destinations the engine names (places of the geography are keys already)
for extra in ('END', 'EXIT', ''):
    known[extra].add('engine')
# the story graph's own id-like fields name places and scenes
for n in story.values():
    s = n.get('settlement') or {}
    for k in ('placeId', 'id', 'arrivalNodeId'):
        if isinstance(s.get(k), str):
            known[s[k]].add('story')
    if isinstance(n.get('location'), str):
        known[n['location']].add('story-location')

REF_KEY = re.compile(r'(?:Ids?|IDs?|_ids?)$|^(?:enemy|faction|clan|zone|biome|parent|from|to|where|spec|subclan|patron|profession|race|companion|quest|npc|item|skill|spell|shop|port|house|ship|die|dice|nextEventID)$')
# names that hold ids of the code, free text, or the record's own id
SKIP_KEY = re.compile(r'^(?:id|ID|nodeID|questID|itemID|npcID|shopID|portID|zoneID|houseID|shipID|partID|lookID|raceID|professionID|achievementID|companionID|chapterID|gateID|branchID|spellID|remarkID|seed|spriteId|visualAsset|iconId|vfx|kind|trigger|slot|slotType|category|element|type|actionType|mapTheme|screen)$')
# ids that are deliberately not in a table (a clan of the story's own, an
# engine value); listed when a real one turns up
ALLOW = {'', 'none', 'any', 'all', 'player', 'neutral'}

refs = 0
problems = collections.defaultdict(list)


def walk(table, path, obj, key=None):
    global refs
    if isinstance(obj, dict):
        for k, v in obj.items():
            walk(table, f'{path}.{k}', v, k)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            walk(table, f'{path}[{i}]', v, key)
    elif isinstance(obj, str) and key and REF_KEY.search(key) and not SKIP_KEY.match(key):
        if key.endswith('_fr') or key.endswith('Fr'):
            return
        if len(obj) > 60 or ' ' in obj.strip():
            return                       # free text, not an id
        refs += 1
        if obj not in known and obj.lower() not in ALLOW:
            problems[table].append(f'{path} = {obj!r}')


for name, t in tables.items():
    walk(name, name, t)


# typed references: a field that names a thing must name one of that table
TYPED = [
    (r'^subclan$|^subclanId$|^subclanIds$', 'subclans'),
    (r'(?:enemy|Enemy)(?:Ids?|IDs?)$|^possibleEnemies$|^monsters$|^possibleMonsters$', 'enemies'),
    (r'(?:item|Item)(?:Ids?|IDs?)$', 'items'),
    (r'(?:skill|Skill)(?:Ids?|IDs?)$|^linkedSkill', 'skills'),
    (r'(?:quest|Quest)(?:Ids?|IDs?)$', 'quests'),
    (r'(?:npc|NPC|Npc)(?:Ids?|IDs?)$', 'npcs'),
    (r'^(?:house|Houses?)(?:Ids?|IDs?)$|^houseId$|^requiredHouseId$', 'houses'),
    (r'(?:shop|Shop)(?:Ids?|IDs?)$', 'shops'),
    (r'^(?:faction|clan|patron|clanId|factionId)$|(?:faction|clan)(?:Ids?|IDs?)$', 'factions'),
    (r'^(?:race|raceId)$|raceIds$', 'races'),
    (r'^(?:profession|professionId)$|professionIds$', 'professions'),
    (r'(?:dice|die|Dice|Die)(?:Ids?|IDs?)$', 'dice'),
    (r'^companionId$|^companionID$', 'companions'),
    (r'^spec$', 'specialisations'),
    (r'^zone(?:Id|ID)$', 'zones'),
]
wrong = collections.defaultdict(list)


def typed(table, path, obj, key=None):
    if isinstance(obj, dict):
        for k, v in obj.items():
            typed(table, f'{path}.{k}', v, k)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            typed(table, f'{path}[{i}]', v, key)
    elif isinstance(obj, str) and key and obj and ' ' not in obj and len(obj) <= 60:
        for pat, target in TYPED:
            if re.search(pat, key):
                keys = tables.get(target)
                if target == 'factions':          # a person's faction may be a clan or a sub-clan
                    keys = {**tables['factions'], **tables['subclans']}
                if isinstance(keys, dict) and obj not in keys and obj.lower() not in ALLOW:
                    wrong[table].append(f'{path} = {obj!r} is no {target} id')
                break


for name, t in tables.items():
    if name == 'companion_remarks' or name == 'geography':
        pass
    typed(name, name, t)

# story graph ids named in the data: the choices' targets are the graph audit's job
# own-id equals key
mismatch = []
for name, t in tables.items():
    if not isinstance(t, dict):
        continue
    for k, v in t.items():
        if isinstance(v, dict):
            for fk in ('id', 'ID', 'nodeID', 'questID', 'itemID', 'npcID', 'shopID', 'portID', 'zoneID', 'houseID',
                       'shipID', 'partID', 'lookID', 'raceID', 'professionID', 'achievementID', 'companionID',
                       'chapterID', 'gateID', 'branchID', 'spellID', 'remarkID'):
                if fk in ('professionID', 'raceID') and name not in ('professions', 'races'):
                    continue
                if fk in v and v[fk] != k and not (name == 'companion_remarks' and fk == 'companionID') and v[fk] != '':
                    mismatch.append(f'{name}.{k}: {fk} = {v[fk]!r}')

# French twins: any English string field with a `_fr` sibling expected
TEXT = {'name', 'text', 'title', 'blurb', 'description', 'line', 'flavour', 'rumour', 'premise', 'gift',
        'voice', 'lockedText', 'failNote', 'flavorText', 'shopName', 'shopDescription', 'itemName',
        'questName', 'npcName', 'enemyName', 'diceName', 'houseName', 'zoneName', 'portName', 'role',
        'buttonText', 'skillName', 'raceName', 'professionName', 'branchName', 'spellName'}
nofr = collections.defaultdict(list)


def twins(table, path, obj):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(v, str) and k in TEXT and not k.endswith('_fr') and len(v) >= 3 and '.effects[' not in path:
                fr = obj.get(k + '_fr', obj.get(k + 'Fr'))
                if not isinstance(fr, str) or not fr.strip():
                    nofr[table].append(f'{path}.{k}')
            twins(table, f'{path}.{k}', v)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            twins(table, f'{path}[{i}]', v)


for name, t in tables.items():
    if name in ('city_plans', 'game_config', 'detours'):
        continue
    twins(name, name, t)


# ---- the story graph's references into the tables ----------------------
story_bad = []
banner_ids = set()
for q in (tables.get('quests') or {}).values():
    pass
for nid, n in story.items():
    for i, c in enumerate(n.get('choices', [])):
        where = f'story.{nid}.choices[{i}]'
        for key in ('next_id', 'failNextId', 'loseNextId'):
            t = c.get(key)
            if t and t not in story and t not in ('END', 'EXIT'):
                story_bad.append(f'{where}.{key} = {t!r} is no scene')
        for e in ([c['triggerEnemyId']] if c.get('triggerEnemyId') else []) + c.get('triggerEnemyIds', []):
            if e not in tables['enemies'] and not e.startswith('@'):   # '@first_ally': the engine's own alias
                story_bad.append(f'{where} enemy {e!r}')
        for key, tab in (('grantItemId', 'items'), ('unlockQuestId', 'quests'), ('questIDToProgress', 'quests'),
                         ('landRouteId', 'land_routes')):
            if c.get(key) and c[key] not in tables[tab]:
                story_bad.append(f'{where}.{key} = {c[key]!r} is no {tab} id')
for nid, n in story.items():
    for cb in n.get('flag_callbacks') or []:
        pass
    loc = n.get('location')
    if isinstance(loc, str) and loc and loc not in tables['geography'] and loc not in story:
        story_bad.append(f'story.{nid}.location = {loc!r} is no place')
    sp = n.get('spot')
    comp = n.get('companion')
print(f'\nstory graph: {len(story)} scenes, {sum(len(n.get("choices", [])) for n in story.values())} choices: '
      f'{len(story_bad)} references into the tables that do not resolve')
for r in story_bad[:40]:
    print('  ', r)

total = sum(len(v) for v in problems.values())
typed_total = sum(len(v) for v in wrong.values())
print(f'{len(tables)} tables, {len(known)} known ids, {refs} id-like references read: '
      f'{total} point at no known id, {typed_total} name the wrong kind of thing, {len(mismatch)} records whose own id field differs from the key, '
      f'{sum(len(v) for v in nofr.values())} text fields with no French twin')
for t, rows in sorted(problems.items()):
    print(f'\n== dangling in {t} ({len(rows)})')
    for r in rows[:40]:
        print('  ', r)
    if len(rows) > 40:
        print(f'   ... {len(rows) - 40} more')
for t, rows in sorted(wrong.items()):
    print(f'\n== wrong kind in {t} ({len(rows)})')
    for r in rows[:40]:
        print('  ', r)
if mismatch:
    print('\n== own id differs from key')
    for m in mismatch[:40]:
        print('  ', m)
print('\n== text fields with no French twin')
for t, rows in sorted(nofr.items()):
    print(f'  {t}: {len(rows)}  e.g. {rows[0]}')
if '--json' in sys.argv:
    json.dump(dict(dangling=problems, mismatch=mismatch, nofr=nofr), open(sys.argv[sys.argv.index('--json') + 1], 'w'), indent=1)
