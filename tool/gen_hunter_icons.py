#!/usr/bin/env python3
"""Draws the six rival hunters' icons (v1.384, from Narrative's looks in
docs/proposals/rival-hunters.md): 16x16 sprites in the enemy icons' style
(flat tones, a near-black outline), written at 128x128 (x8, no smoothing) to
assets/icons/enemies/<id>.png.

Each sprite is drawn as its inside only; the outline is added around it.
Run from the repo root:  python3 tool/gen_hunter_icons.py
"""
import os

from PIL import Image

OUT = (10, 8, 7, 255)


def rgb(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


SKIN = '#e2b894'
SKIN_D = '#b88a68'
EYE = '#1e1816'

SPRITES = {}

# Halvard, Spearman of the Last Watch: a steel cap, a long grey cloak, a
# spear in the right hand.
SPRITES['vigil_spearman_halvard'] = (
    {
        'H': '#8c929e', 'h': '#b4bac6', 'G': '#606672', 'L': '#828896',
        'S': SKIN, 'K': EYE, 'W': '#8c643c', 'T': '#dce2ec', 'B': '#3c2c20',
        'Y': '#c8b060',
    },
    [
        "................",
        ".............T..",
        "......hHHh...T..",
        ".....HHHHHH..W..",
        ".....HSSSSH..W..",
        ".....SKSSKS..W..",
        "......SSSS...W..",
        "....GGGGGGGG.W..",
        "...GGLGGGGLGSW..",
        "...GGLGGYYLGSW..",
        "...GGLGGGGLGGW..",
        "....GLGGGGLG.W..",
        "....GGGGGGGG.W..",
        "....GGG..GGG.W..",
        "....BBB..BBB.W..",
        "................",
    ],
)

# Ysel, Candlebearer: a hooded grey-blue robe, a lantern in the left hand,
# a notched tally-stick in the right.
SPRITES['vigil_candlebearer_ysel'] = (
    {
        'H': '#767a96', 'R': '#a8abc4', 'D': '#8184a0', 'S': SKIN,
        'K': EYE, 'Y': '#ffd666', 'O': '#e8964a', 'M': '#6e5a3a',
        'W': '#966c40', 'N': '#46301c', 'B': '#3c2c3a',
    },
    [
        "................",
        ".....HHHH.......",
        "....HHHHHH......",
        "....HSSSSH...W..",
        "....HKSSKH...N..",
        "....HSSSSH...W..",
        "...RRRRRRRR..N..",
        "..RRDRRRRDRRSW..",
        "..SRDRRRRDRR.N..",
        ".MMMRRRRRRRR.W..",
        ".OYORRDRRDRR.N..",
        ".OYORRRRRRRR.W..",
        ".MMM.RRRRRR.....",
        ".....RRDDRR.....",
        ".....BB..BB.....",
        "................",
    ],
)

# Brodin Stonehand, Quarryman: broad and brown, stone dust on the sleeves,
# a great hammer on the right.
SPRITES['compact_quarryman_brodin'] = (
    {
        'C': '#5e4022', 'c': '#7c5c40', 'D': '#402004', 'S': SKIN,
        'K': EYE, 'Z': '#9a968c', 'z': '#c8c4ba', 'I': '#5a554e',
        'W': '#8c643c', 'B': '#2a1c10', 'E': '#46321e',
    },
    [
        "................",
        "......EEEE......",
        ".....EEEEEE.III.",
        ".....ESSSSE.IZI.",
        ".....SKSSKS.IZI.",
        ".....SSDDSS.III.",
        "...cccccccc..W..",
        "..ZCCCCCCCCZ.W..",
        ".zZCCCCCCCCZSW..",
        ".zZCCDDDDCCZ.W..",
        "..SCCCCCCCC..W..",
        "....CCCCCC...W..",
        "....CC..CC...W..",
        "....CC..CC......",
        "....BB..BB......",
        "................",
    ],
)

# Tove the Unheard, of the Anvil-Deaf: grey hair, bare forearms raised in
# a sign, a smith's leather apron.
SPRITES['compact_anvil_deaf_tove'] = (
    {
        'G': '#b8b4b0', 'g': '#dcd8d4', 'S': SKIN, 's': SKIN_D,
        'K': EYE, 'A': '#4a3220', 'a': '#6a4a30', 'R': '#8a3c2a',
        'D': '#323038', 'B': '#2a1c10', 'M': '#7a7a84',
    },
    [
        "................",
        "......gGGg......",
        ".....GGGGGG.....",
        ".....GSSSSG.....",
        ".....SKSSKS.....",
        ".....SSsSSS.....",
        "....RRSSSSRR....",
        "..SSRAAaaAARSS..",
        "..SSSAAAAAASSS..",
        "...S.AAMMAA.S...",
        ".....AAAAAA.....",
        ".....AAAAAA.....",
        ".....DD..DD.....",
        ".....DD..DD.....",
        ".....BB..BB.....",
        "................",
    ],
)

# Sedge of the Returned: a mask of woven reeds over the face, a wrap of
# dark marsh green.
SPRITES['mire_returned_sedge'] = (
    {
        'R': '#c8c070', 'r': '#e4dc98', 'q': '#8c8444', 'G': '#3c5a3c',
        'g': '#52743e', 'D': '#26382a', 'K': '#161c14', 'V': '#7a9a62',
        'B': '#1c241a', 'P': '#8a8a7a',
    },
    [
        "................",
        "....r.r.r.r.....",
        ".....RrRrRR.....",
        "....RRRRRRRR....",
        "....RKRRRRKR....",
        "....qRRRRRRq....",
        ".....qRqRRq.....",
        "....DGGGGGGD....",
        "...DGgGGGGgGD...",
        "..PDGgGDDGgGDP..",
        "..P.GGGDDGGG.P..",
        "....GgGGGGgG....",
        "....DGG..GGD....",
        "....DGG..GGD....",
        "....BBB..BBB....",
        "................",
    ],
)

# Wen of the Heron's Wake: a wide hat, a teal cloak, a pole with a hanging
# lantern in the right hand.
SPRITES['mire_herons_wake_wen'] = (
    {
        'T': '#3c7a78', 't': '#58a09a', 'U': '#27504e', 'S': SKIN,
        'K': EYE, 'H': '#8a7a50', 'h': '#b4a270', 'W': '#8c643c',
        'Y': '#ffd666', 'O': '#e8964a', 'M': '#6e5a3a', 'B': '#1c241a',
    },
    [
        "................",
        "......hh......MM",
        "....hHHHHh...MYM",
        "...hHHHHHHh..OYO",
        ".....SSSSS...MMM",
        ".....SKSKS...W..",
        ".....SSSSS...W..",
        "....TTTTTTT..W..",
        "...TTtTTTtTTSW..",
        "...TTtTTTtTTSW..",
        "...TTtTUUtTTSW..",
        "....TTTTTTT..W..",
        "....TTTTTTT..W..",
        "....TT...TT..W..",
        "....BB...BB..W..",
        "................",
    ],
)


def render(palette, rows):
    assert len(rows) == 16, len(rows)
    for row in rows:
        assert len(row) == 16, (len(row), row)
    colours = {k: rgb(v) for k, v in palette.items()}
    px = [[None] * 16 for _ in range(16)]
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != '.':
                px[y][x] = colours[ch]
    out = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    o = out.load()
    for y in range(16):
        for x in range(16):
            if px[y][x] is not None:
                o[x, y] = px[y][x]
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < 16 and 0 <= ny < 16 and px[ny][nx] is not None:
                    o[x, y] = OUT
                    break
    return out


def main():
    folder = os.path.join('assets', 'icons', 'enemies')
    sheet = Image.new('RGBA', (3 * 136 + 8, 2 * 136 + 8), (40, 36, 48, 255))
    for i, (enemy_id, (palette, rows)) in enumerate(SPRITES.items()):
        small = render(palette, rows)
        big = small.resize((128, 128), Image.NEAREST)
        big.save(os.path.join(folder, f'{enemy_id}.png'))
        sheet.paste(big, (4 + (i % 3) * 136, 4 + (i // 3) * 136), big)
    sheet.save('/tmp/hunter_sheet.png')


if __name__ == '__main__':
    main()
