# Cut paper: how to extend it (plan, nothing generated; Art, 25 November 2026)

The user approved cut paper as the direction (the second try: ink, paper, a paper shadow, one clan colour). What worked in the second try: **text-only prompts for flat subjects** (the fire, the dice) and a **very light init (strength about 80)** when an emblem must survive (the banner). Costs are in generations: one per piece, plus about 30 % for retries. Balance 1751. Rule: ask the user before any batch above about 30.

| Step | What | Count | Size | Cost (1 seed) | With retries | Ask? |
|---|---|---|---|---|---|---|
| 1 | **Dice**: the six dice shapes d4, d6, d8, d10, d12, d20, blank faces, bold black with a cream edge (the pips and numbers are drawn by the game) | 6 at 44 px (the 40 px cut by a second call, or by the game scaling) | 44 x 44 | 6 (12 with the 40 px cut) | 8 (15) | no |
| 2 | **The six clan banners**, one colour per clan (Dominion 2F6FE0, Crows E0479E, Compact E8782A, Mire 3FB06A, Vigil E8C21A, Penitents 9B5DE5), each from its current banner at init strength 80 so the emblem survives | 6 | 64 x 128 | 6 | 9 | no |
| 3 | **Tower backgrounds**: the 14 plates (bands 1 to 3, the wards, the bosses, shop, bargain, parley, win, lose), text plus a light init from the current plate, cut paper with strong shadows | 14 | 180 x 320 | 14 | 19 | no (under 30) |
| 4 | **Foe heads**: the 14 faceless heads of `docs/art/wave2-heads-brief.md` as cut-paper faces (a black silhouette with a cream face shape and one colour), the first 4 as a test | 14 (test 4) | 32 x 28 | 14 (test 4) | 18 (6) | the test no, the rest no |
| 5 | **Icon pilot**: 8 icons in cut paper (potion, dagger, sword, boots, coat, helm, charm, shop) | 8 | 16 x 16 | 8 | 12 | no |
| 6 | **Icons, all families**: 132 items, 64 foes, 14 shops, 10 chests (the 157 skill icons stay Apollo: they are the skill language) | 220 | 16 or 32 | 220 | about 290 | **yes**, in 4 waves of about 70 |
| 7 | **Fight plates** (30 at 180 x 320) | 30 | 180 x 320 | 30 | 39 | yes (just above 30) |
| 8 | **Scenes** (73 at 240 x 100, the chapter and the life art) | 73 | 240 x 100 | 73 | about 95 | **yes**, in 3 waves |
| 9 | **Tarot vignettes redone in cut paper** (the 14 of 96 x 64): optional, the cards have the ink ones | 14 | 96 x 64 | 14 | 18 | no |

## Suggested order and running cost
1. Dice and the six banners first (steps 1 and 2): small, visible everywhere, and they set the look: **12 generations, 17 with retries**.
2. The Tower backgrounds (step 3): the Tower is where the user moves toward the new style: **14, about 19**. Running total about 36.
3. Foe heads, test of 4 (step 4): fixes the faceless heads at the same time: **4, about 6**.
4. Icon pilot (step 5), then the icon waves (step 6): the biggest line; do the pilot, look, then ask for the first wave: **8, then waves of about 70**.
5. Fight plates and scenes (steps 7 and 8) last: the most generations for the least change of identity.

## Notes
- The Tower's clan offer cards keep the story's banner card style (UX's), so no new frames are planned for them; step 2 gives the banners the card shows.
- Palette, the same for every step and free after the call: `art/pixellab-brut/` snap to ink 090A14, a dark 28283A, paper shadow C9C2A6, paper E7E1CD and one clan hue plus a dark of it; a plate or a scene may carry two or three of the clan hues, but no piece uses the warning red A53030 except for blood and warnings.
- Risks seen in the second try: the model adds a little 3D shading to cubes (dice), keeps a grey ground on banners (keyed out in code), and drifts from the emblem if the init strength is below about 60.
- The paper doll stays on hold.
