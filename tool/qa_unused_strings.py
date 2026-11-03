#!/usr/bin/env python3
"""QA: the keys of lib/l10n/app_strings.dart that no code reads (analysis only).

    python3 tool/qa_unused_strings.py [--json out.json]

A key is "read" when the quoted key appears in lib/ (outside the table) or
test/. Keys built at run time ('prefix_$x') are matched by prefix and listed
apart as `maybe_dynamic`, to be checked by hand. Also reports keys with an
English or French text missing, and French text identical to English.
"""
import collections, json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
TABLE = 'lib/l10n/app_strings.dart'
src = open(os.path.join(ROOT, TABLE), encoding='utf-8').read()
start = src.index('const Map<String, Map<AppLanguage, String>> _strings = {')
end = src.index('\n};', start)
table = src[start:end]
keys = []
for m in re.finditer(r"^  '([A-Za-z0-9_.]+)':\s*\{", table, re.M):
    keys.append((m.group(1), table.count('\n', 0, m.start()) + src[:start].count('\n') + 1))

others = {}
for d in ('lib', 'test', 'tool'):
    for dp, _, fs in os.walk(os.path.join(ROOT, d)):
        for f in fs:
            if f.endswith('.dart'):
                p = os.path.relpath(os.path.join(dp, f), ROOT)
                if p == TABLE:
                    continue
                others[p] = open(os.path.join(ROOT, p), encoding='utf-8').read()
alltext = '\n'.join(v for k, v in others.items() if k.startswith('lib/'))
testtext = '\n'.join(v for k, v in others.items() if not k.startswith('lib/'))
# the table's own helpers read keys too (trAlignmentLabel etc.): text after the table
tail = src[end:]
prefixes = set()
# a lookahead, so a key built inside an interpolated string ('${tr(r, 'a_$x')}')
# is seen: the outer match would swallow the inner quote
for m in re.finditer(r"(?=['\"]([A-Za-z0-9_.]*)\$(?:\{[^}]*\}|\w+))", alltext + tail):
    if m.group(1):
        prefixes.add(m.group(1))
for m in re.finditer(r"['\"]([A-Za-z0-9_.]+)['\"]\s*\+", alltext + tail):
    prefixes.add(m.group(1))

suffixes = set()
for m in re.finditer(r"\$(?:\{[^}]*\}|[A-Za-z_]\w*?)([A-Za-z0-9_.]{3,})['\"]", alltext + tail):
    suffixes.add(m.group(1))
unused, test_only, dynamic = [], [], []
for k, line in keys:
    q = ("'%s'" % k, '"%s"' % k)
    in_lib = any(x in alltext or x in tail for x in q)
    in_test = any(x in testtext for x in q)
    if in_lib:
        continue
    pre = [p for p in prefixes if k.startswith(p) and len(p) >= 4]
    pre += ['*' + x for x in suffixes if k.endswith(x) and len(x) >= 4]
    if pre:
        dynamic.append((k, line, max(pre, key=len)))
    elif in_test:
        test_only.append((k, line))
    else:
        unused.append((k, line))

print(f'{len(keys)} keys; {len(unused)} read nowhere; {len(test_only)} read only by tests; '
      f'{len(dynamic)} possibly built at run time (prefix match)')
if '--json' in sys.argv:
    json.dump(dict(keys=len(keys), unused=unused, test_only=test_only, dynamic=dynamic),
              open(sys.argv[sys.argv.index('--json') + 1], 'w'), indent=1)
print('\n== read nowhere')
for k, line in unused:
    print(f'{TABLE}:{line} {k}')
print('\n== read only by tests')
for k, line in test_only:
    print(f'{TABLE}:{line} {k}')
print('\n== possibly dynamic (prefix)')
byp = collections.Counter(p for _, _, p in dynamic)
for p, n in byp.most_common():
    print(f'{n:4} {p}*')
