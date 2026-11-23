"""B ("ink and one colour"): today's sprites, Art's style-1 dice and ground, brought
into the five greys of art/pixellab-styles (090A14 202E37 394A50 8B9BA0 EBEDE9).
Sprites are mapped by luminance percentile (so each keeps its detail) and get one
pixel of ink round them; the style-1 red and gold are folded into the greys: the
accent colour belongs to the UI (your turn, the aimed foe, a x3 weakness, health).

Run from the repo root:  python3 docs/ux-shots/fight-proposals/make_b_assets.py
Needs Pillow, and /tmp/style1/ filled from origin/claude/art-npc-export
(art/pixellab-styles/final/style1_{d6,d12,combat}.png).
"""
from PIL import Image, ImageFilter
import os

INK, G1, G2, G3, PAPER = [(0x09, 0x0A, 0x14), (0x20, 0x2E, 0x37), (0x39, 0x4A, 0x50),
                          (0x8B, 0x9B, 0xA0), (0xEB, 0xED, 0xE9)]
OUT = 'docs/ux-shots/fight-proposals/b-assets'
os.makedirs(OUT, exist_ok=True)


def lum(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def to_greys(path, cuts=(0.18, 0.42, 0.72, 0.93), outline=True, scale=1):
    im = Image.open(path).convert('RGBA')
    px = list(im.getdata())
    ls = sorted(lum(p) for p in px if p[3] > 0)
    if not ls:
        return im
    th = [ls[min(len(ls) - 1, int(c * len(ls)))] for c in cuts]
    pal = [INK, G1, G2, G3, PAPER]
    out = []
    for p in px:
        if p[3] == 0:
            out.append((0, 0, 0, 0))
            continue
        l = lum(p)
        i = sum(l > t for t in th)
        out.append(pal[i] + (255,))
    res = Image.new('RGBA', im.size)
    res.putdata(out)
    if outline:
        pad = Image.new('RGBA', (im.width + 2, im.height + 2), (0, 0, 0, 0))
        pad.paste(res, (1, 1))
        a = pad.split()[3]
        grown = a.filter(ImageFilter.MaxFilter(3))
        ring = Image.new('RGBA', pad.size, INK + (255,))
        ring.putalpha(grown)
        ring.alpha_composite(pad)
        res = ring
    if scale != 1:
        res = res.resize((res.width * scale, res.height * scale), Image.NEAREST)
    return res


def fold_accent(path, keep_ink=True):
    """Art's own style-1 piece with its red and gold folded into greys."""
    im = Image.open(path).convert('RGBA')
    out = []
    for p in im.getdata():
        if p[3] == 0:
            out.append(p)
            continue
        r, g, b = p[:3]
        if r > 140 and g < 90 and b < 90:      # blood red A53030
            out.append(G2 + (255,))
        elif r > 200 and g > 150 and b < 120:  # gold F2C14E
            out.append(G3 + (255,))
        else:
            out.append(p)
    res = Image.new('RGBA', im.size)
    res.putdata(out)
    return res


foes = {'void_sovereign': 'assets/visuals/fighters/void_sovereign_idle_west.png',
        'inquisition_warden': 'assets/visuals/fighters/inquisition_warden_idle_west.png',
        'white_soldier': 'assets/visuals/fighters/white_soldier_idle_west.png'}
heroes = {'warrior': 'assets/visuals/heroes/warrior_stand_east.png',
          'cleric': 'assets/visuals/heroes/cleric_stand_east.png',
          'mage': 'assets/visuals/heroes/mage_stand_east.png'}
for name, path in {**foes, **heroes}.items():
    to_greys(path).save(f'{OUT}/{name}.png')
fold_accent('/tmp/style1/style1_d6.png').save(f'{OUT}/die_d6.png')
fold_accent('/tmp/style1/style1_d12.png').save(f'{OUT}/die_d12.png')
fold_accent('/tmp/style1/style1_combat.png').save(f'{OUT}/ground.png')
print('ok', sorted(os.listdir(OUT)))
