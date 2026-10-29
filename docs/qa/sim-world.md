# The simulator tests' shared world (QA, v1.606, 2026-10-29)

`test/support/sim_world.dart` is the one place the 24 simulator tests get their tables from: `simTables()` loads every table the playthrough simulator reads (`playthrough_simulator_screen.dart`, `_simContextOf`), companions included, so since v1.601 every hero walks with Vica. `qa_sim_tables_test.dart` holds it: a simulator test calls `simTables()`, or names the tables it needs, or marks what it leaves out (`// sim-tables-ok: <table>: <why>`); and the shared list must equal the tables the simulator screen reads. The guard now scans `simulateFightsByChapter(` as well as `simulatePlaythroughs(`, and requires `companions`.

## What moved

| Test | World | Why |
|---|---|---|
| 20 tests | the full world | their bands held; the extra tables (companions, specialisations, spec variants, skill merges, detour scenes, ports) changed no pass or fail |
| `boss_balance_test` | the full world **without `specialisations` and `spec_variants`** | see below |
| `sim_companions_test`, `sim_competent_test` | the full world without the five tables the screen loads and they did not | the frozen naive run (tuple and hash) is pinned on the old world; Core replaces the pin with property checks (S1) and the exclusion goes with it |
| `sign_fight_hooks_test` | its own minimal list, marked | the test is about a world with no clan tables |

## The finding

**With the hero's specialisation in the world, the boss curve is 15 to 20 points too easy.** Same 400 runs, same seed, bosses won (target): chapter 4 inquisitor 68 (55), bone warden 72 (55), void archon 71 (50), white admiral 66 (45), chapter 8 tear herald 55 (35), void sovereign 67 (35); the claimants together 58 (40); the mean 65 (target about 50). The professions' spread stays at 8.3. Only `specialisations` and `spec_variants` do this; the other three tables (skill merges, detour scenes, ports) change nothing. The simulator screen loads both, so its L3 numbers include them; the CI bands were measured without. `boss_balance_test` keeps its measure and says why at the call. **Core decides** whether the bosses or the targets move; until then the CI curve and the simulator screen disagree by that much.

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
