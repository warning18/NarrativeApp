import re,sys,glob,collections
src=open('lib/l10n/app_strings.dart',encoding='utf8').read()
# entries: 'key': { AppLanguage.en: '...' , AppLanguage.fr: '...' }  (strings may be concatenated)
entries={}
idx=[(m.start(),m.group(1)) for m in re.finditer(r"^  '([A-Za-z0-9_\.\-]+)':\s*\{",src,flags=re.M)]
for i,(pos,key) in enumerate(idx):
    end=idx[i+1][0] if i+1<len(idx) else len(src)
    entries[key]=src[pos:end]
print('keys parsed',len(entries))
def val(body,lang):
    m=re.search(r"AppLanguage\.%s:\s*((?:'(?:[^'\\]|\\.)*'|\"(?:[^\"\\]|\\.)*\"|\s)+)"%lang,body,flags=re.S)
    if not m: return None
    parts=re.findall(r"'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\"",m.group(1))
    return ''.join(a or b for a,b in parts)
missing_fr=[];missing_en=[];empty=[];same=[];ph=[]
for k,b in entries.items():
    en=val(b,'en'); fr=val(b,'fr')
    if en is None: missing_en.append(k); continue
    if fr is None: missing_fr.append(k); continue
    if not en.strip() or not fr.strip(): empty.append(k)
    if en==fr and len(en)>12 and re.search('[a-z]{4}',en): same.append(k)
    if sorted(re.findall(r'\{[a-zA-Z0-9_]+\}',en))!=sorted(re.findall(r'\{[a-zA-Z0-9_]+\}',fr)): ph.append(k)
print('missing French',len(missing_fr),missing_fr[:20])
print('missing English',len(missing_en),missing_en[:20])
print('empty',len(empty),empty[:20])
print('French identical to English (long, wordy)',len(same),same[:25])
print('placeholder mismatch EN/FR',len(ph),ph[:25])
# keys used in code
used=set()
for f in glob.glob('lib/**/*.dart',recursive=True):
    if f.endswith('app_strings.dart'): continue
    t=open(f,encoding='utf8').read()
    for m in re.finditer(r"\b(?:tr|trFor)\(\s*(?:ref|lang|[a-zA-Z_\.]+)\s*,\s*'([A-Za-z0-9_\.\-]+)'",t): used.add(m.group(1))
undefined=sorted(k for k in used if k not in entries)
print('keys used in code',len(used),'| used but undefined',len(undefined),undefined[:30])
unused=sorted(k for k in entries if k not in used)
print('defined, no literal use in code (dynamic keys possible)',len(unused))
open('/tmp/claude-0/-home-user-NarrativeApp/84491416-0bd1-56b3-939c-5ed3b5e40689/scratchpad/l3/strings_unused.txt','w').write('\n'.join(unused))
