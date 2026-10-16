# Clan power over 50 playthroughs, re-run at v1.464

The same 50 runs as QA's [clan-power-50](../qa/clan-power-50.md) (seeds 7000 to 7049, the same strategy, profession and race rotation), re-run on `main` at v1.464.0. Since v1.464 the simulator plays a quest turn-in's politics. The harness is `test/qa_clan_power_50_test.dart` and the report is `tool/clan_power_report.py`. The raw data is [clan-power-50-v1.464.json](clan-power-50-v1.464.json).

This is not a pure A/B test. Between v1.453 and v1.464 the fights changed too (Option C, v1.458), so a few runs took other paths and other patrons.

## Before and after

| Clan | end, v1.453 | end, v1.464 | quest power a run | at 0 at the end (of 50) | backed: end, v1.453 → v1.464 |
|---|---|---|---|---|---|
| Dominion | 73.1 | 75.5 | +1.4 | 0 → 0 | 92.5 (6) → 94.6 (5) |
| Vigil | 32.5 | 29.4 | 0 | 2 → 7 | 60.5 (10) → 54.6 (16) |
| Compact | 60.0 | 61.2 | +0.1 | 0 → 0 | 79.8 (13) → 84.1 (10) |
| Mire | 6.1 | 7.8 | +0.1 | 41 → 40 | 40.0 (4) → 47.2 (4) |
| Crows | 67.5 | 65.3 | +0.1 | 0 → 0 | 100 (7) → 99.3 (6) |
| Penitents | 13.7 | 13.4 | +0.7 | 14 → 15 | 33.0 (10) → 38.9 (9) |

The patron is at 0 at the end of the run in 9 runs at v1.453 and 10 at v1.464.

## What it says

- **Quest power is now counted, and it is small:** about 1% of all the points moved, against 0% before. The rest of the shares hold: holding 27%, neglect 34%, gifts 26%, claims, wars and falls 12%, story 0%.
- **The quest power goes to the Dominion** (+1.4 a run) and **to the Penitents** (+0.7), as QA predicted from the data. The other clans get almost none: the simulator rarely picks a turn-in choice that raises their standing by 5.
- **The curves keep their shape.** The mean curves are still close to straight lines (R² 0.91 to 0.98, except the Vigil at 0.20 and the Mire at 0.88). Single runs still move in steps: 82% of clan-chapters move by 5 or less, and the biggest drop is −58 when a clan falls.
- **The Vigil falls more often** (7 runs, up from 2). This is probably not the quest change: the Vigil was backed in 16 runs instead of 10, after Option C changed which runs take which patron.

## Still not simulated

The seat crisis, gifts only from the patron, and story power are still missing; see [sim-gaps.md](sim-gaps.md).
