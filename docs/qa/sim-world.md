# The simulator tests' shared world (QA, v1.606, 2026-10-29)

`test/support/sim_world.dart` is the one place the 24 simulator tests get their tables from: `simTables()` loads every table the playthrough simulator reads (`playthrough_simulator_screen.dart`, `_simContextOf`), companions included, so since v1.601 every hero walks with Vica. `qa_sim_tables_test.dart` holds it: a simulator test calls `simTables()`, or names the tables it needs, or marks what it leaves out (`// sim-tables-ok: <table>: <why>`); and the shared list must equal the tables the simulator screen reads. The guard now scans `simulateFightsByChapter(` as well as `simulatePlaythroughs(`, and requires `companions`.

## What moved

All 24 simulator tests play in the full world, apart from `sign_fight_hooks_test`, which keeps its own marked list (it is about a world with no clan tables). The shared list has no way to leave a table out any more.

*History:* when this helper first landed (#591) `boss_balance_test` and the two frozen-run tests kept the old world through a `simTables(without: ...)` argument, because with the specialisations in the world the same 400 runs won the bosses 15 to 20 points more often. Core's decision was to keep the targets and re-size the bosses (v1.613 and v1.614, `docs/proposals/bosses-full-world.md`) and to replace the frozen runs with property checks (#603, v1.617); the exclusions went with them and the argument is gone.

## S5: one big run

`boss_balance_test` now runs its 400 runs with `championFights: true` and measures the nemeses' champions on the same walk (47.0% of 1,079 met, band 50 ± 12). The 200-run champions' test in `nemesis_quests_test` is removed. The profession spread skips the champions' fights (the spread keeps its old measure; with them it read 11, without 6.9: cleric 68.8, mage 75.7). The boss rates passed unchanged with the champions in the walk.

## Suite time

The 25 simulator files, run alone on the same machine (`flutter test --reporter json`, summed per file / wall):

| | before | after |
|---|---|---|
| summed | 273.5 s | 246.5 s |
| wall (parallel) | 142.9 s | 125.2 s |
| `nemesis_quests_test` | 37.8 s | 0.7 s |
| `boss_balance_test` | 82.4 s | 73.8 s |
| `clash_balance_test` | 33.3 s | 46.4 s |
| `sim_coverage_test` | 28.0 s | 36.3 s |

The full world costs the walk more (specialisations, ports and detour scenes are more to roll): `clash_balance_test` (+13 s) and `sim_coverage_test` (+8 s) paid for what `nemesis_quests_test` saved. Both are the next speed candidates (`clash_balance_test`: three seeds of 40 runs, twice).

## Reference numbers since v1.766 (the simulator reaches the shops)

Core's #742 made the simulated walk visit the ports', the houses' and the caravan's shops ([sim-reach-v1.766.md](../simulation/sim-reach-v1.766.md)) and re-tuned `void_stalker` (health 44 to 54, damage 4 to 5). The numbers QA compares against move; the older L3 tables ([1.696.0](l3-1.696.0.md) and before) stay as they were measured, on the simulator of their day, and are **not** comparable with these:

| 800 naive runs, seeds 11 and 23, four goals (QA's method) | v1.762 | **v1.766** |
|---|---|---|
| encounters won | 71.0% | **75.3%** |
| ordinary (non-boss) fights won | 74.4% | **79.3%** |
| won at the first attempt | 40.0% | **44.4%** |
| level and gold at the end | 21.6, 4,976 | **22.1, 4,110** |
| runs that reach an ending | 800 of 800 | 800 of 800 |
| profession spread (encounter win, mage to warrior) | 6.1 points | **8.2 points** (mage 80.2, warrior 74.9) |
| `void_stalker` in the boss test (target 65) | 60.3% | **62.5%** (88.3% before the re-tuning) |

What reads differently: chapter 3 is 83% won (was 71), chapters 6 to 8 lose 1 to 4 points (the shopping leaves less gold). Every boss stays inside its band. `l3_sim_metrics.py` keeps the same boss targets (no target moved), so the next L3 compares with this table. The guards that quote bands (`boss_balance`, the class spread, `sim_competent`, `sim_playthroughs`, `sim_coverage`, `clash_balance`, `qa_sim_tables`) pass on main at v1.766 (CI of #742); no `qa_` guard quotes the old figures, so none changes.
