# Builds overview-dark.png and overview-light.png (three directions x five
# screens) from the pictures of test/ux_story_redesign_test.dart (UX_SHOTS run).
import os
from PIL import Image, ImageDraw, ImageFont

d = os.path.dirname(os.path.abspath(__file__)) + '/'
fonts = os.path.abspath(d + '../../../assets/fonts') + '/'
title = ImageFont.truetype(fonts + 'IMFellEnglishSC-Regular.ttf', 24)
body = ImageFont.truetype(fonts + 'Spectral-Regular.ttf', 16)
dirs = [('a', 'A  Illuminated page', 'Framed ink panels, drop caps, choices as small framed cards; a clan tab where a choice touches a clan.'),
        ('b', 'B  Board and plates', 'The fight blocks everywhere: nameplates, gems, plates. One system with the fights.'),
        ('c', 'C  Quiet book', 'Large calm type on the page; colour and frames only for what weighs: clan choices, rare rewards.')]
screens = ['scene', 'npc', 'chapter', 'quests', 'character']
names = ['Story scene', 'NPC', 'Chapter title', 'Journal / quests', 'Character sheet']
for mode in ('dark', 'light'):
    bg = (22, 22, 26) if mode == 'dark' else (226, 220, 208)
    ink = (235, 237, 233) if mode == 'dark' else (30, 30, 34)
    ims = {(k, s): Image.open(f'{d}{k}-{s}-{mode}.png').convert('RGB') for k, _, _ in dirs for s in screens}
    w, h = ims[('a', 'scene')].size
    sc = 0.5
    tw, th = int(w * sc), int(h * sc)
    head, left = 36, 0
    sheet = Image.new('RGB', (5 * (tw + 8) + 8, 3 * (th + 96) + 8 + head), bg)
    dr = ImageDraw.Draw(sheet)
    for i, n in enumerate(names):
        dr.text((8 + i * (tw + 8), 6), n, font=title, fill=ink)
    for r, (k, t, c) in enumerate(dirs):
        y = head + 4 + r * (th + 96)
        dr.text((8, y), t + '  —  ' + c, font=body, fill=ink)
        for i, s in enumerate(screens):
            sheet.paste(ims[(k, s)].resize((tw, th), Image.LANCZOS), (8 + i * (tw + 8), y + 28))
    sheet.save(f'{d}overview-{mode}.png')
    print(mode, sheet.size)
