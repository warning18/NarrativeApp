"""Pixel icons for the nine building materials (v1.281.0): 16x16 art at 8x,
a near-black outline round the silhouette, flat shading with a light top
edge and a dark bottom edge, like the iron ore's. Writes
assets/icons/items/material_<name>.png (128x128).

    python3 tool/gen_material_icons.py [outdir]
"""
import os
import sys
from PIL import Image

OUTLINE = (10, 8, 7, 255)


def rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


# name: (palette, rows). Rows are up to 14 wide and 14 tall; '.' is empty,
# the outline is added round the silhouette.
ICONS = {
    'timber': ({'L': '#C98F4E', 'M': '#9A6532', 'D': '#5E3B1D', 'R': '#E0B574', 'r': '#7A4B25'}, [
        '..LLLLLLLLLL..',
        '.LMMMMMMMMRRM.',
        '.MMMMMMMMRrrR.',
        '.DDDDDDDDRrrR.',
        '..DDDDDDDDRRD.',
        '..LLLLLLLLLL..',
        '.LMMMMMMMMRRM.',
        '.MMMMMMMMRrrR.',
        '.DDDDDDDDRrrR.',
        '..DDDDDDDDRRD.',
    ]),
    'cut_stone': ({'L': '#D3CDBF', 'M': '#A39D90', 'D': '#6B665C', 'm': '#5A564E', 'S': '#EFEBDD'}, [
        '..LLLLLLLLLL..',
        '.LSSMMMMMMMML.',
        '.MMMMMmMMMMMM.',
        '.MMMMMmMMMMMM.',
        '.mmmmmmmmmmmm.',
        '.MMMmMMMMMMMM.',
        '.MMMmMMMMMDDM.',
        '.MMMmMMMMMMMM.',
        '.DDDDDDDDDDDD.',
        '..DDDDDDDDDD..',
    ]),
    'slag_glass': ({'L': '#6FD3C4', 'M': '#2F7F77', 'D': '#173B3A', 'B': '#0E2423', 'S': '#D4FFF6'}, [
        '.....LLLL.....',
        '...LLSMMMML...',
        '..LSLMMMMMMM..',
        '.LLMMMMMBMMMM.',
        '.LMMMMMMBBMMM.',
        '.MMMBMMMMMMMD.',
        '.MMMBBMMMMMDD.',
        '..MMMMMMMMDD..',
        '...DDMMMDDD...',
        '.....DDDD.....',
    ]),
    'ash_steel': ({'L': '#C3CBD4', 'M': '#8693A0', 'D': '#4A5460', 'A': '#B9B2A8', 'S': '#FFFFFF'}, [
        '....LLLLLLLL..',
        '...LSLLLLLLLM.',
        '..LLLLLLLLLMM.',
        '.LMMMMMAMMMMD.',
        '.MMMAMMMMMMDD.',
        '.MMMMMMMAMMD..',
        '.DDDDDDDDDDD..',
        '..............',
    ]),
    'rime_crystal': ({'L': '#E8FAFF', 'M': '#8EDCF2', 'D': '#4AA3C9', 'B': '#2A6C93'}, [
        '.......L......',
        '......LLM.....',
        '..L...LLMM.L..',
        '..LL..LLMM.LM.',
        '..LMM.LMMD.LM.',
        '.LLMMDLMMDLMD.',
        '.LMMMDLMMDMDD.',
        '.LMMDDLMMDMDB.',
        '.MMMDDDMMDDDB.',
        '..MDDDDMDDDB..',
        '...DDBBDDBB...',
    ]),
    'tear_glass': ({'L': '#EDE6FF', 'M': '#A592F0', 'D': '#6A55C0', 'B': '#3E2F85', 'S': '#FFFFFF'}, [
        '......LL......',
        '.....LMM......',
        '.....LMMD.....',
        '....LSMMMD....',
        '....LMMMMD....',
        '...LMMMMMMD...',
        '..LLMMMMMMMD..',
        '..LMMMMMMMMD..',
        '..MMMMMMMMDD..',
        '..MMMMMMMDDB..',
        '...MMDDDDDB...',
        '....DDBBBB....',
    ]),
    'shroud_thread': ({'L': '#DAD5EC', 'M': '#A19CBA', 'D': '#6A6586', 'B': '#3F3B58', 'G': '#F4F0FF', 'W': '#9FE3FF'}, [
        '...BBBBBBBB...',
        '..BLLLLLLLLB..',
        '..BDDDDDDDDB..',
        '.LMGMMMMMMMMD.',
        '.MMMWMMMGMMMD.',
        '.LMMMMMMWMMMD.',
        '.MMGMMMMMMMGD.',
        '.MMMMMWMMMMMD.',
        '.DMMMMMMMMMDD.',
        '..BDDDDDDDDB..',
        '..BBBBBBBBBB..',
    ]),
    'lantern_brass': ({'L': '#F2D072', 'M': '#CF9F33', 'D': '#8A6420', 'B': '#553D12', 'F': '#FFF3B8', 'R': '#FFB347'}, [
        '......LL......',
        '.....LMMD.....',
        '....LLLLLD....',
        '...LMMMMMMD...',
        '...MMFRRFMD...',
        '...MFRRRRFD...',
        '...MMFRRFMD...',
        '...MMMMMMMD...',
        '..LLLLLLLLLD..',
        '..MMMMMMMMMD..',
        '..DDDDDDDDDD..',
    ]),
    'white_fleet_oak': ({'L': '#F4EBD3', 'M': '#D8C8A0', 'D': '#A28F66', 'G': '#8A7650', 'R': '#FFFFFF'}, [
        '..LLLLLLLLLL..',
        '.LRLLMMMMMMMM.',
        '.LMMMMMGMMMMD.',
        '.MMGMMMMMMGMD.',
        '.MMMMMMMMMMMD.',
        '.MMMGMMMGMMMD.',
        '.MMMMMMMMMMDD.',
        '.DDDDDDDDDDD..',
        '..DDDDDDDDD...',
    ]),
}


def render(palette, rows):
    pal = {k: rgb(v) for k, v in palette.items()}
    h = len(rows)
    w = max(len(r) for r in rows)
    grid = [[None] * 16 for _ in range(16)]
    ox = (16 - w) // 2
    oy = (16 - h) // 2
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != '.':
                grid[oy + y][ox + x] = pal[ch]
    out = [row[:] for row in grid]
    for y in range(16):
        for x in range(16):
            if grid[y][x] is None:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 16 and 0 <= ny < 16 and grid[ny][nx] is not None:
                        out[y][x] = OUTLINE
                        break
    im = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    px = im.load()
    for y in range(16):
        for x in range(16):
            if out[y][x] is not None:
                px[x, y] = out[y][x]
    return im.resize((128, 128), Image.NEAREST)


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(__file__), '..', 'assets', 'icons', 'items')
    os.makedirs(out, exist_ok=True)
    for name, (palette, rows) in ICONS.items():
        render(palette, rows).save(os.path.join(out, 'material_%s.png' % name))
