#!/usr/bin/env python3
"""Draws the game's small pixel animations as sprite strips.

    python3 tool/gen_pixel_fx.py

Each strip is one row of square frames in assets/visuals/pixel_fx/, drawn
with no antialiasing in a few flat colours and faded by dithering, so it
reads as pixel art at any integer scale. PixelStrip (lib/widgets/
pixel_sprite.dart) plays them: the frame size is the strip's height.

  die_<kind>     the burst of a landed die face, 40 px, 8 frames
  el_<element>   an element's tint over it, 40 px, 8 frames
  kw_<word>      a rule word's flourish, 40 px, 8 frames
  die_surge, die_curse, die_glint   special landings, 40 px, 8 frames
  moment_seal    a place stamped on the map, 48 px, 10 frames
  campfire       a camp fire's flame, 18 px, 6 frames (loops)
  chest_<tier>   a chest bursting open in its tier's light, 48 px, 8 frames
"""
import math
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'visuals', 'pixel_fx')
os.makedirs(OUT, exist_ok=True)

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def rgb(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def new(size):
    im = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def fade(im, amount):
    """Dither [im] away: amount 0 keeps it, 1 is gone."""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] and BAYER[y % 4][x % 4] / 16 < amount:
                px[x, y] = (0, 0, 0, 0)
    return im


def dot(d, x, y, c, w=1):
    d.rectangle([round(x), round(y), round(x) + w - 1, round(y) + w - 1], fill=c)


def ring(d, cx, cy, r, c, w=1):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=c, width=w)


def disc(d, cx, cy, r, c):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c)


def line(d, a, b, c, w=1):
    d.line([round(a[0]), round(a[1]), round(b[0]), round(b[1])], fill=c, width=w)


def hash01(i, salt):
    x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453
    return x - math.floor(x)


def strip(name, frames):
    s = frames[0].width
    out = Image.new('RGBA', (s * len(frames), s), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, (i * s, 0))
    out.save(os.path.join(OUT, name + '.png'), optimize=True)


N = 8
S = 40
C = S // 2


def ease(t):
    return 1 - (1 - t) ** 3


# ------------------------------------------------------------ dice kinds
def die_strike(i):
    t = i / (N - 1)
    im, d = new(S)
    flash, ringc, hot, blood = rgb('#FFE08A'), rgb('#FFB04D'), rgb('#FF8A3D'), rgb('#E53935')
    if i < 4:
        f = Image.new('RGBA', (S, S), (0, 0, 0, 0)); fd = ImageDraw.Draw(f)
        disc(fd, C, C, 4 + i * 3, hot)
        im.alpha_composite(fade(f, 0.45 + i * .12))
    ring(d, C, C, 6 + round(ease(t) * 12), ringc, 2 if t < .5 else 1)
    for k in range(12):
        a = k * 2 * math.pi / 12 + hash01(k, 1) * .5
        r0 = 7 + ease(t) * (7 + hash01(k, 2) * 5)
        r1 = r0 + 3 * (1 - t) + 1
        line(d, (C + math.cos(a) * r0, C + math.sin(a) * r0), (C + math.cos(a) * r1, C + math.sin(a) * r1), flash if k % 2 == 0 else blood)
    return fade(im, max(0, t - .55) * 2.1)


def die_ward(i):
    t = i / (N - 1)
    im, d = new(S)
    steel, pale = rgb('#9FC2D6'), rgb('#E6F3FA')
    rad = 7 + ease(t) * 12
    pts = [(C + math.cos(k * math.pi / 3 + math.pi / 6) * rad, C + math.sin(k * math.pi / 3 + math.pi / 6) * rad) for k in range(6)]
    d.polygon([(round(x), round(y)) for x, y in pts], outline=steel, width=2 if t < .5 else 1)
    if t < .7:
        f = Image.new('RGBA', (S, S), (0, 0, 0, 0)); fd = ImageDraw.Draw(f)
        disc(fd, C, C, round(rad * .75), rgb('#90B4C8'))
        im.alpha_composite(fade(f, .55 + t * .4))
    for k in (0, 2, 4):
        dot(d, *pts[k], pale, 2)
    return fade(im, max(0, t - .5) * 2)


def die_bloom(i):
    t = i / (N - 1)
    im, d = new(S)
    for k in range(8):
        x = C + (hash01(k, 3) - .5) * 26 + math.sin(t * 5 + k) * 2
        y = C + 6 - ease(t) * (14 + hash01(k, 4) * 8) - hash01(k, 5) * 4
        c = rgb('#F48FB1') if k % 2 == 0 else rgb('#EAF7EA')
        d.point([(round(x), round(y)), (round(x) - 1, round(y)), (round(x) + 1, round(y)), (round(x), round(y) - 1), (round(x), round(y) + 1)], fill=c)
    f = Image.new('RGBA', (S, S), (0, 0, 0, 0)); fd = ImageDraw.Draw(f)
    disc(fd, C, C, 11, rgb('#EC407A'))
    im.alpha_composite(fade(f, .7 + t * .3))
    return fade(im, max(0, t - .5) * 2)


def die_arcs(i):
    t = i / (N - 1)
    im, d = new(S)
    for k in range(8):
        a = k * math.pi / 4 + t * 4
        r = 8 + ease(t) * 11
        x, y = C + math.cos(a) * r, C + math.sin(a) * r * .7 - t * 6
        dot(d, x, y, rgb('#64B5F6') if k % 2 == 0 else rgb('#BBDEFB'), 2)
    ring(d, C, C, 7 + round(ease(t) * 12), rgb('#64B5F6'))
    return fade(im, max(0, t - .45) * 1.9)


def die_miasma(i):
    t = i / (N - 1)
    im, d = new(S)
    f = Image.new('RGBA', (S, S), (0, 0, 0, 0)); fd = ImageDraw.Draw(f)
    fd.ellipse([C - 6 - round(t * 10), C, C + 6 + round(t * 10), C + 12], fill=rgb('#43A047'))
    im.alpha_composite(fade(f, .55 + t * .4))
    for k in range(7):
        x = C + (hash01(k, 6) - .5) * 22
        kk = max(0, min(1, (t - hash01(k, 7) * .3) / .7))
        y = C + 8 - kk * 20
        if 0 < kk < 1:
            ring(d, x, y, 1 + round(kk * 2), rgb('#81C784'))
    return fade(im, max(0, t - .55) * 2.1)


def die_shock(i):
    t = i / (N - 1)
    im, d = new(S)
    if t < .4:
        f = Image.new('RGBA', (S, S), (0, 0, 0, 0)); fd = ImageDraw.Draw(f)
        disc(fd, C, C, 12, rgb('#FFC107'))
        im.alpha_composite(fade(f, .4 + t * 1.2))
    for k in range(4):
        a = k * math.pi / 2 + hash01(k, 8)
        pts = [(C, C)]
        for j in range(1, 5):
            r = (4 + 4 * j) * (.5 + ease(t) * .5)
            jag = (3 if j % 2 == 0 else -3)
            pts.append((C + math.cos(a) * r - math.sin(a) * jag, C + math.sin(a) * r + math.cos(a) * jag))
        d.line([(round(x), round(y)) for x, y in pts], fill=rgb('#FFE082'), width=1)
    return fade(im, max(0, t - .35) * 1.6)


def die_drain(i):
    t = i / (N - 1)
    im, d = new(S)
    ring(d, C, C, max(2, 18 - round(ease(t) * 12)), rgb('#AB47BC'), 2 if t < .5 else 1)
    for k in range(8):
        a = k * math.pi / 4 - t * 5
        r = (16 - ease(t) * 12)
        dot(d, C + math.cos(a) * r, C + math.sin(a) * r, rgb('#CE93D8'), 2)
    return fade(im, max(0, t - .5) * 2)


def die_fizzle(i):
    t = i / (N - 1)
    im, d = new(S)
    f = Image.new('RGBA', (S, S), (0, 0, 0, 0)); fd = ImageDraw.Draw(f)
    for k in range(6):
        a = k * math.pi / 3 + hash01(k, 9)
        r = 6 + ease(t) * 9
        disc(fd, C + math.cos(a) * r, C + math.sin(a) * r, 2 + round(t * 2), rgb('#9E9E9E'))
    im.alpha_composite(fade(f, .35 + t * .6))
    return im


# --------------------------------------------------------------- elements
def el_fire(i):
    t = i / (N - 1)
    im, d = new(S)
    for k in range(9):
        x = C + (hash01(k, 11) - .5) * 24
        y = C + 10 - t * (14 + hash01(k, 12) * 12)
        dot(d, x, y, rgb('#FF7043') if k % 3 else rgb('#FFD54F'), 2 if k % 3 == 0 else 1)
    return fade(im, max(0, t - .45) * 1.8)


def el_water(i):
    t = i / (N - 1)
    im, d = new(S)
    for k in range(6):
        x = C + (hash01(k, 13) - .5) * 22
        y = C - 14 + t * 28 * (.7 + hash01(k, 14) * .5)
        d.line([round(x), round(y), round(x), round(y) + 2], fill=rgb('#4FC3F7'))
        dot(d, x, y + 3, rgb('#B3E5FC'))
    return fade(im, max(0, t - .5) * 2)


def el_wind(i):
    t = i / (N - 1)
    im, d = new(S)
    for k in range(3):
        r = 9 + k * 4
        d.arc([C - r, C - r, C + r, C + r], math.degrees(t * 7 + k * 2), math.degrees(t * 7 + k * 2 + 1.6), fill=rgb('#A5D6C8'))
    return fade(im, max(0, t - .5) * 2)


def el_earth(i):
    t = i / (N - 1)
    im, d = new(S)
    for k in range(6):
        x = C + (hash01(k, 15) - .5) * 28
        up = math.sin(math.pi * t) * (6 + hash01(k, 16) * 10)
        dot(d, x, C + 11 - up, rgb('#A1887F') if k % 2 else rgb('#6D4C41'), 2)
    return fade(im, max(0, t - .55) * 2.2)


def el_electricity(i):
    t = i / (N - 1)
    im, d = new(S)
    if t < .65:
        for k in range(2):
            a = k * math.pi + hash01(k, 17) * 2 + t * 2
            pts = [(C, C)]
            for j in range(1, 4):
                r = 8 * j
                jag = (3 if j % 2 == 0 else -3)
                pts.append((C + math.cos(a) * r - math.sin(a) * jag, C + math.sin(a) * r + math.cos(a) * jag))
            d.line([(round(x), round(y)) for x, y in pts], fill=rgb('#FFE082'))
    return im


def el_ice(i):
    t = i / (N - 1)
    im, d = new(S)
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        bx, by = C + math.cos(a) * 14, C + math.sin(a) * 14
        tip = (bx + math.cos(a) * 8 * ease(t), by + math.sin(a) * 8 * ease(t))
        d.polygon([(round(bx - 1), round(by)), (round(tip[0]), round(tip[1])), (round(bx + 1), round(by + 1))], fill=rgb('#B3E5FC'))
    return fade(im, max(0, t - .5) * 2)


def el_void(i):
    t = i / (N - 1)
    im, d = new(S)
    for k in range(3):
        r = 8 + round(ease(t) * 11)
        d.arc([C - r, C - r, C + r, C + r], math.degrees(k * 2.1 + t * 2), math.degrees(k * 2.1 + t * 2 + .9), fill=rgb('#9575CD'), width=2)
    return fade(im, max(0, t - .5) * 2)


def el_light(i):
    t = i / (N - 1)
    im, d = new(S)
    for k in range(8):
        a = k * math.pi / 4
        line(d, (C + math.cos(a) * 9, C + math.sin(a) * 9), (C + math.cos(a) * (9 + 11 * ease(t)), C + math.sin(a) * (9 + 11 * ease(t))), rgb('#FFF59D'))
    return fade(im, max(0, t - .45) * 1.9)


# ----------------------------------------------------------- rule words
def kw_cleave(i):
    t = i / (N - 1)
    im, d = new(S)
    for s in (-1, 1):
        x = C + s * (8 + ease(t) * 10)
        d.arc([x - 4, C - 10, x + 4, C + 10], 270 if s > 0 else 90, 90 if s > 0 else 270, fill=rgb('#FF8A3D'), width=2)
    return fade(im, max(0, t - .5) * 2)


def kw_pierce(i):
    t = i / (N - 1)
    im, d = new(S)
    x = 2 + ease(t) * 36
    line(d, (x - 12, C), (x, C), rgb('#7FD1FF'), 2)
    d.line([round(x), C, round(x) - 3, C - 3], fill=rgb('#7FD1FF'))
    d.line([round(x), C, round(x) - 3, C + 3], fill=rgb('#7FD1FF'))
    return fade(im, max(0, t - .6) * 2.5)


PLUS = ['.#.', '###', '.#.']
ONE = ['.#.', '##.', '.#.', '.#.', '###']


def blit(d, rows, x, y, c):
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch == '#':
                d.point((round(x) + i, round(y) + j), fill=c)


def kw_growth(i):
    t = i / (N - 1)
    im, d = new(S)
    y = C - 10 - ease(t) * 8
    blit(d, PLUS, C + 6, y, rgb('#CFEFB8'))
    blit(d, ONE, C + 10, y - 1, rgb('#CFEFB8'))
    # a sprout
    sx = C - 8
    line(d, (sx, C + 6), (sx, C - 2 - ease(t) * 3), rgb('#8FCB6A'))
    dot(d, sx - 2, C - 3 - ease(t) * 3, rgb('#8FCB6A'), 2)
    dot(d, sx + 1, C - 5 - ease(t) * 3, rgb('#8FCB6A'), 2)
    return fade(im, max(0, t - .55) * 2.2)


def kw_echo(i):
    t = i / (N - 1)
    im, d = new(S)
    for k in range(3):
        kk = max(0, min(1, t - k * .14))
        if kk > 0:
            ring(d, C, C, 6 + round(ease(kk) * 12), rgb('#B39DFF'), 2 if kk < .4 else 1)
    return fade(im, max(0, t - .5) * 2)


def kw_pain(i):
    t = i / (N - 1)
    im, d = new(S)
    red = rgb('#E8473F')
    d.line([C - 3, C - 12, C + 1, C - 4, C - 2, C + 3, C + 2, C + 12], fill=red, width=1)
    y = C + 12 + ease(t) * 12
    d.line([C + 7, round(y) - 3, C + 7, round(y)], fill=red)
    dot(d, C + 6, y + 1, red, 2)
    return fade(im, max(0, t - .5) * 2)


def kw_steady(i):
    t = i / (N - 1)
    im, d = new(S)
    gold = rgb('#D6C28A')
    ax, ay = C, C - 14
    ring(d, ax, ay - 3, 2, gold)
    line(d, (ax, ay), (ax, ay + 9), gold)
    line(d, (ax - 3, ay + 3), (ax + 3, ay + 3), gold)
    d.arc([ax - 6, ay + 2, ax + 6, ay + 12], 0, 180, fill=gold)
    k = math.sin(math.pi * t)
    return fade(im, 1 - k)


# --------------------------------------------------------------- specials
def die_surge(i):
    t = i / (N - 1)
    im, d = new(S)
    gold = rgb('#F2C14E')
    r = 14
    for k in range(14):
        a = k * 2 * math.pi / 14 + t * 3
        if k % 2 == 0:
            dot(d, C + math.cos(a) * r, C + math.sin(a) * r, gold, 2)
    cx, cy = C, C - 17
    d.polygon([(cx - 4, cy + 3), (cx - 5, cy - 2), (cx - 2, cy), (cx, cy - 4), (cx + 2, cy), (cx + 5, cy - 2), (cx + 4, cy + 3)], fill=gold)
    return fade(im, max(0, t - .6) * 2.5)


def die_curse(i):
    t = i / (N - 1)
    im, d = new(S)
    iron = rgb('#9E9E9E')
    for s in (-1, 1):
        for k in range(8):
            x = C - 15 + k * 4
            y = C + s * (5 - 3 * math.sin(k / 7 * math.pi))
            d.rectangle([round(x), round(y), round(x) + 2, round(y) + (1 if k % 2 else 2)], outline=iron)
    return fade(im, max(0, t - .4) * 1.6)


def die_glint(i):
    t = i / (N - 1)
    im, d = new(S)
    g = math.sin(math.pi * t)
    n = round(10 * g)
    line(d, (C - n, C), (C + n, C), (255, 255, 255, 255))
    line(d, (C, C - n), (C, C + n), (255, 255, 255, 255))
    if g > .5:
        dot(d, C - 1, C - 1, (255, 255, 255, 255), 3)
    return im


# ---------------------------------------------------------------- moments
def moment_seal(i, size=48, n=10):
    im, d = new(size)
    c = size // 2
    t = i / (n - 1)
    red, dark, rim, ink = rgb('#B0472E'), rgb('#6B2A1C'), rgb('#E0805E'), rgb('#3A2A22')
    if i < 4:  # the seal comes down
        r = 15 - i
        off = (3 - i) * 3
        disc(d, c, c - off, r, dark)
        disc(d, c, c - off, r - 2, red)
        ring(d, c, c - off, r - 5, rim)
        shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0)); sd = ImageDraw.Draw(shadow)
        disc(sd, c + 3, c + 4, r, (0, 0, 0, 255))
        im2 = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        im2.alpha_composite(fade(shadow, .6 + (3 - i) * .1)); im2.alpha_composite(im)
        return im2
    k = (i - 4) / (n - 5)
    disc(d, c, c, 11, dark)
    disc(d, c, c, 9, red)
    ring(d, c, c, 6, rim)
    d.line([c - 3, c, c, c + 3, c + 4, c - 3], fill=rim)
    if i == 4:
        ring(d, c, c, 15, (255, 255, 255, 255), 2)
    for j in range(14):  # ink flung out
        a = j * 2 * math.pi / 14 + hash01(j, 21)
        r = 11 + ease(min(1, k * 1.6)) * (4 + hash01(j, 22) * 8)
        dot(d, c + math.cos(a) * r, c + math.sin(a) * r, red if j % 3 else ink, 2 if j % 3 == 0 else 1)
    return fade(im, max(0, k - .45) * 1.7)


def campfire(i, size=18):
    im, d = new(size)
    # logs
    d.rectangle([2, 14, 15, 15], fill=rgb('#5A3A22'))
    d.rectangle([4, 12, 13, 13], fill=rgb('#7A5030'))
    d.point([(2, 14), (15, 14)], fill=rgb('#3A2414'))
    h = [8, 9, 7, 9, 8, 10][i % 6]
    sway = [0, 1, 0, -1, 0, 1][i % 6]
    cx = 9 + sway // 1
    for y in range(h):
        w = max(0, round((h - y) / h * 4 - (1 if y < 2 else 0)))
        col = rgb('#E53935') if y > h * .6 else rgb('#FF8A3D') if y > h * .25 else rgb('#FFD54F')
        yy = 11 - y
        d.rectangle([cx - w, yy, cx + w, yy], fill=col)
    d.rectangle([cx - 1, 10, cx + 1, 11], fill=rgb('#FFF3C4'))
    for k in range(2):  # embers
        e = (i + k * 3) % 6
        dot(d, 5 + k * 7 + (1 if e % 2 else 0), 5 - e // 2 + 2, rgb('#FFB04D'))
    return im


CHEST = {  # tier -> (light, pale)
    'wooden': ('#C98A4B', '#F1D3A4'),
    'iron': ('#9AA3AD', '#E3E8EE'),
    'silver': ('#C9D2E0', '#FFFFFF'),
    'gold': ('#F2C14E', '#FFF2B8'),
    'void': ('#9B6BE8', '#E2D0FF'),
}


def chest_burst(tier, i, size=48, n=8):
    light, pale = CHEST[tier]
    t = i / (n - 1)
    im, d = new(size)
    c = size // 2
    cy = c + 4
    f = Image.new('RGBA', (size, size), (0, 0, 0, 0)); fd = ImageDraw.Draw(f)
    for k in range(10):
        a = -math.pi + k * math.pi / 9
        r0 = 6 + ease(t) * 4
        r1 = 10 + ease(t) * 18
        line(fd, (c + math.cos(a) * r0, cy + math.sin(a) * r0), (c + math.cos(a) * r1, cy + math.sin(a) * r1), rgb(light), 2 if t < .5 else 1)
    im.alpha_composite(fade(f, max(0, t - .35) * 1.4))
    for k in range(7):  # sparkles rising
        x = c + (hash01(k, 31) - .5) * 30
        y = cy - 4 - ease(t) * (10 + hash01(k, 32) * 16)
        p = rgb(pale) if k % 2 else rgb(light)
        d.point([(round(x), round(y)), (round(x) - 1, round(y)), (round(x) + 1, round(y)), (round(x), round(y) - 1), (round(x), round(y) + 1)], fill=p)
    return fade(im, max(0, t - .6) * 2.4)


def main():
    for name, fn in [
        ('die_strike', die_strike), ('die_ward', die_ward), ('die_bloom', die_bloom), ('die_arcs', die_arcs),
        ('die_miasma', die_miasma), ('die_shock', die_shock), ('die_drain', die_drain), ('die_fizzle', die_fizzle),
        ('el_fire', el_fire), ('el_water', el_water), ('el_wind', el_wind), ('el_earth', el_earth),
        ('el_electricity', el_electricity), ('el_ice', el_ice), ('el_void', el_void), ('el_light', el_light),
        ('kw_cleave', kw_cleave), ('kw_pierce', kw_pierce), ('kw_growth', kw_growth), ('kw_echo', kw_echo),
        ('kw_pain', kw_pain), ('kw_steady', kw_steady),
        ('die_surge', die_surge), ('die_curse', die_curse), ('die_glint', die_glint),
    ]:
        strip(name, [fn(i) for i in range(N)])
    strip('moment_seal', [moment_seal(i) for i in range(10)])
    strip('campfire', [campfire(i) for i in range(6)])
    for tier in CHEST:
        strip('chest_' + tier, [chest_burst(tier, i) for i in range(8)])


if __name__ == '__main__':
    main()
