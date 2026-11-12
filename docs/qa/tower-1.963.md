# The Tower on v1.963: the floors without a fight are live

QA, on Core's switch (`claude/core-switch`, merged as v1.963): the floor
events' version 2, the user's option 2: the parley, the merchant (with shop
rooms after the bosses of floors 10 and 20) and the bargain, at the foe scale
1.17 and the extras `{25: .42, 30: .34}`. The same 2,000-seed bot batch as
`tower-1.961.md` (seeds 1 to 2000; 10001 to 12000 as the check; no unlocks and
all unlocks), run on the branch before the merge, and the events report
extended for the new floors. Reports: `tower-1.963/tower-batch.md`,
`tower-1.963/event-tally.json`.

## Core's figures reproduce

The live-Tower pin (`qa_tower_live_pin_test.dart`, re-set to 66 / 240 / 9,609
and 144 / 323 / 11,140) and `qa_tower_sim_test.dart` (its events default is now
`towerEventsLive`) pass together (7 tests).

| figure | Core | QA (v1.963) | v1.961 |
|---|---|---|---|
| win floor 30, no unlocks | 14.25% | **14.25%** (check seeds 14.1%) | 13.2% |
| win floor 30, all unlocks | 26.55% | **26.55%** (26.6%) | 24.9% |
| floor 25 warden, lost (none / all) | 13.8 / 8.0% | **13.8 / 8.0%** | 13.5% (none) |
| floor 30 boss, lost (none / all) | 27.5 / 19.4% | **27.5 / 19.4%** | 26.2 / 23.5% |
| floor 10 / 20 boss, lost (none) | | 6.1 / 13.8% | 6.3 / 13.6% |
| floor 10 / 20 boss, lost (all) | | 2.6 / 14.6% | |
| worst ordinary floor, lost (none) | f26 8.7% | **8.8% (floor 17)**, then floor 26 at 8.7%, floor 24 8.1% | 8.8% (floor 22) |
| worst ordinary floor, lost (all) | f19 6.2% | **6.2% (floor 19)** | |
| median floor (none / all) | | 19 / 22 | 18 / 22 |
| reach floor 20 (none / all) | | 47.7% / 63.1% | 45.2% / 62.5% |
| mean floor (none / all) | | 19.2 / 22.1 | 18.7 / 21.9 |

No ordinary floor is over 10% (the worst is 8.8%). One small difference with
Core's list: with no unlocks my hardest ordinary floor is 17 (8.8%), then
Core's floor 26 (8.7%); the conclusion is the same.

## What the new floors do (the bot, 2,000 runs each)

Counted from the bot's own choices (`qa_tower_events_report_test.dart`).

| | no unlocks | all unlocks |
|---|---|---|
| floors that held a parley (of the floors reached) | 3,060 | 3,481 |
| ...fought by choice | 2,089 (60 died there) | 2,588 (66) |
| ...talked, failed (the fight follows) | 139 (9 died after) | 49 (3) |
| ...talked, passed (the floor skipped), inferred | about 832 | about 844 |
| runs that bought in a store | 974 (49%) | 687 (34%) |
| stores that sold something | 1,216 | 794 |
| ...salves / potion bundles bought | 679 / 918 | 581 / 326 |
| marks spent in stores | 4,531 (2.3 a run, 4.7 per spender, most 18) | 2,262 (1.1 a run, 3.3 per spender, most 11) |
| bargains signed (the bot never refuses) | 1,709 (0.85 a run) | 2,014 (1.01 a run) |

Anything odd: **nothing**. All 4,000 runs end (1,715 died and 285 won with no
unlocks; 1,469 and 531 with all), no hero stays in a shop, no climb cannot end.

Limits: the bot talks only when hurt (below 70% health), buys a salve when
hurt and a bundle when short of potions, and always signs a bargain; a player
will do otherwise. The parley passes are not counted but inferred (floors met
less fights and failed talks), because a passed talk leaves no trace on the
final run. The stores' stock on the floors 10 and 20 is always offered, so
the 974 and 687 buyers are those that chose to buy, not those that visited.
