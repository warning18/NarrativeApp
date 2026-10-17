# L3 checklist for v1.471.0 (wave 12)

Prepared on `main` at v1.466.0 (`98ba9fc`), for the L3 the manager asked for once v1.471 is merged. The last L3 was at 1.285.0 (`5a416c6`, 2026-10-13), so this one covers about 180 releases, far more than the earlier ones (1.264 to 1.274 to 1.285: 10 each).

## 1. What changed since the last L3 (1.285.0 to 1.466.0)

- **209 files of `lib/`** changed (36,940 lines added, 3,944 removed); none deleted.
- **4 new screens:** `city_chart_screen`, `heard_of_travel`, `quest_autopilot`, `training_picker`.
- **41 new widgets** (listed in section 4) and **63 changed screen and widget files**.
- **7 new gamedata tables:** `city_plans`, `detour_scenes`, `detours`, `expedition_steps`, `spec_variants`, `specialisations`, `training_paths` (35 gamedata files changed in all).
- **New data code:** the detour engine and scenes, city plans and districts, the feature ladder, clan power and territory, the crisis and the fall, the nemesis and rival hunters, specialisations, skill crafting, training, stat picks and the stat ledger, the stat-scale save migration.
- **Rules changed on purpose, so the simulator's numbers are not comparable with 1.285.0 as they stand:**
  - v1.429 difficulty review (every profession wins about 70% of its fights);
  - v1.458 the smaller scale: one pick a level, every fight number divided by 5, save version 6;
  - v1.464 the simulator applies turn-in politics (quest power and standing);
  - v1.380 to v1.401 fight rules by place, markers and the nemesis fights;
  - v1.351 fight-length rules.
  Compare the new batch with the **latest report in `docs/simulation/`** (`report-100-runs.md`, `difficulty-review.md`, `clan-power-50-v1.464.md`) and with the 1.285.0 table in `l3-1.285.0.md` for the shape (class gap, chapter curve), not for the level.
- **Save versions:** 6 now (3 to 4 materials, 4 to 5 harbour, 5 to 6 the stat rescale). Fixtures `test/fixtures/session_v1_198.json` and `session_v1_204.json` must load through the whole chain and not be granted anything twice (guarded in `qa_harbour_crossing_test` and `stat_scale_test`).

## 2. Wave 12, read first (the screens it changes)

| Release | What | Read |
|---|---|---|
| v1.467 Narrative | "Go" in place of "Partir" | every place the word showed: the map's place sheet, the Journey's step marks, the camp's travel buttons, in French at 360 and 320 px (a shorter word should not leave a gap); no "Partir" left in `app_strings.dart` or the story |
| v1.468 Core | the fight tutorial on the first goal, doctrine or situation | the tutorial card over a fight on a 360 and 320 px phone, EN and FR; that it shows once per save and stays out of the way of the fight's buttons; a fight loaded from an old save (no flag) |
| v1.469 UX | the stat popin on the Character radar | the radar's tap, the popin's text with the new scale (÷5), the stat ledger's sources, EN and FR, both sizes, with real fonts |
| v1.470 UX | the story text display (coloured names, bold, paragraphs, typewriter) | the story player on long scenes at 360 and 320 px: no overflow with bold and coloured runs, the typewriter's skip (a tap), reduced motion (`disableAnimations`), the read-aloud, and the French apostrophes and non-breaking spaces |
| v1.471 Narrative | chapters 1 and 2 marked | the marks' text (EN and FR, with `qa_story_fr_test`), where the marks show, and that no node is changed in its ids or links (`story_graph_integrity_test`) |

## 3. Automated steps, in this order

1. Merge `origin/main` into `claude/qa-2`; note the head and the version.
2. `dart format --output=none --set-exit-if-changed .`, `flutter analyze`.
3. The full suite alone on the machine (nothing else running): `flutter test --reporter json > report.json`. Compare the time with 882 s (v1.445, 3305 tests, 4 cores); expect a little more (the suite has grown), and see `test/shard_weights.json` for the per-file times. Refresh `test/shard_weights.json` from that same run (`tool/shard_weights_from_report.py report.json`) and check the four shards' balance with `tool/shard_tests.py --check 4`.
4. The simulator: the 100-run batch (seed 7) and the 800-run check (seeds 11 and 23), goals random, favorGood, favorEvil, maximizeGold, 20 runs per profession in the 100-run batch (`SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=.. SIM_SEED=.. SIM_OUT=.. flutter test test/sim_playthroughs_test.dart`); `sim_coverage_test` at 300 runs, seed 7. Record: attempt win (100 and 800), level and gold at the end, per class, per chapter, per boss, endings reached (100 of 100 expected), scenes unreachable (0), unvisited scenes against the 13 of 1.285.0.
5. The clan-power batch for comparison: `CLAN_POWER_OUT=/tmp/cp flutter test test/qa_clan_power_50_test.dart` and `tool/clan_power_report.py` (compare with `clan-power-50-v1.464.md`): falls, the patron's curve, quest power now above 0%.
6. The cross-reference audit of the gamedata: `qa_data_refs_test`, `qa_strings_test`, `qa_story_fr_test` (all in the suite). **They do not read the 7 new tables** (no mention of `city_plans`, `detour_scenes`, `detours`, `expedition_steps`, `spec_variants`, `specialisations` or `training_paths` in them; the owners' tests do read some). So the audit needs a pass over these: every id referenced exists (enemies, items, skills, places, clans, quests), every text has its French, no `{placeholder}` left unresolved (`text_placeholders.dart`), no empty names. Add the checks to `qa_data_refs_test` if any gap shows.
7. Old saves: the two fixtures through the chain to 6, round-trip, nothing granted twice; a save of version 5 with a rescaled-looking hero is not rescaled twice.

## 4. Screens to read at 360 and 320 px, English and French, real fonts

New widgets, grouped by where they show:

- **Fight:** `fight_figure`, `fight_sprites`, `fight_markers`, `choice_card` and `choice_rings` (the fight's chips and the blow coming on the health bar), `mercy_dialog`, the fight tutorial.
- **Journey and map:** `journey_banner_pin` (banners and legend), `journey_glyph`, `level_signpost`, `detour_scene_band`, `city_chart_screen` and `widgets/city_chart/*` (the city plans, zoom, fog, districts), `heard_of_travel`, the place sheet.
- **Story:** `side_view/*` (the side-view scenes: desert, ruins, sea, gear, ship), `ability_roll_dialog` and `d20_roll` (a check's d20 on screen), `reward_card` and `reward_cards` (quest complete, item found, a clan's gift), `feature_unlock` (the feature ladder's unlock moment), `quest_autopilot`, the story text display (v1.470).
- **Camp:** `camp_build_tray`, `camp_works_list`, `arrival_sheet`, `return_notice` ("You came back to ..."), `training_picker`.
- **Character:** `stat_pick_picker` (the level's picks), `clan_compass`, `clan_compass_card`, `clan_radar_chart`, `clan_power_block`, `clan_peek`, `item_detail_view`, `title_detail_view`, `face_skill_sheet`, the stat popin (v1.469).
- Already guarded by a `qa_` test (re-run, then read what they cannot see): `qa_full_map`, `qa_harbour_crossing`, `qa_real_font_cards`, `qa_ch7_hub_layout` (changed by UX in v1.465: read in L3), `qa_anomaly_chip_en` and `_fr`.

For each: no overflow, no clipped button, no missing French, the back path (Back and the system gesture), the empty and the full state, reduced motion. A screenshot sweep (the way `qa_real_font_cards_test` does) for the new ones is the cheapest read; keep the PNGs out of the repo.

## 5. Carried over, to watch

- The warrior's gap to the cleric (30% against 62% at 1.285.0; the difficulty review of v1.429 aimed at about 70% for every profession).
- A failed crossing carries a spent party back at half health (a free rest), pinned in `qa_harbour_crossing_test`.
- Unseeded rolls: `qa_seeded_rolls_test` guards the tests; `story_player_screen` takes `storyCheckRandomProvider` and `SkillChallengeScreen` a `random` since v1.466. The guard could be extended to see those two overrides (optional, Core's note).
- The simulator plays no seat crisis, no companions, no detour choices (`docs/simulation/sim-gaps.md`): a finding on a sim figure is checked against that list first.

## 6. Output

`docs/qa/l3-1.471.0.md` (report in the shape of `l3-1.285.0.md`: result table, simulator comparison, coverage, audit, screens read, guards added, findings, open items) and, at the top of `docs/qa/README.md`, "Last L3: 1.471.0" with its row in the table. Docs and tests only: no version bump.
