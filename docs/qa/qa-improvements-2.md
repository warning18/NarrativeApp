# QA improvements, second round

2026-11-04. New items only: nothing here repeats [qa-improvements.md](qa-improvements.md) (PR #699) or the open issues. Scope is QA's: tests, `docs/qa/`, CI checks, the simulator's checks, `qa` issues. **Nothing is built from this note until the Manager releases items.**

## The suite now (fresh profile, `flutter test --reporter json`, v1.752 plus #699)

| | |
|---|---|
| test files / test entries | 545 / 4,521 |
| wall time, one process | **1,304 s** (21 min 44 s) |
| time in test bodies | 2,170 s |
| time loading files (about 0.76 s per file) | 419 s |
| CI shards on the last runs (4 runners, setup included) | 311 to 403 s |
| `qa_` files (40) | 323 s of bodies; of which the 12 smoke files 169 s |
| `fight_*` files (31) | 319 s |

Biggest single tests: `boss_balance_test` setUpAll 65 s, `clash_balance_test` 39 s, `sim_coverage_test` 32 s, `qa_smoke_l3_test` 28 s, `fight_backdrop_test` "every anomaly on every stage" 23 s, `fight_echo_silence_test` 22 s, `qa_smoke_screens_test` 20 s. Nothing is skipped; nothing fails.

## Ranked, value over effort

### 1. Cut the real-time sleeps in the files' own `_settle` helpers

- **What.** 38 test files define their own `_settle` that sleeps in real time (`runAsync` + `Future.delayed`) 3 to 8 times per call, 100 to 200 ms each time. Together their bodies are **447 s**. The shared `settleApp` already sleeps 100 ms; `camp_flow_test` and others already use 30 ms after the first call and pass.
- **Why (evidence).** Measured on one file: `fight_lab_test` (10 calls x 6 sleeps x 200 ms) takes **24.0 s alone; with 200 ms changed to 30 ms, 11.7 s**, same two tests passing, same CPU time (12.9 s vs 11.6 s user), so the saving is idle wall time. Files with the 200 ms form and 4 to 11 calls: `fight_echo_silence` (22 s), `fight_lab_companion` (20 s), `fight_lab` (19 s), `qa_smoke_tints` (19 s), `ux_story_room` (18 s), `world_road_play` (15 s), `journey_moves` (15 s), `fight_ground` (15 s), `fight_dice_rules` (14 s), `world_map` and `main_menu` (150 ms, 15 s each).
- **Size.** S per file; M for the 38. Do the 12 slowest first (a one-number change each), then move the rest to a shared `settleApp(tester, {first})`.
- **Risk.** Low to medium: a test that needs the real wait for an async load fails (then keep the long first call, as `camp_flow` does). Each file is run before and after.
- **Saves.** Up to about 150 s summed of idle time. Idle sleeps overlap when four files run at once, so expect about 25 to 40 s off each CI shard, not 150. Touches Core's and UX's tests (speed only; listed in the PR).

### 2. QA's own smoke tests: drop 360 px, keep 412 and 320

- **What.** The smoke cases run every screen at 412, 360 and 320 px in English and French. Keep 412 (the common phone) and 320 (the smallest); drop 360.
- **Why.** 12 smoke files cost 169 s of bodies, 7% of the suite, and are QA's own. Layouts here are width-monotonic: every real finding so far (#688, the 1.654 and 1.473 reviews) failed at 320 and passed at 412; none failed at 360 only. 360 costs a third of the 169 s.
- **Size.** S (one `sizes:` default in `qa_smoke_harness.dart`). **Risk.** Low; keep 360 in the L3 pass (one-off picture run) rather than in CI.
- **Saves.** About 55 s summed, about 14 s per shard.

### 3. Run the four statistical simulator tests only when a PR could move them

- **What.** `boss_balance_test` (66 s), `clash_balance_test` (39 s), `sim_coverage_test` (32 s) and `adapt_gap_test` (26 s) play whole simulated runs on every PR: **163 s, 7% of the suite**. Give the CI a path filter: run them when a PR touches `lib/combat`, `lib/data`, `lib/models`, `lib/screens/fight`, `assets/gamedata`, `assets/Cleaned_Narrative_DAG.json` or `test/sim*`, and always on `main`.
- **Why.** Most PRs (UX, story text, docs, tests) cannot move a balance band; they pay 40 s per shard for nothing.
- **Size.** S to M (a `dorny/paths-filter` step or a `git diff` in `shard_tests.py`; the filter must also run them when `shard_tests.py` or the weights change). **Risk.** Medium: an indirect change (a shared helper) skips them on the PR; `main` still runs them and the manager sees the failure at merge. Mitigation: list the filter in `docs/qa/README.md`.
- **Saves.** About 40 s per shard on a typical PR.

### 4. A nightly job: random seeds and shuffled test order

- **What.** A scheduled workflow (not a required check) that runs the simulator batch with a date-based seed (200 runs) and the whole suite with `--test-randomize-ordering-seed=random`, and opens a `qa` issue when it fails.
- **Why.** Every sim test uses a fixed seed, so a rare dead end or crash the fixed seeds miss stays hidden until a player finds it. And 282 test files set up `SharedPreferences` mocks and many use shared globals; an order dependence is invisible today because the order never changes.
- **Size.** M. **Risk.** Low (informational job; noise is limited by logging the seed). **Saves.** No PR time; buys risk reduction of the "blocks the player" kind.

### 5. A save round-trip check in a simulated run

- **What.** A `test/qa_save_roundtrip_test.dart`: play a seeded run with the simulator's world and, after every scene, save the session, load it into a fresh session and compare the state (level, gold, flags, quests, party, position). Fails with the scene id.
- **Why.** The full review's top finding (#693) is the save/load path, and the existing tests cover chosen fixtures, not the states a real run passes through. 479 scenes and 51 quests make for far more state than the hand-built cases.
- **Size.** M (uses the sim helpers of `test/support/sim_world.dart`). **Risk.** Low; it only fails on a real mismatch (and a mismatch from a field the save deliberately drops needs an allow-list, agreed with Core). **Saves.** Risk: a lost save is the worst bug the app can have. About 10 s of CI time.

### 6. Narrow the fight backdrop's "every anomaly on every stage at every level" test

- **What.** `fight_backdrop_test` has one test of 22.8 s that paints the full matrix of stages, anomalies and levels.
- **Why.** The matrix repeats the same paint path; the corners (first and last stage, each anomaly once, lowest and highest level) hit every branch. UX-2 just changed this file (#691, ticker), so the owner knows what each cell guards.
- **Size.** S. **Risk.** Low to medium (a cell that has its own branch must stay): UX-2 decides. **Saves.** About 15 s summed.

### 7. Remove the dead `skipUntilFixPack` switches

- **What.** `qa_ch7_hub_layout_test.dart:42` and `qa_real_font_cards_test.dart:211` define `const skipUntilFixPack = false`, and the tests still pass `skip: ...` expressions built from it (`size.width < 340 && skipUntilFixPack`).
- **Why.** The fix pack landed long ago; the flag can never be true. It reads like a pending skip to the next person and hides that all cases run.
- **Size.** S (two files, QA's own). **Risk.** None. **Saves.** Clarity only.

### 8. Stop shipping no-op report generators as tests

- **What.** `qa_clan_power_50_test.dart` (375 lines) runs on every PR and does nothing (0.6 s of load; its test does no work without `CLAN_POWER_OUT`). Same shape: report modes of the `sim_*` tests behind `SIM_*` variables. Move the report generators to `tool/` (a `dart run` script or a `flutter test` command listed in `docs/qa/README.md`), keep the guards in the suite.
- **Why.** 11 files in the suite have no `expect()`; 10 of them are fine (harnesses that assert inside `runSmoke` or the chip helper), and this one is a pure generator, and the next reader cannot tell the two apart.
- **Size.** S. **Risk.** Low (the L3 instructions must name the new command). **Saves.** About 1 s and a clearer suite.

## Not proposed (checked, no gain)

- A fifth CI shard: the shards finish in 311 to 403 s with about 60 to 90 s of setup each, and the `apk` job runs for about 4 to 5 minutes beside them; the wall time is already set by the slowest shard and a fifth runner would cost more in setup than it saves.
- Merging the 186 files with under 0.3 s of bodies: already item 7 of the first list.
- Deduplicating test names: no test name appears in three or more files.

## Suggested order

1 (the 12 slowest files first), 2, 7 and 8 together (small, QA's own), then 3 and 5, then 4 and 6.
