#!/usr/bin/env python3
"""French typography pass over lib/l10n/app_strings.dart (Narrative).

Rewrites ONLY the text inside the French string literals (the value after
`AppLanguage.fr:`), never a key, never an English value:

  1. a plain space before  :  ;  !  ?  %  becomes a no-break space (\\u00a0);
  2. « and » are padded with a no-break space inside, not a plain space;
  3. a straight apostrophe between two letters (l'étage, \\') becomes ’.

Idempotent: a second run changes nothing.

  python3 tool/fix_fr_typography.py            # dry run: counts + 10 samples
  python3 tool/fix_fr_typography.py --write    # apply in place
  python3 tool/fix_fr_typography.py --tests test/a_test.dart test/b_test.dart
      # bring the French expectations of THESE test files to the same spelling
      # (single-line literals that carry a French marker and a violation; test
      # names and the French lint tests are never touched). Run it only on the
      # files that fail after the pass; do not run it on all of test/.

Run `dart format lib/l10n/app_strings.dart` afterwards (long lines re-wrap).
"""
import re
import sys

PATH = 'lib/l10n/app_strings.dart'
NB = '\u00a0'          # the character, for matching
NB_SRC = '\\u00a0'      # how it is written in the Dart source (readable in diffs)


def scan_literals(src, i):
    """Yield (start, end, quote, raw) of consecutive Dart string literals
    starting at index i (skipping whitespace between adjacent ones)."""
    n = len(src)
    while True:
        j = i
        while j < n and src[j] in ' \t\r\n':
            j += 1
        raw = False
        if j < n and src[j] == 'r' and j + 1 < n and src[j + 1] in '\'"':
            raw = True
            j += 1
        if j >= n or src[j] not in '\'"':
            return
        q = src[j]
        k = j + 1
        while k < n:
            c = src[k]
            if c == '\\' and not raw:
                k += 2
                continue
            if c == q:
                break
            k += 1
        yield (j + 1, k, q, raw)
        i = k + 1


def fix(text, quote):
    out = text
    # straight apostrophe between letters: \' (escaped in a '...' literal) or '
    out = re.sub(r"\\'(?=\w)", '’', out)
    out = re.sub(r"(?<=\w)\\'", '’', out)
    if quote == '"':
        out = re.sub(r"(?<=\w)'(?=\w)", '’', out)
    # « text »
    out = re.sub(r'«[ ' + NB + r']+', lambda m: '«' + NB_SRC, out)
    out = re.sub(r'[ ' + NB + r']+»', lambda m: NB_SRC + '»', out)
    # space before : ; ! ? %  (not after another space, not in {placeholders})
    out = re.sub(r'(?<=[^\s' + NB + r'\\]) ([:;!?%])', lambda m: NB_SRC + m.group(1), out)
    return out


FRENCH = re.compile(r"[éèêàâçùûôîœÉÈÊÀ]|\b(vous|votre|vos|le|la|les|des|une|du|de|pour|avec|sur)\b", re.I)
LIT = re.compile(r"(?<![\w$])(\'(?:[^\'\\\n]|\\.)*\'|\"(?:[^\"\\\n]|\\.)*\")")


SKIP_TESTS = ('french_data_lint_test', 'french_address_test', 'qa_story_fr_test',
              'l10n_data_test', 'qa_strings_test', 'app_strings_french_typography_test')


def fix_tests(paths):
    total = 0
    for path in paths:
        if any(k in path for k in SKIP_TESTS):
            print('  skipped (lint test):', path)
            continue
        txt = open(path, encoding='utf-8').read()

        def repl(m):
            lit = m.group(1)
            q = lit[0]
            body = lit[1:-1]
            if '${' in body or not FRENCH.search(body):
                return lit
            before = txt[max(0, m.start() - 12):m.start()]
            if re.search(r"(test|group|testWidgets)\(\s*$", before):
                return lit      # a test's name is not an expectation
            new = fix(body, q)
            return lit if new == body else q + new + q

        out = LIT.sub(repl, txt)
        if out != txt:
            total += 1
            open(path, 'w', encoding='utf-8').write(out)
            print('  test updated:', path)
    print('test files updated:', total)


def main():
    if '--tests' in sys.argv:
        fix_tests([a for a in sys.argv[1:] if a.endswith('.dart')])
        return
    write = '--write' in sys.argv
    src = open(PATH, encoding='utf-8').read()
    out = []
    pos = 0
    changed = 0
    samples = []
    for m in re.finditer(r'AppLanguage\.fr:', src):
        if m.start() < pos:
            continue
        for (a, b, q, raw) in scan_literals(src, m.end()):
            if raw:
                continue
            old = src[a:b]
            if '${' in old:      # never touch Dart code inside a string
                continue
            new = fix(old, q)
            if new != old:
                changed += 1
                if len(samples) < 10:
                    samples.append((old, new))
                out.append(src[pos:a])
                out.append(new)
                pos = b
    out.append(src[pos:])
    result = ''.join(out)
    print('French literals changed:', changed)
    for old, new in samples:
        print('  before:', old.replace(NB, '⍽')[:100])
        print('  after: ', new.replace(NB_SRC, '⍽').replace(NB, '⍽')[:100])
    if write:
        open(PATH, 'w', encoding='utf-8').write(result)
        print('written')


if __name__ == '__main__':
    main()
