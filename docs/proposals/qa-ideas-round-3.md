# QA ideas, round 3 (tests, simulator, suite speed, guards, docs/qa)

New items only: nothing from `docs/qa/qa-improvements.md`, `qa-improvements-2.md`, or the held nightly 360 px job. Numbers come from `test/shard_weights.json` (file time in seconds, v1.468 to v1.855 profiles, 602 test files) and from the repository as of main v1.863. I did not run a fresh full profile for this note; where a figure needs one, it says so.

Ranked, my recommendation first. Removing and speeding up come first.

## 1. Delete the one-off picture folders after each hand test (remove)

- **What**: `docs/qa/hand-test-1.846/` (15 MB), `docs/qa/village-hubs-1.851/` (0.9 MB), `docs/qa/smoke/` (2.1 MB) and the old `l3-*/` picture folders are single-use evidence. Once the user has tested the release they belong to, the next hand-test PR deletes the previous folder (git history keeps it). `docs/` is 79 MB, `docs/qa` 20 MB, `.git` 374 MB.
- **Why**: every clone, every CI checkout and every cloud session pays for them; nobody opens them after the test.
- **Size**: small (a `git rm` and a line in `docs/qa/README.md`).
- **Risk**: none for the build; a README link to a deleted picture (the README of the next folder replaces it).
- **User notices**: nothing; a smaller checkout.

## 2. Make the shard weights complete and keep them complete (speed)

- **What**: 67 of the 602 test files have no entry in `test/shard_weights.json` (all `tower_*`, `qa_mending_light_*`, `journey_*`, `fight_qa694_*`, `ux_*_shot*` among them). `tool/shard_tests.py` gives them the median weight (2.2 s). Any of them that is really a 10 to 30 s widget test makes one runner the slow one. Refresh the weights from one CI run (the four shard JSON reports, `tool/shard_weights_from_report.py`), and add to `shard_tests.py --check` a failure when a file has no weight (the author adds a line when adding a test).
- **Why**: the pull request's wall time is its slowest runner; the weights are the only lever the partition has, and 11% of the files are blind.
- **Size**: small. A fresh profile is needed first (about 14 min of one runner's time, or the artefacts of the last green main run).
- **Risk**: low; a new test file would need a weight line to pass `--check`.
- **User notices**: nothing, or a faster CI by a few tens of seconds when the slowest shard was the unlucky one.

## 3. A time budget for a new test file (guard on speed)

- **What**: the heaviest files are the gated simulator tests (`boss_balance` 75 s, `clash_balance` 43 s, `sim_coverage` 36 s) and then `qa_smoke_l3` 32 s, `qa_smoke_screens` 32 s, `fight_backdrop` 31 s, `new_game_start` 26 s, `clash_test` 25 s, `qa_real_font_cards` 25 s, `fight_echo_silence` 24 s. Add to `--check` a rule: a file whose weight is above 30 s must be in `tool/sim_gate.txt` or in a short allow-list in the same file with a reason. A new slow test then fails the check and is gated or split before it lands.
- **Why**: speed is only ever lost one file at a time; today nothing notices.
- **Size**: small (one function in `shard_tests.py`, a list).
- **Risk**: an allow-list that grows; reviewed with the weights refresh.
- **User notices**: nothing.

## 4. Gate the two big smoke files and the real-font cards on the paths that can break them (speed)

- **What**: `qa_smoke_l3_test` (32 s), `qa_smoke_screens_test` (32 s) and `qa_real_font_cards_test` (25 s) check how screens look. Put them in `tool/sim_gate.txt` as gated tests with the triggers `lib/screens/`, `lib/widgets/`, `lib/theme/`, `lib/l10n/`, `pubspec.yaml` and `assets/fonts/`; a pull request that only touches `lib/data/`, `lib/combat/`, `assets/gamedata/`, `lib/data/tower/` or tests skips them; main always runs all. (The gate is the one that already skips the four simulator tests.)
- **Why**: about 89 s of file time of 2,570 s (3.5%), 20 s or so on the slowest runner, for the pull requests that cannot move a layout. Core's Tower and data pull requests are most of those today.
- **Size**: small.
- **Risk**: a data change that breaks a screen (a longer French name in `assets/gamedata/`) is not caught until main. Mitigation: keep `assets/gamedata/` as a trigger for the real-font cards (the name-length case) and gate only the L3 and screens smoke files.
- **User notices**: nothing, or a faster CI.

## 5. Lazy batches in `qa_tower_sim_test.dart` (speed)

- **What**: `main()` plays both 500-seed batches (1,000 Tower runs; the whole file weighs 16 s) before any test, so a `--plain-name batch` run for the report pays for them too, as does any run of one test of that file. Move the two batches into a lazy `late final` read by the guards only.
- **Why**: a report rerun (two ranges of 2,000 seeds) spends part of those 16 s on guards it does not use; in CI it is a wash (all tests run). A small gain for whoever reruns the report; I have not timed the split.
- **Size**: tiny (3 lines).
- **Risk**: none; the guards are unchanged.
- **User notices**: nothing.

## 6. Replace the hand-test harness's duplicated `settle`/`pumpUntil` with `skill_fight_harness.dart` (remove)

- **What**: 6 of QA's own `qa_*_test.dart` files declare their own copy of `_settle`, `_pumpUntil` or `_tapWhenEnabled` (by `grep`); `test/skill_fight_harness.dart` already exports them. `qa-improvements.md` item 3 covers the other sessions' files; this item is the 6 QA-owned ones only.
- **Why**: fewer copies; a fix to a wait lands once.
- **Size**: small, mechanical (one PR, tests only).
- **Risk**: low; each file's tests must still pass; verify with the same files.
- **User notices**: nothing.

## 7. A sample of real-fight floors against the Tower's bot (new guard, simulator)

- **What**: the balance batch plays the bot on the headless fight, which has no affixes, no clan-die resonance and no specialisations (`lib/data/tower/tower_bot.dart`), so the real floors are harder than the report says (it says so, but only in a note). Add a small guard: play the bot's decisions on 10 seeded Tower floors through the real `FightScreen` (the detached session as in `qa_cleric_watchfire_tower_test.dart`) and assert the win and loss agree with `simulateSimFight` on at least 7 of 10, to put a bound on the gap.
- **Why**: the balance numbers (floor 20 boss at 73%) are only as good as that agreement; today nothing measures it.
- **Size**: medium (a widget-driven bot of the die picks, 20 to 40 s of CI time, so it would be gated as in item 4).
- **Risk**: medium; fights with randomness need the seeded provider (`fightRandomProvider`); the first run may show a larger gap, which is the point and is a finding for Core, not a failure to hide.
- **User notices**: nothing directly; later, a Tower balance that matches what the player sees.

## Summary for the manager

1. Delete finished hand-test picture folders (15 MB now): small, no risk.
2. Complete the shard weights (67 of 602 files unweighted) and fail `--check` on a missing one.
3. A 30 s budget in `--check`: a slow new file must be gated or allow-listed.
4. Gate the L3/screens smoke files and real-font cards on screen paths (about 89 s of file time on data-only PRs).
5. Smaller: lazy Tower batch in the guard file; share the wait helpers in QA's own files; and a medium item, a real-fight sample against the bot to bound the headless gap.
