# Suite time on v1.499.0

Run alone on the machine (four cores), `flutter test --reporter json`, head `248381ec` (v1.499.0, 2026-10-21), compared with the same measure on v1.489.0 (this morning's L3, [l3-1.489.0.md](l3-1.489.0.md)) and v1.473.0.

| | 1.473.0 | 1.489.0 | **1.499.0** |
|---|---|---|---|
| tests (without "loading" and hidden entries) | 2,941 | 3,056 | **3,086** |
| failed | 0 | 0 | **0** |
| wall time | 942 s | 851 s | **839 s** |
| test seconds, summed over all files | n/a | 1,680 | **1,660** |
| files | 418 | 418 | 425 |

30 more tests, 7 more files, and 12 s less wall time (20 s less summed test time). Per file, between 1.489 and 1.499 (summed seconds; the same files measured in both runs):

- **Cut: 121 s**, all from QA's two speed PRs (#438, #440) and the smoke files' own waits: the offer smoke 15 s, the anomaly chips (fr, en) 15 and 13, `story_layout` 11, the character smoke 11, `camp_flow` 10, the story-text real-font test 6, `qa_full_map` 5, the story, walk and world smoke 5, 5 and 3.
- **Added: 101 s**, almost all new guards and smoke tests: the profession-spread guard 35 s, the town-tints smoke 16, the companions' words 12, the temple sheet 7, the camp smoke 4 (the roll-house cards), and Core's and UX's new tests (`temple_test`, `town_tints_test`, `moment_remarks_test`) a few seconds each.

## Where the time is now (summed seconds by file, top)

| s | tests | file |
|---|---|---|
| 35.0 | 2 | `qa_sim_spread_test` (the 400-run simulation of the profession guard) |
| 33.0 | 21 | `boss_balance_test` (the same 400 runs, by design) |
| 21.3 | 27 | `qa_real_font_cards_test` |
| 19.7 | 2 | `fight_lab_companion_test` |
| 19.7 | 5 | `nemesis_quests_test` |
| 18.6 | 3 | `fight_lab_test` |
| 18.4 | 25 | `qa_full_map_test` (was 23.6) |
| 18.0 | 2 | `story_layout_test` (was 29.3) |
| 17.8 | 2 | `clash_balance_test` |
| 17.5 | 4 | `ux_story_room_test` |

The two 400-run simulations at the top run the same plan (seed 7): `qa_sim_spread_test` computes the encounter win of each profession and `boss_balance_test` the bosses'. They sit in different files, so they cannot share the run (each test file is its own process). Putting the spread check in `boss_balance_test`'s `setUpAll` would save about 33 s of summed time (about 8 s of wall time on four runners); it is Core's file, so the change is proposed here and not made.

`test/shard_weights.json` is refreshed from this run; the four shards balance at 415 s each.
