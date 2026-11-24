# Tower roguelike art: plan and costs (Art, 24 November 2026; zero generations, nothing called)

Pieces the user may approve next, all in the Tower's ink style (ink greys and deep reds, one spot colour; `docs/art/ink-style.md`). Cost is 1 generation per piece (`create_image_pixen`, transparent); "one seed + retries" is the figure to plan with. Balance 1780 now. The relic names come from Core's brief 4, which I have not seen: the 12 below are placeholders by effect family; tell me the real list and I rewrite the prompts.

| Piece | Count | Size (px) | Prompt pattern (after the ink style line) | Cost, one seed | With 2 seeds |
|---|---|---|---|---|---|
| Tower relics | 12 | 16 x 16 (as the item icons; a 32 px version by the same prompt at 2 generations if wanted) | "pixel art game icon, black ink style, near black and grey, 1 px black outline, light from the top left, centred, no background, <the relic>, only <one accent> coloured" | 12 | 24 |
| Heat level emblems | 3 (heat 1, 2, 3) | 32 x 32 | "a round emblem, black ink style, a flame growing from one small flame to a ring of flames, deep red, no text" | 3 | 6 |
| Daily-climb seal | 1 | 32 x 32 | "a round red wax seal pressed with a rising sun over a stair, deep red and near black, no text" | 1 | 2 |
| Tower coin icon | 1 | 16 x 16 | "a small round coin with a tower stamped on it, black ink style, grey metal, a deep red rim, no background" | 1 | 2 |

Placeholder relic list (one per effect family; the accent colour carries the family): (1) a cracked hourglass, red, (2) a lantern with a pale flame, gold, (3) a bundle of dice, white and red, (4) a rusted key, orange, (5) a bone charm on a cord, grey, (6) a torn banner scrap, red, (7) a vial of black water, blue, (8) a small iron mask, purple, (9) a stack of coins, gold, (10) a chain link ring, grey, (11) a candle stub in a dish, orange, (12) a frost-covered gauntlet, blue.

## Totals
- All 17 pieces, one seed: **17 generations**; with up to 6 retries for weak ones: **about 23**.
- Two seeds for everything: **34** (needs the user's OK above 30).
- Palette work after the call is free: a nearest-colour snap to the ink greys, deep reds and one accent ramp (`art/pixellab-wave2/remap.py`).
- The relics could also come from the existing icon art by a free ink remap, but they are new objects, so they need new drawings.

## Notes
- Heat emblems: if the three need to read as a growing set, generate them as one image of 96 x 32 and cut it into three (1 generation, 2 seeds = 2), the same pattern as the walk strips.
- The seal and the coin share the wax and metal handling of the tarot seals and the Tower coin: the seal can reuse `art/pixellab-tarot/final/tower_cards/seal_*dots.png` as the init (img2img) for a matching look.
