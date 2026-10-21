# Phone smoke pictures

Real fonts, 320 and 360 px wide, English and French. Made by
`SMOKE_SHOTS=<folder> flutter test test/qa_smoke_*_test.dart`; the tests
fail on any overflow at both sizes in both languages.

| File | Test | Covers |
|---|---|---|
| `qa_smoke_character_test.dart` | clan card, power, radar, compass, stat pick, level signpost, face skill sheet, item and title details |
| `qa_smoke_story_test.dart` | choice cards, arrival sheet, return notice, mercy dialog, locked features, banner pins |
| `qa_smoke_offer_test.dart` | the offer hall with a risky gift: picked, confirm, reward after a bad and a good die |
| `qa_smoke_walk_test.dart` | wave 13 (v1.480): land walk with party, walk bubble, clan flags, level-up radar |
| `qa_smoke_world_test.dart` | wave 14 and v1.482: city chart with service pins, town service sheets, world move (flat and globe), roll power row |
| `qa_smoke_camp_test.dart` | the camp's town section (building tray, works list, built and slot counts), the Parley Tent, Bone-Caster's Hut, Warding Cairn and Star Well cards opened (all chapters unlocked), the skill tree with its clan flags |

Shared setup: `test/qa_smoke_harness.dart`. Not yet covered: the skill sheet's flag row (a skill opened), the stat pick and offer hall with a built roll house (after UX's #425).

Findings (no overflow; cosmetic, for UX): in the Star Well sheet at 320 px the
gold need reads "G" on one line and "900/1200" on the next, beside "Encore
300 G." (`camp_card_star_well_320_fr.png`).
