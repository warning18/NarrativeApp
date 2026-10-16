# Town buildings (v1.426, Core): the buildings for Narrative to name

Core added the districts of `docs/proposals/town-districts.json` to `geography.json` and laid out the plans (`assets/gamedata/city_plans.json`, `dart run tool/city_plans/gen_city_plans.dart`). These are the buildings that host a scene: its id, its district, its kind on the plan, and the scenes whose pin stands on it. A follow-up (a scene ending in an outcome word: `_failed`, `_found`, `_after`, ...) stands at the building of the scene it follows.

Names go into `city_plans.json` under the place's `names` (`"<building id>": {"en": ..., "fr": ...}`), as for Saltmouth; a re-run of the generator keeps them. Until the story's scenes are retagged to their districts, the generator seats them from `tool/city_plans/district_seats.json` (Narrative's proposal, by each scene's present `location`); after the retag the story's `location` wins and the buildings stay the same as long as the scenes stay in the same districts and order.

The Black Reliquary was regenerated on its five districts, so its building ids changed (no names were written for it yet). Candlehold was regenerated on its three: the Gates kept every building and id, and `7510_seen` and `7515_rest` share `candlehold_b003` in the Gates.

## Rimewell (`rimewell`)

Plan: village, inland, no river, open, lotKeep 0.8 (radius 220, lots 42). 42 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `rimewell_b000` | The Bell Square (`rimewell_bell_square`) | hall | `6100_clan_penitents_2` |
| `rimewell_b001` | The Bell Square (`rimewell_bell_square`) | temple | `6100` |
| `rimewell_b004` | The Bell Square (`rimewell_bell_square`) | house | `6100_clan_penitents_2_broken` |
| `rimewell_b005` | The Bell Square (`rimewell_bell_square`) | stall | `6100_clan_penitents_2_heard` |
| `rimewell_b010` | The Bell Square (`rimewell_bell_square`) | house | `6100_bell`, `6100_bell_failed` |
| `rimewell_b011` | The Pilgrims’ Road (`rimewell_pilgrims_road`) | hall | `6100_clan_mire_2_fourth` |
| `rimewell_b012` | The Pilgrims’ Road (`rimewell_pilgrims_road`) | temple | `6100_clan_mire_2`, `6100_clan_mire_2_found` |
| `rimewell_b013` | The Pilgrims’ Road (`rimewell_pilgrims_road`) | house | `6100_debt_rising` |
| `rimewell_b015` | The Pilgrims’ Road (`rimewell_pilgrims_road`) | house | `6100_road` |
| `rimewell_b017` | The Pilgrims’ Road (`rimewell_pilgrims_road`) | house | `6100_bread` |
| `rimewell_b019` | The Pilgrims’ Road (`rimewell_pilgrims_road`) | house | `6100_knife` |
| `rimewell_b021` | The Pilgrims’ Road (`rimewell_pilgrims_road`) | house | `6100_charter_signing` |
| `rimewell_b022` | The Ridge Post (`rimewell_ridge_post`) | hall | `6100_keeper` |
| `rimewell_b023` | The Ridge Post (`rimewell_ridge_post`) | temple | `6100_clan_vigil_2`, `6100_clan_vigil_2_after` |
| `rimewell_b026` | The Ridge Post (`rimewell_ridge_post`) | house | `6100_keeper_later` |
| `rimewell_b030` | The Ridge Post (`rimewell_ridge_post`) | house | `6100_stitcher_door` |
| `rimewell_b032` | The Choir Well (`rimewell_choir_well`) | temple | `6100_house_scorched_choir`, `6100_house_scorched_choir_failed` |

## Greyhithe (`greyhithe`)

Plan: village, shore (shoreY 700, bay 50), open, the Shingle outside on the beach. 67 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `greyhithe_b000` | The Net-Lofts (`greyhithe_net_lofts`) | hall | `7200_house_spire_fallen` |
| `greyhithe_b001` | The Net-Lofts (`greyhithe_net_lofts`) | temple | `7200_reflection` |
| `greyhithe_b002` | The Net-Lofts (`greyhithe_net_lofts`) | house | `7200_elder` |
| `greyhithe_b014` | The Net-Lofts (`greyhithe_net_lofts`) | house | `7200_stitcher_kin` |
| `greyhithe_b018` | The Net-Lofts (`greyhithe_net_lofts`) | house | `7200_elder_later` |
| `greyhithe_b033` | The Watch Stones (`greyhithe_watch_stones`) | hall | `7200_clan_vigil_3_changed` |
| `greyhithe_b034` | The Watch Stones (`greyhithe_watch_stones`) | temple | `7200_clan_vigil_3` |
| `greyhithe_b039` | The Watch Stones (`greyhithe_watch_stones`) | house | `7200_clan_vigil_3_sworn` |
| `greyhithe_b043` | The Moorings (`greyhithe_moorings`) | hall | `7200_clan_mire_3` |
| `greyhithe_b044` | The Moorings (`greyhithe_moorings`) | temple | `7200_thieves_aboard` |
| `greyhithe_b046` | The Moorings (`greyhithe_moorings`) | house | `7200_followed` |
| `greyhithe_b047` | The Moorings (`greyhithe_moorings`) | house | `7200_fourth_piece` |
| `greyhithe_b048` | The Moorings (`greyhithe_moorings`) | house | `7200_returned` |
| `greyhithe_b049` | The Moorings (`greyhithe_moorings`) | house | `7200_stitcher` |
| `greyhithe_b051` | The Moorings (`greyhithe_moorings`) | warehouse | `7200_courts_children` |
| `greyhithe_b059` | The Shingle (`greyhithe_shingle`) | shed | `7200_ledger` |
| `greyhithe_b061` | The Shingle (`greyhithe_shingle`) | shed | `7200_nets` |
| `greyhithe_b063` | The Shingle (`greyhithe_shingle`) | shed | `7200_tide`, `7200_tide_failed` |
| `greyhithe_b064` | The Shingle (`greyhithe_shingle`) | shed | `7200` |
| `greyhithe_b066` | The Shingle (`greyhithe_shingle`) | shed | `7200_relic` |

## Wrack’s End (`wracks_end`)

Plan: village, shore (shoreY 720, bay 70), open. 62 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `wracks_end_b000` | The Hull-Houses (`wracks_end_hull_houses`) | hall | `5100` |
| `wracks_end_b001` | The Hull-Houses (`wracks_end_hull_houses`) | temple | `5100_house_tar_hands` |
| `wracks_end_b005` | The Hull-Houses (`wracks_end_hull_houses`) | house | `5100_headman_later` |
| `wracks_end_b007` | The Hull-Houses (`wracks_end_hull_houses`) | house | `5100_house_fishbasket_line` |
| `wracks_end_b012` | The Hull-Houses (`wracks_end_hull_houses`) | house | `5100_nets` |
| `wracks_end_b014` | The Hull-Houses (`wracks_end_hull_houses`) | house | `5100_house_fishbasket_line_drawn` |
| `wracks_end_b022` | The Hull-Houses (`wracks_end_hull_houses`) | house | `5100_headman` |
| `wracks_end_b029` | The Hull-Houses (`wracks_end_hull_houses`) | house | `5100_keyholder_cut` |
| `wracks_end_b033` | The Hull-Houses (`wracks_end_hull_houses`) | house | `5100_tar_hand_book` |
| `wracks_end_b036` | The Lamp Path (`wracks_end_lamp_path`) | hall | `5100_clan_dominion_1`, `5100_clan_dominion_1_lit` |
| `wracks_end_b037` | The Lamp Path (`wracks_end_lamp_path`) | temple | `5100_clan_dominion_1_out` |
| `wracks_end_b040` | The Lamp Path (`wracks_end_lamp_path`) | house | `5100_drowned` |
| `wracks_end_b050` | The Quay (`wracks_end_quay`) | hall | `5100_salvage`, `5100_salvage_failed` |
| `wracks_end_b051` | The Quay (`wracks_end_quay`) | temple | `5100_clan_crows_1`, `5100_clan_crows_1_seen`, `5100_clan_crows_1_lost` |
| `wracks_end_b053` | The Quay (`wracks_end_quay`) | house | `5100_anvil_deaf_vote` |
| `wracks_end_b057` | The Quay (`wracks_end_quay`) | house | `5100_vote` |

## The Cove Camp (`cove_camp`)

Plan: village, shore (shoreY 700), walled (the palisade, 3 gates), the Landing outside on the beach (radius 210, lots 46). 49 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `cove_camp_b000` | The Fireside (`cove_camp_fireside`) | hall | `7400_reed` |
| `cove_camp_b001` | The Fireside (`cove_camp_fireside`) | temple | `7400` |
| `cove_camp_b003` | The Fireside (`cove_camp_fireside`) | house | `7400_chain_later` |
| `cove_camp_b006` | The Fireside (`cove_camp_fireside`) | house | `7400_reed_later` |
| `cove_camp_b013` | The Fireside (`cove_camp_fireside`) | house | `7400_herald_later` |
| `cove_camp_b014` | The Fireside (`cove_camp_fireside`) | house | `7400_herald` |
| `cove_camp_b015` | The Fireside (`cove_camp_fireside`) | house | `7400_chain` |
| `cove_camp_b025` | The Palisade (`cove_camp_palisade`) | hall | `6002_siege`, `6002_siege_breach` |
| `cove_camp_b026` | The Palisade (`cove_camp_palisade`) | temple | `6002_siege_2` |
| `cove_camp_b028` | The Palisade (`cove_camp_palisade`) | house | `6002_siege_end` |
| `cove_camp_b031` | The Palisade (`cove_camp_palisade`) | house | `6002_camp` |
| `cove_camp_b032` | The Sail-Loft (`cove_camp_sail_loft`) | hall | `7800_council` |
| `cove_camp_b033` | The Sail-Loft (`cove_camp_sail_loft`) | temple | `7800` |
| `cove_camp_b039` | The Sail-Loft (`cove_camp_sail_loft`) | house | `7800_lines` |
| `cove_camp_b041` | The Landing (`cove_camp_landing`) | shed | `4999_camp` |
| `cove_camp_b042` | The Landing (`cove_camp_landing`) | shed | `3001_camp` |
| `cove_camp_b043` | The Landing (`cove_camp_landing`) | shed | `3001` |
| `cove_camp_b047` | The Landing (`cove_camp_landing`) | shed | `7001` |
| `cove_camp_b048` | The Landing (`cove_camp_landing`) | shed | `7800_nkem_later` |

## The Kindly Hill (`kindly_hill`)

Plan: village, the fen's water as a shore to the south (shoreY 760, bay 40), open. 69 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `kindly_hill_b000` | The Hall Under the Hill (`kindly_hill_hall`) | hall | `5200` |
| `kindly_hill_b001` | The Hall Under the Hill (`kindly_hill_hall`) | temple | `5200_riddles`, `5200_riddles_failed` |
| `kindly_hill_b002` | The Hall Under the Hill (`kindly_hill_hall`) | stall | `5200_sleep` |
| `kindly_hill_b005` | The Hall Under the Hill (`kindly_hill_hall`) | house | `5200_nell` |
| `kindly_hill_b018` | The Hall Under the Hill (`kindly_hill_hall`) | house | `5200_nell_later` |
| `kindly_hill_b037` | The Fen Edge (`kindly_hill_fen_edge`) | hall | `5200_house_barkbleeders_bled` |
| `kindly_hill_b038` | The Fen Edge (`kindly_hill_fen_edge`) | temple | `5200_house_barkbleeders` |
| `kindly_hill_b052` | The Fen Edge (`kindly_hill_fen_edge`) | house | `5200_house_returned` |
| `kindly_hill_b056` | The Fen Edge (`kindly_hill_fen_edge`) | house | `5200_clan_mire_1` |
| `kindly_hill_b057` | The Fen Edge (`kindly_hill_fen_edge`) | house | `5200_barrows` |
| `kindly_hill_b058` | The Fen Edge (`kindly_hill_fen_edge`) | house | `5200_clan_mire_1_edge` |
| `kindly_hill_b061` | The Fen Edge (`kindly_hill_fen_edge`) | house | `5200_clan_mire_1_answered` |

## Highhearth (`highhearth`)

Plan: village, inland, walled, giant lots (radius 250, lots 58). 41 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `highhearth_b000` | The Moot-Hall (`highhearth_moot_hall`) | hall | `6200_clan_compact_2`, `6200_clan_compact_2_refused` |
| `highhearth_b001` | The Moot-Hall (`highhearth_moot_hall`) | temple | `6200` |
| `highhearth_b002` | The Moot-Hall (`highhearth_moot_hall`) | stall | `6200_eldest` |
| `highhearth_b010` | The Moot-Hall (`highhearth_moot_hall`) | house | `6200_eldest_later` |
| `highhearth_b017` | The Moot-Hall (`highhearth_moot_hall`) | stall | `6200_hearth` |
| `highhearth_b018` | The Moot-Hall (`highhearth_moot_hall`) | stall | `6200_ghrem` |
| `highhearth_b019` | The Frost Quarry (`highhearth_quarry`) | hall | `6200_house_quarrymen` |
| `highhearth_b020` | The Frost Quarry (`highhearth_quarry`) | temple | `6200_quarry_face`, `6200_quarry_face_fight` |
| `highhearth_b029` | The Long Houses (`highhearth_long_houses`) | hall | `6200_gate` |
| `highhearth_b030` | The Long Houses (`highhearth_long_houses`) | temple | `6200_birth`, `6200_birth_failed` |

## Emberwick (`emberwick`)

Plan: village, inland, open, lotKeep 0.8. 58 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `emberwick_b000` | The Well Square (`emberwick_well_square`) | hall | `3100_house_cantors` |
| `emberwick_b001` | The Well Square (`emberwick_well_square`) | temple | `3100_tithe` |
| `emberwick_b022` | The Kilns (`emberwick_kilns`) | hall | `3100` |
| `emberwick_b023` | The Kilns (`emberwick_kilns`) | temple | `3100_house_emberwives` |
| `emberwick_b024` | The Kilns (`emberwick_kilns`) | house | `3100_new_moon` |
| `emberwick_b025` | The Kilns (`emberwick_kilns`) | house | `3100_bread` |
| `emberwick_b037` | The Kilns (`emberwick_kilns`) | house | `3100_kiln`, `3100_kiln_failed` |
| `emberwick_b044` | Smithy Lane (`emberwick_smithy_lane`) | hall | `3100_widow` |
| `emberwick_b045` | Smithy Lane (`emberwick_smithy_lane`) | temple | `3100_house_anvil_deaf`, `3100_house_anvil_deaf_failed` |
| `emberwick_b046` | Smithy Lane (`emberwick_smithy_lane`) | house | `3100_widow_later` |

## Akagiri (`akagiri`)

Plan: village, inland, open. 63 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `akagiri_b000` | The Brewhouse (`akagiri_brewhouse`) | hall | `3200_brew`, `3200_brew_failed` |
| `akagiri_b025` | The Springs (`akagiri_springs`) | hall | `3200_house_road_exorcists` |
| `akagiri_b026` | The Springs (`akagiri_springs`) | temple | `3200` |
| `akagiri_b034` | The Springs (`akagiri_springs`) | house | `3200_springs` |
| `akagiri_b036` | The Springs (`akagiri_springs`) | house | `3200_circle` |
| `akagiri_b047` | The Forge Terrace (`akagiri_forge_terrace`) | hall | `3200_smith` |
| `akagiri_b048` | The Forge Terrace (`akagiri_forge_terrace`) | temple | `3200_clan_penitents_1` |
| `akagiri_b052` | The Forge Terrace (`akagiri_forge_terrace`) | house | `3200_blade` |
| `akagiri_b058` | The Forge Terrace (`akagiri_forge_terrace`) | house | `3200_smith_later` |

## The White Wells (`white_wells`)

Plan: village, inland, open, small (radius 200), lotKeep 0.85. 41 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `white_wells_b000` | The Pool (`white_wells_pool`) | hall | `1000` |
| `white_wells_b001` | The Pool (`white_wells_pool`) | temple | `1200` |
| `white_wells_b007` | The Pool (`white_wells_pool`) | house | `1001` |
| `white_wells_b009` | The Pool (`white_wells_pool`) | house | `1002` |
| `white_wells_b028` | The Caravan Ring (`white_wells_caravan_ring`) | temple | `1210` |

## The Black Reliquary (`black_reliquary`)

Plan: town as before: river (riverX 280), walled, no sea, no arena; 5 district seeds. 273 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `black_reliquary_b000` | The Reliquary Quarter (`reliquary_quarter`) | hall | `6010` |
| `black_reliquary_b001` | The Reliquary Quarter (`reliquary_quarter`) | temple | `6010_gate` |
| `black_reliquary_b005` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_house_reliquary` |
| `black_reliquary_b018` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_lysa_mercy` |
| `black_reliquary_b020` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_lysa_sworn` |
| `black_reliquary_b023` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_lysa` |
| `black_reliquary_b024` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_clement_refused` |
| `black_reliquary_b028` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_lysa_sacrifice` |
| `black_reliquary_b030` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_house_reliquary_thieves`, `6010_house_reliquary_thieves_searched` |
| `black_reliquary_b031` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_lysa_ledger` |
| `black_reliquary_b038` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_record` |
| `black_reliquary_b043` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_lysa_rescued` |
| `black_reliquary_b044` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_lysa_later` |
| `black_reliquary_b061` | The Reliquary Quarter (`reliquary_quarter`) | house | `6010_brannoc_later` |
| `black_reliquary_b106` | The Dead Heart (`dead_heart`) | hall | `6003` |
| `black_reliquary_b107` | The Dead Heart (`dead_heart`) | temple | `6004` |
| `black_reliquary_b110` | The Dead Heart (`dead_heart`) | house | `6003b` |
| `black_reliquary_b138` | Last Lantern Street (`reliquary_last_lantern`) | hall | `6010_malrik` |
| `black_reliquary_b139` | Last Lantern Street (`reliquary_last_lantern`) | temple | `6010_lantern` |
| `black_reliquary_b147` | Last Lantern Street (`reliquary_last_lantern`) | house | `6010_lantern_keeper` |
| `black_reliquary_b148` | Last Lantern Street (`reliquary_last_lantern`) | house | `6010_wickwarden` |
| `black_reliquary_b153` | Last Lantern Street (`reliquary_last_lantern`) | house | `6010_orsabet` |
| `black_reliquary_b163` | Last Lantern Street (`reliquary_last_lantern`) | house | `6010_lantern_manifest` |
| `black_reliquary_b167` | Last Lantern Street (`reliquary_last_lantern`) | house | `6010_count_short` |
| `black_reliquary_b196` | The Chapels of the Chair (`reliquary_chapels`) | hall | `6010_clan_dominion_2` |
| `black_reliquary_b197` | The Chapels of the Chair (`reliquary_chapels`) | temple | `6010_clan_compact_3`, `6010_clan_compact_3_seen`, `6010_clan_compact_3_hammer` |
| `black_reliquary_b198` | The Chapels of the Chair (`reliquary_chapels`) | stall | `6010_chart_bought` |
| `black_reliquary_b199` | The Chapels of the Chair (`reliquary_chapels`) | house | `6010_heist_night` |
| `black_reliquary_b200` | The Chapels of the Chair (`reliquary_chapels`) | stall | `6010_thread` |
| `black_reliquary_b201` | The Chapels of the Chair (`reliquary_chapels`) | stall | `6010_confession` |
| `black_reliquary_b206` | The Chapels of the Chair (`reliquary_chapels`) | stall | `6010_lysa_dead` |
| `black_reliquary_b207` | The Chapels of the Chair (`reliquary_chapels`) | stall | `6010_returned_roll` |
| `black_reliquary_b208` | The Chapels of the Chair (`reliquary_chapels`) | house | `6010_penitent` |
| `black_reliquary_b209` | The Chapels of the Chair (`reliquary_chapels`) | stall | `6010_chartkeeper`, `6010_chartkeeper_words` |
| `black_reliquary_b213` | The Chapels of the Chair (`reliquary_chapels`) | house | `6010_masked`, `6010_masked_after` |
| `black_reliquary_b216` | The Chapels of the Chair (`reliquary_chapels`) | house | `6010_confession_later` |
| `black_reliquary_b217` | The Frost Line (`reliquary_frost_line`) | hall | `6010_hounds` |
| `black_reliquary_b218` | The Frost Line (`reliquary_frost_line`) | temple | `6010_spawn` |
| `black_reliquary_b238` | The Frost Line (`reliquary_frost_line`) | house | `6010_candle_walk`, `6010_candle_walk_fight` |
| `black_reliquary_b241` | The Frost Line (`reliquary_frost_line`) | house | `6010_frost`, `6010_frost_failed` |

## Candlehold (`candlehold`)

Plan: town as before: sea (shoreY 820, bay 130), walled, no river, no arena; the Cliff's seed set above the Hall's so the Gates keep their shape and buildings. 294 buildings in all.

| Building | District | Kind | Scenes |
|---|---|---|---|
| `candlehold_b000` | The Gates (`candlehold_gates`) | hall | `7500` |
| `candlehold_b001` | The Gates (`candlehold_gates`) | temple | `7510_dominion` |
| `candlehold_b002` | The Gates (`candlehold_gates`) | house | `7510_mire` |
| `candlehold_b003` | The Gates (`candlehold_gates`) | house | `7510_seen`, `7515_rest` |
| `candlehold_b014` | The Gates (`candlehold_gates`) | house | `7510_crows` |
| `candlehold_b020` | The Gates (`candlehold_gates`) | house | `7510_open_hand` |
| `candlehold_b022` | The Gates (`candlehold_gates`) | house | `7510_penitents` |
| `candlehold_b033` | The Gates (`candlehold_gates`) | house | `7510_compact` |
| `candlehold_b066` | The Gates (`candlehold_gates`) | warehouse | `7510_vigil` |
| `candlehold_b157` | The Lantern Hall (`candlehold_lantern_hall`) | hall | `7520_morrow` |
| `candlehold_b158` | The Lantern Hall (`candlehold_lantern_hall`) | temple | `7520_vane` |
| `candlehold_b162` | The Lantern Hall (`candlehold_lantern_hall`) | house | `7520_tallis` |
| `candlehold_b282` | The Lantern Cliff (`candlehold_lantern_cliff`) | hall | `7590_vigil` |
| `candlehold_b283` | The Lantern Cliff (`candlehold_lantern_cliff`) | temple | `7590_dominion` |
| `candlehold_b284` | The Lantern Cliff (`candlehold_lantern_cliff`) | house | `7590_crows` |
| `candlehold_b285` | The Lantern Cliff (`candlehold_lantern_cliff`) | house | `7590_mire` |
| `candlehold_b287` | The Lantern Cliff (`candlehold_lantern_cliff`) | house | `7590_compact` |
| `candlehold_b290` | The Lantern Cliff (`candlehold_lantern_cliff`) | house | `7590_penitents` |
| `candlehold_b292` | The Lantern Cliff (`candlehold_lantern_cliff`) | house | `7590_open_hand` |
