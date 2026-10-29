# Code cleanup: analysis and plan (QA, v1.611.0, 2026-10-29)

Analysis only. Nothing in `lib/`, `assets/` or `pubspec.yaml` was touched; the doing is for the user to assign. Everything below was measured by scripts in `tool/qa_*.py` (read-only, no dependencies, 2 to 8 seconds each; rerun them to refresh the numbers) and by `flutter analyze` with extra lints in a throwaway `analysis_options.yaml` (reverted). The raw lists are in [`docs/qa/code-cleanup/`](code-cleanup/). No simulator run.

## The short version

| What | Found | Worth it? |
|---|---|---|
| Unused code (nothing calls it, anywhere) | **38 symbols, about 250 lines**, 30 of them in Core's files | yes, small and safe |
| Code used only by a test | **71 symbols, about 870 lines** (the biggest: `SuitorCard` 185, `TitlesSection` 115, `ClansSection` 33; `simulatePlaythroughs`, 144 lines, is the tests' entry point: keep) | yes, delete with its test lines |
| Unused imports, locals, privates, parameters | **0** (the analyzer is already clean) | nothing to do |
| Unused UI strings (`app_strings.dart`) | **71 keys read nowhere** + 2 read only by a test, of 3,564 | yes, about 300 lines |
| Unused gamedata fields | **20 fields in 4 files**, 3 of them real (quest choices: `flagToAdd`, `actionType`, `locationID`; NPC `stancePlayer`) | check with the owners |
| Unused images | **5** (`assets/icons/chests/*_open.png`); 52 more are loaded only by a built name and are fine | trivial |
| **A real bug** found on the way: images the build does not ship | the tutorial guide's walk frames **west and south** (16 files) are not in `pubspec.yaml`: the guide dog shows a paw icon when it walks those ways | fix first |
| Duplicates | `lib/`: **6 copy-paste blocks across files** (the 237 "blocks" are almost all data tables inside one file); `test/`: **about 3,200 lines of repeated setup** across 260 files | tests: yes; lib: UX's merges |
| Size | **22 files over 1,500 lines** (the largest: `app_strings.dart` 13,700, `journey_screen.dart` 6,710, `player_session_provider.dart` 6,132, `playthrough_simulator_screen.dart` 4,674, `story_player_screen.dart` 4,367); 17 functions over 150 lines (a 1,621-line `build`) | splits are a later wave, with tests |
| Performance | Core's C1 to C3 and C8 are done (v1.608, v1.609); C4, C5, the sim items C6, C7 and UX's typewriter are open; **2,111 `prefer_const_constructors` sites, but 2,071 of them are two chart data tables**, not widgets | small |

**Recommendation.** Do waves 1 and 2 (about 1,500 lines removed and 750 changed, each change proven by the analyzer) in one dedicated cleanup session, because they cross every owner's files and are mechanical. Leave the big-file splits (wave 4) until a quiet period, one file at a time, and let the owners do the duplicates that need a design choice (wave 3). Nothing here needs the simulator.

## 1. How it was measured, and what it cannot see

| Script | What it reads | Limit |
|---|---|---|
| [`tool/qa_unused.py`](../../tool/qa_unused.py) | every declaration in `lib/` (14,476: classes, functions, constants, methods, getters, fields, enum values) against every identifier use in `lib/`, `test/` and `tool/`, comments and strings stripped, string interpolation kept | counts the **name**, so two symbols with one name hide each other: it can miss dead code, never invent it. Fields set only through a constructor, and enum values, are weak. `@override` and framework hooks are skipped |
| [`tool/qa_unused_strings.py`](../../tool/qa_unused_strings.py) | the keys of `app_strings.dart` against every quoted use; keys built at run time (`'sign_fx_$x'`) are matched by prefix or suffix | 951 keys are covered only by such a pattern and are **not** listed as unused, so the real number can be a little higher |
| [`tool/qa_unused_assets.py`](../../tool/qa_unused_assets.py) | every png by path, file name or stem in code and data; and every folder against `pubspec.yaml` | a name built from an id counts as used |
| [`tool/qa_unused_fields.py`](../../tool/qa_unused_fields.py) | every field the gamedata and the story graph use against the strings of `lib/` | a field read through a whole-object forward (an editor) looks unread |
| [`tool/qa_duplicates.py`](../../tool/qa_duplicates.py) | windows of 15 lines, numbers and strings blanked | tables of similar rows show as duplicates; judge by eye |
| [`tool/qa_size.py`](../../tool/qa_size.py) | file lengths; function lengths by brace matching | one function's name is misread (`simulateSimFight`, 1,462 lines, `sim_combat.dart:1007`) |
| `flutter analyze` with `avoid_unused_constructor_parameters`, `unnecessary_*`, `prefer_const_*`, `cascade_invocations`, `avoid_redundant_argument_values`, `unreachable_from_main` and others | all of `lib/`, `test/`, `tool/` | `unreachable_from_main` reports nothing for a library with no `main` |

False positives to check by hand before deleting: a symbol read only by a JSON key or a reflection-like lookup (marked `in_string` in the raw list), and anything a test uses on purpose (`simulatePlaythroughs`, `debugEditorRoundTrip`).

## 2. Findings

### 2.1 Unused code

**Analyzer:** `unused_import`, `unused_element`, `unused_field`, `unused_local_variable`, `unused_shown_name` and `unused_element_parameter` are default warnings and report **0**. The extra lints found one `avoid_unused_constructor_parameters` (`form` in `lib/widgets/side_view/side_ship.dart:191`), 38 `unnecessary_breaks`, 35 `unnecessary_parenthesis`, 27 `unnecessary_lambdas`, 13 `unnecessary_null_checks`, 8 `prefer_final_locals`, 37 `prefer_const_declarations`: all cosmetic, all fixable by `dart fix --apply` (wave 1).

**Public code nothing uses** (38 symbols in 36 rows; by directory the owner is Core for `combat`, `data`, `gamedata`, `models`, `providers`, `tutorial`; UX for `widgets`, `utils`, `theme`; the shared screens are marked Core/UX). Risk **none** for each: the name appears once in the repository. Proof: delete, `flutter analyze` clean, no test fails (none mentions them).

| Where | Name | Kind | Lines | Owner |
|---|---|---|---|---|
| `lib/combat/combat_aftermath.dart:297` | `aftermathSeed` | function | 1 | Core |
| `lib/combat/doctrine.dart:36` | `doctrineAffixBoost` | constant | 1 | Core |
| `lib/combat/doctrine.dart:39` | `doctrineAffixTasteShare` | constant | 1 | Core |
| `lib/combat/element_reaction.dart:104` | `reactionDescriptionKey` | function | 2 | Core |
| `lib/combat/enemy_affix.dart:69` | `affixFortuneBonus` | constant | 1 | Core |
| `lib/combat/enemy_response.dart:54` | `enemyResponseLabelKey` | function | 2 | Core |
| `lib/combat/ship_combat.dart:274` | `ShipState.baseEvasion` | getter | 2 | Core |
| `lib/combat/skill_vfx.dart:136` | `projectileStyles` | constant | 6 | Core (UX file) |
| `lib/combat/specialisations.dart:404` | `trapStun` | constant | 2 | Core |
| `lib/combat/specialisations.dart:535` | `specResult` | function | 2 | Core |
| `lib/data/camp_rolls.dart:205` | `CampRolls.bansOn` | method | 4 | Core |
| `lib/data/climate.dart:461` | `ChartClimate.coastAt` | method | 1 | Core |
| `lib/data/detour_scenes.dart:114` | `DetourScene.rumourFor` | method | 2 | Core |
| `lib/data/detour_scenes.dart:125` | `DetourScene.isDangerous` | getter | 1 | Core |
| `lib/data/detour_scenes.dart:144` | `detourStopTag` | constant | 1 | Core |
| `lib/data/factions.dart:587` | `SubClan.favourFor` | method | 1 | Core |
| `lib/data/offers.dart:1662` | `anySuitorCanCome` | function | 4 | Core |
| `lib/data/politics_events.dart:334` | `EventVariant.newsFor` | method | 1 | Core |
| `lib/data/risky_gifts.dart:108` | `riskyOutcomeNamed` | function | 2 | Core |
| `lib/data/risky_gifts.dart:229` | `RiskCurse.levelsLeftAt` | method | 1 | Core |
| `lib/data/signs.dart:428` | `scaleSignValue` | function | 2 | Core |
| `lib/data/signs.dart:629` | `SignDef.flavourFor` | method | 2 | Core |
| `lib/data/sim_growth.dart:80` | `SimGrowthTables.offerTables` | getter | 10 | Core |
| `lib/gamedata/db_schema.dart:52` | `visualAssetPath` | function | 7 | Core |
| `lib/providers/elevenlabs_tts_provider.dart:164` | `NarrationRecordings.isBundled` | method | 2 | Core |
| `lib/providers/mode_nudge_provider.dart:23,30` | `ModeNudgeNotifier.dismiss`, `hasSeenModeNudgeProvider` | method, provider | 7 | Core |
| `lib/providers/tab_badges_provider.dart:123` | `questReadinessProvider` | provider | 9 | Core |
| `lib/providers/temple_provider.dart:47` | `activeBlessingProvider` | provider | 9 | Core |
| `lib/providers/town_rulers_provider.dart:22` | `rulerOfTown` | function | 2 | Core |
| `lib/screens/inventory_screen.dart:276` | `scalingStatAbbrev` | function | 10 | Core/UX |
| `lib/screens/skills/skill_sheet.dart:62` | `costLabel` | function | 3 | Core/UX |
| `lib/utils/game_icons.dart:73,112` | `elementColor`, `adventureNodeCategoryIcon` | functions | 25 | UX |
| `lib/widgets/camp_travel.dart:75` | `campRouteLabel` | function | 10 | UX |
| `lib/widgets/item_lore.dart:24` | `itemRarityLabel` | function | 2 | UX |
| `lib/widgets/ship_cutaway.dart:105` | `RoomArtPainter` | class | 107 | UX |
| `lib/widgets/side_view/side_ship.dart:210` | `_Palette.hullDeep` | getter | 1 | UX |

(Core's chapter 1 note C11 and UX's finding 2 listed some of these; `InkReveal` and the French skill-name helper were already removed in v1.611.)

**Code used only by tests** (71 symbols, about 870 lines, of which 144 are `simulatePlaythroughs`, a test entry point to keep; the full list with the test that holds each is in [`code-cleanup/test-only-symbols.md`](code-cleanup/test-only-symbols.md)). The code exists so a test has something to test; delete both, or, if a feature is waiting for it, keep and say so. The big ones:

| Where | What | Lines | Owner | Test |
|---|---|---|---|---|
| `lib/widgets/offer_dialog.dart:1221` | `SuitorCard` | 185 | UX | `clan_story_widgets_test` |
| `lib/widgets/title_widgets.dart:25` | `TitlesSection` | 115 | UX | `offer_dialog_test` |
| `lib/widgets/clan_widgets.dart:702` | `ClansSection` | 33 | UX | `throne_widgets_test` |
| `lib/data/chapter_loop.dart:99,129,155` | `recommendedLevelFor`, `levelsShort`, `nextChapterLevelAdvice` | ~60 | Core | **`chapter_level_advice_test`: the whole file tests code nothing calls** |
| `lib/providers/day_phase_provider.dart:14`, `player_session_provider.dart:597,600` | `hourOfDayProvider`, `dayPhase`, `hourOfDay` | ~20 | Core | `wave16_hooks_test` |
| `lib/combat/spells.dart:202-209` | `hitsEnemies`, `needsEnemyPick`, `needsAllyPick` | ~12 | Core | `spells_test` |
| `lib/combat/specialisations.dart` | `isMainSpec`, `briarReflect`, `longVigilMend`, `censerBurn` | ~50 | Core | `specialisations_test`, `spec_variants_test` |
| `lib/data/character_start.dart:46` | `startingTotals` (its fallbacks of 100 HP and 10 damage disagree with the game's 20 and 2) | ~20 | Core | `character_start_test` |
| `lib/providers/player_session_provider.dart:5707` | `learnSpell` | ~30 | Core | `player_session_provider_test` |

**`file_only`:** 130 classes, 272 constants, 143 functions and 9 enums are public but used only inside their own file. They could be private (a rename, which makes the analyzer's `unused_element` watch them from then on). No deletion; a mechanical wave-1 option, and the cheapest way to make the analyzer catch future dead code (list in `code-cleanup/unused-symbols.txt`).

### 2.2 Strings, data and assets

- **Strings**: 71 keys of `app_strings.dart` are read nowhere and 2 only by a test (`journey_level_place`, `stat_pick_rare`); 3,564 keys in all. Full list with line numbers: [`code-cleanup/unused-strings.txt`](code-cleanup/unused-strings.txt). Families: the `*_abbr` stat labels (7), `journey_level_*`/`geo_level_*` (6), the quest sections (`quests_section_*`), the skill tree toggles, `sign_*_button`, `patron_kind_*`, `stat_pick_tier_*`, `mode_nudge_*` (the nudge provider is dead too). **Owner: whoever added the screen; the key's text is Narrative's wording, the removal is mechanical.** Risk none if no key is built at run time under that name (the script already matched prefixes/suffixes); prove with `qa_strings_test`, `qa_data_refs_test` and the analyzer. The 951 keys that are covered only by a built name are worth a second pass by hand in the same wave.
- **Gamedata fields** ([`code-cleanup/unused-gamedata-fields.txt`](code-cleanup/unused-gamedata-fields.txt)): quest choices carry `flagToAdd` (51 records), `actionType` (51) and objectives `locationID` (59), which no code reads (only the editor's schema text names them); NPCs carry `stancePlayer` (50). In the story graph, the `race:*`, `profession:*` persona-variant keys are read through a prefix and are fine. **Owner: Core (quests, NPCs).** Either dead data, or a missing feature: Core should say which before anything is deleted. Do not delete until Narrative confirms no quest relies on it.
- **Images**: 620 png files. 5 are mentioned nowhere (`assets/icons/chests/*_open.png`, 5 files: the closed ones are used). 52 more (`pixel_fx/vfx_*`, `banners/clan_*`, `ship_cutaways/*_battered`, `fighters/*`, `chests/*_closed`) are loaded only by a name the code builds, and are fine.
- **Bug: images the build does not ship.** `pubspec.yaml` lists asset folders one by one (a folder entry is not recursive). Checked by loading them in a test (`rootBundle.load`):
  - `assets/visuals/chapters/` (8 art strips): not listed at v1.610; UX found it too and v1.611 fixed it.
  - `assets/visuals/companion/dog_companion_animations/Walking/west/` and `…/Walking/south/` (16 files): **not listed, still missing at v1.611**. `lib/tutorial/guide_tour.dart:264,266` asks for them when the guide walks west or south and gets the paw-icon fallback (`errorBuilder`, `guide_tour.dart:650`). Two lines of `pubspec.yaml` fix it. **Owner: UX (assets) and the Manager (pubspec).** A guard test ("every asset folder is declared, or listed as source art") goes in with the fix; QA will add it.
  - Source art that is correctly not shipped: `Fight_-_Attack/rotations` and `…/Bark/{east,north,west}` (26 files). If they are only sources, they belong outside `assets/` (a repo folder such as `art-src/`), so the next audit does not have to ask.

### 2.3 Duplicates

- **`lib/`**: `qa_duplicates.py` (15-line windows) finds 237 blocks, but 3,632 of the repeated lines are inside `app_strings.dart`, 1,174 in `data/origin_stories.dart`, 734 in `data/chart_worlds.dart`, 695 in `gamedata/db_schema.dart` and 277 in `data/expedition_kinds.dart`: **tables with a common shape, not code to merge**. The real copy-paste across files is six blocks of 15 to 20 lines:

  | Block | Where |
  |---|---|
  | 20 lines | `widgets/feature_unlock.dart:345` and `widgets/return_notice.dart:94` |
  | 17 lines | `screens/journey_screen.dart:456` and `screens/city_chart_screen.dart:57` |
  | 17 lines | `screens/story_player_screen.dart:4083` and `screens/main_menu_screen.dart:390` |
  | 17 lines | `widgets/weather_chip.dart:141` and `widgets/ward_mark.dart:79` |
  | 15 lines | `widgets/title_detail_view.dart:187` and `widgets/item_detail_view.dart:498` |
  | 15 lines | `screens/journey_screen.dart:5800` and `screens/story_player_screen.dart:3426` |

  Within one file: `story_player_screen.dart:3015-3044` and `3229-3259` (28 lines), `sim_combat.dart:519-549` and `639-668` (29), `expedition_kinds.dart:322-370` (30 overlapping). **UX's list** (the `DieBadge`/`CharacterDieBadge` pair and four private tag widgets `_Tag` x2, `_TagChip`, `_Badge`) is not found by line matching because the lines differ; it is a design merge (UX, finding 3 of `chapter1-ux.md`, about 150 lines). **Core's list** (the simulator copies the fight screen's constants, C6 and C7) needs a shared file in `lib/combat`.
- **`test/`**: 293 duplicated blocks, 14,288 repeated lines by the same count; the part that is plain setup repeated across files is **about 3,200 lines**:
  - a 19-line `MaterialApp`/`ProviderScope`/size setup in 26 files, a 22-line one in 20, a 15-line one in 24 (`journey_*`, `district_*`, `weather_chip_narrow`, ...);
  - the UX mock tests (`ux_skills_mock_test`, `ux_skills_styles_mock_test`, `ux_skills_combined_mock_test`) repeat the same 102 lines three times;
  - font loading is written in `qa_smoke_harness.dart` and, with the same 19 lines, in `qa_fight_tips_real_font_test`, `qa_story_text_real_font_test`, `qa_real_font_layout_test` and others.

  A `test/support/` set (a phone `pumpApp`, `loadFonts`, the mock scaffold) would remove it. **Owner: QA** (tests only, nothing weakened); done in #591 for the simulator's tables, the same pattern.

### 2.4 Size and complexity

Files over 1,500 lines (`code-cleanup/size.txt` has all 51 over 1,000):

| Lines | File | Classes | What a split needs |
|---|---|---|---|
| 13,700 | `lib/l10n/app_strings.dart` | 0 (one const map) | a map per feature merged in one `const`, keys unchanged: no behaviour change; every session edits this file, so do it in a quiet window (a conflict magnet) |
| 6,710 | `lib/screens/journey_screen.dart` | 21 | `build` is 1,621 lines (`:1453`), another 792 (`:4292`) and 579 (`:6129`); cut by view (map, list, sheets, walk) into files with `part`/extensions as the fight screen already does (`fight_actions`, `fight_cards`, `fight_clash`) |
| 6,132 | `lib/providers/player_session_provider.dart` | 3 | one notifier with hundreds of methods: extensions or mixins per feature (camp, forge, allies, signs) |
| 4,674 | `lib/screens/playthrough_simulator_screen.dart` | 15 | the engine (`simulatePlaythroughs` and the runner) belongs in `lib/data/`; the screen is a debug UI |
| 4,367 | `lib/screens/story_player_screen.dart` | 21 | `build` 796 and 440 lines; the choice, the sheet and the excursion parts |
| 3,993 | `lib/gamedata/db_schema.dart` | 1 | schema data: one file per table family |
| 3,980 | `lib/screens/ship_battle_panel.dart` | 9 | panel, log, orders |
| 2,735 | `lib/data/sim_combat.dart` | 3 | `simulateSimFight` is 1,462 lines: the biggest function in the code |
| 2,588 | `lib/data/factions.dart` | 28 | one file per type |
| 2,422 | `lib/widgets/chart_map_painter.dart` | 3 | `paint` 499 lines |

Other long functions: `shop_detail_screen.dart` `build` 657, `settings_screen.dart` `build` 590, `journey_place.dart` `paint` 544, `playthrough_simulator_screen.dart` `build` 549, `fight_rounds.dart` `_confirmRoll` 470 and `_takeEnemyTurn` 415, `room_plan.dart` `_lay` 431, `race_profession_screen.dart` `build` 421, `inventory_screen.dart` `build` 411, `world_map_screen.dart` `build` 407. 353 functions over 150 lines in `lib/` and `test/`, 17 of them in `lib/` by the script's own declaration pattern (it undercounts; `main` bodies of tests are long by habit: `player_session_provider_test` 1,084, `combat_engine_test` 1,058).

### 2.5 Performance, status of what the notes name

| Item | Where | Status at v1.611 |
|---|---|---|
| C1 the fight reparses tables each build | `fight_screen.dart` | **done**, v1.609 |
| C2 the Journey's places rebuild on every session change | `city_provider.dart` | **done**, v1.609 |
| C3 the camp's companion leads | `chapter_loop_provider.dart` | **done**, v1.609 |
| C4 three chapter providers watch the whole story state | `chapter_loop_provider.dart:24,34,53` | **open**, 3 lines (a select) |
| C5 story stops indexed twice at startup | `choice_flow_provider.dart:15` | **open**, 2 lines |
| C6 the simulator's damage is lower than the game's | `sim_combat.dart:335` | **open**; changes the simulator's numbers (a re-baseline, after the specialisations decision, see `docs/qa/sim-world.md`) |
| C7 the simulator copies the fight screen's constants | `sim_combat.dart:814`, `sim_companions.dart:44` | **open** |
| C8 the heal preview ignores two heal rules | `fight_dice_rules.dart:316` | **done**, v1.608 |
| UX typewriter: `setState` every 16 ms for the whole bubble | `companion_remark_bubble.dart:149`, `guide_tour.dart:423` | **open**, ~15 lines (2 chars a tick, or a `ValueNotifier` for the text) |
| `.repeat()` animations and reduced motion | `city_chart_view.dart:226`, `fight_figure.dart:117` | **unverified** (UX); trace the callers |
| `prefer_const_constructors` | 2,111 sites in `lib/`, **2,071 of them in `data/chart_story.dart` (1,294) and `data/chart_worlds.dart` (777)**: data tables | const-izing the tables moves them out of startup allocation; the other 40 sites (widgets, `intro_screen`, `room_plan`) are free wins |
| `cascade_invocations` (665), `avoid_redundant_argument_values` (290) | everywhere | style only; **leave** (an explicit default documents intent) |

No other hotspot is claimed: nothing was profiled, and this analysis measured no frame time. A `flutter run --profile` timeline of the Journey and the fight is the way to find the next one.

### 2.6 The test suite

- **Size**: 521 `_test.dart` files; the shard weights (427 files carry one, the rest use the default) add up to about 1,626 s, four shards of about 448 s each. After #591 the 25 simulator files cost 246 s summed (273 before).
- **Slowest (shard weights, seconds)**: `boss_balance_test` 30, `clash_balance_test` 25, `qa_real_font_cards_test` 21, `sim_coverage_test` 21, `fight_lab_companion_test` 20, `fight_lab_test` 19, `qa_full_map_test` 18, `story_layout_test` 18, `ux_story_room_test` 18, `qa_smoke_tints_test` 16, `camp_flow_test` 16, `journey_moves_test` 16, `world_road_play_test` 15. Next speed candidates: `clash_balance_test` (three seeds of 40 runs, twice; +13 s since the shared world) and `sim_coverage_test`.
- **Overlap**: the three UX `ux_skills_*_mock_test` files share 102 lines; `fight_*` tests (`fight_ground`, `fight_entrance`, `fight_windup`, `fight_dice_rules`) share a 17-line setup; the 26-file `MaterialApp` setup above. Setup, not coverage: merging helpers keeps every assertion.
- **Tests of dead code**: `chapter_level_advice_test` (the whole file), parts of `spells_test`, `wave16_hooks_test`, `specialisations_test`, `throne_widgets_test` (`ClansSection`); see the test-only list. Delete together with the code (wave 2).
- **Two frozen runs** (`sim_competent_test`, `sim_companions_test`) are re-pinned on nearly every story PR: Core's S1, replaced by property checks (v1.615).

## 3. The plan

Order is chosen so that the least-shared files move first, the files every session edits move last, and each wave leaves `main` green.

| Wave | What | Files | Lines | Who | Prove it safe |
|---|---|---|---|---|---|
| **0** (a few minutes) | declare the two missing guide folders in `pubspec.yaml` (`Walking/west`, `Walking/south`), then QA's guard "every asset folder is declared or listed as source" | `pubspec.yaml`, 1 test | +2 | Manager or UX, QA for the guard | the guard; `rootBundle.load` of the 16 files |
| **1** mechanical, analyzer-proof | `dart fix --apply` for `unnecessary_breaks`, `unnecessary_parenthesis`, `unnecessary_lambdas`, `unnecessary_null_checks`, `prefer_final_locals`, `prefer_const_declarations`, and `prefer_const_constructors` on the ~40 widget sites; enable those lints in `analysis_options.yaml` so they stay at zero | ~60 files | ~150 changed | one cleanup session | analyze clean with the lints on, changed tests, CI |
| **2** unused code and data | the 38 dead symbols; the 71 test-only symbols with their test lines; 73 strings; 5 chest icons; the quest/NPC fields once Core confirms | ~70 lib files, ~25 test files, `app_strings.dart` | **about -1,000 lib, -700 test, -300 strings** | by owner: Core (providers, data, combat), UX (widgets, utils), Narrative reviews the strings; or the cleanup session with the owners' sign-off | each name appears once in the repo; analyze clean; the tests that mentioned the name; `qa_strings_test`, `qa_data_refs_test` |
| **2b** analyzer watches the rest | make the 130 file-only classes, 143 functions, 272 constants private (a rename inside one file) | ~150 files | ~600 changed | cleanup session | analyze clean (any name that turns out used elsewhere fails at once) |
| **3a** test boilerplate | `test/support/` (`pumpPhone`, `loadFonts`, the mock scaffold) and the 260 files that repeat it | ~260 test files | **about -3,200** | **QA** (tests only) | the same tests pass, unchanged assertions; the suite time reported before and after |
| **3b** UI duplicates | `DieBadge`/`CharacterDieBadge`, the four tag widgets, the six cross-file blocks | ~14 files | ~-300 | UX | the widget tests of each; pictures before/after |
| **3c** simulator constants | C6, C7: one shared sum and one constants file in `lib/combat` | ~6 files | ~-50 | Core, with QA re-baselining the bands once | `boss_balance_test`, `sim_*` tests; numbers move: the user decides |
| **4** big files, one per PR | `app_strings.dart` first (no behaviour, but the conflict magnet: only when every session has merged), then `playthrough_simulator_screen.dart` (engine to `lib/data/`), `journey_screen.dart`, `story_player_screen.dart`, `player_session_provider.dart`, `db_schema.dart`, `ship_battle_panel.dart`, `sim_combat.dart` | 8 files to ~60 | moves, ~0 net | the owner of each screen, **never two at once** | analyze clean; every test that imports the file; the smoke tests (`qa_smoke_*`); CI; a run-through of the screen |
| **5** performance | C4, C5, the typewriter, the reduced-motion check, then a profile timeline before anything else | ~10 files | ~50 | Core (providers), UX (widgets) | the existing tests; a frame-time capture before and after |

Estimate: waves 0 to 2b are about 1,500 lines removed and about 750 changed in about 250 files, one dedicated session; 3a is QA's own; waves 3b to 5 are owners' work over time. The versions: only waves that change `lib/` or `pubspec.yaml` bump one; 3a and any docs/tests-only PR do not.

**Order against other sessions' open PRs.** Before each PR: `git fetch origin && git diff --stat origin/main...origin/<other-branch>` for every open branch (CLAUDE.md, shared files), and skip the files any of them touches; do those files in the next PR, after the other merges. Wave 2 touches `app_strings.dart` (everyone edits it): remove keys in one small PR, never reformat neighbours. Waves 1 and 2b touch many files: do them right after a merge of every open PR, and merge them the same day.

## 4. Rules for a dedicated cleanup session

1. **No behaviour change.** A cleanup PR moves, deletes or renames; it never changes a number, a string's text, a layout or a rule. If a deletion would change what the player sees, it is not a cleanup: it goes to the owner.
2. **One wave per PR, one area per PR** (Core's files, UX's files, or the shared screens), small enough to read in ten minutes. Never a repo-wide PR except wave 1's lint fixes, which the analyzer proves.
3. **Prove every deletion.** Before: the name's use count from `tool/qa_unused.py` (zero, or only the tests you delete with it). After: `dart format --output=none --set-exit-if-changed .`, `flutter analyze` clean, the test files that mentioned the name, then the full CI. A name in a string (`in_string` in the raw list) is checked by hand.
4. **Never touch a file another session has an open PR on.** Check with `git diff --stat origin/main...origin/<branch>` first; leave that file for the next PR. Resolve conflicts by keeping both sides.
5. **Merge `origin/main` into the branch right before opening the PR**, and rerun the scripts: the lists move as the others merge.
6. **A deleted symbol takes its tests with it**, in the same PR, and the PR says which test lines went.
7. **The big files are split one at a time**, each after the owner confirms no open work on it, with no other change in the PR.
8. **The version bumps only when `lib/`, `assets/` or `pubspec.yaml` changes.** Docs and tests do not bump. Use the number the Manager reserved.
9. **Report the suite time** before and after any PR that touches tests.
10. **Never weaken a test to make a deletion pass.** A test that fails because the code it tests is gone is deleted with it; a test that fails for any other reason is a finding, not a cleanup.
11. **Refresh `docs/qa/code-cleanup/` and this plan** with the scripts at the end of each wave (`python3 tool/qa_unused.py`, `qa_unused_strings.py`, `qa_unused_assets.py`, `qa_unused_fields.py`, `qa_duplicates.py`, `qa_size.py`).

## 5. What QA added to the repository

`tool/qa_unused.py`, `qa_unused_strings.py`, `qa_unused_assets.py`, `qa_unused_fields.py`, `qa_duplicates.py`, `qa_size.py` and their shared `qa_dart_scan.py` (read-only analysis, run from the repo root), and the raw outputs in `docs/qa/code-cleanup/`. The extra lint run was a throwaway `analysis_options.yaml` and was reverted; its counts are in section 2.1 and 2.5.
