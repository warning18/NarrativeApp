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

### Round 1 rest: chests, panels and button, die skin, chapter strips (all in `art/pixellab-pilots/`, see its `index.json`)
Balance 1317.5 before, 1288.5 after: **29 generations** (6 chests x 1, die 1, 2 chapter strips x 1, 2 `create_ui_asset` x 10). Nothing is wired into the game. Raw downloads are in `art/pixellab-pilots/raw/`; review files in `pixellab/` (palette PNG8) with today's crop in `today/`.
- Chests: pixen 32x32, seed 5, no background; one prompt per tier and state.
- Panel + button: one `create_ui_asset` call per surface (dark `#1F1C23`, parchment `#EAE0C9`, the app's real `surfaceContainer` tokens, not the board mock's `#3B3743`), seed 21, palette-locked, style reference = the stitched-ink mock of the board. The button on the parchment sheet had the word "BUTTON" written in it; it is painted out in the review file.
- Die: pixen 64x64, seed 7. One fixed isometric cube (no rotation, no numbers).
- Chapter strips: pixen 160x56, seed 3; they are much more detailed than today's code strips.

## Round 2 (after the user's marks on round 1), `art/pixellab-pilots/round2/`
Balance 1288.5 before, 1267.5 after: **21 generations**. Nothing wired.
- Renn, 3 candidates (A greatcoat and peaked cap, B bald toll collector with apron, C black wide-brim hat and cloak): `create_character` v3, 2 each = 6.
- Open chests (wooden and iron, 2 tries each): `edit_image_pixen` with the approved closed chest as the input, 1 each = 4. Gold open kept as approved.
- Dice in the Ember skin (blank faces): d4, d8, d10, d12, d20 and the d6 bone and iron skins, pixen 64x64, 1 each = 7; retries for d12 and d20 (the first tries read as diamonds) = 4, of which two (`d12_c`, `d20_c`, seeds 9) were not kept (flames around the die). Raw files of all are in `round2/raw/`.
- Banners: 3 stronger versions of the Dominion banner by exact pixel edit (0 generations), `round2/banners/`.
Seeds: chest edits 41 and 42; dice 7 (retries 8 and 9). Prompts per file: `round2/index.json`.

## Round 3: simple dice bodies (`art/pixellab-pilots/round3/`)
The user: the game draws the skill glyph on each face, so the body must be simple. One skin for the set: plain warm bone, three flat tones, thin dark outline, no texture, cracks, runes or marks. 16 generations (balance 1267.5 to 1251.5), pixen 64x64, 1 each, seeds 11 to 16, views side or high top-down per `round3/index.json`. Chosen: d4 (`d4_c`), d6, d8, d12 (`d12_c`), d20 (`d20_a`). The d10 is NOT solved: 5 tries read as a d20, a spiky bipyramid with small faces, or a hexagon (a d6 from above). Resting bodies only: a PixelLab body cannot rotate, so the code keeps the roll. Nothing wired.

## Round 5 (user: dice approved with icons on the faces, Dominion v2): no generation
- `docs/art/boards/dice-with-skill-icons.png`: the five approved bone dice (d4 `d4_c`, d6, d8, d12 `d12_c`, d20 `d20_a`) drawn at 2x with real skill icons (fireball, power_strike, mage_frost_nova, cleric_holy_light, rogue_backstab, warrior_shield_bash, ranger_aimed_shot, second_wind) composited on each face large enough for a 16 px icon; the d10 stays the code painter. Free PIL composite.
- `art/pixellab-banners-v2/`: the Dominion v2 treatment (folds, brighter brass rod and finials, woven accent hem) applied by exact pixel edit to all 13 `clan_*` banners, 64x128 palette PNGs, plus `docs/art/boards/clan-banners-v2.png` (today vs v2). Staged only: `assets/visuals/banners/` is untouched.

## Round 4: panels and buttons, three new directions (free pixel drawing, 0 generations)
`art/pixellab-pilots/round4/` (`index.json`, `<direction>/<dark|parchment>/panel_<state>.png` 48x32 and `button_<state>.png` 40x16, states normal, pressed, disabled, lit) and `docs/art/boards/round4-*.png`. Real tokens: dark surface `#1F1C23`, parchment `#EAE0C9`, panel corner 10 dp and button corner 4 dp (art px = 2 dp: 5 and 2 px), gold primary buttons. A: double ink line with corner stitches. B: worn leather/parchment edge (ragged 3-tone edge, rivets). C: flat pixel frame with 1 px highlight and shadow bevel. Nine-slice corner 6 px (panel), 4 px (button). Round 1's stitched ink was not chosen. Balance unchanged, 1251.5.
