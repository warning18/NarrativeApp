# Catalogue of generated assets

One row per PixelLab generation made by the Art session: prompt, seed, model, size, cost, date, and the app element it is for.
Style suffix for backgrounds: "16-bit pixel art, flat colour with a dark ink outline, muted warm palette, no text, no characters, no UI"; view `side`, `medium detail`.

| File | For | Model | Size | Seed | Cost | Date | Prompt (before the suffix) |
|---|---|---|---|---|---|---|---|
| `art/pixellab-backgrounds/tower_band2.png` (raw: `raw2/b2`) | Tower floor background, floors 11 to 20 | pixen | 180x320 | 11 | 1 | 2026-11-10 | pixel art, interior of a round stone tower room higher up, cold blue-violet masonry, two narrow arched windows with pale moonlight, iron brackets with a single guttering torch, a stair curving up the wall, empty stone floor in front, mostly dark so UI text stays legible |
| `art/pixellab-backgrounds/tower_band3.png` (raw: `raw2/b3`) | Tower floor background, floors 21 to 30 | pixen | 180x320 | 11 | 1 | 2026-11-10 | pixel art, top of a ruined round stone tower, cracked dark masonry, a broad broken opening onto a night sky with a few stars and drifting ash, embers glowing in an iron brazier, empty stone floor in front, mostly dark so UI text stays legible |
| `art/pixellab-backgrounds/tower_band1.png` | floors 1 to 10 | pixen | 180x320 | 11 | 1 (earlier, Manager) | earlier | the earlier `tower_s11`, quantized |

Quantized with PIL median cut to 24 colours, no dither, saved as 8-bit palette PNG. Balance 1331.5 before, 1329.5 after.

## Pilots (design boards validated by the user, 2026-11-10)

### Characters (v3, from text, 8 directions each, only `west` kept; no seed exists for create_character)
Cost: 2 generations each (v3, up to 88 px), 12 in total. Balance 1329.5 before, 1317.5 after. Raw: `art/pixellab/pilots/<id>/Idle/rotations/`; staged palette PNG8 (32 colours, transparent): `art/pixellab/pilots/staged/<id>_idle_west.png`. Common suffix: "muted warm palette, dark ink outline, flat colour, side view facing west, no text"; mode v3, view side, outline single color black outline, detail medium.

| Staged file | For | Canvas | PixelLab id | Description (before the suffix) |
|---|---|---|---|---|
| `iron_golem_idle_west.png` | enemy `iron_golem` | 60x60 | 3424606c-7557-4086-8734-47146ed6dab4 | hulking iron guardian golem built by an old church, riveted dark grey iron plates, rust streaks, a dim amber glow in the visor slit, heavy fists, a rune-etched chest |
| `void_sovereign_idle_west.png` | enemy `void_sovereign` | 60x60 | 7ae33aa4-9428-4ea7-adf8-0461bd0cbf24 | tall ominous void sovereign, a robed crowned figure of black glass and violet void light, long torn cloak, a faint purple glow in the hollow eyes, regal and dreadful |
| `lysa_idle_west.png` | NPC `lysa` | 48x48 | 364a48ef-e7c6-440c-89f5-30c1108565e9 | young girl, the hero's younger sister, plain brown wool dress, a worn grey shawl, tied-back dark hair, thin and wary, poor harbour town clothes |
| `renn_idle_west.png` | NPC `renn` | 48x48 | a02561e0-85e5-4903-af4e-ca1e9e8090cc | stern Inquisition customs officer, white and grey coat with a lantern emblem, dark cap, ledger under one arm, cold hard expression |
| `kelda_idle_west.png` | companion `kelda` | 48x48 | dcc7dd9a-f799-4004-8a69-aa5d826d10c9 | stout dwarf woman warrior, braided red hair, iron round shield and short axe, riveted brown leather and iron plate, grin |
| `sable_idle_west.png` | companion `sable` | 48x48 | afc30f43-afd8-4b20-ada0-287f623d3177 | lean human rogue woman, hooded dark grey cloak, short black hair, leather jerkin, dagger at the belt, sly look |

Notes for UX-2: the PixelLab frames are exactly the canvas size (no extra margin). Feet are near the bottom edge: measure the foot inset per sprite in the table. The void sovereign reads gold and black more than purple; the 'void' accent is only in the glints.

### Banners (no generation; exact pixel edit of today's files)
Cost 0. `art/pixellab-banners/clan_{dominion,oni}_{rim,rim_folds}.png`: only the first cloth pixel inside the left outline (`#8A6B43`, the rod's brass) and, for `rim_folds`, a faint fold dot (`#332B22`) every second row 4 px inside each edge. Emblem, rod, hem, accents and the 64x128 size are untouched. A PixelLab `edit_image` costs 10 generations per banner and may redraw the emblem; it was not used. Not yet staged for `assets/`.
