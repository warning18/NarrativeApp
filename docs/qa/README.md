# QA log

**Last L3: 1.264.0** (2026-10-12, head `ef2e38b`, Android only). Next L3 due at
1.274.0, before a release the user shares, after a big refactor, or on
request. See "QA levels" in `CLAUDE.md` for what each level covers.

Prepared for the next L3: [the 1.270.0 baseline and the screens to read](l3-prep-1.270.0.md)
(compare 1.274.0 against it).

Full-regression (L3) passes, newest first. The detail of each is in its own
file in this folder.

| Version | Date | Result | Suite time | Report |
|---|---|---|---|---|
| 1.264.0 (`ef2e38b`, #186) | 2026-10-12 | Pass. `dart format` clean, `flutter analyze` no issues (15 s), full suite 2141 tests all passed. 100-run simulator batch compared with 1.256.0: no regression (800-run check 36.7% attempt win against 37%). 0 scenes statically unreachable; exploring runs reach 97% of 415 scenes. Cross-reference audit clean. One issue filed (#182) and fixed (#184) during the cycle. | 14m32s | [l3-1.264.0.md](l3-1.264.0.md) |
| 1.254.0 (`76c8773`) | 2026-10-12 | Pass (first baseline). `dart format` clean, `flutter analyze` no issues (31 s), full suite 2113 tests all passed. Cross-reference audit found no dangling skill, tree, merge, enemy-move, loot or effect references, and every skill has French text. No issues filed. | 14m44s | this file |

Notes from the 1.254.0 baseline:

- The reports in `docs/simulation/` then dated from 1.228.0 (regenerated on
  1.256.0 in #176).
- The guards added with it: `test/qa_strings_test.dart` (string table and
  `tr()` keys), `test/qa_data_refs_test.dart` (gamedata cross-references),
  and `test/qa_story_fr_test.dart` (French typography of the story graph's
  bare `fr` keys, which `french_data_lint_test` does not read).
