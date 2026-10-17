# Phone smoke pictures

Real fonts, 320 and 360 px wide, English and French. Made by
`SMOKE_SHOTS=<folder> flutter test test/qa_smoke_*_test.dart`; the tests
fail on any overflow at both sizes in both languages.

| File | Test | Covers |
|---|---|---|
| `qa_smoke_character_test.dart` | clan card, power, radar, compass, stat pick, level signpost, face skill sheet, item and title details |
| `qa_smoke_story_test.dart` | choice cards, arrival sheet, return notice, mercy dialog, locked features, banner pins |
| `qa_smoke_offer_test.dart` | the offer hall with a risky gift: picked, confirm, reward after a bad and a good die |

Shared setup: `test/qa_smoke_harness.dart`. Not yet covered: UX #402 (walk
party, clan flags, level-up radar) and #408 (world move, town service pins),
camp build tray and works list, city chart; add them when on main.
