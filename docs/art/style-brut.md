> **Standing rule for everything Art draws (the user, 25 November):** "the art should not have too many details, like the backgrounds, but more an arty direction". Bold simple silhouettes, a few strong ink strokes, **no hatching, no shading ramps, no small texture**, lots of empty paper, one spot of colour, a recognisable shape at a glance: think a stamp or a woodcut, not a small illustration. Prompts must say "bold simple silhouette, no hatching, no shading" and must not ask for hatching.


> **Detail level in numbers (the one rule for plates, tarot, icons, dice and banners; 25 November):**
> | Piece | Canvas | Smallest region kept | Tones | Line weight | Code |
> |---|---|---|---|---|---|
> | Tower plate (the approved plates are NOT simplified: they keep the text-only generation as it is; 60 px is for new plates only) | 180 x 320 | **60 px** (the pass merges any region of one colour smaller than that into what surrounds it) | at most 5: ink, dark, paper shadow, paper, deep red | none (shapes, no outlines) | `art/pixellab-cutpaper/simplify.py` |
> | Tarot vignette | 96 x 64 | **16 px** | at most 5, the same | none | same |
> | Icon | 32 x 32 | **3 px** (about 2 x 2) | ink black, paper white, one spot hue, at most one grey | 1 px outline; 2 to 4 inner ink lines and one paper highlight for form; no hatching | by the prompt |
> | Die, banner | 44 / 64 x 128 | 6 / 12 px | the five above plus the clan hue on a banner | none | same pass |
> A piece with more regions than that is too detailed; a piece with larger flat areas and fewer than about 4 regions per 1,000 px is too bare. Merge, do not blur: no antialiasing, no gradients.

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

## Second try, looser (25 November): 6 generations, balance 1766
Text only for the fire and the dice (no skeleton), the original Dominion banner at init strength 80 for the banner; prompt: cut paper, shapes cut from black paper on cream paper, strong hard shadows, very simple bold shapes, one colour. Board `docs/art/boards/style-brut-pilot2.png` (original | seed 1 | seed 2 snapped to ink, paper, a paper shadow and the one clan colour | the two raw outputs). Files `art/pixellab-brut/final2/{fire,dice,banner}_seed{1,2}.png`, raw in `art/pixellab-brut/raw2/`.
This time PixelLab drew: the fire is a black hand holding a flame (seed 2: inside a black laurel ring), the dice are black cubes with cream pips and a soft shadow (these have a little 3D shading), the banner keeps the lantern and the E in cream on black. It is a cut-paper look with one hue (orange, green, Dominion blue), less detailed than the first set. Caveats: the dice are drawn in a 3/4 view, not flat; seed 2 of the banner keeps a beige border where the grey ground did not key out; the paper-shadow level (a second cream) is mine.

## Icon recipe: V1 light ink (user's pick, 25 Nov 2026)

Look: black outline, paper-white body, a few ink lines, one spot of colour. Rule: no isolated specks, 2 px minimum region, colours only from the Ashen Ink tokens (ink 090A14, paper E7E1CD, one spot: red A53030, heal 7DBE6A, tide 4FB0B0).

1. Generate (PixelLab `create_image_pixflux`, 32x32, text only, 1 gen): the object alone, centred, "bold black outline, dark filled body with a few light highlights, one spot of colour, pixel art, no background".
2. Code pass (0 gens): `art/pixellab-cutpaper/lighter.py` -> `v1_final(im, pre=0, min_area=2)`. Edge pixels become ink; dark interior becomes paper; light interior becomes ink lines; the spot pixels are classified to red/heal/tide; regions under 2 px are merged. For icons whose lines break into specks (helm) use `pre=4` (merge under 4 px first) or regenerate once.
3. Output: `art/pixellab-cutpaper/hi/final/v1_<icon>32.png`; sheet `docs/art/boards/icons-v1-final.png`.
