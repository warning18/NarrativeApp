# Style exploration "brut" (24 November 2026; 0 generations; waits for the user's pick)

The user: "too much detail; something less detailed, more raw (brut), playing with shadows, with a unique colour for each clan. Globally the art should not be too complex, but have a style of its own."

Board `docs/art/boards/style-brut-exploration.png`: the fire vignette, the dice and a clan banner (the Dominion's) in three directions derived **in code** from the existing files (`art/pixellab-brut/derive.py`: threshold, local threshold, blur and posterise), plus a swatch row of one strong hue per clan.
- **A, cut paper**: flat black silhouettes on paper, the clan colour as the only hue.
- **B, woodcut**: two values with hard edges that follow the forms, one accent.
- **C, one light source**: big shadow shapes, the light from the top left, almost no interior detail, one accent.

## What the code derivations show (honest)
- **A** works on the fire (the arch and the flame read as a silhouette with the orange accent) and on the banner (the lantern and the E read cleanly in blue); on the dice it fails (the dice melt into the paper).
- **B** keeps too much of the original's detail on the fire and the dice (it reads as a harsher version of the same picture); it is clean on the banner.
- **C** is the rawest: the banner reads, the fire and the dice become unreadable blobs. Deriving from detailed art cannot give a drawn look; a style of its own needs the shapes to be drawn that way, so a PixelLab pass is needed for any of them.

## One colour per clan (never the warning red A53030)
| Clan | Hue | Hex |
|---|---|---|
| The Lantern Dominion | blue | 2F6FE0 |
| The Salt Crows | magenta | E0479E |
| The Cinder Compact | orange | E8782A |
| The Mire Courts | green | 3FB06A |
| The Grey Vigil | yellow | E8C21A |
| The Ashen Penitents | violet | 9B5DE5 |
The hue angles (about 215, 320, 24, 140, 52, 270) are spaced 28 to 88 degrees apart and none is near the warning red (355). The Crows' old red (B0303F) and the Dominion's blue are changed or sharpened; the Vigil moves from grey to yellow; the Penitents' sand becomes violet.

## PixelLab pilot (proposal, nothing called)
For the direction the user picks: the same 3 subjects (fire vignette 96 x 64, dice vignette 96 x 64, the Dominion banner 64 x 128) by img2img from the existing art with a prompt of the style, 1 generation each: **3 generations per direction, 2 seeds = 6** (under 10). For all three directions at one seed: **9**. Free afterwards: a palette snap to the style's values and the clan hue.

## Pilot done (24 November): cut paper, 6 generations, balance 1772
The user picked A (cut paper) and the clan hues above. Board `docs/art/boards/style-brut-pilot.png` (original | seed 1 | seed 2); files `art/pixellab-brut/final/{fire,dice,banner}_seed{1,2}.png` (PNG8: near-black, paper cream and one hue: orange for the fire, green for the dice pip, the Dominion blue for the banner). Each is img2img (init strength 220 to 230) from a code skeleton in `art/pixellab-brut/skel/`: the cut-paper derivation of the fire and of the banner, and a dice skeleton drawn in code (two bold black dice with big paper pips and a light top-left edge, a ground shadow).
**Honest result:** at that strength PixelLab copied the skeletons almost exactly. The fire and the banner are the derivation with small clean-ups (seed 2's flame is a little more broken); the dice are essentially my skeleton, and the green pip did not survive. So the pilot proves the look (flat black silhouettes, paper, one hue, bold pips and a light edge read as dice) but not what PixelLab adds. A bolder pass is the same 6 generations at an init strength of about 120, which would let it redraw the shapes in its own way, at the risk of losing the silhouette discipline. The banner's generated grey background was keyed out to transparent.
