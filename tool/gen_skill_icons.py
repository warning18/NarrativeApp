#!/usr/bin/env python3
"""Draws the skill icons of the 20 skills added in 1.245 (assets/icons/skills).

Same make as the older gem icons: a 32x32 grid scaled x4, a dark outline, a
diamond gem in the skill's element colours, and a cream pictogram on it.
Run from the repo root:  python3 tool/gen_skill_icons.py [out_dir]
"""
import math
import os
import sys

from PIL import Image, ImageDraw

OUT = (10, 8, 7)
CREAM = (250, 242, 218)
SHADE = (24, 18, 28)

# element -> (dark, mid, light)
PAL = {
    'Fire': ((176, 68, 30), (222, 128, 60), (255, 200, 120)),
    'Water': ((52, 92, 150), (104, 150, 199), (176, 232, 255)),
    'Ice': ((70, 130, 170), (150, 210, 235), (230, 250, 255)),
    'Wind': ((60, 140, 110), (130, 206, 170), (220, 255, 230)),
    'Earth': ((100, 76, 44), (150, 112, 72), (214, 176, 110)),
    'Electricity': ((150, 118, 30), (214, 176, 50), (255, 240, 150)),
    'Light': ((190, 150, 40), (240, 212, 72), (255, 250, 200)),
}


def gem(el):
    """The element's diamond on a 32x32 canvas."""
    dark, mid, light = PAL[el]
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    def diamond(r, color):
        d.polygon([(16, 16 - r), (16 + r, 16), (16, 16 + r), (16 - r, 16)],
                  fill=color)

    diamond(15, OUT)
    diamond(14, dark)
    diamond(12, mid)
    # a lit upper-left rim
    d.polygon([(16, 5), (5, 16), (8, 16), (16, 8)], fill=light)
    return im


def glyph(name):
    """A 16x16 cream pictogram on transparent."""
    im = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = CREAM + (255,)

    def line(a, b, w=1):
        d.line([a, b], fill=c, width=w)

    def poly(pts):
        d.polygon(pts, fill=c)

    def dots(*pts):
        for p in pts:
            d.point(p, fill=c)

    def bolt(ox=0, oy=0, s=1.0):
        pts = [(9, 0), (3, 8), (7, 8), (5, 15), (12, 6), (8, 6), (11, 0)]
        poly([(int(ox + x * s), int(oy + y * s)) for x, y in pts])

    def cloud(y=4, w=14):
        x0 = (16 - w) // 2
        d.ellipse([x0 + 1, y - 1, x0 + 7, y + 5], fill=c)
        d.ellipse([x0 + 4, y - 4, x0 + 11, y + 3], fill=c)
        d.ellipse([x0 + w - 8, y - 1, x0 + w - 1, y + 5], fill=c)
        d.rectangle([x0 + 3, y + 1, x0 + w - 3, y + 5], fill=c)

    def shield():
        poly([(3, 2), (13, 2), (13, 9), (8, 15), (3, 9)])

    if name == 'mage_rime_lance':
        line((2, 14), (11, 5), 2)
        poly([(10, 6), (15, 0), (14, 4), (15, 5)])
        poly([(11, 5), (14, 1), (10, 3)])
        dots((2, 6), (4, 3), (13, 12), (10, 14))
        line((5, 1), (5, 5))
        line((3, 3), (7, 3))
    elif name == 'mage_glacial_ward':
        shield()
        # a snowflake cut into the shield, in the shade colour
        for a in range(0, 180, 60):
            r = math.radians(a)
            d.line([(8 - 4 * math.cos(r), 7 - 4 * math.sin(r)),
                    (8 + 4 * math.cos(r), 7 + 4 * math.sin(r))],
                   fill=(0, 0, 0, 0), width=1)
    elif name == 'mage_chain_lightning':
        bolt(0, 0, 0.95)
        bolt(9, 8, 0.5)
        dots((8, 11), (10, 10))
    elif name == 'mage_static_charge':
        bolt(2, 0, 0.9)
        dots((1, 3), (14, 2), (1, 12), (14, 13), (0, 7), (15, 8))
    elif name == 'mage_thunderclap':
        cloud(3, 14)
        poly([(9, 7), (5, 12), (8, 12), (6, 16), (11, 10), (8, 10), (10, 7)])
    elif name == 'mage_stormcaller':
        cloud(2, 16)
        for ox in (0, 5, 10):
            poly([(ox + 3, 7), (ox + 1, 10), (ox + 3, 10), (ox + 2, 14),
                  (ox + 5, 9), (ox + 3, 9), (ox + 4, 7)])
    elif name == 'cleric_tidal_wash':
        for y in (4, 8, 12):
            pts = [(x, y + round(1.6 * math.sin(x / 2.0 + y))) for x in range(1, 15)]
            d.line(pts, fill=c, width=2)
        dots((13, 1), (14, 2))
    elif name == 'cleric_undertow':
        pts = []
        for t in range(0, 40):
            a = t / 40 * 3.2 * math.pi
            r = 6.5 - t * 0.14
            pts.append((8 + r * math.cos(a), 8 + r * math.sin(a)))
        d.line(pts, fill=c, width=2)
        poly([(13, 12), (15, 15), (10, 15)])
    elif name == 'cleric_dawn_lance':
        line((8, 15), (8, 4), 2)
        poly([(8, 0), (5, 5), (11, 5)])
        for a in (-50, 50):
            r = math.radians(a)
            line((8, 6), (8 + 7 * math.sin(r), 6 - 5 * math.cos(r)))
        dots((2, 12), (14, 12))
    elif name == 'cleric_lantern_ward':
        d.rectangle([5, 1, 10, 2], fill=c)
        d.rectangle([4, 4, 11, 13], fill=c)
        d.rectangle([6, 6, 9, 11], fill=(0, 0, 0, 0))
        d.rectangle([7, 7, 8, 10], fill=c)
        d.rectangle([5, 14, 10, 15], fill=c)
        line((6, 0), (9, 0))
    elif name == 'cleric_winter_hush':
        for a in range(0, 180, 60):
            r = math.radians(a)
            d.line([(8 - 7 * math.cos(r), 8 - 7 * math.sin(r)),
                    (8 + 7 * math.cos(r), 8 + 7 * math.sin(r))],
                   fill=c, width=1)
        for a in range(0, 360, 60):
            r = math.radians(a)
            for k in (3, 5):
                px, py = 8 + k * math.cos(r), 8 + k * math.sin(r)
                nx, ny = -math.sin(r), math.cos(r)
                d.line([(px - nx * 1.5, py - ny * 1.5),
                        (px + nx * 1.5, py + ny * 1.5)], fill=c)
        d.rectangle([7, 7, 8, 8], fill=c)
    elif name == 'cleric_second_dawn':
        d.pieslice([2, 6, 14, 18], 180, 360, fill=c)
        d.rectangle([0, 12, 15, 13], fill=c)
        for a in range(-70, 71, 35):
            r = math.radians(a)
            line((8 + 6 * math.sin(r), 5 - 5 * math.cos(r) + 4),
                 (8 + 9 * math.sin(r), 5 - 8 * math.cos(r) + 4))
    elif name == 'rogue_gale_cut':
        line((1, 12), (13, 2), 2)
        line((3, 15), (15, 6), 2)
        poly([(13, 2), (15, 0), (14, 4)])
        dots((1, 4), (2, 3), (3, 3), (5, 6))
    elif name == 'rogue_dust_devil':
        for y, (x0, x1) in enumerate([(1, 14), (3, 13), (4, 12), (5, 11),
                                       (6, 10), (7, 9)]):
            if y % 2 == 0:
                line((x0, y * 2 + 1), (x1, y * 2 + 1), 2)
        dots((12, 14), (13, 13), (3, 14))
        line((6, 13), (9, 14))
    elif name == 'ranger_rain_of_arrows':
        for ox in (-3, 1, 5):
            line((ox + 4, 0), (ox + 9, 11))
            poly([(ox + 9, 14), (ox + 7, 10), (ox + 11, 10)])
            dots((ox + 4, 0), (ox + 3, 1), (ox + 5, 1))
    elif name == 'ranger_hawk_mark':
        d.ellipse([2, 2, 13, 13], outline=c, width=2)
        for a in (0, 90, 180, 270):
            r = math.radians(a)
            line((8 + 4 * math.cos(r), 8 + 4 * math.sin(r)),
                 (8 + 8 * math.cos(r), 8 + 8 * math.sin(r)))
        d.rectangle([7, 7, 8, 8], fill=c)
    elif name == 'ranger_windwalker':
        for y, w in ((3, 13), (8, 15), (13, 11)):
            line((1, y), (w, y))
            dots((w + 1, y - 1) if w < 15 else (14, y - 1), (w, y - 2))
        poly([(10, 5), (15, 8), (10, 11)])
    elif name == 'warrior_rockfall':
        poly([(2, 1), (7, 0), (8, 5), (3, 6)])
        poly([(9, 5), (14, 4), (15, 9), (10, 10)])
        poly([(3, 9), (8, 8), (9, 14), (2, 14)])
        dots((13, 13), (12, 14))
    elif name == 'warrior_bastion_slam':
        d.rectangle([3, 3, 12, 11], fill=c)
        d.rectangle([5, 5, 10, 9], fill=(0, 0, 0, 0))
        d.rectangle([6, 6, 9, 8], fill=c)
        for a in range(0, 360, 45):
            r = math.radians(a)
            line((8 + 7 * math.cos(r), 7 + 6 * math.sin(r)),
                 (8 + 8 * math.cos(r), 7 + 7 * math.sin(r)))
        d.rectangle([2, 13, 13, 15], fill=c)
    elif name == 'warrior_thornwall':
        for y in (7, 10, 13):
            d.rectangle([1, y, 14, y + 1], fill=c)
        for x in (3, 7, 11):
            d.line([(x, 7), (x, 6)], fill=(0, 0, 0, 0))
        for x in (2, 6, 10, 14):
            poly([(x - 1, 6), (x, 1), (x + 1, 6)])
    else:
        raise KeyError(name)
    return im


ICONS = {
    'mage_rime_lance': 'Ice',
    'mage_glacial_ward': 'Ice',
    'mage_chain_lightning': 'Electricity',
    'mage_static_charge': 'Electricity',
    'mage_thunderclap': 'Electricity',
    'mage_stormcaller': 'Electricity',
    'cleric_tidal_wash': 'Water',
    'cleric_undertow': 'Water',
    'cleric_dawn_lance': 'Light',
    'cleric_lantern_ward': 'Light',
    'cleric_winter_hush': 'Ice',
    'cleric_second_dawn': 'Light',
    'rogue_gale_cut': 'Wind',
    'rogue_dust_devil': 'Wind',
    'ranger_rain_of_arrows': 'Wind',
    'ranger_hawk_mark': 'Wind',
    'ranger_windwalker': 'Wind',
    'warrior_rockfall': 'Earth',
    'warrior_bastion_slam': 'Earth',
    'warrior_thornwall': 'Earth',
}


def icon(name, el):
    base = gem(el)
    g = glyph(name)
    # The pictogram is cream with a dark shadow a pixel down-right; on the
    # pale gems (light, lightning, wind) it is dark with a cream shadow.
    alpha = g.getchannel('A')
    pale = el in ('Light', 'Electricity', 'Wind')
    ink = (46, 30, 14, 255) if pale else CREAM + (255,)
    cast = (255, 250, 220, 255) if pale else SHADE + (255,)
    shadow = Image.new('RGBA', (16, 16), cast)
    shadow.putalpha(alpha)
    body = Image.new('RGBA', (16, 16), ink)
    body.putalpha(alpha)
    base.alpha_composite(shadow, (9, 9))
    base.alpha_composite(body, (8, 8))
    return base.resize((128, 128), Image.NEAREST)


def main(out):
    os.makedirs(out, exist_ok=True)
    for name, el in ICONS.items():
        icon(name, el).save(os.path.join(out, name + '.png'))
    print(len(ICONS), 'icons ->', out)


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'assets/icons/skills')
