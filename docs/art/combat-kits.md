# Combat-screen kits, two palettes (23 November, pictures only, nothing wired)

The user's complaint: the dice ground, the cards and the sprites do not look like they belong together. UX-2 lays out six screens (3 directions x 2 palettes); these are the pieces. **A** = the current Apollo palette (every pixel remapped to Apollo 46); **B** = style 1, "ink and one colour" (five greys from 090A14 to EBEDE9, blood red A53030 on small parts only). Same pixel scale as the 48 px sprites, light from the top left, 1 px dark outline. Files: `art/pixellab-combat-kits/final/<palette>_<piece>.png` with palette `apollo` or `b`, PNG8, transparent where the piece has no ground.

| Direction | Piece | Size (px) | Notes |
|---|---|---|---|
| 1 One stage | `stage` | 180 x 100 | the ground the fighters stand on (top 44 px, lit from the top left), a ledge, then the darker dice tray surface; the fighters' feet stand on the ledge line (row 40) |
| 2 Table | `table` | 180 x 100 | a tabletop with a wooden rim and a felt surface (blue in A, grey in B) and a faint dice circle |
| 2 Table | `cardframe` | 56 x 80 | the card frame for the hand, dark inside |
| 3 Frame kit | `panel` | 48 x 48 | nine-slice, corner 8 px, four corner studs |
| 3 Frame kit | `slot` | 32 x 32 | an inset slot |
| 3 Frame kit | `kitcard` | 56 x 80 | the card frame of the kit, with the panel's corner studs |
| B only | `b_hero.png` | 48 x 48 | Starter_basic_hero, east view, idle, redrawn in ink with the belt in blood red |
| B only | `b_foe.png` | 48 x 48 | the Inquisition Warden (today's fighter sprite, facing west) in ink with the sash in blood red |
| B dice | `art/pixellab-styles/final/style1_d6.png`, `style1_d12.png` | 44 x 44 | made in the style test, blank like today's dice |

Sheets (`docs/art/boards/`): `combat-kits-1x.png`, `combat-kits-2x.png`: the three directions in A (left three) and in B (right three), with the hero, the foe, the dice and three cards placed on each, so the pieces can be judged together. The placement is a quick mock, not a layout.

## How and cost
`create_image_pixflux` img2img from code skeletons (`skel.py`; the hero and foe from their game sprites), `gen.py`, then a palette snap (A: `tool/apollo_remap.py`; B: `art/pixellab-styles/post.py`, seed 1 picked for every piece). 6 pieces x 2 palettes x 2 seeds = 24, plus the B hero and foe x 2 seeds = 4: **28 generations** (balance 1888 after).

## Honest notes
- At the init strengths used (150 to 170) PixelLab stayed close to my skeletons: the pieces are clean and consistent with the sprites, but they carry little ornament. A bolder pass (strength about 110, as for the card frames) would add rivets, wear and carving, at 1 generation per try.
- The B palette snap flattens the stage planks to stripes; the Apollo stage keeps its wood.
- The B dice are the style-test dice (grey bodies, red edges); a die with a red pip needs the game to draw the pips.
