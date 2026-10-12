# QA log

Full-regression (L3) passes, newest first. See "QA levels" in `CLAUDE.md`
for what each level covers and when an L3 is due (every 10th release, before
a release the user shares, after a big refactor, or on request).

| Version | Date | Level | Result | Suite time |
|---|---|---|---|---|
| 1.254.0 (`76c8773`) | 2026-10-12 | L3 (first baseline) | Pass. `dart format` clean, `flutter analyze` no issues (31 s), full suite 2113 tests all passed (14m44s, includes `test/sim_*_test.dart`). Gamedata cross-reference audit found no dangling skill, tree, merge, enemy-move, loot or effect references, and every skill has French text. No issues filed. | 14m44s |

Notes from the 1.254.0 baseline:

- The reports in `docs/simulation/` date from 1.228.0 and were not re-run
  (attempt win rate 34%, chapter 5 the hardest at 18%, melee classes about
  17 points behind casters). Regenerate them at the next L3.
- The guards added with it: `test/qa_strings_test.dart` (string table and
  `tr()` keys), `test/qa_data_refs_test.dart` (gamedata cross-references),
  and `test/qa_story_fr_test.dart` (French typography of the story graph's
  bare `fr` keys, which `french_data_lint_test` does not read).

Next L3 due: 1.264.0, or sooner on request.
