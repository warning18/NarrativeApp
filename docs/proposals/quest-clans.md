# Quest plates: proposed clans

The proposed display `clan` for each quest of `assets/gamedata/quests.json` that has no `faction` (39 of 51). The plate colour only (`questClanOf`, `lib/data/story_plates.dart`); the rules keep reading `faction`. **These are proposals for Narrative to correct**: v1.977 ships the `clan` field empty, and Narrative fills or confirms it in its own text PR. Empty means the neutral plate.

The 12 quests with a `faction` wear it unless given a `clan`.

| ch. | quest | name | category | proposed clan | why |
|---|---|---|---|---|---|
| 0 | `q_temptation_dark` | A Bargain in Shadow | Side | (neutral) | no clan signal in the data |
| 0 | `q_temptation_light` | A Charge of Light | Side | (neutral) | no clan signal in the data |
| 1 | `q_first_blood` | First Blood | Main | (neutral) | main quest: no clan signal |
| 1 | `q_retrieve_banner` | The Family Heirloom | Main | (neutral) | main quest: no clan signal |
| 2 | `q_ch1_vess_in_the_dark` | Vess in the Dark | Side | (neutral) | no clan signal in the data |
| 2 | `q_ch2_leave_saltmouth` | A Hull to Leave In | Main | (neutral) | main quest: no clan signal |
| 2 | `q_ch2_unpaid_scaffold` | The Unpaid Scaffold | Side | compact | turn-in standing: compact 19, dominion 13 |
| 3 | `q_ch3_alsters_dawn` | Alster’s Dawn | Main | (neutral) | main quest: no clan signal |
| 3 | `q_ch3_ashen_oath` | The Ashen Oath | Main | (neutral) | main quest: no clan signal |
| 3 | `q_ch3_glass_from_the_terraces` | Glass from the Terraces | Side | oni | turn-in standing: oni 25, penitents 13 |
| 3 | `q_ch3_groshs_price` | Grosh’s Price | Side | (neutral) | no clan signal in the data |
| 3 | `q_ch3_inquisition_ledger` | The Inquisition’s Ledger | Main | (neutral) | main quest: no clan signal |
| 3 | `q_ch3_marens_penance` | Sister Maren’s Penance | Side | (neutral) | no clan signal in the data |
| 3 | `q_ch3_reckoning_wall` | The Reckoning Wall | Side | (neutral) | no clan signal in the data |
| 3 | `q_ch3_the_high_wardens_fall` | The High Warden’s Fall | Main | (neutral) | main quest: no clan signal |
| 3 | `q_ch3_void_relic` | The Void Relic | Main | (neutral) | main quest: no clan signal |
| 4 | `q_ch4_bark_tithe` | The Bark Tithe | Side | mire | turn-in standing: mire 23, crows 18 |
| 4 | `q_ch4_ossuary_bounty` | The Ossuary Bounty | Side | (neutral) | no clan signal in the data |
| 4 | `q_ch4_the_second_ledger` | The Second Ledger | Main | (neutral) | main quest: no clan signal |
| 4 | `q_ch4_tobins_vigil` | Brother Tobin’s Vigil | Side | (neutral) | no clan signal in the data |
| 4 | `q_nemesis_compact` | The Last Hammer | Nemesis | compact | the nemesis hunt of this clan (from its id) |
| 4 | `q_nemesis_crows` | A Debt Called In | Nemesis | crows | the nemesis hunt of this clan (from its id) |
| 4 | `q_nemesis_dominion` | The List of Oaths | Nemesis | dominion | the nemesis hunt of this clan (from its id) |
| 4 | `q_nemesis_mire` | The Court's Courtesy | Nemesis | mire | the nemesis hunt of this clan (from its id) |
| 4 | `q_nemesis_penitents` | The Weight Set Down | Nemesis | penitents | the nemesis hunt of this clan (from its id) |
| 4 | `q_nemesis_vigil` | The Hour Unwatched | Nemesis | vigil | the nemesis hunt of this clan (from its id) |
| 5 | `q_ch5_candle_count` | The Candle Count | Side | vigil | turn-in standing: vigil 25, dominion 20, penitents 8 |
| 5 | `q_ch5_hearth_stone` | The Hearth-Stone | Side | giants | turn-in standing: giants 23, compact 12 |
| 5 | `q_ch5_malriks_cut` | Malrik’s Cut | Side | (neutral) | no clan signal in the data |
| 5 | `q_ch5_penitents_confession` | The Penitent’s Confession | Side | penitents | turn-in standing: penitents 25, dominion 5 |
| 5 | `q_ch5_the_dead_heart` | The Dead Heart | Main | (neutral) | main quest: no clan signal |
| 6 | `q_ch6_faces_of_the_fallen` | Faces of the Fallen | Side | (neutral) | no clan signal in the data |
| 6 | `q_ch6_salvage_rights` | Salvage Rights | Side | crows | turn-in standing: crows 25, dominion 18, tidekin 3 |
| 6 | `q_ch6_the_white_fleet` | The White Fleet’s Grave | Main | (neutral) | main quest: no clan signal |
| 7 | `q_ch7_chain_masters_boy` | The Chain-Master’s Boy | Side | crows | turn-in standing: crows 3, dominion 3 (tie: first written) |
| 7 | `q_ch7_heralds_errand` | The Herald’s Errand | Side | dominion | turn-in standing: dominion 7 |
| 7 | `q_ch7_lantern_throne` | The Lantern Throne | Main | (neutral) | main quest: no clan signal |
| 7 | `q_ch7_reed_gate_grievance` | The Reed Gate’s Grievance | Side | dominion | turn-in standing: dominion 6, compact 2 |
| 8 | `q_ch6_beyond_the_tear` | Beyond the Tear | Main | (neutral) | main quest: no clan signal |
