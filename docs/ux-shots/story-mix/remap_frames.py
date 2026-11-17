# A darker, palette-fit version of Art's five card frames (no generation: a
# colour-to-colour remap inside the Apollo palette, docs/art/palette-apollo.md).
# `muted` steps every light tone one step down its Apollo ramp; `deep` two.
# Output: frames/<strength>/frame_<tier>.png, PNG8 like the originals.
#   python3 remap_frames.py
import os
from PIL import Image

root = os.path.dirname(os.path.abspath(__file__)) + '/'
src = os.path.abspath(root + '../../../assets/visuals/cards/') + '/'

def h(s): return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))

MAPS = {
    'muted': {
        'common':    {'EBEDE9': '577277', 'A8B5B2': '577277', '577277': '394A50', '394A50': '202E37'},
        'uncommon':  {'FFF6E0': 'DE9E41', 'DA863E': 'BE772B', '884B2B': '884B2B', '602C2C': '4D2B32'},
        'rare':      {'EBEDE9': 'A8B5B2', 'C7CFCC': '819796', '819796': '577277', '394A50': '394A50', '73BED3': '4F8FBA'},
        'epic':      {'EBEDE9': 'C7CFCC', 'E8C170': 'DE9E41', 'DE9E41': 'BE772B', '884B2B': '602C2C'},
        'legendary': {'FFF6E0': 'E8C170', 'EBEDE9': 'DE9E41', 'E8C170': 'DE9E41', 'BE772B': '884B2B'},
    },
    'deep': {
        'common':    {'EBEDE9': '394A50', 'A8B5B2': '394A50', '577277': '202E37', '394A50': '151D28'},
        'uncommon':  {'FFF6E0': 'BE772B', 'DA863E': '884B2B', '884B2B': '602C2C', '602C2C': '411D31'},
        'rare':      {'EBEDE9': '819796', 'C7CFCC': '577277', '819796': '394A50', '394A50': '202E37', '73BED3': '3C5E8B'},
        'epic':      {'EBEDE9': '819796', 'E8C170': 'BE772B', 'DE9E41': '884B2B', '884B2B': '602C2C', 'BE772B': '884B2B'},
        'legendary': {'FFF6E0': 'DE9E41', 'EBEDE9': 'BE772B', 'E8C170': 'BE772B', 'BE772B': '884B2B', 'DE9E41': 'BE772B'},
    },
}

for strength, tiers in MAPS.items():
    os.makedirs(f'{root}frames/{strength}', exist_ok=True)
    for tier, table in tiers.items():
        im = Image.open(f'{src}frame_{tier}.png').convert('RGBA')
        m = {h(k): h(v) for k, v in table.items()}
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                if a and (r, g, b) in m:
                    px[x, y] = (*m[(r, g, b)], a)
        out = im.quantize(colors=24, method=Image.Quantize.FASTOCTREE)
        out.save(f'{root}frames/{strength}/frame_{tier}.png', optimize=True)
        print(strength, tier)
