#!/usr/bin/env python3
"""Draws the Lantern Throne room of the Clans screen (v1.247).

Writes to assets/visuals/throne/: the throne on its dais (throne.png, 128x144),
a brazier (brazier.png, 24x40), the carpet tile and the parts of a standard
(pole tile, foot and finial) the banners stand on, and to
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
    """A gilded throne with a red velvet back and seat, on a low dais."""
    im, d = canvas(128, 144)
    # --- the dais: three steps, a lit top and a dark front on each
    steps = [(104, 115, 22, 105), (116, 127, 14, 113), (128, 143, 6, 121)]
    for y0, y1, x0, x1 in steps:
        box(d, x0, y0, x1, y1, S1)
        d.rectangle([x0 + 1, y0 + 1, x1 - 1, y0 + 3], fill=S3)
        d.rectangle([x0 + 1, y0 + 4, x1 - 1, y0 + 5], fill=S2)
        d.rectangle([x0 + 1, y1 - 2, x1 - 1, y1 - 1], fill=S0)
        for x in range(x0 + 6, x1 - 4, 14):
            d.line([(x, y0 + 6), (x, y1 - 3)], fill=S0)
    for y0, y1, x0, x1 in [(104, 115, 52, 75), (116, 127, 49, 78), (128, 143, 46, 81)]:
        d.rectangle([x0, y0 + 1, x1, y1], fill=GOLD_D)
        d.rectangle([x0 + 2, y0 + 1, x1 - 2, y1], fill=RED)
        d.rectangle([x0 + 2, y0 + 1, x0 + 3, y1], fill=RED_L)
        d.rectangle([x1 - 3, y0 + 1, x1 - 2, y1], fill=RED_D)
    # --- the throne's back: a gilded frame round a tufted red panel
    d.polygon([(41, 36), (46, 22), (56, 14), (64, 6), (72, 14), (82, 22), (87, 36), (87, 96), (41, 96)], fill=OUT)
    d.polygon([(43, 36), (47, 24), (57, 16), (64, 9), (71, 16), (81, 24), (85, 36), (85, 94), (43, 94)], fill=GOLD)
    d.rectangle([43, 24, 45, 94], fill=GOLD_L)                          # the lit side of the frame
    d.rectangle([83, 30, 85, 94], fill=GOLD_D)
    d.polygon([(49, 38), (52, 28), (60, 21), (64, 17), (68, 21), (76, 28), (79, 38), (79, 90), (49, 90)], fill=OUT)
    d.polygon([(50, 38), (53, 29), (60, 22), (64, 19), (68, 22), (75, 29), (78, 38), (78, 89), (50, 89)], fill=RED)
    d.rectangle([50, 38, 52, 89], fill=RED_L)
    d.rectangle([76, 38, 78, 89], fill=RED_D)
    # tufting: a lattice of gold buttons
    for yy in range(34, 88, 9):
        for k, xx in enumerate(range(57, 78, 10)):
            ox = 5 if (yy // 9) % 2 else 0
            x = xx - ox
            if 52 <= x <= 76:
                d.point((x, yy), fill=GOLD_L)
                d.point((x + 1, yy + 1), fill=RED_D)
    # the crest: a gilded shell and a bead on the apex
    d.ellipse([57, 9, 71, 23], fill=OUT)
    d.ellipse([58, 10, 70, 22], fill=GOLD)
    d.ellipse([60, 12, 68, 20], fill=GOLD_D)
    d.point((63, 13), fill=GOLD_L)
    d.line([(64, 11), (64, 21)], fill=GOLD_L)
    for cx, cy in [(64, 5), (44, 36), (84, 36)]:
        d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=OUT)
        d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=GOLD)
        d.point((cx - 1, cy - 1), fill=GOLD_L)
    # --- armrests: gilded scrolls with red pads
    for x0, sign in ((34, -1), (85, 1)):
        d.rectangle([x0, 66, x0 + 9, 100], fill=OUT)
        d.rectangle([x0 + 1, 67, x0 + 8, 99], fill=GOLD)
        d.rectangle([x0 + 1, 67, x0 + 2, 99], fill=GOLD_L)
        d.rectangle([x0 + 7, 67, x0 + 8, 99], fill=GOLD_D)
        d.rectangle([x0 - 1, 60, x0 + 10, 68], fill=OUT)
        d.rectangle([x0, 61, x0 + 9, 67], fill=RED)
        d.rectangle([x0, 61, x0 + 9, 62], fill=RED_L)
        fx = x0 + 1 if sign < 0 else x0 + 3
        d.ellipse([fx - 1, 53, fx + 6, 60], fill=OUT)
        d.ellipse([fx, 54, fx + 5, 59], fill=GOLD)
        d.point((fx + 1, 55), fill=GOLD_L)
    # --- the seat: a deep red cushion in a gilded base, on carved legs
    d.rectangle([38, 88, 90, 104], fill=OUT)
    d.rectangle([39, 89, 89, 103], fill=GOLD)
    d.rectangle([39, 89, 89, 90], fill=GOLD_L)
    d.rectangle([39, 101, 89, 103], fill=GOLD_D)
    d.rectangle([44, 78, 84, 90], fill=OUT)
    d.rectangle([45, 79, 83, 89], fill=RED)
    d.rectangle([45, 79, 83, 81], fill=RED_L)
    d.rectangle([45, 87, 83, 89], fill=RED_D)
    for x in range(51, 80, 8):
        d.point((x, 84), fill=GOLD)
    for x0 in (40, 80):
        d.rectangle([x0, 103, x0 + 8, 108], fill=OUT)
        d.rectangle([x0 + 1, 103, x0 + 7, 107], fill=GOLD_D)
    return im


def standard_parts():
    """The pole, its foot and its finial: what the banners stand on."""
    pole, d = canvas(6, 8)
    d.rectangle([0, 0, 5, 7], fill=OUT)
    d.rectangle([1, 0, 4, 7], fill=GOLD)
    d.rectangle([1, 0, 1, 7], fill=GOLD_L)
    d.rectangle([4, 0, 4, 7], fill=GOLD_D)
    d.point((2, 3), fill=GOLD_L)
    foot, d = canvas(30, 12)
    d.ellipse([0, 4, 29, 11], fill=OUT)
    d.ellipse([1, 4, 28, 10], fill=GOLD_D)
    d.ellipse([3, 4, 26, 8], fill=GOLD)
    d.ellipse([6, 4, 22, 6], fill=GOLD_L)
    d.rectangle([11, 0, 18, 7], fill=OUT)
    d.rectangle([12, 0, 17, 7], fill=GOLD)
    d.rectangle([12, 0, 13, 7], fill=GOLD_L)
    d.rectangle([16, 0, 17, 7], fill=GOLD_D)
    fin, d = canvas(12, 16)
    d.ellipse([1, 5, 10, 14], fill=OUT)
    d.ellipse([2, 6, 9, 13], fill=GOLD)
    d.ellipse([3, 7, 6, 10], fill=GOLD_L)
    d.polygon([(6, 0), (9, 6), (3, 6)], fill=OUT)
    d.polygon([(6, 2), (8, 6), (4, 6)], fill=GOLD)
    d.rectangle([5, 14, 6, 15], fill=OUT)
    return pole, foot, fin


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
    pole, foot, fin = standard_parts()
    pole.save(os.path.join(root, 'pole_tile.png'))
    foot.save(os.path.join(root, 'standard_foot.png'))
    fin.save(os.path.join(root, 'finial.png'))
    carpet_tile().save(os.path.join(root, 'carpet_tile.png'))
    flame_frames().save(os.path.join('assets', 'visuals', 'pixel_fx', 'throne_flame.png'))
    print('throne room written')


if __name__ == '__main__':
    main()
