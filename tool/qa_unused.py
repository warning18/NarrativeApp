#!/usr/bin/env python3
"""QA: a symbol-reference scan of lib/ for code nothing uses (analysis only,
nothing is edited). Read-only, no dependencies.

    python3 tool/qa_unused.py [--json out.json]

For every declaration in lib/ (top-level classes, mixins, enums, extensions,
typedefs, functions, constants, and the methods, getters, fields and enum
values inside them) it counts the identifier's uses in code (comments and
string literals stripped) across lib/, test/ and tool/ and says where they
are. A candidate is one of:

  dead        no use anywhere but its own declaration
  test_only   used only by test/ (the code exists for a test)
  file_only   public, but used only inside the file that declares it
              (could be private; a rename, not a deletion)

False positives to double-check by hand: a member read only through a JSON
key or a reflection-like lookup (the name appears in a string: `in_string`),
an @override or an interface a framework calls (`build`, `createState`,
`toString`, `hashCode`, `==`, `noSuchMethod`), a field set only by a named
constructor argument, a name shared with another symbol (`shared`: the count
is of the name, not of one receiver, so it only ever hides dead code).
"""
import collections, json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
SRC_DIRS = ['lib', 'test', 'tool']


def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read()


STRING_RE = re.compile(
    r"""r'''.*?'''|r\"\"\".*?\"\"\"|'''.*?'''|\"\"\".*?\"\"\"|r'[^'\n]*'|r"[^"\n]*"|'(?:\\.|[^'\\\n])*'|"(?:\\.|[^"\\\n])*\"""",
    re.S)
COMMENT_RE = re.compile(r'//[^\n]*|/\*.*?\*/', re.S)


sys.path.insert(0, os.path.join(ROOT, 'tool'))
from qa_dart_scan import strip_code  # noqa: E402


def files_under(d):
    for dp, _, fs in os.walk(os.path.join(ROOT, d)):
        for f in fs:
            if f.endswith('.dart'):
                yield os.path.join(dp, f)


IDENT = re.compile(r'[A-Za-z_$][A-Za-z0-9_$]*')
KEYWORDS = set('''abstract as assert async await base break case catch class const continue covariant default
deferred do dynamic else enum export extends extension external factory false final finally for Function get hide
if implements import in interface is late library mixin new null on operator part required rethrow return sealed
set show static super switch sync this throw true try typedef var void when while with yield int double num String
bool List Map Set Future Stream Object Iterable Never Type Record Duration DateTime'''.split())

code = {}       # path -> stripped source
strs = {}       # path -> list of string literals
for d in SRC_DIRS:
    for p in files_under(d):
        rel = os.path.relpath(p, ROOT)
        code[rel], strs[rel] = strip_code(read(p))

uses = collections.defaultdict(lambda: collections.Counter())   # name -> Counter(file)
for rel, src in code.items():
    for m in IDENT.finditer(src):
        uses[m.group(0)][rel] += 1
string_names = collections.Counter()
for rel, ss in strs.items():
    for s in ss:
        for m in IDENT.finditer(s):
            string_names[m.group(0)] += 1

# ---- declarations -------------------------------------------------------
TOP_TYPE = re.compile(r'^(?:abstract |sealed |base |final |interface |mixin )*(class|mixin|enum|extension type|extension|typedef)\s+(\w+)', re.M)
TOP_FUNC = re.compile(r'^(?:[A-Za-z_][\w<>,?\[\]\s.()]*?\s)?(\w+)\s*(?:<[^>\n]*>)?\(', re.M)
TOP_VAR = re.compile(r'^(?:final|const|var|late final|late)\s+(?:[\w<>,?\[\]. ()]+?\s+)?(\w+)\s*(?:=|;)', re.M)
decls = []   # dict(kind, name, file, line, owner, private, override)


def line_of(src, pos):
    return src.count('\n', 0, pos) + 1


def body_extent(src, open_pos):
    depth, i, n = 0, open_pos, len(src)
    while i < n:
        c = src[i]
        if c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0: return i
        i += 1
    return n


for rel, src in code.items():
    if not rel.startswith('lib/'):
        continue
    if rel.endswith('.g.dart'):
        continue
    raw_lines = read(os.path.join(ROOT, rel)).split('\n')
    top = []
    for m in TOP_TYPE.finditer(src):
        kind, name = m.group(1), m.group(2)
        decls.append(dict(kind=kind, name=name, file=rel, line=line_of(src, m.start()), owner=None))
        if kind == 'typedef':
            continue
        brace = src.find('{', m.end())
        semi = src.find(';', m.end())
        if brace < 0 or (0 <= semi < brace):
            continue
        end = body_extent(src, brace)
        top.append((m.start(), end, kind, name, brace))
    # top-level functions and variables: lines at column 0
    inside = [(a, b) for a, b, *_ in top]
    for m in TOP_FUNC.finditer(src):
        if any(a <= m.start() <= b for a, b in inside): continue
        name = m.group(1)
        if name in KEYWORDS or name in ('if', 'for', 'while', 'switch', 'catch', 'return', 'main'): continue
        line = src[src.rfind('\n', 0, m.start()) + 1: src.find('\n', m.start())]
        if line.startswith(('import', 'export', 'part', 'typedef', 'class', 'enum', 'mixin', 'extension')): continue
        if re.match(r'^\s', line): continue
        decls.append(dict(kind='function', name=name, file=rel, line=line_of(src, m.start()), owner=None))
    for m in TOP_VAR.finditer(src):
        if any(a <= m.start() <= b for a, b in inside): continue
        decls.append(dict(kind='constant', name=m.group(1), file=rel, line=line_of(src, m.start()), owner=None))
    # members of classes / mixins / enums / extensions
    for a, b, kind, owner, brace in top:
        body = src[brace + 1:b]
        base = brace + 1
        depth, i, n = 0, 0, len(body)
        start = 0
        stmts = []
        while i < n:
            c = body[i]
            if c in '{(': depth += 1 if c == '{' else 0
            if c == '{':
                pass
            i += 1
        # split into depth-0 chunks: a chunk ends at ';' or at the '}' that closes a body
        depth = 0; chunk_start = 0; paren = 0
        for i, c in enumerate(body):
            if c == '(' : paren += 1
            elif c == ')': paren -= 1
            elif c == '{': depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0 and paren == 0:
                    stmts.append((chunk_start, i + 1)); chunk_start = i + 1
            elif c == ';' and depth == 0 and paren == 0:
                stmts.append((chunk_start, i + 1)); chunk_start = i + 1
        if kind == 'enum':
            # values: up to the first top-level ';' (or the whole body if none)
            first = body.split(';')[0] if ';' in body else body
            vals_src = first
            depthp = 0
            cur = ''
            parts = []
            for c in vals_src:
                if c in '([{<': depthp += 1
                elif c in ')]}>': depthp -= 1
                if c == ',' and depthp == 0:
                    parts.append(cur); cur = ''
                else:
                    cur += c
            parts.append(cur)
            off = 0
            for part in parts:
                m = re.match(r'\s*(\w+)', part)
                if m and m.group(1) not in KEYWORDS and not part.strip().startswith(('static', 'final', 'const', 'int', 'String', 'bool')):
                    pos = base + body.find(part, off) + part.find(m.group(1))
                    decls.append(dict(kind='enum value', name=m.group(1), file=rel, line=line_of(src, pos), owner=owner))
                off += len(part)
            continue
        for s, e in stmts:
            text = body[s:e]
            head = text.strip()
            if not head: continue
            pos = base + s + (len(text) - len(text.lstrip()))
            line = line_of(src, pos)
            if '@override' in raw_lines[max(0, line - 2)] or '@override' in raw_lines[line - 1]:
                continue
            h = re.sub(r'^(?:@\w+(?:\([^)]*\))?\s*)+', '', head)
            h = re.sub(r'^(?:static |external |abstract |late |final |const |covariant |factory )+', lambda m: m.group(0), h)
            m = re.match(r'(?:static\s+|abstract\s+)*(?:(?:[\w<>,?\[\]. ]+?)\s+)?(get|set)\s+(\w+)', h)
            if m:
                decls.append(dict(kind=m.group(1) + 'ter', name=m.group(2), file=rel, line=line, owner=owner)); continue
            m = re.match(r'(?:static\s+)?(?:const\s+|factory\s+)?%s(?:\.(\w+))?\s*\(' % re.escape(owner), h)
            if m:
                if m.group(1):
                    decls.append(dict(kind='constructor', name=owner + '.' + m.group(1), file=rel, line=line, owner=owner, short=m.group(1)))
                continue
            m = re.match(r'factory\s+%s(?:\.(\w+))?\s*\(' % re.escape(owner), h)
            if m:
                if m.group(1):
                    decls.append(dict(kind='constructor', name=owner + '.' + m.group(1), file=rel, line=line, owner=owner, short=m.group(1)))
                continue
            m = re.match(r'(?:static\s+|abstract\s+|external\s+)*(?:[\w<>,?\[\]. ()]+?\s+)?(operator\s*\S+|\w+)\s*(?:<[^>]*>)?\(', h)
            if m and not re.match(r'(?:static\s+|late\s+)*(?:final|const|var)\b', h) and '=>' in h or (m and '{' in h and re.match(r'.*\)\s*(?:async\*?|sync\*)?\s*\{', h.split('\n')[0] + (h.split('\n')[1] if '\n' in h else ''), re.S)):
                name = m.group(1)
                if name.startswith('operator') or name in KEYWORDS: continue
                decls.append(dict(kind='method', name=name, file=rel, line=line, owner=owner)); continue
            m = re.match(r'(?:static\s+|late\s+|final\s+|const\s+|var\s+|covariant\s+)+(?:[\w<>,?\[\]. ()]+?\s+)?(\w+)\s*(?:=|;|$)', h) \
                or re.match(r'(?:[A-Z][\w<>,?\[\]. ]*?)\s+(\w+)\s*(?:=|;)', h)
            if m:
                decls.append(dict(kind='field', name=m.group(1), file=rel, line=line, owner=owner))

OVERRIDDEN = {'build', 'createState', 'toString', 'hashCode', 'initState', 'dispose', 'didUpdateWidget',
              'didChangeDependencies', 'copyWith', 'toJson', 'fromJson', 'values', 'key', 'main', 'props',
              'noSuchMethod', 'paint', 'shouldRepaint', 'hitTest', 'performLayout', 'createElement',
              'debugFillProperties', 'dispatch', 'reassemble', 'deactivate', 'activate', 'call'}


def classify(d):
    name = d['name']
    short = d.get('short') or name.split('.')[-1]
    token = short if d['kind'] != 'constructor' else short
    c = uses.get(token, collections.Counter())
    total = sum(c.values())
    own = c.get(d['file'], 0)
    in_lib_other = sum(v for f, v in c.items() if f.startswith('lib/') and f != d['file'])
    in_test = sum(v for f, v in c.items() if f.startswith('test/'))
    in_tool = sum(v for f, v in c.items() if f.startswith('tool/'))
    decl_uses = 1  # the declaration itself
    if d['kind'] == 'constructor':
        decl_uses = 1
    others_own = own - decl_uses
    # same-name declarations count as uses of each other: the name is shared
    shared = sum(1 for x in NAME_COUNT[token:token + 1]) if False else NAME_DECLS[token] > 1
    if d['kind'] in ('class', 'enum', 'mixin', 'extension', 'typedef'):
        # a type's own file mentions it in its constructor and factories
        pass
    return dict(total=total, own=own, lib_other=in_lib_other, test=in_test, tool=in_tool,
                shared=shared, in_string=string_names.get(token, 0) > 0)


NAME_DECLS = collections.Counter()
for d in decls:
    NAME_DECLS[d.get('short') or d['name'].split('.')[-1]] += 1

# Constructor mentions inside a class body (its own name) are not uses of the type.
rows = []
for d in decls:
    short = d.get('short') or d['name'].split('.')[-1]
    if short in OVERRIDDEN and d['kind'] in ('method', 'getter', 'setter', 'field'):
        continue
    if d['kind'] == 'extension':
        continue
    info = classify(d)
    if d['kind'] in ('class', 'mixin', 'enum', 'extension'):
        # discount self-references inside the declaring file: constructors,
        # `const Foo(...)`, `Foo.of`, and State classes. Count the file's uses
        # outside the declaration's own body.
        src = code[d['file']]
        m = re.search(r'\b(?:class|mixin|enum|extension)\s+%s\b' % re.escape(short), src)
        if m:
            brace = src.find('{', m.end())
            end = body_extent(src, brace) if brace >= 0 else m.end()
            inside = len(re.findall(r'\b%s\b' % re.escape(short), src[m.start():end + 1]))
            info['own'] = info['own'] - inside
            info['own_outside_body'] = info['own']
    elif d['kind'] in ('method', 'field', 'getter', 'setter', 'function', 'constant', 'constructor'):
        info['own'] = info['own'] - 1
    status = None
    external_uses = info['lib_other'] + info['tool']
    if external_uses == 0 and info['test'] == 0 and info['own'] <= 0:
        status = 'dead'
    elif external_uses == 0 and info['own'] <= 0 and info['test'] > 0:
        status = 'test_only'
    elif external_uses == 0 and info['test'] == 0 and info['own'] > 0 and not short.startswith('_') and d['owner'] is None:
        status = 'file_only'
    if status:
        rows.append(dict(d, status=status, **info))

rows.sort(key=lambda r: (r['status'], r['file'], r['line']))
if '--json' in sys.argv:
    out = sys.argv[sys.argv.index('--json') + 1]
    json.dump(rows, open(out, 'w'), indent=1)
by = collections.Counter((r['status'], r['kind']) for r in rows)
for (s, k), n in sorted(by.items()):
    print(f'{s:10} {k:12} {n}')
print(len(decls), 'declarations scanned in', len([f for f in code if f.startswith("lib/")]), 'lib files')
for r in rows:
    flag = ' [in_string]' if r['in_string'] else ''
    flag += ' [shared]' if r['shared'] else ''
    owner = f"{r['owner']}." if r.get('owner') else ''
    print(f"{r['status']:9} {r['kind']:11} {r['file']}:{r['line']} {owner}{r['name']}{flag}")
