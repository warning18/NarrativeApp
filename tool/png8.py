#!/usr/bin/env python3
"""Stores every picture under assets/ that fits 256 colours as an 8-bit palette
PNG, with nothing lost (UX round 2, item 1).

    python3 tool/png8.py            # rewrite what can be rewritten
    python3 tool/png8.py --dry-run  # say what it would do, write nothing
    python3 tool/png8.py --check    # list the pictures that should be palette
                                    # PNGs and are not; exit 1 if there are any

The art is pixel art in a few flat tones, but the scripts and the editors save
it as 32-bit RGBA, four bytes a pixel for at most 256 different colours. A
palette PNG holds the colours once and the alpha of each, exactly, so the same
picture weighs about a fifth less and decodes to the same pixels. A picture
with more than 256 colours (the sea beasts, soft glows) is left alone. A
rewrite is checked before it is kept: the new file, read back as RGBA, must
equal the old one byte for byte, and must be smaller, or nothing is written.

Needs Pillow. Run from the repository root; run it after any generator that
writes a picture (`tool/gen_*.py`, `tools/gen_*.py`), which save RGBA.
"""
import os
import sys

from PIL import Image

ROOT = 'assets'


def pngs():
    for dirpath, _, names in os.walk(ROOT):
        for name in sorted(names):
            if name.lower().endswith('.png'):
                yield os.path.join(dirpath, name)


def palette_version(path):
    """The picture as a palette image, or None when it cannot be one (more
    than 256 colours) or already is one."""
    im = Image.open(path)
    if im.mode == 'P':
        return None
    rgba = im.convert('RGBA')
    colours = rgba.getcolors(maxcolors=257)
    if colours is None:
        return None
    colours = [c for _, c in sorted(colours, key=lambda n: -n[0])]
    index = {c: i for i, c in enumerate(colours)}
    out = Image.new('P', rgba.size)
    flat = [c for rgb in colours for c in rgb[:3]]
    # Exactly as many entries as colours: Pillow then stores 1, 2, 4 or 8 bits
    # a pixel, as few as the palette allows.
    out.putpalette(flat)
    pixels = (rgba.get_flattened_data() if hasattr(rgba, 'get_flattened_data')
              else rgba.getdata())
    out.putdata([index[p] for p in pixels])
    out.info['transparency'] = bytes(c[3] for c in colours)
    return rgba, out


def encode(path, image, rgba):
    """Writes [image] to a temporary file and returns its bytes, or None when
    it does not read back as [rgba] or is not smaller than [path]."""
    tmp = path + '.png8tmp'
    try:
        image.save(tmp, 'PNG', optimize=True,
                   transparency=image.info['transparency'])
        back = Image.open(tmp).convert('RGBA')
        if back.size != rgba.size or back.tobytes() != rgba.tobytes():
            return None
        data = open(tmp, 'rb').read()
    finally:
        if os.path.exists(tmp):
            os.remove(tmp)
    return data if len(data) < os.path.getsize(path) else None


def main(argv):
    check = '--check' in argv
    dry = '--dry-run' in argv
    todo, before, after, many = [], 0, 0, 0
    for path in pngs():
        got = palette_version(path)
        if got is None:
            if Image.open(path).mode != 'P':
                many += 1
            continue
        rgba, image = got
        data = encode(path, image, rgba)
        if data is None:
            continue
        todo.append(path)
        before += os.path.getsize(path)
        after += len(data)
        if not (check or dry):
            open(path, 'wb').write(data)
    if check:
        for path in todo:
            print('not a palette PNG:', path)
        print(len(todo), 'picture(s) to convert;', many,
              'keep their colours (more than 256).')
        return 1 if todo else 0
    verb = 'would rewrite' if dry else 'rewrote'
    print(f'{verb} {len(todo)} pictures: {before} -> {after} bytes;',
          f'{many} left (more than 256 colours).')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
