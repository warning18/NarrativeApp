#!/usr/bin/env python3
"""The hero's walk in side view, one strip per facing for each variant of the
user's PixelLab Hero states (the frames Art exports in art/hero-walks).

Writes assets/visuals/heroes/<name>_walk_{east,west}.png (the frames side by
side, 48 x 48 each, the feet on the last row) and <name>_stand_{east,west}.png
(the frame where the legs are closest together, for a hero who stops).
Nothing is drawn: every pixel is the frame's own, only the window moves so the
feet stay where they were and the figure sits in the middle.

Run from the repository root:  python3 tool/gen_hero_walks.py
"""
import glob
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import png8  # noqa: E402

SRC = 'art/hero-walks'
OUT = 'assets/visuals/heroes'
SIZE = 48

# The variant's name in the game, and its folder in art/hero-walks.
VARIANTS = {
    'warrior': '27_hero_hero_basic_warrior',
    'mage': '14_hero_hero_mage',
    'cleric': '05_hero_cleric',
    'ranger': '11_hero_rogue_starter',
    'rogue': '12_hero_hero_rogue_basic',
}


def save(path, im):
    im.save(path)
    r = png8.palette_version(path)
    if r:
        rgba, out = r
        out.save(path, 'PNG', optimize=True,
                 transparency=out.info['transparency'])


def strip(frames):
    boxes = [f.getchannel('A').getbbox() for f in frames]
    boxes = [b for b in boxes if b]
    bottom = max(b[3] for b in boxes)
    centre = sum((b[0] + b[2]) / 2 for b in boxes) / len(boxes)
    x0 = round(centre - SIZE / 2)
    y0 = bottom - SIZE
    out = Image.new('RGBA', (SIZE * len(frames), SIZE))
    for i, f in enumerate(frames):
        f = f.convert('RGBA')
        # Paste through a window so what lies outside the canvas is empty.
        win = Image.new('RGBA', (SIZE, SIZE))
        win.paste(f, (-x0, -y0))
        out.paste(win, (i * SIZE, 0))
    return out


def stand(frames):
    def width(f):
        b = f.getchannel('A').getbbox()
        return (b[2] - b[0]) if b else 999
    return min(range(len(frames)), key=lambda i: (width(frames[i]), i))


os.makedirs(OUT, exist_ok=True)
for name, folder in VARIANTS.items():
    for facing in ('east', 'west'):
        files = sorted(glob.glob(f'{SRC}/{folder}/{facing}/frame_*.png'))
        frames = [Image.open(f).convert('RGBA') for f in files]
        s = strip(frames)
        save(f'{OUT}/{name}_walk_{facing}.png', s)
        i = stand(frames)
        save(f'{OUT}/{name}_stand_{facing}.png',
             s.crop((i * SIZE, 0, (i + 1) * SIZE, SIZE)))
        print(name, facing, len(frames), 'frames, standing', i)
