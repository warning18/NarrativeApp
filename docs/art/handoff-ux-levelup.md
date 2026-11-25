# Hand-off to UX: the Level Up screen art (Art, 25 November 2026)

The user picked **all three plates** (UX rotates them) and the **red ribbon** header. Files only; nothing in the game was changed. Mock: `docs/art/boards/levelup-plates.png`.

## Files (`art/pixellab-levelup/handoff/`)
- `levelup_plate_shrine.png`, `levelup_plate_anvil.png`, `levelup_plate_yard.png`: 180 x 320 PNG, cut paper in the Tower plates' five tones (ink 090A14, dark 28283A, paper shadow C9C2A6, paper E7E1CD, deep red A53030), no text, no characters. Suggested path `assets/visuals/levelup/<name>.png` (UX's call). A shrine (a black arch, a red sigil circle on the floor, a stone altar), an anvil in a forge yard (a red-lit brick forge, sparks, black rubble), a training yard (a post and a weapon rack at the sides, a red banner).
- `levelup_header_ribbon.png`: 168 x 27 PNG, transparent, a flat red ribbon with swallow-tail ends and a cream border, **blank**: draw "Level N" on it as text (white on the red).

## Layout the plates are made for
Same 180 x 320 plate format as the Tower plates (scale 2x for a 360 x 640 screen). Keep clear: the **header on the top 10 to 40 px**; the **hero standing in the middle** (the heroes' **south** frames, `art/pixellab-boss-rotations/handoff/<hero>_south.png`, 48 px drawn at 2x, feet near plate y 185 to 195, centred at x 90); the **stat panel in the bottom ~75 px** (y 246 to 312 in the mock, a paper strip with an ink frame). The middle and the bottom of every plate are empty paper on purpose.

## With the stat symbols
`art/pixellab-stats/handoff/<stat>_24.png` and `_32.png` (handed off before): the mock puts the 24 px symbols in two rows of four on the paper strip.

## Notes
Rotating the three: any one per level-up visit (by level or at random). The scroll header was the other option and is dropped. The plates carry no text, so the game's strings and numbers stay code.
