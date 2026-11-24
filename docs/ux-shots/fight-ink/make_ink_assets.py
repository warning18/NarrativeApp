"""Ink versions of the real chibi sprites (UX-2, pictures only).

The sprites keep their drawing; only the colours change: near-black, cold greys
and paper white by luminance percentile (as make_b_assets.py does for B), one
pixel of ink round each, and deep red only on the small parts that are red
already in the source (sash, eyes, weapon edge), capped to a few percent so it
never takes over.

Run from the repo root:  python3 docs/ux-shots/fight-ink/make_ink_assets.py
"""
from PIL import Image, ImageFilter
import os

INK, G1, G2, G3, PAPER = [(0x09, 0x0A, 0x14), (0x20, 0x2E, 0x37), (0x39, 0x4A, 0x50),
                          (0x8B, 0x9B, 0xA0), (0xEB, 0xED, 0xE9)]
RED = (0xB0, 0x14, 0x1C)
OUT = 'docs/ux-shots/fight-ink/assets'
os.makedirs(OUT, exist_ok=True)


def lum(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def redness(p):
    r, g, b = p[:3]
    return r - max(g, b)


def to_ink(path, cuts=(0.18, 0.42, 0.72, 0.93), red_share=0.05):
    im = Image.open(path).convert('RGBA')
    px = list(im.getdata())  # noqa
    solid = [p for p in px if p[3] > 0]
    ls = sorted(lum(p) for p in solid)
    th = [ls[min(len(ls) - 1, int(c * len(ls)))] for c in cuts]
    # the reddest few percent of the sprite, and only if clearly red
    reds = sorted((redness(p) for p in solid), reverse=True)
    cap = reds[min(len(reds) - 1, max(1, int(red_share * len(reds))))]
    red_min = max(cap, 40)
    pal = [INK, G1, G2, G3, PAPER]
    out = []
    for p in px:
        if p[3] == 0:
            out.append((0, 0, 0, 0))
        elif redness(p) >= red_min and lum(p) < 135:
            out.append(RED + (255,))
        else:
            out.append(pal[sum(lum(p) > t for t in th)] + (255,))
    res = Image.new('RGBA', im.size)
    res.putdata(out)
    pad = Image.new('RGBA', (im.width + 2, im.height + 2), (0, 0, 0, 0))
    pad.paste(res, (1, 1))
    grown = pad.split()[3].filter(ImageFilter.MaxFilter(3))
    ring = Image.new('RGBA', pad.size, INK + (255,))
    ring.putalpha(grown)
    ring.alpha_composite(pad)
    return ring


foes = {'void_sovereign': 'assets/visuals/fighters/void_sovereign_idle_west.png',
        'inquisition_warden': 'assets/visuals/fighters/inquisition_warden_idle_west.png',
        'white_soldier': 'assets/visuals/fighters/white_soldier_idle_west.png'}
heroes = {'warrior': 'assets/visuals/heroes/warrior_stand_east.png',
          'cleric': 'assets/visuals/heroes/cleric_stand_east.png',
          'mage': 'assets/visuals/heroes/mage_stand_east.png'}
for name, path in {**foes, **heroes}.items():
    to_ink(path).save(f'{OUT}/{name}.png')
print('ok', sorted(os.listdir(OUT)))
