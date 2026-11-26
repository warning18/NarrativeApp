# Hand-off to UX: the Tower fight backgrounds in cut paper (Art, 26 November 2026)

The user approved the test and the rest. 22 plates, 180 x 320 PNG, cut paper in the Tower plates' five tones (ink 090A14, dark 28283A, paper shadow C9C2A6, paper E7E1CD, deep red A53030), no text, no people. Files `art/pixellab-fightplates/handoff/fight_<name>.png`; suggested target `assets/visuals/tower_fight/` (UX's call). Sheet `docs/art/boards/fightplates-all.png` (each plate with a foe's south frame at the top, the warrior's north frame at the bottom and the boss panel and the slim strip as paper blocks, like the v2.10.9 layout; the 3 dice plates below).
The middle and the lower two thirds of every plate are an empty floor on purpose (the fighters and the panels sit there). The stray figures the model drew were painted out in code (`art/pixellab-fightplates/post.py`); five plates were redrawn "deserted" and one doorway figure was painted over.

## Which plate for which fight
| Fight | Plate(s) | Today's file it replaces |
|---|---|---|
| Band 1 floors (1 to 10, ordinary) | `band`, `band1_b`, `band1_c`: a tall hall with a light shaft; a curved stair under an arch; a hall with a gallery bridge. Pick by floor number mod 3 (or the seed) | `tower_ink/fight_band1_scene.png` |
| Band 2 floors (11 to 20) | `band2_a` (pillared hall), `band2_b` (library with a red carpet), `band2_c` (a broken brick hall) | `fight_band2_scene.png` |
| Band 3 floors (21 to 30) | `band3_a` (a round chamber with a moon window), `band3_b` (a shard-scattered stone hall with a red stripe), `band3_c` (a black stair up to a red doorway) | `fight_band3_scene.png` |
| Warden, floor 5 / 15 / 25 | `warden` (an iron gate and a red lantern), `ward15` (a hollow court of empty chairs and a red sigil), `ward25` (a glass hall with a red tear) | `tower_ward5/15/25` |
| Boss, floor 10 / 20 / 30 | `boss` (torn red banners), `boss20` (a long red carpet to an empty throne), `boss30` (a black abyss with a red rift) | `tower_boss10/20/30` |
| Elite fights (an elite affix on an ordinary floor) | `elite1`, `elite2`, `elite3` (red braziers; red lanterns and spikes; a glowing red floor crack): one per band, or any | none today |
| The rival (event) | `rival` (a duelling ring) | none today |
| Under the dice, by band | `dice1`, `dice2`, `dice3`: the ground seen from above (stone tiles, planks, black glass). `dice3` is nearly empty (one red crack) | `fight_band1/2/3_dice.png` |

## Notes
- Foes without a south frame (not a Tower boss or warden) keep their icon or head as today.
- Cost: 19 first tries + 5 redraws = 24 generations (plus the 3 of the test). Balance 1016 -> 989.
