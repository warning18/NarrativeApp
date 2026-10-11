#!/usr/bin/env python3
"""Draws the fight's skill and spell effects as pixel strips, in the poster hand.

    python3 tool/gen_fight_fx.py

One strip per effect in assets/visuals/pixel_fx/ (vfx_<name>.png): a row of
square 48 px frames, drawn with no antialiasing in four flat tones (a white
highlight, a light-steel middle, a slate shadow and a deep one) and faded by
Bayer dithering. The game recolours the four tones to a skill's element at
run time (lib/widgets/pixel_vfx.dart), so one strip serves every element.

The hand is taken from the Japanese kanji posters (see tool/gen_banners.py):
heavy slabs with rounded corners and fat arcs, thin stencil slits cut through
them, shaded round discs and eyes, fine concentric lines, and pixel particles.
The middle tone is the body of a slab, the highlight lights its top-left rim
and the discs, the shadow its bottom-right rim and the fine lines.

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
import random
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'visuals', 'pixel_fx')

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

FR = 48          # frame size of every strip
N = 8
K = 0.75         # the motions are drawn in a 64 px space and set down at this scale


def rgb(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


HI = rgb('#FFFFFF')      # highlight: a slab's lit rim, discs, glints
MID = rgb('#C9D1DC')     # the body of a slab
LO = rgb('#5E6B7E')      # shadow rim, fine lines
DEEP = rgb('#2A303B')    # cores, stone
CLEAR = (0, 0, 0, 0)
CREAM, DARK = MID, DEEP


def shade(c, t):
    return DEEP if (t >= .5 or c in (LO, DEEP)) else LO


def light(c, t):
    return HI


def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def ease(x):
    x = clamp(x)
    return x * x * (3 - 2 * x)


def eout(x):
    x = clamp(x)
    return 1 - (1 - x) ** 2


def seg(t, a, b):
    return clamp((t - a) / (b - a)) if b > a else (1.0 if t >= a else 0.0)


def fade_img(im, amount):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] and BAYER[y % 4][x % 4] / 16 < amount:
                px[x, y] = CLEAR
    return im


class Cv:
    """One frame. Heavy shapes on [main] (cut by slits, then bevelled), fine
    lines and particles on [fine], shaded discs on [top]. The motions are
    written in a 64 px space; [target] is the point of it that lands on the
    frame's [anchor]."""

    def __init__(self, seed, target=(32, 32), anchor=(24, 24)):
        self.seed = seed
        self.tx, self.ty = target
        self.ax, self.ay = anchor
        self.S = 1.0
        self.A, self.B = HI, LO
        self.grade = [HI, MID, HI]
        self.k = 14
        self.ex = 0
        self.main = Image.new('RGBA', (FR, FR), CLEAR)
        self.fine = Image.new('RGBA', (FR, FR), CLEAR)
        self.top = Image.new('RGBA', (FR, FR), CLEAR)

    def X(self, x):
        return self.ax + (x - self.tx) * K

    def Y(self, y):
        return self.ay + (y - self.ty) * K

    def layer(self, name):
        return {'main': self.main, 'fine': self.fine, 'top': self.top}[name]

    def put(self, im, x, y, c):
        if 0 <= x < FR and 0 <= y < FR:
            im.putpixel((x, y), c)

    def disc(self, cx, cy, r, c, layer='main'):
        cx, cy, r = self.X(cx), self.Y(cy), max(.8, r * K)
        im = self.layer(layer)
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + .3:
                    self.put(im, x, y, c)

    def ring(self, cx, cy, ro, ri, c, layer='main'):
        cx, cy, ro, ri = self.X(cx), self.Y(cy), ro * K, max(0, ri * K)
        if ro - ri < 1:
            ri = max(0, ro - 1)
        im = self.layer(layer)
        for y in range(int(cy - ro) - 1, int(cy + ro) + 2):
            for x in range(int(cx - ro) - 1, int(cx + ro) + 2):
                d = (x - cx) ** 2 + (y - cy) ** 2
                if ri * ri <= d <= ro * ro + .3:
                    self.put(im, x, y, c)

    def arc(self, cx, cy, ro, ri, a0, sweep, c, layer='main', caps=True):
        if sweep <= 0:
            return
        sweep = min(sweep, 360)
        cx_, cy_ = self.X(cx), self.Y(cy)
        ro_, ri_ = ro * K, ri * K
        if ro_ - ri_ < 1:
            ri_ = max(0, ro_ - 1)
        im = self.layer(layer)
        for y in range(int(cy_ - ro_) - 1, int(cy_ + ro_) + 2):
            for x in range(int(cx_ - ro_) - 1, int(cx_ + ro_) + 2):
                d = math.hypot(x - cx_, y - cy_)
                if not ri_ <= d <= ro_ + .3:
                    continue
                a = math.degrees(math.atan2(y - cy_, x - cx_))
                if (a - a0) % 360 <= sweep:
                    self.put(im, x, y, c)
        if caps and sweep < 359:
            rm, w = (ro + ri) / 2, (ro - ri) / 2
            for a in (a0, a0 + sweep):
                self.disc(cx + rm * math.cos(math.radians(a)),
                          cy + rm * math.sin(math.radians(a)), w, c, layer)

    def line(self, x0, y0, x1, y1, w, c, layer='main'):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * K * 1.5) + 1
        for i in range(n + 1):
            t = i / n
            self.disc(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, w * 0.65, c, layer)

    def slab(self, x0, y0, x1, y1, c, r=2, layer='main'):
        im = self.layer(layer)
        xa, xb = sorted((round(self.X(x0)), round(self.X(x1))))
        ya, yb = sorted((round(self.Y(y0)), round(self.Y(y1))))
        ImageDraw.Draw(im).rounded_rectangle(
            [xa, ya, xb, yb], radius=max(0, min(round(r * K), (xb - xa) // 2, (yb - ya) // 2)), fill=c)

    def poly(self, pts, c, layer='main'):
        ImageDraw.Draw(self.layer(layer)).polygon(
            [(self.X(x), self.Y(y)) for x, y in pts], fill=c)

    def stripes(self, cx, cy, ro, ri, a0, sweep, c, step=3):
        cx_, cy_ = self.X(cx), self.Y(cy)
        ro_, ri_ = ro * K, ri * K
        for y in range(int(cy_ - ro_) - 1, int(cy_ + ro_) + 2):
            for x in range(int(cx_ - ro_) - 1, int(cx_ + ro_) + 2):
                d = math.hypot(x - cx_, y - cy_)
                if ri_ <= d <= ro_ and int(round(d)) % step == 0:
                    a = math.degrees(math.atan2(y - cy_, x - cx_))
                    if (a - a0) % 360 <= sweep:
                        self.put(self.fine, x, y, c)

    def cutline(self, x0, y0, x1, y1, w=2):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * K * 1.5) + 1
        for i in range(n + 1):
            t = i / n
            cx, cy = self.X(x0 + (x1 - x0) * t), self.Y(y0 + (y1 - y0) * t)
            for y in range(int(cy - w), int(cy + w) + 1):
                for x in range(int(cx - w), int(cx + w) + 1):
                    if (x - cx) ** 2 + (y - cy) ** 2 <= (w * K / 2) ** 2 + .2:
                        self.put(self.main, x, y, CLEAR)

    def cutarc(self, cx, cy, r, a0, sweep, w=2):
        steps = max(2, int(sweep / 6))
        for i in range(steps + 1):
            a = math.radians(a0 + sweep * i / steps)
            x, y = self.X(cx + r * math.cos(a)), self.Y(cy + r * math.sin(a))
            for yy in range(int(y - w), int(y + w) + 1):
                for xx in range(int(x - w), int(x + w) + 1):
                    if (xx - x) ** 2 + (yy - y) ** 2 <= (w * K / 2) ** 2 + .2:
                        self.put(self.main, xx, yy, CLEAR)

    def bead(self, cx, cy, r, base, core=None):
        """A shaded round disc (lit top-left) on the top layer: a deep rim,
        the body in [base], a glint; [core] sets a dot in it."""
        im = self.top
        cx, cy, r = self.X(cx), self.Y(cy), max(1.2, r * K)

        def fill(cx_, cy_, r_, c):
            for y in range(int(cy_ - r_) - 1, int(cy_ + r_) + 2):
                for x in range(int(cx_ - r_) - 1, int(cx_ + r_) + 2):
                    if (x - cx_) ** 2 + (y - cy_) ** 2 <= r_ * r_ + .3:
                        self.put(im, x, y, c)
        fill(cx, cy, r, LO)
        if r >= 2:
            fill(cx - .6, cy - .6, r - 1, base)
        if r >= 3:
            for y in range(int(cy - r), int(cy + r) + 1):
                for x in range(int(cx - r), int(cx + r) + 1):
                    if (x - cx) ** 2 + (y - cy) ** 2 <= (r - .5) ** 2 and \
                            (x - cx) + (y - cy) > r * .7 and BAYER[y % 4][x % 4] < 8:
                        self.put(im, x, y, MID if base == HI else LO)
        if core:
            fill(cx, cy, max(1, r * .42), core)

    def dust(self, x, y, size, c):
        x, y = round(x), round(y)
        for yy in range(y, y + size):
            for xx in range(x, x + size):
                self.put(self.fine, xx, yy, c)

    def spark(self, x, y, c):
        x, y = round(x), round(y)
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            self.put(self.fine, x + dx, y + dy, c)

    def burst(self, t, ox, oy, t0, life, speed, cols, tag, n=None, grav=0.0,
              ang=(0, 360), inward=False, plus=0.25):
        n = self.k if n is None else n
        rnd = random.Random(f'{self.seed}{tag}')
        for i in range(n):
            b = t0 + rnd.random() * life * .55
            age = (t - b) / life
            a = math.radians(ang[0] + rnd.random() * (ang[1] - ang[0]))
            sp = speed * (.45 + rnd.random() * .7)
            big = rnd.random() < .4
            kind_plus = rnd.random() < plus
            c = cols[i % len(cols)]
            if not 0 <= age <= 1:
                continue
            dist = sp * (eout(age) if not inward else (1 - age) ** 1.4)
            x = self.X(ox) + math.cos(a) * dist * K
            y = self.Y(oy) + math.sin(a) * dist * K + grav * age * age * 22 * K
            if age > .8:
                self.dust(x, y, 1, c)
            elif kind_plus and big:
                self.spark(x, y, c)
            else:
                self.dust(x, y, 2 if big else 1, c)

    def halo(self, *a, **k):
        """Rarity's extra is the game's tier layers now (the shock strip)."""


def bevel(layer):
    out = layer.copy()
    w, h = layer.size
    for y in range(h):
        for x in range(w):
            p = layer.getpixel((x, y))
            if not p[3]:
                continue
            up = layer.getpixel((x, y - 1))[3] if y > 0 else 0
            left = layer.getpixel((x - 1, y))[3] if x > 0 else 0
            down = layer.getpixel((x, y + 1))[3] if y < h - 1 else 0
            right = layer.getpixel((x + 1, y))[3] if x < w - 1 else 0
            if not up or not left:
                out.putpixel((x, y), HI)
            elif not down or not right:
                out.putpixel((x, y), LO)
    return out


def quantise(im):
    """Every pixel one of the four tones (or clear): the game recolours by them."""
    tones = [HI, MID, LO, DEEP]
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if p[3] == 0:
                px[x, y] = CLEAR
            elif p not in tones:
                px[x, y] = min(tones, key=lambda c: sum((c[i] - p[i]) ** 2 for i in range(3)))
    return im


# ------------------------------------------------------------------ motions
def swipe(cv, t, cx, cy, ro, ri, a0, sweep, rev=False, c=CREAM, cut=True):
    front = sweep * ease(seg(t, 0, .45))
    back = sweep * ease(seg(t, .5, .95))
    if front - back > 1:
        cv.arc(cx, cy, ro, ri, a0 + back, front - back, c)
        if cut:
            cv.cutarc(cx, cy, (ro + ri) / 2, a0 + back + 6, max(0, front - back - 12), 2)
        cv.stripes(cx, cy, ri - 1, ri - 6, a0 + back, front - back, cv.B, 3)
    return a0 + front


def m_slash(cv, t):
    end = swipe(cv, t, 30, 46, 27, 19, 205, 135)
    ex, ey = 30 + 23 * math.cos(math.radians(end)), 46 + 23 * math.sin(math.radians(end))
    if t > .1:
        cv.bead(ex, ey, 3.5 * (1 - seg(t, .5, 1)) + 1, cv.A)
    cv.burst(t, ex, ey, .35, .5, 12, [CREAM, cv.A, cv.B], 'a')


def m_heavy_slash(cv, t):
    swipe(cv, t, 32, 44, 27, 18, 200, 140)
    swipe(cv, seg(t, .15, 1) if t > .15 else 0, 32, 20, 27, 18, 20, 140)
    if t > .4:
        e = eout(seg(t, .4, .9))
        for k in range(9):
            a = k * 20 - 80
            cv.disc(32 + math.cos(math.radians(a)) * 24 * e * 1.0, 52 + math.sin(math.radians(a)) * 5 * e,
                    max(1, round(3 * (1 - e)) + 1), cv.grade[k % 3], 'fine')
    cv.burst(t, 32, 32, .3, .5, 18, [CREAM, cv.A, cv.B], 'b', grav=.4)
    cv.halo(t, .35, 32, 32)


def m_claw(cv, t):
    for i in range(3):
        a = seg(t, i * .12, i * .12 + .32)
        b = seg(t, .5 + i * .06, .9)
        x0, y0 = 14 + i * 14, 8
        x1, y1 = 24 + i * 14, 54
        if a > 0:
            p0 = ease(b)
            p1 = ease(a)
            if p1 - p0 > .02:
                cv.line(x0 + (x1 - x0) * p0, y0 + (y1 - y0) * p0,
                        x0 + (x1 - x0) * p1, y0 + (y1 - y0) * p1, 6 - i, CREAM)
        if 0 < a < 1:
            cv.bead(x0 + (x1 - x0) * ease(a), y0 + (y1 - y0) * ease(a), 2.5, cv.A)
    cv.burst(t, 32, 34, .3, .5, 16, [CREAM, cv.A], 'c')
    cv.halo(t, .4, 32, 32)


def m_pierce(cv, t):
    tip = -6 + 52 * ease(seg(t, 0, .4))
    tail = tip - 34
    if t < .75:
        cv.line(max(2, tail), 32, tip, 32, 6, CREAM)
        cv.poly([(tip, 24), (tip + 10, 32), (tip, 40)], CREAM)
        cv.cutline(max(2, tail) + 2, 32, tip - 2, 32, 1)
    if t > .38:
        e = eout(seg(t, .38, .85))
        for k in range(8):
            a = math.radians(k * 45)
            r0, r1 = 8 + 4 * e, 8 + 20 * e
            cv.line(46 + math.cos(a) * r0, 32 + math.sin(a) * r0, 46 + math.cos(a) * r1,
                    32 + math.sin(a) * r1, 4 * (1 - e) + 1.5, CREAM)
        cv.bead(46, 32, 6 * (1 - seg(t, .5, 1)) + 1, cv.A)
    cv.burst(t, 46, 32, .4, .5, 14, [CREAM, cv.A, cv.B], 'd')
    cv.halo(t, .4, 46, 32)


def m_impact(cv, t):
    r = 11 * ease(seg(t, 0, .25)) * (1 - .5 * seg(t, .5, 1))
    if r > 1:
        cv.disc(32, 32, r, CREAM)
    e = ease(seg(t, .05, .45))
    shrink = 1 - seg(t, .55, 1)
    for k in range(8):
        a = math.radians(k * 45 + 22)
        r0, r1 = 11 + 2 * e, 11 + 15 * e
        if shrink > .05:
            cv.line(32 + math.cos(a) * r0, 32 + math.sin(a) * r0, 32 + math.cos(a) * r1,
                    32 + math.sin(a) * r1, 5 * shrink + 1, CREAM)
    a = seg(t, .1, .9)
    if 0 < a < 1:
        cv.ring(32, 32, 8 + 22 * eout(a), 8 + 22 * eout(a) - 3, cv.A, 'fine')
    cv.bead(32, 32, 6 * (1 - seg(t, .25, .7)), cv.A)
    cv.burst(t, 32, 32, .15, .6, 22, [CREAM, cv.A, cv.B], 'e', grav=.6)
    cv.halo(t, .2, 32, 32)


def m_whirl(cv, t):
    rot = 360 * t * 1.2
    f = ease(seg(t, 0, .2)) * (1 - ease(seg(t, .8, 1)))
    for k in range(3):
        cv.arc(32, 32, 26, 19, rot + k * 120, 85 * f, CREAM)
    cv.stripes(32, 32, 17, 11, -rot * 1.3, 240 * f, cv.B, 3)
    cv.bead(32, 32, 5 * f, cv.A)
    cv.burst(t, 32, 32, .2, .6, 20, [CREAM, cv.A], 'f')
    cv.halo(t, .3, 32, 32)


def arrow_at(cv, x, y, f=1.0):
    cv.line(x - 20, y, x, y, 3, CREAM)
    cv.poly([(x - 2, y - 6), (x + 9, y), (x - 2, y + 6)], CREAM)
    cv.slab(x - 24, y - 5, x - 17, y - 1, cv.A, 1)
    cv.slab(x - 24, y + 1, x - 17, y + 5, cv.A, 1)


def m_arrow(cv, t):
    x = -6 + 56 * ease(seg(t, 0, .6))
    if t < .65:
        arrow_at(cv, x, 32)
        cv.stripes(x - 20, 32, 14, 6, 0, 360, cv.B, 4)
    if t > .58:
        a = seg(t, .58, 1)
        cv.ring(50, 32, 4 + 12 * eout(a), 4 + 12 * eout(a) - 2, cv.A, 'fine')
    cv.burst(t, 50, 32, .58, .4, 14, [CREAM, cv.A], 'g', ang=(100, 260))
    cv.halo(t, .6, 50, 32, 20)


def m_volley(cv, t):
    for i, y in enumerate((16, 32, 48)):
        s = i * .08
        x = -6 + 56 * ease(seg(t, s, .55 + s))
        if t < .6 + s:
            arrow_at(cv, x, y)
        if t > .52 + s:
            a = seg(t, .52 + s, 1)
            cv.ring(50, y, 3 + 8 * eout(a), 3 + 8 * eout(a) - 2, cv.A, 'fine')
    cv.burst(t, 50, 32, .55, .45, 16, [CREAM, cv.A], 'h', ang=(100, 260))
    cv.halo(t, .6, 50, 32, 22)


def m_fireball(cv, t):
    p = ease(seg(t, 0, .6))
    x, y = 6 + 40 * p, 52 - 28 * p
    if t < .62:
        for k in range(1, 5):
            q = max(0, p - k * .06)
            cv.disc(6 + 40 * q, 52 - 28 * q, 6 - k, cv.grade[min(2, k // 2 + 1)], 'fine')
        cv.bead(x, y, 8, cv.grade[0])
    else:
        a = seg(t, .6, 1)
        e = eout(a)
        for k in range(12):
            ang = math.radians(k * 30)
            r = 4 + 20 * e
            cv.disc(46 + math.cos(ang) * r, 24 + math.sin(ang) * r,
                    max(1, round(5 * (1 - a))), cv.grade[k % 3], 'fine')
        cv.bead(46, 24, 9 * (1 - a) + 1, cv.grade[0])
        cv.ring(46, 24, 6 + 16 * e, 6 + 16 * e - 3, CREAM)
    cv.burst(t, 46, 24, .6, .4, 18, [CREAM, cv.A, cv.B], 'i', grav=.3)
    cv.halo(t, .62, 46, 24, 24)


def zig(cv, pts, w, c):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        cv.line(x0, y0, x1, y1, w, c)


def m_bolt(cv, t):
    on = (int(t * 12) % 2 == 0) or t > .55
    pts = [(10, 8), (30, 22), (22, 28), (46, 50)]
    k = ease(seg(t, 0, .4))
    n = max(1, int(round(k * 3 + .4)))
    if on and t < .85:
        zig(cv, pts[:n + 1], 5, CREAM)
        cv.cutline(pts[0][0], pts[0][1], pts[1][0], pts[1][1], 1)
    if t > .35:
        a = seg(t, .35, 1)
        cv.bead(46, 50, 8 * (1 - a) + 2, cv.A)
        cv.ring(46, 50, 4 + 14 * eout(a), 4 + 14 * eout(a) - 2, cv.B, 'fine')
    cv.burst(t, 46, 50, .35, .5, 14, [CREAM, cv.A, cv.B], 'j', plus=.6)
    cv.halo(t, .4, 46, 50, 22)


def m_lightning(cv, t):
    on = (int(t * 14) % 2 == 0) or t > .5
    k = ease(seg(t, 0, .3))
    pts = [(32, 0), (26, 14), (36, 24), (28, 38), (34, 52)]
    n = max(1, int(round(k * 4 + .4)))
    if on and t < .85:
        zig(cv, pts[:n + 1], 5, CREAM)
        if n >= 3:
            zig(cv, [(36, 24), (46, 30), (50, 42)], 3, CREAM)
        if n >= 2:
            zig(cv, [(26, 14), (16, 22), (14, 32)], 3, CREAM)
    if t > .3:
        a = seg(t, .3, 1)
        cv.bead(34, 52, 7 * (1 - a) + 2, cv.A)
        cv.ring(34, 56, 4 + 20 * eout(a), 4 + 20 * eout(a) - 2, cv.B, 'fine')
    cv.burst(t, 34, 52, .3, .5, 16, [CREAM, cv.A, cv.B], 'k', plus=.7, ang=(180, 360))
    cv.halo(t, .35, 34, 52, 22)


def m_meteor(cv, t):
    p = ease(seg(t, 0, .55))
    x, y = 4 + 40 * p, 0 + 44 * p
    if t < .58:
        for k in range(1, 6):
            q = max(0, p - k * .05)
            cv.line(4 + 40 * q, 44 * q, 4 + 40 * (q - .02), 44 * (q - .02), 7 - k, CREAM, 'fine')
        cv.bead(x, y, 9, cv.grade[0])
    else:
        a = seg(t, .58, 1)
        cv.slab(6, 52, 58, 56, CREAM, 2)
        cv.ring(44, 50, 4 + 18 * eout(a), 4 + 18 * eout(a) - 4, CREAM)
        cv.bead(44, 48, 10 * (1 - a) + 1, cv.grade[0])
    cv.burst(t, 44, 50, .56, .5, 20, [CREAM, cv.A, cv.B], 'l', grav=.9, ang=(200, 340))
    cv.halo(t, .6, 44, 50, 24)


def flame_at(cv, cx, base, h, w, c, sway):
    cv.disc(cx, base - w * .6, w, c)
    cv.poly([(cx - w, base - w * .6), (cx + sway, base - h), (cx + w, base - w * .6)], c)


def m_flame(cv, t):
    g = ease(seg(t, 0, .25)) * (1 - ease(seg(t, .8, 1)))
    for i, (cx, h, w) in enumerate(((20, 24, 7), (44, 28, 8), (32, 40, 11))):
        sw = math.sin(t * 12 + i * 2) * 4
        flame_at(cv, cx, 56, h * g, w * max(.2, g), CREAM, sw)
    flame_at(cv, 32, 54, 30 * g, 6 * max(.2, g), cv.grade[0], math.sin(t * 14) * 3)
    cv.slab(10, 56, 54, 59, CREAM, 2)
    cv.burst(t, 32, 40, .1, .8, 22, [cv.A, cv.B, CREAM], 'm', ang=(230, 310), plus=.15)
    cv.halo(t, .3, 32, 40, 22)


def m_frost(cv, t):
    g = ease(seg(t, 0, .45)) * (1 - ease(seg(t, .78, 1)))
    for k in range(6):
        a = math.radians(k * 60 + 30 * t)
        r = 24 * g
        cv.line(32, 32, 32 + math.cos(a) * r, 32 + math.sin(a) * r, 4, CREAM)
        cv.disc(32 + math.cos(a) * r, 32 + math.sin(a) * r, 3, cv.A)
        a2 = a + math.radians(26)
        cv.line(32 + math.cos(a) * r * .55, 32 + math.sin(a) * r * .55,
                32 + math.cos(a) * r * .55 + math.cos(a2) * 6 * g,
                32 + math.sin(a) * r * .55 + math.sin(a2) * 6 * g, 2, CREAM)
    cv.ring(32, 32, 9 * g + 1, 5 * g, CREAM)
    cv.bead(32, 32, 4 * g, cv.A)
    cv.stripes(32, 32, 20, 12, 0, 360, cv.B, 4)
    cv.burst(t, 32, 20, .2, .8, 12, [CREAM, cv.B], 'n', grav=.9, plus=.5, ang=(200, 340))
    cv.halo(t, .4, 32, 32, 24)


def m_splash(cv, t):
    g = ease(seg(t, 0, .35)) * (1 - ease(seg(t, .75, 1)))
    cv.arc(32, 58, 28 * g + 2, 20 * g, 200, 60, CREAM)
    cv.arc(32, 58, 28 * g + 2, 20 * g, 280, 60, CREAM)
    cv.arc(32, 58, 17 * g + 1, 10 * g, 215, 110, cv.A)
    cv.stripes(32, 58, 31 * g, 28 * g, 200, 140, cv.B, 2)
    cv.slab(8, 56, 56, 59, CREAM, 2)
    for k in range(7):
        a = seg(t, .22 + k * .02, .85)
        if 0 < a < 1:
            ang = math.radians(215 + k * 18)
            cv.disc(32 + math.cos(ang) * 26 * eout(a), 58 + math.sin(ang) * 30 * eout(a) + a * a * 22,
                    max(1, 3 * (1 - a) + 1), cv.grade[k % 3], 'fine')
    cv.burst(t, 32, 40, .25, .55, 16, [cv.A, cv.B, CREAM], 'o', grav=.8, ang=(200, 340))
    cv.halo(t, .3, 32, 50, 24)


def m_poison(cv, t):
    for k, (x, y0, r, s) in enumerate(((18, 54, 6, 0), (34, 56, 9, .12), (46, 52, 5, .2),
                                       (28, 58, 4, .3), (40, 58, 7, .38))):
        a = seg(t, s, s + .55)
        if 0 < a < 1:
            y = y0 - 40 * ease(a)
            xx = x + math.sin(a * 6 + k) * 3
            if a < .9:
                cv.ring(xx, y, r, r - 2.5, CREAM)
                cv.bead(xx, y, max(1, r * .45), cv.A)
            else:
                cv.burst(t, xx, y, t - .001, .12, 6, [CREAM, cv.A], f'p{k}', n=5)
    cv.slab(12, 58, 52, 60, cv.A, 1)
    cv.burst(t, 32, 40, .1, .8, 8, [cv.A, cv.B], 'q', ang=(230, 310), plus=0)
    cv.halo(t, .5, 32, 36, 22)


def m_smoke(cv, t):
    for k in range(7):
        s = k * .07
        a = seg(t, s, s + .6)
        if 0 < a < 1:
            r = 6 + 9 * eout(a)
            x = 32 + math.sin(k * 2.1) * 14 + a * (k - 3) * 3
            y = 52 - 36 * ease(a)
            cv.disc(x, y, r, CREAM if k % 2 == 0 else cv.B, 'fine')
            cv.ring(x, y, r, r - 2, shade(CREAM, .2), 'fine')
    # dither the smoke away
    fade_img(cv.fine, 0.0)
    cv.burst(t, 32, 40, .1, .8, 10, [cv.A, cv.B], 'r', ang=(230, 310), plus=0)
    cv.halo(t, .5, 32, 36, 22)


def m_wind(cv, t):
    for k in range(3):
        s = k * .1
        a = seg(t, s, s + .75)
        if 0 < a < 1:
            y = 18 + k * 14
            x1 = -6 + 70 * ease(a)
            x0 = x1 - 30
            cv.line(max(2, x0), y, min(62, x1), y, 4, CREAM)
            cv.arc(min(58, x1) , y - 5, 6, 3, 0, 270, CREAM)
            cv.cutline(max(2, x0) + 2, y, min(62, x1) - 6, y, 1)
    cv.burst(t, 6, 32, .05, .8, 36, [cv.A, cv.B, CREAM], 's', ang=(-30, 30), plus=0.1)
    cv.halo(t, .4, 32, 32, 24)


def m_quake(cv, t):
    g = ease(seg(t, 0, .4))
    out = 1 - ease(seg(t, .8, 1))
    pts = [(32, 46), (24, 50), (18, 46), (10, 52), (4, 48)]
    pts2 = [(32, 46), (40, 50), (46, 46), (54, 52), (60, 48)]
    n = max(1, int(round(g * 4)))
    if out > .1:
        zig(cv, pts[:n + 1], 4, CREAM)
        zig(cv, pts2[:n + 1], 4, CREAM)
    for k, (x, s) in enumerate(((16, 0), (32, .05), (46, .1))):
        a = seg(t, .15 + s, .8)
        if 0 < a < 1:
            y = 46 - 18 * math.sin(a * math.pi)
            cv.slab(x - 6, y - 8, x + 6, y + 4, CREAM, 2)
            cv.cutline(x - 5, y - 2, x + 5, y - 2, 1)
    a = seg(t, .1, .9)
    if 0 < a < 1:
        cv.arc(32, 46, 6 + 24 * eout(a), 3 + 24 * eout(a), 190, 160, cv.A)
    cv.burst(t, 32, 46, .1, .6, 22, [CREAM, cv.A, cv.B], 't', grav=.9, ang=(200, 340))
    cv.halo(t, .2, 32, 46, 24)


def m_void_rift(cv, t):
    o = ease(seg(t, 0, .4)) * (1 - ease(seg(t, .78, 1)))
    h = 16 * o
    if o > .05:
        cv.arc(32, 32 + h * 1.2, 26 + 2, 18, 232, 76, CREAM)
        cv.arc(32, 32 - h * 1.2, 26 + 2, 18, 52, 76, CREAM)
        cv.bead(32, 32, 8 * o + 1, cv.A, DARK)
        cv.cutline(46, 12, 18, 52, 2)
        cv.stripes(32, 32, 30, 24, 0, 360, cv.B, 3)
    cv.burst(t, 32, 32, .1, .7, 34, [cv.A, cv.B, CREAM], 'u', inward=True, plus=.2)
    cv.halo(t, .5, 32, 32, 26)


def m_drain(cv, t):
    for k in range(10):
        s = k * .05
        a = seg(t, s, s + .55)
        if 0 < a < 1:
            ang = math.radians(k * 36 + 220 * a)
            r = 26 * (1 - ease(a))
            cv.disc(32 + math.cos(ang) * r, 32 + math.sin(ang) * r, max(1, 4 * (1 - a) + 1),
                    cv.grade[k % 3], 'fine')
            cv.arc(32, 32, r + 3, r, math.degrees(ang) - 30, 30, CREAM, caps=False)
    g = ease(seg(t, .4, .75)) * (1 - ease(seg(t, .85, 1)))
    cv.bead(32, 32, 9 * g, cv.A, DARK)
    cv.ring(32, 32, 12 * g + 1, 9 * g, CREAM)
    cv.burst(t, 32, 32, .3, .6, 20, [cv.A, cv.B, CREAM], 'v', inward=True)
    cv.halo(t, .7, 32, 32, 24)


def m_shadow(cv, t):
    x = 10 + 32 * ease(seg(t, 0, .6))
    for k in range(4, -1, -1):
        xx = x - k * 8
        if xx < 6:
            continue
        sub = Image.new('RGBA', (FR, FR), CLEAR)
        keep = cv.main
        cv.main = sub
        cv.slab(xx - 6, 10, xx + 6, 54, CREAM if k == 0 else cv.B, 5)
        if k == 0:
            cv.cutline(xx, 14, xx, 50, 2)
        cv.main = keep
        fade_img(sub, 0.0 if k == 0 else min(.85, .2 + k * .16))
        cv.fine.alpha_composite(sub)
    out = ease(seg(t, .75, 1))
    cv.bead(x, 20, 3.5 * (1 - out) + .8, cv.A, DARK)
    cv.burst(t, x, 36, .1, .7, 18, [cv.B, cv.A, CREAM], 'w', ang=(150, 210))
    cv.halo(t, .5, x, 36, 22)


def m_radiance(cv, t):
    g = ease(seg(t, 0, .35)) * (1 - ease(seg(t, .8, 1)))
    for k in range(12):
        a = math.radians(k * 30 + 20 * t)
        r0, r1 = 12 * g + 4, 12 + 16 * g * (1.1 if k % 2 else .8)
        cv.line(32 + math.cos(a) * r0, 32 + math.sin(a) * r0, 32 + math.cos(a) * r1,
                32 + math.sin(a) * r1, 3.5 if k % 2 == 0 else 2.5, CREAM)
    cv.ring(32, 32, 13 * g + 1, 9 * g, CREAM)
    cv.bead(32, 32, 7 * g, cv.A)
    cv.burst(t, 32, 32, .2, .7, 22, [CREAM, cv.A, cv.B], 'x', plus=.8)
    cv.halo(t, .3, 32, 32, 26)


def m_holy_fire(cv, t):
    g = ease(seg(t, 0, .3)) * (1 - ease(seg(t, .8, 1)))
    flame_at(cv, 32, 52, 38 * g, 11 * max(.2, g), CREAM, math.sin(t * 10) * 3)
    flame_at(cv, 32, 50, 24 * g, 6 * max(.2, g), cv.A, math.sin(t * 12) * 2)
    cv.ring(32, 14, 14 * g + 1, 11 * g, cv.B, 'fine')
    cv.line(32, 4, 32, 24, 3 * g + .5, CREAM)
    cv.line(23, 12, 41, 12, 3 * g + .5, CREAM)
    cv.slab(14, 52, 50, 56, CREAM, 2)
    cv.burst(t, 32, 40, .1, .8, 22, [cv.B, cv.A, CREAM], 'y', ang=(230, 310), plus=.5)
    cv.halo(t, .3, 32, 32, 24)


def m_heal(cv, t):
    g = ease(seg(t, 0, .35)) * (1 - ease(seg(t, .8, 1)))
    cv.slab(32 - 6 * g, 32 - 22 * g, 32 + 6 * g, 32 + 22 * g, CREAM, 4)
    cv.slab(32 - 22 * g, 32 - 6 * g, 32 + 22 * g, 32 + 6 * g, CREAM, 4)
    cv.cutline(32, 32 - 20 * g, 32, 32 + 20 * g, 1)
    cv.bead(32, 32, 5 * g, cv.A)
    for k, (dx, dy) in enumerate(((-17, -17), (17, -17), (-17, 17), (17, 17))):
        a = seg(t, .25 + k * .05, .8)
        if 0 < a < 1:
            cv.bead(32 + dx, 32 + dy, 4 * math.sin(a * math.pi) + .5, cv.grade[k % 3])
    cv.burst(t, 32, 44, .2, .75, 14, [cv.A, cv.B, CREAM], 'z', ang=(250, 290), plus=1.0)
    cv.halo(t, .35, 32, 32, 26)


def m_shield(cv, t):
    g = ease(seg(t, 0, .4))
    out = 1 - ease(seg(t, .85, 1))
    if out > .1:
        cv.arc(32, 44, 24, 16, 180 + 90 * (1 - g), 180 * g, CREAM)
        if g > .5:
            cv.slab(8, 44, 15, 56, CREAM, 3)
            cv.slab(49, 44, 56, 56, CREAM, 3)
            cv.slab(8, 58, 56, 61, CREAM, 2)
        for k in range(3):
            if g > .3 + k * .15:
                a = math.radians(205 + k * 65)
                cv.bead(32 + math.cos(a) * 20, 44 + math.sin(a) * 20, 3, cv.grade[k])
    a = seg(t, .4, .95)
    if 0 < a < 1:
        cv.arc(32, 44, 14 + 20 * eout(a), 14 + 20 * eout(a) - 3, 180, 180, cv.A, 'fine')
    cv.stripes(32, 44, 14, 8, 180, 180 * g, cv.B, 3)
    cv.burst(t, 32, 28, .35, .5, 14, [CREAM, cv.A, cv.B], 'aa', ang=(180, 360))
    cv.halo(t, .4, 32, 40, 26)


def m_stone_shield(cv, t):
    slabs = [(10, 50, 54, 58), (14, 38, 50, 47), (20, 26, 44, 35)]
    for k, (x0, y0, x1, y1) in enumerate(slabs):
        s = k * .16
        a = seg(t, s, s + .25)
        if a <= 0:
            continue
        drop = (1 - eout(a)) * 40
        bounce = math.sin(seg(t, s + .25, s + .4) * math.pi) * 3
        if seg(t, .85, 1) < .95:
            cv.slab(x0, y0 - drop - bounce, x1, y1 - drop - bounce, CREAM, 3)
            cv.slab(x0 + 3, y0 + 2 - drop - bounce, x1 - 3, y0 + 3 - drop - bounce, cv.B, 0, 'fine')
        if 0 < seg(t, s + .25, s + .6) < 1:
            q = seg(t, s + .25, s + .6)
            cv.disc(x0 - 2 - 8 * q, y1 - 2, max(1, 3 * (1 - q)), CREAM, 'fine')
            cv.disc(x1 + 2 + 8 * q, y1 - 2, max(1, 3 * (1 - q)), CREAM, 'fine')
    if t > .5:
        cv.bead(32, 22, 4 * (1 - seg(t, .7, 1)) + 1, cv.A)
    cv.burst(t, 32, 54, .3, .5, 16, [CREAM, cv.A, cv.B], 'ab', grav=.7, ang=(190, 350))
    cv.halo(t, .6, 32, 40, 26)


def m_mana(cv, t):
    g = ease(seg(t, 0, .25)) * (1 - ease(seg(t, .85, 1)))
    cv.ring(32, 32, 20 * g + 1, 15 * g, CREAM)
    cv.stripes(32, 32, 13 * g, 7 * g, 360 * t, 220, cv.B, 3)
    for k in range(3):
        a = math.radians(360 * t * 1.3 + k * 120)
        cv.bead(32 + math.cos(a) * 17 * g, 32 + math.sin(a) * 17 * g, 4 * g, cv.grade[k])
    cv.bead(32, 32, 5 * g, cv.A)
    cv.burst(t, 32, 32, .15, .8, 18, [cv.A, cv.B, CREAM], 'ac', plus=.9)
    cv.halo(t, .4, 32, 32, 26)


def m_shout(cv, t):
    cv.slab(2, 24, 14, 40, CREAM, 5)
    cv.slab(5, 28, 11, 36, cv.A, 2, 'fine')
    for k in range(3):
        s = k * .14
        a = seg(t, s, s + .55)
        if 0 < a < 1:
            r = 8 + 36 * eout(a)
            cv.arc(10, 32, r + 4, r - 3 * (1 - a) - 1, -48, 96, CREAM if k != 1 else cv.A)
            cv.cutarc(10, 32, r + 1, -36, 72, 1)
    cv.stripes(10, 32, 44, 30, -40, 80, cv.B, 4)
    cv.burst(t, 16, 32, .1, .8, 20, [CREAM, cv.A, cv.B], 'ad', ang=(-35, 35), plus=.1)
    cv.halo(t, .35, 28, 32, 26)


def m_stun(cv, t):
    g = ease(seg(t, 0, .2)) * (1 - ease(seg(t, .85, 1)))
    cv.ring(32, 30, 18 * g + 1, 13 * g, CREAM)
    for k in range(3):
        a = math.radians(360 * t * 1.5 + k * 120)
        cv.bead(32 + math.cos(a) * 18 * g, 30 + math.sin(a) * 9 * g, 4 * g, cv.grade[k])
    zig(cv, [(22, 48), (28, 42), (24, 38), (32, 32)], 3 * g + .5, CREAM)
    cv.burst(t, 32, 30, .1, .8, 16, [cv.A, cv.B, CREAM], 'st', plus=.9, ang=(200, 340))
    cv.halo(t, .3, 32, 30, 24)


def m_weaken(cv, t):
    g = ease(seg(t, 0, .35))
    out = 1 - ease(seg(t, .85, 1))
    if out > .1:
        cv.slab(26, 8, 38, 36 * g + 8, CREAM, 3)
        cv.poly([(14, 36 * g + 6), (50, 36 * g + 6), (32, 36 * g + 28)], CREAM)
        cv.cutline(32, 12, 32, 36 * g + 8, 2)
    cv.stripes(32, 48, 18, 8, 0, 360, cv.B, 3)
    cv.burst(t, 32, 44, .3, .7, 20, [cv.A, cv.B, CREAM], 'wk', grav=.9, ang=(40, 140))
    cv.halo(t, .4, 32, 44, 24)


def m_crit(cv, t):
    g = ease(seg(t, 0, .2)) * (1 - ease(seg(t, .75, 1)))
    for k in range(12):
        a = math.radians(k * 30)
        r1 = 8 + (24 if k % 2 == 0 else 15) * g
        cv.line(32 + math.cos(a) * 6, 32 + math.sin(a) * 6, 32 + math.cos(a) * r1, 32 + math.sin(a) * r1,
                4 if k % 2 == 0 else 3, CREAM)
    cv.disc(32, 32, 9 * g + 1, CREAM)
    cv.bead(32, 32, 6 * g, cv.A)
    for q in (0, .12):
        a = seg(t, .1 + q, .8)
        if 0 < a < 1:
            cv.ring(32, 32, 6 + 24 * eout(a), 6 + 24 * eout(a) - 3, cv.B if q else cv.A, 'fine')
    cv.burst(t, 32, 32, .1, .6, 30, [CREAM, cv.A, cv.B], 'cr', plus=.7, grav=.4)
    cv.halo(t, .2, 32, 32, 26)


def m_miss(cv, t):
    p = ease(seg(t, 0, .7))
    cv.arc(30, 40, 24, 21, 215, 100 * p, CREAM)
    cv.arc(30, 40, 24, 21, 215 + 100 * max(0, p - .5), 100 * min(p, .5), CREAM, 'fine')
    cv.stripes(30, 40, 20, 12, 215, 110 * p, cv.B, 3)
    for k in range(3):
        a = seg(t, .3 + k * .1, 1)
        if 0 < a < 1:
            cv.disc(44 + k * 5, 28 - a * 12 + k * 2, max(1, 3 * (1 - a)), CREAM, 'fine')
    cv.burst(t, 46, 32, .35, .6, 10, [CREAM, cv.A], 'ms', ang=(-60, 60), plus=0)


def m_phase(cv, t):
    g = ease(seg(t, 0, .4)) * (1 - ease(seg(t, .8, 1)))
    for k in range(8):
        a = math.radians(k * 45 + 40 * t)
        r0, r1 = 10 + 8 * g, 14 + 14 * g
        cv.slab(32 + math.cos(a) * r0 - 4, 32 + math.sin(a) * r0 - 4, 32 + math.cos(a) * r1 + 4,
                32 + math.sin(a) * r1 + 4, CREAM, 3)
    cv.ring(32, 32, 10 * g + 1, 6 * g, CREAM)
    cv.bead(32, 32, 7 * g, cv.A, DARK)
    for q in (0, .18):
        a = seg(t, .2 + q, .95)
        if 0 < a < 1:
            cv.ring(32, 32, 8 + 26 * eout(a), 8 + 26 * eout(a) - 3, cv.A if q == 0 else cv.B, 'fine')
    cv.burst(t, 32, 32, .2, .7, 24, [cv.A, cv.B, CREAM], 'ph', plus=.4)
    cv.halo(t, .4, 32, 32, 26)




def m_shout2(cv, t):
    """A shout from the middle: a mouth slab, fat arcs radiating both ways."""
    cv.slab(26, 24, 38, 40, CREAM, 5)
    cv.slab(29, 28, 35, 36, cv.A, 2, 'fine')
    for k in range(3):
        s = k * .14
        a = seg(t, s, s + .55)
        if 0 < a < 1:
            r = 6 + 24 * eout(a)
            for sgn, a0 in ((1, -48), (-1, 132)):
                cv.arc(32, 32, r + 4, r - 3 * (1 - a) - 1, a0, 96, CREAM if k != 1 else cv.A)
                cv.cutarc(32, 32, r + 1, a0 + 12, 72, 1)
    cv.stripes(32, 32, 34, 22, -40, 80, cv.B, 4)
    cv.stripes(32, 32, 34, 22, 140, 80, cv.B, 4)
    cv.burst(t, 32, 32, .1, .8, 20, [CREAM, cv.A, cv.B], 'ad', ang=(-35, 35), plus=.1)
    cv.burst(t, 32, 32, .1, .8, 20, [CREAM, cv.A, cv.B], 'ae', ang=(145, 215), plus=.1)


# ---- the strips that are not a skill's own motion: what flies, lands, shakes
def s_arrow_proj(cv, i):
    x = 46
    cv.line(x - 20, 32, x, 32, 3.4, CREAM)
    cv.poly([(x - 2, 25), (x + 9, 32), (x - 2, 39)], CREAM)
    cv.slab(x - 24, 27, x - 17, 31, HI, 1)
    cv.slab(x - 24, 33, x - 17, 37, HI, 1)
    for k, ln in enumerate((16 + (i % 2) * 5, 10 + (i % 3) * 3)):
        cv.slab(x - 26 - ln, 22 + k * 20, x - 28, 24 + k * 20, LO, 1, 'fine')
    cv.stripes(x - 22, 32, 10, 5, 0, 360, LO, 4)
    cv.burst(i / 2, x - 28, 32, 0, .9, 12, [HI, MID], 'ap', n=5, ang=(150, 210), plus=0)


def s_orb(cv, i):
    cx = 42.7
    for g in range(1, 6):
        cv.disc(cx - g * 5.5, 32 + round(math.sin(g + i * 1.6) * 3), max(1.3, 7 - g * 1.1),
                MID if g < 3 else LO, 'fine')
    cv.bead(cx, 32, 9, HI)
    for k in range(5):
        a = i * 1.5 + k * 1.26
        cv.dust(cv.X(cx + math.cos(a) * 13), cv.Y(32 + math.sin(a) * 13), 1 + (k % 2), HI if k % 2 else MID)


def s_meteor_proj(cv, i):
    for g in range(1, 7):
        cv.line(32 - g * 2.5 + (i + g) % 2 * 2, 40 - g * 6, 32 - g * 2.5 + (i + g) % 2 * 2, 40 - g * 6 - 4,
                max(1, 9 - g * 1.2), MID if g < 4 else LO, 'fine')
    cv.bead(32, 40, 10, HI, DEEP)
    cv.stripes(32, 40, 15, 12, 180, 180, LO, 2)
    for k in range(5):
        cv.dust(cv.X(32 + (k - 2) * 5 + (i % 2)), cv.Y(24 - (k % 3) * 5 - i * 2), 2 if k % 2 else 1, HI if k % 2 else MID)


def s_impact_s(cv, t):
    r = 7 * ease(seg(t, 0, .3)) * (1 - .5 * seg(t, .5, 1))
    if r > 1:
        cv.disc(32, 32, r, CREAM)
    e = ease(seg(t, .05, .45))
    shrink = 1 - seg(t, .55, 1)
    for k in range(8):
        a = math.radians(k * 45 + 22)
        r0, r1 = 7 + 2 * e, 7 + 11 * e
        if shrink > .05:
            cv.line(32 + math.cos(a) * r0, 32 + math.sin(a) * r0, 32 + math.cos(a) * r1,
                    32 + math.sin(a) * r1, 3.6 * shrink + 1, CREAM)
    a = seg(t, .1, .9)
    if 0 < a < 1:
        cv.ring(32, 32, 6 + 16 * eout(a), 6 + 16 * eout(a) - 2.5, MID, 'fine')
    cv.bead(32, 32, 4.5 * (1 - seg(t, .25, .7)), HI)
    cv.burst(t, 32, 32, .15, .6, 12, [HI, MID], 'is', n=14, grav=.6)


def s_zap(cv, t):
    for b in range(5):
        a = b * 2 * math.pi / 5 + .4 + (int(t * 7) % 2) * .5
        pts = [(32, 32)]
        r = 0
        rnd = random.Random(f'zap{b}{int(t * 7)}')
        while r < 26:
            r += 5 + rnd.random() * 5
            aa = a + (rnd.random() - .5) * .9
            pts.append((32 + math.cos(aa) * r, 32 + math.sin(aa) * r))
        for p0, p1 in zip(pts, pts[1:]):
            cv.line(p0[0], p0[1], p1[0], p1[1], 3.4 if t < .5 else 2.4, CREAM)
    cv.bead(32, 32, 7 * (1 - t) + 3, HI)
    cv.ring(32, 32, 7 + 16 * eout(t), 7 + 16 * eout(t) - 2.5, MID, 'fine')
    cv.burst(t, 32, 32, .05, .6, 18, [HI, MID, LO], 'zp', plus=.7)


def s_explosion(cv, t):
    a = clamp(t)
    e = eout(a)
    for k in range(12):
        ang = math.radians(k * 30 + 12 * a)
        r = 6 + 22 * e
        cv.disc(32 + math.cos(ang) * r, 32 + math.sin(ang) * r, max(1.3, round(6 * (1 - a * .8))),
                [HI, MID, HI][k % 3], 'fine')
    cv.ring(32, 32, 8 + 20 * e, 8 + 20 * e - 4 * (1 - a) - 1.5, CREAM)
    cv.bead(32, 32, 11 * (1 - a * .8) + 1, HI)
    cv.stripes(32, 32, 5 + 20 * e, 2 + 12 * e, 0, 360, LO, 3)
    cv.burst(t, 32, 32, 0, .8, 24, [HI, MID, LO], 'ex', n=22, grav=.4)


def s_shock(cv, t):
    e = ease(seg(t, 0, .8))
    rx = 6 + 30 * e
    ry = max(3, rx / 3)
    n = 18
    for k in range(n):
        a = k * 2 * math.pi / n
        cv.disc(32 + math.cos(a) * rx, 50 + math.sin(a) * ry, max(1.2, 3.4 * (1 - e * .7)),
                HI if k % 2 else MID, 'fine')
    for sgn in (-1, 1):
        cv.line(32, 50, 32 + sgn * rx * .9, 50 + ry * .4, 3.4 * (1 - e * .5) + 1, CREAM)
    cv.burst(t, 32, 50, .05, .7, 16, [HI, MID], 'sk', grav=.9, ang=(210, 330), plus=.2)


def draw_frame(fn, i, n, tag, target=(32, 32), anchor=(24, 24), loop=False):
    cv = Cv(tag, target, anchor)
    t = i / (N - 1) if not loop else i
    fn(cv, t)
    out = Image.new('RGBA', (FR, FR), CLEAR)
    out.alpha_composite(bevel(cv.main))
    out.alpha_composite(cv.fine)
    out.alpha_composite(cv.top)
    if not loop and i == n - 1:
        fade_img(out, .8)
    elif not loop and i == n - 2:
        fade_img(out, .35)
    return quantise(out)


# name: (frames, motion, target in the 64 px space, the strip pixel it lands on, loops)
STRIPS = {
    # strikes
    'slash': (N, m_slash, (30, 34), (24, 24), False),
    'heavy': (N, m_heavy_slash, (32, 36), (24, 24), False),
    'claw': (N, m_claw, (36, 31), (24, 24), False),
    'pierce': (N, m_pierce, (46, 32), (24, 24), False),
    'impact': (N, m_impact, (32, 32), (24, 24), False),
    'whirl': (N, m_whirl, (32, 32), (24, 24), False),
    # projectiles (loops), landings
    'arrow_proj': (3, s_arrow_proj, (32, 32), (24, 24), True),
    'orb': (4, s_orb, (32, 32), (24, 24), True),
    'meteor_proj': (4, s_meteor_proj, (32, 40), (24, 30), True),
    'impact_s': (N, s_impact_s, (32, 32), (24, 24), False),
    'zap': (N, s_zap, (32, 32), (24, 24), False),
    'explosion': (N, s_explosion, (32, 32), (24, 24), False),
    # elements
    'flame': (N, m_flame, (32, 52), (24, 40), False),
    'frost': (N, m_frost, (32, 32), (24, 24), False),
    'lightning': (N, m_lightning, (34, 52), (24, 40), False),
    'holy_beam': (N, m_holy_fire, (32, 50), (24, 40), False),
    'splash': (N, m_splash, (32, 52), (24, 32), False),
    'poison': (N, m_poison, (32, 44), (24, 32), False),
    'smoke': (N, m_smoke, (32, 40), (24, 36), False),
    'wind': (N, m_wind, (32, 32), (24, 24), False),
    'quake': (N, m_quake, (32, 46), (24, 34), False),
    'void_rift': (N, m_void_rift, (32, 32), (24, 24), False),
    'drain': (N, m_drain, (32, 32), (24, 24), False),
    'shadow': (N, m_shadow, (30, 44), (24, 40), False),
    'radiance': (N, m_radiance, (32, 32), (24, 24), False),
    # support
    'heal': (N, m_heal, (32, 32), (24, 28), False),
    'shield': (N, m_shield, (32, 38), (24, 26), False),
    'stone_shield': (N, m_stone_shield, (32, 44), (24, 32), False),
    'mana': (N, m_mana, (32, 32), (24, 26), False),
    'shout': (N, m_shout2, (32, 32), (24, 26), False),
    # states
    'stun': (N, m_stun, (32, 30), (24, 14), False),
    'weaken': (N, m_weaken, (32, 36), (24, 24), False),
    'crit': (N, m_crit, (32, 32), (24, 24), False),
    'miss': (N, m_miss, (34, 30), (24, 24), False),
    'phase': (N, m_phase, (32, 32), (24, 24), False),
    # tiers
    'shock': (N, s_shock, (32, 50), (24, 38), False),
}


def make(name):
    n, fn, target, anchor, loop = STRIPS[name]
    out = Image.new('RGBA', (FR * n, FR), CLEAR)
    for i in range(n):
        out.alpha_composite(draw_frame(fn, i, n, name, target, anchor, loop), (i * FR, 0))
    return out


def main():
    import sys
    os.makedirs(OUT, exist_ok=True)
    for name in STRIPS:
        make(name).save(os.path.join(OUT, 'vfx_' + name + '.png'), optimize=True)
    print('drew', len(STRIPS), 'strips in', os.path.normpath(OUT))


if __name__ == '__main__':
    main()
