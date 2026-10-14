# Simulation report: every branch and side quest (v1.256.0)

Regenerated on `main` at v1.256.0 (702df94), docs only: nothing in the game was changed. The previous run was v1.229.0.

Question: do the story's branches, side quests and checks all get played, across different playthroughs, and what is never reached? Method: three batches of 100 full playthroughs each (seed 7, professions rotated, race random), every run from the first scene to the end with the real fight model.

- **random**: any open way on.
- **explore**: always the way on taken least so far over the whole batch (`SimStrategy.explore`, shared `SimCoverage`), the dice deciding ability checks.
- **explore, both sides of checks**: as explore, but each ability check is settled by the outcome (pass or fail) seen less often so far, so every check's two scenes are walked.

Run with `SIM_RUNS=100 SIM_SEED=7 SIM_OUT=coverage.json flutter test test/sim_coverage_test.dart`, then `python3 docs/simulation/make_report.py branches coverage.json` (the tables below). The simulator rolls ability checks and a sneak that works skips its fight (since v1.229.0), and plays quests (since v1.230.0).

Compared with v1.229.0: scenes reached by at least one of the 300 runs went from 363 (94%) to **370 (96%)**, ways on from 843 to 855, and the scenes no run reached from 22 to **15**. Seven second-beat and clan scenes are reached now (`3005_dorran_later`, `5010_imeh_later`, `6010_brannoc_later`, `7100_ghrem_later`, `7100_orsabet_later`, `7800_nkem_later`, `7100_clan_dominion_3`). `7002_orders` and `7002_throne` are **still never reached**. The quests, shops and enemies met are the same as before.

## 1. Coverage

The story has **385 scenes** (all reachable on paper: 0 unreachable), **915 ways on**, **39 quests**, 14 shops and 65 enemies.

| batch | runs | scenes | ways on | quests offered | shops opened | enemies met |
|---|---|---|---|---|---|---|
| random | 10 | 275 (71%) | 527 (58%) | 29 | 5 | 40 |
| random | 30 | 319 (83%) | 660 (72%) | 33 | 5 | 42 |
| random | 100 | 354 (92%) | 766 (84%) | 33 | 5 | 42 |
| explore | 10 | 329 (85%) | 659 (72%) | 33 | 5 | 42 |
| explore | 30 | 357 (93%) | 772 (84%) | 34 | 5 | 42 |
| explore | 100 | 368 (96%) | 837 (91%) | 35 | 5 | 42 |
| explore, both sides of checks | 10 | 329 (85%) | 670 (73%) | 31 | 5 | 42 |
| explore, both sides of checks | 30 | 359 (93%) | 783 (86%) | 34 | 5 | 42 |
| explore, both sides of checks | 100 | 368 (96%) | 839 (92%) | 34 | 5 | 42 |

All three batches together (300 runs): **370/385 scenes (96%)** and 855/915 ways on (93%).

Curve of the explore batch (scenes seen after N runs):

| runs | scenes | ways on | quests | enemies |
|---|---|---|---|---|
| 10 | 329 | 659 | 33 | 42 |
| 20 | 347 | 744 | 34 | 42 |
| 30 | 357 | 772 | 34 | 42 |
| 40 | 359 | 788 | 34 | 42 |
| 50 | 363 | 803 | 35 | 42 |
| 60 | 368 | 823 | 35 | 42 |
| 70 | 368 | 829 | 35 | 42 |
| 80 | 368 | 833 | 35 | 42 |
| 90 | 368 | 835 | 35 | 42 |
| 100 | 368 | 837 | 35 | 42 |

In v1.229.0 the explore batch reached 362 scenes and 830 ways on after 100 runs; random 348 and 766.

## 2. What no run reached (15 scenes)

| scene | place | reached only from | what blocks it |
|---|---|---|---|
| 3100_widow_later | emberwick | 3100 | 3100#3: next; needs hub_3100_widow, scaffold_yards_cleared (no run set it) |
| 3200_smith_later | akagiri | 3200 | 3200#3: next; needs hub_3200_smith, exorcists_road_cleared (no run set it) |
| 5010_clan_crows_2 | drowned_cloister | 5010 | 5010#15: next; needs clan_crows_step_1; clan/politics gate {"flags": ["clan_crows_step_1"], "standingAtLeast": {"crows": 6}} |
| 5010_clan_crows_2_failed | drowned_cloister | (only from other unreached scenes: 5010_clan_crows_2) | downstream of the above |
| 5010_clan_crows_2_found | drowned_cloister | (only from other unreached scenes: 5010_clan_crows_2) | downstream of the above |
| 5100_clan_crows_1_lost | wracks_end | 5100_clan_crows_1, 5100_clan_crows_1_seen | 5100_clan_crows_1#2: lose / 5100_clan_crows_1_seen#0: lose |
| 5200_nell_later | kindly_hill | 5200 | 5200#3: next; needs hub_5200_nell, changeling_fen_cleared (no run set it) |
| 6010_clan_compact_3 | reliquary_quarter | 6010 | 6010#20: next; needs clan_compact_step_2; clan/politics gate {"flags": ["clan_compact_step_2"], "standingAtLeast": {"compact": 26}} |
| 6010_clan_compact_3_hammer | reliquary_quarter | (only from other unreached scenes: 6010_clan_compact_3, 6010_clan_compact_3_seen) | downstream of the above |
| 6010_clan_compact_3_seen | reliquary_quarter | (only from other unreached scenes: 6010_clan_compact_3) | downstream of the above |
| 6200_eldest_later | highhearth | 6200 | 6200#3: next; needs hub_6200_eldest, frost_quarry_cleared (no run set it) |
| 7002_orders | hollow_shore | 7002 | 7002#3: next; needs fleet_log_read |
| 7002_throne | hollow_shore | 7002 | 7002#4: next; needs admiralty_vote |
| 7100_clan_crows_3 | white_anchorage | 7100 | 7100#10: next; needs clan_crows_step_2 (no run set it); clan/politics gate {"flags": ["clan_crows_step_2"], "standingAtLeast": {"crows": 26}} |
| 7100_cutter_lost | white_anchorage | 7100 | 7100#7: lose |


Causes, in order of how many scenes they hold:

1. **Clan step 2 and 3 scenes** (`clan_crows_2`, `clan_crows_3`, `clan_compact_3` and their outcome scenes, 7 scenes). Each needs the previous step's flag and a standing in the clan (6, then 26) that the simulated character never reached; step 2 of the Crows was reached in no run, so step 3 is shut behind it. (`7100_clan_dominion_3` is reached now.)
2. **Second beats of a hub that need a zone cleared** (`3100_widow_later`, `3200_smith_later`, `5200_nell_later`, `6200_eldest_later`, 4 scenes). The way in needs the first beat's flag and a zone-cleared flag (`scaffold_yards_cleared`, `exorcists_road_cleared`, `changeling_fen_cleared`, `frost_quarry_cleared`): no run set them, because the expedition bosses were not beaten. The six other `..._later` scenes of v1.229.0 are reached now.
3. **7002_orders and 7002_throne**: their ways in need `fleet_log_read` and `admiralty_vote` (set only at 7100, chapter 6) **and** are hidden by `on_throne` (`7002#3` and `7002#4`). `on_throne` is set by every `7590_*` scene, the end of chapter 7, and all 300 runs have it. `7002` is a place of two chapters: the Hollow Shore of chapter 6 (before the throne) and again in chapter 8 (travel from the camp `7800`, `travelPlaceId`). So the two choices can only be taken in chapter 6, on a visit to 7002 made *after* `7100_log` / `7100_chaplain` set the flags; in chapter 8 they are always hidden. 95 of 300 runs hold `fleet_log_read` and 77 hold `admiralty_vote`, every run visits 7002, and none takes either choice: the simulated walk visits 7002 first and the Anchorage later. A player who does the Anchorage first can reach them; whether the story means them to be seen only in that order is a question for a hand check (and for Narrative: if they are meant for chapter 8, `on_throne` hides them there).
4. **Two defeat branches** (`7100_cutter_lost`, `5100_clan_crows_1_lost`): the fight was won, or not met, in every run that got there.

Every one of them has an incoming way in the data, so none is orphaned; whether the real conditions (clan standing 6 and 26, the four zone-cleared flags, the 7002 flags) can be met has not been checked here and deserves a hand check in the real game.

## 3. Side quests

**35 of 39 quests were offered** by some run. The four others: `q_first_blood` is progressed (not offered) by the choice "Refuse and fight" at 260, so it is a measuring artifact (the walk counts only offers); `q_temptation_dark` and `q_temptation_light` come from the alignment temptation events in code (`alignment_events.dart`), which the story walk does not run; and `q_ch2_smugglers_favor` is not offered by any story choice but is the follow-up of `q_ch2_dockside_debts` (`nextQuestID`), which the thorough player takes in 100% of runs (see `report-quests.md`). The note of v1.229.0 that it "cannot be received" was wrong: it is received, as a follow-up.

The branch batches count a quest as taken when its offering choice is taken; completion, turn-ins and rewards are measured in `report-quests.md`.

## 4. Shops and enemies

Shops opened by a story choice: 5 of 14 (anchorage_chandlery, apothecary_row, arcane_bazaar, last_lantern, ossuary_relics). No story choice opens the other 9 (arcane_academy, black_market_docks, blind_beggar_stall, hammersmith_forge, sharpweave_den, shieldwrights_hall, smugglers_vault, wayfarer_caravan, weaponsmith_forge); the walk does not visit them.

Enemies met: 42 of 65. Not met (23): angel_judicator, angel_sentinel, brine_jack, demon_imp, demon_tormentor, frost_kept_giant, glass_shepherd, grosh_turned, horn_taker, inquisition_legate, kelda_turned, knell_keeper, kraken_arm, kroll_the_branded, liora_turned, malrik_turned, maren_turned, purifier_vell, sable_turned, strand_colossus, teind_rider, tobin_turned, vess_turned. They are the companions turned (`*_turned`), the angel and demon temptation fights, named variants of hunts (`kroll_the_branded`, `horn_taker`...), sea beasts (`kraken_arm`, `strand_colossus`) and the Inquisition legate: they come from systems the walk does not run (hunts, temptations, voyages, betrayal flags), as far as the names suggest; not traced one by one. The same list as in v1.229.0. (`rime_bailiff`, met in the 100-run report, is among the 42.)

## 5. Ability checks and the headline numbers over time

The same 100-run balance plan (random, favorGood, favorEvil, maximizeGold; see `report-100-runs.md`):

| measure | v1.228.0 (no checks, no quests) | v1.229.0 (checks) | v1.256.0 (checks and quests) |
|---|---|---|---|
| attempt win rate | 34% | 31% | 39% |
| encounter win rate | 64% | 61% | 70% |
| chapter 5 attempt win | 18% | 15% | 24% |
| cleric / mage attempt win | 45% / 45% | 39% / 43% | 59% / 48% |
| warrior / rogue / ranger | 25% / 29% / 29% | 25% / 25% / 25% | 27% / 33% / 36% |

**Ability checks still fail about half the time.** In the exploring batch the character rolls 13.6 checks a run and fails 7.0 of them (51%; 13.9 and 7.6, 54%, in v1.229.0). The scores are the starting ones (a d20 plus 0 to 3 against DC 10 to 15): the simulator does not add level-up points or gear to them, so this is a floor, but it says the checks are tuned for characters who invest in the stat.

## 6. Findings

1. The story holds together under every playthrough shape tried: all 300 runs reach chapter 8 and the ending, with no dead end and no broken link, including the failure scenes the checks lead to.
2. 96% of the scenes are reached by at least one of 300 runs (94% in v1.229.0); the remaining 15 are clan steps, zone-gated second beats and the two 7002 scenes, behind conditions the simulated character does not meet. They deserve a hand check in the real game (clan standing 6 and 26, the four zone-cleared flags, the 7002 flags).
3. `7002_orders` and `7002_throne` are reachable only in one order: the Anchorage (`7100_log`, `7100_chaplain`) before the first visit to 7002 in chapter 6; in chapter 8 `on_throne` hides both choices for every player. No simulated run takes that order. Worth a hand check, and a decision by Narrative on whether chapter 8 should show them.
4. Ability checks are hard for a starting character (51% fail); with the character's gold unspent, a stat-point spend on the check stats would be the usual answer, which the simulator does not do.
5. Melee classes remain about 16 points behind casters in fight win rate (31% against 48%, 800 runs; see `report-100-runs.md`).
