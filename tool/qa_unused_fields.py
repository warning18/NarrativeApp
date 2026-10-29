#!/usr/bin/env python3
"""QA: gamedata fields no Dart code reads (analysis only).

    python3 tool/qa_unused_fields.py

For every JSON file in assets/gamedata/ and the story graph, collects the
field names used by its records (the keys of the objects at every depth) and
checks whether any code in lib/ names the field as a string literal
('reqGold', "reqGold"). A field is listed when it appears in the data and in
no string of lib/. French twins (`x_fr`, `xFr`) follow their English field.
Keys that are the data's own ids (an object whose keys are item ids, zone ids)
are told apart from fields: a key counts as a field when two or more records
share it.

False positives: fields read through a built name ('${prefix}Chance'), or
through a whole-object read that forwards every key (editor screens, the
game-data browser); listed per file with the record count so the owner can
judge. A field nothing reads is either dead data or a missing feature.
"""
import collections, json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
code = []
for dp, _, fs in os.walk(os.path.join(ROOT, 'lib')):
    for f in fs:
        if f.endswith('.dart'):
            code.append(open(os.path.join(dp, f), encoding='utf-8').read())
code = '\n'.join(code)
quoted = set(re.findall(r"""['"]([A-Za-z0-9_]+)['"]""", code))
# names built at run time: prefix$x / ${x}suffix
dyn_pre = set(re.findall(r"""['"]([A-Za-z0-9_]{3,})\$""", code))
dyn_suf = set(re.findall(r"""\$(?:\{[^}]*\}|[A-Za-z_]\w*)([A-Za-z0-9_]{3,})['"]""", code))


def base(k):
    k2 = re.sub(r'(_fr|Fr)$', '', k)
    return k2


def collect(obj, counter, depth=0):
    if isinstance(obj, dict):
        for k, v in obj.items():
            counter[k] += 1
            collect(v, counter, depth + 1)
    elif isinstance(obj, list):
        for v in obj:
            collect(v, counter, depth + 1)


report = {}
gd = os.path.join(ROOT, 'assets/gamedata')
files = [os.path.join(gd, f) for f in sorted(os.listdir(gd)) if f.endswith('.json')]
files.append(os.path.join(ROOT, 'assets/Cleaned_Narrative_DAG.json'))
for p in files:
    data = json.load(open(p, encoding='utf-8'))
    counter = collections.Counter()
    collect(data, counter)
    # "ids": keys appearing once are ids/names of records, not fields
    unread = []
    for k, n in counter.items():
        if n < 2:
            continue
        for cand in (k, base(k)):
            if cand in quoted or any(cand.startswith(x) for x in dyn_pre) or any(cand.endswith(x) for x in dyn_suf):
                break
        else:
            unread.append((k, n))
    if unread:
        report[os.path.relpath(p, ROOT)] = sorted(unread, key=lambda x: -x[1])

total = sum(len(v) for v in report.values())
print(f'{total} fields in {len(report)} files that no string in lib/ names')
for f, rows in report.items():
    print(f'\n{f}: {len(rows)}')
    print('   ' + ', '.join(f'{k} ({n})' for k, n in rows[:60]))
if '--json' in sys.argv:
    json.dump(report, open(sys.argv[sys.argv.index('--json') + 1], 'w'), indent=1)
