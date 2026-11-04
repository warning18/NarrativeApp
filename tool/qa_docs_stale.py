#!/usr/bin/env python3
"""QA: what the docs still name that is gone (analysis only).

    python3 tool/qa_docs_stale.py

Reads every Markdown file of the repository (README, CLAUDE.md, docs/, assets/
READMEs) and lists: a repository path named in it (`lib/...`, `test/...`,
`tool/...`, `assets/...`, `docs/...`) that does not exist, a relative link
whose target is missing, and a Dart symbol in backticks (CamelCase class,
camelCase function) that no file of lib/ or test/ declares. Pictures and
generated folders are skipped. A hit is a candidate: the doc may be history
(a changelog entry, a proposal that was done) rather than stale.
"""
import os, re, sys, collections

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
SKIP_DIRS = {'.git', 'build', '.dart_tool', 'node_modules', 'android', 'ios', 'web', 'windows', 'macos', 'linux'}
mds = []
for dp, dn, fs in os.walk(ROOT):
    dn[:] = [d for d in dn if d not in SKIP_DIRS]
    for f in fs:
        if f.endswith('.md'):
            mds.append(os.path.relpath(os.path.join(dp, f), ROOT))

declared = set()
for base in ('lib', 'test', 'tool'):
    for dp, _, fs in os.walk(os.path.join(ROOT, base)):
        for f in fs:
            if f.endswith(('.dart', '.py')):
                src = open(os.path.join(dp, f), encoding='utf-8', errors='ignore').read()
                declared.update(re.findall(r'\b(?:class|mixin|enum|typedef|extension)\s+(\w+)', src))
                declared.update(re.findall(r'^\s*(?:[\w<>?,\[\] ]+?\s+)?(\w+)\s*\(', src, re.M))
                declared.update(re.findall(r'\b(?:final|const|var)\s+(?:[\w<>?,\[\] ]+?\s+)?(\w+)\s*=', src))
                declared.update(re.findall(r'^def (\w+)', src, re.M))
                declared.update(re.findall(r'^\s+(\w+)\s*[,(]', src, re.M))
PATH = re.compile(r'(?<![\w/.-])((?:lib|test|tool|tools|assets|docs)/[\w./*<>{}-]+)')
LINK = re.compile(r'\]\(([^)#\s]+)(?:#[^)]*)?\)')
SYM = re.compile(r'`([A-Za-z_][A-Za-z0-9_]{4,})`')
HISTORY = ('CHANGELOG.md', 'docs/handoff', 'docs/narrative-audit', 'docs/ux-shots', 'docs/proposals', 'docs/qa/l3-', 'docs/qa/chapter1', 'docs/simulation')

rows = collections.defaultdict(lambda: collections.defaultdict(list))
for md in sorted(mds):
    text = open(os.path.join(ROOT, md), encoding='utf-8', errors='ignore').read()
    hist = md.startswith(HISTORY) or md == 'CHANGELOG.md'
    kind = 'history' if hist else 'live'
    for m in PATH.finditer(text):
        p = m.group(1).rstrip('.,;:)')
        if any(c in p for c in '*<>{}'):
            continue
        if not os.path.exists(os.path.join(ROOT, p)) and not p.endswith(('/',)):
            rows[kind][md].append(f'path {p}')
    for m in LINK.finditer(text):
        t = m.group(1)
        if t.startswith(('http', 'mailto', '/')):
            continue
        full = os.path.normpath(os.path.join(ROOT, os.path.dirname(md), t))
        if not os.path.exists(full):
            rows[kind][md].append(f'link {t}')
    for m in SYM.finditer(text):
        w = m.group(1)
        if re.search(r'[a-z][A-Z]|^[A-Z][a-z]+[A-Z]', w) and w not in declared and not w.isupper():
            rows[kind][md].append(f'symbol {w}')

for kind in ('live', 'history'):
    tot = sum(len(set(v)) for v in rows[kind].values())
    print(f'== {kind} docs: {tot} stale-looking references in {len(rows[kind])} files')
    for md, items in sorted(rows[kind].items(), key=lambda kv: -len(set(kv[1]))):
        u = sorted(set(items))
        # a symbol that the JSON data or the docs' own prose names is no proof of staleness:
        # list the paths and links in full, the symbols as a count
        pl = [x for x in u if not x.startswith('symbol ')]
        syms = len(u) - len(pl)
        print(f'  {md}: {len(pl)} paths/links, {syms} symbols' + ('  -> ' + '; '.join(pl[:8]) if pl else ''))
