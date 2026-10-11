#!/usr/bin/env python3
"""Draws the game's banners as pixel art.

    python3 tool/gen_banners.py [contact-sheet.png]

One 64x128 PNG per banner in assets/visuals/banners/: the six pieces of the
Shroud (named by their ids), the title's standard and the clans' main
banners (clan_<faction id>). After the Japanese kanji posters of the type
studios: a black woven cloth filled edge to edge by two heavy signs stacked
the way vertical writing is. The signs are built from thick slabs with
rounded corners, fat arcs and rings, cut through by thin black stencil slits
where the pieces meet, with rows of round discs shading from red to yellow,
eyes (a ring round a dot), and fine concentric lines laid along the curves.
The cloth has its folds, a header band and tail trim in the banner's colour,
and hangs from a turned pole with rings, brass finials and tassels. No
antialiasing, a handful of flat colours; shown by PixelBanner
(lib/widgets/pixel_banner.dart) at a whole-number scale.
"""
import json
import math
import os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'assets', 'visuals', 'banners')
FACTIONS = os.path.join(HERE, '..', 'assets', 'gamedata', 'factions.json')
os.makedirs(OUT, exist_ok=True)

W, H = 64, 128
CL, CR = 9, 54                    # the cloth's first and last column
CT, CB = 11, 112                  # its top row, and the last row of the body
TAIL = 11                         # the swallow-tail's depth below CB
MID = (CL + CR) / 2
CELL = 40                         # a sign is drawn in a 40 px square
TOP_AT = (12, 20)
LOW_AT = (12, 66)

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
DIM = rgb('#8F876F')        # fine lines: cream, turned down


class Cell:
    """A sign's 40 px square. Heavy shapes go on the glyph layer (cut through
    by stencil slits, then bevelled), fine lines on their own layer and round
    discs on a third, so the cuts never touch them."""

    def __init__(self, glyph, fine, accents, at):
        self.glyph = glyph
        self.fine = fine
        self.accents = accents
        self.ox, self.oy = at
        self.gd = ImageDraw.Draw(glyph)

    # --- heavy shapes ---
    def slab(self, x0, y0, x1, y1, c, r=2):
        self.gd.rounded_rectangle([x0 + self.ox, y0 + self.oy, x1 + self.ox,
                                   y1 + self.oy], radius=r, fill=c)

    def paint(self, inside, c, layer=None):
        im = layer or self.glyph
        for y in range(CELL):
            for x in range(CELL):
                if inside(x, y):
                    im.putpixel((x + self.ox, y + self.oy), c)

    def disc(self, cx, cy, r, c):
        self.paint(lambda x, y: (x - cx) ** 2 + (y - cy) ** 2 <= r * r + 0.3, c)

    def ring(self, cx, cy, ro, ri, c):
        def inside(x, y):
            d = (x - cx) ** 2 + (y - cy) ** 2
            return ri * ri <= d <= ro * ro + 0.3
        self.paint(inside, c)

    def arc(self, cx, cy, ro, ri, a0, a1, c, caps=True):
        """A fat arc between angles a0 and a1 (degrees, clockwise from the
        right), round at both ends."""
        a0 %= 360
        a1 %= 360

        def inside(x, y):
            d = math.hypot(x - cx, y - cy)
            if not ri <= d <= ro + 0.3:
                return False
            a = math.degrees(math.atan2(y - cy, x - cx)) % 360
            return a0 <= a <= a1 if a0 <= a1 else a >= a0 or a <= a1
        self.paint(inside, c)
        if caps:
            rm, w = (ro + ri) / 2, (ro - ri) / 2
            for a in (a0, a1):
                self.disc(cx + rm * math.cos(math.radians(a)),
                          cy + rm * math.sin(math.radians(a)), w, c)

    def poly(self, pts, c):
        self.gd.polygon([(x + self.ox, y + self.oy) for x, y in pts], fill=c)

    def line(self, x0, y0, x1, y1, w, c):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            t = i / n
            self.disc(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, w / 2, c)

    def cut(self, x0, y0, x1, y1):
        """A stencil slit: the glyph's pixels in the box are cleared."""
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                if 0 <= x < CELL and 0 <= y < CELL:
                    self.glyph.putpixel((x + self.ox, y + self.oy), CLEAR)

    def cutline(self, x0, y0, x1, y1, w=2):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            t = i / n
            cx, cy = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            for y in range(max(0, int(cy - w)), min(CELL, int(cy + w) + 1)):
                for x in range(max(0, int(cx - w)), min(CELL, int(cx + w) + 1)):
                    if (x - cx) ** 2 + (y - cy) ** 2 <= (w / 2) ** 2 + 0.2:
                        self.glyph.putpixel((x + self.ox, y + self.oy), CLEAR)

    # --- fine lines and discs ---
    def stripes(self, cx, cy, ro, ri, a0, a1, c, step=3):
        """Fine concentric lines in an annulus sector."""
        a0 %= 360
        a1 %= 360

        def inside(x, y):
            d = math.hypot(x - cx, y - cy)
            if not ri <= d <= ro or int(round(d)) % step:
                return False
            a = math.degrees(math.atan2(y - cy, x - cx)) % 360
            return a0 <= a <= a1 if a0 <= a1 else a >= a0 or a <= a1
        self.paint(inside, c, self.fine)

    def bead(self, cx, cy, r, c, core=None):
        """A round disc, shaded; [core] sets a dot in it (an eye)."""
        self.accents.append((cx + self.ox, cy + self.oy, r, c, core))


# --- the signs: 40 px squares. M the main colour, A the disc colour, S fine lines

def pipe(c, pts, w, M):
    """A heavy line through [pts], round at every bend, like the poster
    strokes that turn corners."""
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        c.line(x0, y0, x1, y1, w, M)


def g_box(c, M, A, S):
    """A rounded box on a bar, a disc nested in each half (a kanji's mouth)."""
    pipe(c, [(4, 4), (35, 4), (35, 35), (4, 35), (4, 4)], 8, M)
    pipe(c, [(4, 19.5), (35, 19.5)], 5, M)
    c.cutline(19.5, 6, 19.5, 33, 2)
    c.bead(12, 11.5, 3.2, A)
    c.bead(27, 27.5, 3.2, A)


def g_comb(c, M, A, S):
    """A spine with prongs, a disc at the end of each: an E that turns."""
    pipe(c, [(6, 3), (6, 36)], 8, M)
    pipe(c, [(6, 5), (33, 5)], 6, M)
    pipe(c, [(6, 19.5), (26, 19.5)], 6, M)
    pipe(c, [(6, 34), (33, 34)], 6, M)
    c.cutline(10, 12, 28, 12, 2)
    c.cutline(10, 27, 28, 27, 2)
    for y in (5, 19.5, 34):
        c.bead(36 if y != 19.5 else 31, y, 3, A)


def g_spiral(c, M, A, S):
    """A square spiral of one heavy stroke, a disc at its heart."""
    pipe(c, [(36, 4), (4, 4), (4, 35), (35, 35), (35, 15), (16, 15), (16, 26)],
         6, M)
    c.cutline(5, 10, 34, 10, 2)
    c.bead(25, 25, 4, A)


def g_roof(c, M, A, S):
    """A dome on two legs over a post and a sill, a disc nested under it."""
    c.arc(19.5, 22, 19.5, 12.5, 180, 360, M)
    c.slab(1, 22, 7, 31, M)
    c.slab(32, 22, 38, 31, M)
    c.slab(16, 17, 23, 31, M, 1)
    c.slab(0, 34, 39, 39, M, 3)
    c.bead(19.5, 11, 5, A)


def g_ring(c, M, A, S):
    """A fat ring, an eye in it, set on a plinth."""
    c.ring(19.5, 17.5, 17.5, 10, M)
    c.cutline(2, 33, 37, 33, 2)
    c.slab(8, 35, 31, 39, M, 2)
    c.bead(19.5, 17.5, 6, A, INK)


def g_crescent(c, M, A, S):
    """A fat moon, fine lines inside its belly, a star beside it."""
    c.paint(lambda x, y: (x - 17) ** 2 + (y - 20) ** 2 <= 18 * 18 and
            (x - 25) ** 2 + (y - 16) ** 2 > 15 * 15, M)
    c.stripes(25, 16, 14, 8, 20, 160, S, 3)
    c.bead(31, 8, 5, A)
    c.slab(4, 36, 30, 39, M, 1)


def g_shard(c, M, A, S):
    """A splinter: a heavy triangle cut in two, a disc on its tip."""
    c.poly([(2, 38), (21, 1), (38, 38)], M)
    c.cutline(8, 36, 29, 6, 2)
    c.stripes(30, 38, 14, 8, 180, 270, S, 3)
    c.bead(21, 11, 4, A)


def g_gate(c, M, A, S):
    """A lintel on two posts, a bar between, a disc nested beneath."""
    c.slab(0, 0, 39, 7, M, 3)
    c.slab(2, 10, 9, 39, M, 3)
    c.slab(30, 10, 37, 39, M, 3)
    c.slab(12, 15, 27, 20, M, 2)
    c.bead(19.5, 29, 5, A, INK)


def g_tower(c, M, A, S):
    """Three heavy courses stepped down on a post, a row of discs above."""
    c.slab(0, 8, 39, 15, M, 3)
    c.slab(6, 18, 33, 25, M, 3)
    c.slab(12, 28, 27, 34, M, 3)
    c.slab(16, 36, 23, 39, M, 1)
    c.cutline(19.5, 9, 19.5, 33, 2)
    for i in range(3):
        c.bead(9 + i * 10.5, 3, 3, A)


def g_thread(c, M, A, S):
    """A thread's S: two fat half rings, fine lines flowing beside them."""
    c.arc(19.5, 10, 10, 3.5, 90, 360, M)
    c.arc(19.5, 28.5, 10, 3.5, 270, 540, M)
    c.stripes(19.5, 10, 17, 12, 90, 300, S, 2)
    c.stripes(19.5, 28.5, 17, 12, 270, 120, S, 2)
    c.bead(33, 10, 4, A)


def g_cross(c, M, A, S):
    """A fat cross, cut at its heart, a disc in each quarter."""
    c.slab(14, 0, 25, 39, M, 4)
    c.slab(0, 14, 39, 25, M, 4)
    c.cut(14, 19, 25, 20)
    c.cut(19, 14, 20, 25)
    c.bead(6, 6, 3, A)
    c.bead(33, 6, 3, A)
    c.bead(6, 33, 3, A)
    c.bead(33, 33, 3, A)


def g_sail(c, M, A, S):
    """A heavy sail on its mast above a hull."""
    c.slab(7, 0, 12, 33, M, 2)
    c.poly([(15, 2), (38, 28), (15, 28)], M)
    c.cutline(16, 24, 33, 24, 2)
    c.slab(0, 34, 39, 39, M, 3)
    c.stripes(14, 28, 22, 18, 280, 350, S, 2)
    c.bead(28, 11, 4, A)


def g_waves(c, M, A, S):
    """Three fat swells, fine lines beneath."""
    for y in (8, 20, 32):
        c.arc(10, y, 9, 3, 180, 360, M)
        c.arc(29, y, 9, 3, 0, 180, M)
    c.bead(19.5, 20, 3, A)


def g_crown(c, M, A, S):
    """A heavy band with three posts, each topped with a disc of its own
    colour from red to yellow."""
    c.slab(0, 30, 39, 39, M, 3)
    c.cutline(2, 28, 37, 28, 2)
    for i, x in enumerate((1, 16.5, 32)):
        c.slab(x, 12, x + 6, 26, M, 2)
        c.bead(x + 3, 6, 5, A)


def g_eye(c, M, A, S):
    """The torn eye: a fat almond, an iris, a slash through it all."""
    c.arc(19.5, 31, 22, 15, 232, 308, M)
    c.arc(19.5, 9, 22, 15, 52, 128, M)
    c.bead(19.5, 20, 7, A, INK)
    c.cutline(33, 2, 7, 38, 2)


def g_lantern(c, M, A, S):
    """A lantern: a fat frame with a flame inside and a handle above."""
    c.arc(19.5, 9, 9, 4, 180, 360, M)
    c.slab(4, 12, 35, 18, M, 3)
    c.slab(4, 18, 10, 36, M, 2)
    c.slab(29, 18, 35, 36, M, 2)
    c.slab(2, 34, 37, 39, M, 3)
    c.bead(19.5, 27, 5, A, INK)
    c.stripes(19.5, 36, 9, 5, 200, 340, S, 2)


def g_anvil(c, M, A, S):
    """An anvil: a long face and horn, a waist, a heavy foot."""
    c.slab(0, 6, 28, 15, M, 3)
    c.poly([(26, 6), (39, 11), (26, 15)], M)
    c.slab(8, 17, 22, 28, M, 2)
    c.slab(2, 30, 29, 39, M, 3)
    c.cutline(0, 16, 30, 16, 2)
    c.bead(33, 28, 4, A)


def g_hammer(c, M, A, S):
    """A hammer: a heavy head over a haft."""
    c.slab(0, 2, 39, 15, M, 5)
    c.cutline(19.5, 2, 19.5, 15, 2)
    c.slab(16, 17, 23, 39, M, 2)
    c.bead(7, 33, 4, A)
    c.stripes(19.5, 39, 14, 9, 200, 340, S, 2)


def g_leaf(c, M, A, S):
    """A leaf: a fat lens on a slant, a rib cut through it."""
    def inside(x, y):
        u = (x - y) / 1.414
        v = (x + y - 40) / 1.414
        return abs(u) <= 19 and abs(v) <= 11 * (1 - (u / 19) ** 2) ** 0.7
    c.paint(inside, M)
    c.cutline(5, 35, 34, 5, 2)
    c.stripes(19.5, 19.5, 17, 4, 0, 360, S, 6)
    c.bead(32, 31, 5, A)


def g_anchor(c, M, A, S):
    """An anchor: a ring, a heavy shank and stock, fat flukes."""
    c.ring(19.5, 5, 5, 2, M)
    c.slab(16, 9, 23, 33, M, 2)
    c.slab(5, 13, 34, 18, M, 2)
    c.arc(19.5, 20, 18, 11, 10, 170, M)
    c.bead(19.5, 5, 2, A)
    c.stripes(19.5, 20, 9, 5, 20, 160, S, 2)


def g_coin(c, M, A, S):
    """A coin with a square hole, a disc nested at its rim."""
    c.ring(19.5, 19.5, 19.5, 12, M)
    c.slab(14, 14, 25, 25, M, 1)
    c.cut(19, 14, 20, 25)
    c.cut(14, 19, 25, 20)
    c.bead(31, 8, 4, A)
    c.stripes(19.5, 19.5, 10, 7, 0, 360, S, 3)


def g_flame(c, M, A, S):
    """A flame: a fat drop with a tongue, a core cut from it, discs below."""
    def inside(x, y):
        if (x - 19.5) ** 2 + (y - 22) ** 2 <= 15 * 15:
            return True
        if 1 <= y <= 22:
            lean = (y - 1) / 21 * 12 + 1
            return abs(x - (24 - (y - 1) * 0.28)) <= lean
        return False
    c.paint(inside, M)
    c.bead(19.5, 24, 6, A, INK)
    for i in range(3):
        c.bead(9 + i * 10.5, 37, 2.4, A)


def g_sun(c, M, A, S):
    """A sun: a fat ring ringed by heavy rays."""
    c.ring(19.5, 19.5, 12, 8, M)
    for a in range(0, 360, 30):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        c.line(19.5 + ca * 15, 19.5 + sa * 15, 19.5 + ca * 18, 19.5 + sa * 18,
               5, M)
    c.bead(19.5, 19.5, 6, A)


def g_pit(c, M, A, S):
    """The pit: heavy bars narrowing downward, a disc in the dark below."""
    c.slab(0, 2, 39, 10, M, 3)
    c.slab(6, 14, 33, 21, M, 3)
    c.slab(13, 25, 26, 30, M, 2)
    c.stripes(19.5, 2, 30, 24, 60, 120, S, 2)
    c.bead(19.5, 36, 3.5, A)


def g_mountain(c, M, A, S):
    """Two heavy peaks cut by a slit, a sun disc over them."""
    c.poly([(0, 39), (12, 6), (24, 39)], M)
    c.poly([(16, 39), (28, 14), (39, 39)], M)
    c.cutline(15, 39, 22, 20, 2)
    c.stripes(12, 39, 22, 18, 255, 300, S, 2)
    c.bead(30, 5, 4, A)


def g_horns(c, M, A, S):
    """Two fat horns on a brow, an eye under each."""
    for sx, x0 in ((1, 20.5), (-1, 18.5)):
        pts = [(x0 + sx * 3, 38), (x0 + sx * 3, 22), (x0 + sx * 14, 2),
               (x0 + sx * 18, 4), (x0 + sx * 12, 24), (x0 + sx * 17, 38)]
        c.poly(pts, M)
    c.slab(10, 30, 29, 39, M, 3)
    c.bead(10, 22, 3.6, A, INK)
    c.bead(29, 22, 3.6, A, INK)


def g_cup(c, M, A, S):
    """A cup: a fat bowl, a stem and a heavy foot."""
    c.paint(lambda x, y: (x - 19.5) ** 2 + (y - 8) ** 2 <= 19 * 19 and y >= 8, M)
    c.slab(0, 4, 39, 9, M, 2)
    c.cutline(2, 10, 37, 10, 2)
    c.slab(16, 24, 23, 33, M, 1)
    c.slab(6, 34, 33, 39, M, 3)
    c.bead(19.5, 17, 4, A)
    c.stripes(19.5, 8, 17, 12, 20, 160, S, 2)


def g_shell(c, M, A, S):
    """A shell: a fat half disc cut into ribs, a pearl in its hinge."""
    c.paint(lambda x, y: (x - 19.5) ** 2 + (y - 31) ** 2 <= 19.5 ** 2 and y <= 31, M)
    for a in (210, 240, 270, 300, 330):
        c.cutline(19.5, 31, 19.5 + 24 * math.cos(math.radians(a)),
                  31 + 24 * math.sin(math.radians(a)), 2)
    c.slab(0, 33, 39, 39, M, 3)
    c.bead(19.5, 27, 4, A)


def g_clock(c, M, A, S):
    """A clock: a fat ring, two heavy hands, a disc at its heart."""
    c.ring(19.5, 19.5, 19.5, 13, M)
    c.slab(17, 6, 22, 21, M, 2)
    c.slab(19, 18, 31, 23, M, 2)
    c.bead(19.5, 20, 4, A)
    c.stripes(19.5, 19.5, 12, 9, 0, 360, S, 3)


def g_hand(c, M, A, S):
    """An open hand: four heavy fingers, a palm and a thumb, a disc in the palm."""
    for i, x in enumerate((3, 12, 21, 30)):
        top = (6, 1, 0, 4)[i]
        c.slab(x, top, x + 6, 22, M, 3)
    c.slab(3, 24, 36, 39, M, 5)
    c.slab(0, 22, 6, 32, M, 3)
    c.bead(19.5, 31, 4, A)
    c.cut(9, 0, 9, 24)
    c.cut(18, 0, 18, 24)
    c.cut(27, 0, 27, 24)


GLYPHS = {n[2:]: f for n, f in list(globals().items()) if n.startswith('g_')}

# The Shroud: id -> (top sign, lower sign, colour, tone)
SHROUD = {
    'heirloom_shroud': ('roof', 'box', RED, 'cream'),
    'moon_shard_shroud': ('crescent', 'shard', YELLOW, 'cream'),
    'warden_standard': ('gate', 'comb', GREEN, 'cream'),
    'reliquary_thread': ('thread', 'spiral', ORANGE, 'cream'),
    'white_fleet_sail': ('sail', 'waves', rgb('#E9EEF0'), 'cream'),
    'sovereign_mantle': ('crown', 'eye', RED, 'cream'),
    'void_standard': ('eye', 'spiral', RED, 'cream'),
}
# The clans: faction id -> (top sign, lower sign, tone). 'cream' draws the
# signs in cream with the clan's discs; 'colour' draws the top sign in the
# clan's own colour with cream discs; 'both' draws both in its colour.
CLANS = {
    'dominion': ('lantern', 'comb', 'cream'),
    'vigil': ('eye', 'box', 'colour'),
    'compact': ('anvil', 'hammer', 'cream'),
    'mire': ('leaf', 'waves', 'both'),
    'crows': ('anchor', 'coin', 'cream'),
    'penitents': ('flame', 'cross', 'colour'),
    'choir': ('sun', 'box', 'cream'),
    'pit': ('pit', 'crescent', 'both'),
    'giants': ('mountain', 'tower', 'colour'),
    'oni': ('horns', 'cup', 'cream'),
    'tidekin': ('shell', 'waves', 'both'),
    'kindly': ('leaf', 'clock', 'colour'),
    'open_hand': ('hand', 'spiral', 'cream'),
}


def banners():
    """id -> (top sign, lower sign, colour, tone)."""
    out = dict(SHROUD)
    try:
        factions = json.load(open(FACTIONS, encoding='utf-8'))
    except OSError:
        factions = {}
    colours = {fid: rgb(f['color']) for fid, f in factions.items()
               if isinstance(f, dict) and 'color' in f}
    for fid, (top, low, tone) in CLANS.items():
        if fid in colours:
            out[f'clan_{fid}'] = (top, low, colours[fid], tone)
    return out


def cloth_pixels():
    """The cloth's pixels: straight sides, a swallow-tail below."""
    ok = set()
    for y in range(CT, CB + TAIL + 1):
        for x in range(CL, CR + 1):
            if y <= CB or abs(x - MID) >= (y - CB) * 1.2 - 0.5:
                ok.add((x, y))
    return ok


def disc3d(im, cx, cy, r, base, core=None):
    """A round disc lit from the top left: a dark rim, the body, a glint."""
    def put(x, y, c):
        if 0 <= x < W and 0 <= y < H:
            im.putpixel((x, y), c)

    def fill(cx_, cy_, r_, c):
        for y in range(int(cy_ - r_) - 1, int(cy_ + r_) + 2):
            for x in range(int(cx_ - r_) - 1, int(cx_ + r_) + 2):
                if (x - cx_) ** 2 + (y - cy_) ** 2 <= r_ * r_ + 0.3:
                    put(x, y, c)
    fill(cx, cy, r, shade(base, 0.35))
    fill(cx - 0.6, cy - 0.6, r - 1, base)
    if r >= 3:
        fill(cx - 1.2, cy - 1.2, max(1, r - 2.6), light(base, 0.25))
    for y in range(int(cy - r) - 1, int(cy + r) + 2):
        for x in range(int(cx - r) - 1, int(cx + r) + 2):
            if (x - cx) ** 2 + (y - cy) ** 2 <= (r - 0.5) ** 2 and \
                    (x - cx) + (y - cy) > r * 0.7 and BAYER[y % 4][x % 4] < 8:
                put(x, y, shade(base, 0.2))
    if core:
        fill(cx, cy, max(1, r * 0.42), core)
        put(int(cx - 1), int(cy - 1), light(core, 0.5))
    elif r >= 4:
        put(int(cx - 2), int(cy - 2), CREAM_HI)
        put(int(cx - 2), int(cy - 3), CREAM_HI)


def bevel(layer):
    """Lights the top-left rim of every heavy shape and darkens its
    bottom-right, so a flat slab reads as a thick piece."""
    out = layer.copy()
    for y in range(H):
        for x in range(W):
            p = layer.getpixel((x, y))
            if not p[3]:
                continue
            up = layer.getpixel((x, y - 1))[3] if y > 0 else 0
            left = layer.getpixel((x - 1, y))[3] if x > 0 else 0
            down = layer.getpixel((x, y + 1))[3] if y < H - 1 else 0
            right = layer.getpixel((x + 1, y))[3] if x < W - 1 else 0
            if not up or not left:
                out.putpixel((x, y), light(p, 0.28))
            elif not down or not right:
                out.putpixel((x, y), shade(p, 0.28))
    return out


def draw(name, spec):
    top, low, colour, tone = spec
    im = Image.new('RGBA', (W, H), CLEAR)
    cloth = cloth_pixels()

    # --- the cloth: a weave, folds, a sheen -----------------------------------
    for (x, y) in cloth:
        c = INK
        if x % 2 == 0 and y % 2 == 0:
            c = WEAVE
        for fx in (21, 45):
            d = x - fx
            if -4 <= d <= 0 and BAYER[y % 4][x % 4] < (5 + d) * 3 + 2:
                c = FOLD
            elif 1 <= d <= 2 and BAYER[y % 4][x % 4] < 5:
                c = SHEEN
        if 30 <= x <= 33 and BAYER[(y + 2) % 4][x % 4] < 3:
            c = SHEEN
        im.putpixel((x, y), c)

    # --- the signs ------------------------------------------------------------
    glyph = Image.new('RGBA', (W, H), CLEAR)
    fine = Image.new('RGBA', (W, H), CLEAR)
    accents = []
    s2 = DIM
    colours = [(CREAM, colour), (CREAM, colour)]
    for (sign, at), (m, a) in zip(((top, TOP_AT), (low, LOW_AT)), colours):
        GLYPHS[sign](Cell(glyph, fine, accents, at), m, a, s2)
    im.alpha_composite(bevel(glyph))
    im.alpha_composite(fine)
    for (cx, cy, r, c, core) in accents:
        disc3d(im, cx, cy, r, c, core)

    # --- header band and the trim along the tail: the banner's one colour,
    # kept quiet ----------------------------------------------------------------
    for y in range(CT, CT + 4):
        for x in range(CL, CR + 1):
            im.putpixel((x, y), colour if y == CT + 1 else shade(colour, 0.55))
    for (x, y) in cloth:
        if y > CB - 3 and (x, y + 1) not in cloth:
            im.putpixel((x, y), shade(colour, 0.25))
    # a stitched hem down both sides
    for (x, y) in cloth:
        if y > CT + 6 and min(x - CL, CR - x) == 1 and y % 2 == 0 and y < CB - 2:
            im.putpixel((x, y), EDGE)

    # --- the pole: turned wood with a lit top, rings and brass finials ---------
    p = ImageDraw.Draw(im)
    p.rectangle([5, 1, 58, 6], fill=POLE)
    p.rectangle([5, 1, 58, 1], fill=POLE_LIGHT)
    p.rectangle([5, 2, 58, 2], fill=light(POLE, 0.12))
    p.rectangle([5, 6, 58, 6], fill=POLE_DARK)
    for x in range(8, 56, 6):
        im.putpixel((x, 4), POLE_DARK)
        im.putpixel((x + 1, 4), POLE_LIGHT)
    for fx in (4, 59):
        p.ellipse([fx - 3, 1, fx + 3, 7], fill=BRASS_DARK)
        p.ellipse([fx - 2, 1, fx + 2, 6], fill=BRASS)
        im.putpixel((fx - 1, 2), light(BRASS, 0.4))
    for x in (14, 32, 49):
        p.rectangle([x, 7, x, 11], fill=BRASS_DARK)
        im.putpixel((x - 1, 7), BRASS)
        im.putpixel((x + 1, 7), BRASS)
        im.putpixel((x, 6), BRASS)
    # --- tassels at the two tips of the tail --------------------------------------
    for tx in (CL + 4, CR - 4):
        ty = CB + TAIL + 1
        p.rectangle([tx, ty, tx, ty], fill=BRASS_DARK)
        for dx in (-1, 0, 1):
            p.rectangle([tx + dx, ty + 1, tx + dx, ty + 2], fill=BRASS)
        im.putpixel((tx, ty + 1), light(BRASS, 0.3))
        im.putpixel((tx, ty + 3), BRASS_DARK)

    # --- a one-pixel dark outline round it all ---------------------------------
    solid = {(x, y) for y in range(H) for x in range(W) if im.getpixel((x, y))[3]}
    for (x, y) in solid:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and (nx, ny) not in solid:
                im.putpixel((nx, ny), OUTLINE)
    return im


def sheet(items, scale=4, per_row=10):
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
