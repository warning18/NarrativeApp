#!/usr/bin/env python3
"""Draws the fight's skill and spell effects as pixel strips.

    python3 tool/gen_fight_fx.py

One strip per effect in assets/visuals/pixel_fx/ (vfx_<name>.png): a row of
square 48 px frames, drawn with no antialiasing in three flat tones (a
white highlight, a light-steel middle and a slate shadow) and faded by
Bayer dithering. The game recolours the three tones to a skill's element at
run time (lib/widgets/pixel_vfx.dart), so one strip serves every element.

  strikes      slash heavy claw pierce impact whirl
  projectiles  arrow_proj orb meteor_proj  (loop while they travel)
  landings     impact_s zap explosion
  elements     flame frost lightning holy_beam splash poison smoke wind
               quake void_rift drain shadow radiance
  support      heal shield stone_shield mana shout
  states       stun weaken crit miss phase
  tiers        shock
"""
import math
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'visuals', 'pixel_fx')

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

FR = 48          # frame size of every strip
N = 8


def rgb(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


RAMPS = {  # highlight, mid, shadow
    'steel': ('#FFFFFF', '#C9D1DC', '#5E6B7E'),
    'fire': ('#FFF0B0', '#FF9A3D', '#B3361A'),
    'ice': ('#F2FCFF', '#7FD3FF', '#2E78AE'),
    'electricity': ('#FFFBD0', '#FFD54F', '#9A6A08'),
    'void': ('#F1E6FF', '#A07CE0', '#43296E'),
    'light': ('#FFFFFF', '#FFF08A', '#D19B1A'),
    'water': ('#EAFBFF', '#4FC3F7', '#1D6EA8'),
    'earth': ('#F0E2D2', '#B08C70', '#5E4636'),
    'wind': ('#F4FFFA', '#A5D6C8', '#4F8E80'),
    'poison': ('#F2FFD8', '#8BD04F', '#3B7A1E'),
}


DEEP = rgb('#2A303B')  # the fourth tone: the darkest, for cores and stone


def ramp(name):
    return tuple(rgb(c) for c in RAMPS[name])


def new(size=FR):
    im = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def fade(im, amount):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] and BAYER[y % 4][x % 4] / 16 < amount:
                px[x, y] = (0, 0, 0, 0)
    return im


def dot(d, x, y, c, w=1):
    d.rectangle([round(x), round(y), round(x) + w - 1, round(y) + w - 1], fill=c)


def disc(d, cx, cy, r, c):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c)


def ring(d, cx, cy, r, c, w=1):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=c, width=w)


def line(d, a, b, c, w=1):
    d.line([round(a[0]), round(a[1]), round(b[0]), round(b[1])], fill=c, width=w)


def hash01(i, salt):
    x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453
    return x - math.floor(x)


def ease(t):
    return 1 - (1 - t) ** 3


def clamp(v, a=0.0, b=1.0):
    return max(a, min(b, v))


def strip(frames):
    s = frames[0].width
    out = Image.new('RGBA', (s * len(frames), s), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, (i * s, 0))
    return out


def bez(p0, p1, p2, u):
    a = (1 - u) ** 2
    b = 2 * (1 - u) * u
    c = u * u
    return (a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1])


def sparks(d, cx, cy, i, n, rmin, rmax, c1, c2, seed=1, life=1.0, t=0.0):
    for k in range(n):
        a = k * 2 * math.pi / n + hash01(k, seed) * 0.6
        r = rmin + ease(clamp(t / life)) * (rmax - rmin) * (0.6 + 0.4 * hash01(k, seed + 3))
        dot(d, cx + math.cos(a) * r, cy + math.sin(a) * r, c1 if k % 2 else c2, 2 if (k % 3 == 0 and t < .5) else 1)


# ================================================================== strikes
def swoosh(d, curve, tail, head, maxw, hi, mid, lo):
    """A tapering crescent between [tail] and [head] along [curve]."""
    if head <= tail:
        return
    steps = 40
    for s in range(steps + 1):
        u = tail + (head - tail) * s / steps
        x, y = curve(u)
        k = math.sin(math.pi * (s / steps)) ** 0.8
        w = 1 + round(maxw * k)
        r = w / 2
        d.rectangle([round(x - r), round(y - r), round(x + r), round(y + r)], fill=lo if w > 3 else mid)
    for s in range(steps + 1):
        u = tail + (head - tail) * s / steps
        x, y = curve(u)
        k = math.sin(math.pi * (s / steps)) ** 0.8
        w = max(1, round(maxw * k * 0.62))
        r = w / 2
        d.rectangle([round(x - r), round(y - r), round(x + r), round(y + r)], fill=mid)
    for s in range(steps + 1):
        u = tail + (head - tail) * s / steps
        x, y = curve(u)
        k = math.sin(math.pi * (s / steps)) ** 0.8
        w = max(1, round(maxw * k * 0.28))
        r = w / 2
        d.rectangle([round(x - r), round(y - r), round(x + r), round(y + r)], fill=hi)


def fx_slash(i, rp):
    hi, mid, lo = rp
    t = 0.06 + i / (N - 1) * 0.94
    im, d = new()
    c = lambda u: bez((41, 5), (38, 36), (7, 43), u)
    head = ease(clamp(t / 0.5))
    tail = clamp((t - 0.22) / 0.6)
    swoosh(d, c, tail, head, 7, hi, mid, lo)
    if 0.3 < t < 0.9:
        sparks(d, 8, 42, i, 8, 2, 11, hi, mid, 5, 0.6, t - 0.3)
    return fade(im, clamp((t - 0.62) * 2.3))


def fx_heavy(i, rp):
    hi, mid, lo = rp
    t = 0.06 + i / (N - 1) * 0.94
    im, d = new()
    c = lambda u: bez((43, 2), (40, 38), (4, 44), u)
    c2 = lambda u: bez((46, 10), (44, 40), (14, 46), u)
    head = ease(clamp(t / 0.45))
    swoosh(d, c, clamp((t - 0.28) / 0.6), head, 11, hi, mid, lo)
    swoosh(d, c2, clamp((t - 0.35) / 0.6), ease(clamp((t - 0.1) / 0.45)), 6, mid, lo, lo)
    if t > 0.4:
        e = clamp((t - 0.4) / 0.5)
        ry = 3 + round(ease(e) * 5)
        d.ellipse([24 - 4 - round(ease(e) * 16), 44 - ry, 24 + 4 + round(ease(e) * 16), 44 + ry // 2], outline=mid, width=1)
        for k in range(10):
            a = math.pi + k * math.pi / 9
            r = 6 + ease(e) * (10 + hash01(k, 2) * 9)
            dot(d, 22 + math.cos(a) * r, 42 + math.sin(a) * r * 0.9 - 6 * e, hi if k % 2 else mid, 2 if k % 3 == 0 else 1)
    return fade(im, clamp((t - 0.7) * 3.2))


def fx_claw(i, rp):
    hi, mid, lo = rp
    t = 0.06 + i / (N - 1) * 0.94
    im, d = new()
    for k in range(3):
        off = (k - 1) * 9
        start = k * 0.09
        u = clamp((t - start) / 0.4)
        c = lambda v, off=off: bez((30 + off, 4 + abs(off) * 0.2), (27 + off, 24), (22 + off - 6, 44), v)
        swoosh(d, c, clamp((t - start - 0.18) / 0.5), ease(u), 5, hi, mid, lo)
    if 0.35 < t:
        for k in range(8):
            dot(d, 16 + hash01(k, 4) * 20, 12 + hash01(k, 8) * 28 + (t - .35) * 8, mid if k % 2 else hi)
    return fade(im, clamp((t - 0.6) * 2.5))


def fx_pierce(i, rp):
    hi, mid, lo = rp
    t = 0.06 + i / (N - 1) * 0.94
    im, d = new()
    x = -6 + ease(clamp(t / 0.45)) * 36
    y = 24
    for k, (yy, ln) in enumerate(((19, 12), (24, 18), (29, 10))):
        if t < 0.7:
            line(d, (x - ln - 4, yy), (x - 5, yy), mid if k != 1 else hi, 1)
    if t < 0.62:
        d.polygon([(round(x + 8), y), (round(x - 2), y - 5), (round(x - 2), y + 5)], fill=mid, outline=lo)
        d.polygon([(round(x + 6), y), (round(x - 1), y - 2), (round(x - 1), y + 2)], fill=hi)
        line(d, (x - 2, y), (x - 20, y), lo, 2)
    if t > 0.4:
        e = clamp((t - 0.4) / 0.5)
        for k in range(8):
            a = k * math.pi / 4
            r0 = 3 + ease(e) * 4
            r1 = r0 + 4 + ease(e) * 8 * (1.4 if k % 2 == 0 else 0.8)
            line(d, (30 + math.cos(a) * r0, 24 + math.sin(a) * r0), (30 + math.cos(a) * r1, 24 + math.sin(a) * r1), hi if k % 2 == 0 else mid, 2 if e < .5 else 1)
        if e < .4:
            disc(d, 30, 24, 3, hi)
    return fade(im, clamp((t - 0.72) * 3.5))


def star(d, cx, cy, ro, ri, n, fill, outline):
    pts = []
    for k in range(n * 2):
        a = k * math.pi / n - math.pi / 2
        r = ro if k % 2 == 0 else ri
        pts.append((round(cx + math.cos(a) * r), round(cy + math.sin(a) * r)))
    d.polygon(pts, fill=fill, outline=outline)


def fx_impact(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    e = ease(clamp(t / 0.55))
    ro = 4 + e * 17
    star(d, 24, 24, round(ro), round(ro * 0.45), 8, mid, lo)
    if t < 0.75:
        star(d, 24, 24, round(ro * 0.62), round(ro * 0.28), 8, hi, hi)
    if t > 0.15:
        ring(d, 24, 24, round(6 + ease(clamp((t - .15) / .7)) * 18), mid, 2 if t < .5 else 1)
    for k in range(12):
        a = k * 2 * math.pi / 12 + hash01(k, 7) * .5
        r = 10 + ease(t) * (12 + hash01(k, 9) * 8)
        dot(d, 24 + math.cos(a) * r, 24 + math.sin(a) * r, hi if k % 2 else mid, 3 if k % 4 == 0 else 2)
    return fade(im, clamp((t - 0.6) * 2.6))


# ================================================================ elements
def flame_tongue(d, bx, by, h, sway, hi, mid, lo, width):
    for s in range(h):
        k = s / max(1, h - 1)
        w = max(1, round(width * (1 - k) ** 0.75))
        x = bx + math.sin(k * 3.1 + sway) * 3.2 * k
        y = by - s
        col = lo if k > .66 else (mid if k > .3 or w > 3 else hi)
        d.rectangle([round(x - w / 2), round(y), round(x + w / 2), round(y)], fill=col)
    # bright core
    for s in range(int(h * .5)):
        k = s / max(1, h - 1)
        w = max(1, round(width * .5 * (1 - k * 1.4)))
        x = bx + math.sin(k * 3.1 + sway) * 3.2 * k
        d.rectangle([round(x - w / 2), round(by - s), round(x + w / 2), round(by - s)], fill=hi)


def fx_flame(i, rp):
    hi, mid, lo = rp
    t = 0.06 + i / (N - 1) * 0.94
    im, d = new()
    grow = ease(clamp(t / 0.35))
    for k, (bx, h, wd) in enumerate(((24, 30, 9), (15, 21, 6), (33, 23, 6), (9, 12, 4), (39, 13, 4))):
        flame_tongue(d, bx, 44, round(h * grow * (0.9 + 0.1 * math.sin(i * 1.7 + k))), i * 0.9 + k * 1.3, hi, mid, lo, wd)
    for k in range(8):
        r = hash01(k, 3)
        age = (t * 1.6 + r) % 1
        dot(d, 12 + r * 24 + math.sin(age * 6 + k) * 3, 40 - age * 34, mid if k % 2 else hi)
    return fade(im, clamp((t - 0.72) * 3.4))


def fx_frost(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    if i < 5:
        g = ease(i / 4)
        for k in range(6):
            a = k * math.pi / 3 + math.pi / 6
            L = (10 + (k % 2) * 6) * g
            ca, sa = math.cos(a), math.sin(a)
            px, py = -sa, ca
            tip = (24 + ca * L, 24 + sa * L)
            base1 = (24 + px * 3.4, 24 + py * 3.4)
            base2 = (24 - px * 3.4, 24 - py * 3.4)
            d.polygon([tuple(map(round, tip)), tuple(map(round, base1)), tuple(map(round, base2))], fill=mid, outline=lo)
            line(d, (24, 24), tip, hi, 1)
        disc(d, 24, 24, round(3 + g * 2), hi)
        if i >= 2:
            ring(d, 24, 24, round(5 + g * 14), mid, 1)
    else:
        e = (i - 4) / 3
        for k in range(18):
            a = k * 2 * math.pi / 18 + hash01(k, 11) * .4
            r = 9 + ease(e) * (8 + hash01(k, 12) * 14)
            x, y = 24 + math.cos(a) * r, 24 + math.sin(a) * r + e * 5 * hash01(k, 13)
            w = 3 if k % 3 == 0 else 2
            d.rectangle([round(x), round(y), round(x) + w - 1, round(y) + w - 1], fill=hi if k % 2 else mid)
        im = fade(im, clamp(e * 0.9))
    return im


def fx_lightning(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()

    def bolt(seed, w, col, x0=24, forks=True):
        pts = [(x0, 0)]
        y = 0
        while y < 38:
            y += 6 + hash01(len(pts), seed) * 5
            pts.append((x0 + (hash01(len(pts), seed + 2) - .5) * 16, min(y, 40)))
        for a, b in zip(pts, pts[1:]):
            line(d, a, b, col, w)
        if forks:
            for k in (2, 4):
                if k < len(pts):
                    s = pts[k]
                    e = (s[0] + (14 if k % 4 == 0 else -14), s[1] + 9)
                    line(d, s, e, col, max(1, w - 1))
        return pts

    if i == 0:
        disc(d, 24, 40, 4, hi)
        for k in range(8):
            dot(d, 12 + k * 3, 3 + hash01(k, 1) * 6, mid)
    elif i < 5:
        seed = 1 + (i % 2) * 7
        bolt(seed, 5 if i < 3 else 3, lo)
        bolt(seed, 3 if i < 3 else 2, mid)
        bolt(seed, 1, hi)
        disc(d, 24, 40, 6 - (i - 1), mid)
        disc(d, 24, 40, 3, hi)
        if i < 3:
            ring(d, 24, 40, 9 + i * 2, mid, 1)
    else:
        e = (i - 4) / 3
        bolt(3, 1, mid)
        for k in range(10):
            a = math.pi + hash01(k, 21) * math.pi
            r = 6 + ease(e) * 14
            dot(d, 24 + math.cos(a) * r * 1.3, 40 + math.sin(a) * r * 0.9, hi if k % 2 else mid)
        im = fade(im, clamp(e * 1.15))
    return im




# ---------------------------------------------------------------- helpers
def veil(im, painter, amount):
    """Draws [painter] on a fresh layer, dithers it by [amount], lays it on [im]."""
    layer = Image.new('RGBA', (FR, FR), (0, 0, 0, 0))
    painter(ImageDraw.Draw(layer))
    im.alpha_composite(fade(layer, clamp(amount)))


def arc_swoosh(d, cx, cy, r, a_tail, a_head, maxw, hi, mid, lo):
    steps = 36
    for layer, k0, col in ((0, 1.0, lo), (1, 0.62, mid), (2, 0.28, hi)):
        for s in range(steps + 1):
            u = s / steps
            a = a_tail + (a_head - a_tail) * u
            k = math.sin(math.pi * u) ** 0.8
            w = max(1, round(maxw * k * k0))
            x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
            d.rectangle([round(x - w / 2), round(y - w / 2), round(x + w / 2), round(y + w / 2)], fill=col)


# ---------------------------------------------------------------- strikes
def fx_whirl(i, rp):
    hi, mid, lo = rp
    t = 0.06 + i / (N - 1) * 0.94
    im, d = new()
    spin = ease(clamp(t / 0.8)) * math.pi * 2.6
    for k in range(2):
        a0 = spin + k * math.pi
        arc_swoosh(d, 24, 24, 15, a0 - 1.9, a0, 7, hi, mid, lo)
    if t > 0.25:
        ring(d, 24, 24, 17 + round(ease(clamp((t - .25) / .6)) * 5), mid, 1)
    for k in range(8):
        a = spin + k * math.pi / 4
        dot(d, 24 + math.cos(a) * (19 + 3 * math.sin(i + k)), 24 + math.sin(a) * (19 + 3 * math.cos(i + k)), hi if k % 2 else mid)
    return fade(im, clamp((t - 0.7) * 3.2))


# ------------------------------------------------------------ projectiles
def fx_arrow_proj(i, rp):
    hi, mid, lo = rp
    im, d = new()
    y = 24
    for k, ln in enumerate((16 + (i % 2) * 3, 10 + (i % 3) * 2)):
        line(d, (28 - ln, y - 4 + k * 8), (24, y - 4 + k * 8), mid if k else lo, 1)
    line(d, (12, y), (35, y), lo, 3)
    line(d, (12, y), (35, y), mid, 1)
    d.polygon([(41, y), (34, y - 4), (34, y + 4)], fill=hi, outline=lo)
    for off in (-1, 1):
        d.polygon([(12, y), (7, y + off * 5), (16, y)], fill=mid, outline=lo)
    return im


def fx_orb(i, rp):
    hi, mid, lo = rp
    im, d = new()
    cx = 32
    for g in range(1, 6):
        veil(im, lambda dd, g=g: disc(dd, cx - g * 4, 24 + round(math.sin(g + i * 1.3) * 2), max(1, 6 - g), lo if g > 2 else mid), 0.18 * g + 0.1)
    disc(d, cx, 24, 7, lo)
    disc(d, cx, 24, 6, mid)
    disc(d, cx - 1, 23, 3 + (i % 2), hi)
    for k in range(5):
        a = i * 1.3 + k * 1.26
        dot(d, cx + math.cos(a) * 9, 24 + math.sin(a) * 9, hi if k % 2 else mid)
    return im


def fx_meteor_proj(i, rp):
    hi, mid, lo = rp
    im, d = new()
    for g in range(1, 8):
        veil(im, lambda dd, g=g: disc(dd, 24 - g * 1 + round(math.sin(g * 1.7 + i) * 2), 22 - g * 4, max(1, 8 - g), lo if g > 3 else mid), 0.12 * g + 0.05)
    disc(d, 24, 30, 9, lo)
    disc(d, 24, 30, 8, DEEP)
    disc(d, 21, 27, 3, lo)
    dot(d, 20, 25, mid, 2)
    for k in range(6):
        dot(d, 17 + k * 3 + (i % 2), 22 + (k % 3) * 2 - 3, mid if k % 2 else hi, 2)
    ring(d, 24, 30, 9, mid, 1)
    return im


# --------------------------------------------------------------- landings
def fx_impact_s(i, rp):
    hi, mid, lo = rp
    t = 0.06 + i / (N - 1) * 0.94
    im, d = new()
    e = ease(clamp(t / 0.55))
    ro = 3 + e * 10
    star(d, 24, 24, round(ro), round(ro * 0.45), 6, mid, lo)
    if t < 0.75:
        star(d, 24, 24, round(ro * 0.6), round(ro * 0.28), 6, hi, hi)
    for k in range(8):
        a = k * math.pi / 4 + hash01(k, 7) * .4
        r = 7 + ease(t) * (7 + hash01(k, 9) * 5)
        dot(d, 24 + math.cos(a) * r, 24 + math.sin(a) * r, hi if k % 2 else mid, 2 if k % 3 == 0 else 1)
    return fade(im, clamp((t - 0.6) * 2.6))


def fx_zap(i, rp):
    hi, mid, lo = rp
    t = 0.06 + i / (N - 1) * 0.94
    im, d = new()
    for b in range(5):
        a = b * 2 * math.pi / 5 + 0.4 + (i % 2) * 0.5
        pts = [(24, 24)]
        r = 0
        while r < 20:
            r += 4 + hash01(len(pts) + b * 5 + i, 3) * 4
            aa = a + (hash01(len(pts) + b * 7 + i, 5) - .5) * 0.9
            pts.append((24 + math.cos(aa) * r, 24 + math.sin(aa) * r))
        for p0, p1 in zip(pts, pts[1:]):
            line(d, p0, p1, lo, 3 if t < .5 else 2)
            line(d, p0, p1, mid, 1)
    disc(d, 24, 24, max(2, round(7 * (1 - t) + 2)), mid)
    disc(d, 24, 24, max(1, round(4 * (1 - t) + 1)), hi)
    ring(d, 24, 24, 5 + round(ease(t) * 12), mid, 1)
    return fade(im, clamp((t - 0.55) * 2.4))


def fx_explosion(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    r = 5 + round(ease(clamp(t / .7)) * 17)
    veil(im, lambda dd: disc(dd, 24, 24, r, lo), t * 0.55)
    veil(im, lambda dd: disc(dd, 24, 24, round(r * 0.72), mid), t * 0.45)
    disc(d, 24, 24, max(1, round(r * 0.45 * (1 - t * .7))), hi)
    ring(d, 24, 24, min(23, r + 2), mid, 2 if t < .5 else 1)
    for k in range(12):
        a = k * 2 * math.pi / 12 + hash01(k, 5)
        rr = r * 0.6 + ease(t) * (7 + hash01(k, 6) * 9)
        dot(d, 24 + math.cos(a) * rr, 24 + math.sin(a) * rr - t * 5, hi if k % 2 else mid, 2 if k % 3 == 0 else 1)
    return fade(im, clamp((t - 0.5) * 1.9)) if t > .5 else im


# --------------------------------------------------------------- elements
def fx_holy_beam(i, rp):
    hi, mid, lo = rp
    t = 0.06 + i / (N - 1) * 0.94
    im, d = new()
    w = round(4 + 7 * math.sin(math.pi * clamp(t / 0.8)) ** 0.7)
    veil(im, lambda dd: dd.rectangle([24 - w - 3, 0, 24 + w + 3, 41], fill=mid), 0.62 - t * 0.25)
    d.rectangle([24 - w, 0, 24 + w, 41], fill=mid)
    d.rectangle([24 - w // 2, 0, 24 + w // 2, 41], fill=hi)
    d.ellipse([24 - 12 - round(t * 8), 38, 24 + 12 + round(t * 8), 46], outline=hi, width=2 if t < .5 else 1)
    for k in range(10):
        age = (t * 1.5 + hash01(k, 3)) % 1
        dot(d, 24 + (hash01(k, 4) - .5) * 2 * (w + 6), 42 - age * 40, hi if k % 2 else mid, 2 if k % 3 == 0 else 1)
    return fade(im, clamp((t - 0.7) * 3.3))


def fx_splash(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    for k in range(14):
        a = -math.pi / 2 + (k - 6.5) * 0.19
        v = 11 + hash01(k, 2) * 9
        x = 24 + math.cos(a) * v * t * 1.6
        y = 30 + math.sin(a) * v * t * 1.6 + 26 * t * t
        w = 3 if k % 3 == 0 else 2
        d.ellipse([round(x), round(y), round(x) + w, round(y) + w + 1], fill=hi if k % 2 else mid, outline=lo)
    for k, t0 in enumerate((0.0, 0.2, 0.4)):
        e = clamp((t - t0) / 0.6)
        if 0 < e < 1:
            rx = 3 + round(ease(e) * 17)
            d.ellipse([24 - rx, 32 - rx // 3, 24 + rx, 32 + rx // 3 + 1], outline=mid if k % 2 == 0 else hi, width=1)
    return fade(im, clamp((t - 0.65) * 2.8))


def fx_poison(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    for k, (cx, cy, r) in enumerate(((24, 30, 11), (15, 32, 8), (33, 32, 8), (24, 24, 8))):
        layer = Image.new('RGBA', (FR, FR), (0, 0, 0, 0)); ld = ImageDraw.Draw(layer)
        disc(ld, cx, cy - round(t * 3), round(r * (0.6 + 0.4 * ease(t))), lo if k % 2 else mid)
        im.alpha_composite(fade(layer, 0.38 + 0.08 * k))
    for k in range(9):
        age = (t * 1.2 + hash01(k, 3)) % 1
        x = 12 + hash01(k, 4) * 24 + math.sin(age * 6 + k) * 2
        y = 40 - age * 34
        r = 1 + round(age * 2.5)
        ring(d, round(x), round(y), r, hi if k % 2 else mid, 1)
        if r > 2 and age > .8:
            dot(d, x, y, hi, 1)
    return fade(im, clamp((t - 0.7) * 3.2))


def fx_smoke(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    for k in range(7):
        age = clamp(t * 1.1 - k * 0.07)
        if age <= 0:
            continue
        x = 24 + (hash01(k, 1) - .5) * 18 + math.sin(age * 4 + k) * 3
        y = 40 - age * 26
        r = 3 + round(age * 8)
        layer = Image.new('RGBA', (FR, FR), (0, 0, 0, 0)); ld = ImageDraw.Draw(layer)
        disc(ld, round(x), round(y), r, mid if k % 2 else lo)
        disc(ld, round(x - 1), round(y - 1), max(1, r - 3), hi if k % 3 == 0 else mid)
        im.alpha_composite(fade(layer, 0.25 + age * 0.7))
    return im


def fx_wind(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    for k, (cy, ph) in enumerate(((14, 0.0), (24, 0.15), (34, 0.3))):
        u = clamp((t - ph) / 0.7)
        if u <= 0:
            continue
        pts = []
        for s in range(14):
            q = s / 13
            x = 4 + (q * 40) * (0.4 + 0.6 * ease(u)) + 0
            y = cy + math.sin(q * 6 + k * 1.2 + t * 7) * 4
            pts.append((x, y))
        n = max(2, int(len(pts) * ease(u)))
        for a, b in zip(pts[max(0, n - 10):n - 1], pts[max(0, n - 9):n]):
            line(d, a, b, mid if k != 1 else hi, 2 if k == 1 else 1)
        if n >= len(pts) - 1:
            x, y = pts[-1]
            ring(d, round(x), round(y), 2 + round(u * 2), mid, 1)
    for k in range(6):
        age = (t * 1.3 + hash01(k, 3)) % 1
        dot(d, 4 + age * 40, 10 + hash01(k, 5) * 28 + math.sin(age * 8 + k) * 3, hi, 2 if k % 3 == 0 else 1)
    return fade(im, clamp((t - 0.7) * 3.3))


def fx_quake(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    e = ease(clamp(t / 0.5))
    cy = 34
    for k in range(10):
        a = math.pi * 2 * k / 10 + 0.2
        pts = [(24, cy)]
        r = 0
        L = 5 + e * 19 + (k % 2) * 3
        while r < L:
            r += 3 + hash01(len(pts) + k, 2) * 3
            aa = a + (hash01(len(pts) + k * 3, 4) - .5) * 0.8
            pts.append((24 + math.cos(aa) * r * 1.15, cy + math.sin(aa) * r * 0.5))
        for p0, p1 in zip(pts, pts[1:]):
            line(d, p0, p1, DEEP, 3)
            line(d, p0, p1, mid, 1)
    for k in range(10):
        a = (k - 4.5) * 0.42
        h = math.sin(math.pi * clamp(t * 1.25 - hash01(k, 3) * 0.2)) * (9 + hash01(k, 4) * 14)
        x = 24 + a * 13
        y = cy + 2 - h
        w = 3 if k % 2 else 2
        d.rectangle([round(x), round(y), round(x) + w, round(y) + w], fill=mid, outline=lo)
        if h > 4:
            dot(d, x, y - 1, hi, 1)
    if t > 0.08:
        ex = round(4 + ease(clamp((t - .08) / .7)) * 19)
        d.ellipse([24 - ex, cy - ex // 3, 24 + ex, cy + ex // 3], outline=hi, width=1)
    return fade(im, clamp((t - 0.7) * 3.3))


def fx_void_rift(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    op = ease(clamp(t / 0.4)) * (1 - clamp((t - 0.7) / 0.3))
    rx, ry = round(3 + 8 * op), round(4 + 17 * op)
    d.ellipse([24 - rx - 2, 24 - ry - 2, 24 + rx + 2, 24 + ry + 2], fill=mid)
    d.ellipse([24 - rx, 24 - ry, 24 + rx, 24 + ry], fill=lo)
    d.ellipse([24 - rx // 2, 24 - ry // 2, 24 + rx // 2, 24 + ry // 2], fill=DEEP)
    for k in range(14):
        a = k * 2 * math.pi / 14 + t * 5
        r = (22 - ((t * 1.4 + hash01(k, 3)) % 1) * 20)
        dot(d, 24 + math.cos(a) * r * 0.8, 24 + math.sin(a) * r, hi if k % 2 else mid, 2 if k % 4 == 0 else 1)
    for k in range(6):
        a = k * math.pi / 3 + 0.5
        line(d, (24 + math.cos(a) * (rx + 2), 24 + math.sin(a) * (ry + 2)), (24 + math.cos(a) * (rx + 7 + k % 3 * 2), 24 + math.sin(a) * (ry + 7 + k % 3 * 2)), mid, 1)
    return fade(im, clamp((t - 0.82) * 5)) if t > .82 else im


def fx_drain(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    for k in range(26):
        u = clamp((t - hash01(k, 2) * 0.3) / 0.7)
        if u <= 0 or u >= 1:
            continue
        a = hash01(k, 3) * 2 * math.pi + u * 6
        r = 22 * (1 - ease(u)) + 2
        x, y = 24 + math.cos(a) * r, 24 + math.sin(a) * r * 0.85 - u * 5
        w = 3 if (u < .5 and k % 3 == 0) else 2
        d.rectangle([round(x), round(y), round(x) + w - 1, round(y) + w - 1], fill=hi if k % 2 else mid)
        for tail in (1, 2, 3):
            uu = max(0, u - 0.05 * tail)
            r2 = 22 * (1 - ease(uu)) + 2
            a2 = a - 0.5 * tail
            dot(d, 24 + math.cos(a2) * r2, 24 + math.sin(a2) * r2 * 0.85 - uu * 5, lo if tail > 1 else mid, 1)
    veil(im, lambda dd: disc(dd, 24, 20, 3 + round(7 * math.sin(math.pi * t)), lo), 0.3)
    ring(d, 24, 20, 3 + round(9 * math.sin(math.pi * t)), mid, 1)
    return im


def fx_shadow(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    for k in range(5):
        bx = 10 + k * 7
        h = round((10 + hash01(k, 2) * 18) * ease(clamp((t - hash01(k, 4) * 0.2) / 0.5)))
        for s in range(h):
            q = s / max(1, h)
            x = bx + math.sin(q * 5 + k + t * 4) * 4
            w = max(1, round(4 * (1 - q)))
            d.rectangle([round(x - w / 2), 42 - s, round(x + w / 2), 42 - s], fill=lo if q < .7 else mid)
        if h > 8:
            dot(d, bx + math.sin(h / h * 5 + k + t * 4) * 4, 42 - h, hi, 2)
    veil(im, lambda dd: dd.ellipse([8, 38, 40, 46], fill=lo), 0.3)
    for k in range(8):
        age = (t * 1.2 + hash01(k, 3)) % 1
        dot(d, 12 + hash01(k, 4) * 24, 40 - age * 30, mid, 1)
    return fade(im, clamp((t - 0.72) * 3.5))


def fx_radiance(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    w = round(2 + 4 * math.sin(math.pi * clamp(t / 0.85)) ** 0.7)
    veil(im, lambda dd: dd.rectangle([24 - w - 3, 0, 24 + w + 3, 40], fill=mid), 0.7 - t * 0.15)
    d.rectangle([24 - w, 0, 24 + w, 40], fill=hi)
    rot = t * 1.2
    g = round(5 + 6 * math.sin(math.pi * clamp(t / .9)))
    disc(d, 24, 24, g, lo)
    disc(d, 24, 24, g - 1, mid)
    disc(d, 24, 24, max(1, g // 2), hi)
    for k in range(12):
        a = k * math.pi / 6 + rot
        r0 = g + 2
        r1 = g + 4 + (10 if k % 2 == 0 else 5) * ease(clamp(t / .6))
        line(d, (24 + math.cos(a) * r0, 24 + math.sin(a) * r0), (24 + math.cos(a) * r1, 24 + math.sin(a) * r1), hi if k % 2 == 0 else mid, 2 if k % 2 == 0 else 1)
    for k in range(8):
        a = hash01(k, 3) * 6.28
        r = 8 + hash01(k, 5) * 14
        x, y = 24 + math.cos(a) * r, 24 + math.sin(a) * r * 0.9
        if int(t * 8 + k) % 3 == 0:
            line(d, (x - 3, y), (x + 3, y), hi, 1)
            line(d, (x, y - 3), (x, y + 3), hi, 1)
        else:
            dot(d, x, y, mid)
    return fade(im, clamp((t - 0.72) * 3.5))


# ---------------------------------------------------------------- support
def plus(d, x, y, r, c, w=1):
    d.rectangle([round(x - r), round(y - w // 2), round(x + r), round(y - w // 2 + w - 1)], fill=c)
    d.rectangle([round(x - w // 2), round(y - r), round(x - w // 2 + w - 1), round(y + r)], fill=c)


def fx_heal(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    veil(im, lambda dd: disc(dd, 24, 26, round(8 + 11 * ease(clamp(t / .6))), mid), 0.55 + t * 0.3)
    for k, (x, ph, r) in enumerate(((14, 0.0, 4), (24, 0.12, 5), (34, 0.05, 4), (19, 0.3, 3), (30, 0.4, 3))):
        age = clamp((t - ph) / 0.6)
        if 0 < age < 1:
            plus(d, x + math.sin(age * 5 + k) * 2, 38 - age * 30, r, lo, 4 if r > 3 else 3)
            plus(d, x + math.sin(age * 5 + k) * 2, 38 - age * 30, r, hi if k % 2 else mid, 2)
    for k in range(10):
        age = (t * 1.3 + hash01(k, 2)) % 1
        dot(d, 8 + hash01(k, 3) * 32, 40 - age * 34, hi, 1)
    return fade(im, clamp((t - 0.72) * 3.5))


def fx_shield(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    rad = round(8 + 11 * ease(clamp(t / 0.4)))
    pts = [(24 + math.cos(k * math.pi / 3 + math.pi / 6) * rad, 26 + math.sin(k * math.pi / 3 + math.pi / 6) * rad * 1.15) for k in range(6)]
    veil(im, lambda dd: dd.polygon([(round(x), round(y)) for x, y in pts], fill=mid), 0.5 + t * 0.4)
    d.polygon([(round(x), round(y)) for x, y in pts], outline=hi, width=3 if t < .6 else 2)
    d.polygon([(round(x), round(y)) for x, y in pts], outline=lo, width=1)
    for k in range(6):
        x, y = pts[k]
        dot(d, x - 1, y - 1, hi, 3)
    if 0.35 < t < 0.8:
        e = (t - .35) / .45
        line(d, (24 - rad * .5, 26 - rad * .6 + e * rad), (24 + rad * .5, 26 - rad * .2 + e * rad * .9), hi, 2)
    return fade(im, clamp((t - 0.72) * 3.5))


def fx_stone_shield(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    rise = ease(clamp(t / 0.4))
    w, h = 11, round(20 * rise)
    top = 42 - h
    for row in range(0, h, 5):
        y0 = top + row
        off = 0 if (row // 5) % 2 == 0 else 5
        for bx in range(24 - w - 5, 24 + w + 5, 10):
            x0 = bx + off
            xa, xb = max(24 - w - 3, x0), min(24 + w + 2, x0 + 9)
            if xb > xa:
                d.rectangle([xa, y0, xb, min(41, y0 + 4)], fill=mid, outline=lo)
                dot(d, xa + 1, y0 + 1, hi, 2)
    if 0.4 < t < 0.8:
        e = (t - .4) / .4
        for k in range(8):
            a = k * math.pi / 4
            dot(d, 24 + math.cos(a) * (12 + e * 9), 28 + math.sin(a) * (12 + e * 9), hi if k % 2 else mid, 2)
    d.ellipse([24 - w - 6, 40, 24 + w + 6, 46], outline=lo, width=1)
    return fade(im, clamp((t - 0.72) * 3.5))


def fx_mana(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    for k in range(18):
        u = clamp((t - hash01(k, 2) * 0.3) / 0.6)
        if u <= 0 or u >= 1:
            continue
        a = hash01(k, 3) * 6.28 + u * 4.5
        r = 21 * (1 - ease(u))
        dot(d, 24 + math.cos(a) * r, 26 + math.sin(a) * r * 0.85, hi if k % 2 else mid, 2 if k % 3 == 0 else 1)
    if t > 0.45:
        e = clamp((t - .45) / .55)
        rr = round(4 + 7 * math.sin(math.pi * e))
        d.polygon([(24, 26 - rr - 2), (24 + rr, 26), (24, 26 + rr + 2), (24 - rr, 26)], fill=mid, outline=lo)
        d.polygon([(24, 26 - rr // 2 - 1), (24 + rr // 2, 26), (24, 26 + rr // 2 + 1), (24 - rr // 2, 26)], fill=hi)
        ring(d, 24, 26, rr + 5, mid, 1)
    return fade(im, clamp((t - 0.78) * 4.5))


def fx_shout(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    for k, t0 in enumerate((0.0, 0.18, 0.36)):
        e = clamp((t - t0) / 0.6)
        if 0 < e < 1:
            r = 5 + round(ease(e) * 18)
            for a0 in (-0.9, math.pi - 0.9):
                for s in range(12):
                    a = a0 + s / 11 * 1.8
                    x, y = 24 + math.cos(a) * r, 26 + math.sin(a) * r
                    d.rectangle([round(x), round(y), round(x) + 1 + (1 if k == 0 else 0), round(y) + 1], fill=hi if k % 2 == 0 else mid)
    for k in range(10):
        a = k * 2 * math.pi / 10 + hash01(k, 2) * .3
        r = 4 + ease(t) * (12 + hash01(k, 3) * 6)
        line(d, (24 + math.cos(a) * r, 26 + math.sin(a) * r), (24 + math.cos(a) * (r + 4), 26 + math.sin(a) * (r + 4)), mid, 1)
    return fade(im, clamp((t - 0.7) * 3.4))


# ----------------------------------------------------------------- states
def star4(d, x, y, r, c, o):
    d.polygon([(round(x), round(y - r)), (round(x + r * .35), round(y - r * .35)), (round(x + r), round(y)), (round(x + r * .35), round(y + r * .35)),
               (round(x), round(y + r)), (round(x - r * .35), round(y + r * .35)), (round(x - r), round(y)), (round(x - r * .35), round(y - r * .35))], fill=c, outline=o)


def fx_stun(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    for k in range(4):
        a = t * 2 * math.pi + k * math.pi / 2
        x, y = 24 + math.cos(a) * 13, 14 + math.sin(a) * 4.5
        star4(d, x, y, 5 if math.sin(a) > 0 else 4, hi if k % 2 else mid, lo)
    for k in range(3):
        a = -t * 2 * math.pi + k * 2.1
        dot(d, 24 + math.cos(a) * 10, 14 + math.sin(a) * 3.5, mid, 1)
    return im


def fx_weaken(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    for k, x in enumerate((13, 24, 35)):
        for row in range(3):
            ph = (t * 1.2 - k * 0.12 + row * 0.18) % 1
            y = 8 + ph * 32 + row * 3
            w = 6 - row
            alpha = 1 - ph
            if alpha < 0.15:
                continue
            col = hi if row == 0 else mid if row == 1 else lo
            d.line([(x - w, y), (x, y + w), (x + w, y)], fill=col, width=2)
    return fade(im, clamp((t - 0.8) * 4))


def fx_crit(i, rp):
    hi, mid, lo = rp
    t = 0.06 + i / (N - 1) * 0.94
    im, d = new()
    e = ease(clamp(t / 0.45))
    ro = 5 + e * 19
    star(d, 24, 24, round(ro), round(ro * 0.38), 10, lo, lo)
    star(d, 24, 24, round(ro * .86), round(ro * 0.34), 10, mid, mid)
    star(d, 24, 24, round(ro * 0.5), round(ro * 0.22), 10, hi, hi)
    for k in range(16):
        a = k * math.pi / 8
        r0 = ro + 1
        r1 = ro + 3 + ease(t) * 8
        line(d, (24 + math.cos(a) * r0, 24 + math.sin(a) * r0), (24 + math.cos(a) * r1, 24 + math.sin(a) * r1), hi if k % 2 == 0 else mid, 1)
    return fade(im, clamp((t - 0.55) * 2.4))


def fx_miss(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    head = ease(clamp(t / 0.5))
    for s_ in range(34):
        u = s_ / 33 * head
        x = 3 + u * 42
        y = 31 - math.sin(u * math.pi) * 15
        w = max(1, round(5 * math.sin(math.pi * s_ / 33)))
        d.rectangle([round(x), round(y), round(x) + 1, round(y) + w], fill=lo if w > 3 else mid)
        d.rectangle([round(x), round(y), round(x) + 1, round(y) + max(1, w - 2)], fill=hi if s_ % 3 else mid)
    for k in range(3):
        y = 16 + k * 7
        line(d, (6, y), (6 + round(14 * head), y), mid, 1)
    if t > 0.4:
        e = clamp((t - .4) / .6)
        for k in range(10):
            side = -1 if k % 2 else 1
            dot(d, 38 + side * (2 + e * 8 * hash01(k, 2)), 40 - e * 5 * hash01(k, 3), mid if k % 3 else hi, 2 if e < .5 else 1)
    return fade(im, clamp((t - 0.62) * 2.6))


def fx_phase(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    e = ease(clamp(t / 0.7))
    r1, r2 = round(5 + e * 18), round(3 + ease(clamp((t - .2) / .7)) * 17)
    ring(d, 24, 24, r1, lo, 4 if t < .4 else 3 if t < .7 else 1)
    ring(d, 24, 24, r1, mid, 2 if t < .5 else 1)
    ring(d, 24, 24, r2, hi, 1)
    for k in range(8):
        a = k * math.pi / 4 + .3
        pts = [(24 + math.cos(a) * 4, 24 + math.sin(a) * 4)]
        L = 5 + e * 18
        r = 4
        while r < L:
            r += 3 + hash01(k * 5 + int(r), 3) * 3
            aa = a + (hash01(k * 3 + int(r), 4) - .5) * .7
            pts.append((24 + math.cos(aa) * r, 24 + math.sin(aa) * r))
        for p0, p1 in zip(pts, pts[1:]):
            line(d, p0, p1, lo, 2)
            line(d, p0, p1, mid, 1)
    if t < .35:
        disc(d, 24, 24, round(9 * (1 - t / .35)) + 1, hi)
    return fade(im, clamp((t - 0.62) * 2.7))


def fx_shock(i, rp):
    hi, mid, lo = rp
    t = i / (N - 1)
    im, d = new()
    e = ease(clamp(t / 0.8))
    rx = 4 + round(e * 20)
    ry = max(2, rx // 3)
    d.ellipse([24 - rx, 38 - ry, 24 + rx, 38 + ry], outline=lo, width=3 if t < .5 else 2)
    d.ellipse([24 - rx, 38 - ry, 24 + rx, 38 + ry], outline=mid, width=1)
    for k in range(12):
        a = math.pi * (k / 11)
        r = rx * (0.5 + hash01(k, 2) * 0.5)
        dot(d, 24 + math.cos(a + math.pi) * r * 0.8 * (1 if k % 2 else -1), 38 - e * (4 + hash01(k, 3) * 9) + math.sin(a) * 2, hi if k % 2 else mid, 2 if k % 3 == 0 else 1)
    return fade(im, clamp((t - 0.5) * 2.2))


STRIPS = {
    # strikes
    'slash': fx_slash, 'heavy': fx_heavy, 'claw': fx_claw, 'pierce': fx_pierce, 'impact': fx_impact, 'whirl': fx_whirl,
    # projectiles (loops), landings
    'arrow_proj': (fx_arrow_proj, 3), 'orb': (fx_orb, 4), 'meteor_proj': (fx_meteor_proj, 4),
    'impact_s': fx_impact_s, 'zap': fx_zap, 'explosion': fx_explosion,
    # elements
    'flame': fx_flame, 'frost': fx_frost, 'lightning': fx_lightning, 'holy_beam': fx_holy_beam, 'splash': fx_splash,
    'poison': fx_poison, 'smoke': fx_smoke, 'wind': fx_wind, 'quake': fx_quake, 'void_rift': fx_void_rift,
    'drain': fx_drain, 'shadow': fx_shadow, 'radiance': fx_radiance,
    # support
    'heal': fx_heal, 'shield': fx_shield, 'stone_shield': fx_stone_shield, 'mana': fx_mana, 'shout': fx_shout,
    # states
    'stun': fx_stun, 'weaken': fx_weaken, 'crit': fx_crit, 'miss': fx_miss, 'phase': fx_phase,
    # tiers
    'shock': fx_shock,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    rp = ramp('steel')
    for name, fn in STRIPS.items():
        count = N
        if isinstance(fn, tuple):
            fn, count = fn
        strip([fn(i, rp) for i in range(count)]).save(os.path.join(OUT, 'vfx_' + name + '.png'), optimize=True)
    print('drew', len(STRIPS), 'strips in', os.path.normpath(OUT))


if __name__ == '__main__':
    main()
