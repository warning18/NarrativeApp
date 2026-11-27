# Hand-off to UX: the five redesigned Inquisition bosses (Art, 27 November 2026)

The five Tower bosses and wardens that shared one masked Inquisition look now have their own designs. New characters (pro mode, Starter_basic_hero as the style reference, the dark palette, 48 px, 8 directions), 10 generations each, 50 in all (`art/pixellab-chars5/gen.py`, ids in `art/pixellab-chars5/ids.json`, raw in `raw/`):
- `kroll_the_branded` (Inquisitor Clement, floor 5): a gaunt grey-haired inquisitor in a long black coat with a white collar and a blue sash, a branding iron.
- `hollow_court_zealot` (floor 15): a hunched figure in a dark violet hood with a white half mask, a crystal shard in clasped hands.
- `hollow_court_inquisitor` (floor 15): a tall figure in a violet coat and a tall pointed black hat, a staff with a seal.
- `inquisition_penitent` (floor 25): a barefoot bandaged figure in a violet hood and a torn grey skirt, a barbed scourge.
- `purifier_vell` (floor 15 pool in the code's warden list for 5/15; Purifier Vell): a soot-black apron, goggles and a lit torch in each hand.

## Files
`art/pixellab-boss-rotations/handoff/<id>_{south,north,east,west}.png` (48 x 48, native frames): **these replace** the stand-ins of the same names from the earlier hand-off (the stand-in files are kept in `art/pixellab-boss-rotations/standins_old/`). Use them for the boss scene: the boss **south** (facing the player), the hero **north**. Sheet `docs/art/boards/bosses5-south-north.png` (the five south frames with the old stand-in beside each, the heroes' north frames, and five mock fights).

## Notes
The 48 px size is smaller than the older 60 px foes (the rat matriarch, the claimant, the void sovereign); scale as you do for the other new characters. The hollow court inquisitor's pointed hat reads a little like a witch's; it is distinct from the others.
