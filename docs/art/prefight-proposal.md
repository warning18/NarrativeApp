# The pre-fight screen, painted like the boss scene and Level Up (proposal; Art, 26 November 2026)

Source: `docs/feedback/pre-fight-screen.jpg` (ccr-76229db7-131ulj @ 4bb8362e): a header, a teal hint card, a red Doctrine card, the foe's name, text and numbers, the hero's numbers, the equipped die, the red Enter Battle button, and the two fighters side on at the bottom, over a dark stone wall.
**Mock, 0 generations:** `docs/art/boards/prefight-mock.png` (180 x 390 at 3x, a phone at 1/6): a fight plate fills the screen (the warden test plate), the **foe's south frame** faces the player at the top (the rat matriarch), the **hero's north frame** stands at the bottom (the warrior), the header, the hint card and the Doctrine card are **ink kit panels** (the Doctrine one with a red border: the same panel recoloured in code), the foe's name, its numbers and the die are **ink kit chips**, and Enter Battle is the **kit's red button**. Text in the mock is a default font; the game's text stays code.
## What to paint, and what it costs
| Piece | Size | What | By | Gens |
|---|---|---|---|---|
| Plate | 180 x 320 or 390 | the fight plates of wave 6 (band, warden, boss in the test; the other ~35 on the user's OK) | PixelLab | 0 extra (wave 6); generate wave 6 at **180 x 390** so the plate fits a tall phone without a dark band at the top, same cost per plate |
| Foe | 48 or 60 px | the foe's south frame (done for the 20 Tower bosses and wardens: `art/pixellab-boss-rotations/handoff/`) | none | 0 |
| Hero | 48 px | the hero's north frame (done) | none | 0 |
| Cards, chips, button | 9-slice | the ink kit (done, waiting for the user's approval) | none | 0 |
| Hint and Doctrine glyphs | 24 px | a lantern for the hint (or a bulb) and a gavel for the Doctrine, in the Apollo palette like the stat symbols | PixelLab | about 3 (2 + 1 retry) |
Total new: **about 3 generations**; the rest is wave 6 (already planned) and the kit.
Needs from UX: the foe and hero stand in the plate's lower and upper thirds, so the cards float over the middle of the plate, which is empty by design; the plate behind the cards should be dimmed a little (a 25 percent ink overlay) so the card text stays legible. For a foe without a south frame (any non-Tower foe) the foe icon or head stays as today.
