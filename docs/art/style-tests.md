# Two dark style tests (23 November, pictures only, nothing wired)

The user asked for a darker design with limited colours, tried in two styles on four subjects. Same sizes as today's assets, so each piece compares one to one. Files: `art/pixellab-styles/final/<style>_<subject>.png` (PNG8; `alt_<style>_<subject>.png` is the other seed).

- **Style 1, "ink and one colour"** (`style1_*`): five greys from 090A14 to EBEDE9, plus blood red A53030 and gold F2C14E on small parts only.
- **Style 2, "dark ambiance"** (`style2_*`): 8 colours, 090A14 151D28 202E37 3C5E8B 577277 884B2B DE9E41 E8C170: deep shadows, one muted blue and a warm amber; every pixel darkened to 62 % then snapped to the palette.

| Subject | File | Size (px) | Today's asset |
|---|---|---|---|
| UX panel with corners | `<style>_panel.png` | 104 x 72 | `art/pixellab-styles/skel/panel.png` (the stepped panel in today's slate, as a reference) |
| UX button | `<style>_button.png` | 64 x 24 | `skel/button.png` |
| UX icon plate | `<style>_plate.png` | 40 x 40 | `art/pixellab-cards/skel/plate_common.png` |
| Die d6, die d12 | `<style>_d6.png`, `<style>_d12.png` | 44 x 44 | `assets/visuals/dice/die_d6_bone_44.png`, `die_d12_bone_44.png` |
| Hero idle (ronin, east) | `<style>_hero.png` | 44 x 48 (today's 42 x 47 on a padded canvas) | `assets/visuals/walker/ronin_idle_east.png` |
| Combat backdrop (the quay) | `<style>_combat.png` | 180 x 320 | `assets/visuals/fight_plates/quay.png` |

Sheets (`docs/art/boards/`): `style-test-compare-1x.png` and `-2x.png` (today, style 1, style 2 side by side), `style-test-style1-1x.png`, `-2x.png`, `style-test-style2-1x.png`, `-2x.png`.

## How and cost
`create_image_pixflux` img2img from today's asset (or a code skeleton for the UX pieces), a palette swatch as `color_image_base64`, `gen.py`; then `post.py` enforces the palettes by hand (a nearest-colour snap), because the generation alone did not stay dark or limited: style 1 came out with large red and yellow areas, style 2 bright amber. In style 1 the red and gold stay only on small parts (the lantern flame on the quay, the gems and sash of the hero, rims of the dice). 7 pieces x 2 styles x 2 seeds = **28 generations**, seed picks in `build.py` (panel, button and hero: seed 2; the rest seed 1).

## Honest notes
- Today's dice have no pips or numbers: the game draws them, so the test dice are blank too (PixelLab invented text on some seed-2 dice, which I did not pick).
- The UX panel and button come out as thin frames with empty interiors (PixelLab keeps the transparent background); they show the border and corners, not a filled panel.
- Style 2's quay has a large amber sky; it is "dark ambiance" with a warm light, but darker or bluer is one more pass at a lower brightness (the 62 % factor in `post.py`).
- The hero is the idle frame only, east view, redrawn by img2img; it was not rebuilt as a PixelLab character.
