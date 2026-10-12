#!/usr/bin/env python3
"""Draws the Lantern Throne room of the Clans screen (v1.247).

Writes to assets/visuals/throne/: the throne on its dais (throne.png, 128x144),
a brazier (brazier.png, 24x40) and three tiles (wall, floor, carpet), and to
assets/visuals/pixel_fx/ the brazier's flame (throne_flame.png, six 24x24
frames, in fire colours). The app shows the scenery at x2.
Run from the repo root:  python3 tool/gen_throne_room.py
"""
import os
import random

from PIL import Image, ImageDraw

OUT = (10, 8, 7, 255)
S0 = (24, 18, 28, 255)
S1 = (42, 34, 50, 255)
S2 = (70, 60, 84, 255)
S3 = (112, 100, 128, 255)
CREAM = (236, 224, 196, 255)
GOLD = (217, 164, 65, 255)
GOLD_D = (150, 104, 34, 255)
GOLD_L = (255, 222, 128, 255)
RED = (120, 24, 36, 255)
RED_L = (168, 44, 52, 255)
RED_D = (70, 12, 22, 255)
CLEAR = (0, 0, 0, 0)


def canvas(w, h):
    im = Image.new('RGBA', (w, h), CLEAR)
    return im, ImageDraw.Draw(im)


def box(d, x0, y0, x1, y1, fill, edge=OUT):
    """A filled box with a one pixel outline."""
    d.rectangle([x0, y0, x1, y1], fill=edge)
    d.rectangle([x0 + 1, y0 + 1, x1 - 1, y1 - 1], fill=fill)


def trapezoid(d, top_y, bottom_y, top_x0, top_x1, bottom_x0, bottom_x1, fill, edge=OUT):
    d.polygon([(top_x0, top_y), (top_x1, top_y), (bottom_x1, bottom_y), (bottom_x0, bottom_y)], fill=edge)
    d.polygon([(top_x0 + 1, top_y + 1), (top_x1 - 1, top_y + 1), (bottom_x1 - 1, bottom_y - 1), (bottom_x0 + 1, bottom_y - 1)], fill=fill)


def throne():
    im, d = canvas(128, 144)
    # --- the dais: three steps, a lit top and a dark front on each
    steps = [(104, 115, 22, 105), (116, 127, 14, 113), (128, 143, 6, 121)]
    for y0, y1, x0, x1 in steps:
        box(d, x0, y0, x1, y1, S1)
        d.rectangle([x0 + 1, y0 + 1, x1 - 1, y0 + 3], fill=S3)         # the lit tread
        d.rectangle([x0 + 1, y0 + 4, x1 - 1, y0 + 5], fill=S2)
        d.rectangle([x0 + 1, y1 - 2, x1 - 1, y1 - 1], fill=S0)         # shadow under the edge
        for x in range(x0 + 6, x1 - 4, 14):                            # joints in the stone
            d.line([(x, y0 + 6), (x, y1 - 3)], fill=S0)
    # --- the carpet runs down the steps
    for y0, y1, x0, x1 in [(104, 115, 52, 75), (116, 127, 49, 78), (128, 143, 46, 81)]:
        d.rectangle([x0, y0 + 1, x1, y1], fill=GOLD_D)
        d.rectangle([x0 + 2, y0 + 1, x1 - 2, y1], fill=RED)
        d.rectangle([x0 + 2, y0 + 1, x0 + 3, y1], fill=RED_L)
        d.rectangle([x1 - 3, y0 + 1, x1 - 2, y1], fill=RED_D)
    # --- the throne: wings, back, arch
    box(d, 36, 50, 91, 103, S1)
    box(d, 44, 28, 83, 103, S2)
    d.polygon([(43, 29), (64, 3), (84, 29)], fill=OUT)
    d.polygon([(45, 29), (64, 6), (82, 29)], fill=S2)
    # the lit left edge and the dark right edge of the back
    d.rectangle([45, 29, 47, 84], fill=S3)
    d.rectangle([80, 29, 82, 84], fill=S1)
    # an inner panel with gold trim and thin slits cut in it
    box(d, 50, 36, 77, 84, S0, GOLD_D)
    d.rectangle([51, 37, 76, 38], fill=GOLD)
    d.polygon([(50, 36), (64, 17), (77, 36)], fill=GOLD_D)
    d.polygon([(52, 36), (64, 20), (75, 36)], fill=S0)
    for x in (56, 64, 71):
        d.rectangle([x, 56, x + 1, 82], fill=S1)
        d.point((x, 56), fill=CREAM)
    # the crest: a gold ring round a lantern
    d.ellipse([54, 17, 74, 37], fill=OUT)
    d.ellipse([55, 18, 73, 36], fill=GOLD)
    d.ellipse([57, 20, 71, 34], fill=GOLD_D)
    d.ellipse([58, 21, 70, 33], fill=S0)
    d.rectangle([62, 24, 66, 31], fill=CREAM)                          # the lantern
    d.rectangle([63, 26, 65, 29], fill=GOLD_L)
    d.rectangle([61, 23, 67, 23], fill=GOLD)
    d.rectangle([62, 32, 66, 32], fill=GOLD)
    d.rectangle([63, 21, 65, 22], fill=GOLD)                           # its ring
    # a bead on the apex and one on each wing
    for cx, cy in [(64, 3), (38, 50), (89, 50)]:
        d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=OUT)
        d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=GOLD)
        d.point((cx - 1, cy - 1), fill=GOLD_L)
    # armrests
    for x0 in (34, 85):
        box(d, x0, 70, x0 + 9, 98, S1)
        d.rectangle([x0 + 1, 71, x0 + 8, 73], fill=S3)
        d.ellipse([x0 + 1, 64, x0 + 8, 72], fill=OUT)
        d.ellipse([x0 + 2, 65, x0 + 7, 71], fill=GOLD)
        d.point((x0 + 3, 66), fill=GOLD_L)
    # the seat: a deep red cushion on a stone base
    box(d, 40, 92, 87, 103, S1)
    d.rectangle([41, 93, 86, 94], fill=S3)
    box(d, 46, 80, 81, 93, RED, OUT)
    d.rectangle([47, 81, 80, 83], fill=RED_L)
    d.rectangle([47, 90, 80, 92], fill=RED_D)
    for x in range(52, 78, 8):
        d.point((x, 86), fill=GOLD)
    # the throne's feet on the top step
    box(d, 38, 100, 49, 104, S0)
    box(d, 78, 100, 89, 104, S0)
    return im


def brazier():
    im, d = canvas(24, 40)
    box(d, 9, 14, 14, 33, S1)                                           # the stem
    d.rectangle([10, 15, 11, 32], fill=S3)
    trapezoid(d, 6, 14, 3, 20, 7, 16, S2)                               # the bowl
    d.rectangle([3, 6, 20, 8], fill=GOLD)
    d.rectangle([4, 6, 8, 6], fill=GOLD_L)
    d.rectangle([5, 9, 18, 10], fill=S3)
    box(d, 5, 32, 18, 39, S1)                                           # the foot
    d.rectangle([6, 33, 17, 34], fill=S3)
    d.rectangle([6, 37, 17, 38], fill=S0)
    # coals
    for x in (6, 9, 12, 15, 17):
        d.point((x, 5), fill=RED_L)
    return im


def flame_frames():
    """Six 24x24 frames in the lantern's own fire: core, flame, edge, ember."""
    tones = [(255, 240, 170, 255), (255, 168, 58, 255), (214, 84, 38, 255), (120, 34, 30, 255)]
    rnd = random.Random(7)
    strip = Image.new('RGBA', (24 * 6, 24), CLEAR)
    for f in range(6):
        im, d = canvas(24, 24)
        sway = [0, 1, 2, 1, 0, -1][f]
        lick = [0, 2, 1, 3, 1, 2][f]
        cx = 12 + sway // 2
        # outer flame (shadow tone), middle, core
        d.polygon([(cx - 6, 23), (cx - 7, 15), (cx - 3, 8 - lick // 2), (cx + 1 + sway, 1 + lick), (cx + 2, 8), (cx + 7, 14), (cx + 6, 23)], fill=tones[2])
        d.polygon([(cx - 4, 23), (cx - 5, 16), (cx - 1, 9), (cx + 1 + sway, 5 + lick), (cx + 3, 11), (cx + 5, 16), (cx + 4, 23)], fill=tones[1])
        d.polygon([(cx - 2, 23), (cx - 2, 17), (cx + 0, 12), (cx + 1, 17), (cx + 2, 23)], fill=tones[0])
        # a lick and a spark that rise with the frame
        d.point((cx + 4 - f, 4 + (f * 3) % 7), fill=tones[0])
        if f % 2:
            d.point((cx - 5 + f % 3, 6 + rnd.randint(0, 3)), fill=tones[1])
        strip.paste(im, (f * 24, 0))
    return strip


def wall_tile():
    im, d = canvas(16, 16)
    d.rectangle([0, 0, 15, 15], fill=S0)
    for row, (y0, off) in enumerate([(0, 0), (8, 8)]):
        for x0 in (-8 + off, 0 + off, 8 + off):
            x0 = x0 % 16
            d.rectangle([x0 + 1, y0 + 1, min(15, x0 + 6), y0 + 6], fill=S1)
            d.line([(x0 + 1, y0 + 1), (min(15, x0 + 6), y0 + 1)], fill=S2)
    d.point((3, 4), fill=S2)
    d.point((12, 12), fill=S2)
    return im


def floor_tile():
    im, d = canvas(16, 16)
    d.rectangle([0, 0, 15, 15], fill=S0)
    d.rectangle([1, 1, 14, 14], fill=S1)
    d.line([(1, 1), (14, 1)], fill=S2)
    d.line([(1, 1), (1, 14)], fill=S2)
    d.point((6, 7), fill=S2)
    d.point((10, 10), fill=S0)
    return im


def carpet_tile():
    """36 wide: the carpet as it runs over the dais's lowest step."""
    im, d = canvas(36, 16)
    d.rectangle([0, 0, 35, 15], fill=GOLD_D)
    d.rectangle([2, 0, 33, 15], fill=RED)
    d.rectangle([2, 0, 3, 15], fill=RED_L)
    d.rectangle([31, 0, 33, 15], fill=RED_D)
    # a diamond down the middle
    d.polygon([(18, 2), (24, 8), (18, 14), (12, 8)], fill=GOLD_D)
    d.polygon([(18, 4), (22, 8), (18, 12), (14, 8)], fill=RED_D)
    d.point((18, 8), fill=GOLD_L)
    d.point((7, 8), fill=GOLD)
    d.point((28, 8), fill=GOLD)
    return im


def main():
    root = os.path.join('assets', 'visuals', 'throne')
    os.makedirs(root, exist_ok=True)
    throne().save(os.path.join(root, 'throne.png'))
    brazier().save(os.path.join(root, 'brazier.png'))
    wall_tile().save(os.path.join(root, 'wall_tile.png'))
    floor_tile().save(os.path.join(root, 'floor_tile.png'))
    carpet_tile().save(os.path.join(root, 'carpet_tile.png'))
    flame_frames().save(os.path.join('assets', 'visuals', 'pixel_fx', 'throne_flame.png'))
    print('throne room written')


if __name__ == '__main__':
    main()
