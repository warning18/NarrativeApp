"""Python port of the asset/manifest guards (flutter is not installed in the Art session): test/qa_assets_declared_test.dart (1) and test/icon_sizes_test.dart. python3 art/pixellab-audit/asset_checks.py"""
import os, re, struct, sys
SRC={'assets/visuals/companion/dog_companion_animations/Sitting_down/rotations','assets/visuals/companion/dog_companion_animations/Make_it_with_angel_w/rotations','assets/visuals/companion/dog_companion_animations/Make_it_with_demon_w/rotations','assets/visuals/companion/dog_companion_animations/Fight_-_Attack/animations/Bark/south','assets/visuals/companion/dog_companion_animations/Fight_-_Attack/rotations','assets/visuals/companion/dog_companion_animations/Fight_-_Attack/animations/Bark/east','assets/visuals/companion/dog_companion_animations/Fight_-_Attack/animations/Bark/north','assets/visuals/companion/dog_companion_animations/Fight_-_Attack/animations/Bark/west'}
decl=set(re.findall(r'^\s+- (assets/\S+)',open('pubspec.yaml').read(),re.M))
miss=set()
for r,_,fs in os.walk('assets'):
    for f in fs:
        if f.endswith(('.png','.webp')):
            p=os.path.join(r,f).replace('\\','/');fo=p.rsplit('/',1)[0]
            if fo+'/' in decl or p in decl or fo in SRC: continue
            miss.add(fo)
big=[];n=0
for r,_,fs in os.walk('assets/icons'):
    for f in fs:
        if f.endswith('.png'):
            n+=1;h=open(os.path.join(r,f),'rb').read(24);w,hh=struct.unpack('>II',h[16:24])
            if w>32 or hh>32: big.append((os.path.join(r,f),w,hh))
gone=[s for s in SRC if not os.path.isdir(s)]
ok=not miss and not big and n>300 and not gone
print('declared-missing',sorted(miss),'| icons',n,'too big',big,'| source-only gone',gone,'|','PASS' if ok else 'FAIL')
sys.exit(0 if ok else 1)
