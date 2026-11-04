# UX (main): improvements, round 2

Second list, as the manager asked: only new items, nothing in
`ux-main-improvements.md`, `map-performance.md`, or already merged or held
(radar painters, die widgets). "Measured" means I ran it here; "read" means I
read the code and did not run it on a device. No code, nothing built.

Ranked by value over effort:

| # | Item | Size | Risk | What shrinks |
|---|---|---|---|---|
| 1 | Palette-encode every picture that fits 256 colours | S | none | APK −0.35 MB |
| 2 | Icons stored at their own size, not 8 times bigger | S-M | low | APK −0.13 MB, memory, decode time |
| 3 | Measure, then fix, what repaints every frame | M | medium | frame cost (not measured) |

## 1. Palette-encode the pictures that fit 256 colours (S, no risk)

- **What.** Of the 687 PNGs under `assets/`, 679 have 256 colours or fewer
  (pixel art, flat tones), but are stored as 32-bit RGBA. Re-encoded as 8-bit
  palette PNGs (ImageMagick `PNG8`, compression 9), the same pictures weigh
  **1,812,993 B → 1,466,904 B (−346 KB, −19%)** (measured over all 687 on
  main today; the 8 that stay are the three sea beasts of #702, soon WebP,
  and a few with more than 256 colours).
- **Why it is safe.** A palette holds the colours and the alpha of each
  exactly. I compared 80 files, chosen at random, pixel by pixel (`compare
  -metric AE`): 80 identical, 0 different. The decoded picture in memory is
  the same, so nothing on screen changes.
- **What I would add.** The generators write RGBA, so `tool/README.md`'s
  check ("run it, no file changes") would then differ by encoding only. The
  fix is one line at the end of each generator (`im.quantize` is lossy, so
  rather `im.convert('P')` on an image already under 256 colours), and a
  short `tool/png8.py` to run over `assets/` that refuses any picture with
  more than 256 colours. A `qa_` guard can then keep new pictures palette
  PNGs.
- **Player notices.** Nothing; the APK is about 0.35 MB smaller (with item 2
  the two overlap on the icons, so they do not simply add up: do item 2
  first, then this).

## 2. Icons stored at their own size (S-M, low risk)

- **What.** All 377 icons (items 132, skills 157, enemies 64, shops 14,
  chests 10; the heads are separate) are 128×128 PNGs, but every one of them
  is an exact nearest-neighbour upscale of a 16×16 picture (the skills' of a
  32×32), ×8 for the items, enemies, shops and chests and ×4 for the skills
  (the scripts say so: `gen_hunter_icons.py` "written at 128x128 (x8, no
  smoothing)"). I checked all 377 by shrinking and
  enlarging again with `-filter point`: **377 of 377 come back
  pixel-identical**.
- **Picture.** `docs/ux-shots/icons-8x-vs-native.png`: top row the shipped
  128 px files, bottom row the same icons stored at 16 px (32 px for the
  skill) and enlarged by the same factor. Nothing to tell apart.
- **Why bother.** (a) APK: the icons are 235,667 B today, 101,025 B stored
  at native size (−134 KB, more if item 1 is applied after). (b) Memory and
  decode time: Flutter keeps a decoded picture at its stored size, so a
  128×128 icon takes 64 KB of RAM for 256 pixels of art (1 KB at 16×16, 4 KB
  at 32×32). A screen of 40 icons holds 2.5 MB of icons instead of 40 KB.
- **Why the screen does not change** (measured). The icon widgets I found
  (`offer_dialog`, `reward_cards`, `mercy_dialog`, `spoils_chest_dialog`) go
  through `PixelIcon`, which draws with `FilterQuality.none`. I drew one icon at
  18, 26, 28, 30, 36, 44 and 52 px (the sizes the app uses) from the 128 px
  file and from the 16 px file in a widget test: **0 differing bytes at all
  seven sizes**.
- **What it touches.** The generators' scale factor (×8 → ×1, ×4 → ×1);
  `pixel_portrait.dart`, which loads the enemy icon and draws a crop of it
  and must follow the image's own size, not 128; the head crops of
  `gen_fight_heads.py`, which read `assets/icons/enemies` at 128 px and
  would read 16 px. The other consumers (`offer_dialog`, `reward_cards`,
  `mercy_dialog`, `spoils_chest_dialog`) use `PixelIcon` and need nothing.
  `test/qa_assets_declared_test.dart` does not change.
- **Player notices.** Nothing on screen; a screen full of icons opens with
  less memory and decode work, which counts most on an old phone.

## 3. Measure, then fix, what repaints every frame (M, medium risk)

Read, **not measured on a device**: this is a list of where to look first,
and a timeline capture on the phone the user plays on comes first, as for the
map.

- **Painters that always repaint** (`shouldRepaint => true`): the Journey's
  scene (`side_view.dart`), the sea battle's ships (`sea_battlefield.dart`,
  `ship_fx.dart`), the fight's effects (`combat_vfx.dart`), the moments
  (`moments.dart`) and the map (`chart_map_painter.dart`, already in
  `map-performance.md`). The scene and the ships rebuild their widgets every
  frame through an `AnimatedBuilder` around a `CustomPaint`; giving the
  painter the clock as `repaint:` lets Flutter skip the widget rebuild and
  repaint only the canvas. The Journey scene is on screen for most of play,
  so it comes first.
- **Blurs in painters that run every frame**: 24 `MaskFilter.blur` (the sea
  battle 8, the ships' hulls and effects 7, the fight's backdrop 3, the
  Journey's effects 2, the map 2) and 4 `saveLayer`. A blur mask is one of
  the dearest things the canvas does; each could be drawn once into a
  picture and reused where its shape does not change. Only a capture says
  which ones matter.
- **What the user would notice.** Smoother scenes and sea battles on an
  older phone, and a cooler phone. If the capture shows nothing, nothing is
  built.

## Looked at, nothing to do

- **Unused effect strips.** All 36 `vfx_*` strips in `assets/visuals/pixel_fx`
  are named by a `PixelLayer` in `pixel_vfx.dart` (nine are not named by the
  skills' data, but by the status and miss styles). None is unused.
- **The Saltmouth chart stub** (`assets/visuals/city/saltmouth_stub.json`,
  185 KB): the Journey's city chart opens it (`journey_screen.dart:1623`
  to `CityChartScreen`), so it ships on purpose.
- **Animations running on hidden tabs.** A bare `IndexedStack` keeps its
  hidden child's ticker going (I drew a probe: 30 of 30 frames), which was
  the worry; in the app's shell the hidden tab pages report their tickers as
  "inactive and muted" (read from the element tree), so nothing runs there.
- **Duplicate palettes.** Eight palette classes exist (`ChartPalette`,
  `BiomePalette`, `VfxPalette`, `ShipFxPalette`, and so on), each for its own
  domain with its own colours; I found no pair worth merging.
- **The theme's gold copied as a literal** (40 uses of `0xFFF2C14E` outside
  the theme): the ones I opened (`DieBadge`, the dice) draw a dark chip with
  the gold on it, which is right on the light theme too. No change.
