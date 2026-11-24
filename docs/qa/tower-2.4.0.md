# The Tower on v2.4.0: harder floors, rank-ups, more boons, against v1.1009

QA, on main v2.4.0 (`b79cfbb9`, #1134: floors 11 to 20 8% tougher, 21 to 29
and the floor-30 boss 6% tougher, rank-up cards, reward floors 13, 23 and 28).
The same 2,000-seed bot batch as [tower-1.1009](tower-1.1009.md) (seeds 1 to
2000, 10001 to 12000 as the check; no unlocks and all unlocks), the same
commands. Full report `tower-2.4.0/tower-batch.md`; events
`tower-2.4.0/event-tally.json`. The live-Tower pin and `qa_tower_sim_test`
(Core's re-banded guards) pass: Core's figures reproduce.

## Against v1.1009

| figure | band | v1.1009 | v2.4.0 |
|---|---|---|---|
| win floor 30, no unlocks | 5 to 12% | 14.3% (check 14.5) | **11.9%** (check 11.6) in band |
| win floor 30, all unlocks | 15 to 25% | 26.9% (26.6) | **23.6%** (22.0) in band |
| median floor (none / all) | 13 to 18 | 19 / 22 | **17** / 21 |
| reach floor 20 (none / all) | 20 to 38% | 48.1 / 63.4% | **42.3** / 60.1% (none still 4 points over) |
| reach floor 10 (none / all) | | 89.2 / 96.4% | 89.5 / 96.4% |
| mean floor (none / all) | | 19.3 / 22.1 | 18.3 / 21.5 |
| marks a run, mean (none / all) | | 28.4 / 36.1 | 26.6 / 34.6 |
| floor 10 boss, lost (none / all) | | 5.8 / 2.5% | 5.7 / 2.4% (unchanged, as built) |
| floor 20 boss, lost (none / all) | | 14.0 / 14.8% | 15.5 / 16.8% |
| floor 25 warden, lost (none / all) | | 13.6 / 8.6% | 14.8 / 9.6% |
| floor 30 boss, lost (none / all) | | 27.5 / 19.7% | 21.4 / 19.8% |
| worst ordinary floor, lost (none) | | floor 17, 8.8% | floor 21, 9.7% (then 26, 17) |

Core's changelog says 12.0% and 23.7% on its seeds; mine are 11.9% and 23.6%.
Both tops are in their bands, narrowly (none: 0.1 under the ceiling; the check
seeds, 11.6 and 22.0, are a little lower). The climb is harder where it was
meant to be (floors 11 to 29: median 19 to 17, reach floor 20 48 to 42%), the
first ten floors are unchanged, and no ordinary floor kills more than 10% of
those who reach it. The floor-30 boss is lost less often among those who get
there (fewer, stronger heroes arrive). The one figure still outside its band is
"reach floor 20", 42.3% against 20 to 38%: it was 48.1% before, so the change
moved it four points of the ten it was over; if the user wants it in band, that
is the next number to look at (Core).

## What the events do (the bot, 2,000 runs each)

| | no unlocks (v1.1009 → now) | all unlocks (v1.1009 → now) |
|---|---|---|
| floors that held a parley | 3,066 → 2,899 | 3,486 → 3,353 |
| ...fought by choice (died there) | 2,028 (60) → 1,936 (62) | 2,523 (63) → 2,413 (65) |
| runs that bought in a store | 977 → 964 | 694 → 669 |
| bargains signed | 1,718 → 1,628 | 2,019 → 1,976 |

The counts fall with the number of floors reached (about 6% fewer). Nothing
odd; every run ends.

## The rank-up cards (the bot, 400 climbs)

603 rank-ups in 277 of 400 climbs; none past rank 3, every tier is exactly the
rank-ups taken, the fight is given the tiers, and a run is saved and read back
with them (`qa_tower_rank_up_test`, a new guard). One thing found: **108 of
the 603 (18%) are for a skill that is off the die at the end of the climb** (a
later pick re-places the faces), filed for Core as #1147.
