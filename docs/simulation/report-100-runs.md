# Simulation report: 100 playthroughs (chapter 5 softened, VERSION)

Regenerated after the chapter 5 tuning of VERSION. QA's L3 of 1.264.0 (`docs/qa/l3-1.264.0.md`) found chapter 5 to be the wall: 21% attempt win and the most failed attempts of any chapter. This release changes numbers only, and only for chapter 5's enemies (`assets/gamedata/enemies.json`). Every batch below was run twice on the same seeds, once on `main` at 1.267.0 and once with the change: the 100-run batch (seed 7) and the 800-run check (seeds 11 and 23).

## 0. Chapter 5, before and after

**Why chapter 5 was the wall.** No single fight caused it; attrition did. A won fight keeps its wounds, and only a lost one refills health. In the simulator the character rests only at a new chapter's hub. Chapter 5 has the longest run of fights before that rest (16 to 17 attempts a run), and its ordinary foes were heavies. The void hound, met 3.3 times a run (mostly in pairs), borrowed the legendary player skill `venomous_ambush`: a 56 base hit plus 3 turns of poison on 30% of its turns. No other ordinary enemy hits that hard. The penitents and the Unstitched carried mini-boss health and damage. Characters arrive at level 7.5 with 1 800 gold (chapter 4: 6.3 and 1 350; chapter 6: 8.7 and 2 330), so level and gear were on the normal curve. What I checked and ruled out:
- removing the ambush alone: 23.7%
- removing the pack howl alone: 23.0%
- removing the hound's counter: 21.0%
- 15% less health on six enemies: 23.5%
- 15% less damage: 27.0%
- one fight fewer in the Shroud's Vigil expedition: no change

Damage, not health, decides an attrition chapter.

**What changed** (`enemies.json`; health / damage, then the moves):

| enemy | before | after |
|---|---|---|
| void hound | 155 / 20; venomous ambush 30%, pack howl 25% | 135 / 16; venomous ambush 12%, pack howl 20% |
| inquisition penitent | 260 / 26 | 220 / 22 |
| masked penitent | 250 / 25 | 215 / 21 |
| the Unstitched (`tear_spawn`) | 300 / 28 | 255 / 24 |
| void archon (the chapter's boss) | 380 / 32; void blast 40%, eclipse 35% | 340 / 27; void blast 30%, eclipse 25% |

The void manifestation is unchanged. Cutting it made `boss_balance_test` fail: its level-4 win rate rose to 75%, above the test's 15 to 55% band. The band was not touched.

**Attempt win by chapter**, before → after:

| batch | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | all |
|---|---|---|---|---|---|---|---|---|---|
| 800-run check (seeds 11, 23) | 84% → 84% | 74% → 74% | 40% → 40% | 36% → 36% | **21% → 31%** | 28% → 31% | 15% → 16% | 19% → 21% | 36.7% → 39.9% |
| 100 runs (seed 7) | 83% → 83% | 72% → 72% | 40% → 40% | 34% → 34% | **21% → 29%** | 29% → 28% | 15% → 14% | 20% → 17% | 36.3% → 37.9% |

Failed attempts per run in chapter 5: 14.1 → 11.1 (800 runs). Chapter 5 now sits between chapter 4 (36%) and chapter 6 (31%), and is no longer the chapter that fails most per fight. It still has the most fights, so it keeps the most failed attempts a run.

**Chapter 5's enemies**, share of encounters lost, before → after:

| enemy | encounters (800 runs) | 800 runs | 100 runs |
|---|---|---|---|
| void hound | 2 463 | 60% → 34% | 59% → 39% |
| inquisition penitent | 459 | 63% → 41% | 67% → 43% |
| the Unstitched | 368 | 65% → 46% | 71% → 50% |
| masked penitent | 267 | 63% → 42% | 57% → 42% |
| void manifestation (unchanged) | 800 | 37% → 35% | 34% → 35% |
| void archon | 634 | 96% → 86% | 96% → 93% |

**What spread.** Chapters 1 to 4 are identical: same seeds, same rolls, and none of these enemies appears before chapter 5. Chapters 6 to 8 rise by 1 to 3 points over 800 runs, for two reasons. The hounds and penitents also turn up there. And characters now reach chapter 6 at level 9.2 instead of 8.7, because fewer lost attempts leave more XP. In the 100-run batch, chapters 6 to 8 move by −3 to −1 points; that is seed noise in small samples, as the L3 report explains. Every profession gains in the 800-run check: cleric 47% → 52%, mage 45% → 49%, ranger and rogue 33% → 36%, warrior 28% → 31%. The melee gap is unchanged. The archon is still lost 86% of the time, the band every boss of the game sits in (chapter 4's inquisitor 93%, chapter 6's admiral 85%). That is a question about bosses in general, not about chapter 5.

## How it was run

Harness: `simulatePlaythroughs` in `lib/screens/playthrough_simulator_screen.dart` (the in-app simulator's walk and fight model, run headless), driven by `test/sim_playthroughs_test.dart`:

```
SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=100 SIM_SEED=7   SIM_OUT=runs100.json flutter test test/sim_playthroughs_test.dart
SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=400 SIM_SEED=11  SIM_OUT=runs11.json  flutter test test/sim_playthroughs_test.dart
SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=400 SIM_SEED=23  SIM_OUT=runs23.json  flutter test test/sim_playthroughs_test.dart
python3 docs/simulation/make_report.py tables runs100.json     # the tables below
python3 docs/simulation/make_report.py csv runs100.json > docs/simulation/runs-100.csv
```

Seed 7, 100 runs from the first scene to the end, 25 per goal, professions rotated so each is played 20 times, race drawn at random. A lost fight is retried up to 3 times; then the walk moves on and counts it lost, so reaching the end says nothing about difficulty. An "attempt" is one try at a fight; an "encounter" is one fight scene (up to 3 attempts). The 800-run check plays seeds 11 and 23, 400 runs each. Since this release, the JSON also carries `enemiesByChapter` (encounters fought and lost per enemy in each chapter) and `arrivals` (the level and gold with which each chapter's hub was first reached). Section 0 is built from those. `make_report.py` only formats the simulator's JSON.

What it does **not** cover: the Journey map, the fight lab, ship battles on voyages, and the player's real choices of dice faces and loadouts. It also does not cover resting at camp in the middle of a chapter, which a player can do and the simulator does not. For an attrition chapter like 5 that makes the simulator harsher than play.

## 1. Headline

- Ended in a real ending: **100/100** (dead ends: 0, broken links: 0, step cap: 0). All 100 reach chapter 8. 800-run check: 800/800.
- Fights: 7 359 attempts over 4 071 encounters, 73.6 attempts and 40.7 encounters a run. **Attempt win rate 38%; encounter win rate 69%.** 800-run check: 39.9% and 71% (before: 36.7% and 67%).
- Level at the end: mean 11.1, p10/p50/p90 = 8/11/15. Gold at the end: mean 3 707 (p10/p50/p90 2 253/3 414/5 495).

## 2. By goal

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| random | 25 | 10.8 | 2989 | 34 | 214 | 62 | 40% | 234 | 11.9 | 1.2 | 24 | 11.1 |
| favorGood | 25 | 9.8 | 2722 | 85 | 214 | 68 | 35% | 217 | 12.4 | 0.7 | 22 | 10.5 |
| favorEvil | 25 | 10.6 | 3583 | -44 | 223 | 69 | 37% | 243 | 12.4 | 1.4 | 24 | 10.2 |
| maximizeGold | 25 | 13.3 | 5534 | 19 | 218 | 95 | 39% | 327 | 13.0 | 0.6 | 31 | 12.4 |

## 3. By profession

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cleric | 20 | 12.6 | 4081 | 40 | 222 | 63 | 49% | 960 | 13.2 | 1.1 | 29 | 12.2 |
| mage | 20 | 12.4 | 3882 | 10 | 221 | 69 | 48% | 313 | 12.8 | 1.2 | 29 | 11.2 |
| ranger | 20 | 10.8 | 3627 | 20 | 219 | 77 | 36% | 0 | 12.8 | 0.8 | 24 | 11.8 |
| rogue | 20 | 11.3 | 3511 | 25 | 214 | 74 | 37% | 2 | 11.9 | 1.0 | 26 | 10.2 |
| warrior | 20 | 8.5 | 3435 | 25 | 209 | 85 | 24% | 0 | 11.5 | 0.8 | 19 | 9.8 |

## 4. By race

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| dwarf | 20 | 11.3 | 3584 | 15 | 223 | 70 | 42% | 221 | 12.8 | 0.8 | 26 | 11.0 |
| elf | 19 | 11.6 | 3889 | 32 | 217 | 73 | 41% | 181 | 12.8 | 0.9 | 26 | 10.2 |
| human | 24 | 10.6 | 3875 | 18 | 214 | 81 | 33% | 241 | 12.2 | 0.8 | 25 | 11.5 |
| orc | 19 | 10.0 | 3176 | 30 | 215 | 71 | 33% | 363 | 11.7 | 1.2 | 23 | 10.4 |
| voidkin | 18 | 12.3 | 3990 | 24 | 218 | 71 | 43% | 278 | 12.7 | 1.1 | 28 | 12.2 |

## 5. By chapter

| chapter | runs | encounters | attempts | attempts/run | encounter win | attempt win | failed attempts/run |
|---|---|---|---|---|---|---|---|
| Chapter 1 | 100 | 411 | 445 | 4.5 | 90% | 83% | 0.8 |
| Chapter 2 | 100 | 786 | 1045 | 10.4 | 96% | 72% | 2.9 |
| Chapter 3 | 100 | 468 | 868 | 8.7 | 73% | 40% | 5.2 |
| Chapter 4 | 100 | 631 | 1211 | 12.1 | 65% | 34% | 8.0 |
| Chapter 5 | 100 | 782 | 1606 | 16.1 | 59% | 29% | 11.4 |
| Chapter 6 | 100 | 419 | 876 | 8.8 | 58% | 28% | 6.3 |
| Chapter 7 | 100 | 162 | 405 | 4.0 | 34% | 14% | 3.5 |
| Chapter 8 | 100 | 384 | 903 | 9.0 | 41% | 17% | 7.5 |

Chapter by goal (attempt win / attempts per run):

| strategy | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 |
|---|---|---|---|---|---|---|---|---|
| random | 90% / 3 | 67% / 10 | 43% / 8 | 35% / 9 | 32% / 13 | 36% / 8 | 14% / 4 | 19% / 9 |
| favorGood | 82% / 5 | 71% / 9 | 42% / 7 | 33% / 11 | 20% / 14 | 18% / 8 | 13% / 4 | 17% / 10 |
| favorEvil | 84% / 5 | 73% / 9 | 41% / 7 | 32% / 11 | 26% / 17 | 28% / 8 | 15% / 3 | 18% / 9 |
| maximizeGold | 78% / 5 | 76% / 14 | 35% / 13 | 34% / 17 | 35% / 21 | 28% / 11 | 13% / 5 | 15% / 9 |

Chapter by profession (attempt win):

| profession | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 |
|---|---|---|---|---|---|---|---|---|
| cleric | 81% | 87% | 62% | 49% | 36% | 45% | 7% | 26% |
| mage | 84% | 85% | 63% | 40% | 46% | 31% | 36% | 17% |
| ranger | 73% | 63% | 36% | 34% | 25% | 26% | 11% | 19% |
| rogue | 86% | 67% | 37% | 31% | 33% | 28% | 14% | 15% |
| warrior | 92% | 67% | 16% | 19% | 10% | 13% | 6% | 12% |

## 6. Every enemy met (encounter loss = all 3 attempts failed)

| enemy | first chapter | HP | damage | encounters | lost | loss rate |
|---|---|---|---|---|---|---|
| rime_bailiff | 5 | 340 | 29 | 3 | 3 | 100% |
| hollow_court_inquisitor | 4 | 340 | 33 | 94 | 89 | 95% |
| tear_herald | 8 | 345 | 27 | 100 | 93 | 93% |
| void_archon | 5 | 340 | 27 | 81 | 75 | 93% |
| white_admiral | 6 | 395 | 32 | 85 | 75 | 88% |
| claimant_vane | 7 | 365 | 33 | 32 | 28 | 88% |
| void_sovereign | 6 | 390 | 30 | 80 | 68 | 85% |
| claimant_tallis | 7 | 300 | 23 | 28 | 23 | 82% |
| bone_warden | 4 | 320 | 30 | 37 | 29 | 78% |
| void_stalker | 3 | 200 | 23 | 45 | 35 | 78% |
| claimant_morrow | 7 | 390 | 22 | 40 | 30 | 75% |
| aurel_vane | 1 | 165 | 18 | 31 | 21 | 68% |
| drowned_pilgrim | 5 | 165 | 21 | 102 | 59 | 58% |
| tear_spawn | 5 | 255 | 24 | 42 | 21 | 50% |
| hollow_reflection | 6 | 180 | 22 | 252 | 119 | 47% |
| inquisition_penitent | 5 | 220 | 22 | 71 | 32 | 45% |
| masked_penitent | 5 | 215 | 21 | 31 | 13 | 42% |
| void_hound | 5 | 135 | 16 | 340 | 129 | 38% |
| unmade_knight | 6 | 175 | 23 | 37 | 14 | 38% |
| white_soldier | 1 | 80 | 19 | 54 | 19 | 35% |
| void_manifestation | 5 | 165 | 21 | 100 | 35 | 35% |
| inquisition_soldier | 2 | 150 | 18 | 262 | 81 | 31% |
| iron_golem | 3 | 180 | 21 | 34 | 10 | 29% |
| inquisition_high_warden | 3 | 170 | 19 | 100 | 26 | 26% |
| catacomb_ghoul | 4 | 145 | 18 | 104 | 23 | 22% |
| bone_sexton | 4 | 150 | 19 | 88 | 19 | 22% |
| hollow_court_zealot | 4 | 160 | 20 | 113 | 24 | 21% |
| inquisition_auxiliary | 3 | 120 | 14 | 165 | 33 | 20% |
| smuggler_captain | 2 | 135 | 16 | 36 | 7 | 19% |
| rat_matriarch | 2 | 150 | 18 | 100 | 7 | 7% |
| void_wisp | 3 | 121 | 14 | 159 | 8 | 5% |
| plague_hound | 2 | 130 | 16 | 141 | 3 | 2% |
| dock_overseer | 2 | 112 | 14 | 118 | 1 | 1% |
| cultist_acolyte | 3 | 100 | 11 | 149 | 1 | 1% |
| harbor_rat | 2 | 62 | 9 | 195 | 1 | 1% |
| den_bouncer | 1 | 44 | 8 | 36 | 0 | 0% |
| den_looter | 1 | 44 | 8 | 30 | 0 | 0% |
| inquisition_warden | 1 | 111 | 17 | 105 | 0 | 0% |
| slum_thug | 1 | 56 | 9 | 102 | 0 | 0% |
| sore_loser | 1 | 44 | 8 | 34 | 0 | 0% |
| street_bandit | 1 | 78 | 10 | 233 | 0 | 0% |
| wreck_scavenger | 1 | 85 | 12 | 54 | 0 | 0% |

## 7. Distributions across the runs

| measure | min | p10 | median | p90 | max | mean |
|---|---|---|---|---|---|---|
| level | 6 | 8 | 11 | 15 | 20 | 11.1 |
| gold | 1681 | 2299 | 3495 | 5495 | 6974 | 3707.2 |
| alignment | -74 | -54 | 31 | 84 | 121 | 23.7 |
| steps | 196 | 202 | 215 | 234 | 262 | 217.2 |
| unique | 136 | 141 | 151 | 161 | 181 | 150.4 |
| encounters | 25 | 33 | 38 | 53 | 59 | 40.7 |
| won | 14 | 17 | 27 | 41 | 56 | 27.9 |
| lost | 12 | 23 | 43 | 68 | 103 | 45.7 |
| casts | 0 | 0 | 0 | 929 | 1708 | 255.2 |
| potions | 3 | 3 | 3 | 11 | 17 | 5.7 |
| quests | 9 | 10 | 12 | 14 | 21 | 12.4 |
| shops | 0 | 0 | 1 | 2 | 4 | 1.0 |
| flags | 115 | 122 | 134 | 147 | 161 | 134.2 |
| signs | 2 | 6 | 10 | 15 | 24 | 10.4 |
| offers | 14 | 17 | 24 | 35 | 47 | 25.5 |
| skills | 5 | 8 | 11 | 14 | 18 | 11.0 |

(`won`/`lost` are attempts won / lost; `steps` scenes walked; `unique` distinct scenes; `signs`, `offers`, `skills`: growth choices taken.)

## 8. What the data says

Numbers are the 100-run figures; the 800-run check agrees within 2 points unless noted.

1. **The story is consistent.** All 100 runs reach a real ending through chapter 8: all four goals and all five professions, with no dead end, no broken link and no step cap (also 800/800). `test/sim_playthroughs_test.dart` pins this.
2. **Chapter 5 is no longer the wall.** Attempt win by chapter is 83%, 72%, 40%, 34%, **29%**, 28%, 14%, 17% (800 runs: 84%, 74%, 40%, 36%, **31%**, 31%, 16%, 21%). The curve now falls steadily from chapter 3 to chapter 6. The trough is chapters 7 and 8, where the claimants and the tear herald are fought. Chapter 5 is still the longest chapter (16 attempts a run), so it still has the most failed attempts a run (11.4).
3. **Melee classes still trail the casters by about 15 points.** Warrior 31%, rogue 36%, ranger 36%, against cleric 52% and mage 49% (800 runs). The warrior's chapter 5 is 10% in the 100-run batch (19% over 800 runs), still the lowest cell after chapters 7 and 8. The caveat of earlier reports holds: the simulator plays spells for the casters and a plain dice policy for the others.
4. **Grinding raises level, barely odds.** The maximize-gold goal fights about 40% more (95 attempts a run against 62 to 69). It ends at level 13.3 against 9.8 to 10.8, yet wins 39% of attempts against 35% to 40%.
5. **The bosses are still lost 75% to 93% of the time** (800 runs): the hollow court inquisitor (chapter 4), the void archon (chapter 5: 86%, was 96%), the white admiral and the void sovereign (chapter 6), the claimants (chapter 7) and the tear herald (chapter 8). They are fought after a chapter's worth of wounds. A camp rest before a boss, which the simulator does not take, would move these more than any number.
6. **Easy enemies are still trivial**: the wreck scavenger, the sore loser and the den looter and bouncer lose nothing.
7. **Gold is not spent.** A run ends with about 3 400 gold in the median and visits 1 shop. This measures the simulator's policy as much as the economy.
8. **Alignment goals work.** Favor good ends at +85, favor evil at −44, the others at +19 to +34.

## 9. Not measured here

The Journey map and fight lab, ship battles, rest at camp in the middle of a chapter, and the player's own choices of dice faces and loadouts. A human who reads telegraphs, picks faces and rests before a boss will do better than this policy. Treat the absolute rates as a floor; the comparisons between classes, chapters and goals are the signal.
