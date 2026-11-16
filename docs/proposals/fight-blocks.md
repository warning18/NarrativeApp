# Stats blocks for the fight (UX-2, pictures only)

The user: "propose designs for characters' stats blocks in combat (a dedicated one per group of enemies would be great)."
Pictures: `docs/ux-shots/fight-blocks/`. The mock is `test/ux_fight_blocks_mock_test.dart` (UX_SHOTS=<folder>, UX_DIR=a|b|c, UX_GROUPS=1): the screen is drawn by the mock with the real heads, the real fight figures and real enemy ids; nothing in `lib/` changes. The numbers in the pictures are made up (a level-7 Mage and Kelda against enemies at 60-90 % health).

## What a block shows today (`fight_board_view.dart`, `fight_cards.dart`)
Hero and companion: the head (34 dp), the turn number, the name, the damage (bolt, the hero only) and the armour (shield, the hero only), the health bar with its numbers (and the blow on the way, "-N"), the status chips, the parry chip. Enemy: the head, the name (orange; gold frame for an Elite or a boss), the health bar (with the execute tick), the status chips (guard, wind-up, staggered, rally, "N more" for elements, goals, reactions, affixes), and the intent box (what it will do). Blocks are 164 dp wide (two columns at 360, 190 at 412), about 78 dp high.

## Three directions (`blocks.png`: the hero, a companion, an enemy, an Elite and a boss in each; `blocks-320.png`: the same at 320 px)
- **A, Plate**: today's block in the game's pixel frame: head, name and damage, the bar, armour, chips and intent in a fixed bottom row; the rank (ELITE, BOSS) next to the name, a gold frame. Closest to today, cheapest.
- **B, Banner edge**: a banner strip down the left edge carries the side (the hero's green, an enemy's orange or its group's colour and emblem) and the rank at its foot; the head, name and bar to its right. A strong colour code but the strip takes 22 dp of a block that is already narrow.
- **C, Nameplate and gems**: a nameplate across the top in the side's or the group's colour (the emblem at its left, the name, the rank at its right), the head under it with the armour and the damage as two small gems on its corner, the bar next to it, the chips and the intent under the bar. The numbers sit in the same place on every block, and the group is read from the plate before anything else. **My pick.**

Full screens, a mixed fight (four enemies of four groups: Dominion, Crows, Vigil Elite, the dead) and a boss (Aurel Vane with two soldiers), with the hero and Kelda, at 360 x 780: `screen-a-mixed.png`, `screen-a-boss.png`, and the same for b and c. In B and C the enemies wear their group (the colour, the emblem, the ornament); in A they keep today's orange frame (it is the plain version).

## A variant per group (`groups-c.png`)
For C: the nameplate colour (the clan's colour, or Apollo for the kinds), the emblem (the clan's own banner cropped to its sign, or a pixel glyph: skull, void, paw, gear, halo, horns, fist, wave, mask), and a corner ornament (studs for the clans and the people, spikes for the Pit and the Void, rivets for constructs and giants, bites for the dead, beasts and the Tide-Kin). The groups are the data's own: the `faction` of enemies.json when it has one, else the `kind`.

| group | enemies | who |
|---|---|---|
| Lantern Dominion | 12 | Inquisition Warden, Inquisition Soldier, Inquisition High Warden, Inquisitor Clement, Overseer Renn, Inquisition Auxiliary, The Legate's Champion, White Soldier, Purifier Vell, Cassian Oriel, Regent of the Lantern, Inquisitor-General Aurel Vane, Brother Clement |
| Salt Crows | 7 | Slum Thug, Street Bandit, Smuggler Captain, Brine Jack, The House's Bouncer, Back-Room Looter, Wreck Scavenger |
| Cinder Compact | 2 | Brodin Stonehand, Quarryman, Tove the Unheard, of the Anvil-Deaf |
| Mire Courts | 2 | Sedge of the Returned, Wen, Guide of the Heron’s Wake |
| Grey Vigil | 2 | Halvard, Spearman of the Last Watch, Ysel, Candlebearer |
| Ashen Penitents | 2 | Inquisition Penitent, Masked Penitent |
| The Choir (angels) | 2 | Sentinel of the Choir, Judicator of the Choir |
| The Pit (demons) | 2 | Pit Wretch, Tormentor of the Pit |
| Giants | 1 | Gorm, Kept by the Frost |
| Tide-Kin | 1 | Kraken Arm |
| The dead | 9 | Catacomb Ghoul, Bone Warden, Bone Sexton, Drowned Pilgrim, Unmade Knight, The White Admiral, The Teind-Rider, The Knell-Keeper, The Rime Bailiff |
| The Void | 9 | Grey Candle, Void Stalker, Void Manifestation, Void Hound, The Unstitched, Void Archon, Hollow Reflection, The Sovereign, The Tear-Herald |
| Beasts | 3 | Rat Matriarch, Harbour Rat, Plague Hound |
| Constructs | 3 | Iron Golem, The Strand Colossus, The Glass Shepherd |
| People of no clan | 21 | Cultist Acolyte, Hollow Court Zealot, Hollow Court Inquisitor, Kelda, Turned, Sable, Turned, Maren, Turned, Liora, Turned, Vess, Turned, Grosh, Turned, Tobin, Turned, Malrik, Turned, The Horn-Taker, Hesk Morrow, Grand Master, Maud Tallis, Eldest Wickwarden, Sore Loser, High Lantern-Bearer Orsolya Keld, Watch-Captain Edda Grey, Master Hollis Reck, The Heron Queen's Hand, Captain Mireille Sorrel, The Ash Confessor |

## Cost to build
C (and A or B) is one block widget used for the hero, a companion and an enemy: it replaces `_buildPartySlot` and `_buildEnemySlot` in `fight_board_view.dart` (a shared file: I check the open PRs on it before building; its card logic stays). About 1 PR for the block and the group look, plus a second for the 15 emblems if they are drawn as assets instead of the pixel glyphs. Group look is a table (`group id -> colour, emblem, ornament`) in my file, derived from `faction` and `kind`.

## What it needs from Core
Nothing is required. Two things to know: (1) 21 enemies have no faction and are all `kind: person` (the Hollow Court, the turned companions, the claimants, the champions, the Sore Loser): they share one "people of no clan" look; a `group` field on them (court, turned, champions) would let them have their own, Core's to add if wanted; (2) the armour gem of an enemy is its guard in the fight (`enemy.guard`, a runtime value, hidden at 0), not a data field.
