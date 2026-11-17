# overview-<mode>.png: the six screens of the mix, muted, deep and weighted frames (python3 make_overview.py after the UX_SHOTS runs, UX_FRAMES=muted and deep).
import os
from PIL import Image, ImageDraw, ImageFont

d = os.path.dirname(os.path.abspath(__file__)) + '/'
fonts = os.path.abspath(d + '../../../assets/fonts') + '/'
title = ImageFont.truetype(fonts + 'IMFellEnglishSC-Regular.ttf', 24)
body = ImageFont.truetype(fonts + 'Spectral-Regular.ttf', 16)
screens = ['scene', 'npc', 'chapter', 'quests', 'character', 'clans']
names = ['Story scene', 'NPC', 'Chapter title', 'Quests', 'Character', 'Clans']
rows = [('muted', 'Muted frames: every tier one step down the Apollo ramps'), ('deep', 'Deep frames: every tier two steps down'), ('weighted', 'Weighted (my pick): quiet common frame (deep), the rich metals muted')]
for mode in ('dark', 'light'):
    bg = (22, 22, 26) if mode == 'dark' else (226, 220, 208)
    ink = (235, 237, 233) if mode == 'dark' else (30, 30, 34)
    ims = {(k, s): Image.open(f'{d}{k}-{s}-{mode}.png').convert('RGB') for k, _ in rows for s in screens}
    w, h = ims[('muted', 'scene')].size
    tw, th = int(w * 0.46), int(h * 0.46)
    head = 38
    sheet = Image.new('RGB', (6 * (tw + 8) + 8, 3 * (th + 40) + head + 8), bg)
    dr = ImageDraw.Draw(sheet)
    for i, n in enumerate(names):
        dr.text((8 + i * (tw + 8), 6), n, font=title, fill=ink)
    for r, (k, t) in enumerate(rows):
        y = head + r * (th + 40)
        dr.text((8, y + 4), t, font=body, fill=ink)
        for i, s in enumerate(screens):
            sheet.paste(ims[(k, s)].resize((tw, th), Image.LANCZOS), (8 + i * (tw + 8), y + 30))
    sheet.save(f'{d}overview-{mode}.png')
    print(mode, sheet.size)
