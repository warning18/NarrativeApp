# QA log

**Last L3: 1.285.0** (2026-10-14, head `5a416c6`, Android only). Next L3 due at
1.295.0, before a release the user shares, after a big refactor, or on
request. See "QA levels" in `CLAUDE.md` for what each level covers.

The baselines taken ahead of the L3s: [1.270.0](l3-prep-1.270.0.md), [1.285.0](l3-prep-1.285.0.md).

Full-regression (L3) passes, newest first. The detail of each is in its own
file in this folder.

| Version | Date | Result | Suite time | Report |
|---|---|---|---|---|
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
