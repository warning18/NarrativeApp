"""Clan-accent pictures (pictures only). Input: base-<scene>.png/.json made by
test/ux_clan_accent_shots_test.dart (UX_SHOTS=<dir>) at 360 x 780, pixel ratio 2.
Output: one sheet per screen (neutral ink and paper + the six clan colours), a contrast
sheet, and the moment of change. Usage: python3 gen.py <base-dir> <out-dir>"""
import colorsys, json, sys
from PIL import Image, ImageDraw, ImageFont

BASE, OUT = sys.argv[1], sys.argv[2]
FONTS = '/tmp/wt-clans2/assets/fonts/'
def font(name, size): return ImageFont.truetype(FONTS + name, size)
DISPLAY = lambda s: font('IMFellEnglishSC-Regular.ttf', s)
PROSE = lambda s: font('Spectral-Regular.ttf', s)
SYS = lambda s: font('PixelifySans-Regular.ttf', s)

INK_BLACK = '#05060A'; PAPER = '#EFEDE8'; INK_RED = '#C1121A'
CLANS = json.load(open('/tmp/wt-clans2/assets/gamedata/factions.json'))
ORDER = ['dominion', 'vigil', 'compact', 'mire', 'crows', 'penitents']

def rgb(h): return tuple(int(h[i:i+2], 16) for i in (1, 3, 5))
def hexs(c): return '#%02X%02X%02X' % tuple(int(round(x)) for x in c)
def lum(c):
    v = [x / 255 for x in rgb(c)]
    v = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in v]
    return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2]
def cr(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

def shade(c, dl):
    h, l, s = colorsys.rgb_to_hls(*[x / 255 for x in rgb(c)])
    l = min(1, max(0, l + dl))
    return hexs([x * 255 for x in colorsys.hls_to_rgb(h, l, s)])

HUES = {'dominion': '#2F6FE0', 'crows': '#E0479E', 'compact': '#E8782A',
        'mire': '#3FB06A', 'vigil': '#E8C21A', 'penitents': '#9B5DE5'}

def text_on(c):
    """The text colour on a fill: paper or ink, whichever reads best."""
    return PAPER if cr(PAPER, c) >= cr(INK_BLACK, c) else INK_BLACK

def fill_for(c):
    """Darken a fill only if neither text colour reaches 4.5 on it."""
    n = 0
    while max(cr(PAPER, c), cr(INK_BLACK, c)) < 4.5 and n < 60:
        c = shade(c, -0.01); n += 1
    return c

def line_for(c):
    """A frame on ink black wants 3+; lighten only if it falls short."""
    n = 0
    while cr(c, INK_BLACK) < 3.0 and n < 60:
        c = shade(c, +0.01); n += 1
    return c

ACC = [('neutral', 'No leader: ink and paper', PAPER, PAPER)]
for k in ORDER:
    raw = HUES[k]
    ACC.append((k, CLANS[k]['short'], fill_for(raw), line_for(raw)))

def recolour(img, rects, fill, line_, groups):
    """Move the red of the given rects to the accent: luminance-preserving."""
    px = img.load()
    ref_v = 0xC1 / 255
    for group, rs in rects.items():
        target = rgb(fill if group == 'fill' else line_)
        ink_text = text_on(fill) == INK_BLACK
        th, tl, ts = colorsys.rgb_to_hls(*[x / 255 for x in target])
        for (l, t, r, b) in rs:
            pad = 4 if group == 'line' else 0
            for y in range(max(0, int((t - pad) * 2)), min(img.height, int((b + pad) * 2))):
                for x in range(max(0, int((l - pad) * 2)), min(img.width, int((r + pad) * 2))):
                    p = px[x, y]
                    h, s, v = colorsys.rgb_to_hsv(p[0] / 255, p[1] / 255, p[2] / 255)
                    if group == 'fill' and ink_text:
                        # Paper text on a light fill turns to ink, antialiasing
                        # included: how far the pixel is from the red toward paper.
                        lu = 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]
                        t = max(0.0, min(1.0, (lu - 52) / (238 - 52)))
                        if t > 0.04 and s < 0.5:
                            base = [c * (v / ref_v) if False else c for c in target]
                            px[x, y] = tuple(int(base[k] + (rgb(INK_BLACK)[k] - base[k]) * t) for k in range(3))
                            continue
                    if not (h < 0.045 or h > 0.94) or s < 0.4 or v < 0.12:
                        continue
                    w = min(1, (s - 0.4) / 0.25)
                    rel = v / ref_v
                    tr, tg, tb = [min(255, c * rel) for c in target]
                    px[x, y] = (int(p[0] + (tr - p[0]) * w), int(p[1] + (tg - p[1]) * w), int(p[2] + (tb - p[2]) * w))
    return img

def tidy(img, scene):
    """The debug ribbon of a test build, painted out (each row from the pixel left of it)."""
    px = img.load()
    for y in range(0, 118):
        bg = px[585, y]
        for x in range(595, 720):
            if x + y >= 612:
                px[x, y] = bg
    return img

SCENES = {
    'home': dict(title='Home menu', rects={'fill': [[22, 326, 338, 392]], 'line': [[22, 396, 338, 690]]}),
    'floor': dict(title='Tower floor, tarot pick', rects=None),
    'fight': dict(title='Tower fight', rects={'fill': [[60, 714, 348, 754]], 'line': [[10, 112, 24, 128]]}),
}
def load(scene):
    img = Image.open(f'{BASE}/base-{scene}.png').convert('RGB')
    rects = SCENES[scene]['rects']
    if rects is None:
        j = json.load(open(f'{BASE}/base-{scene}.json'))
        rects = {'line': j['line'], 'fill': [[264, 376, 344, 416]]}
    return tidy(img, scene), rects

def sheet(scene):
    base, rects = load(scene)
    cols, cell_w, cell_h, pad, head = 4, 360, 780 + 52, 10, 70
    rows = 2
    W = cols * cell_w + (cols + 1) * pad
    H = head + rows * cell_h + (rows + 1) * pad
    s = Image.new('RGB', (W, H), '#0B0C14')
    d = ImageDraw.Draw(s)
    d.text((pad, 12), SCENES[scene]['title'] + ' — the clan accent (360 px)', font=DISPLAY(26), fill=PAPER)
    d.text((pad, 46), 'One flat colour a clan on buttons, ribbons, held frames and the current rung. No leader: ink and paper. Red only for damage, health and danger.', font=PROSE(13), fill='#9AA3A7')
    for i, (k, name, fill, line_) in enumerate(ACC):
        im = recolour(base.copy(), rects, fill, line_, None).resize((360, 780), Image.LANCZOS)
        x = pad + (i % cols) * (cell_w + pad); y = head + pad + (i // cols) * (cell_h + pad)
        s.paste(im, (x, y + 40))
        d.rectangle([x, y, x + 24, y + 30], fill=fill)
        d.rectangle([x + 28, y, x + 52, y + 30], fill=line_)
        d.text((x + 60, y + 2), name, font=DISPLAY(20), fill=PAPER)
        d.text((x + 60, y + 24), f'fill {fill}  line {line_}', font=PROSE(12), fill='#9AA3A7')
    s.save(f'{OUT}/sheet-{scene}.png')

def contrast():
    rows = ACC
    W, H = 1100, 120 + 62 * len(rows) + 30
    s = Image.new('RGB', (W, H), '#0B0C14'); d = ImageDraw.Draw(s)
    d.text((16, 12), 'Contrast of each clan colour (WCAG; text 4.5+, frames 3+)', font=DISPLAY(24), fill=PAPER)
    d.text((16, 52), 'The fill carries ink or paper text, whichever reads best; the line is a frame or an edge on ink black. A fill is darkened only if neither reaches 4.5.', font=PROSE(13), fill='#9AA3A7')
    cols = ['Clan', 'Art hue', 'On ink black', 'On paper', 'Best text on fill', 'Fill used', 'Line (frame)']
    xs = [16, 190, 300, 410, 520, 720, 900]
    for x, c in zip(xs, cols): d.text((x, 86), c, font=SYS(13), fill='#9AA3A7')
    for i, (k, name, fill, line_) in enumerate(rows):
        y = 112 + i * 62
        raw = PAPER if k == 'neutral' else HUES[k]
        d.text((16, y + 10), name, font=DISPLAY(18), fill=PAPER)
        d.rectangle([xs[1], y + 6, xs[1] + 60, y + 40], fill=raw)
        d.text((xs[1], y + 42), raw, font=PROSE(11), fill='#9AA3A7')
        def val(x, v, need, yy=10, size=20):
            d.text((x, y + yy), '%.1f' % v, font=PROSE(size), fill=('#7CCB84' if v >= need else '#E8776F'))
        val(xs[2], cr(raw, INK_BLACK), 3.0); val(xs[3], cr(raw, PAPER), 3.0)
        t = text_on(raw); best = max(cr(PAPER, raw), cr(INK_BLACK, raw))
        d.rectangle([xs[4], y + 4, xs[4] + 110, y + 40], fill=raw)
        d.text((xs[4] + 8, y + 10), 'Roll Dice', font=SYS(16), fill=t)
        d.text((xs[4] + 116, y + 10), '%.1f' % best, font=PROSE(16), fill=('#7CCB84' if best >= 4.5 else '#E8776F'))
        tf = text_on(fill)
        d.rectangle([xs[5], y + 4, xs[5] + 110, y + 40], fill=fill)
        d.text((xs[5] + 8, y + 10), 'Roll Dice', font=SYS(16), fill=tf)
        d.text((xs[5] + 116, y + 10), '%.1f' % max(cr(PAPER, fill), cr(INK_BLACK, fill)), font=PROSE(16), fill='#7CCB84')
        d.rectangle([xs[6], y + 4, xs[6] + 110, y + 40], fill=INK_BLACK, outline=line_, width=3)
        d.text((xs[6] + 8, y + 10), 'Held card', font=SYS(14), fill=line_)
        d.text((xs[6] + 116, y + 10), '%.1f' % cr(line_, INK_BLACK), font=PROSE(16), fill='#7CCB84')
    s.save(f'{OUT}/contrast.png')
    return rows

def change(scene='floor'):
    base, rects = load(scene)
    frames = []
    a, b = ACC[0], ACC[1]
    steps = [0, .25, .5, .75, 1]
    def mix(c1, c2, t):
        return hexs([x + (y - x) * t for x, y in zip(rgb(c1), rgb(c2))])
    toast = ['The Dominion thinks more of you. Standing 3 to 5']
    for t in steps:
        im = recolour(base.copy(), rects, mix(a[2], b[2], t), mix(a[3], b[3], t), None).resize((360, 780), Image.LANCZOS)
        d = ImageDraw.Draw(im)
        d.rectangle([12, 690, 348, 728], fill='#1B1D27', outline='#394A50')
        d.text((22, 698), toast[0], font=PROSE(13), fill=PAPER)
        frames.append(im)
    W = 5 * 360 + 6 * 10
    s = Image.new('RGB', (W, 780 + 100), '#0B0C14'); d = ImageDraw.Draw(s)
    d.text((10, 10), 'The moment it changes: a 400 ms fade when the toast fires (neutral to Dominion blue)', font=DISPLAY(24), fill=PAPER)
    d.text((10, 44), 'Tower: when the cards close and the toast shows. Story: at the next screen. Frames at 0, 100, 200, 300, 400 ms.', font=PROSE(13), fill='#9AA3A7')
    for i, f in enumerate(frames):
        s.paste(f, (10 + i * 370, 90))
        d.text((10 + i * 370, 70), f'{int(steps[i] * 400)} ms', font=SYS(12), fill='#9AA3A7')
    s.save(f'{OUT}/change-fade.png')
    frames[0].save(f'{OUT}/change-fade.gif', save_all=True, append_images=frames[1:] + frames[-1:] * 4 + frames[::-1][:-1],
                   duration=[400] + [100] * 3 + [900] + [100] * 4 + [100] * 4 , loop=0)

if __name__ == '__main__':
    import os
    os.makedirs(OUT, exist_ok=True)
    for sc in SCENES: sheet(sc)
    contrast(); change()
    for k, name, f, l in ACC: print(k, f, l)
