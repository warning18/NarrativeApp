# The first-launch intro, redrawn: two versions (picture first, nothing wired)

> **Chosen by the user: Version A "Alster in ashes".** The final four plates are in `art/pixellab-intro/final/` (README, picks.json): seeds A1 s5, A2 s6, A3 s5 with the sign text painted out, A4 s5. Version B stays in `staged/` as an alternative.

Sheet: `docs/art/boards/intro-redraw.png`. Files: `art/pixellab-intro/staged/<plate>_s5|s6.png` (180x320, PNG8) + `index.json` (prompts, seeds, per-plate notes). 16 generations (balance 1175.5 to 1159.5). The intro today is eight beats of code painters (`intro_art.dart`, 70x124 grid); the redraw replaces the four picture plates and keeps the timing, the four lines, the die (`Die3D`, bone skin), the title and the fade.

## The four plates (both versions)
| Plate | Beats | What it is |
|---|---|---|
| 1 | 1 to 2 (0 to 4.5 s) | the Great Shroud burning over the ash-sky city |
| 2 | 3 (4.5 to 6.5 s) | Alster on alert: tower and bell, the harbour giant, the white ships far off, calm streets |
| 3 | 4 (6.5 to 8.5 s) | Tallow Street, the Blind Beggar's front with chalked doors |
| 4 | 5 to 7 (8.5 to 13.5 s) | the room where the code die drops and rests under the title |

## Version A: "Alster in ashes"
Wide establishing plates in warm ash dusk, the same compositions as today's storyboard (`docs/ux-shots/intro-storyboard-d.png`). The camera pushes down through the plates by code (a slow zoom and a vertical pan, smoke and embers as code particles). Calm and faithful to the lore as written: no shell before beat 6.
- Strengths: matches the written beats exactly; the street (plate 3) and the tavern (plate 4) fit the real `StreetViewScene` look.
- Weaknesses: less drama; the plate-3 tavern art has baked text (a "BEGGAR" sign in seed 5, garbled letters in seed 6): paint it out or use a code sign (French build).

## Version B: "The night of the shells"
Closer, darker, dramatic framings: a burning banner filling the frame, the bombardment of the harbour under the giant, a chalked door lit by one lantern, the table in a pool of light. More cinematic; the camera cuts closer each beat.
- **Lore tension (Narrative's note in `intro-animation-d.md`):** the first shell comes when the die stops (beat 6), not before; so plate B2 (iron balls over the harbour) is the beat-6 plate, and beat 3 needs a calm plate (A2) instead. B with a calm beat 3 is a mix.
- B4 seed 6 has a die already drawn in the light pool; the die is code, so the pool must be empty (seed 5 has dice-like boxes on the table).

## Recommended: A for beats 1 to 4, B for the end
Plate A1 (the Shroud), A2 (the calm city), A3 (the Blind Beggar; the sign painted out), then B4 (the table in the pool of light) for the die and B2 as the beat-6 flash (the shell's light crossing the room is a code flash over B4; B2 itself can be the camera's cut for one second). If the user wants only one version, A is the safe one and B the strong one.

## How it moves (code, the UX's part, later)
- **Camera:** each plate cover-fits the 70x124 ratio and zooms slowly; beats 3 to 4 are a downward pan through the smoke (the plate's lower third is the next plate's top).
- **Layers by band** (free, cut by code): sky, skyline, foreground move at three speeds for a parallax push; fire, embers and smoke stay code particles so the plate stays still.
- **Optional PixelLab motion** (not generated): `animate_image` on a plate costs about 1 generation per 8 frames at 64 px and more at 180x320 (width x height x frames limit); a cheaper way is to cut a 64x64 piece (the burning banner's flame, one ship's sail) and animate that: about 4 pieces, 4 to 8 generations. Only if the user wants real flame animation.

## Cost
Done: 16 generations (4 plates x 2 versions x 2 seeds). To finish a version: clean-up of the baked text and the die in the pool by hand (0), a re-roll of a plate if rejected (1 each); optional animated pieces 4 to 8. Total to ship either version: under 30 more.
