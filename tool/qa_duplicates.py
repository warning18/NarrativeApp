#!/usr/bin/env python3
"""QA: copy-pasted blocks in lib/ and test/ (analysis only).

    python3 tool/qa_duplicates.py [--min 15] [--dir lib] [--json out.json]

Lines are normalised (comments and blank lines dropped, whitespace squeezed,
number literals and string literals blanked) and every window of --min
consecutive lines is hashed. Windows that occur more than once, in one file
or in several, are merged into maximal blocks. The report lists each block
(its length, the places it occurs) biggest first; a block that is only
boilerplate (imports, a table of similar rows) is for a human to dismiss.
"""
import collections, hashlib, json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
MIN = int(sys.argv[sys.argv.index('--min') + 1]) if '--min' in sys.argv else 15
DIRS = [sys.argv[sys.argv.index('--dir') + 1]] if '--dir' in sys.argv else ['lib']

NUM = re.compile(r'\b\d+(?:\.\d+)?\b')
STR = re.compile(r"""r?'(?:\\.|[^'\\])*'|r?"(?:\\.|[^"\\])*\"""")


def norm(line):
    line = line.split('//')[0] if '//' in line and "'" not in line and '"' not in line else line
    line = STR.sub("''", line)
    line = NUM.sub('0', line)
    return re.sub(r'\s+', ' ', line).strip()


files = {}
for d in DIRS:
    for dp, _, fs in os.walk(os.path.join(ROOT, d)):
        for f in fs:
            if f.endswith('.dart'):
                p = os.path.relpath(os.path.join(dp, f), ROOT)
                lines = open(os.path.join(ROOT, p), encoding='utf-8').read().split('\n')
                keep = []
                for i, l in enumerate(lines, 1):
                    n = norm(l)
                    if not n or n.startswith(('//', '///', 'import ', 'export ', 'part ')):
                        continue
                    if n in ('}', '};', ');', '),', '],', '},', ']);', '});', '))', ')'):
                        pass
                    keep.append((i, n))
                files[p] = keep

windows = collections.defaultdict(list)
for p, keep in files.items():
    for i in range(0, len(keep) - MIN + 1):
        chunk = '\n'.join(n for _, n in keep[i:i + MIN])
        # a window of mostly closers or one repeated line is noise
        distinct = len(set(n for _, n in keep[i:i + MIN]))
        if distinct < MIN * 0.5:
            continue
        h = hashlib.md5(chunk.encode()).hexdigest()
        windows[h].append((p, i))

# merge: positions (file, idx) that start a repeated window, per hash group
rep = {h: v for h, v in windows.items() if len(v) > 1}
covered = collections.defaultdict(set)   # file -> set of idx starts in repeated windows
groups = {}
for h, v in rep.items():
    for p, i in v:
        covered[p].add(i)
# extend: consecutive starts in the same file with the same partner shift form one block
blocks = []
seen = set()
for h, v in sorted(rep.items(), key=lambda kv: kv[0]):
    for p, i in v:
        if (p, i) in seen:
            continue
        # grow while the next window is also repeated and its group has the same partners shifted by one
        partners = [(q, j) for q, j in v if (q, j) != (p, i)]
        length = MIN
        cur = [(p, i)] + partners
        k = 1
        while True:
            nxt = []
            ok = True
            for q, j in cur:
                kq = files[q]
                if j + k + MIN > len(kq):
                    ok = False; break
                nxt.append((q, j + k))
            if not ok:
                break
            hs = {hashlib.md5('\n'.join(n for _, n in files[q][j:j + MIN]).encode()).hexdigest() for q, j in nxt}
            if len(hs) != 1 or hs.pop() not in rep:
                break
            length += 1
            k += 1
        for q, j in cur:
            for t in range(k):
                seen.add((q, j + t))
        blocks.append((length, [(q, files[q][j][0], files[q][j + length - 1][0]) for q, j in cur]))

blocks.sort(key=lambda b: (-b[0], -len(b[1])))
# drop blocks whose places all lie inside blocks already listed (the same
# duplication seen from a shifted window)
shown = []
listed = collections.defaultdict(list)   # file -> [(a, b)] ranges of listed places
for length, places in blocks:
    def inside(q, a, b):
        return any(x <= a and b <= y for x, y in listed[q])
    if all(inside(q, a, b) for q, a, b in places):
        continue
    shown.append((length, places))
    for q, a, b in places:
        listed[q].append((a, b))

print(f'{len(shown)} duplicated blocks of {MIN}+ lines in {", ".join(DIRS)}; '
      f'{sum(l * (len(pl) - 1) for l, pl in shown)} lines repeated (copies beyond the first)')
for length, places in shown[:80]:
    print(f'\n{length} lines x {len(places)}:')
    for q, a, b in places:
        print(f'   {q}:{a}-{b}')
if '--json' in sys.argv:
    json.dump(shown, open(sys.argv[sys.argv.index('--json') + 1], 'w'), indent=1)
