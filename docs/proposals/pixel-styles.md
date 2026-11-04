# Three new pixel-art styles (proposal, docs and pictures only)

The user asked for three new pixel-art styles, different from each other and
from today's, each as a small design system: same layouts, same numbers, only
the look changes. Nothing in `lib/`, `assets/`, `tool/` or `pubspec.yaml` is
touched by this note. Pictures: `docs/ux-shots/pixel-styles/`.

## 0. What the look is today (measured on main, v1.803)

- 684 PNGs under `assets/` (306,004 bytes in all, stored as palette PNGs since
  #756; the rest of the 8.5 MB of assets is data). **1,518 distinct opaque
  colours** across them; one sprite uses 7 to 50 colours (icons 8 to 14).
- Sizes: item, enemy, shop, chest and skill icons 16x16 (357 files; the skills'
  gems 32x32), heads 19x15 to 50x46 (crops of sprites), companions 64 to 92 px,
  banners 64x128, chapter strips 160x56, effect strips with 48 px frames, ship
  cutaways 130x84, throne-room tiles 6x8 to 36x16. Enlarged with no smoothing
  (`FilterQuality.none`, 26 places).
- Make: flat tones, a near-black outline, a light top edge and a dark bottom
  edge, ordered (Bayer) dither in skies and fades. 251 pictures come from
  scripts (banners 20, chapter strips 8, effect strips and small animations 69,
  throne 6, skill icons 60, hunters' icons 12, materials 9, heads 67); the other
  433 (most item, enemy and skill icons, the companions, ships, races,
  professions) are the source themselves, no script.
- Code: `lib/theme/stitched_ink.dart` (the colour scheme and `InkColors`);
  **1,892 `Color(0x...)` literals in 103 files (1,330 distinct values)** and 595
  `Colors.x` uses elsewhere in `lib/`; code-drawn icons in
  `lib/utils/pixel_icons/` (596 lines); effects in `skill_vfx.dart`,
  `pixel_vfx.dart`, `combat_vfx/`.
- Type: Spectral (prose), PixelifySans (labels, numbers), IM Fell English SC
  (titles); all bundled.
- Palette in the generators: each script holds its own colours (for example
  `PAL` in `gen_skill_icons.py`); there is no shared palette module.

## 1. About the pictures

`today.png`, `style-A.png`, `style-B.png`, `style-C.png`: the three real screens
at 320 x 568, French (the fight board after "Entrer au combat", a Journey
scene with its choice card, the Character card), rendered by the app's own test
harness, then **converted automatically**: reduced to the style's grid, every
pixel snapped to the style's palette (A: ordered 2x2 dither, B: none, C: the
screen's lightness turned into ink on paper with a diagonal hatch). They show the
**palette, the grid, the dither and the contrast of each style on real screens**.
They are not drawn art: the text is smashed with everything else (a real build
keeps the fonts as vectors), icons are today's sprites recoloured, not redrawn
for the style, and the dither is applied everywhere (the rules below confine
it). `palettes.png` shows the swatches.

## 2. The styles

### A. Cinder 16: the same night, as a 16-colour console

**Idea.** Keep today's dark, warm world and make it strict: one fixed 16-colour
palette for everything (UI, sprites, effects), three-step ramps, so a sword, a
button and a flame share the same colours. Cheapest to reach; reads as "the
game, tidied up".

**Palette (16).** `#0e0b10` `#1c1620` `#2e2433` `#4a3a4f` `#6b4a3f` `#a0603a`
`#e0762b` `#f2c14e` `#f7e6a8` `#5c8a4e` `#9ec06a` `#2f6d73` `#4fb0b0`
`#7a4fb0` `#c9564d` `#ece7dc`. Three of today's accents are already in it
exactly (gold `f2c14e`, ember `e0762b`, tide `4fb0b0`); blood, void and heal
move to the nearest swatch.

**Grid and sprites.** Today's grid is kept: icons 16x16 (gems 32x32), heads
24x24, enemies 24x24 (today 16x16), tiles 8x8, banners 64x128, effect frames 48.

**Outline, shading, dither.** 1 px selective outline: the silhouette in
`#0e0b10`, inner edges one ramp step darker than the fill. Light from the top
left; each hue has dark / mid / light, shadows slide toward violet
(`#4a3a4f`, `#2e2433`), highlights toward cream (`#f7e6a8`). Ordered 2x2 dither
only on large fills (sky, fog, weather, fades), never on a sprite of 16 px or
less.

**Type.** The three families stay. Text colours come only from the palette
(bone `ece7dc` on dark, gold `f2c14e` for emphasis, `ece7dc` / `a0603a` on gold).

### B. Salt 8: cold, coarse, two accents

**Idea.** A pale-blue slate world with a single gold and a single red. Chunky,
flat, almost no detail: the screen reads as a signage system; effects and
elements are told by shape, not hue.

**Palette (8).** `#0b1016` `#1b2a35` `#35525f` `#5f8a96` `#a8cdd0` `#eef3ee`
plus the two accents `#d9a441` (gold) and `#c4524a` (danger).

**Grid and sprites.** Coarser: icons 12x12 (shown at today's size, one art pixel
about 3 px), gems 24x24, heads 16x16, enemies 16x16, tiles 6x6, banners 48x96,
effect frames 32.

**Outline, shading, dither.** No outline: shapes stand by value against the
`1b2a35` ground, with a 1 px lighter rim (`a8cdd0`) on the top edge. Flat: a
base tone and one step darker, nothing else. No dither at all; fog and weather
are a 1-pixel checkerboard at 50 %.

**Type.** Prose stays Spectral (the story is the hero); every other label moves
to PixelifySans SemiBold, upper case, letter-spaced; the IM Fell display face
is dropped. Text on gold is `0b1016`.

**Cost to the design.** Seven elements and the status colours cannot be told by
hue in 8 colours: each needs a pictogram (the gem's glyph), which the skill
icons already have, and the fight's effect chips need a distinct silhouette each.
In the mock the selected tab (text on gold) loses its label: the contrast rule
above is what protects it in a real build.

### C. Woodcut 5: ink on paper

**Idea.** A printed map: five warm tones, light by default (paper), the dark
theme being the same palette inverted (ink as ground). Fine linework and
hatching instead of fills, so the Journey reads as an old chart and the
Character card as a ledger.

**Palette (5).** `#1a1410` (ink) `#4a3a2c` `#8c7a5e` `#d8c8a0` `#f1e6c8` (paper).

**Grid and sprites.** Finer: icons 24x24, gems 32x32, heads 32x32, enemies
32x32, tiles 16x16, banners 64x128 (drawn in line, not in fills), effect frames 48.

**Outline, shading, dither.** The outline is the drawing: a 1 px ink line, no
fills except the paper tones. Shading is hatching in three densities (25 / 50 /
75 %, a 45 degree line every 4th pixel, doubled and tripled); no Bayer dither,
only hatch and stipple.

**Type.** The pixel font goes: titles and numbers in IM Fell English SC,
prose in Spectral, tiny labels in Spectral Medium; figures in the Fell face.

**Cost to the design.** A light theme becomes the first-class one (the app has a
light mode today, but the pictures are made for dark); the clans', elements' and
statuses' colours are unavailable, so each moves to a pictogram plus a hatch
pattern.

## 3. What each would cost

All sizes measured on the 684 current pictures, by snapping every pixel to the
style's palette (nearest colour) and saving as palette PNG; a quick measure,
not a finished recolour.

| | Today | A Cinder 16 | B Salt 8 | C Woodcut 5 |
|---|---|---|---|---|
| All 684 PNGs, bytes | 306,004 | 265,995 (no dither) / 297,676 (2x2 dither) | 262,480 | 243,294 (no dither) / 282,985 (hatch) |
| Change | | -13 % / -3 % | -14 % | -20 % / -8 % |
| 357 icons at the style's grid (16 / 16 / 12 / 24) | 71,051 | 64,752 (-9 %) | 56,773 (-20 %) | 72,756 (+2 %) |

**APK size.** The pictures are 0.3 MB of the 8.5 MB of assets, so every style
moves the APK by less than 60 KB (under 1 %), down for all three; C's finer
grid brings its icons back to today's size. No style is chosen for size.

**Recolour by script or redraw?**
- **A: a script.** The grid is today's and the pictures are palette PNGs
  (`png8.py`), so a recolour can rewrite each file's palette: a table from
  today's colours to the 16 (nearest in Lab, then fixed by hand for the sprites
  whose ramps collapse) and no pixel moves. The 251 generated pictures can run
  the same table or be re-run with a shared palette module (to be added: today
  each script holds its own colours). The 433 pictures with no script are
  recoloured by the table and checked by eye. The code side is a codemod of the
  1,892 colour literals to palette names, driven by the theme file (about 40
  constants in `stitched_ink.dart` carry most of it).
- **B: redraw.** A coarser grid cannot come from the 16x16 pictures by a script
  (a 16-to-12 reduction ruins them); the 357 icons, the heads, the enemies and the
  banners are drawn again, and the generators' recipes (explicit coordinates
  on a 16 or 32 grid: `glyph()` and `gem()` of `gen_skill_icons.py`) are
  rewritten, not parametrised. Plus a pictogram system for the elements.
- **C: redraw.** A finer grid and a line-and-hatch language, everything redrawn
  (433 by hand-drawn art or new recipes, 251 by rewritten recipes), a light theme
  made first-class, fonts changed in the theme.

**Generators that change (UX main's):** A: `gen_*.py` read the shared palette (all
nine and `tools/gen_skill_card_icons.py`); B: all rewritten on a 12 px grid;
C: all rewritten, plus a hatch helper. **Widgets that change:** A: the theme
file, then the per-widget colours (103 files); B: also `PixelIcon` sizes and the
effect chips (`fight_effect_icons.dart`), `skill_vfx.dart` (three-tone
recolouring by element); C: also the theme brightness defaults, `face_style.dart`,
the fight board's colours, every place that relies on hue for meaning (clans,
elements, status).

**My reading.** A is a tidy-up of what the game already is (low risk, a script
and a codemod, can ship in stages: theme, then pictures). B and C are new games'
looks: they need new art and a rule for every colour-coded thing. If the user
wants a look the app can reach safely, A; for a different identity, C reads the
most distinct and fits the story's maps and ledgers, at the cost of a full
redraw.

## 4. Libraries

Nothing is added to `pubspec.yaml`. I read the page of each (via the session's
web fetch) unless noted.

| Package | What it does for us | Licence | Size | Maintained |
|---|---|---|---|---|
| **Pillow** (Python, used by every generator and `png8.py`) | resize, palette, dither, palette PNG: all I used for the measures above | MIT-CMU (from the installed 12.3.0 metadata) | n/a | **docs page not reachable from this session** (readthedocs host blocked); version and licence read locally |
| **Pyxelate** (Python, github.com/sedthh/pyxelate) | turns an image into pixel art with a palette from hex or a retro set; dither none / naive / bayer / floyd / atkinson | MIT | not stated | **could not confirm**: the page shows no release and no last-commit date; its requirements pin scikit-learn 0.24.1, scikit-image 0.18.1 and numba 0.53.1 (2021). Not recommended: the recolour needs about 40 lines of Pillow |
| **oxipng** (Rust, github.com/shssoichiro/oxipng) | lossless PNG recompression; a dev tool, not an app dependency; it could shave more bytes after `png8.py` | MIT | not stated | looks active (978 commits, 2026 copyright, 10.x), no release date on the page |
| **libimagequant / pngquant** | picks a palette for an image | **GPL v3 or later, or a commercial licence** | not stated | maintenance not confirmed from the page. Not needed (palettes are fixed here); the licence is the point against it for anything shipped |
| **image** (Dart, pub.dev/packages/image 4.12.0) | pure-Dart image tools, "color quantization and dithering" listed, no detail on the page | MIT | not stated | active (published about 3 weeks before I read it, 8.85M downloads, verified publisher taosengine.com). Only useful if the app recoloured at run time; it does not need to, the pictures are recoloured offline |
| **flutter_shaders** (pub.dev, 0.1.5, flutter.dev) | helpers for fragment shaders; ships a pixelation shader (blocks of a child widget) | BSD-3-Clause | not stated | recent publish (about 4 weeks before I read it); the page says nothing about maintenance. It pixelates; it has no palette-snap shader named on its page, so a palette shader would be our own |
| **flame** (pub.dev, 1.38.2) | a game engine: sprites, sheets, animations | MIT | not stated | active; a full engine for what `PixelStrip` already does: not recommended |
| **palette_generator** (pub.dev, 0.3.3+7, flutter.dev) | extracts prominent colours from an image | BSD-3-Clause | not stated | **discontinued** ("This project has been discontinued"); not recommended |

**Could not check:** the Flutter fragment-shader documentation page
(docs.flutter.dev is not reachable from this session) and the Pillow docs
(pillow.readthedocs.io): so I recommend no shader approach and no
run-time-recolour approach here, and the Pillow facts above are the ones read
from the installed package, not from the docs. No library is needed for A (the
measures above were done with Pillow and NumPy; I did not read NumPy's page,
so I do not recommend it as a dependency).

## 5. Asked, not yet answered

UX main (session_01Y8cU3zPWWudNpnZGCrkKEc) was asked about which generators
write the pictures (684 on main, not 686), whether they share a palette module, and whether a
recolour by palette rewrite fits `png8.py`'s files. The answers above come
from reading the scripts and the README myself (no shared palette module: each
script holds its own colours); UX main's reply, if it differs, goes in an
addendum.
