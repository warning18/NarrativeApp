# Suite speed, v2.4.0 to v2.7.0: the real pauses of the settle helpers

QA, after the week's ~25 PRs (the suite went from 4,053 tests at 1.888 to
4,494). Profile of the whole suite (per-file seconds from `flutter test
--reporter json`, the four CI shards one after the other on a 4-core box), then
one change, measured twice.

## Where the time goes

Sum of the files' seconds, 3,286 on the baseline: the ten slowest files are
boss_balance 63 (a gated simulator group: CI leaves it out of a pull request
that cannot move it), clash_balance 43, qa_heal_rules_fight 34, sim_coverage 34,
fight_backdrop 31, qa_smoke_l3 27, qa_weakness_all_foes 27, new_game_start 26,
ability_radar_preview 25, app_strings_french_typography 25: **19%** of the
time, so no short list of files holds the suite. What is everywhere is the real
pause the helpers make after pumping a screen: `settleApp` (test/support/
pump.dart, 505 calls in 95 files) waited a real 100 ms three times a call, and
`settle` of skill_fight_harness (32 files) the same, so a test that settles
twenty times slept six seconds doing nothing.

## The change (tests only)

- `settleApp`: the first call of a test keeps its three pauses of 100 ms (the
  game data loads from the bundle in a real future then); the later calls wait
  30 ms a round, which was enough in every test.
- `skill_fight_harness.settle`: the same (its first call keeps 200 ms).
- `qa_weakness_all_foes_test` (mine): a foe with no resistance to learn is met
  once, not twice (the second pass could only repeat the first).

No check is removed or weakened; nothing asserts on a duration.

## Before and after (same commit, e7ea2190, `tool/shard_tests.py` shards)

| | shard 0 / 1 / 2 / 3 (s) | serial sum | files' seconds | tests | failed |
|---|---|---|---|---|---|
| before | 413 / 414 / 455 / 389 | **1,671 s** | 3,286 | 4,494 | 0 |
| after, run 1 | 399 / 427 / 407 / 318 | **1,551 s** (-7%) | 3,050 | 4,494 | 0 |
| after, run 2 | 351 / 380 / 367 / 317 | **1,415 s** (-15%) | 2,788 | 4,494 | 0 |

Run 2 ran on a quieter machine (nothing else of mine going), so the honest
figure is between the two: **7 to 15% of the suite, about 2 to 4 minutes of
serial time**; one shard of CI is about 6 minutes, so a shard saves about 30 to
60 s. The same result for every one of the 4,494 tests in both after-runs
(no test differs between them), and on current main (v2.7.0) the 131 files that
use the helpers pass with the change (323 tests, 330 s).

Biggest gains, file by file (s, before to after): qa_weakness_all_foes 27 to
12, qa_fight_marks_real 22 to 10, qa_heal_rules_fight 34 to 26,
qa_no_conflict_markers 10 to 1 (noise: a read-only file), ability_radar_preview
25 to 17, app_strings_french_typography 25 to 16, qa_journey_map_click_detour 18
to 11, merge_ready_plate 19 to 13, map_ladder 17 to 11.

## What is left, and what I did not do

- The statistical simulators (boss_balance, clash_balance, sim_coverage) are
  about 140 s of file time together; they are Core's and already gated on pull
  requests. Fewer runs would weaken them, so I left them.
- `qa_heal_rules_fight` plays six real fights in one test; its steps need
  separate apps, so I did not merge them.
- A whole-suite single baseline has about 5% noise (shard to shard on the same
  code: 389 to 455 s); do not read the last percent of the table.

## Shard balance (the weights file, refreshed)

CI's wall time is its slowest shard. `tool/shard_tests.py` splits the files by
the seconds of `test/shard_weights.json`, and those weights were old (for
instance `ability_radar_preview_test.dart` weighed 1.3 s and takes 17). With
the per-file times of the two after-runs above, held out one against the other
(weights from run 1, loads read in run 2): the old weights give the shards
691 / 747 / 725 / 626 file-seconds (the slowest 7% over an even split), the
refreshed ones 702 / 703 / 707 / 677 (1.3% over): **the slowest shard is 5%
shorter, about 20 to 30 s of CI's wall time**, with no test touched. The
refresh is `tool/qa_shard_weights.py RUN.json ...` (new, reads the JSON
reporter's output of any runs, averages, keeps the weight of a file no run
has); rerun it after a big change in the suite's time.
