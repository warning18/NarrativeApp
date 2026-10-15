# 50 playthroughs, read as stories (Narrative audit)

Requested by the user: *"Make it do 50 playthroughs and check the resulting coherence of the full narrative of each (detours encountered, ...)."*
Run on `main` at v1.346.0 (base commit of this branch). **Docs only.** Tags: **[N]** text I fix, **[C]** logic or data of Core's, **[UX]**; **[W11]** feeds the Wave 11 detours proposal (#279).

## 1. What was run, and what could not be seen

### How
- **The 50 runs:** the headless simulator (`simulatePlaythroughs`, the engine behind `test/sim_playthroughs_test.dart`), seed base `20261015` (run *i* plays seed `20261015 * 100003 + i`), 50 runs: strategies cycling over all six (random, favorGood, favorEvil, maximizeGold, explore, completionist), professions cycling over the five, races rotating over the five (`race = (i + i/5) mod 5`), so every combination of strategy and profession appears and every race ten times. Every run reached chapter 8 and a real ending.
- **What the existing JSON export records:** counts only (steps, flags, quests, ...). It **does not record the ordered scenes or the choices**. The public result *does* carry `choicesTaken` (ordered `scene|next|text`), `flagIds` and `questRecords`, so I wrote two scratch tests that call only the public API and are **not committed to `test/`** (kept here as `.txt` so `flutter analyze` ignores them): `tools/narrative_audit_scratch_test.dart.txt` writes the ordered choices; `tools/narrative_roads_scratch_test.dart.txt` replays every transition of every run through the real road rules. The Python scripts that count are in `tools/`.
- **The road replay:** for each transition of each run's real path it applies the game's own rules in the game's own order: spine chapter of the scene it leaves, `detourAllowedBetweenScenes`, `roadEventFor` (hazards included), and then `SubNodeEngine.maybeGenerate` with the flavor from `PlacePools.flavorAt` over `detours.json`, recording each node's kind, the foe or shop it offers, its text and **which pool answered** (place, biome, theme or Dart). A different random draw per transition and per run, so the figures are what the rules *tend* to produce, not what each real session would have met.

### What is missing from the harness (for Core, if a transcript option is built)
The simulator walks the story with a model of the fights, the shops and the quests. It does **not** model, and so this audit cannot see:
1. **Detours.** The walk passes them by (see the comment on `roadHazard` in `playthrough_simulator_screen.dart`). I replayed them (above), but the *text the player saw*, the choice they took in it and what it gave are not in any run.
2. **Familiar faces and alignment hunters** (`recurring_encounters.dart`, `alignment_events.dart`). Not replayed either: they take slots the detour would otherwise have.
3. **Owed detours** (a detour rolled mid-crisis and paid at the next road at rest), **chapter conditions** (they shift road odds) and **weather**.
4. **The camp's own trips** (chapters 4 to 7 travel between the camp and its places through `camp_travel.dart`, and `choicesTaken` holds only the story's choices). The camp chapters' roads are therefore under-counted.
5. **Companions present** (who is in the party at each scene) and **clan standing** over time. So "remarks match what happened" and "standing changes match what happened" could not be checked.
6. **Engine-set flags.** 566 flags were set across the runs; **219 of the 720 flags the story reads were never set** (`origin_*` from character creation, `hub_*_later`, `house_*`, `plot_*`, `clan_*_step_*`, `banner_stood_*`, `*_cleared`, ...). They are set by systems the harness does not play (expeditions, houses, politics). Callbacks that wait on them could not be read, and **63 of the story's 426 nodes were never reached** in 50 runs (list in section 4).

**What I need if you want these read:** a transcript option in the harness that records, in order, per step: the scene, the choice, the flags after it, the party, the standing of each clan, the road event, and for each detour its kind, place, pool level, node text and choice taken (plus familiar faces, hunters and expedition outcomes). That is the *exact* list asked for.

## 2. Summary per run

*Detours (nodes):* detours the replay rolled on this run's path, and the nodes they held. *Dart-fallback:* nodes whose lines came from the built-in Dart pool because no place or biome pool answered. *Repeated lines:* extra copies of a text already seen in the run. *<=2 roads apart:* detours within two transitions of the previous one. *Inside one place:* a detour that fires between two scenes of the same location. *Chapters with none:* of chapters 2, 3, 5, 6, 7, 8 (those with roads at rest), how many held no detour. *Issues:* dart-fallback + repeated lines + close detours + detours inside one place + final-chapter detours; **a rough weight, not a score**.

| Run | Strategy | Race + profession | Chapter reached | Detours (nodes) | Road events | Dart-fallback nodes | Repeated lines | Detours <=2 roads apart | Detours inside one place | Chapters with none* | Issues |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | random | Dwarf Cleric | 8 | 3 (5) | 4 | 2 | 0 | 2 | 2 | 4 | 6 |
| 1 | good | Elf Mage | 8 | 3 (7) | 1 | 2 | 0 | 1 | 2 | 3 | 5 |
| 2 | evil | Human Ranger | 8 | 6 (8) | 2 | 2 | 0 | 0 | 3 | 1 | 6 |
| 3 | gold | Orc Rogue | 8 | 3 (5) | 3 | 1 | 0 | 0 | 3 | 4 | 4 |
| 4 | explore | Voidkin Warrior | 8 | 5 (13) | 3 | 1 | 0 | 3 | 3 | 3 | 7 |
| 5 | completionist | Elf Cleric | 8 | 0 (0) | 2 | 0 | 0 | 0 | 0 | 6 | 0 |
| 6 | random | Human Mage | 8 | 4 (11) | 0 | 3 | 0 | 0 | 2 | 3 | 5 |
| 7 | good | Orc Ranger | 8 | 3 (5) | 1 | 0 | 0 | 0 | 2 | 3 | 2 |
| 8 | evil | Voidkin Rogue | 8 | 2 (2) | 2 | 1 | 0 | 0 | 1 | 4 | 2 |
| 9 | gold | Dwarf Warrior | 8 | 0 (0) | 2 | 0 | 0 | 0 | 0 | 6 | 0 |
| 10 | explore | Human Cleric | 8 | 1 (2) | 2 | 0 | 0 | 0 | 1 | 5 | 1 |
| 11 | completionist | Orc Mage | 8 | 5 (8) | 2 | 4 | 0 | 1 | 3 | 3 | 8 |
| 12 | random | Voidkin Ranger | 8 | 3 (3) | 3 | 0 | 0 | 1 | 3 | 4 | 4 |
| 13 | good | Dwarf Rogue | 8 | 5 (10) | 1 | 2 | 1 | 1 | 4 | 3 | 8 |
| 14 | evil | Elf Warrior | 8 | 3 (6) | 2 | 2 | 0 | 1 | 2 | 3 | 5 |
| 15 | gold | Orc Cleric | 8 | 3 (5) | 1 | 1 | 0 | 1 | 2 | 4 | 4 |
| 16 | explore | Voidkin Mage | 8 | 3 (6) | 0 | 2 | 0 | 0 | 2 | 3 | 4 |
| 17 | completionist | Dwarf Ranger | 8 | 4 (7) | 2 | 1 | 0 | 1 | 3 | 3 | 5 |
| 18 | random | Elf Rogue | 8 | 4 (7) | 1 | 1 | 0 | 0 | 2 | 2 | 3 |
| 19 | good | Human Warrior | 8 | 3 (5) | 4 | 0 | 0 | 1 | 1 | 4 | 2 |
| 20 | evil | Voidkin Cleric | 8 | 4 (7) | 1 | 2 | 1 | 0 | 2 | 4 | 5 |
| 21 | gold | Dwarf Mage | 8 | 2 (3) | 2 | 0 | 0 | 0 | 2 | 4 | 2 |
| 22 | explore | Elf Ranger | 8 | 1 (2) | 2 | 0 | 0 | 0 | 1 | 5 | 1 |
| 23 | completionist | Human Rogue | 8 | 5 (10) | 3 | 2 | 0 | 2 | 4 | 3 | 9 |
| 24 | random | Orc Warrior | 8 | 5 (7) | 2 | 2 | 0 | 1 | 2 | 2 | 5 |
| 25 | good | Dwarf Cleric | 8 | 5 (8) | 1 | 0 | 0 | 0 | 4 | 2 | 5 |
| 26 | evil | Elf Mage | 8 | 6 (14) | 1 | 3 | 3 | 3 | 5 | 4 | 14 |
| 27 | gold | Human Ranger | 8 | 3 (5) | 1 | 1 | 0 | 0 | 2 | 4 | 3 |
| 28 | explore | Orc Rogue | 8 | 5 (8) | 2 | 2 | 0 | 1 | 2 | 2 | 5 |
| 29 | completionist | Voidkin Warrior | 8 | 3 (7) | 2 | 0 | 0 | 0 | 2 | 3 | 3 |
| 30 | random | Elf Cleric | 8 | 6 (12) | 2 | 3 | 0 | 2 | 3 | 2 | 8 |
| 31 | good | Human Mage | 8 | 4 (7) | 2 | 0 | 0 | 1 | 1 | 3 | 2 |
| 32 | evil | Orc Ranger | 8 | 7 (14) | 3 | 0 | 0 | 2 | 7 | 1 | 10 |
| 33 | gold | Voidkin Rogue | 8 | 4 (8) | 2 | 0 | 1 | 0 | 3 | 2 | 4 |
| 34 | explore | Dwarf Warrior | 8 | 3 (5) | 3 | 1 | 0 | 0 | 3 | 3 | 4 |
| 35 | completionist | Human Cleric | 8 | 6 (14) | 1 | 0 | 0 | 2 | 3 | 2 | 6 |
| 36 | random | Orc Mage | 8 | 5 (11) | 2 | 1 | 0 | 1 | 3 | 2 | 6 |
| 37 | good | Voidkin Ranger | 8 | 2 (8) | 2 | 3 | 0 | 0 | 1 | 4 | 4 |
| 38 | evil | Dwarf Rogue | 8 | 6 (16) | 2 | 3 | 1 | 0 | 4 | 2 | 8 |
| 39 | gold | Elf Warrior | 8 | 6 (13) | 0 | 3 | 1 | 1 | 2 | 2 | 7 |
| 40 | explore | Orc Cleric | 8 | 4 (11) | 1 | 2 | 0 | 0 | 2 | 2 | 4 |
| 41 | completionist | Voidkin Mage | 8 | 9 (19) | 1 | 1 | 3 | 4 | 7 | 1 | 16 |
| 42 | random | Dwarf Ranger | 8 | 3 (5) | 3 | 0 | 0 | 0 | 1 | 3 | 1 |
| 43 | good | Elf Rogue | 8 | 4 (9) | 2 | 1 | 1 | 1 | 3 | 4 | 6 |
| 44 | evil | Human Warrior | 8 | 6 (14) | 2 | 0 | 0 | 2 | 3 | 3 | 5 |
| 45 | gold | Voidkin Cleric | 8 | 1 (1) | 2 | 1 | 0 | 0 | 1 | 5 | 2 |
| 46 | explore | Dwarf Mage | 8 | 3 (6) | 2 | 1 | 0 | 0 | 2 | 3 | 3 |
| 47 | completionist | Elf Ranger | 8 | 0 (0) | 1 | 0 | 0 | 0 | 0 | 6 | 0 |
| 48 | random | Human Rogue | 8 | 5 (9) | 4 | 0 | 0 | 1 | 5 | 2 | 7 |
| 49 | good | Orc Warrior | 8 | 2 (9) | 2 | 2 | 0 | 1 | 1 | 5 | 4 |

**Across the 50 runs:** 188 detours (3.8 a run, 0 to 9) holding 377 nodes (kinds: fight 83, shop 78, generic 73, rest 52, treasure 49, quest 42); 94 road events (champions 36, shrines 25, caravans 24, hazards 9). Every run reached chapter 8.

## 3. The issues, ranked by how often they occur

Counts are across the 50 runs (seed base `20261015`, example run numbers are from the table). **Who fixes each is in brackets.**

### 3.1 Detours and road events (all **[W11]**)

| # | Issue | How often | Who |
|---|---|---|---|
| D1 | **A detour fires between two scenes of the same place.** 122 of 188 detours (65%) happen on a choice that leads to another scene of the same location: the camp hub's errand picks (`7400` to `7400_herald`, `_chain`, `_reed` and their `_later` echoes: **46 detours in chapter 7 alone**), `3001`, `6002_camp`, `7800`. A "detour" there is not off the road; it interrupts the choice of an errand. | 122 / 188; run 24, 41, 32 | **[C]** a rule (no roll when the two scenes share a location, or move it to the hub's exit), decided with the user |
| D2 | **Chapter 4 never holds a detour or a road event.** All 250 chapter-4 transitions on the spine (5 per run) are blocked: they leave a `noDetour` scene or run between two tense scenes. Also blocked: chapter 7 (250 of 362), chapter 8 (282 of 311), chapter 3 (176 of 250), chapter 5 (100 of 250), chapter 2 (107 of 241). Road events: none in chapters 4, 7 and 8. | ch 4: 50/50 runs, 0 detours | **[C][N]** `noDetour` and moods are on the DAG (mine), the rule is Core's: decide per chapter which beats may hold one (see D8) |
| D3 | **The camp's pool answers half of everything.** `cove_camp` leaves 186 of the 377 nodes (49%). Its pool has 2 lines per kind, so the same 6 lines come back **14 to 20 times in 50 runs** ("a survivor has set up a bench by the palisade gate" 20, "the watch-bell is struck once" 19, "the sail-loft's door is open" 18, ...). 12 extra copies within single runs. | 186 / 377; runs 4, 39 | **[N]** grow the camp's pool (6+ lines a kind, by chapter); **[C]** the place a detour is set at should be the road's, not the camp's |
| D4 | **Dry spells and clusters.** 21 to 26 runs out of 50 hold no detour in a given chapter (chapters 2, 3, 5, 6, 7), and 41 hold none in chapter 8. The longest stretch of roads at rest without one is on average 4.9 (11 at most); yet **38 detours** come within two roads of the previous one. | every chapter | **[C]** the pacing in section 5 of #279 (pity timer, cooldown) |
| D5 | **Fights ignore the place.** The fight node's text is the drawn foe's own encounter line ("An Inquisition warden is checking faces..." at the Cove camp in chapter 5; a Hollow Reflection's lair in chapter 8). The place's `enemy` lines are used only when the foe has no line. 59 of the 83 fight nodes (71%) drew the **Dart** fallback for their flavor: every `enemy` line in `detours.json` is tagged `tense`, so calm scenes (most of them) fall through. | 83 fight nodes | **[N]** retag part of the enemy lines as calm; **[C]** choose foes by place and biome; both feed the scene design |
| D6 | **The same four shops, anywhere.** 78 shop nodes offered `shieldwrights_hall` (25), `weaponsmith_forge` (22), `arcane_bazaar` (18) and `apothecary_row` (13), whatever the place: at White Fleet Grave, the Hollow Shore and the Spire alike. | 78 / 78 | **[C]** shops for detours by place; **[N]** the line must name who sells |
| D7 | **Treasure in a city draws sea-cliff or desert text.** Saltmouth's six districts have no `treasure` lines, so 9 treasure nodes there drew the arid-coast biome's ("a crust of salt on the rocks, cracked open, shows the glint of a ring" while on the sewers' scene). The same gap exists wherever a place pool lacks a kind. | 9 / 9 in Saltmouth | **[N]** add `treasure` (and the other missing kinds) to every place pool |
| D8 | **Final-act detours.** Chapter 8 (the crowning's aftermath) held 9 detours (21 nodes) in 50 runs: a quiet-shore line, a hunter's lair (the hunt for Sabine the Branded Twice) and the like, between the mustering and the battle. | 9 detours; run 13, 35 | **[N]** `noDetour` on the chapter-8 beats (DAG: mine) **or [C]** a chapter rule; the user decides |
| D9 | **Pool levels.** Of 377 nodes: place pools 195 (52%), biome pools 123 (33%), the Dart pool 59 (16%, all of them fights). Chapters 3 and 4 have **no place pool at all**; chapter 5 is mostly biome-level. | see above | **[N]** the Wave 11 pools |
| D10 | **Road events cluster in chapter 5** (50 of 94; chapter 2: 8, chapter 3: 19, chapter 6: 17), none in 4, 7 and 8 (see D2). Hazards are 9 of 94. | 94 events | **[C]** with D2 |

### 3.2 Story: continuity, beats, flags

| # | Issue | How often | Who |
|---|---|---|---|
| S1 | **Chapter 2's fourth beat is optional.** `chapter_spine.dart` lists `{2030, 2040, 2070}` as a beat every run passes, but **26 of 50 runs** go from the yards' arrival to `2900` by another way (`2050` then `2010_crane`, `2010_liora`, the skiff) and never see the tunnel, the insult or the cordon. The story reads fine without it; the spine over-claims. | 26 / 50; runs 0, 2, 3, 4 | **[C]** `chapter_spine.dart` (a beat that is a branch, not a spine) |
| S2 | **Repeated visits to the Saltmouth hub.** Scene `2015` is entered 6 or more times in a single run by 27 of 50 runs, and `7400` (the camp, chapter 7) by 12: the same opening description comes back each time. | 27 + 12 / 50 | **[N]** shorter return text for hub scenes (a "back at the hub" line) |
| S3 | **63 of 426 nodes were never reached** (section 4). 10 are `*_later` echoes and 18 are `*_clan_*` steps; they wait on engine state the harness does not produce. | 63 / 426 | **[C]** confirm reachability with a transcript; I read them in the DAG and they are well formed |
| S4 | **A flag is set and never read:** `open_hand_6` (added, no text or gate uses it). | 1 | **[N]** use it or drop it |
| S5 | **Quests left open at the end:** 34 runs ended with `q_ch6_beyond_the_tear` open, 33 with `q_ch6_the_white_fleet`, 24 with `q_ch5_hearth_stone`, 15 `q_ch6_salvage_rights`, 13 `q_ch7_chain_masters_boy`. Their objectives are kills or flags the harness cannot do. They are the simulator's limit, not a story defect, but cannot be proven from here. | 875 accepted, 664 completed | **[C]** a transcript |
| S6 | **No other continuity break found in what could be read.** The chapter openings and closings read as one story (2900 to 3001, 3002 to 4999, 4999_camp to 5003, 6004 to 7001, 7300 to 7400, 7500 to 7800 to 7810 to 7002_confront); first mentions of named characters follow the node that introduces them once each callback's `andFlags` are honoured (my first pass ignored them and found false breaks, for example Maud Tallis at the finale, which are gated); the 18 scenes with a single bare way on are all set pieces (the endings, the sail-for-the-next-place beats, the fights). | all 50 | — |
| S7 | **One cold name.** `6100_knife` (the frozen pilgrim at Rimewell) names *Maud Tallis* for the first time in 14 of 50 runs; only `3005_envoys` (seen by 2) names her earlier. The reader has never heard of her. | 14 / 50 | **[N]** a clause ("the Eldest Wickwarden, Maud Tallis") |

*What this audit cannot say:* whether a companion's remark matches the scene, whether a clan standing change is explained in the text, and whether the tone of a detour line fits the run's alignment: those need the party, the standing and the detour text per step (section 1).

## 4. Nodes no run reached

`115`, `2015_scaffold_clerk`, `3005_dorran_later`, `3005_glass_fire`, `3005_glass_fire_fight`, `3005_tribunal_gold`, `3100_widow_later`, `3200_smith_later`, `5010_bark_cache` (+`_fight`), `5010_clan_crows_2` (+`_failed`, `_found`), `5010_deserter_dive_fail`, `5010_deserter_later`, `5010_imeh_later`, `5010_thieves_ship`, `5010_tobin_hymn`, `5100_anvil_deaf_vote`, `5100_clan_crows_1_lost`, `5100_tar_hand_book`, `5200_nell_later`, `6010_brannoc_later`, `6010_candle_walk_fight`, `6010_clan_compact_3` (+`_hammer`, `_seen`), `6010_clan_dominion_2`, `6010_count_short`, `6010_heist_night`, `6010_lantern_keeper`, `6010_lantern_manifest`, `6010_lysa_later`, `6010_wickwarden`, `6100_charter_signing`, `6100_stitcher_door`, `6200_clan_compact_2` (+`_refused`), `6200_eldest_later`, `6200_quarry_face_fight`, `7100_charter_choice`, `7100_clan_crows_3`, `7100_clan_dominion_3`, `7100_clan_penitents_3` (+`_bolt`, `_through`), `7100_cutter_lost`, `7100_flagship_hold`, `7100_impound`, `7200_clan_vigil_3` (+`_changed`, `_sworn`), `7200_courts_children`, `7200_followed`, `7200_fourth_piece`, `7200_ledger`, `7200_relic`, `7200_returned`, `7200_stitcher`, `7200_stitcher_kin`, `7200_thieves_aboard`, `7800_nkem_later`, `822_lie_failed`.

## 5. What I will do next, and what I need

**[N], in my own files, as a small data PR once I have a version number:**
1. Add `treasure` lines (and any missing kind) to every place pool in `detours.json`, starting with the six Saltmouth districts and the Cove camp (D7).
2. Grow the Cove camp's pool to 6+ lines per kind, with chapter ranges so chapters 3, 5, 6 and 7 do not repeat (D3).
3. Retag part of the `enemy` lines as calm (D5).
4. A "back at the hub" return line for `2015` and `7400` (S2) and the `open_hand_6` flag (S4).
5. Candidate: `noDetour` on the chapter-8 beats (D8): **I will not set it without the user's say**, it changes how the finale feels.

**For Core:** D1, D2, D4, D6, D10, S1, S3, S5, and the transcript option (section 1).

**Decisions for the user (via the manager):** whether a detour may fire between two scenes of one place (D1); which chapters may hold detours (D2, D8).

## 6. Reproducing

```
# the 50 runs (ordered choices)
SIM_OUT=runs50.json flutter test narrative_audit_scratch_test.dart
# the road replay
RUNS=runs50.json ROADS_OUT=roads50.json flutter test narrative_roads_scratch_test.dart
# the counts
python3 stats.py ; python3 analyze3.py
```
The scratch tests are in `tools/` as `.dart.txt`; copy them to the repository root (not `test/`) and rename. Same seed, same figures.

## 8. Decided (the user's answers on the audit)

- **D1: no.** No detour between two scenes of the same place. (Core: a rule in the detour engine; a city scene is the exception, section 5.5 of the Wave 11 proposal.)
- **D2: yes.** Chapter 4 gets detours. **What the DAG can and cannot do:** chapter 4's spine runs `4999_camp` (the cove camp) to `5003`, `5004`, `5004_altar`, `5005` inside the Hollow Court (one location). The only place-changing step is the sail `4999_camp` to `5003`: a voyage (`travelPlaceId`), into a set piece (`noDetour`, tense), which a detour should not touch. So **no chapter-4 beat of the spine can honestly be lifted**. The chapter's roads are the camp's trips to its three hubs, `5010` (the Drowned Cloister), `5100` (Wrack's End) and `5200` (Kindly Hill), and the hubs are not spine beats, so nothing rolls when leaving them. The hubs are calm and carry no `noDetour` (`5100` neutral, `5200` wondrous, `5010` action but without a set piece). **For Core:** let a choice that travels from or between these hubs roll a detour for chapter 4 (or add them to the chapter's spine).
- **D8: no detours in chapter 8.** Core enforces it as a chapter rule; I set no `noDetour` there.

