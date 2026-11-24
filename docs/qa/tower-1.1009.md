# The Tower on v1.1009: a fresh batch against v1.963

QA, on main v1.1009 (the Tower in ink, parts 1 to 3, v1.1004 to v1.1009, are
view-only; the clan gift dice, v1.993, and the weakness rules, v1.994, came
since v1.963). The same 2,000-seed bot batch as [tower-1.963](tower-1.963.md)
(seeds 1 to 2000, 10001 to 12000 as the check; no unlocks and all unlocks), run
with the same commands:

```
TOWER_SEEDS=2000 TOWER_FIRST=1 TOWER_OUT=<file> flutter test test/qa_tower_sim_test.dart --plain-name batch
TOWER_EVENTS_OUT=<file> flutter test test/qa_tower_events_report_test.dart
python3 tool/qa_tower_report.py seeds-1.json seeds-10001.json
```

Full report: `tower-1.1009/tower-batch.md`; events: `tower-1.1009/event-tally.json`.
The live-Tower pin (`qa_tower_live_pin_test`) and `qa_tower_sim_test` pass (7
tests): Core's seeded figures are unchanged.

## Against v1.963

| figure | v1.963 | v1.1009 |
|---|---|---|
| win floor 30, no unlocks | 14.2% (check seeds 14.1) | **14.3%** (check 14.5) |
| win floor 30, all unlocks | 26.6% (26.6) | **26.9%** (26.6) |
| reach floor 20 (none / all) | 47.7 / 63.1% | 48.1 / 63.4% |
| reach floor 10 (none / all) | 89.2 / 96.2% | 89.2 / 96.4% |
| median floor (none / all) | 19 / 22 | 19 / 22 |
| mean floor (none / all) | 19.2 / 22.1 | 19.3 / 22.1 |
| marks a run, mean (none / all) | 28.3 / 36.0 | 28.4 / 36.1 |
| floor 10 boss, lost (none) | 6.1% | 5.8% |
| floor 20 boss, lost (none / all) | 13.8 / 14.6% | 14.0 / 14.8% |
| floor 25 warden, lost (none / all) | 13.8 / 8.0% | 13.6 / 8.6% |
| floor 30 boss, lost (none / all) | 27.5 / 19.4% | 27.5 / 19.7% |
| worst ordinary floor, lost (none) | floor 17, 8.8% | floor 17, 8.8% |

Nothing moved by more than 0.6 of a point, and every figure is inside the
noise of a 2,000-seed batch except the small rise at the top with all unlocks
(+0.3 on seeds 1 to 2000, none on the check seeds). The probable cause is the
three clan gift dice of v1.993 (the bot takes the clan's die); I did not
isolate it. The top rate is still above the design's bands (5 to 12% none,
15 to 25% all), as the 1.906 and 1.963 reports said; that is Core's call and
the user's.

## What the events do (the bot, 2,000 runs each)

| | no unlocks (v1.963 → now) | all unlocks (v1.963 → now) |
|---|---|---|
| floors that held a parley | 3,060 → 3,066 | 3,481 → 3,486 |
| ...fought by choice (died there) | 2,089 (60) → 2,028 (60) | 2,588 (66) → 2,523 (63) |
| ...talked and failed (died after) | 139 (9) → 132 (9) | 49 (3) → 47 (2) |
| runs that bought in a store | 974 → 977 | 687 → 694 |
| salves / potion bundles bought | 679 / 918 → 685 / 920 | 581 / 326 → 587 / 330 |
| bargains signed | 1,709 → 1,718 | 2,014 → 2,019 |

All 4,000 runs end; no hero stays in a shop, no climb cannot end. Nothing odd.

The ink Tower's screens are read in `l3-1.996.md` and guarded by
`qa_tower_ink_screens_test` and `qa_tower_ink_360_test`.
