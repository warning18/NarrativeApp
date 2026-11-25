# Level Up screen, made like the rest of the art (proposal and cost; Art, 25 November 2026)

Mock, 0 generations: `docs/art/boards/levelup-mock.png`: three existing Tower plates (the sigil ward, the win plate, the shop plate) as the background, a hero's south frame standing in it, a paper header strip with the level in a red seal, and the 8 new stat symbols on a paper strip. The text in the mock is code in the game. The sigil ward plate already works as a shrine, so the screen could ship today with an existing plate; the pieces below make it its own.

| Piece | Size | What | By | Gens (with retries) |
|---|---|---|---|---|
| Level Up plate, 3 options | 180 x 320 | cut paper, five tones, text only like the Tower plates: (a) a shrine with a red sigil circle on the floor and black arches, (b) an anvil in a forge yard with sparks, (c) a training yard with a post and a weapon rack | PixelLab | 3 (about 5) |
| "Level N" header | ~160 x 36 | an ink and paper banner with torn ends, number in the seal (the existing Tower seal pieces) | PixelLab | 2 (about 3) |
| The hero | 48 px | the heroes' south frames (done, `art/pixellab-boss-rotations/handoff/<hero>_south.png`) | none | 0 |
| Stat symbols | 24 and 32 px | done (the sheet) | done | 0 |
| Stat rows, the road bar, the buttons | panels | the ink kit (row 7 of the full plan), which still waits for the user | PixelLab + code | not counted |
Total new: **about 8 generations (10 at most)**, well under 30. The text, the numbers, the bar and the layout stay code.

## Result (25 November): 8 generations (stop line 12)
3 plates (180 x 320, text only, cut paper, snapped to the five tones: `art/pixellab-cutpaper/snap.py`) and the header: the first two header tries (a banner with torn ends and a ribbon with swallow-tail ends) came out messy at 160 x 40 and were dropped; a second round at 192 x 48 gave a clean red ribbon and a parchment scroll (3 generations). Files in `art/pixellab-levelup/handoff/`: `levelup_plate_shrine.png`, `levelup_plate_anvil.png`, `levelup_plate_yard.png` (180 x 320) and `levelup_header_ribbon.png` (168 x 27), `levelup_header_scroll.png` (171 x 38), transparent, blank (the "Level N" text is code). Sheet `docs/art/boards/levelup-plates.png`: each plate with a hero's south frame, a header and the stat symbols. The middle and the bottom of every plate are left empty for the hero and the stat panel; the header sits at the top 10 to 40 px. The user picks one plate and one header; the others stay unused.
