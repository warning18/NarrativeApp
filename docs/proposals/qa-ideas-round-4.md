# QA ideas, round 4 (tests, simulator, suite speed, guards, docs/qa)

New items only. Not repeated: anything in `docs/qa/qa-improvements.md`, `qa-improvements-2.md`, `docs/proposals/qa-ideas-round-3.md`, the held 360 px nightly job, and the done ones (picture clean-up, smoke gate, 10-floor sample). The shard weights come back **only with new evidence** (idea 1).

**Evidence.** A fresh full profile on main v1.874 (`flutter test --reporter json`, one machine, one process): **4,035 tests in 611 files, 0 failed, 3 skipped, 1,395 s wall**; 2,224 s in tests and **462 s loading the 611 files** (0.76 s each). CI step times of run 42686752831 (#876): "Run tests" 331 / 290 / 310 / 322 s on the four shards, "Set up Flutter" 15 to 30 s, "Analyze" 19 s, "Build APK" 189 s. Raw: `file_times` of that profile are summarised below; nothing here was timed on the user's phone.

Ranked, my recommendation first.

## 1. Refresh the shard weights from this profile (speed; re-proposed with new evidence)

- **What**: replace `test/shard_weights.json` with the per-file times of today's profile (test time plus 0.76 s load), and keep `tool/shard_weights_from_report.py` as the way. 76 of the 611 files have no weight today (they count as the median, 2.2 s); the weights date from v1.468 to v1.855.
- **Evidence**: re-splitting the 611 files with the old and the new weights and scoring both with today's times: **old weights give shards of 680 / 644 / 691 / 673 s (spread 47 s, slowest 691); new weights 672 / 672 / 671 / 672 (spread 1 s, slowest 672)**. CI shows the same imbalance: the four "Run tests" steps differ by 41 s (13%). The slowest shard sets the PR's wall time: **about 19 s a run off the critical path** (the model; CI noise is +/-60 s, so it will not be measurable run to run, as the gate was not).
- **Size**: small (one JSON file, one script run). **Risk**: none to the build; a new file counts as the median until the next refresh. **User notices**: nothing (a few seconds).

## 2. Six CI shards instead of four (speed; a `.github/` change, the Manager's)

- **What**: `matrix.shard: [0..5]` and `shard_tests.py N 6` in `build_apk.yml` (the script already takes any N; `--check 6` to test).
- **Evidence**: each job is about 28 s of setup plus the shard's tests (290 to 331 s at four shards, about 4,000 s of test work split four ways). At six the tests take about 210 s: **a PR's wall time falls from about 6 min to about 4 min 30 (roughly 100 s)**, for two more runners (+8 runner-minutes a PR, +50% on the test job; the APK job runs beside them and takes 4 min 37 s, so the tests would stop being the longest job).
- **Size**: tiny. **Risk**: more concurrent runners on one PR (a queue when several PRs run at once); runner minutes. **User notices**: PRs go green about a minute and a half sooner.

## 3. Cut QA's own slowest test back (speed; mine)

- **What**: `qa_heal_rules_fight_test.dart` (the heal guards, #872) is now **the second slowest file of the suite, 35.4 s**, six fights in one test. The cleric fatigue fight and the plain-ground fight can share three rounds, and the potion fatigue fight the Anvil-Deaf's: four fights, each guard kept (the four mutation checks are rerun).
- **Evidence**: the profile: 35.4 s, after `clash_balance` (gated), above `sim_coverage` (gated) and the smoke files. QA's own 58 `qa_*` files cost 415 s of the 2,224 s (19%).
- **Size**: small. **Risk**: low if the mutations still fail it. **User notices**: nothing; about 12 s of file time (a shard has room).

## 4. Delete the pictures nothing names (remove; owners decide)

- **What**: 73 of 270 pictures under `docs/ux-shots`, `docs/feedback`, `docs/maps` and `docs/proposals` (**17.6 MB of 54 MB**) have a file name that appears in no `.md`, `.dart`, `.py`, `.json`, `.yml`, `.txt` or `.csv` of the repository (`docs/qa/unreferenced-pictures-1.874.txt`: size and path of each). Most are in `docs/feedback` (10), `ux-shots/journey-moves` (10), `ux-shots/skill-glyphs` (9), `proposals/images` (8), `maps/fmg-chart` (6).
- **Why**: `docs/` is 62 MB of the repository's 80 MB of text and pictures (and `.git` 374 MB); every clone and every cloud session pays for them.
- **Size**: small per owner (UX for `ux-shots`, the Manager for `feedback` and `proposals`, Core for `maps`). **Risk**: a README that names a range or a folder instead of a file (`-01s to -11s`) hides a reference from my search, so each owner checks their list before deleting; history keeps everything.
- **User notices**: nothing; a smaller checkout.

## 5. Fewer, fuller small test files (speed; medium, cross-session)

- **What**: 275 of the 611 files take under 1 s of test time (60 s together) but each loads for 0.76 s (about 209 s). Merging the pure-Dart data and model tests of one folder into a handful of files (a `test/data/` file per area) would save most of that load.
- **Evidence**: the profile: loading is **462 s of the 2,686 s of work (17%)**; the 62 files over 10 s hold 980 s of tests. Merging 275 tiny files into about 40 would save roughly **150 to 190 s of work (6 to 7%)**, about 20 s a shard.
- **Size**: medium (many files, every session's). **Risk**: the highest here: merge conflicts with open PRs, and a test that leans on a sibling's state inside one file (the suite keeps one fight per file for this reason); only data and model tests, a few at a time, after the weights are refreshed.
- **User notices**: nothing. I recommend it last, or not at all: the saving is small beside its churn.

## Held for a request, not an idea

Core's hero copy for the Tower (1.880 provisional): a guard that every `SimCharacter` field is copied (one reflective test: a field added to the class and left out of the copy fails it). I will write it when the PR opens, as the Manager asked.

## Summary for the manager

1. Refresh the shard weights from today's profile (611 files): new evidence, the model says slowest shard 691 s to 672 s, spread 47 s to 1 s; CI's own four steps differ by 41 s.
2. Six CI shards (yours): about 100 s off a PR's wall time for 8 more runner-minutes.
3. Trim QA's own heal guard test (35 s, the 2nd slowest file) to four fights.
4. Delete the 73 pictures nothing names (17.6 MB), owner by owner (`docs/qa/unreferenced-pictures-1.874.txt`).
5. Merging the 275 tiny test files (loading is 17% of the suite's work): small saving, large churn: last.
