#!/usr/bin/env python3
"""Draws the Lantern Throne room of the Clans screen (v1.247, darkened v1.249, broken v1.250).

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
# the dark throne's own tones: old black stone, ember light, tarnished brass
B0 = (14, 10, 18, 255)
B1 = (30, 25, 38, 255)
B2 = (52, 45, 64, 255)
B3 = (88, 78, 104, 255)
B4 = (126, 114, 140, 255)
EMBER = (214, 78, 34, 255)
EMBER_L = (255, 150, 64, 255)
EMBER_D = (120, 32, 24, 255)
BRASS = (140, 108, 52, 255)
BRASS_L = (196, 160, 88, 255)
BRASS_D = (84, 62, 30, 255)
BONE = (186, 174, 148, 255)
WINE = (88, 18, 30, 255)
WINE_L = (126, 30, 42, 255)
WINE_D = (48, 10, 18, 255)


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
    """An old throne of black stone whose top has broken off: a cracked back
    with a ragged fracture, ember slits in its recess, a worn wine cushion,
    rubble on the steps. Nothing on it is sharp."""
    im, d = canvas(128, 144)
    # --- the dais: dark worn steps
    steps = [(104, 115, 22, 105), (116, 127, 14, 113), (128, 143, 6, 121)]
    for y0, y1, x0, x1 in steps:
        box(d, x0, y0, x1, y1, B1)
        d.rectangle([x0 + 1, y0 + 1, x1 - 1, y0 + 2], fill=B3)
        d.rectangle([x0 + 1, y0 + 3, x1 - 1, y0 + 4], fill=B2)
        d.rectangle([x0 + 1, y1 - 2, x1 - 1, y1 - 1], fill=B0)
        for x in range(x0 + 6, x1 - 4, 14):
            d.line([(x, y0 + 5), (x, y1 - 3)], fill=B0)
    for y0, y1, x0, x1 in [(104, 115, 52, 75), (116, 127, 49, 78), (128, 143, 46, 81)]:
        d.rectangle([x0, y0 + 1, x1, y1], fill=BRASS_D)
        d.rectangle([x0 + 2, y0 + 1, x1 - 2, y1], fill=WINE)
        d.rectangle([x0 + 2, y0 + 1, x0 + 3, y1], fill=WINE_L)
        d.rectangle([x1 - 3, y0 + 1, x1 - 2, y1], fill=WINE_D)
    # --- the shoulders either side: squat blocks, their tops worn flat
    d.polygon([(30, 100), (30, 62), (34, 58), (39, 60), (40, 66), (40, 100)], fill=OUT)
    d.polygon([(31, 99), (31, 63), (34, 59), (38, 61), (39, 67), (39, 99)], fill=B2)
    d.line([(32, 64), (32, 98)], fill=B3)
    d.polygon([(88, 100), (88, 52), (92, 50), (96, 56), (97, 100)], fill=OUT)
    d.polygon([(89, 99), (89, 53), (92, 51), (95, 57), (96, 99)], fill=B1)
    d.line([(95, 58), (95, 98)], fill=B0)
    # --- the back: a tall slab, the top of it gone in a ragged break
    outline = [(40, 96), (40, 52), (41, 40), (40, 30), (44, 24), (43, 18), (48, 15), (50, 20), (54, 17),
               (57, 24), (61, 22), (63, 30), (67, 28), (70, 35), (75, 33), (78, 40), (82, 38),
               (84, 46), (88, 50), (88, 96)]
    d.polygon(outline, fill=OUT)
    inner = [(x + (1 if x < 64 else -1), y + (1 if y < 96 else 0)) for x, y in outline]
    d.polygon(inner, fill=B1)
    # the old face of the stone: lit left, dark right
    d.rectangle([42, 42, 44, 96], fill=B2)
    d.rectangle([84, 52, 87, 96], fill=B0)
    # the fresh, pale edge of the break
    d.line([(41, 31), (45, 25), (44, 19), (48, 16), (50, 21), (54, 18), (57, 25), (61, 23)], fill=B4)
    d.line([(63, 31), (67, 29), (70, 36), (75, 34), (78, 41), (82, 39), (84, 47), (87, 51)], fill=B3)
    d.line([(41, 40), (41, 96)], fill=B3)
    # a recess cut deep, its top broken away with the rest
    d.polygon([(49, 92), (49, 46), (50, 36), (53, 29), (56, 31), (58, 26), (61, 28), (63, 34), (66, 33),
               (69, 38), (74, 38), (77, 44), (79, 50), (79, 92)], fill=B3)
    d.polygon([(50, 92), (50, 47), (51, 37), (53, 31), (56, 33), (58, 28), (61, 30), (63, 36), (66, 35),
               (69, 40), (74, 40), (77, 46), (78, 51), (78, 92)], fill=(9, 6, 13, 255))
    # ember slits glowing in the dark
    for x, top in ((57, 56), (64, 50), (71, 56)):
        d.rectangle([x - 1, top, x + 1, 88], fill=EMBER_D)
        d.line([(x, top + 2), (x, 86)], fill=EMBER)
        d.line([(x, top + 6), (x, top + 14)], fill=EMBER_L)
    # a worn brass ring with an ember in it, cracked across
    d.ellipse([57, 40, 71, 54], fill=OUT)
    d.ellipse([58, 41, 70, 53], fill=BRASS_D)
    d.ellipse([59, 42, 69, 52], fill=BRASS)
    d.ellipse([60, 43, 68, 51], fill=(9, 6, 13, 255))
    d.ellipse([62, 45, 66, 49], fill=EMBER)
    d.point((63, 46), fill=EMBER_L)
    d.rectangle([66, 40, 67, 44], fill=(9, 6, 13, 255))                 # a chip gone from the ring
    # cracks across the old stone
    for pts in ([(43, 62), (45, 68), (44, 74), (46, 82)], [(85, 56), (83, 64), (85, 70)],
                [(52, 58), (50, 62), (51, 67)], [(46, 34), (48, 40), (47, 46)]):
        d.line(pts, fill=B0)
    # --- armrests: rounded blocks of black stone, one chipped
    for x0 in (35, 83):
        d.rectangle([x0, 70, x0 + 10, 100], fill=OUT)
        d.rectangle([x0 + 1, 71, x0 + 9, 99], fill=B1)
        d.rectangle([x0 + 1, 71, x0 + 2, 99], fill=B3 if x0 < 64 else B2)
        d.rectangle([x0 + 8, 71, x0 + 9, 99], fill=B0)
        d.rectangle([x0 - 1, 66, x0 + 11, 72], fill=OUT)
        d.rectangle([x0, 67, x0 + 10, 71], fill=B2)
        d.rectangle([x0, 67, x0 + 10, 67], fill=B3)
        d.rectangle([x0 + 1, 84, x0 + 9, 85], fill=BRASS_D)
        d.point((x0 + 2, 84), fill=BRASS_L)
    d.rectangle([89, 66, 93, 69], fill=CLEAR)                           # the right arm chipped
    d.point((88, 70), fill=OUT)
    # --- the seat: a worn wine cushion on a banded stone base
    d.rectangle([38, 90, 90, 106], fill=OUT)
    d.rectangle([39, 91, 89, 105], fill=B1)
    d.rectangle([39, 91, 89, 92], fill=B3)
    d.rectangle([39, 99, 89, 99], fill=B0)
    d.rectangle([39, 102, 89, 103], fill=BRASS_D)
    for x in range(44, 88, 11):
        d.point((x, 95), fill=B3)
    d.rectangle([44, 79, 84, 91], fill=OUT)
    d.rectangle([45, 80, 83, 90], fill=WINE)
    d.rectangle([45, 80, 83, 81], fill=WINE_L)
    d.rectangle([45, 88, 83, 90], fill=WINE_D)
    for x in range(51, 80, 8):
        d.point((x, 85), fill=BRASS)
    # stout feet on the top step
    for x0 in (39, 81):
        d.rectangle([x0, 106, x0 + 9, 109], fill=OUT)
        d.rectangle([x0 + 1, 106, x0 + 8, 108], fill=B2)
    # --- rubble: what fell from the top lies on the steps and the seat
    def chunk(pts, fill=B2, lit=B3):
        d.polygon(pts, fill=OUT)
        inner = [(x + (1 if x < sum(p[0] for p in pts) / len(pts) else -1),
                  y + (1 if y < sum(p[1] for p in pts) / len(pts) else -1)) for x, y in pts]
        d.polygon(inner, fill=fill)
        d.point(inner[0], fill=lit)
    chunk([(25, 106), (33, 103), (36, 108), (29, 111)])
    chunk([(92, 108), (99, 105), (102, 110), (95, 112)], B1, B2)
    chunk([(16, 123), (24, 121), (26, 126), (18, 127)], B1, B2)
    chunk([(100, 121), (106, 118), (109, 123), (103, 125)])
    chunk([(66, 76), (73, 74), (76, 79), (69, 81)], B2, B3)         # on the cushion
    chunk([(54, 134), (60, 132), (63, 137), (57, 138)], B1, B2)     # on the carpet
    for x, y in ((38, 112), (86, 113), (30, 118), (108, 130), (12, 139), (118, 137), (46, 139)):
        d.point((x, y), fill=B2)
    return im


def standard_parts():
    """The pole, its foot and its finial: what the banners stand on, in black
    iron with tarnished brass."""
    pole, d = canvas(6, 8)
    d.rectangle([0, 0, 5, 7], fill=OUT)
    d.rectangle([1, 0, 4, 7], fill=B2)
    d.rectangle([1, 0, 1, 7], fill=B4)
    d.rectangle([4, 0, 4, 7], fill=B0)
    d.point((2, 3), fill=BRASS_L)
    foot, d = canvas(30, 12)
    d.ellipse([0, 4, 29, 11], fill=OUT)
    d.ellipse([1, 4, 28, 10], fill=B1)
    d.ellipse([3, 4, 26, 8], fill=B2)
    d.ellipse([6, 4, 22, 6], fill=B3)
    d.rectangle([11, 0, 18, 7], fill=OUT)
    d.rectangle([12, 0, 17, 7], fill=B2)
    d.rectangle([12, 0, 13, 7], fill=B4)
    d.rectangle([16, 0, 17, 7], fill=B0)
    d.rectangle([12, 3, 17, 4], fill=BRASS_D)
    fin, d = canvas(12, 16)
    d.ellipse([1, 5, 10, 14], fill=OUT)
    d.ellipse([2, 6, 9, 13], fill=BRASS)
    d.ellipse([3, 7, 6, 10], fill=BRASS_L)
    d.rectangle([3, 11, 9, 12], fill=BRASS_D)
    d.rectangle([4, 3, 7, 5], fill=OUT)
    d.rectangle([5, 4, 6, 5], fill=B2)
    d.rectangle([5, 14, 6, 15], fill=OUT)
    return pole, foot, fin


def brazier():
    im, d = canvas(24, 40)
    box(d, 9, 14, 14, 33, B1)                                           # the stem
    d.rectangle([10, 15, 11, 32], fill=B3)
    d.rectangle([9, 22, 14, 23], fill=BRASS_D)
    trapezoid(d, 6, 14, 3, 20, 7, 16, B2)                               # the bowl
    d.rectangle([3, 6, 20, 8], fill=BRASS)
    d.rectangle([4, 6, 8, 6], fill=BRASS_L)
    d.rectangle([5, 9, 18, 10], fill=B3)
    box(d, 5, 32, 18, 39, B1)                                           # the foot
    d.rectangle([6, 33, 17, 34], fill=B3)
    d.rectangle([6, 37, 17, 38], fill=B0)
    for x in (6, 9, 12, 15, 17):                                        # coals
        d.point((x, 5), fill=EMBER)
    return im


def flame_frames():
    """Six 24x24 frames in the lantern's own fire: core, flame, edge, ember."""
    tones = [(255, 214, 130, 255), (236, 120, 44, 255), (176, 52, 30, 255), (96, 24, 24, 255)]
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
    """36 wide: the carpet as it runs over the dais's lowest step, worn wine."""
    im, d = canvas(36, 16)
    d.rectangle([0, 0, 35, 15], fill=BRASS_D)
    d.rectangle([2, 0, 33, 15], fill=WINE)
    d.rectangle([2, 0, 3, 15], fill=WINE_L)
    d.rectangle([31, 0, 33, 15], fill=WINE_D)
    d.polygon([(18, 2), (24, 8), (18, 14), (12, 8)], fill=BRASS_D)
    d.polygon([(18, 4), (22, 8), (18, 12), (14, 8)], fill=WINE_D)
    d.point((18, 8), fill=BRASS_L)
    d.point((7, 8), fill=BRASS)
    d.point((28, 8), fill=BRASS)
    d.point((9, 3), fill=WINE_D)
    d.point((26, 12), fill=WINE_D)
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
