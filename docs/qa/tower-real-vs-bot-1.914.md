# The Tower: the real fights against the bot (v1.914)

QA, on main v1.914 (Core's bot fix #960, the twin-foe fix #967). The Manager's
question: Core says the bands now describe a player who rerolls well and QA's
real-fight driver reads lower. How big is the gap?

## The batch (the bot, 2,000 seeds each)

`tool/qa_tower_report.py` on `test/qa_tower_sim_test.dart`, v1.911 engine
(before #967, which does not change the numbers: the bot does not use the
launcher).

| measure (no unlocks) | design band | 1.906 | 1.911 |
|---|---|---|---|
| median floor | 13 to 18 | 17 | 18 |
| mean floor | | 17.7 | 19.0 |
| reach floor 20 | 20 to 38% | 36.2% | 42.4% |
| win floor 30 | 5 to 12% | 12.2% | 17.6% |
| win floor 30, all unlocks | 15 to 25% | 22.6% | 27.0% |

By race (no unlocks): the median floor is 20 for dwarf, 19 for elf and orc,
17 for voidkin, 16 for human; the top is won by 24.7% of dwarfs and 8.0% to
9.5% of voidkin and humans. Seeds 10001 to 12000 agree (top 18.6%).

The bands in the report script are the design's (tower-mechanics.md §11);
Core re-set the bands of the CI guard, not these. By the design's bands the
bot is now above on floor 20 and on the top.

## The real fights (QA's driver, one run each, v1.914)

`test/qa_tower_playthrough_test.dart` drives the real app and the real
fights: the bot's picks are not used, the driver takes the first oath or boon
offered, the first Level Up pick, drinks a potion when hurt, and rerolls the
dice with a simple rule. One run per row, random seed:

| race, calling | how it ended |
|---|---|
| human warrior | died on floor 19 |
| orc warrior | died on floor 9 |
| human mage | died on floor 15 (the warden) |
| dwarf warrior | reached floor 29 alive (the driver's own cap stopped it) |
| elf ranger | not run: the driver cannot pick the calling (driver limit) |

Mean floor of the four: **18**, against the bot's mean of 19.0 (and the
medians of the same races, 16 to 20). With one run each this is not a
measurement, but it shows **no gap of the size "the driver reads lower"
suggested**: the earlier low reads (floors 5 to 7) were the two blockers,
not the difficulty (#949 the warden freeze, #963 a floor with a repeated foe).
Both are fixed (v1.910, v1.914).

## What to do with it

- The bands and the real fights agree within what one run each can say. A
  proper check needs about 30 real runs a race, which is hours; the batch
  stays the instrument, and the real runs stay a smoke test.
- Both races at the bottom (human, voidkin) die earlier in both: the race
  gap of #955 is real, not a bot artefact (human died on 19 and 15 here with
  warrior and mage; the dwarf went to 29).
- Every floor of the five real runs started its fight; no floor failed to
  start after #967.

## Driver notes (not game bugs)

- The driver's floor counter runs ahead of the real floor (it counts every
  "stand" screen, including the repeats after an oath); it stopped the dwarf
  at its cap on real floor 29.
- The elf and dwarf runs of an earlier session failed at the creation
  screen (calling card not found); the dwarf run now works, the elf ranger
  still does not.
