# The Tower on v1.944: the floor events live, against v1.932

QA, on main v1.944 (the three floor events switched on: setback, rival,
shortcut, at the events-on foe scale 1.14). The same 2,000-seed batch of the
bot (seeds 1 to 2000, 10001 to 12000 as the check; no unlocks and all
unlocks) as `story-1.932.md` / `tower-1.922.md`, plus a control: the same
batch on v1.944 with the events off (`TOWER_EVENTS=0`), which separates the
effect of the events from the foe scale. Reports: `tower-1.944/tower-batch.md`,
`tower-1.944/event-tally.json`.

## The curve, v1.932 against v1.944

| figure | v1.932 | v1.944 events off (control) | v1.944 (events live) |
|---|---|---|---|
| win floor 30, no unlocks | 12.6% | 12.9% | **13.5%** |
| win floor 30, all unlocks | 26.8% | 27.4% | **25.3%** |
| reach floor 20, no unlocks | 47.2% | 47.2% | **47.0%** |
| reach floor 20, all unlocks | 64.5% | 64.5% | **64.5%** |
| median floor (none / all) | 19 / 23 | 19 / 23 | **19 / 22** |
| mean floor (none / all) | 18.9 / 22.3 | 19.0 / 22.3 | **18.9 / 22.2** |
| floor 10 boss, lost | 5.9% | 5.9% | **5.7%** |
| floor 20 boss, lost | 13.6% | 13.6% | **13.5%** |
| floor 30 boss, lost | 25.4% | 26.1% | **24.6%** |
| warden 5 / 15 / 25, lost | 0.9 / 7.5 / 15.0% | 0.9 / 7.5 / 15.0% | **1.2 / 7.5 / 13.7%** |
| worst ordinary floor, lost | 10.6% (floor 28) | 9.3% (floor 28) | **10.7% (floor 21)**, then 22 (10.4%) |

Seeds 10001 to 12000 agree (events live: median 19, floor 20 reached by
46.0%, top 13.8% none / 26.3% all).

What it says:

- **The events barely move the curve.** Top with no unlocks 12.9% (off) to
  13.5% (on); with all unlocks 27.4% to 25.3% (two points down, the shortcut's
  Elite and the setback's fall costing the strong runs more than the skip
  gives them). Reach floor 20, the median and the mean floor are unchanged
  within a tenth of a point. All of it sits at the centre of what Core
  planned (13.5% / 25.3% are Core's own figures).
- **Floors 27 and 28 are eased as agreed** (control: floor 28 9.3%, from
  10.6%), but with the events on the hardest ordinary floors move to 21 and 22
  (10.7% and 10.4%); the batch does not say why (a shortcut's landing or the
events-on foe scale are the candidates, Core's to tell).
  "No ordinary floor over 10%" is missed by 0.7 point on floor 21, hit by
  none of the floors above 22.
- **The bosses did not move** (5.7 / 13.5 / 24.6% lost against 5.9 / 13.6 /
  25.4%); the floor 30 boss is a point easier for the all-unlocks run.

## By race (win floor 30, no unlocks)

| race | v1.932 | v1.944 |
|---|---|---|
| elf | 16.5% | 18.8% |
| human | 13.7% | 15.9% |
| voidkin | 11.6% | 13.7% |
| dwarf | 11.7% | 10.1% |
| orc | 9.7% | 9.2% |

The spread (9.2% to 18.8%) is a little wider than at v1.932 (9.7% to 16.5%):
the events help the three races that were already ahead more than dwarf and
orc. Orc is now the lowest.

## How often each event fires (the bot, 2,000 runs each, v1.944)

Counted from the bot's own card choice (`qa_tower_events_report_test.dart`):
after each floor won, how that floor's event ended and what was chosen on its
shortcut; a shortcut taken and lost ends the run on that floor.

| | no unlocks | all unlocks |
|---|---|---|
| runs with a setback (at most 1 a run) | 1,083 (54%) | 1,187 (59%) |
| rival floors met | 1,490 | 1,749 |
| ...beaten in time (skip) | 873 (59%) | 951 (54%) |
| shortcuts offered | 2,223 | 2,578 |
| ...taken | 1,404 (63%) | 1,762 (68%) |
| ...taken and won | 1,282 (91% of taken) | 1,575 (89%) |
| ...taken and lost (the run ends there) | 122 (8.7% of taken) | 187 (10.6%) |
| ...declined | 819 | 816 |

So on a run a player meets, on average, about 1.1 shortcuts and 0.75 rivals,
and every second run takes its one setback. About one run in 16 (no unlocks)
dies on a shortcut it took.

Limits of the count: the setback is counted from `TowerRun.setbacks`
(failed tests only: a passed test leaves no trace on the final run), so
the number of setback CHECKS met is higher; a shortcut offered while the
bot is hurt is declined (the bot takes it with health to spare), a player may
choose otherwise.

## Pin

`qa_tower_events_off_pin_test.dart` reads `towerEventsLive`; Core re-pinned it
on the live curve (58 / 231 / 9,358 no unlocks; 129 / 334 / 11,203 all
unlocks) and I verified the numbers on the branch.
