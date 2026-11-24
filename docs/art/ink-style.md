# 7th combat screen: an ink-brush pixel homage (23 November, pictures only, nothing wired)

The user asked for a screen in the general spirit of a Korean martial-arts manhwa: black ink with brush strokes and dry-brush texture, strong contrast and solid blacks, cold greys and paper-white with deep red accents, taller more realistic figures, snow or wind. General style only; our own hero and foe, no characters, costumes, compositions or panels from any work. The prompts used only generic words (black ink brush painting, dry-brush, deep red, snow).

**What PixelLab did here:** a higher-resolution pixel style that reads as ink wash (large blacks, white snow, red accents). It cannot make real brush strokes or dry-brush edges, and comic panels with diagonal borders and speed lines are UX-2's layout or a code overlay. The result is a pixel-art homage in ink and deep red, not the manhwa look itself.

Files: `art/pixellab-ink/final/` (PNG8, 63 colours at most; `alt_ink_<piece>.png` is the other try).
| Piece | File | Size (px) | Notes |
|---|---|---|---|
| Background | `ink_background.png` | 360 x 640 (2x the 180 x 320 plates; draw at 0.5 for one to one) | a snowy mountain pass in a storm, red banners, an empty snow floor |
| Hero | `ink_hero.png` | 136 x 136 canvas, the figure about 96 px tall | a tall ronin, black coat, straw hat, katana, red sash; facing east (right) |
| Foe | `ink_foe.png` | 136 x 136 canvas, about 96 px tall | a tall hooded warden, black robe, pale mask, red sash; facing west (left) |
| Card or panel frame | `ink_frame.png` | 112 x 160 | rough black brush strokes with a red corner; the inside is transparent |
| Hit effect | `ink_hit.png` | 128 x 128 | an ink splash with speed lines and a red splatter |
| d6, d12 | `ink_d6.png`, `ink_d12.png` | 88 x 88 | black dice with red pips, drawn in 3/4 view like the rest of the set |

Sheets (`docs/art/boards/`): `ink-combat-mock-1x.png` and `-2x.png` (the pieces placed on the background, a quick mock, not a layout), `ink-pieces-1x.png` and `-2x.png` (the frame, hit, dice and the two figures).

How and cost: `create_image_pixen` (background, 360 x 640, 1 generation each), `create_image_pixflux` (frame, hit, dice), `create_character` standard mode, 96 px, `realistic_male` proportions (hero and foe, 1 generation each); 2 tries per piece = **14 generations** (balance 1874). Hero and foe are 8-direction PixelLab characters (ids in `art/pixellab-ink/jobs.json`), so they can still get walks or other facings.

Notes: the hero and foe keep a thin lighter outline in some tries (the alt versions); the dice are not exact d6 and d12 shapes in every view; the figures are not yet scaled to the sprites of the game, the same pixel scale as the 48 px sprites would need them at half size.

## Tower pieces (24 November, 6 generations: 4 announced + 2 for a second try of the plate)
- `art/pixellab-ink/final/ink_wideframe.png` (160 x 96, transparent outside): a wide brush-ink panel frame in the style of `ink_frame.png`, for text-heavy screens (menu, start, run end, marks); white paper inside with a black dry-brush border and a red corner. Nine-slice insets about 14 / 14 / 14 / 14 px. `alt_ink_wideframe.png` is the first try, which came out black inside.
- `art/pixellab-ink/final/ink_tower_band1.png` (180 x 320, same as `assets/visuals/tower/tower_band1.png`): the sample painted ink plate; `alt_ink_tower_band1.png` is the other try (lit window, no gold torches). Sheet: `docs/art/boards/ink-tower-band1.png` (original, the two plates).
- Honest: PixelLab keeps the plate's structure, so at an init strength of 230 the result stayed brown and orange (not ink); at 100 it still did. The plates shown are the second try with a palette snap to five greys (gold kept on the torch flames only), by `art/pixellab-styles/post.py`. So the sample is a painted plate redrawn by PixelLab, then snapped to ink greys: closer to a luminance recolour than to a true ink painting, with the stone and the shapes redrawn.
