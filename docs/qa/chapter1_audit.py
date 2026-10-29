#!/usr/bin/env python3
"""Chapter 1 cross-reference audit. Reads the story graph and the game data;
no simulator, no dependencies.

    python3 docs/qa/chapter1_audit.py

Chapter 1 = the graph nodes from "0" to "1002" in file order (intro, race and
profession, Alster 100-960, the Lark, the Waste, Vica, the White Wells, the
three origin endings). It checks, for those nodes: references (next, fail,
lose, land route, enemy, item, quest, banner, politics), flags set but never
read and read but never set (against the whole game), FR/EN parity, gold
choices with no check, and leftover text (the dog, the old caravan-day Vica).
"""
import collections, json, os, re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
G = json.load(open(f'{ROOT}/assets/Cleaned_Narrative_DAG.json'))
def table(n): return json.load(open(f'{ROOT}/assets/gamedata/{n}.json'))
KEYS = list(G)
CH1 = KEYS[:KEYS.index('1002') + 1]
S = set(CH1)
END = {'END', 'EXIT'}
out = collections.OrderedDict()
def add(k, v): out.setdefault(k, []).append(v)

enemies, items = table('enemies'), table('items')
quests, routes = table('quests'), table('land_routes')
pol = table('politics_events')
banners = set()
try:
    banners = set(table('banner_pieces'))
except Exception:
    pass

# --- flags: who sets, who reads (whole game, so chapter 1 flags read later count)
setters, readers = collections.defaultdict(set), collections.defaultdict(set)
def scan_text_flags(obj, where):
    pass
for nid, n in G.items():
    for c in n['choices']:
        for f in c.get('flagsToAdd', []): setters[f].add(nid)
        for key in ('showIfFlags', 'hideIfFlags', 'reqFlags'):
            for f in c.get(key, []): readers[f].add(nid)
    for f in n.get('reqFlags', []): readers[f].add(nid)
    for cb in n.get('flag_callbacks', []):
        if cb.get('flag'): readers[cb['flag']].add(nid)
blob = open(f'{ROOT}/assets/gamedata/quests.json').read() + open(f'{ROOT}/assets/gamedata/chapters.json').read()
for f in re.findall(r'"flagToAdd"\s*:\s*"([^"]+)"', blob): setters[f].add('quests')
code = ''
for dp, _, fs in os.walk(f'{ROOT}/lib'):
    for fn in fs:
        if fn.endswith('.dart'): code += open(os.path.join(dp, fn)).read()
def code_mentions(f): return f"'{f}'" in code or f'"{f}"' in code

ch1_flags = {f for n in CH1 for c in G[n]['choices'] for f in c.get('flagsToAdd', [])}
for f in sorted(ch1_flags):
    if not (readers[f] or code_mentions(f)):
        add('flags_set_never_read', f'{f}  (set in {sorted(setters[f] & S)})')
for n in CH1:
    for c in G[n]['choices']:
        for key in ('showIfFlags', 'hideIfFlags', 'reqFlags'):
            for f in c.get(key, []):
                if not setters[f] and not code_mentions(f):
                    add('flags_read_never_set', f'{n}: {key} {f}')

# --- references and parity
for n in CH1:
    node = G[n]
    for c in node['choices']:
        for key in ('next_id', 'failNextId', 'loseNextId'):
            t = c.get(key)
            if t and t not in G and t not in END:
                add('missing_target', f'{n} {key} -> {t}')
        for e in ([c['triggerEnemyId']] if c.get('triggerEnemyId') else []) + c.get('triggerEnemyIds', []):
            if e not in enemies: add('missing_enemy', f'{n}: {e}')
        for key in ('grantItemId',):
            if c.get(key) and c[key] not in items: add('missing_item', f'{n}: {c[key]}')
        if c.get('unlockQuestId') and c['unlockQuestId'] not in quests: add('missing_quest', f'{n}: {c["unlockQuestId"]}')
        if c.get('questIDToProgress') and c['questIDToProgress'] not in quests: add('missing_quest', f'{n}: {c["questIDToProgress"]}')
        if c.get('landRouteId') and c['landRouteId'] not in routes: add('missing_route', f'{n}: {c["landRouteId"]}')
        if banners and c.get('grantsBannerPieceId') and c['grantsBannerPieceId'] not in banners:
            add('missing_banner', f'{n}: {c["grantsBannerPieceId"]}')
        # FR parity
        for en, fr in (('text', 'text_fr'), ('lockedText', 'lockedText_fr'), ('failNote', 'failNote_fr')):
            if c.get(en) and not c.get(fr): add('fr_missing', f'{n} choice "{c[en][:40]}": {fr}')
            if c.get(fr) and c.get(en) and c[fr].strip() == c[en].strip() and len(c[en]) > 20:
                add('fr_same_as_en', f'{n} {fr}: {c[en][:50]}')
        if c.get('pays') or (c.get('goldMod', 0) < 0 and not c.get('checkAbility')):
            add('gold_cost_no_check', f'{n} "{c["text"][:50]}" goldMod={c.get("goldMod")} pays={c.get("pays")} showIf={c.get("showIfFlags")}')
    for en, fr in (('description', 'description_fr'), ('prompt', 'prompt_fr')):
        if node.get(en) and not node.get(fr): add('fr_missing', f'{n}: {fr}')
    if node.get('description') and node.get('description_fr'):
        a, b = len(node['description']), len(node['description_fr'])
        if b < a * 0.6 or b > a * 1.8: add('fr_length_odd', f'{n}: EN {a} / FR {b}')
        pa, pb = node['description'].count('\n\n'), node['description_fr'].count('\n\n')
        if pa != pb: add('fr_paragraph_count', f'{n}: EN {pa + 1} / FR {pb + 1} paragraphs')
    for pk, v in (node.get('persona_variants') or {}).items():
        if v.get('en') and not v.get('fr'): add('fr_missing', f'{n} persona_variants {pk}')
    for cb in node.get('flag_callbacks') or []:
        if cb.get('en') and not cb.get('fr'): add('fr_missing', f'{n} flag_callback {cb.get("flag")}')

# --- reachability inside chapter 1 (structure only)
reach, todo = {'0'}, ['0']
while todo:
    x = todo.pop()
    for c in G[x]['choices']:
        for key in ('next_id', 'failNextId', 'loseNextId'):
            t = c.get(key)
            if t in G and t not in reach: reach.add(t); todo.append(t)
for n in CH1:
    if n not in reach and n not in ('0',):
        add('unreachable_from_start', n)
for n in CH1:
    if not G[n]['choices']: add('no_choices', n)

# --- leftover text
pat = {
    'dog': re.compile(r'\b(dog|hound|pup|puppy|bark|paw)s?\b', re.I),
    'chien': re.compile(r'\b(chien|chienne|chiot|aboie\w*|truffe)\b', re.I),
    'caravan': re.compile(r'caravan|caravane', re.I),
}
def texts(nid):
    n = G[nid]
    for k in ('description', 'description_fr', 'prompt', 'prompt_fr'):
        if n.get(k): yield (k, n[k])
    for c in n['choices']:
        for k in ('text', 'text_fr', 'lockedText', 'lockedText_fr', 'failNote', 'failNote_fr'):
            if c.get(k): yield (k, c[k])
    for pk, v in (n.get('persona_variants') or {}).items():
        for k, val in v.items(): yield (f'persona.{pk}.{k}', val)
    for cb in n.get('flag_callbacks') or []:
        for k in ('en', 'fr'):
            if cb.get(k): yield (f'callback.{cb.get("flag")}.{k}', cb[k])
for n in CH1:
    for k, t in texts(n):
        for name, p in pat.items():
            for m in p.finditer(t):
                a = max(0, m.start() - 50)
                add(f'mention_{name}', f'{n} [{k}] …{t[a:m.end() + 50]}…'.replace('\n', ' '))

# --- gold with a floor: hidden under the cost?
for n in CH1:
    for c in G[n]['choices']:
        if c.get('goldMod', 0) < 0:
            add('gold_choices', f'{n} "{c["text"][:50]}" goldMod={c["goldMod"]} showIf={c.get("showIfFlags")} hideIf={c.get("hideIfFlags")} check={c.get("checkAbility")}')

for k, v in out.items():
    print(f'== {k} ({len(v)})')
    for x in v: print('  ', x)
