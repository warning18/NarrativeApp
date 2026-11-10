# Icon inventory (phase 0): every icon family the game shows

For Art's common icon style and pilot sheet. Counts from the code and assets
on `main` (v1.902); sizes are logical pixels (dp) as written in `lib/`.
Pictures are the real widgets drawn by a scratch picture test (not committed)
or crops of real screens.

## The two systems today

| System | What it is | Count | Look |
|---|---|---|---|
| **Pixel PNG icons** (`assets/icons/*`, via `PixelIcon`) | hand-made pixel art, `FilterQuality.none` | 157 skills, 132 items, 64 enemies, 14 shops, 10 chests = **377 files** | each has its own colours and outline; native 16x16 (20 skills and 6 chests are 32x32) |
| **Material Icons** (`Icons.*`) | a font, drawn flat in one colour | **378 distinct glyphs, 1255 uses in 163 files** | thin or filled, outline and rounded variants mixed; the opposite of pixel art |

So the game shows a pixel world through a flat vector UI. The user's ask ("a
version for each icon, coherent") is mostly the second row: the 378 Material
glyphs and the painted/PNG marks next to them.

## Families, where they come from, how big they are on screen

| # | Family | Source | Count | Native size | On screen (dp) | Picture |
|---|---|---|---|---|---|---|
| 1 | Skill icons | `assets/icons/skills` via `SkillPixelIcon` | 157 files (162 skills; 5 borrow another's, see `skill_icons.dart`) | 16 (137), 32 (20) | 14, 22, 26 (die facet), 30, 36, 44 | `1-skill-icons.png` |
| 2 | Item icons | `assets/icons/items` via `ItemPixelIcon`, falling back to Material by item type | 132 files (134 items) + 11 Material type icons | 16 | 18, 24, 28 (most), 36, 40, 52 | `2-item-icons.png` |
| 3 | Enemy icons | `assets/icons/enemies` via `EnemyPixelIcon` | 64 files (78 enemies: **14 have none**, the Material bug glyph is used) | 16 | 28, 36, 40 | `3-enemy-shop-chest-icons.png` |
| 4 | Shop icons | `assets/icons/shops` via `ShopPixelIcon` | 14 | 16 | 18, 44 | same |
| 5 | Chests | `assets/icons/chests` | 10 | 32 (6), 16 (4) | reward and loot screens | same |
| 6 | Die face kinds | `FaceKind` in `face_style.dart`, Material | 8 (attack, defend, heal, mana, poison, stun, weaken, empty) | vector | 11 to 30, coloured by kind | `4-material-...png` |
| 7 | Face rule words | `FaceKeyword.icon`, Material | 6 (cleave, pierce, growth, echo, pain, steady) | vector | 11 (badge on a die), 18 (rows) | same |
| 8 | Elements | `elementIcon` in `game_icons.dart`, Material | 9 names, **only 4 have a glyph** (Fire, Water, Earth, Wind); Lightning, Ice, Holy, Dark and None all draw the same empty circle | vector | 14 to 18 | same |
| 9 | Spell effects | `spellEffectIcon`, Material | 5 | vector | 18 to 20 | same |
| 10 | Game lookups | `game_icons.dart`: item type/id, quest category, schema, NPC kind, race, profession | 62 distinct Material glyphs | vector | 16 to 28 | `6-material-game-lookups.png` |
| 11 | Journey way glyphs | `journey_glyph.dart` (a glyph per kind of way, with an idle motion) | 33 distinct Material glyphs | vector | 20 to 26 | `5-material-journey-glyphs.png` |
| 12 | Stats bar, header, nav bar | `player_stats_bar.dart`, `home_shell.dart` | 25 distinct | vector | 16 to 28, nav 24 | `7-material-stats-bar-nav-header.png`, real screen `9-real-header-and-nav-bar.png` |
| 13 | Main menu | `main_menu_screen.dart` | 7 | vector | 24 | `8-material-main-menu.png` |
| 14 | Map pins | banner pins (`assets/visuals/banners`, 20 PNG 64x128), place and street pins, way marks | 20 banners + painted pins | 64x128 PNG; code-drawn rest | 24 to 36 on the map | `10-banner-pins-20.png`, real screens `11-...`, `12-...` |
| 15 | Pixel effect strips | `assets/visuals/pixel_fx`: 36 vfx, 11 die bursts, 8 element tints (`el_*`), 6 rule-word marks (`kw_*`), chests, campfire, moment, throne | 69 strips | 320x40 / 384x48 strips | over dice, in fights | not drawn (animations) |
| 16 | Buttons, chips, lists | Material everywhere else: chevron_right (42), lock_outline (36), auto_awesome (24), check_circle (18), casino, shield, bolt, anchor, flag... | rest of the 378 | vector | **18 (108 uses), 16 (52), 20 (49), 14 (39)**, then 12, 13, 28, 11 | not drawn |

Not icons but pixel art the user may also mean (no strips drawn here):
portraits and sprites (`heads` 67, `companion` 104, `fighters` 19, races 5,
professions 5 at 128x128), the chapter strips (8), the tower bands (3), the
dice bodies (10). Say if they are in scope.

## What I see (for the style decision)

1. **Two languages on one screen**: a pixel sword in the inventory row sits
   beside a Material chevron and lock; the stats bar and nav bar are pure
   Material. The pixel set is also uneven: items and skills are detailed,
   enemies are small figures, chests are 32x32.
2. **Sizes are not on a scale**: 18 dp is the most used icon size (108), then
   16, 20, 14, with 11, 12, 13, 15 and 26 also present. A pixel set at 16 native
   reads cleanly only at 16, 32, 48 (whole multiples); 18, 20, 14 smear.
3. **Gaps**: 5 of the 9 elements draw an empty circle; 14 enemies, 2 items and
   5 skills have no icon of their own; Lightning, Ice, Holy, Dark have no glyph.
4. **The most reused glyphs** (chevron_right, lock_outline, check, close,
   add, arrow_forward) are UI chrome; a pixel version must stay legible at
   14 to 18 dp or they should stay vector.
5. **Sizing rule that would make a pixel set work**: a 16x16 grid shown at
   16/32/48 dp (1x, 2x, 3x), a 24x24 or 32x32 grid for the large ones, and
   a size scale (16, 24, 32, 48) in `lib/theme` so a screen never asks for 18.

## Where the pictures are

`1-` to `8-`: the families as the real widgets draw them today (parchment
background, the app's fonts). `9-` real header and nav bar. `10-` the 20
banner pins. `11-` the Journey map with its pins and `12-` the world map with
its marks (real screens, older builds).
