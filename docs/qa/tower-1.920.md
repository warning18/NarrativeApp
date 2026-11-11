# The Tower on v1.920: the batch, the real fights, the dice panel

QA, on main v1.920 (dice to the bag v1.917, "Your dice" panel v1.918, the
fight's place v1.919, the Tower's curve v1.920). The Manager asked for three
things: the real-fight driver with a die swapped in the panel, the 2,000-seed
batch against Core's figures, and a guard for the bag.

## 1. The batch confirms Core's figures

`tool/qa_tower_report.py` on `test/qa_tower_sim_test.dart`, seeds 1 to 2000
(10001 to 12000 as the check). Full report: `tower-1.920/tower-batch.md`.

| figure | Core | QA |
|---|---|---|
| win floor 30, no unlocks | 13.6% | **13.6%** (seeds 10001 to 12000: 13.3%) |
| win floor 30, all unlocks | 28.7% | **28.8%** (27.1%) |
| floor 10 boss, lost | 9.0% | **9.0%** |
| floor 20 boss, lost | 11.9% | **11.9%** |
| floor 30 boss, lost | 22.8% | **22.8%** |
| worst ordinary floor, lost | 8.2% | **8.2%** (floor 27) |

Also: median floor 17, floor 20 reached by 41.5% (all unlocks 62.2%), mean
floor 18.1 (22.1), marks a run 28.6 (37.5). The only difference is 0.1 point
on the all-unlocks top (28.8 against 28.7), a rounding of the same batch.

**By race (no unlocks), the gap is wider than at v1.911:**

| race | median floor | floor 20 | top | top, all unlocks |
|---|---|---|---|---|
| elf | 20 | 54.2% | 24.2% | 38.9% |
| dwarf | 19 | 49.9% | 16.4% | 36.9% |
| orc | 18 | 44.3% | 14.8% | 32.8% |
| voidkin | 15 | 30.7% | **4.7%** | 17.1% |
| human | 14 | 29.0% | **7.8%** | 18.3% |

Voidkin is under the design's 5% floor for the top; human and voidkin top
rates were 8.0% and 9.5% at v1.911. Core's v1.922 (the human and voidkin start,
option B) is aimed at this; the batch will be rerun when it lands.

## 2. The real fights (the driver, v1.920)

`test/qa_tower_playthrough_test.dart` now also opens a new die on the floor
screen and puts it in play (inert unless `QA_PLAY`).

| run | die | how it ended |
|---|---|---|
| human warrior | Court Die gained on floor 2, put in play | died to the floor 10 boss |
| orc warrior | Court Die gained on floor 2, put in play | died on floor 9 |
| dwarf warrior | Court Die gained on floor 2, put in play | died to the floor 10 boss |
| human mage | none | died on floor 1 |

- **The dice panel: no dead end.** In three runs the new die showed its red
  dot, opened to its faces, "Roll this die" put it in play, and the panel then
  read "In play" with the button disabled (`panel-die-in-play.png`,
  `panel-die-open.png`). The die the hero started with stayed in the bag.
  Pictures at 412 dark: the tags ("In play", "Resonates"), the faces row and
  the button read clearly, nothing overflows.
- **No floor failed to start** (floors 1 to 10 of four runs).
- **What the driver cannot tell.** Its deaths at floors 9, 10, 10 and 1 sit
  well below the bot's mean of 18.1. The driver plays the dice in the most
  basic way (roll, confirm, no rerolls, no keeping the right faces) and takes
  the first card offered; the bot takes better gear, the clan's die and a
  heal first, and Core's bands now describe a player who rerolls well. So the
  driver is a floor under "a player who does not think", with one run per
  race: it shows that a floor starts and what the player sees, not an average
  and not a win rate. As an anchor for a "typical player" it gives a lower
  bound only (a thoughtless player dies by the first boss), not the middle.
- The human mage died on floor 1 (the Sentinel of the Choir, 15 health, 11
  rounds). With basic dice play a mage is weak at level 1; that is the
  driver's play, not a finding by itself, but a first floor that can kill a
  mage that does not reroll is worth Core's eye when the typical player is
  measured.

## 3. The guard

`test/qa_tower_die_bag_test.dart`: a saved run with a die on offer; taking it
puts it in the bag, marked new and not in play, the other die stays; opening
it clears the dot; "Roll this die" is enabled, puts it in play, and the run's
saved die becomes it; the button then reads disabled. Red with
`towerChooseDie` broken (checked, not committed), green on main. About 8 s.
