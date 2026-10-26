# UX mocks and Wave 18 proposal — index

Four mocks (pictures from the mock tests, no `lib/` changes) and the Wave 18
proposal, on one branch (`claude/ux-mocks`). Each plan lists what it needs from
Core or Narrative.

| Mock | Picture | Plan | Mock test |
|---|---|---|---|
| Life Before scenes | `docs/ux-shots/life-scenes-mock.png` | `life-scenes.md` | `test/ux_life_scene_mock_test.dart` |
| Grouped way list | `docs/ux-shots/ways-grouped-mock.png` | `ways-grouped.md` | `test/ux_ways_group_mock_test.dart` |
| Tutorial animation | `docs/ux-shots/tutorial-animation-mock.png` | `tutorial-animation.md` (hooks needed from Core in `lib/tutorial`) | `test/ux_tutorial_anim_mock_test.dart` |
| Notice board | `docs/ux-shots/noticeboard-mock.png` | `noticeboard.md` | `test/ux_noticeboard_mock_test.dart` |

Wave 18 (one page): `wave18-ux.md`. Its build is v1.558, after Core's step 1
(Saltmouth: locked districts, clan-held districts, flips).

To regenerate a picture: `UX_SHOTS=<dir> flutter test test/ux_<name>_mock_test.dart`.
