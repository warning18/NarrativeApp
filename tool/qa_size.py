#!/usr/bin/env python3
"""QA: the biggest files and functions of lib/ and test/ (analysis only).

    python3 tool/qa_size.py [--files 1000] [--funcs 120]

Files over --files lines, and functions or methods over --funcs lines (a
declaration at class or file level whose body, found by matching braces on
the source with strings and comments blanked, runs that long). Also the
number of classes per file, for the files that should be split.
"""
import collections, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
FILES = int(sys.argv[sys.argv.index('--files') + 1]) if '--files' in sys.argv else 1000
FUNCS = int(sys.argv[sys.argv.index('--funcs') + 1]) if '--funcs' in sys.argv else 120
sys.path.insert(0, os.path.join(ROOT, 'tool'))
from qa_dart_scan import strip_code  # noqa: E402

rows, funcs = [], []
DECL = re.compile(r'^( {0,2})(?:@\w+(?:\([^)]*\))?\s*)*(?:static\s+|external\s+)*(?:[A-Za-z_][\w<>,?\[\]. ()]*?\s+)?(\w+)\s*(?:<[^>\n]*>)?\([^;{]*?\)\s*(?:async\*?\s*|sync\*\s*)?\{', re.M | re.S)
CLASS = re.compile(r'^(?:abstract |sealed |base |final |interface |mixin )*(?:class|mixin|enum|extension(?: type)?)\s+(\w*)', re.M)
for base in ('lib', 'test', 'tool'):
    for dp, _, fs in os.walk(os.path.join(ROOT, base)):
        for f in fs:
            if not f.endswith('.dart'):
                continue
            p = os.path.relpath(os.path.join(dp, f), ROOT)
            raw = open(os.path.join(ROOT, p), encoding='utf-8').read()
            n = raw.count('\n') + 1
            code, _ = strip_code(raw)
            rows.append((n, p, len(CLASS.findall(code))))
            if base != 'lib' and base != 'test':
                continue
            for m in DECL.finditer(code):
                name = m.group(2)
                if name in ('if', 'for', 'while', 'switch', 'catch', 'else', 'return'):
                    continue
                brace = m.end() - 1
                depth, i = 0, brace
                while i < len(code):
                    if code[i] == '{': depth += 1
                    elif code[i] == '}':
                        depth -= 1
                        if depth == 0: break
                    i += 1
                length = code.count('\n', brace, i) + 1
                if length >= FUNCS:
                    funcs.append((length, p, code.count('\n', 0, m.start()) + 1, name))

rows.sort(reverse=True)
big = [r for r in rows if r[0] >= FILES]
print(f'{len(rows)} Dart files, {sum(r[0] for r in rows)} lines; {len(big)} over {FILES} lines')
for n, p, c in big:
    print(f'{n:6} {p}  ({c} classes)')
funcs.sort(reverse=True)
print(f'\n{len(funcs)} functions over {FUNCS} lines')
for length, p, line, name in funcs[:60]:
    print(f'{length:5} {p}:{line} {name}')
