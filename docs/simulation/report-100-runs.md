# Simulation report: 100 playthroughs (the boss curve, v1.280.0)

Regenerated after the boss curve of v1.280.0, a design decision by the user: each chapter's bosses are won about half the time on average, more often early and less often late. Until now, every boss was lost 80% to 95% of the time. This release changes numbers only: the health and damage of eleven bosses in `assets/gamedata/enemies.json`.

Every batch below was run twice on the same `main` (v1.277.0, `c7ba508`): once as it is and once with the change. The batches are the 100-run batch (seed 7) and the 800-run check (seeds 11 and 23). The previous report, chapter 5's tuning at v1.270.0, is in the git history of this file.

## 0. The boss curve, before and after

**Targets** (share of encounters won; an encounter is lost after 3 failed attempts):

| chapter | 1 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|
| target | 75% | 65% | 55% | 50% | 45% | 40% | 35% |

The bosses are measured where the story puts them: after the chapter's own fights, with its wounds, at the level a run has by then. That is why the numbers were so low before. Chapter 2's fights (the smuggler captain, the rat matriarch, the plague hound) were already won 88% to 98% of the time and are not changed.

**Method.** Each boss has a factor that scales its health, with damage scaled by the factor's square root, so the fight stays the same shape and only gets shorter. The factors were tuned on separate seeds (101 and 103, 800 runs each round, nine rounds). Only then were they measured on this report's seeds, which the tuning never saw.

| ch | boss | health / damage before | after | target | 800 runs (11, 23) | 100 runs (7) |
|---|---|---|---|---|---|---|
| 1 | Aurel Vane | 165 / 18 | 111 / 15 | 75% | 29% → **79%** | 32% → 77% |
| 3 | void stalker | 200 / 23 | 147 / 20 | 65% | 26% → **65%** | 30% → 61% |
| 4 | Hollow Court inquisitor | 340 / 33 | 165 / 23 | 55% | 8% → **55%** | 8% → 59% |
| 4 | bone warden | 320 / 30 | 229 / 25 | 55% | 17% → **56%** | 25% → 50% |
| 5 | void archon | 340 / 27 | 235 / 22 | 50% | 18% → **50%** | 16% → 51% |
| 6 | white admiral | 395 / 32 | 305 / 28 | 45% | 18% → **45%** | 18% → 37% |
| 7 | claimant Vane | 365 / 33 | 276 / 29 | 40% | 14% → **42%** | 24% → 36% |
| 7 | claimant Tallis | 300 / 23 | 203 / 19 | 40% | 16% → **37%** | 4% → 40% |
| 7 | claimant Morrow | 390 / 22 | 375 / 22 | 40% | 28% → **39%** | 39% → 39% |
| 8 | tear herald | 345 / 27 | 264 / 24 | 35% | 13% → **34%** | 19% → 30% |
| 8 | void sovereign | 390 / 30 | 332 / 28 | 35% | 16% → **33%** | 17% → 36% |

Over 800 runs, every boss lands within 4 points of its target. The 100-run figures have only 30 to 100 encounters per boss, so they scatter more (within 8 points). The average over the eleven bosses goes from 18% to 49%. The Hollow Court inquisitor needed the largest cut, its health halved: it was won 8% of the time, the least of any boss.

**Attempt win by chapter**, before → after:

| batch | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | all |
|---|---|---|---|---|---|---|---|---|---|
| 800 runs (seeds 11, 23) | 84 → 90 | 73 → 74 | 41 → 44 | 35 → 45 | 31 → 36 | 30 → 36 | 17 → 24 | 21 → 27 | 39.8 → 45.1 |
| 100 runs (seed 7) | 83 → 86 | 74 → 74 | 40 → 42 | 38 → 46 | 34 → 35 | 31 → 35 | 20 → 24 | 22 → 26 | 41.3 → 44.6 |

**What spread.**
- Every chapter with a boss gains, by 3 to 10 points, and chapter 4 gains the most, since it has two bosses.
- Characters end about one level higher (11.7 → 12.9 over 800 runs) and with about 450 more gold, because fewer lost attempts leave more XP and more fights won.
- They reach each chapter from 5 on about half a level higher (chapter 6: 9.3 → 9.8). The "Play to chapter" arrival table of v1.275 was measured before this change and can be regenerated with it.
- By profession (800 runs): cleric 54 → 63, mage 49 → 55, ranger 35 → 41, rogue 36 → 40, warrior 30 → 33. The gap between melee classes and casters is unchanged.

**The test.** `test/boss_balance_test.dart` gains a group, "the boss curve". It runs the simulator for 200 seeded runs (seed 7, about 15 seconds) and checks each boss against its target within 12 points. It also checks that the average stays between 42% and 58% and that early bosses are won more often than late ones. Moving these targets is the user's decision for this release. The test's three older cases (the high warden, the zealot and the manifestation, measured in a simplified duel) are unchanged and still pass.

## How it was run

Harness: `simulatePlaythroughs` in `lib/screens/playthrough_simulator_screen.dart` (the in-app simulator's walk and fight model, run headless), driven by `test/sim_playthroughs_test.dart`:

```
SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=100 SIM_SEED=7   SIM_OUT=runs100.json flutter test test/sim_playthroughs_test.dart
SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=400 SIM_SEED=11  SIM_OUT=runs11.json  flutter test test/sim_playthroughs_test.dart
SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=400 SIM_SEED=23  SIM_OUT=runs23.json  flutter test test/sim_playthroughs_test.dart
python3 docs/simulation/make_report.py tables runs100.json     # the tables below
python3 docs/simulation/make_report.py csv runs100.json > docs/simulation/runs-100.csv
```

Seed 7, 100 runs from the first scene to the end, 25 per goal, professions rotated so each is played 20 times, race drawn at random. A lost fight is retried up to 3 times; then the walk moves on and counts it lost, so reaching the end says nothing about difficulty. An "attempt" is one try at a fight; an "encounter" is one fight scene (up to 3 attempts). The 800-run check plays seeds 11 and 23, 400 runs each. The JSON also carries (since v1.270) `enemiesByChapter` (encounters fought and lost per enemy in each chapter) and `arrivals` (the level and gold with which each chapter's hub was first reached). Section 0 is built from those. `make_report.py` only formats the simulator's JSON.

What it does **not** cover: the Journey map, the fight lab, ship battles on voyages, and the player's real choices of dice faces and loadouts. It also does not cover resting at camp in the middle of a chapter, which a player can do and the simulator does not. It makes the simulator harsher than play, above all for the bosses, which a player can meet rested.

## 1. Headline

- Ended in a real ending: **100/100** (dead ends: 0, broken links: 0, step cap: 0). All 100 reach chapter 8. 800-run check: 800/800.
- Fights: 6 922 attempts over 4 078 encounters, 69 attempts and 40.8 encounters a run. **Attempt win rate 45%; encounter win rate 76%.** 800-run check: 45.1% and 77% (before: 39.8% and 68%).
- Level at the end: mean 12.8, p10/p50/p90 = 9/13/17. Gold at the end: mean 4 274 (p10/p50/p90 2 582/3 963/6 183).
- The eleven chapter bosses are won 49% of the time on average (800 runs; 18% before), from 79% in chapter 1 to 33–34% in chapter 8.

## 2. By goal

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| random | 25 | 12.2 | 3612 | 37 | 222 | 61 | 45% | 226 | 12.9 | 1.4 | 27 | 11.4 |
| favorGood | 25 | 12.6 | 3182 | 87 | 225 | 58 | 50% | 175 | 13.5 | 1.1 | 28 | 11.6 |
| favorEvil | 25 | 12.5 | 4296 | -47 | 225 | 66 | 43% | 273 | 13.2 | 1.2 | 28 | 12.3 |
| maximizeGold | 25 | 14.1 | 6006 | 22 | 219 | 92 | 42% | 304 | 13.7 | 0.3 | 34 | 12.8 |

## 3. By profession

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cleric | 20 | 15.1 | 5108 | 45 | 224 | 56 | 63% | 890 | 13.0 | 0.8 | 35 | 12.8 |
| mage | 20 | 14.3 | 4462 | 18 | 226 | 67 | 55% | 301 | 13.5 | 1.0 | 34 | 11.9 |
| ranger | 20 | 13.7 | 4238 | 19 | 225 | 70 | 47% | 0 | 13.6 | 1.2 | 31 | 13.4 |
| rogue | 20 | 11.5 | 4095 | 16 | 221 | 74 | 36% | 30 | 13.1 | 1.0 | 26 | 11.7 |
| warrior | 20 | 9.6 | 3467 | 24 | 216 | 79 | 29% | 0 | 13.4 | 0.9 | 21 | 10.3 |

## 4. By race

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| dwarf | 20 | 13.6 | 4336 | 19 | 222 | 67 | 49% | 202 | 12.9 | 0.8 | 31 | 12.4 |
| elf | 19 | 13.4 | 4406 | 32 | 224 | 70 | 46% | 198 | 12.9 | 1.1 | 31 | 12.6 |
| human | 24 | 12.1 | 4097 | 18 | 222 | 75 | 40% | 222 | 13.7 | 1.1 | 27 | 11.7 |
| orc | 19 | 11.8 | 4125 | 36 | 220 | 67 | 41% | 345 | 13.4 | 0.7 | 27 | 11.6 |
| voidkin | 18 | 13.4 | 4459 | 20 | 223 | 65 | 50% | 262 | 13.4 | 1.1 | 31 | 11.9 |

## 5. By chapter

| chapter | runs | encounters | attempts | attempts/run | encounter win | attempt win | failed attempts/run |
|---|---|---|---|---|---|---|---|
| Chapter 1 | 100 | 393 | 422 | 4.2 | 93% | 86% | 0.6 |
| Chapter 2 | 100 | 774 | 1016 | 10.2 | 97% | 74% | 2.7 |
| Chapter 3 | 100 | 464 | 846 | 8.5 | 76% | 41% | 5.0 |
| Chapter 4 | 100 | 630 | 1081 | 10.8 | 78% | 46% | 5.9 |
| Chapter 5 | 100 | 786 | 1519 | 15.2 | 68% | 35% | 9.8 |
| Chapter 6 | 100 | 429 | 809 | 8.1 | 67% | 35% | 5.2 |
| Chapter 7 | 100 | 172 | 376 | 3.8 | 53% | 24% | 2.9 |
| Chapter 8 | 100 | 401 | 853 | 8.5 | 54% | 26% | 6.3 |

Chapter by goal (attempt win / attempts per run):

| strategy | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 |
|---|---|---|---|---|---|---|---|---|
| random | 92% / 3 | 69% / 10 | 41% / 8 | 47% / 8 | 36% / 13 | 38% / 7 | 23% / 4 | 31% / 9 |
| favorGood | 82% / 5 | 76% / 9 | 46% / 7 | 52% / 9 | 44% / 11 | 41% / 7 | 32% / 3 | 28% / 7 |
| favorEvil | 84% / 5 | 74% / 8 | 41% / 7 | 45% / 10 | 32% / 17 | 38% / 8 | 23% / 3 | 26% / 9 |
| maximizeGold | 89% / 4 | 76% / 14 | 40% / 12 | 42% / 16 | 33% / 21 | 28% / 11 | 20% / 5 | 18% / 9 |

Chapter by profession (attempt win):

| profession | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 |
|---|---|---|---|---|---|---|---|---|
| cleric | 85% | 83% | 76% | 66% | 49% | 70% | 25% | 52% |
| mage | 88% | 84% | 67% | 59% | 50% | 38% | 51% | 21% |
| ranger | 77% | 68% | 37% | 46% | 41% | 41% | 33% | 30% |
| rogue | 88% | 69% | 31% | 33% | 26% | 25% | 15% | 23% |
| warrior | 96% | 68% | 20% | 30% | 17% | 15% | 8% | 12% |

## 6. Every enemy met (encounter loss = all 3 attempts failed)

| enemy | first chapter | HP | damage | encounters | lost | loss rate |
|---|---|---|---|---|---|---|
| tear_herald | 8 | 264 | 24 | 100 | 70 | 70% |
| rime_bailiff | 5 | 340 | 29 | 3 | 2 | 67% |
| claimant_vane | 7 | 276 | 29 | 39 | 25 | 64% |
| void_sovereign | 6 | 332 | 28 | 83 | 53 | 64% |
| white_admiral | 6 | 305 | 28 | 89 | 56 | 63% |
| claimant_morrow | 7 | 375 | 22 | 31 | 19 | 61% |
| claimant_tallis | 7 | 203 | 19 | 30 | 18 | 60% |
| drowned_pilgrim | 5 | 165 | 21 | 91 | 46 | 51% |
| bone_warden | 4 | 229 | 25 | 40 | 20 | 50% |
| void_archon | 5 | 235 | 22 | 86 | 42 | 49% |
| inquisition_penitent | 5 | 220 | 22 | 73 | 32 | 44% |
| masked_penitent | 5 | 215 | 21 | 28 | 12 | 43% |
| hollow_reflection | 6 | 180 | 22 | 248 | 104 | 42% |
| tear_spawn | 5 | 255 | 24 | 48 | 20 | 42% |
| hollow_court_inquisitor | 4 | 165 | 23 | 93 | 38 | 41% |
| void_stalker | 3 | 147 | 20 | 43 | 17 | 40% |
| iron_golem | 3 | 180 | 21 | 34 | 13 | 38% |
| white_soldier | 1 | 80 | 19 | 56 | 18 | 32% |
| void_hound | 5 | 135 | 16 | 325 | 102 | 31% |
| void_manifestation | 5 | 165 | 21 | 100 | 29 | 29% |
| inquisition_soldier | 2 | 150 | 18 | 269 | 78 | 29% |
| inquisition_high_warden | 3 | 170 | 19 | 100 | 28 | 28% |
| unmade_knight | 6 | 175 | 23 | 20 | 5 | 25% |
| aurel_vane | 1 | 111 | 15 | 31 | 7 | 23% |
| inquisition_auxiliary | 3 | 120 | 14 | 183 | 37 | 20% |
| hollow_court_zealot | 4 | 160 | 20 | 117 | 22 | 19% |
| catacomb_ghoul | 4 | 145 | 18 | 99 | 15 | 15% |
| bone_sexton | 4 | 150 | 19 | 108 | 15 | 14% |
| smuggler_captain | 2 | 135 | 16 | 44 | 3 | 7% |
| rat_matriarch | 2 | 150 | 18 | 87 | 5 | 6% |
| cultist_acolyte | 3 | 100 | 11 | 132 | 4 | 3% |
| dock_overseer | 2 | 112 | 14 | 113 | 3 | 3% |
| void_wisp | 3 | 121 | 14 | 148 | 2 | 1% |
| inquisition_warden | 1 | 111 | 17 | 93 | 1 | 1% |
| slum_thug | 1 | 56 | 9 | 128 | 1 | 1% |
| den_bouncer | 1 | 44 | 8 | 36 | 0 | 0% |
| den_looter | 1 | 44 | 8 | 30 | 0 | 0% |
| harbor_rat | 2 | 62 | 9 | 210 | 0 | 0% |
| plague_hound | 2 | 130 | 16 | 140 | 0 | 0% |
| sore_loser | 1 | 44 | 8 | 34 | 0 | 0% |
| street_bandit | 1 | 78 | 10 | 232 | 0 | 0% |
| wreck_scavenger | 1 | 85 | 12 | 55 | 0 | 0% |

## 7. Distributions across the runs

| measure | min | p10 | median | p90 | max | mean |
|---|---|---|---|---|---|---|
| level | 5 | 9 | 13 | 17 | 20 | 12.8 |
| gold | 1845 | 2705 | 3985 | 6183 | 7710 | 4273.9 |
| alignment | -79 | -53 | 32 | 87 | 111 | 24.6 |
| steps | 197 | 206 | 224 | 237 | 256 | 222.4 |
| unique | 134 | 143 | 153 | 162 | 175 | 152.7 |
| encounters | 24 | 33 | 39 | 52 | 56 | 40.8 |
| won | 6 | 19 | 31 | 43 | 54 | 30.9 |
| lost | 4 | 16 | 34 | 68 | 93 | 38.4 |
| casts | 0 | 0 | 0 | 838 | 1505 | 244.2 |
| potions | 3 | 3 | 3 | 10 | 13 | 5.2 |
| quests | 8 | 11 | 13 | 16 | 19 | 13.3 |
| shops | 0 | 0 | 1 | 2 | 4 | 1.0 |
| flags | 115 | 124 | 139 | 152 | 164 | 138.6 |
| signs | 5 | 6 | 12 | 19 | 26 | 12.6 |
| offers | 13 | 20 | 30 | 39 | 48 | 29.4 |
| skills | 6 | 9 | 12 | 16 | 18 | 12.0 |

(`won`/`lost` are attempts won / lost; `steps` scenes walked; `unique` distinct scenes; `signs`, `offers`, `skills`: growth choices taken.)

## 8. What the data says

Numbers are the 100-run figures; the 800-run check agrees within 2 points unless noted.

1. **The story is consistent.** All 100 runs reach a real ending through chapter 8, across all four goals and all five professions: no dead end, no broken link, no step cap (also 800/800).
2. **The bosses follow the curve.** See section 0: 75% in chapter 1 down to 35% in chapter 8, all within 4 points over 800 runs, and about half on average. `boss_balance_test` pins it.
3. **The chapters fall more gently.** Attempt win by chapter is 86%, 74%, 42%, 46%, 35%, 35%, 24% and 26% (800 runs: 90, 74, 44, 45, 36, 36, 24, 27). The trough is still chapters 7 and 8, but it is 7 points higher than before.
4. **Melee classes still trail the casters**, by about 18 points: warrior 33%, rogue 40%, ranger 41%, against cleric 63% and mage 55% (800 runs). The bosses moved every class about alike. The caveat of earlier reports holds: the simulator plays spells for casters and a plain dice policy for the others.
5. **Gold is still not spent.** A run ends with about 4 000 gold in the median.

## 9. Not measured here

The Journey map and the fight lab, ship battles, rest at camp in the middle of a chapter, and the player's own choices of dice faces and loadouts. A human who reads telegraphs, picks faces and rests before a boss will do better than this policy. Treat the absolute rates as a floor; the comparisons between classes, chapters and bosses are the signal.
