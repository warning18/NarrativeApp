# Hand-off to UX: the gamble outcomes and the Stat point card picture (Art, 27 November 2026)

The user: the dud should be generated art too. Nine cut-paper tarot vignettes, 96 x 64 (the same size as `loot_*.png`), the five tones plus red, objects filling the frame, text only, 9 generations (cap 12, no retries): `art/pixellab-cutpaper/tarot/gamble/gen.py`.
## Files (`art/pixellab-cutpaper/tarot/handoff/`)
| File | Outcome | Picture |
|---|---|---|
| `gamble_gilded.png` | best gear one tier up | a gilded breastplate (cream and red) |
| `gamble_twin.png` | you get both other cards | a pair of cards, a black spade and a beige diamond |
| `gamble_hoard.png` | coins | a heap of cream and red coins |
| `gamble_dud.png` | nothing | an empty open hand, black on navy, a red smear |
| `gamble_wound.png` | -20% max health | a cracked black heart with a red crack |
| `gamble_spill.png` | -1 potion | a broken flask and a red puddle |
| `gamble_bright.png` | skill one rarity up | a big cream star on navy with small stars |
| `gamble_hex.png` | next floor's foes stronger | a black eye with a red pupil in a hex circle |
| `stat_point.png` | the Stat point card | a hexagonal chart with spokes and a red star (cut paper radar), to replace the radar icon placeholder |
The good ones lean cream (the cream tones kept with brighter snap levels), the bad ones lean ink and red. Sheet `docs/art/boards/gamble-vignettes.png` (with two existing tarot vignettes for scale).
## Notes
`gamble_gilded` is red-heavy (no gold in the five tones); `gamble_hex` and `stat_point` are a little noisy at the edges. The code-drawn radar chart glyph (`art/pixellab-bookmarks/handoff/stats_32.png`) is an alternative for the Stat point card if a cleaner chart is wanted.
