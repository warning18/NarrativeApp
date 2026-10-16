#!/usr/bin/env python3
"""Draws one art strip per chapter (v1.370) for the quest-complete card.

Writes assets/visuals/chapters/chapter_1.png .. chapter_8.png, each 160x56,
in the game's pixel style (flat colours, a dark outline tone, ordered
dither in the sky). The app shows them at their own size scaled up with no
smoothing. Run from the repo root:  python3 tool/gen_chapter_art.py
"""
import math
import os
import random

from PIL import Image, ImageDraw

W, H = 160, 56
OUT = (10, 8, 12, 255)

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def rgb(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def sky(im, top, bottom, steps=7, until=None):
    """A banded sky from `top` to `bottom`, the bands blended by ordered dither."""
    until = until or H
    px = im.load()
    t, b = rgb(top), rgb(bottom)
    for y in range(until):
        f = y / max(1, until - 1) * (steps - 1)
        band = int(f)
        frac = f - band
        for x in range(W):
            lo = band
            if frac * 16 > BAYER[y % 4][x % 4]:
                lo = min(steps - 1, band + 1)
            k = lo / (steps - 1)
            px[x, y] = tuple(int(t[i] + (b[i] - t[i]) * k) for i in range(3)) + (255,)


def ridge(d, base, amp, seed, fill, step=4, rough=0.5, top=None):
    """A silhouette ridge: a random walk of heights, filled down to the bottom."""
    r = random.Random(seed)
    pts = []
    y = base
    for x in range(0, W + step, step):
        y += r.uniform(-amp, amp) * rough
        y = max(base - amp * 2, min(base + amp * 2, y))
        pts.append((x, int(y)))
    poly = [(0, H)] + pts + [(W, H)]
    d.polygon(poly, fill=fill)
    if top:
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            d.line([(x0, y0), (x1, y1)], fill=top)
    return dict(pts)


def stars(d, seed, n, colour, ymax):
    r = random.Random(seed)
    for _ in range(n):
        d.point((r.randrange(W), r.randrange(ymax)), fill=colour)


def box(d, x0, y0, x1, y1, fill):
    d.rectangle([x0, y0, x1, y1], fill=fill)


def window(d, x, y, colour):
    d.rectangle([x, y, x + 1, y + 2], fill=colour)


def ch1():
    """Alster's flight: slum rooftops at dusk, a figure on the ridge."""
    im = Image.new('RGBA', (W, H))
    sky(im, '#2a1830', '#e07a2f', steps=8, until=40)
    d = ImageDraw.Draw(im)
    d.ellipse([112, 26, 128, 42], fill=rgb('#f4b560'))
    d.ellipse([116, 30, 124, 38], fill=rgb('#ffd98a'))
    ridge(d, 36, 5, 11, rgb('#3a2438'), step=5)
    r = random.Random(3)
    x = 2
    while x < W - 8:
        w = r.randrange(9, 16)
        h = r.randrange(12, 26)
        top = H - h
        box(d, x, top, x + w, H, rgb('#1c1220'))
        d.polygon([(x - 1, top), (x + w + 1, top), (x + w // 2, top - 5)], fill=rgb('#140c18'))
        if r.random() < 0.6:
            box(d, x + w - 3, top - 8, x + w - 2, top, rgb('#140c18'))
        for wy in range(top + 4, H - 4, 6):
            for wx in range(x + 2, x + w - 2, 4):
                if r.random() < 0.45:
                    window(d, wx, wy, rgb('#f2a640'))
        x += w + r.randrange(1, 4)
    # a lone figure running along a rooftop
    box(d, 76, 20, 77, 25, rgb('#0a0710'))
    box(d, 75, 25, 78, 26, rgb('#0a0710'))
    d.point((77, 19), fill=rgb('#0a0710'))
    box(d, 70, 27, 90, 28, rgb('#140c18'))
    return im


def ch2():
    """Saltmouth: a harbour at dawn, masts and lantern docks."""
    im = Image.new('RGBA', (W, H))
    sky(im, '#2b5a6e', '#f0c58a', steps=8, until=34)
    d = ImageDraw.Draw(im)
    box(d, 0, 34, W, H, rgb('#1d3f52'))
    for y in range(35, H, 3):
        for x in range((y * 7) % 9, W, 9):
            d.line([(x, y), (x + 3, y)], fill=rgb('#3d7088'))
    ridge(d, 30, 3, 5, rgb('#2a3d4a'), step=6)
    # the quay and its houses
    box(d, 0, 32, W, 36, rgb('#1a2a35'))
    r = random.Random(8)
    x = 4
    while x < W - 6:
        w = r.randrange(8, 14)
        h = r.randrange(8, 16)
        box(d, x, 32 - h, x + w, 32, rgb('#222f3a'))
        d.polygon([(x - 1, 32 - h), (x + w + 1, 32 - h), (x + w // 2, 32 - h - 4)], fill=rgb('#16202a'))
        for wx in range(x + 2, x + w - 1, 4):
            if r.random() < 0.5:
                window(d, wx, 32 - h + 3, rgb('#f0b050'))
        x += w + r.randrange(2, 5)
    # ships with masts and sails
    for cx, s in [(40, 1.0), (104, 1.3)]:
        hy = 42
        d.polygon([(cx - 14, hy), (cx + 14, hy), (cx + 10, hy + 5), (cx - 10, hy + 5)], fill=rgb('#10181f'))
        for mx in (cx - 6, cx + 5):
            d.line([(mx, hy), (mx, hy - int(24 * s))], fill=rgb('#10181f'))
            d.polygon([(mx + 1, hy - int(22 * s)), (mx + 8, hy - int(12 * s)), (mx + 1, hy - 4)], fill=rgb('#e8d9b8'))
    # lantern reflections
    for x in (22, 70, 128):
        d.line([(x, 38), (x, 41)], fill=rgb('#f0b050'))
        d.point((x, 40), fill=rgb('#ffe2a0'))
    return im


def ch3():
    """The Spire of Judgment: an ashen sky, a tall fire-crowned spire."""
    im = Image.new('RGBA', (W, H))
    sky(im, '#1a1218', '#8a3a2a', steps=8, until=50)
    d = ImageDraw.Draw(im)
    ridge(d, 44, 4, 21, rgb('#2a1c22'), step=5, top=rgb('#4a2a2a'))
    ridge(d, 49, 3, 22, rgb('#170f14'), step=4)
    # the spire
    cx = 82
    d.polygon([(cx - 9, H), (cx - 5, 24), (cx - 2, 8), (cx + 2, 8), (cx + 5, 24), (cx + 9, H)], fill=rgb('#120c10'))
    d.polygon([(cx - 3, 8), (cx, 0), (cx + 3, 8)], fill=rgb('#120c10'))
    for y in range(14, 46, 6):
        window(d, cx - 1, y, rgb('#e0602a'))
    # the fire on top and its glow
    for i, c in enumerate(['#ffd98a', '#f08a30', '#c8402a']):
        d.ellipse([cx - 4 + i, 1 - i // 2, cx + 3 - i, 7 - i], fill=rgb(c)) if False else None
    d.polygon([(cx - 3, 6), (cx, -2), (cx + 3, 6)], fill=rgb('#c8402a'))
    d.polygon([(cx - 2, 6), (cx, 0), (cx + 2, 6)], fill=rgb('#f08a30'))
    d.polygon([(cx - 1, 6), (cx, 2), (cx + 1, 6)], fill=rgb('#ffd98a'))
    # ash falling
    r = random.Random(9)
    for _ in range(46):
        x, y = r.randrange(W), r.randrange(H - 6)
        d.point((x, y), fill=rgb('#a89890' if r.random() < 0.6 else '#6a5a58'))
    # small figures at the foot, a stair of braziers
    for x in range(20, 140, 17):
        d.line([(x, 49), (x, 51)], fill=rgb('#0c080a'))
        d.point((x, 48), fill=rgb('#e0602a'))
    return im


def ch4():
    """The Hollow Court: arches of a drowned cloister, lanterns on the water."""
    im = Image.new('RGBA', (W, H))
    sky(im, '#102018', '#3c6a50', steps=7, until=34)
    d = ImageDraw.Draw(im)
    box(d, 0, 34, W, H, rgb('#0c1a16'))
    for y in range(36, H, 3):
        for x in range((y * 5) % 8, W, 8):
            d.line([(x, y), (x + 3, y)], fill=rgb('#1f3d34'))
    # arches, half under water
    for i, x in enumerate(range(6, W, 30)):
        d.rectangle([x, 8, x + 4, 40], fill=rgb('#1a2a24'))
        d.rectangle([x + 22, 8, x + 26, 40], fill=rgb('#1a2a24'))
        d.pieslice([x, 2, x + 26, 28], 180, 360, fill=rgb('#1a2a24'))
        d.pieslice([x + 4, 6, x + 22, 26], 180, 360, fill=rgb('#2c4a40'))
        d.rectangle([x + 4, 16, x + 22, 34], fill=rgb('#2c4a40'))
    # fog bands
    px = im.load()
    for y in (30, 33, 36):
        for x in range(W):
            if (x + y * 3) % 5 < 3:
                r, g, b, a = px[x, y]
                px[x, y] = (min(255, r + 26), min(255, g + 34), min(255, b + 30), 255)
    # floating lanterns and reflections
    r = random.Random(14)
    for _ in range(9):
        x, y = r.randrange(8, W - 8), r.randrange(38, 52)
        d.rectangle([x, y, x + 1, y + 1], fill=rgb('#f4c860'))
        d.point((x, y + 3), fill=rgb('#7a6a30'))
    return im


def ch5():
    """The Shroud's Truth: frost mountains, a quarry and a pale band of light."""
    im = Image.new('RGBA', (W, H))
    sky(im, '#0e1a30', '#a8c8e0', steps=9, until=40)
    d = ImageDraw.Draw(im)
    stars(d, 4, 26, rgb('#e8f0ff'), 20)
    # a pale aurora band
    px = im.load()
    for x in range(W):
        y = 14 + int(4 * math.sin(x / 14.0))
        for k in range(3):
            r, g, b, a = px[x, y + k]
            px[x, y + k] = (min(255, r + 40 - k * 10), min(255, g + 70 - k * 20), min(255, b + 60 - k * 15), 255)
    ridge(d, 32, 8, 31, rgb('#46607e'), step=5, rough=1.2, top=rgb('#d8e8f4'))
    ridge(d, 40, 6, 32, rgb('#2a3c58'), step=4, rough=1.0, top=rgb('#9ab8d4'))
    box(d, 0, 46, W, H, rgb('#c8dcec'))
    ridge(d, 47, 2, 33, rgb('#e8f2fa'), step=6)
    # a frozen quarry's cut stairs and a lantern line
    for i in range(6):
        d.rectangle([100 + i * 5, 44 - i * 2, 104 + i * 5, 50], fill=rgb('#8aa4c0'))
    for x in range(10, 90, 14):
        d.line([(x, 47), (x, 49)], fill=rgb('#10182a'))
        d.point((x, 46), fill=rgb('#f4d890'))
    return im


def ch6():
    """The Hollow Shore: a bell tower on a spit, the tide coming in."""
    im = Image.new('RGBA', (W, H))
    sky(im, '#182a4a', '#6aa0d0', steps=8, until=34)
    d = ImageDraw.Draw(im)
    # the tide, in bands that grow lighter toward the front
    for i, c in enumerate(['#27508a', '#2f6098', '#3b72a8', '#4a86b8', '#6aa0c8']):
        box(d, 0, 30 + i * 5, W, 34 + i * 5, rgb(c))
        for x in range((i * 11) % 13, W, 13):
            d.line([(x, 30 + i * 5), (x + 4 - i % 2, 30 + i * 5)], fill=rgb('#c8e0f0'))
    # the spit and the tower
    d.polygon([(30, 36), (130, 36), (110, 44), (50, 44)], fill=rgb('#2a2a34'))
    box(d, 76, 14, 86, 36, rgb('#1c1c26'))
    d.polygon([(75, 14), (87, 14), (81, 6)], fill=rgb('#14141c'))
    d.rectangle([79, 17, 83, 23], fill=rgb('#0c0c12'))
    d.point((81, 20), fill=rgb('#e8c860'))
    d.line([(81, 6), (81, 2)], fill=rgb('#14141c'))
    # shoals: pale lines in the water
    r = random.Random(61)
    for _ in range(10):
        x, y = r.randrange(W - 12), r.randrange(40, H - 2)
        d.line([(x, y), (x + r.randrange(5, 12), y)], fill=rgb('#a8d0e8'))
    return im


def ch7():
    """The Lantern Throne: a hall of columns hung with lanterns, the throne lit."""
    im = Image.new('RGBA', (W, H))
    sky(im, '#1a1410', '#4a3418', steps=6, until=H)
    d = ImageDraw.Draw(im)
    # a floor with a long carpet
    box(d, 0, 40, W, H, rgb('#26190e'))
    d.polygon([(70, 40), (90, 40), (112, H), (48, H)], fill=rgb('#7a1c28'))
    d.polygon([(74, 40), (86, 40), (100, H), (60, H)], fill=rgb('#a02c36'))
    # columns in a row, shrinking toward the back
    for x, w, top in [(8, 8, 0), (32, 7, 4), (54, 6, 8), (100, 6, 8), (121, 7, 4), (144, 8, 0)]:
        box(d, x, top, x + w, 46 if w > 6 else 42, rgb('#3a2a1a'))
        d.line([(x + 1, top), (x + 1, 44)], fill=rgb('#5a4228'))
    # lanterns, many, golden
    r = random.Random(71)
    for x in range(10, W, 12):
        y = r.randrange(6, 22)
        d.line([(x, 0), (x, y)], fill=rgb('#0c0804'))
        d.rectangle([x - 1, y, x + 1, y + 3], fill=rgb('#f4c860'))
        d.point((x, y + 1), fill=rgb('#fff0b0'))
    # the throne on its dais
    box(d, 70, 34, 90, 40, rgb('#2c2018'))
    box(d, 74, 22, 86, 34, rgb('#10100c'))
    box(d, 76, 18, 84, 22, rgb('#10100c'))
    d.point((80, 20), fill=rgb('#f4c860'))
    return im


def ch8():
    """Beyond the Tear: a rift of white light in a violet dark."""
    im = Image.new('RGBA', (W, H))
    sky(im, '#0a0614', '#3a1e5a', steps=8)
    d = ImageDraw.Draw(im)
    stars(d, 8, 60, rgb('#c8b8f0'), H)
    # the tear: a jagged vertical rift with a glow around it
    r = random.Random(81)
    cx = 80
    pts = []
    for y in range(0, H, 4):
        cx += r.randrange(-2, 3)
        cx = max(70, min(90, cx))
        pts.append((cx, y))
    for k, c in enumerate(['#3a1e5a', '#5a3a8a', '#8a68c0', '#c8b8f0', '#ffffff']):
        for (x, y) in pts:
            d.line([(x - (5 - k) * 2, y), (x + (5 - k) * 2, y + 3)], fill=rgb(c))
    # the broken ground below
    ridge(d, 48, 3, 83, rgb('#120a20'), step=5, top=rgb('#5a3a8a'))
    # a few drifting shards
    for x, y in [(30, 18), (46, 30), (118, 22), (132, 36), (56, 12)]:
        d.polygon([(x, y), (x + 3, y + 1), (x + 1, y + 4)], fill=rgb('#a898d8'))
    return im


SCENES = [ch1, ch2, ch3, ch4, ch5, ch6, ch7, ch8]


def main():
    out = os.path.join('assets', 'visuals', 'chapters')
    os.makedirs(out, exist_ok=True)
    for i, scene in enumerate(SCENES, 1):
        im = scene()
        im.save(os.path.join(out, f'chapter_{i}.png'))
    # a contact sheet for a quick look
    sheet = Image.new('RGBA', (W * 2 + 6, (H + 4) * 4), (16, 14, 20, 255))
    for i, scene in enumerate(SCENES):
        sheet.paste(scene(), (2 + (i % 2) * (W + 2), 2 + (i // 2) * (H + 4)))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(
        '/tmp/chapter_sheet.png')


if __name__ == '__main__':
    main()
