#!/usr/bin/env python3
"""Cut the three font families to the letters the game draws (UX-2, v1.868).

The fonts shipped whole (Cyrillic, Greek, Vietnamese, thousands of symbols) at
816 KB; the game is English and French. This keeps, per font file:

  * ASCII, Latin-1 and Latin Extended-A (a name typed by the player keeps its
    accents), no-break space, general punctuation and the arrows;
  * every other character the repository's texts really use (gamedata, the
    story DAG, narration notes and every string in lib/), when the font has it.

Kerning, ligatures and hinting are kept. The characters a font never had stay
absent (the engine falls back to the system font for them, as before).

  python3 tool/subset_fonts.py --src DIR        # DIR holds the full .ttf files
                                                # (the full files of commit 60522342e:
                                                # `git show 60522342e:assets/fonts/NAME.ttf`)

It writes assets/fonts/*.ttf and assets/fonts/GLYPHS.json, which
test/font_glyphs_test.dart reads: a character the texts use, that a font had
and the subset lost, fails the test (run this script again).
Needs fonttools: `pip install fonttools`.
"""
import argparse
import glob
import json
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = os.path.join(ROOT, 'assets', 'fonts')

# What every font keeps, used or not.
BASE = (
    set(range(0x20, 0x7F))
    | set(range(0xA0, 0x100))  # Latin-1
    | set(range(0x100, 0x180))  # Latin Extended-A (oe, OE, accents)
    | set(range(0x2010, 0x2028))  # dashes, quotes, bullets, ellipsis
    | set(range(0x2030, 0x205F))  # per mille ... punctuation
    | set(range(0x2190, 0x2194))  # arrows
    | {0x2212, 0x20AC}  # minus, euro
)

TEXT_GLOBS = [
    'assets/gamedata/*.json',
    'assets/Cleaned_Narrative_DAG.json',
    'assets/narration/**/*',
    'lib/**/*.dart',
]


def used_chars():
    chars = set()
    for pattern in TEXT_GLOBS:
        for path in glob.glob(os.path.join(ROOT, pattern), recursive=True):
            if not os.path.isfile(path):
                continue
            try:
                with open(path, encoding='utf-8') as f:
                    chars.update(ord(c) for c in f.read())
            except (UnicodeDecodeError, OSError):
                continue
    return {c for c in chars if c >= 0x20 and c not in (0x7F,)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True, help='folder with the full fonts')
    args = ap.parse_args()
    used = used_chars()
    manifest = {}
    total_before = total_after = 0
    for path in sorted(glob.glob(os.path.join(args.src, '*.ttf'))):
        name = os.path.basename(path)
        font = TTFont(path)
        has = set(font.getBestCmap())
        wanted = (BASE | used) & has
        opts = subset.Options()
        opts.layout_features = ['*']
        opts.hinting = True
        opts.notdef_outline = True
        opts.name_IDs = ['*']
        opts.glyph_names = False
        opts.drop_tables += ['DSIG']
        sub = subset.Subsetter(opts)
        sub.populate(unicodes=sorted(wanted))
        sub.subset(font)
        out = os.path.join(FONTS, name)
        font.save(out)
        kept = set(TTFont(out).getBestCmap())
        before, after = os.path.getsize(path), os.path.getsize(out)
        total_before += before
        total_after += after
        manifest[name] = {
            # used by the texts and never in this font: the system font draws it
            'absent_in_source': sorted(
                f'{c:04X}' for c in (used & {c for c in used if c > 0x7E}) - has
            ),
            'kept': len(kept),
        }
        print(f'{name}: {before // 1024} KB -> {after // 1024} KB, {len(kept)} glyphs')
    with open(os.path.join(FONTS, 'GLYPHS.json'), 'w') as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
        f.write('\n')
    print(f'total {total_before // 1024} KB -> {total_after // 1024} KB')


if __name__ == '__main__':
    sys.exit(main())
