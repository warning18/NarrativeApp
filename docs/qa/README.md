# QA log

**Last L3: 1.696.0** (2026-11-03, head `0d5f71e5`; [report](l3-1.696.0.md)). Before it: [1.654.0](l3-1.654.0.md) (no simulator batch) and [1.501.0](l3-1.501.0.md) (the last simulator comparison before this one). Next L3 on request, before a release the user shares, or after a big refactor. See "QA levels" in `CLAUDE.md` for what each level covers.

Suite time at v1.499.0 (839 s, 3,086 tests) and where it goes: [suite-time-1.499.0.md](suite-time-1.499.0.md).

The baselines taken ahead of the L3s: [1.270.0](l3-prep-1.270.0.md), [1.285.0](l3-prep-1.285.0.md), [1.473.0](l3-prep-1.473.0.md).

Full-regression (L3) passes, newest first. The detail of each is in its own
file in this folder.

| Version | Date | Result | Suite time | Report |
|---|---|---|---|---|
| 1.696.0 (`0d5f71e5`) | 2026-11-03 | Pass, one finding for UX (#688: the fight's dice board is a 20 px strip at 320 x 568) and three observations for Core and the user. `dart format` clean, `flutter analyze` no issues, full suite 3,852 tests, 0 failed, 0 skipped. Simulator (800 runs, same method as 1.501): bosses on the curve (mean 48.7%, every boss within 6 points), but the ordinary fights are easier (encounter win 75.5% against 66.8%) and the mage leads (spread 7.9 against 1.9). Cross-reference audit of all gamedata: 0 problems. 21 screens and widgets read at 412, 360 and 320 px in English and French. Guards added for the user's feedback of v1.665 to v1.696. | 1,426 s (23 min 46 s) (one process) | [l3-1.696.0.md](l3-1.696.0.md) |
| 1.654.0 (`1a59f62e`) | 2026-10-30 | Pass, two small findings (#650, #651). `dart format` clean, `flutter analyze` no issues, full suite 3,793 tests passed, 0 skipped. Cross-reference audit of all gamedata (45 tables, 2,857 references, the story graph's 1,156 choices): 0 problems. 13 new screens and widgets read at 412, 360 and 320 px in English and French: no overflow. No simulator batch (the user's standing instruction); the band tests in the suite pass and Core's #645 moved no band. | 21m39s (one process) | [l3-1.654.0.md](l3-1.654.0.md) |
| 1.473.0 (`c19b9d0`, #407) | 2026-10-17 | Pass, partial screen read. `dart format` clean, `flutter analyze` no issues, full suite 2,941 tests passed (942 s). Simulator: encounter win 69.2% on 800 runs (the difficulty review's 70% aim; attempt win 36.1% against 45.0% at 1.285.0 by design), class gap closed, bosses won 59% on average (above the curve). 0 scenes unreachable; exploring runs reach 96.8% of 440. Six new gamedata tables audited: 0 problems. One finding for UX (the story text's room on a small phone). v1.474 to v1.477 landed during it. | 15m42s | [l3-1.473.0.md](l3-1.473.0.md) |
| 1.285.0 (`5a416c6`, #215) | 2026-10-14 | Pass. `dart format` clean, `flutter analyze` no issues, full suite 2351 passed, 0 skipped. Simulator compared with 1.274.0: no regression (800-run check 45.0% against 39.8%, the rise being the boss curve). 0 scenes statically unreachable; exploring runs reach 97% of 426 scenes. 40 guards added (full map, harbour and crossing). No finding on `main`. | 16m32s | [l3-1.285.0.md](l3-1.285.0.md) |
| 1.274.0 (`b0218e6`, #202) | 2026-10-13 | Pass. `dart format` clean, `flutter analyze` no issues (14 s), full suite 2216 passed, 10 skipped (the layout guards waiting for #203). 100-run and 800-run simulator batches compared with the 1.270.0 baseline and 1.264.0: no regression (800-run check 39.8% against 40.0% at 1.270.0; 36.7% at 1.264.0, the rise being chapter 5, #196). 0 scenes statically unreachable; exploring runs reach 96% of 426 scenes. No finding on `main`; four on PRs under review. | 14m50s | [l3-1.274.0.md](l3-1.274.0.md) |
| 1.264.0 (`ef2e38b`, #186) | 2026-10-12 | Pass. `dart format` clean, `flutter analyze` no issues (15 s), full suite 2141 tests all passed. 100-run simulator batch compared with 1.256.0: no regression (800-run check 36.7% attempt win against 37%). 0 scenes statically unreachable; exploring runs reach 97% of 415 scenes. Cross-reference audit clean. One issue filed (#182) and fixed (#184) during the cycle. | 14m32s | [l3-1.264.0.md](l3-1.264.0.md) |
| 1.254.0 (`76c8773`) | 2026-10-12 | Pass (first baseline). `dart format` clean, `flutter analyze` no issues (31 s), full suite 2113 tests all passed. Cross-reference audit found no dangling skill, tree, merge, enemy-move, loot or effect references, and every skill has French text. No issues filed. | 14m44s | this file |

Notes from the 1.254.0 baseline:

- The reports in `docs/simulation/` then dated from 1.228.0 (regenerated on
  1.256.0 in #176).
- The guards added with it: `test/qa_strings_test.dart` (string table and
  `tr()` keys), `test/qa_data_refs_test.dart` (gamedata cross-references),
  and `test/qa_story_fr_test.dart` (French typography of the story graph's
  bare `fr` keys, which `french_data_lint_test` does not read).

## CI shards

CI splits the suite across four runners by file time, not by name:
`tool/shard_tests.py` assigns the files (heaviest first, to the lightest
shard) from `test/shard_weights.json`, and fails if a file is dropped or
doubled. A new file needs no entry (it counts as the median file). Refresh the
weights now and then, with `flutter test --reporter json > report.json` and
`tool/shard_weights_from_report.py report.json`.

**The simulator tests and pull requests.** Four files play whole simulated
runs (`boss_balance`, `clash_balance`, `sim_coverage`, `adapt_gap`: about 160 s).
A pull request that changes none of the paths in `tool/sim_gate.txt` (the
combat, data, gamedata, models and providers code, the simulator screen, the
gamedata and story assets, the simulator tests and their helpers, the CI files)
cannot move what they measure, so CI leaves them out and splits the other files
again; main, and any pull request that touches a listed path, run the whole
suite. `test/qa_sim_gate_test.dart` holds the list: every `lib/` file the four
tests read must be under a trigger. To run them anyway, `flutter test
test/boss_balance_test.dart test/clash_balance_test.dart
test/sim_coverage_test.dart test/adapt_gap_test.dart`.

## Picture folders

The pictures of a finished test are deleted (git history keeps them): `hand-test-1.846/` (15 MB), `smoke/` (2.1 MB) and the picture folders of the L3 reports 1.473.0, 1.489.0, 1.501.0 and 1.654.0 (the reports' picture links no longer resolve; `git log -- docs/qa/<folder>` finds them). Kept: `hand-test-1.863/` (until the user has finished testing it), `l3-1.696.0/` (the last L3) and `village-hubs-1.851/` (cited by `docs/proposals/town-chart-framing-and-labels.md`). The next hand-test PR deletes the previous folder.
