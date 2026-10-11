# Simulation report: every branch and side quest (v1.229.0)

Question: do the story's branches, side quests and checks all get played, across different playthroughs, and what is never reached? Method: three batches of 100 full playthroughs each (seed 7, professions rotated, race random), every run from the first scene to the end with the real fight model.

- **random**: any open way on.
- **explore**: always the way on taken least so far over the whole batch (`SimStrategy.explore`, shared `SimCoverage`), the dice deciding ability checks.
- **explore, both sides of checks**: as explore, but each ability check is settled by the outcome (pass or fail) seen less often so far, so every check's two scenes are walked.

Two things changed in the simulator for this: it now rolls **ability checks** (a d20 plus the character's score against the DC, natural 20 passes, natural 1 fails, a skill challenge taking rounds; a failed check with a scene of its own goes there) and a sneak that works skips its fight. Before, it never took a failure branch, so 70 scenes (18% of the story) were never played by any run.

## 1. Coverage

The story has **385 scenes** (all reachable on paper: 0 unreachable), **915 ways on**, **39 quests**, 14 shops and 65 enemies.

| batch | runs | scenes | ways on | quests offered | shops opened | enemies met |
|---|---|---|---|---|---|---|
| random | 10 | 286 (74%) | 550 (60%) | 31 | 3 | 40 |
| random | 30 | 327 (85%) | 693 (76%) | 33 | 5 | 42 |
| random | 100 | 348 (90%) | 766 (84%) | 35 | 5 | 42 |
| explore | 10 | 326 (85%) | 663 (72%) | 34 | 5 | 42 |
| explore | 30 | 357 (93%) | 775 (85%) | 35 | 5 | 42 |
| explore | 100 | 362 (94%) | 830 (91%) | 35 | 5 | 42 |
| explore, both sides of checks | 10 | 323 (84%) | 652 (71%) | 33 | 5 | 41 |
| explore, both sides of checks | 30 | 354 (92%) | 765 (84%) | 33 | 5 | 42 |
| explore, both sides of checks | 100 | 361 (94%) | 831 (91%) | 34 | 5 | 42 |

All three batches together (300 runs): **363/385 scenes (94%)** and 843/915 ways on (92%).

Curve of the explore batch (scenes seen after N runs):

| runs | scenes | ways on | quests | enemies |
|---|---|---|---|---|
| 10 | 326 | 663 | 34 | 42 |
| 20 | 354 | 749 | 35 | 42 |
| 30 | 357 | 775 | 35 | 42 |
| 40 | 359 | 792 | 35 | 42 |
| 50 | 361 | 806 | 35 | 42 |
| 60 | 361 | 812 | 35 | 42 |
| 70 | 361 | 819 | 35 | 42 |
| 80 | 362 | 822 | 35 | 42 |
| 90 | 362 | 828 | 35 | 42 |
| 100 | 362 | 830 | 35 | 42 |

Before the simulator rolled checks the same exploring batch saturated at 308 scenes (80%) and 777 ways on; random reached 299 and 717.

## 2. What no run reached (22 scenes)

| scene | place | reached only from | what blocks it |
|---|---|---|---|
| 7002_orders | hollow_shore | 7002 | 7002#3: next; needs fleet_log_read |
| 7002_throne | hollow_shore | 7002 | 7002#4: next; needs admiralty_vote |
| 5010_imeh_later | drowned_cloister | 5010 | 5010#18: next; clan/politics gate {"anyFlags": ["glass_defended", "glass_burned", "glass_carri |
| 5200_nell_later | kindly_hill | 5200 | 5200#3: next; needs hub_5200_nell, changeling_fen_cleared (no run set it) |
| 7800_nkem_later | cove_camp | 7800 | 7800#3: next; clan/politics gate {"anyFlags": ["salvage_to_crows", "salvage_to_admiralty", "s |
| 3100_widow_later | emberwick | 3100 | 3100#3: next; needs hub_3100_widow, scaffold_yards_cleared (no run set it) |
| 3200_smith_later | akagiri | 3200 | 3200#3: next; needs hub_3200_smith, exorcists_road_cleared (no run set it) |
| 7100_cutter_lost | white_anchorage | 7100 | 7100#7: lose |
| 7100_ghrem_later | white_anchorage | 7100 | 7100#15: next; clan/politics gate {"anyFlags": ["hearth_stone_kept", "hearth_stone_cut", "hear |
| 3005_dorran_later | ashen_quarter | 3005 | 3005#19: next; clan/politics gate {"anyFlags": ["scaffold_paid", "scaffold_skimmed", "scaffold |
| 5010_clan_crows_2 | drowned_cloister | 5010 | 5010#15: next; needs clan_crows_step_1; clan/politics gate {"flags": ["clan_crows_step_1"], "standingAtLeast": {"crows" |
| 6200_eldest_later | highhearth | 6200 | 6200#3: next; needs hub_6200_eldest, frost_quarry_cleared (no run set it) |
| 7100_clan_crows_3 | white_anchorage | 7100 | 7100#10: next; needs clan_crows_step_2 (no run set it); clan/politics gate {"flags": ["clan_crows_step_2"], "standingAtLeast": {"crows" |
| 6010_brannoc_later | reliquary_quarter | 6010 | 6010#23: next; clan/politics gate {"anyFlags": ["bark_returned", "bark_sold", "bark_kept"]} |
| 7100_orsabet_later | white_anchorage | 7100 | 7100#14: next; clan/politics gate {"anyFlags": ["count_to_vigil", "count_sealed", "count_read" |
| 6010_clan_compact_3 | reliquary_quarter | 6010 | 6010#20: next; needs clan_compact_step_2; clan/politics gate {"flags": ["clan_compact_step_2"], "standingAtLeast": {"comp |
| 7100_clan_dominion_3 | white_anchorage | 7100 | 7100#9: next; needs clan_dominion_step_2; clan/politics gate {"flags": ["clan_dominion_step_2"], "standingAtLeast": {"dom |
| 5100_clan_crows_1_lost | wracks_end | 5100_clan_crows_1, 5100_clan_crows_1_seen | 5100_clan_crows_1#2: lose / 5100_clan_crows_1_seen#0: lose |
| 5010_clan_crows_2_found | drowned_cloister | (only from other unreached scenes: 5010_clan_crows_2) | downstream of the above |
| 5010_clan_crows_2_failed | drowned_cloister | (only from other unreached scenes: 5010_clan_crows_2) | downstream of the above |
| 6010_clan_compact_3_seen | reliquary_quarter | (only from other unreached scenes: 6010_clan_compact_3) | downstream of the above |
| 6010_clan_compact_3_hammer | reliquary_quarter | (only from other unreached scenes: 6010_clan_compact_3, 6010_clan_compact_3_seen) | downstream of the above |

Causes, in order of how many scenes they hold:

1. **Second beats of a hub** (`..._later`, 10 scenes: 3005_dorran, 5010_imeh, 6010_brannoc, 7100_ghrem, 7100_orsabet, 7800_nkem, and 5200_nell, 3100_widow, 3200_smith, 6200_eldest, which also need a zone cleared). The way in needs the first beat's flag plus either a clan/politics condition on the choices made, or a zone cleared (`scaffold_yards_cleared`, `exorcists_road_cleared`, `frost_quarry_cleared`, `changeling_fen_cleared`: no run set them, because the expedition bosses were not beaten). Blocked here by the simulated character losing the zone bosses and by visiting a hub once; not verified as reachable in the real game.
2. **Clan step 2 and 3 scenes** (`clan_crows_2`, `clan_crows_3`, `clan_compact_3`, `clan_dominion_3` and their outcome scenes, 8 scenes). Each needs the previous step's flag and a standing in the clan (6, then 26) that the simulated character never reached; step 2 of the Crows was reached in no run, so step 3 is shut behind it.
3. **7002_orders and 7002_throne**: need `fleet_log_read` and `admiralty_vote`, which are set only at 7100 (`7100_log`, `7100_chaplain`); a run that reaches 7002 before 7100 never sees them unless it comes back.
4. **Two defeat branches** (`7100_cutter_lost`, `5100_clan_crows_1_lost`): the fight was won, or not met, in every run that got there.

Every one of them has an incoming way in the data, so none is orphaned; whether the real conditions (clan standing 6 and 26, the four zone-cleared flags, the 7002 flags) can be met has not been checked here and deserves a hand check in the real game.

## 3. Side quests

**35 of 39 quests were offered** by some run. The four others are not offered by a story choice: `q_first_blood` is progressed (not offered) by the choice "Refuse and fight" at 260, so it is a measuring artifact (the walk counts only offers); `q_temptation_dark` and `q_temptation_light` come from the alignment temptation events in code (`alignment_events.dart`), which the story walk does not run; and `q_ch2_smugglers_favor` appears nowhere but quests.json.

`q_ch2_smugglers_favor` is therefore **a quest that cannot be received**: nothing references it. Either wire it or remove it.

The simulator counts a quest as taken when its offering choice is taken; it does not play objectives or turn-ins, so completion and the rewards rescale of 1.226 are not exercised here.

## 4. Shops and enemies

Shops opened by a story choice: 5 of 14 (anchorage_chandlery, apothecary_row, arcane_bazaar, last_lantern, ossuary_relics). No story choice opens the other 9; the walk does not visit them.

Enemies met: 42 of 65. Not met (23): angel_judicator, angel_sentinel, brine_jack, demon_imp, demon_tormentor, frost_kept_giant, glass_shepherd, grosh_turned, horn_taker, inquisition_legate, kelda_turned, knell_keeper, kraken_arm, kroll_the_branded, liora_turned, malrik_turned, maren_turned, purifier_vell, sable_turned, strand_colossus, teind_rider, tobin_turned, vess_turned. They are the companions turned (`*_turned`), the angel and demon temptation fights, named variants of hunts (`kroll_the_branded`, `horn_taker`...), sea beasts (`kraken_arm`, `strand_colossus`) and the Inquisition legate: they come from systems the walk does not run (hunts, temptations, voyages, betrayal flags), as far as the names suggest; not traced one by one.

## 5. What modelling the checks did to the numbers

Same 100-run balance plan as the first report, with the checks rolled (20 runs per goal, five goals now including explore without a shared batch, which plays like random):

| measure | before | now |
|---|---|---|
| attempt win rate | 34% | 31% |
| encounter win rate | 64% | 61% |
| chapter 5 attempt win | 18% | 15% |
| cleric / mage attempt win | 45% / 45% | 39% / 43% |
| warrior / rogue / ranger | 25% / 29% / 29% | 25% / 25% / 25% |

**Ability checks fail more than half the time.** In the exploring batch the character rolls 13.9 checks a run and fails 7.6 of them (54%). The scores are the starting ones (a d20 plus 0 to 3 against DC 10 to 15): the simulator does not add level-up points or gear, so this is a floor, but it says the checks are tuned for characters who invest in the stat.

## 6. Findings

1. The story holds together under every playthrough shape tried: all 300 runs reach chapter 8 and the ending, with no dead end and no broken link, including the failure scenes the checks lead to.
2. 94% of the scenes are reached by at least one of 300 runs; the remaining 22 are second beats and clan steps behind conditions the simulated character does not meet. They deserve a hand check in the real game (clan standing 6 and 26, the four zone-cleared flags, the 7002 flags).
3. `q_ch2_smugglers_favor` is referenced nowhere outside quests.json: no choice and no code offers it. Wire it or remove it.
4. Ability checks are hard for a starting character (55% fail); with the character's gold unspent, a stat-point spend on the check stats would be the usual answer, which the simulator does not do.
5. Melee classes remain 14 to 18 points behind casters in fight win rate (25% against 39% to 43%).
