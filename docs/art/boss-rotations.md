# Boss and hero facing: south for bosses, north for heroes (Art inventory, 25 November 2026, 0 generations)

The user: bosses face SOUTH (down) at the player who faces NORTH (up). PixelLab characters have all 8 rotations, so every figure made as a character already has both frames; the game only bundles east and west.

## 1. The Tower's bosses and wardens (`towerBosses`, `towerWardens` in `lib/data/tower/tower_tables.dart`): 20 foes
| Floor | Foe | South frame today | Where |
|---|---|---|---|
| 5 | rat_matriarch | yes | account character (the sprite is exactly its west frame) |
| 5 | dock_overseer | yes | Renn (`renn_a`, the officer in the peaked cap; the head crop is from it) |
| 5 | smuggler_captain | yes | new character (wave 5b), dark version |
| 5 | plague_hound | yes | account character |
| 5 | kroll_the_branded | **no** | no character (the nearest: `Inquisitor-General Aurel Vane`, a masked inquisitor in a dark coat and red sash) |
| 5 | brine_jack | **no** | no character (nearest: the City Wreck scavenger) |
| 10 | inquisition_legate (boss) | **no** | no character (nearest: the masked inquisitor in black and gold with a crown) |
| 15 | hollow_court_zealot | yes | the Inquisition Warden character (its head crop is from it) |
| 15 | hollow_court_inquisitor | **no** | none (nearest: Inquisition Soldier_02 or the masked inquisitor) |
| 15 | knell_keeper | **no** | none |
| 15 | horn_taker | yes | new character (wave 5b), dark version |
| 15 | purifier_vell | **no** | none (nearest: the Ash Confessor) |
| 20 | claimant_morrow (boss) | yes | account character |
| 25 | strand_colossus | yes | new character (wave 5b), dark version |
| 25 | glass_shepherd | **no** | none |
| 25 | white_admiral | yes | account character |
| 25 | tear_spawn | **no** | none (nearest: the tear herald) |
| 25 | void_manifestation | yes | new character (wave 5b), dark version |
| 25 | inquisition_penitent | **no** | none (nearest: Inquisition Soldier_03) |
| 30 | void_sovereign (boss) | yes | account character |
11 have a south frame; **9 do not**, including the floor-10 boss. Elites (an ordinary foe drawn as an elite) use the foe's own character: nothing extra; of the ordinary foes, those with characters are the ones in the fighters folder (iron_golem, white_soldier, inquisition_warden, street_bandit and the others there).

## 2. The heroes: north frame
All 7 have it: warrior (`27_hero_hero_basic_warrior`), mage (`14_hero_hero_mage`), rogue (`12_hero_hero_rogue_basic`), cleric (`05_hero_cleric`), ranger (`11_hero_rogue_starter`), dwarf (`01_hero_no_armor_and_no_shie`), orc (`04_hero_orc_starter`): each hero sprite in `assets/visuals/heroes` is exactly the east frame of that export, whose `north.png` is in the export. 0 generations.

## 3. Missing south frames: the cost
- **New full character** (pro mode, Starter_basic_hero as the style reference, 48 px, 8 directions): 10 generations each. All 9: **90 generations**. The floor-10 boss alone: 10.
- **Stand-in from an existing character** (a character on the account that suits the foe; its rotations are free): 0 generations; kroll (Aurel Vane's masked inquisitor), inquisition_legate (the masked inquisitor in black and gold), hollow_court_inquisitor (Soldier_02), inquisition_penitent (Soldier_03), purifier_vell (the Ash Confessor), brine_jack (the scavenger), tear_spawn (the tear herald). knell_keeper and glass_shepherd have no close character.
- **Suggested:** the floor-10 boss new (10), knell_keeper and glass_shepherd new (20), the other 6 as stand-ins (0): **30 generations**. Needs the Manager's OK past 30.

## 4. Hand-off (done, 0 generations)
`art/pixellab-boss-rotations/handoff/<id>_south.png` and `<id>_north.png`: the 11 Tower foes above, plus iron_golem, white_soldier and inquisition_warden (fighting already); the 4 wave-5b foes are the **dark** versions, with `_south_light.png` for the lighter. The 7 heroes: `<name>_north.png` (and `<name>_south.png`). Native PixelLab frames (60 x 60 for the older foes, 48 x 48 for the heroes and the new characters), the same size as the east and west sprites already in the game, nothing resized. Sheet `docs/art/boards/boss-south-hero-north.png` (every boss south above every hero north, and six mock fight panels with the boss at the top facing south and the hero at the bottom facing north).
