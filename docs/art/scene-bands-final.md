# Story scene bands: the one final file per location (74 DAG locations)

All 240x100, 32-colour PNG8 (`art/pixellab-backgrounds/` and `art/pixellab-scenes/`), keyed by the DAG `location` id (`assets/Cleaned_Narrative_DAG.json`); sorted by node count. Nothing is under `assets/` yet: UX-2 copies each file to `assets/visuals/scenes/<location>.png` (or any name it prefers; the file stem is the location id except for the `_s<seed>` suffix to drop). Where a place has a redo, the redo replaces the batch file.

**The eight flagged redos: all done** (hollow_shore, saltmouth_landward_gate, hollow_shore_battlefield, saltmouth_lantern_alleys, spire_cathedral, the_crossing, white_anchorage_stern, rimewell_chapel), plus lark_wreck and highhearth (stage mismatches fixed). **Still weak:** none flagged after the redos; the only caveat is `hollow_shore`, which the user had left without a scene (the redo exists). Fixed stage pairing for fights is in `docs/art/pairing-stage-scenes.md` (fights use `fight_*` plates, not these bands).

| location | nodes | final file | made in | status |
|---|---|---|---|---|
| cove_camp | 39 | `art/pixellab-scenes/final/cove_camp.png` | first six | ok |
| reliquary_quarter | 26 | `art/pixellab-backgrounds/batchA/staged/reliquary_quarter_s3.png` | batchA | ok |
| greyhithe | 25 | `art/pixellab-backgrounds/batchA/staged/greyhithe_s3.png` | batchA | ok |
| saltmouth_wharf | 22 | `art/pixellab-scenes/final/saltmouth_wharf.png` | first six | ok |
| wracks_end | 21 | `art/pixellab-backgrounds/batchA/staged/wracks_end_s3.png` | batchA | ok |
| rimewell | 18 | `art/pixellab-backgrounds/batchA/staged/rimewell_s3.png` | batchA | ok |
| hollow_shore | 15 | `art/pixellab-backgrounds/redos/staged/hollow_shore_s7.png` | redo | redone (final); the user had left this place without a scene: wire it only if wanted |
| ashen_quarter_ash_market | 13 | `art/pixellab-backgrounds/batchA/staged/ashen_quarter_ash_market_s3.png` | batchA | ok |
| saltmouth_landward_gate | 13 | `art/pixellab-backgrounds/redos/staged/saltmouth_landward_gate_s7.png` | redo | redone (final) (flagged) |
| white_anchorage_quay | 11 | `art/pixellab-backgrounds/batchA/staged/white_anchorage_quay_s3.png` | batchA | ok |
| candlehold_gates | 10 | `art/pixellab-backgrounds/batchA/staged/candlehold_gates_s3.png` | batchA | ok |
| drowned_cloister_stair | 10 | `art/pixellab-backgrounds/batchA/staged/drowned_cloister_stair_s3.png` | batchA | ok |
| saltmouth_card_row | 10 | `art/pixellab-backgrounds/batchA/staged/saltmouth_card_row_s3.png` | batchA | ok |
| candlehold_throne_room | 9 | `art/pixellab-scenes/final/candlehold_throne_room.png` | first six | ok |
| drowned_cloister_ossuary | 9 | `art/pixellab-backgrounds/batchB/staged/drowned_cloister_ossuary_s3.png` | batchB | ok |
| highhearth | 9 | `art/pixellab-backgrounds/redos/staged/highhearth_s7.png` | redo | redone (final) |
| saltmouth_tern_row | 9 | `art/pixellab-backgrounds/batchA/staged/saltmouth_tern_row_s3.png` | batchA | ok |
| saltmouth_yard | 9 | `art/pixellab-backgrounds/batchB/staged/saltmouth_yard_s3.png` | batchB | ok |
| akagiri | 8 | `art/pixellab-backgrounds/batchB/staged/akagiri_s3.png` | batchB | ok |
| alster_high_quay | 8 | `art/pixellab-backgrounds/batchB/staged/alster_high_quay_s3.png` | batchB | ok |
| ashen_quarter_wall_of_names | 8 | `art/pixellab-backgrounds/batchB/staged/ashen_quarter_wall_of_names_s3.png` | batchB | ok |
| blind_beggar | 8 | `art/pixellab-backgrounds/batchB/staged/blind_beggar_s3.png` | batchB | ok |
| drowned_cloister_nave_hall | 8 | `art/pixellab-backgrounds/batchB/staged/drowned_cloister_nave_hall_s3.png` | batchB | ok |
| emberwick | 8 | `art/pixellab-backgrounds/batchB/staged/emberwick_s3.png` | batchB | ok |
| kindly_hill_long_room | 7 | `art/pixellab-backgrounds/batchB/staged/kindly_hill_long_room_s3.png` | batchB | ok |
| alster_family_house | 6 | `art/pixellab-backgrounds/batchB/staged/alster_family_house_s3.png` | batchB | ok |
| black_hold_cells | 6 | `art/pixellab-scenes/final/black_hold_cells.png` | first six | ok |
| kindly_hill | 6 | `art/pixellab-backgrounds/batchB/staged/kindly_hill_s3.png` | batchB | ok |
| reliquary_chair_chapel | 6 | `art/pixellab-backgrounds/batchB/staged/reliquary_chair_chapel_s3.png` | batchB | ok |
| spire_cathedral | 6 | `art/pixellab-backgrounds/redos/staged/spire_cathedral_s7.png` | redo | redone (final) (flagged) |
| white_anchorage_hulls | 6 | `art/pixellab-backgrounds/batchB/staged/white_anchorage_hulls_s3.png` | batchB | ok |
| white_wells | 6 | `art/pixellab-backgrounds/batchB/staged/white_wells_s3.png` | batchB | ok |
| ashen_quarter_archive | 5 | `art/pixellab-backgrounds/batchB/staged/ashen_quarter_archive_s3.png` | batchB | ok |
| hollow_court_chamber | 5 | `art/pixellab-backgrounds/batchB/staged/hollow_court_chamber_s3.png` | batchB | ok |
| hollow_shore_battlefield | 5 | `art/pixellab-backgrounds/redos/staged/hollow_shore_battlefield_s9.png` | redo | redone, second retry s9 (the first redo s7 had a standing figure); final |
| reliquary_chartkeeper_chapel | 5 | `art/pixellab-backgrounds/batchB/staged/reliquary_chartkeeper_chapel_s3.png` | batchB | ok |
| sleepers_face | 5 | `art/pixellab-backgrounds/batchB/staged/sleepers_face_s3.png` | batchB | ok |
| alster_undercroft | 4 | `art/pixellab-backgrounds/batchB/staged/alster_undercroft_s3.png` | batchB | ok |
| ashen_quarter_spire_stair | 4 | `art/pixellab-backgrounds/batchB/staged/ashen_quarter_spire_stair_s3.png` | batchB | ok |
| highhearth_great_hearth | 4 | `art/pixellab-backgrounds/batchB/staged/highhearth_great_hearth_s3.png` | batchB | ok |
| hollow_court | 4 | `art/pixellab-backgrounds/batchB/staged/hollow_court_s3.png` | batchB | ok |
| lark_wreck | 4 | `art/pixellab-backgrounds/redos/staged/lark_wreck_s7.png` | redo | redone (final) |
| saltmouth_lantern_alleys | 4 | `art/pixellab-backgrounds/redos/staged/saltmouth_lantern_alleys_s7.png` | redo | redone (final) (flagged) |
| white_anchorage_chapel | 4 | `art/pixellab-backgrounds/batchB/staged/white_anchorage_chapel_s3.png` | batchB | ok |
| alster_lower_town | 3 | `art/pixellab-scenes/final/alster_lower_town.png` | first six | ok |
| ashen_quarter_gate | 3 | `art/pixellab-backgrounds/batchB/staged/ashen_quarter_gate_s3.png` | batchB | ok |
| dead_heart | 3 | `art/pixellab-backgrounds/batchC/staged/dead_heart_s3.png` | batchC | ok |
| reliquary_hammer_chapel | 3 | `art/pixellab-backgrounds/batchC/staged/reliquary_hammer_chapel_s3.png` | batchC | ok |
| spire_hall_of_records | 3 | `art/pixellab-backgrounds/batchB/staged/spire_hall_of_records_s3.png` | batchB | ok |
| akagiri_tetsu_forge | 2 | `art/pixellab-backgrounds/batchC/staged/akagiri_tetsu_forge_s3.png` | batchC | ok |
| alster_stone_bridge | 2 | `art/pixellab-backgrounds/batchC/staged/alster_stone_bridge_s3.png` | batchC | ok |
| ashen_quarter_cinder_row | 2 | `art/pixellab-backgrounds/batchC/staged/ashen_quarter_cinder_row_s3.png` | batchC | ok |
| drowned_cloister_cache | 2 | `art/pixellab-backgrounds/batchC/staged/drowned_cloister_cache_s3.png` | batchC | ok |
| emberwick_cold_forge | 2 | `art/pixellab-backgrounds/batchC/staged/emberwick_cold_forge_s3.png` | batchC | ok |
| emberwick_widows_house | 2 | `art/pixellab-backgrounds/batchC/staged/emberwick_widows_house_s3.png` | batchC | ok |
| reliquary_muniment_room | 2 | `art/pixellab-backgrounds/batchC/staged/reliquary_muniment_room_s3.png` | batchC | ok |
| rimewell_chapel | 2 | `art/pixellab-backgrounds/redos/staged/rimewell_chapel_s7.png` | redo | redone (final) (flagged) |
| rimewell_road_keepers_house | 2 | `art/pixellab-backgrounds/batchC/staged/rimewell_road_keepers_house_s3.png` | batchC | ok |
| white_anchorage_impound | 2 | `art/pixellab-backgrounds/batchC/staged/white_anchorage_impound_s3.png` | batchC | ok |
| white_anchorage_stern | 2 | `art/pixellab-backgrounds/redos/staged/white_anchorage_stern_s7.png` | redo | redone (final) (flagged) |
| beyond_the_tear | 1 | `art/pixellab-backgrounds/batchC/staged/beyond_the_tear_s3.png` | batchC | ok |
| candlehold_lantern_hall | 1 | `art/pixellab-backgrounds/batchC/staged/candlehold_lantern_hall_s3.png` | batchC | ok |
| cove_sail_loft | 1 | `art/pixellab-backgrounds/batchC/staged/cove_sail_loft_s3.png` | batchC | ok |
| reliquary_parish_chapel | 1 | `art/pixellab-backgrounds/batchC/staged/reliquary_parish_chapel_s3.png` | batchC | ok |
| reliquary_tribunal_chapel | 1 | `art/pixellab-backgrounds/batchC/staged/reliquary_tribunal_chapel_s3.png` | batchC | ok |
| saltmouth_green_door | 1 | `art/pixellab-backgrounds/batchC/staged/saltmouth_green_door_s3.png` | batchC | ok |
| saltmouth_landward_warehouse | 1 | `art/pixellab-backgrounds/batchC/staged/saltmouth_landward_warehouse_s3.png` | batchC | ok |
| saltmouth_tide_cellar | 1 | `art/pixellab-backgrounds/batchC/staged/saltmouth_tide_cellar_s3.png` | batchC | ok |
| spire_of_judgment | 1 | `art/pixellab-backgrounds/batchC/staged/spire_of_judgment_s3.png` | batchC | ok |
| the_crossing | 1 | `art/pixellab-backgrounds/redos/staged/the_crossing_s7.png` | redo | redone (final) (flagged) |
| white_anchorage_chandlery | 1 | `art/pixellab-backgrounds/batchC/staged/white_anchorage_chandlery_s3.png` | batchC | ok |
| white_anchorage_vault | 1 | `art/pixellab-backgrounds/batchC/staged/white_anchorage_vault_s3.png` | batchC | ok |
| white_fleet_grave | 1 | `art/pixellab-backgrounds/batchC/staged/white_fleet_grave_s3.png` | batchC | ok |
| wracks_end_lamp_room | 1 | `art/pixellab-backgrounds/batchC/staged/wracks_end_lamp_room_s3.png` | batchC | ok |
