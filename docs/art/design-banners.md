# Design proposal: banners (improve, same style)

Board: `boards/banners.png`. Pilots: `clan_dominion`, `clan_oni`. The user's rule: keep the style, only improve.

## Shared rules (all constant, taken from today's 20 files)
- Canvas **64x128**, palette PNG8; black cloth `#16120F`, cream emblem `#F1E7CB`, **one accent colour per clan** on a coloured top band and the hem trim, brass rod `#8A6B43`/`#D8B04C` with two gold finials and three tassels, zig-zag hem. Emblem stays in the same two stacked blocks.
- No text. Emblem shapes are **not** redrawn: they are the clans' identity.
- Improve only: cleaner emblem edges (no stray pixels), one more cloth shade for folds, a rim light on the lit side, accents that match the clan colour in `factions.json`.

## Options (board A, B, C)
A today; B + vertical cloth folds; **C + 1 px rim light**; the choice is how much changes.

## Recommendation
**B and C together, applied by editing today's file** (PixelLab `edit_image`/`inpaint_image` on the current PNG as reference, about 5 generations per banner, then `reduce_colors`). Nothing is generated from scratch. If an edit changes the emblem, it is rejected.
