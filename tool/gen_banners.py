#!/usr/bin/env python3
"""Draws the game's banners as pixel art.

    python3 tool/gen_banners.py [contact-sheet.png]

One 48x96 PNG per banner in assets/visuals/banners/: the six pieces of the
Shroud (named by their ids), the title's standard and the twelve clans'
main banners (clan_<faction id>). After the bold poster lettering of the
Japanese type studios: a black woven cloth, cream strokes of one weight with
rounded ends, built from circles, bars and arcs, two signs to a banner
stacked the way vertical writing is, and one round disc of colour laid
across them. The cloth has its folds, a header band and stitched hem in
the banner's colour, a bevel on every stroke, a shaded disc, a turned pole
with its rings and finials, and tassels at the tail. No antialiasing, a
handful of flat colours; shown by PixelBanner (lib/widgets/pixel_banner.dart)
at a whole-number scale.
"""
import json
import math
import os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'assets', 'visuals', 'banners')
FACTIONS = os.path.join(HERE, '..', 'assets', 'gamedata', 'factions.json')
os.makedirs(OUT, exist_ok=True)

W, H = 48, 96
CL, CR = 7, 40                    # the cloth's first and last column
CT, CB = 8, 80                    # its top row, and the last row of the body
TAIL = 10                         # the swallow-tail's depth below CB
MID = (CL + CR) / 2
STROKE = 3

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def rgb(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3)) + (255,)


def shade(c, t):
    return mix(c, rgb('#0B0908'), t)


def light(c, t):
    return mix(c, rgb('#FFF6DC'), t)


OUTLINE = rgb('#0B0908')
INK = rgb('#16120F')        # the cloth
WEAVE = rgb('#1D1814')      # its threads
SHEEN = rgb('#262019')      # light caught on a fold
FOLD = rgb('#0F0C0A')       # the shade between folds
EDGE = rgb('#5A4C3B')       # stitching
CREAM = rgb('#F1E7CB')
CREAM_SHADE = rgb('#A99C7C')
CREAM_HI = rgb('#FFFDF2')
POLE = rgb('#8A6B43')
POLE_LIGHT = rgb('#B58F5A')
POLE_DARK = rgb('#5A432A')
BRASS = rgb('#D8B04C')
BRASS_DARK = rgb('#8F6E24')
RED = rgb('#D9432F')
ORANGE = rgb('#EA8A2C')
YELLOW = rgb('#F1C73C')
GREEN = rgb('#7E9A3C')
CLEAR = (0, 0, 0, 0)


class Pen:
    """Strokes of one weight with round ends, on an image, in colour [c] and
    shifted by (ox, oy)."""

    def __init__(self, im, c=CREAM):
        self.im = im
        self.d = ImageDraw.Draw(im)
        self.c = c
        self.ox = 0
        self.oy = 0

    def disc(self, cx, cy, r, c=None):
        c = c or self.c
        cx += self.ox
        cy += self.oy
        self.d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c)

    def ring(self, cx, cy, r, w=STROKE):
        cx += self.ox
        cy += self.oy
        self.d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=self.c, width=w)

    def line(self, x0, y0, x1, y1, w=STROKE, c=None):
        c = c or self.c
        x0 += self.ox
        x1 += self.ox
        y0 += self.oy
        y1 += self.oy
        self.d.line([x0, y0, x1, y1], fill=c, width=w)
        if w > 2:
            r = (w - 1) / 2
            for x, y in ((x0, y0), (x1, y1)):
                self.d.ellipse([x - r, y - r, x + r, y + r], fill=c)

    def arc(self, cx, cy, r, a0, a1, w=STROKE):
        cx += self.ox
        cy += self.oy
        self.d.arc([cx - r, cy - r, cx + r, cy + r], a0, a1, fill=self.c, width=w)
        rr = (w - 1) / 2
        for a in (a0, a1):
            x = cx + (r - rr) * math.cos(math.radians(a))
            y = cy + (r - rr) * math.sin(math.radians(a))
            self.d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=self.c)

    def box(self, x0, y0, x1, y1, c=None):
        self.d.rectangle([x0 + self.ox, y0 + self.oy, x1 + self.ox, y1 + self.oy],
                         fill=c or self.c)

    def mask(self, cx, cy, half, inside):
        """Pixels of the square around (cx, cy) where inside(x, y) holds,
        x and y measured from the centre."""
        for y in range(-half, half + 1):
            for x in range(-half, half + 1):
                if inside(x, y):
                    self.im.putpixel((cx + x + self.ox, cy + y + self.oy), self.c)

    def poly(self, pts, c=None):
        self.d.polygon([(x + self.ox, y + self.oy) for x, y in pts], fill=c or self.c)


# --- the signs: each in a 22 px square around (cx, cy) ----------------------------

def sign_roof(p, cx, cy, s=11):
    """A dome over a post and a sill."""
    p.arc(cx, cy + 1, s, 180, 360)
    p.line(cx, cy + 1 - s, cx, cy + s)
    p.line(cx - s, cy + s, cx + s, cy + s)


def sign_ring(p, cx, cy, s=11):
    """A ring, a kernel in it."""
    p.ring(cx, cy, s)
    p.disc(cx, cy, 2)


def sign_crescent(p, cx, cy, s=11):
    """The moon, cut from a disc."""
    p.mask(cx, cy, s + 1, lambda x, y: (x + 1) ** 2 + y ** 2 <= s * s + 1 and
           (x - 5) ** 2 + (y + 2) ** 2 > (s - 2) ** 2)

def sign_shard(p, cx, cy, s=11):
    """A splinter: a leaning triangle."""
    p.line(cx - 8, cy + s, cx + 3, cy - s)
    p.line(cx + 3, cy - s, cx + 9, cy + s)
    p.line(cx - 8, cy + s, cx + 9, cy + s)


def sign_gate(p, cx, cy, s=11):
    """Two posts, a lintel, a bar between."""
    p.line(cx - s + 1, cy - s, cx - s + 1, cy + s)
    p.line(cx + s - 1, cy - s, cx + s - 1, cy + s)
    p.line(cx - s + 1, cy - s, cx + s - 1, cy - s)
    p.line(cx - s + 1, cy + 1, cx + s - 1, cy + 1)


def sign_tower(p, cx, cy, s=11):
    """Three bars on a post."""
    p.line(cx, cy - s, cx, cy + s)
    p.line(cx - 4, cy - s, cx + 4, cy - s)
    p.line(cx - 7, cy, cx + 7, cy)
    p.line(cx - s, cy + s, cx + s, cy + s)


def sign_thread(p, cx, cy, s=11):
    """A thread's S: two half-rings."""
    r = s // 2
    p.arc(cx, cy - r, r + 1, 90, 360)
    p.arc(cx, cy + r, r + 1, 270, 540)


def sign_cross(p, cx, cy, s=11):
    """The reliquary's cross."""
    p.line(cx, cy - s, cx, cy + s)
    p.line(cx - s, cy, cx + s, cy)


def sign_sail(p, cx, cy, s=11):
    """A sail on its mast."""
    p.line(cx - 3, cy - s, cx - 3, cy + s)
    p.line(cx - 3, cy - s + 1, cx + 9, cy + s - 3)
    p.line(cx - 3, cy + s - 3, cx + 9, cy + s - 3)


def sign_waves(p, cx, cy, s=11):
    """Two swells."""
    for dy in (-5, 5):
        p.arc(cx - 5, cy + dy, 5, 180, 360)
        p.arc(cx + 5, cy + dy, 5, 0, 180)


def sign_crown(p, cx, cy, s=11):
    """Three posts on a band, a bead on each."""
    p.line(cx - s + 1, cy + s - 1, cx + s - 1, cy + s - 1)
    for dx in (-s + 1, 0, s - 1):
        p.line(cx + dx, cy - 3, cx + dx, cy + s - 1)
        p.disc(cx + dx, cy - s + 2, 2)


def sign_eye(p, cx, cy, s=11):
    """The torn eye: an almond, a pupil, a slash through it."""
    p.arc(cx, cy + 6, s + 2, 215, 325)
    p.arc(cx, cy - 6, s + 2, 35, 145)
    p.disc(cx, cy, 3)
    p.line(cx + 6, cy - s - 1, cx - 6, cy + s + 1, 1, INK)


def sign_lantern(p, cx, cy, s=11):
    """A lantern: a hanging arc, a frame, a flame within."""
    p.arc(cx, cy - s + 5, 5, 180, 360)
    p.line(cx - 7, cy - 4, cx + 7, cy - 4)
    p.line(cx - 7, cy + s, cx + 7, cy + s)
    p.line(cx - 7, cy - 4, cx - 7, cy + s)
    p.line(cx + 7, cy - 4, cx + 7, cy + s)
    p.disc(cx, cy + 3, 2)


def sign_anvil(p, cx, cy, s=11):
    """An anvil: a long face with its horn, a waist, a foot."""
    p.box(cx - 11, cy - 8, cx + 4, cy - 3)
    p.poly([(cx + 4, cy - 8), (cx + 11, cy - 3), (cx + 4, cy - 3)])
    p.box(cx - 6, cy - 2, cx + 0, cy + 5)
    p.box(cx - 10, cy + 6, cx + 4, cy + 10)

def sign_hammer(p, cx, cy, s=11):
    """A hammer: a haft and a heavy head."""
    p.line(cx, cy - 4, cx, cy + s)
    p.line(cx - 8, cy - s + 2, cx + 8, cy - s + 2, 5)


def sign_leaf(p, cx, cy, s=11):
    """A leaf: a pointed lens on a slant, a rib cut in it, a stem."""
    def inside(x, y):
        # rotate 45 degrees: u along the leaf, v across it
        u = (x - y) / 1.414
        v = (x + y) / 1.414
        return abs(u) <= 11 and abs(v) <= 6.2 * (1 - (u / 11) ** 2) ** 0.7
    p.mask(cx, cy, s + 1, inside)
    p.line(cx - 9, cy + 9, cx - 4, cy + 4, 1, INK)
    p.line(cx - 5, cy + 5, cx + 6, cy - 6, 1, INK)

def sign_anchor(p, cx, cy, s=11):
    """An anchor: ring, shank, stock, flukes."""
    p.ring(cx, cy - s + 3, 3, 2)
    p.line(cx, cy - s + 6, cx, cy + s)
    p.line(cx - 6, cy - 3, cx + 6, cy - 3)
    p.arc(cx, cy + 1, 10, 20, 160)


def sign_coin(p, cx, cy, s=11):
    """A coin with a square hole."""
    p.ring(cx, cy, s)
    p.box(cx - 2, cy - 2, cx + 2, cy + 2)


def sign_flame(p, cx, cy, s=11):
    """A flame: a drop with a tongue, a core cut from it."""
    def inside(x, y):
        if x * x + (y - 3) ** 2 <= 8 * 8 + 4:
            return True
        # the tongue: a leaning triangle over the drop
        if -s <= y <= 2:
            lean = (y + s) / (2 + s) * 7 - 1
            return abs(x - (4 - (y + s) * 0.35)) <= lean
        return False
    p.mask(cx, cy, s + 1, inside)
    p.mask(cx, cy, s + 1, lambda x, y: False)
    p.disc(cx, cy + 5, 3, INK)
    p.disc(cx, cy + 6, 1, CREAM)

def sign_sun(p, cx, cy, s=11):
    """A sun: a disc and eight rays."""
    p.disc(cx, cy, 4)
    for a in range(0, 360, 45):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        p.line(cx + ca * 7, cy + sa * 7, cx + ca * (s + 1), cy + sa * (s + 1))


def sign_pit(p, cx, cy, s=11):
    """The pit: bars narrowing downward."""
    p.line(cx - s, cy - 8, cx + s, cy - 8)
    p.line(cx - 7, cy, cx + 7, cy)
    p.line(cx - 3, cy + 8, cx + 3, cy + 8)


def sign_mountain(p, cx, cy, s=11):
    """Two peaks."""
    p.line(cx - s, cy + s, cx - 4, cy - s + 2)
    p.line(cx - 4, cy - s + 2, cx + 2, cy + 3)
    p.line(cx - 2, cy + 3, cx + 5, cy - 4)
    p.line(cx + 5, cy - 4, cx + s, cy + s)
    p.line(cx - s, cy + s, cx + s, cy + s)


def sign_horns(p, cx, cy, s=11):
    """Two curved horns on a brow."""
    p.box(cx - 10, cy + 6, cx + 10, cy + 10)
    for sx in (-1, 1):
        p.poly([(cx + sx * 10, cy + 6), (cx + sx * 10, cy - 1),
                (cx + sx * 6, cy - 11), (cx + sx * 6, cy - 3),
                (cx + sx * 4, cy + 6)])

def sign_cup(p, cx, cy, s=11):
    """A cup: a bowl, a stem, a foot."""
    p.arc(cx, cy - 3, 9, 0, 180)
    p.line(cx - 9, cy - 3, cx + 9, cy - 3)
    p.line(cx, cy + 6, cx, cy + s)
    p.line(cx - 5, cy + s, cx + 5, cy + s)


def sign_shell(p, cx, cy, s=11):
    """A shell: a fan of ribs on a rim."""
    p.arc(cx, cy + 5, s, 180, 360)
    p.line(cx - s, cy + 5, cx + s, cy + 5)
    p.line(cx, cy + 5, cx, cy - s + 4, 1)
    p.line(cx, cy + 5, cx - 7, cy - 4, 1)
    p.line(cx, cy + 5, cx + 7, cy - 4, 1)


def sign_clock(p, cx, cy, s=11):
    """A clock: a ring and two hands."""
    p.ring(cx, cy, s)
    p.line(cx, cy, cx, cy - 6, 2)
    p.line(cx, cy, cx + 4, cy + 2, 2)


def sign_hand(p, cx, cy, s=11):
    """An open hand: a palm, four fingers and a thumb."""
    p.box(cx - 8, cy - 1, cx + 8, cy + 10)
    for dx, top in ((-6, -8), (-2, -11), (2, -11), (6, -8)):
        p.line(cx + dx, cy + top, cx + dx, cy, 3)
    p.line(cx - 8, cy + 4, cx - 12, cy - 2, 3)

SIGNS = {f.__name__[5:]: f for f in (
    sign_roof, sign_ring, sign_crescent, sign_shard, sign_gate, sign_tower,
    sign_thread, sign_cross, sign_sail, sign_waves, sign_crown, sign_eye,
    sign_lantern, sign_anvil, sign_hammer, sign_leaf, sign_anchor, sign_coin,
    sign_flame, sign_sun, sign_pit, sign_mountain, sign_horns, sign_cup,
    sign_shell, sign_clock, sign_hand)}

# The Shroud: id -> (top sign, lower sign, colour, disc (x, y, r))
SHROUD = {
    'heirloom_shroud': ('roof', 'ring', RED, (31, 21, 5)),
    'moon_shard_shroud': ('crescent', 'shard', YELLOW, (30, 24, 5)),
    'warden_standard': ('gate', 'tower', GREEN, (30, 55, 5)),
    'reliquary_thread': ('thread', 'cross', ORANGE, (30, 52, 5)),
    'white_fleet_sail': ('sail', 'waves', rgb('#E9EEF0'), (33, 22, 4)),
    'sovereign_mantle': ('crown', 'eye', RED, (24, 45, 6)),
    'void_standard': ('eye', 'gate', RED, (32, 24, 5)),
}
# The clans: faction id -> (top sign, lower sign, disc (x, y, r)); the colour
# is the faction's own, from factions.json.
CLANS = {
    'dominion': ('lantern', 'tower', (32, 23, 5)),
    'vigil': ('eye', 'ring', (24, 45, 5)),
    'compact': ('anvil', 'hammer', (32, 24, 5)),
    'mire': ('leaf', 'waves', (31, 22, 5)),
    'crows': ('anchor', 'coin', (31, 25, 5)),
    'penitents': ('flame', 'cross', (31, 53, 5)),
    'choir': ('sun', 'ring', (24, 45, 5)),
    'pit': ('pit', 'crescent', (31, 24, 5)),
    'giants': ('mountain', 'tower', (31, 22, 5)),
    'oni': ('horns', 'cup', (24, 45, 5)),
    'tidekin': ('shell', 'waves', (31, 23, 5)),
    'kindly': ('leaf', 'clock', (31, 22, 5)),
    'open_hand': ('hand', 'ring', (31, 24, 5)),
}


def banners():
    """id -> (top sign, lower sign, colour, disc)."""
    out = dict(SHROUD)
    try:
        factions = json.load(open(FACTIONS, encoding='utf-8'))
    except OSError:
        factions = {}
    colours = {fid: rgb(f['color']) for fid, f in factions.items()
               if isinstance(f, dict) and 'color' in f}
    for fid, (top, low, disc) in CLANS.items():
        if fid in colours:
            out[f'clan_{fid}'] = (top, low, colours[fid], disc)
    return out


def cloth_pixels():
    """The cloth's pixels: straight sides, a swallow-tail below."""
    ok = set()
    for y in range(CT, CB + TAIL + 1):
        for x in range(CL, CR + 1):
            if y <= CB or abs(x - MID) >= (y - CB) * 1.0 - 0.5:
                ok.add((x, y))
    return ok


def disc3d(im, cx, cy, r, base):
    """A round disc lit from the top left: a dark rim, the body, a glint."""
    p = Pen(im)
    p.disc(cx, cy, r, shade(base, 0.35))
    p.disc(cx - 1, cy - 1, r - 1, base)
    p.disc(cx - 2, cy - 2, max(1, r - 3), light(base, 0.28))
    # the dark side, dithered in
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= (r - 0.5) ** 2 and \
                    (x - cx) + (y - cy) > r * 0.7 and BAYER[y % 4][x % 4] < 8:
                im.putpixel((x, y), shade(base, 0.2))
    if r >= 4:
        im.putpixel((cx - 2, cy - 3), CREAM_HI)
        im.putpixel((cx - 3, cy - 2), CREAM_HI)


def draw(name, spec):
    top, low, colour, (ax, ay, ar) = spec
    im = Image.new('RGBA', (W, H), CLEAR)
    p = Pen(im)
    cloth = cloth_pixels()

    # --- the cloth: a weave, folds, a sheen -----------------------------------
    for (x, y) in cloth:
        c = INK
        if x % 2 == 0 and y % 2 == 0:
            c = WEAVE
        # two folds, a dark band with a lit edge, and a sheen between
        for fx in (15, 33):
            d = x - fx
            if -3 <= d <= 0 and BAYER[y % 4][x % 4] < (4 + d) * 4 + 3:
                c = FOLD
            elif 1 <= d <= 2 and BAYER[y % 4][x % 4] < 5:
                c = SHEEN
        if 22 <= x <= 25 and BAYER[(y + 2) % 4][x % 4] < 3:
            c = SHEEN
        im.putpixel((x, y), c)

    # --- header band and the trim along the tail --------------------------------
    for y in range(CT, CT + 5):
        for x in range(CL, CR + 1):
            c = colour
            if y == CT:
                c = light(colour, 0.3)
            elif y == CT + 4:
                c = shade(colour, 0.35)
            elif y == CT + 2 and x % 4 == 1:
                c = shade(colour, 0.55)       # a stitched row of beads
            im.putpixel((x, y), c)
    for (x, y) in cloth:
        if y > CB - 3 and (x, y + 1) not in cloth and (x + 1, y) in cloth:
            im.putpixel((x, y), colour)
        elif y > CB - 3 and (x, y + 1) not in cloth:
            im.putpixel((x, y), shade(colour, 0.2))
    # a band above the tail, the colour dithered into the cloth
    for y in range(CB - 6, CB - 2):
        for x in range(CL + 1, CR):
            if (x, y) in cloth and BAYER[y % 4][x % 4] < (y - (CB - 7)) * 3:
                im.putpixel((x, y), shade(colour, 0.45))

    # --- a stitched hem down both sides and a thread box around the signs --------
    for (x, y) in cloth:
        if y > CT + 4 and min(x - CL, CR - x) == 1 and y % 2 == 0 and y < CB - 2:
            im.putpixel((x, y), EDGE)
    for x in range(CL + 4, CR - 3):
        if x % 2 == 0:
            im.putpixel((x, CT + 7), EDGE)
            im.putpixel((x, CB - 8), EDGE)
    for y in range(CT + 7, CB - 7):
        if y % 2 == 0:
            im.putpixel((CL + 4, y), EDGE)
            im.putpixel((CR - 4, y), EDGE)
    # diamonds at the box's corners
    for (cx, cy) in ((CL + 4, CT + 7), (CR - 4, CT + 7),
                     (CL + 4, CB - 8), (CR - 4, CB - 8)):
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            im.putpixel((cx + dx, cy + dy), colour)

    # --- the signs, bevelled: a shade below-right, then the cream -----------------
    for (sign, cy) in ((top, 31), (low, 58)):
        p.c, p.ox, p.oy = CREAM_SHADE, 1, 1
        SIGNS[sign](p, 24, cy)
        p.c, p.ox, p.oy = CREAM, 0, 0
        SIGNS[sign](p, 24, cy)
    for dx in (-4, 0, 4):
        p.disc(24 + dx, 75, 1, CREAM_SHADE)

    # --- the disc across them ---------------------------------------------------
    disc3d(im, ax, ay, ar, colour)

    # --- the pole: turned wood with a lit top, rings and brass finials ---------
    p.box(4, 1, 43, 5, POLE)
    p.box(4, 1, 43, 1, POLE_LIGHT)
    p.box(4, 2, 43, 2, light(POLE, 0.12))
    p.box(4, 5, 43, 5, POLE_DARK)
    for x in range(6, 42, 5):
        im.putpixel((x, 3), POLE_DARK)
        im.putpixel((x + 1, 3), POLE_LIGHT)
    for fx in (3, 44):
        p.disc(fx, 3, 2, BRASS_DARK)
        im.putpixel((fx - 1, 2), light(BRASS, 0.35))
        im.putpixel((fx, 3), BRASS)
        im.putpixel((fx - 1, 3), BRASS)
        im.putpixel((fx, 2), BRASS)
    # rings that hold the cloth up
    for x in (10, 24, 37):
        p.box(x, 6, x, 9, BRASS_DARK)
        im.putpixel((x - 1, 6), BRASS)
        im.putpixel((x + 1, 6), BRASS)
        im.putpixel((x, 5), BRASS)
    # --- tassels at the two tips of the tail --------------------------------------
    for tx in (CL + 3, CR - 3):
        ty = CB + TAIL + 1
        p.box(tx, ty, tx, ty, BRASS_DARK)
        for dx in (-1, 0, 1):
            p.box(tx + dx, ty + 1, tx + dx, ty + 3, colour)
        im.putpixel((tx, ty + 1), light(colour, 0.3))
        im.putpixel((tx, ty + 4), shade(colour, 0.4))

    # --- a one-pixel dark outline round it all ---------------------------------
    solid = {(x, y) for y in range(H) for x in range(W) if im.getpixel((x, y))[3]}
    for (x, y) in solid:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and (nx, ny) not in solid:
                im.putpixel((nx, ny), OUTLINE)
    return im


def sheet(items, scale=5, per_row=10):
    gap = 4
    rows = (len(items) + per_row - 1) // per_row
    out = Image.new('RGBA', ((W + gap) * per_row + gap, (H + gap) * rows + gap),
                    (60, 54, 50, 255))
    for i, (n, spec) in enumerate(items):
        out.alpha_composite(draw(n, spec), (gap + (i % per_row) * (W + gap),
                                            gap + (i // per_row) * (H + gap)))
    return out.resize((out.width * scale, out.height * scale), Image.NEAREST)


if __name__ == '__main__':
    import sys
    items = list(banners().items())
    for name, spec in items:
        draw(name, spec).save(os.path.join(OUT, f'{name}.png'))
    print(len(items), 'banners')
    if len(sys.argv) > 1:
        sheet(items).save(sys.argv[1])
