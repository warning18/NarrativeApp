# What the QA tests look at, per screen

One table, so an L3 can see at a glance what already has a real-font layout check and what has none. Updated at v1.503 (2026-10-21). "Phone" is 360 x 740 and 320 x 568, English and French, the app's own fonts, no overflow (the `qa_smoke_*` tests share `test/qa_smoke_harness.dart`: `SMOKE_SHOTS=<folder> flutter test test/qa_smoke_<name>_test.dart` also writes a picture per pass; pictures worth keeping are in [`smoke/`](smoke/README.md)). Each file is one test; the file name is the key.

## Layout on a phone (real fonts)

| Screen or widget | Test | Cases |
|---|---|---|
| **Character**: clan card, power, radar, compass; the stat pick; level signpost; face skill sheet; item and title details | `qa_smoke_character_test` | clan card (Crows, the Dominion as the nemesis, the Penitents), power block, radar, compass, stat pick (rare, heroic), signpost, face skill sheet, two items, a title |
| **Level up**: the screen and its stat rows with the ability radar; the walk | `qa_smoke_walk_test` | the land walk with and without companions, the walk bubble (long words), the clan flags, the level-up screen, the stat rows |
| **Level-up pop-up** and the home shell's bar | `qa_real_font_layout_test` | the pop-up at 360 and 320 px, the bar and the tablet rail at a landscape phone |
| **Story**: choice cards, arrival sheet, return notice, mercy dialog, locked features, banner pins | `qa_smoke_story_test` | 6 cases |
| **Story text**: the longest scenes and those with the most bold | `qa_story_text_real_font_test` | scenes of chapters 1 to 8; the choices reachable |
| **Chapter 7 hub** (the cove camp page with the quest tracker) | `qa_ch7_hub_layout_test` | the "Enter the camp" button on the page |
| **Fight**: one-time tips (ambush, a clan's doctrine) | `qa_fight_tips_real_font_test` | two tips, the doctrine tip, buttons on screen |
| **Fight**: the anomaly chip | `qa_anomaly_chip_en_test`, `_fr_test` | every field anomaly, a 360 px fight |
| **Camp**: the town section (tray, works list), the Parley Tent, Bone-Caster's Hut, Warding Cairn and Star Well cards opened, the skill tree with its clan flags | `qa_smoke_camp_test` | poor and rich saves, 4 house sheets, 2 trees |
| **Camp**: the dice loadout's face tiles and the town's cards | `qa_real_font_cards_test` | six tiles of one size whatever they carry |
| **Offer hall** with a risky gift, the die, the reward card; two companions in the party (their words on the card and on the die) | `qa_smoke_offer_test` | roll of 1 and of 20, picked, confirm, die, reward, two bubbles |
| **Temple** sheet | `qa_smoke_temple_test` | neutral, Hostile and Sworn price, the Hunted refusal, too poor, mended today |
| **Companions' words** at the wave 15 moments | `qa_smoke_remarks_test` | the longest of the 88 lines, an exchange, a hut built, a Mending, a Blessing |
| **Journey and tints**: five towns (ruled, mixed, neutral, a place with no town view), district and town views with the "Held by" line, the world chart | `qa_smoke_tints_test` | 4 towns x district/town, the world chart |
| **World chart**: the city chart with its service pins, a market's service sheet, the world move (flat and globe), the towns' halos, a town changing hands (one, many: the toast), the roll power row | `qa_smoke_world_test` | 8 cases |
| **Full map** on real story walks | `qa_full_map_test` | empty, early, mid-game, ending saves; tap and travel rules |

## Not a layout check, but guarded

| What | Test |
|---|---|
| The gamedata's references, the string table, the French story typography, the bold markup | `qa_data_refs_test`, `qa_strings_test`, `qa_story_fr_test`, `qa_markup_test` |
| Each scene's building and spot, each town's service pins | `qa_buildings_pins_test` |
| Tests that roll a check must seed it; every simulator test loads the tables the simulator needs | `qa_seeded_rolls_test`, `qa_sim_tables_test` |
| The harbour, the land crossing and the save versions; the build "Play to chapter" hands back; the chapter 7 side quests; the travel history | `qa_harbour_crossing_test`, `qa_autoplay_build_test`, `qa_ch7_side_quests_test`, `qa_travel_history_test` |
| The five professions win within 8 points of each other | inside `boss_balance_test` (QA's check, Core's file) |
| Clan power over 50 playthroughs (a measurement, runs only with `CLAN_POWER_OUT`) | `qa_clan_power_50_test` |

## Screens with no real-font check yet (candidates for the next L3)

- The Journey's step list and the place sheets (read in the L3s by hand; `journey_*` tests use the test font).
- The camp's other tabs (Companions, Quests) and the bounty board.
- The shop screens, the port and the voyage screen.
- The character tab's sections other than the clan widgets (titles list, equipment, skills lists).
- The main menu and the settings.
- The world chart's camera drag (v1.496) and the colour fade of a town changing hands (v1.503): behaviour is tested by UX, the look is not pictured.
- The fight screen itself beyond the tips and the anomaly chip.
