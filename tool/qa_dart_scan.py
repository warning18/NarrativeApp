"""Shared by the tool/qa_*.py scans: Dart source with its comments and string
literals blanked (line numbers kept), the code interpolated into strings kept."""
import re


def _scan_string(src, i, raw, delim, exprs):
    """From just after the opening delimiter; returns the index past the
    closing one. Interpolated code goes into [exprs]."""
    n = len(src)
    triple = len(delim) == 3
    j = i
    while j < n:
        c = src[j]
        if not raw and c == '\\':
            j += 2; continue
        if src.startswith(delim, j):
            return j + len(delim)
        if not triple and c == '\n':
            return j
        if not raw and c == '$':
            if src.startswith('${', j):
                k = j + 2
                depth = 1
                start = k
                while k < n and depth:
                    ch = src[k]
                    if ch in '\'"':
                        d2 = ch * 3 if src.startswith(ch * 3, k) else ch
                        k = _scan_string(src, k + len(d2), False, d2, exprs)
                        continue
                    if ch == '{': depth += 1
                    elif ch == '}': depth -= 1
                    k += 1
                exprs.append(src[start:k - 1].replace('\n', ' '))
                j = k; continue
            m = re.match(r'\$([A-Za-z_]\w*)', src[j:j + 80])
            if m:
                exprs.append(m.group(1))
        j += 1
    return n


def strip_code(src):
    """Source with comments and string literals blanked (newlines kept, the
    code inside a string's ${...} and $name kept), and the strings apart (for
    the in_string check)."""
    strings = []
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith('//', i):
            j = src.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i)); i = j
        elif src.startswith('/*', i):
            j = src.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out.append(re.sub(r'[^\n]', ' ', src[i:j])); i = j
        elif c in '\'"' or (c == 'r' and i + 1 < n and src[i + 1] in '\'"'
                            and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == '_'))):
            raw = c == 'r'
            k = i + 1 if raw else i
            q = src[k]
            delim = q * 3 if src.startswith(q * 3, k) else q
            exprs = []
            j = _scan_string(src, k + len(delim), raw, delim, exprs)
            strings.append(src[i:j])
            out.append(re.sub(r'[^\n]', ' ', src[i:j]) + ' ' + ' ; '.join(exprs) + ' ')
            i = j
        else:
            out.append(c); i += 1
    return ''.join(out), strings
