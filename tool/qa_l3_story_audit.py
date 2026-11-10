#!/usr/bin/env python3
"""QA's L3 story audit (docs/qa/l3-1.888.0.md): what tool/qa_xref_audit.py does
not read, on the story graph and the gamedata's text.

    python3 tool/qa_l3_story_audit.py

1. (reachability is held by test/story_graph_integrity_test.dart);
2. EN/FR pairs: every text field has its `_fr` twin, none empty, none equal
   to the English (a copy), and the same number of **bold** markers in both,
   each balanced;
3. bold: how long a bold run is (the bold trim), the longest ones;
4. American spellings in the English text (the game's English is British).
"""
import collections
import json
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
story = json.load(open(os.path.join(ROOT, 'assets/Cleaned_Narrative_DAG.json'), encoding='utf-8'))

# 1. reachability: the suite holds it (test/story_graph_integrity_test.dart:
#    every node reachable from the start, parked: scene 270), with the world's
#    travel, camp errands and hubs that a plain next_id walk does not see.

# 2. EN/FR pairs and bold
BOLD = re.compile(r'\*\*')
problems = collections.defaultdict(list)
bold_runs = []


def check(where, en, fr):
    if en is None and fr is None:
        return
    if (en is None) != (fr is None):
        problems['no twin'].append(where)
        return
    if not str(fr).strip():
        problems['empty French'].append(where)
        return
    if en == fr and len(str(en)) > 12:
        problems['French is a copy'].append(where)
    be, bf = len(BOLD.findall(en)), len(BOLD.findall(fr))
    if be % 2 or bf % 2:
        problems['unbalanced **'].append(where)
    elif be != bf:
        problems['bold count differs'].append(f'{where}: EN {be // 2}, FR {bf // 2}')
    for m in re.finditer(r'\*\*(.+?)\*\*', en, re.S):
        bold_runs.append((len(m.group(1).split()), where, m.group(1)))


for sid, n in story.items():
    for f in ('description', 'prompt', 'revisit_description', 'campErrandText'):
        check(f'{sid}.{f}', n.get(f), n.get(f + '_fr'))
    for i, c in enumerate(n.get('choices', [])):
        for f in ('text', 'lockedText', 'failNote', 'reply'):
            check(f'{sid}.choices[{i}].{f}', c.get(f), c.get(f + '_fr'))
print('2. EN/FR pairs on the story graph:')
for k, v in problems.items():
    print(f'   {k}: {len(v)}', *(['e.g. ' + v[0]] if v else []))
if not problems:
    print('   no problem')

runs = sorted(bold_runs, reverse=True)
print(f'3. bold runs in the story: {len(runs)}; words: median '
      f'{sorted(r[0] for r in runs)[len(runs) // 2]}, longest {runs[0][0] if runs else 0}')
for w, where, text in runs[:5]:
    print(f'   {w} words, {where}: {text[:70]}')

# 4. American spellings in the English
AMERICAN = {
    r'\bcolor': 'colour', r'\bhonor': 'honour', r'\bfavor': 'favour', r'\bneighbor': 'neighbour',
    r'\bharbor': 'harbour', r'\blabor': 'labour', r'\bflavor': 'flavour', r'\bsavior': 'saviour',
    r'\bvalor': 'valour', r'\barmor': 'armour', r'\bdefense': 'defence', r'\boffense': 'offence',
    r'\bgray\b': 'grey', r'\bcenter': 'centre', r'\btheater': 'theatre', r'\bfiber': 'fibre',
    r'\bmeter\b': 'metre', r'\bmold\b': 'mould', r'\bplow': 'plough', r'\bpajama': 'pyjama',
    r'\bcozy': 'cosy', r'\bmom\b': 'mum', r'\bjewelry': 'jewellery', r'\blicense\b': 'licence',
    r'\bpracticed\b': 'practised', r'\brealize': 'realise', r'\borganize': 'organise',
    r'\brecognize': 'recognise', r'\bapologize': 'apologise', r'\bcancel(?:ed|ing)': 'cancelled',
    r'\btraveled|\btraveling': 'travelled', r'\bwhilst': None,
}
hits = collections.Counter()
example = {}


def scan(where, text):
    if not isinstance(text, str) or ' ' not in text:
        return  # an id or a one-word label, not prose
    text = re.sub(r'\{[^}]*\}', '', text)  # {armor}: a placeholder
    for pat, brit in AMERICAN.items():
        if brit and re.search(pat, text, re.I):
            hits[pat] += 1
            example.setdefault(pat, (where, re.search(pat, text, re.I).group(0)))


def walk(where, obj):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k.endswith(('_fr', 'Fr')) or k in ('fr', 'FR') or re.search(r'(Id|Ids|ID|id)$', k):
                continue
            walk(f'{where}.{k}', v)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            walk(f'{where}[{i}]', v)
    else:
        scan(where, obj)


walk('story', story)
gd = os.path.join(ROOT, 'assets/gamedata')
for name in sorted(os.listdir(gd)):
    if name.endswith('.json'):
        walk(name, json.load(open(os.path.join(gd, name), encoding='utf-8')))
print('4. American spellings left in the English text (story and gamedata):', sum(hits.values()))
for pat, n in hits.most_common():
    print(f'   {pat}: {n}, e.g. {example[pat][1]!r} in {example[pat][0][:70]}')
