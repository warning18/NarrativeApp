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
