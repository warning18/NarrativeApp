# Fight backgrounds: PixelLab proposals (picture first, nothing wired)

Sheet: `docs/art/boards/fight-backgrounds.png` (today's code painter | seed 11 | seed 12 for five sceneries). Files: `art/pixellab-backgrounds/fight/<scenery>_s11.png` and `_s12.png` (180x320, palette PNG8, 24 colours) with raw downloads and `index.json`. Cost: 10 generations (pixen, 1 each). Same style suffix as the approved Tower backdrop.

The fight has about 22 stages (`FightStage`); the five tried are dunes, woods, ruins, quay and the snow coast. The screenshots of today's painter (4 of the 5) also show the fight's own cards, rain and fighters; the code layer under them is the sky, hills and ground.

## How a picture keeps the hour and the weather
The fight already lays the hour as a veil (`paintFightBackdrop`) and the weather and anomaly over the stage, so the art replaces only the stage's shapes:
- **Open scenes with a sky** (dunes, quay, snow): use the art from the horizon down; the code keeps painting the sky (sun, moon, stars, clouds) above it, because a sun baked into the picture would still shine at night. At night the veil darkens the art; the quay lanterns get a code glow.
- **Enclosed scenes** (woods, ruins): full-bleed art (no sky to animate); the hour veil tints it (dark at night), rain and mist drift on top.
- Weather particles, anomalies and stars stay code in every case. Colour match: the veil is multiplied, so the pictures stay in the `FightScenery` hue family.

## Recommendation per scenery
| Scenery | Pick | Why | Verdict |
|---|---|---|---|
| dunes | seed 12 | clean horizon, empty ground, dunes read as depth | improve (art below the horizon, code sky) |
| woods | seed 12 | a clearing, flat ground; seed 11's centre path draws the eye behind the fighters | replace |
| ruins | seed 12 | open flagstone floor, calm; arch framing | replace |
| quay | seed 12 | planks are flat ground, lanterns; seed 11 is a baked sunset | improve (art below the water line, code sky) |
| snow coast | seed 12 | flat snow ground, cliffs far right; seed 11 has a busy shore | replace |

**Keep as code:** the sea/waves (the earlier try did not tile and the swell is parametric), the salt flats, the ash plain, the glass, the hall, the city road and the ship deck; and any stage that is mostly weather. Their look is a few flat shapes and hour tint, and a picture adds weight without changing the read. Do them one by one only if the user likes these five.

## Honest limits
- The pictures are portrait 180x320, cover-cropped on the phone like the Tower backdrop: the fight area is in the lower 45%, so the ground must stay empty (it is, in the picks).
- A picture is richer than today's painter but static: no parallax, no swaying trees unless the code adds a layer. They would sit behind the 55% scrim the Tower uses, if the UI text needs it.
- The ruins and the quay have a strong central perspective (arch, pier). With two fighters in the middle they can compete; the veil/scrim handles it.
