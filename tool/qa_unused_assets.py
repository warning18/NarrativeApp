#!/usr/bin/env python3
"""QA: assets nothing refers to (analysis only).

    python3 tool/qa_unused_assets.py

For each image under assets/ (png, ttf, md/txt aside): is its path, its file
name, or its stem (the name without .png) mentioned in lib/, test/, tool/ or
any assets/gamedata/*.json or the story graph? Many sprites are named by an id
(assets/icons/items/<item id>.png): the stem is then found in the data. An
image whose stem appears nowhere, and whose folder is not read by pattern, is
a candidate. Also lists pubspec asset entries that match no file, and files in
folders pubspec does not declare (they would not ship).
"""
import os, re, sys, collections

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))


def text_of(dirs, exts):
    out = []
    for d in dirs:
        for dp, _, fs in os.walk(os.path.join(ROOT, d)):
            for f in fs:
                if f.endswith(exts):
                    out.append(open(os.path.join(dp, f), encoding='utf-8', errors='ignore').read())
    return '\n'.join(out)


code = text_of(['lib', 'test', 'tool', 'tools'], ('.dart', '.py')) + '\n' + open(os.path.join(ROOT, 'pubspec.yaml')).read()
data = text_of(['assets/gamedata'], ('.json',)) + open(os.path.join(ROOT, 'assets/Cleaned_Narrative_DAG.json')).read()
alltext = code + '\n' + data
tokens = set(re.findall(r'[A-Za-z0-9_\-]+', alltext))

# names built at run time: 'vfx_$name', '${id}_battered', 'assets/icons/$kind/$id.png'
pre = set(m for m in re.findall(r"['\"]([A-Za-z0-9_\-./]*)\$", code) if len(m) >= 3)
suf = set(m for m in re.findall(r"\$(?:\{[^}]*\}|[A-Za-z_]\w*)([A-Za-z0-9_\-]{3,})(?:\.png)?['\"]", code))
pre = {x.split('/')[-1] for x in pre if x.split('/')[-1]}
pubspec = open(os.path.join(ROOT, 'pubspec.yaml')).read()
declared = re.findall(r'^\s+- (assets/[^\s#]+)', pubspec, re.M)
undeclared_dirs = collections.Counter()
missing_entries = []
for e in declared:
    if not os.path.exists(os.path.join(ROOT, e)):
        missing_entries.append(e)

files = []
for dp, _, fs in os.walk(os.path.join(ROOT, 'assets')):
    for f in fs:
        if f.endswith('.png'):
            files.append(os.path.relpath(os.path.join(dp, f), ROOT))


def shipped(path):
    d = os.path.dirname(path) + '/'
    return any(e == path or (e.endswith('/') and d.startswith(e) and os.path.dirname(path) + '/' == e) for e in declared)


unref = collections.defaultdict(list)
maybe_dynamic = collections.Counter()
total = collections.Counter()
for p in files:
    folder = os.path.dirname(p)
    total[folder] += 1
    stem = os.path.splitext(os.path.basename(p))[0]
    if not shipped(p):
        undeclared_dirs[folder] += 1
    if p in alltext or os.path.basename(p) in alltext or stem in tokens:
        continue
    # a stem like 'enchanted_sword_2' may be built from a prefix + number
    base = re.sub(r'[_\-]?\d+$', '', stem)
    if base and base != stem and base in tokens:
        continue
    if any(stem.startswith(x) and len(x) >= 3 for x in pre) or any(stem.endswith(x) for x in suf):
        maybe_dynamic[folder] += 1
        continue
    unref[folder].append(p)

print(f'{len(files)} png files, {sum(len(v) for v in unref.values())} with no mention of path, name or stem anywhere')
for folder, ps in sorted(unref.items(), key=lambda kv: -len(kv[1])):
    print(f'\n{folder}: {len(ps)} of {total[folder]}')
    for p in sorted(ps)[:40]:
        print('   ', p)
    if len(ps) > 40:
        print('    ...')
print('\n== matched only by a name built at run time (check by hand)')
for d, n in maybe_dynamic.most_common():
    print(f'{n:4} {d}')
print('\n== folders pubspec does not declare (files would not ship)')
for d, n in undeclared_dirs.most_common():
    print(f'{n:4} {d}')
print('\n== pubspec entries matching no file')
for e in missing_entries:
    print('   ', e)
