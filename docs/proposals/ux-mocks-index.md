# UX mocks and Wave 18 proposal — index

Eight mocks (pictures from the mock tests, no `lib/` changes) and the Wave 18
proposal, on one branch (`claude/ux-mocks`). Each plan lists what it needs from
Core or Narrative.

| Mock | Picture | Plan | Mock test |
|---|---|---|---|
| Life Before scenes | `docs/ux-shots/life-scenes-mock.png` | `life-scenes.md` | `test/ux_life_scene_mock_test.dart` |
| Grouped way list | `docs/ux-shots/ways-grouped-mock.png` | `ways-grouped.md` | `test/ux_ways_group_mock_test.dart` |
| Tutorial animation | `docs/ux-shots/tutorial-animation-mock.png` | `tutorial-animation.md` (hooks needed from Core in `lib/tutorial`) | `test/ux_tutorial_anim_mock_test.dart` |
| Notice board | `docs/ux-shots/noticeboard-mock.png` | `noticeboard.md` | `test/ux_noticeboard_mock_test.dart` |
| Forge (sheet and forging moment) | `docs/ux-shots/forge-sheet-mock.png`, `forge-moment-mock.png` | `forge-mock.md` (rule: Core's `forge-roll.md` on `claude/core-forge-roll`) | `test/ux_forge_mock_test.dart` |
| Clan standing sign (banners and ring) | `docs/ux-shots/standing-sign-mock.png` | `standing-sign.md` (Core's three-way mapping; 11-step signs as the finer option) | `test/ux_standing_sign_mock_test.dart` |
| Clan power sign (beside the standing sign) | `docs/ux-shots/power-sign-mock.png` | `power-sign.md` (rank chevrons at the foot, four tiers; crest size on the ring) | `test/ux_power_sign_mock_test.dart` |
| Clan power sign, round 2 (smaller bars, rising steps, a rim) | `docs/ux-shots/power-bars-mock.png` | `power-sign.md` (Round 2) | `test/ux_power_bars_mock_test.dart` |

Wave 18 (one page): `wave18-ux.md`. Its build is v1.560, after Core's step 1 (v1.558) and Narrative (v1.559)
(Saltmouth: locked districts, clan-held districts, flips).

To regenerate a picture: `UX_SHOTS=<dir> flutter test test/ux_<name>_mock_test.dart`.
