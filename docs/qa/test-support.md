# The shared test helpers (QA, wave 3a of the cleanup plan)

Four helpers in `test/support/` replace setup that was copied from file to file. No assertion was touched; every changed file passes (155 test files, 834 tests).

| Helper | Replaces | Files |
|---|---|---|
| `loadAppFonts()` (`fonts.dart`) | the private `_loadFonts()` (the bundled fonts and the SDK icon font) | 73 |
| `settleApp(tester)` (`pump.dart`) | the private `_settle`: three rounds of a real 100 ms and a 100 ms frame | 62 |
| `openGame(tester, {overrides, session})` (`open_game.dart`) | pump the app, press Edit Mode, set English, load a save, in-game mode; `noCityPlans` is the no-stored-chart override | 16 |
| `usePhone(tester, size)` (`pump.dart`) | the four lines that set a window size and pixel ratio and reset them | 103 |

`loadSmokeFonts()` in `qa_smoke_harness.dart` now calls `loadAppFonts()`. One behaviour change: tests that loaded the fonts without looking for the SDK icon font now load it when it exists (`FLUTTER_ROOT`), so a test font no longer draws their icons as boxes; no test depended on the boxes.

Not done, because the files are UX's picture mocks and a merge is a design choice: the 85-, 102- and 108-line blocks the `ux_skills_*_mock_test` files share, and the `ux_*_shots_test` setups. Also left: `openGame` with a custom save (`district_walk_test`, `geography_journey_test`, `companion_remark_story_test`) and the settle variants with other timings.

## Files touched

| File | Change |
|---|---|
| `alster_one_place_test.dart` | settle, openGame, usePhone |
| `bounty_board_test.dart` | fonts |
| `camp_flow_test.dart` | usePhone |
| `camp_header_fr_test.dart` | settle, usePhone |
| `chapter_one_fight_flow_test.dart` | settle, usePhone |
| `character_tab_test.dart` | fonts |
| `chart_weather_test.dart` | settle, usePhone |
| `city_chart_all_plans_test.dart` | fonts |
| `clan_compass_test.dart` | fonts |
| `clan_power_block_test.dart` | fonts, usePhone |
| `clash_test.dart` | settle, usePhone |
| `craft_sheet_test.dart` | fonts |
| `dice_loadout_test.dart` | settle, usePhone |
| `dice_sizes_test.dart` | usePhone |
| `dice_smithing_sheet_test.dart` | usePhone |
| `die_slot_ring_test.dart` | settle, usePhone |
| `district_places_view_test.dart` | settle, openGame, usePhone |
| `district_walk_test.dart` | settle, usePhone |
| `doorstep_scenes_test.dart` | settle, openGame, usePhone |
| `epilogue_map_screen_test.dart` | fonts, usePhone |
| `escort_delivery_test.dart` | settle, usePhone |
| `expedition_written_road_test.dart` | settle, usePhone |
| `feature_unlock_test.dart` | fonts, usePhone |
| `fight_back_guard_test.dart` | settle, usePhone |
| `fight_dice_rules_test.dart` | usePhone |
| `fight_echo_silence_test.dart` | usePhone |
| `fight_entrance_test.dart` | settle, usePhone |
| `fight_goals_test.dart` | settle, usePhone |
| `fight_ground_test.dart` | usePhone |
| `fight_guard_test.dart` | usePhone |
| `fight_hero_harness.dart` | fonts, usePhone |
| `fight_lab_companion_test.dart` | usePhone |
| `fight_lab_parts_test.dart` | settle |
| `fight_lab_test.dart` | usePhone |
| `fight_markers_harness.dart` | usePhone |
| `fight_mirror_spell_test.dart` | usePhone |
| `fight_opening_round_test.dart` | usePhone |
| `fight_pack_echo_test.dart` | usePhone |
| `fight_tips_test.dart` | settle, usePhone |
| `fight_victory_auto_close_test.dart` | settle, usePhone |
| `fight_windup_test.dart` | usePhone |
| `first_journey_test.dart` | usePhone |
| `forge_sheet_view_test.dart` | usePhone |
| `geography_journey_test.dart` | usePhone |
| `host_fight_test.dart` | usePhone |
| `intro_screen_test.dart` | usePhone |
| `item_detail_view_test.dart` | fonts |
| `journey_banner_pin_district_test.dart` | settle, openGame, usePhone |
| `journey_banner_pin_test.dart` | settle, usePhone |
| `journey_choice_cards_test.dart` | fonts, settle, usePhone |
| `journey_city_view_test.dart` | settle, openGame, usePhone |
| `journey_detour_scene_test.dart` | fonts, settle, openGame, usePhone |
| `journey_idle_test.dart` | settle, usePhone |
| `journey_inside_test.dart` | settle, openGame, usePhone |
| `journey_levels_test.dart` | settle, usePhone |
| `journey_motion_still_test.dart` | settle, usePhone |
| `journey_motion_test.dart` | settle, usePhone |
| `journey_moves_test.dart` | usePhone |
| `journey_new_rooms_test.dart` | settle, openGame, usePhone |
| `journey_no_pop_in_test.dart` | settle, openGame, usePhone |
| `journey_places_list_test.dart` | settle, openGame, usePhone |
| `journey_read_through_test.dart` | settle, usePhone |
| `journey_scene_choices_test.dart` | settle, usePhone |
| `journey_scene_sheet_test.dart` | settle, usePhone |
| `journey_selection_still_test.dart` | settle, openGame, usePhone |
| `journey_step_taps_test.dart` | settle, usePhone |
| `journey_tab_test.dart` | settle, usePhone |
| `journey_transit_test.dart` | settle, usePhone |
| `journey_walk_clock_test.dart` | settle, usePhone |
| `level_signpost_test.dart` | fonts, usePhone |
| `main_menu_test.dart` | usePhone |
| `main_quest_lock_test.dart` | settle, usePhone |
| `map_poi_zoom_test.dart` | fonts |
| `mercy_dialog_test.dart` | fonts |
| `new_game_start_test.dart` | usePhone |
| `offer_dialog_test.dart` | fonts |
| `origin_scene_backdrop_test.dart` | fonts |
| `poly_die_test.dart` | fonts, usePhone |
| `qa_ch7_hub_layout_test.dart` | fonts, settle |
| `qa_fight_tips_real_font_test.dart` | fonts |
| `qa_full_map_test.dart` | fonts |
| `qa_real_font_cards_test.dart` | fonts, settle |
| `qa_real_font_layout_test.dart` | fonts |
| `qa_smoke_harness.dart` | harness |
| `qa_story_text_real_font_test.dart` | fonts |
| `quest_tracking_test.dart` | usePhone |
| `quick_hands_test.dart` | settle, usePhone |
| `race_profession_choice_test.dart` | fonts, usePhone |
| `reward_card_test.dart` | fonts |
| `road_fight_test.dart` | settle, usePhone |
| `road_moves_world_view_test.dart` | settle, openGame, usePhone |
| `saltmouth_one_place_test.dart` | settle, openGame, usePhone |
| `scene_flow_play_test.dart` | settle, usePhone |
| `scene_lock_test.dart` | usePhone |
| `sea_beast_hunt_test.dart` | fonts |
| `sea_beast_outrun_test.dart` | fonts |
| `ship_dynamics_panel_test.dart` | fonts |
| `ship_run_feedback_test.dart` | fonts |
| `simulator_insets_test.dart` | fonts |
| `skill_face_limit_test.dart` | settle, usePhone |
| `skill_fight_harness.dart` | usePhone |
| `skill_tree_test.dart` | settle, usePhone |
| `skills_companion_test.dart` | settle |
| `spec_standing_fight_test.dart` | usePhone |
| `specialisations_fight_test.dart` | usePhone |
| `squad_test.dart` | settle, usePhone |
| `star_chart_five_test.dart` | settle, usePhone |
| `star_chart_test.dart` | settle, usePhone |
| `stat_pick_picker_test.dart` | fonts |
| `stat_sheet_test.dart` | fonts, usePhone |
| `stats_bar_day_test.dart` | settle, usePhone |
| `story_text_test.dart` | usePhone |
| `tab_badges_test.dart` | usePhone |
| `throne_room_test.dart` | usePhone |
| `title_detail_view_test.dart` | fonts |
| `town_fold_test.dart` | settle |
| `ux_arrival_shot_test.dart` | fonts, settle, usePhone |
| `ux_character_dice_badge_mock_test.dart` | fonts |
| `ux_character_dice_mock_test.dart` | fonts, usePhone |
| `ux_clan_power_mock_test.dart` | fonts |
| `ux_companion_mock_test.dart` | fonts |
| `ux_dice_built_shots_test.dart` | fonts |
| `ux_dice_mock_test.dart` | fonts |
| `ux_epilogue_map_mock_test.dart` | fonts |
| `ux_fight_fixed_mock_test.dart` | fonts |
| `ux_fight_info_test.dart` | fonts, usePhone |
| `ux_fight_size_shots_test.dart` | fonts |
| `ux_forge_build_shots_test.dart` | fonts, usePhone |
| `ux_forge_mock_test.dart` | fonts |
| `ux_forge_tabs_mock_test.dart` | fonts |
| `ux_inplace_refined_mock_test.dart` | fonts |
| `ux_intro_anim_test.dart` | fonts |
| `ux_intro_build_shots_test.dart` | fonts |
| `ux_intro_d_mock_test.dart` | fonts, usePhone |
| `ux_inventory_build_shots_test.dart` | fonts, usePhone |
| `ux_inventory_dice_mock_test.dart` | fonts, usePhone |
| `ux_inventory_mock_test.dart` | fonts |
| `ux_journey_fix_shots_test.dart` | fonts, settle |
| `ux_journey_pins_mockups_test.dart` | fonts |
| `ux_map_first_mock_test.dart` | fonts, settle, openGame, usePhone |
| `ux_places_build_shots_test.dart` | fonts, settle, usePhone |
| `ux_places_mock_test.dart` | fonts, settle, openGame, usePhone |
| `ux_power_ways_mock_test.dart` | fonts |
| `ux_race_mock_test.dart` | fonts |
| `ux_skills_combined_mock_test.dart` | fonts |
| `ux_skills_ideas_mock_test.dart` | fonts |
| `ux_skills_mock_test.dart` | fonts |
| `ux_skills_styles_mock_test.dart` | fonts |
| `ux_star_chart_shots_test.dart` | fonts |
| `ux_story_room_test.dart` | fonts |
| `ux_sweep_test.dart` | fonts |
| `ux_town_shot_test.dart` | fonts, settle, usePhone |
| `ux_tutorial_ideas_mock_test.dart` | fonts |
| `ux_vica_follow_mock_test.dart` | fonts |
| `weather_chip_narrow_test.dart` | settle, openGame, usePhone |
| `world_map_edit_test.dart` | usePhone |
| `world_map_test.dart` | usePhone |
| `world_road_play_test.dart` | usePhone |
| `zone_cleared_card_test.dart` | fonts |
