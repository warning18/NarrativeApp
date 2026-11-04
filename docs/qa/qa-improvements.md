# QA improvements, ranked by value over effort

Written 2026-11-03 from the v1.696.0 profile (`flutter test --reporter json`, 561 test files, 3,852 tests). Scope is what QA owns: tests, `docs/qa/`, the simulator's checks, `qa` issues and the suite's speed. Nothing here changes `lib/`.

## Suite time, before and after (this PR)

| | before | after |
|---|---|---|
| 22 fight test files, summed | 417 s | **200 s** |
| whole suite, summed | about 2,835 s | **about 2,604 s** |
| slowest CI shard (real, 4 runners) | 753 s | **about 651 s** (weights now balance the four shards at 659 s each) |
| failed or skipped | 0 | 0 |

Nothing was weakened: every changed test still reaches the same state and asserts the same things. The saving is waiting that did nothing (item 1).

## Ranked list

### 1. Stale polls in the fight tests (DONE in this PR)

- **What.** About 30 per-file `_pumpUntil` loops waited for the text `Round 2`, which no longer exists after the fight redesign, so every one ran to its cap (40 or 150 iterations of about 300 ms real time). The dice also threw at 1x speed.
- **Why (evidence).** The profile showed 22 fight files at 417 s summed; the loops accounted for about 180 s and the dice waits for about 40 s. Replaced by `pumpFor(tester, n)` (new in `test/support/pump.dart`) and the `combat_dice_speed: 'quad'` preference.
- **Risk.** Low. A test that waited for text that never came was checking nothing at that point; the assertions after it are unchanged. All 22 files pass.
- **Effort.** Done. **Value:** about 230 s of CPU, about 100 s off the slowest shard.
- **Other sessions' tests touched** (speed only): `skill_fight_harness.dart`, `clash_test.dart`, `squad_test.dart`, `fight_markers_test.dart`, `fight_mirror_spell_test.dart`, `fight_pack_echo_test.dart`, `spec_standing_fight_test.dart`, `specialisations_fight_test.dart`, `fight_hero_harness.dart`, `fight_markers_harness.dart`.

### 2. Rebalance the shards from a fresh profile (DONE; make it routine)

- **What.** `test/shard_weights.json` was out of date: the real shards ran 710/669/690/753 s. Regenerated with `tool/shard_weights_from_report.py`; expected 659 s each. Added `qa_smoke_screens_test.dart`.
- **Why.** CI's wall time is the slowest shard. Stale weights cost about 90 s per run.
- **Risk.** None (a file lives in exactly one shard; `tool/shard_tests.py --check 4` guards it).
- **Effort.** 10 minutes per refresh. Suggest refreshing at every L3. **Value:** high, cheap.

### 3. One loud shared `pumpUntil` instead of about 30 copies

- **What.** Put one `pumpUntil(tester, finder, {maxSteps})` in `test/support/pump.dart` that throws when the cap is reached instead of silently moving on.
- **Why.** Item 1 happened because a copy could time out without failing. A loud helper makes the next stale wait a failing test, not 180 s of silence.
- **Risk.** Low to medium: some copies may today rely on timing out quietly; those will start failing and show a real stale wait. **Effort.** About half a day for the 30 copies (mechanical). **Value:** prevents the regression of item 1.

### 4. One `mockFlutterTts()` helper (Cleanup's input a)

- **What.** The same text-to-speech method-channel mock is pasted in 142 test files (about 450 lines). Move it to `test/support/` as `mockFlutterTts()`.
- **Why.** About 450 lines of duplicate code; a change in the plugin means 142 edits.
- **Risk.** Low (identical text; the analyzer and the suite prove it). **Effort.** 1 to 2 hours, scripted. **Value:** maintenance only, no time saved. Touches most sessions' test files, so do it in one PR when no other PR has open test edits.

### 5. The 36 `ux_*mock/shot` tests (Cleanup's input b)

- **What.** 36 tests are mock-ups or picture generators (14,667 lines, about 36 s summed). Four `ux_skills_*` mock tests repeat 102 to 111 lines each.
- **Why.** They check that a mock page builds, which the real screens' smoke tests now do with the real widgets. They cost CI time and review noise.
- **Risk.** Medium: some may still be the only test of a widget. Check each against `tool/qa_unused*.py` and the smoke coverage before moving it. Suggested: move the picture generators to `tool/` (run on demand, off CI), merge the four skills mocks into one parametrised file. **Effort.** 1 day. **Value:** about 36 s of CPU plus 14k fewer lines. UX owns most of them; list each in the PR.

### 6. The fight backdrop's paint cost

- **What.** `fight_backdrop` tests are among the slowest per test (software paint of the full-screen art).
- **Why.** Profile: the top 10 tests are all fight screens at phone size.
- **Risk.** Low if only the pumped size shrinks where the test does not check layout; keep the 320 px checks. **Effort.** 2 hours. **Value:** about 20 s of CPU.

### 7. Per-file load cost (about 466 s of the total)

- **What.** Each of the 561 files pays about 0.8 s to compile and load before its first test.
- **Why.** Fewer, larger files would save most of it, but it hurts failure locality and the shard balance. The cheap form: merge only the 40 or so files with under 3 tests and under 1 s of test time.
- **Risk.** Low, but merging touches other sessions' files. **Effort.** 1 day. **Value:** perhaps 30 s. Low priority.

### 8. Turn the three audit scripts into Dart guards

- **What.** `tool/qa_xref_audit.py` (cross-references), `tool/qa_quests_audit.py` (new: 51 quests, 0 problems) and `tool/qa_docs_stale.py` run by hand at L3. Port the first two to `test/qa_*_test.dart` so CI runs them (each is a few seconds).
- **Why.** The data's references can break between two L3s. Today only the story graph (`qa_story_blocking_test`) and the new-data guard run in CI.
- **Risk.** Low; mutation-check each guard as done before. **Effort.** 1 day for both. **Value:** high: catches broken gamedata on the PR that causes it.

### 9. Real-font phone checks for the screens that lack them

- **What.** At the start of this review 45 of 54 screens had no real-font phone check. `qa_smoke_l3_test` (21 cases) and the new `qa_smoke_screens_test` (12 screens at 412, 360 and 320 px, English and French) cover the player's own screens.
- **Why.** The missing-font fallback hides overflow; the real fonts show it.
- **Risk.** None. **Effort.** The editor screens (Map, Generate, Data, Nodes) remain; 1 day. Low value for players since edit mode is hidden in play mode.

### 10. Tests that check nothing

- **What.** A test that pumps and asserts only `findsWidgets`, or whose only assertion sits behind a loop that can time out. Candidates are the `ux_*` shot tests (item 5) and the old `_pumpUntil` users. Method: `tool/qa_unused*.py` plus a grep for tests with no `expect`.
- **Why.** They give false assurance and cost time.
- **Risk.** Deleting a test needs the owner's agreement. **Effort.** 1 day to list, owners decide. **Value:** medium.

### 11. Report suite time at each PR that touches many tests

- **What.** A line in CI output (or the shard weights refresh in item 2) with the slowest 20 files.
- **Why.** The stale polls lived for months because no one saw them.
- **Risk.** None. **Effort.** 2 hours. **Value:** medium.

### 12. Simulator takes the camp errands

- **What.** The simulator never takes 21 camp errands (8 loyalty errands, 6 "names", 6 "price", `7200_will_choice`).
- **Why.** The story graph guard treats them as enterable, but nothing proves a play-through can finish them. This is Core's simulator; QA files an issue rather than editing it.
- **Risk.** Low. **Effort.** Core: about a day. **Value:** medium.

## Not worth doing

- Parallelising within a shard: CI already has four runners; the load cost dominates.
- Deleting the L3 pictures: small, and they are the record of what was read.

## Order I suggest

1 and 2 (done), then 3, 8 and 4 (small, protect the gains), then 5 and 6 with the UX and Cleanup sessions, then 10 and 12.
