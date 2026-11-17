# Builds the audit sheets (audit-dark.png, audit-light.png) from the pictures the
# UX_SHOTS run of test/ux_story_audit_shots_test.dart wrote: python3 make_sheet.py
import os, textwrap
from PIL import Image, ImageDraw, ImageFont

d = os.path.dirname(os.path.abspath(__file__)) + '/'
fonts = os.path.abspath(d + '../../../assets/fonts') + '/'
title = ImageFont.truetype(fonts + 'IMFellEnglishSC-Regular.ttf', 22)
body = ImageFont.truetype(fonts + 'Spectral-Regular.ttf', 15)
rows = [
    ('01-menu', 'Main menu', 'The banner and title are the new look; the buttons are plain outlined Material, no frame, no clan colour.'),
    ('02-journey', 'Journey', 'The scene band is good; the quest strip and chips under it are flat cards.'),
    ('03-scene', 'Story scene', 'Band and speaker strip are good; the text is a flat card and the choices are plain rows with a round icon. No frame, no rarity, no clan colour.'),
    ('04-npc', 'NPC', 'A face and a grey clan chip. The clan colour, banner and the fight blocks\' nameplate are missing; the lines are plain boxes.'),
    ('05-journal', 'Journal', 'Tabs and text sections only: no panels, no quest cards, no clan colour.'),
    ('06-other', 'Other (quests, people, clans)', 'A list of collapsing rows with no icon, plate or tier; the quests hide under a bare label.'),
    ('07-character', 'Character sheet', 'Only the crest is pixel; the radar, tabs and stat tiles are Material. No nameplate or gems like the fight blocks.'),
    ('08-inventory', 'Inventory', 'Rarity is a word, not a frame; the slots are plain squares; the rows are flat.'),
    ('09-clans', 'Clans and standings', 'The throne is a lovely picture, then plain tabs. The new clan colours, banners and backdrops are not used here.'),
    ('10-map', 'Map', 'The chart is rich; its legend and filter chips at the foot are plain Material.'),
    ('11-settings', 'Settings', 'A long plain form: no panels, no pixel buttons.'),
]
for mode in ('dark', 'light'):
    ims = [(Image.open(f'{d}{n}-{mode}.png').convert('RGB'), t, c) for n, t, c in rows]
    w, h = ims[0][0].size
    s = 0.5
    tw, th = int(w * s), int(h * s)
    cap = 120
    cols = 6
    nrows = 2
    bg = (24, 24, 28) if mode == 'dark' else (232, 228, 220)
    ink = (235, 237, 233) if mode == 'dark' else (30, 30, 34)
    sheet = Image.new('RGB', (cols * (tw + 10) + 10, nrows * (th + cap + 10) + 10), bg)
    dr = ImageDraw.Draw(sheet)
    for i, (im, t, c) in enumerate(ims):
        x = 10 + (i % cols) * (tw + 10)
        y = 10 + (i // cols) * (th + cap + 10)
        sheet.paste(im.resize((tw, th), Image.LANCZOS), (x, y))
        dr.text((x, y + th + 6), t, font=title, fill=ink)
        for k, line in enumerate(textwrap.wrap(c, 36)[:5]):
            dr.text((x, y + th + 34 + k * 17), line, font=body, fill=ink)
    sheet.save(f'{d}audit-{mode}.png')
    print(mode, sheet.size)
