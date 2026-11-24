"""Placeholders for the Tower's ink pictures (UX-2, pictures only).

The Tower's 14 PixelLab plates (assets/visuals/tower/) recoloured into the ink
palette by luminance percentile (near-black, cold greys, paper white), the same
map as make_ink_assets.py uses for the chibi sprites; no red, no outline. They
stand in for painted ink plates until Art makes them, and every picture that
uses one says so.

Run from the repo root:  python3 -W ignore docs/ux-shots/tower-ink/make_tower_ink.py
"""
from PIL import Image
import os

INK, G1, G2, G3, PAPER = [(0x09, 0x0A, 0x14), (0x20, 0x2E, 0x37), (0x39, 0x4A, 0x50),
                          (0x8B, 0x9B, 0xA0), (0xEB, 0xED, 0xE9)]
OUT = 'docs/ux-shots/tower-ink/assets'
SRC = 'assets/visuals/tower'
os.makedirs(OUT, exist_ok=True)


def lum(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def to_ink(path, cuts=(0.2, 0.45, 0.72, 0.93)):
    im = Image.open(path).convert('RGBA')
    px = list(im.getdata())
    ls = sorted(lum(p) for p in px if p[3] > 0)
    th = [ls[min(len(ls) - 1, int(c * len(ls)))] for c in cuts]
    pal = [INK, G1, G2, G3, PAPER]
    out = [(0, 0, 0, 0) if p[3] == 0 else pal[sum(lum(p) > t for t in th)] + (255,) for p in px]
    res = Image.new('RGBA', im.size)
    res.putdata(out)
    return res


for name in sorted(os.listdir(SRC)):
    if name.endswith('.png'):
        to_ink(f'{SRC}/{name}').save(f'{OUT}/{name}')
print('ok', len(os.listdir(OUT)))
