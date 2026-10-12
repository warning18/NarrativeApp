# Simulation report: 100 playthroughs (v1.256.0)

Regenerated on `main` at v1.256.0 (702df94), docs only: no game or balance number was touched. The previous run was v1.228.0; this one is the same plan (see "How it was run") on the current game and the current simulator. The batches were first run on v1.254.0 and run again on v1.256.0: the output is identical (v1.255.0 reworded story text, v1.256.0 changed the Journey map; neither touches what the simulator plays).

## 0. Compared with v1.228.0

| measure (100 runs, seed 7) | v1.228.0 | now (v1.256.0) |
|---|---|---|
| ended in a real ending / reached chapter 8 | 100 / 100 | 100 / 100 |
| attempt win rate | 34% | **39%** (800-run check: 33% before, 37% now) |
| encounter win rate | 64% | **70%** (800 runs: 64% before, 68% now) |
| level at the end (mean) | 8.6 | 11.2 |
| gold at the end (mean) | 2716 | 3418 |
| chapter 2 / 3 / 4 attempt win | 66% / 34% / 31% | 74% / 41% / 38% |
| chapter 5 attempt win (the wall) | 18% | **24%** (12.8 failed attempts a run, still the most of any chapter) |
| chapter 6 / 7 / 8 attempt win | 28% / 14% / 18% | 32% / 19% / 23% |
| warrior / rogue / ranger attempt win | 25% / 29% / 29% | 27% / 33% / 36% |
| cleric / mage attempt win | 45% / 45% | 59% / 48% |
| melee against casters, 800 runs | about 17 points behind (27% against 44%) | **about 16 points behind** (31% against 48%) |
| scenes no run reached (300 explore and random runs) | 22 of 385 | 15 of 385 (96% reached) |
| `7002_orders`, `7002_throne` | never reached | **still never reached** |

How to read it. Much of the rise of about 5 points comes from the simulator, not the game: v1.229.0 made it roll ability checks (the same plan then scored 31%, down from 34%) and v1.230.0 made it play quests, which pay about 700 to 900 gold and 1 000 to 1 200 XP a run (more for the thorough goal) and put the characters at level 10 to 13 instead of 7 to 8 (see `report-quests.md`). The 1.228.0 column is the old simulator; the "now" column has both changes, so the two columns are not a clean before and after for the game's own balance: the v1.230.0 report already measured 35% to 43% with quests on the game as it was then, and the rest of the rise is what the game changed in between (new enemies such as the rime bailiff among them), which I did not separate. What did not move: chapter 5 is still the hardest stretch, the melee classes are still about 16 points behind the casters, the grinding goal still buys almost no odds, and the same bosses are still lost 80% to 96% of the time.

Not changed in this report: the number of enemies never met (23 of 65), shops opened (5 of 14) and the two unreachable Hollow Shore scenes; see `report-branches.md`.

## How it was run

Harness: `simulatePlaythroughs` in `lib/screens/playthrough_simulator_screen.dart` (the in-app simulator's walk and fight model, run headless), driven by `test/sim_playthroughs_test.dart`:

```
SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=100 SIM_SEED=7   SIM_OUT=runs100.json flutter test test/sim_playthroughs_test.dart
python3 docs/simulation/make_report.py tables runs100.json     # the tables below
python3 docs/simulation/make_report.py csv runs100.json > docs/simulation/runs-100.csv
```

Seed 7, 100 runs from the first scene to the end, 25 per goal (strategy), professions rotated so every one is played 20 times, race drawn at random. A lost fight is retried up to 3 times, then the walk moves on counting it lost (so reaching the end says nothing about difficulty). "Attempt" = one try at a fight; "encounter" = one fight scene (up to 3 attempts). An 800-run check (seeds 11 and 23, 400 each) gives the same picture; its figures are quoted where they differ by more than 2 points. `make_report.py` only formats the simulator's JSON; the numbers come from the harness.

What it does **not** cover: the Journey map, the fight lab, ship battles on voyages, the player's real choices of dice faces and loadouts. Quests are played (since v1.230.0) and ability checks are rolled (since v1.229.0), which the v1.228.0 report did not.

## 1. Headline

- Ended in a real ending: **100/100** (dead ends: 0, broken links: 0, step cap: 0). All 100 reach chapter 8 and the same ending, "Begin again, changed". 800-run check: 800/800.
- Fights: 7224 attempts over 4060 encounters (72 attempts and 40.6 encounters per run). **Attempt win rate 39%; encounter win rate 70%** (an encounter is lost after 3 failed attempts). 800-run check: 37% / 68%.
- Level at the end: mean 11.2, p10/p50/p90 = 8/11/15. Gold at the end: mean 3418 (p10/p50/p90 1911/3091/5378).
- Runs with no lost encounter: 0%; runs with 5 or more lost attempts: 99%.

## 2. By goal (strategy)

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| random | 25 | 10.3 | 2914 | 39 | 213 | 64 | 38% | 196 | 11.5 | 1.1 | 24 | 10.8 |
| favorGood | 25 | 10.8 | 2270 | 84 | 214 | 64 | 40% | 214 | 11.2 | 1.7 | 24 | 9.8 |
| favorEvil | 25 | 10.9 | 3201 | -48 | 218 | 65 | 40% | 200 | 11.2 | 1.6 | 25 | 10.3 |
| maximizeGold | 25 | 12.8 | 5289 | 20 | 218 | 95 | 39% | 318 | 12.4 | 0.5 | 30 | 11.8 |

Goal meaning: random picks any open choice; favorGood / favorEvil take the choice that moves alignment up / down; maximizeGold takes the choice that pays most (which also means taking every fight that pays). Alignment no longer sits near 0 for the goals that do not steer it (+20 to +39): quest rewards now move it.

## 3. By profession (20 runs each)

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cleric | 20 | 14.2 | 4143 | 45 | 219 | 58 | 59% | 824 | 11.8 | 1.6 | 32 | 12.4 |
| mage | 20 | 12.3 | 3340 | 18 | 218 | 68 | 48% | 336 | 11.5 | 1.4 | 30 | 11.1 |
| ranger | 20 | 10.8 | 3341 | 18 | 215 | 75 | 36% | 0 | 11.3 | 1.2 | 24 | 10.9 |
| rogue | 20 | 10.2 | 3278 | 17 | 214 | 77 | 33% | 0 | 11.8 | 1.1 | 23 | 9.7 |
| warrior | 20 | 8.4 | 2990 | 22 | 212 | 83 | 27% | 0 | 11.4 | 0.8 | 19 | 9.3 |

800-run check, attempt win rate: cleric 50%, mage 45%, ranger 32%, rogue 32%, warrior 29%.

## 4. By race

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| dwarf | 20 | 11.3 | 3326 | 20 | 213 | 71 | 40% | 226 | 11.2 | 1.1 | 25 | 10.2 |
| elf | 19 | 11.6 | 3486 | 32 | 218 | 70 | 42% | 153 | 12.6 | 1.3 | 26 | 10.6 |
| human | 24 | 10.3 | 3430 | 18 | 214 | 79 | 34% | 225 | 11.2 | 1.3 | 24 | 10.1 |
| orc | 19 | 11.5 | 3322 | 29 | 217 | 68 | 41% | 262 | 11.3 | 1.5 | 27 | 11.4 |
| voidkin | 18 | 11.5 | 3537 | 23 | 217 | 71 | 42% | 300 | 11.7 | 0.9 | 27 | 11.3 |

800-run check: dwarf 41%, elf 38%, human 35%, orc 35%, voidkin 37% (the 100-run spread of 34% to 42% is mostly noise; the profession gap is not).

## 5. By chapter

| chapter | runs | encounters | attempts | attempts/run | encounter win | attempt win | failed attempts/run |
|---|---|---|---|---|---|---|---|
| Chapter 1 | 100 | 411 | 445 | 4.5 | 90% | 83% | 0.8 |
| Chapter 2 | 100 | 761 | 995 | 9.9 | 96% | 74% | 2.6 |
| Chapter 3 | 100 | 482 | 879 | 8.8 | 74% | 41% | 5.2 |
| Chapter 4 | 100 | 637 | 1175 | 11.8 | 70% | 38% | 7.3 |
| Chapter 5 | 100 | 776 | 1687 | 16.9 | 52% | 24% | 12.8 |
| Chapter 6 | 100 | 398 | 797 | 8.0 | 64% | 32% | 5.4 |
| Chapter 7 | 100 | 167 | 382 | 3.8 | 44% | 19% | 3.1 |
| Chapter 8 | 100 | 396 | 864 | 8.6 | 49% | 23% | 6.7 |

Chapter by goal (attempt win / attempts per run):

| strategy | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 |
|---|---|---|---|---|---|---|---|---|
| random | 90% / 3 | 72% / 9 | 44% / 8 | 40% / 10 | 20% / 14 | 34% / 8 | 15% / 4 | 20% / 8 |
| favorGood | 82% / 5 | 69% / 9 | 39% / 7 | 41% / 11 | 24% / 14 | 35% / 8 | 20% / 3 | 25% / 8 |
| favorEvil | 84% / 5 | 77% / 8 | 40% / 8 | 38% / 10 | 23% / 16 | 32% / 6 | 23% / 4 | 29% / 8 |
| maximizeGold | 78% / 5 | 75% / 14 | 40% / 12 | 35% / 17 | 28% / 23 | 28% / 10 | 19% / 5 | 18% / 10 |

Chapter by profession (attempt win):

| profession | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 |
|---|---|---|---|---|---|---|---|---|
| cleric | 81% | 86% | 71% | 51% | 43% | 68% | 23% | 55% |
| mage | 84% | 85% | 65% | 47% | 35% | 34% | 43% | 19% |
| ranger | 73% | 72% | 39% | 33% | 21% | 28% | 19% | 24% |
| rogue | 86% | 64% | 37% | 35% | 18% | 23% | 11% | 17% |
| warrior | 92% | 66% | 14% | 28% | 11% | 20% | 9% | 9% |

## 6. Every enemy met (encounter loss = all 3 attempts failed)

| enemy | first chapter | HP | damage | encounters | lost | loss rate |
|---|---|---|---|---|---|---|
| hollow_court_inquisitor | 4 | 340 | 33 | 95 | 89 | 94% |
| void_archon | 5 | 380 | 32 | 77 | 70 | 91% |
| tear_herald | 8 | 345 | 27 | 100 | 84 | 84% |
| claimant_vane | 7 | 365 | 33 | 37 | 31 | 84% |
| claimant_tallis | 7 | 300 | 23 | 29 | 24 | 83% |
| white_admiral | 6 | 395 | 32 | 87 | 68 | 78% |
| void_stalker | 3 | 200 | 23 | 42 | 32 | 76% |
| void_sovereign | 6 | 390 | 30 | 85 | 64 | 75% |
| bone_warden | 4 | 320 | 30 | 39 | 27 | 69% |
| aurel_vane | 1 | 165 | 18 | 31 | 21 | 68% |
| rime_bailiff | 5 | 340 | 29 | 11 | 7 | 64% |
| claimant_morrow | 7 | 390 | 22 | 34 | 21 | 62% |
| masked_penitent | 5 | 250 | 25 | 31 | 19 | 61% |
| tear_spawn | 5 | 300 | 28 | 44 | 26 | 59% |
| void_hound | 5 | 155 | 20 | 324 | 172 | 53% |
| inquisition_penitent | 5 | 260 | 26 | 65 | 33 | 51% |
| drowned_pilgrim | 5 | 165 | 21 | 89 | 40 | 45% |
| hollow_reflection | 6 | 180 | 22 | 253 | 87 | 34% |
| white_soldier | 1 | 80 | 19 | 54 | 18 | 33% |
| void_manifestation | 5 | 165 | 21 | 100 | 29 | 29% |
| inquisition_soldier | 2 | 150 | 18 | 251 | 66 | 26% |
| unmade_knight | 6 | 175 | 23 | 35 | 9 | 26% |
| inquisition_high_warden | 3 | 170 | 19 | 100 | 24 | 24% |
| iron_golem | 3 | 180 | 21 | 38 | 9 | 24% |
| inquisition_auxiliary | 3 | 120 | 14 | 194 | 40 | 21% |
| catacomb_ghoul | 4 | 145 | 18 | 108 | 22 | 20% |
| hollow_court_zealot | 4 | 160 | 20 | 123 | 24 | 20% |
| smuggler_captain | 2 | 135 | 16 | 44 | 6 | 14% |
| rat_matriarch | 2 | 150 | 18 | 61 | 6 | 10% |
| bone_sexton | 4 | 150 | 19 | 103 | 9 | 9% |
| plague_hound | 2 | 130 | 16 | 146 | 6 | 4% |
| void_wisp | 3 | 121 | 14 | 148 | 5 | 3% |
| dock_overseer | 2 | 112 | 14 | 116 | 3 | 3% |
| inquisition_warden | 1 | 111 | 17 | 106 | 1 | 1% |
| cultist_acolyte | 3 | 100 | 11 | 133 | 1 | 1% |
| street_bandit | 1 | 78 | 10 | 227 | 1 | 0% |
| den_bouncer | 1 | 44 | 8 | 36 | 0 | 0% |
| den_looter | 1 | 44 | 8 | 30 | 0 | 0% |
| harbor_rat | 2 | 62 | 9 | 215 | 0 | 0% |
| slum_thug | 1 | 56 | 9 | 99 | 0 | 0% |
| sore_loser | 1 | 44 | 8 | 34 | 0 | 0% |
| wreck_scavenger | 1 | 85 | 12 | 54 | 0 | 0% |

## 7. Distributions across the 100 runs

| measure | min | p10 | median | p90 | max | mean |
|---|---|---|---|---|---|---|
| level | 5 | 8 | 11 | 15 | 17 | 11.2 |
| gold | 1096 | 1911 | 3091 | 5279 | 7017 | 3418.4 |
| alignment | -70 | -55 | 31 | 87 | 110 | 23.9 |
| steps | 195 | 205 | 214 | 230 | 260 | 215.7 |
| unique | 136 | 142 | 149 | 158 | 174 | 149.7 |
| encounters | 28 | 32 | 38 | 53 | 59 | 40.6 |
| won | 13 | 18 | 27 | 40 | 47 | 28.3 |
| lost | 4 | 18 | 42 | 68 | 97 | 43.9 |
| casts | 0 | 0 | 0 | 740 | 1513 | 232.1 |
| potions | 3 | 3 | 7 | 13 | 17 | 6.6 |
| quests | 7 | 9 | 12 | 14 | 18 | 11.6 |
| shops | 0 | 0 | 1 | 3 | 4 | 1.2 |
| flags | 116 | 123 | 131 | 140 | 154 | 130.9 |
| signs | 3 | 6 | 11 | 17 | 21 | 11.1 |
| offers | 14 | 17 | 26 | 35 | 38 | 25.7 |
| skills | 4 | 7 | 11 | 14 | 17 | 10.7 |

(`won`/`lost` are attempts won / lost; `steps` scenes walked; `unique` distinct scenes; `signs`, `offers`, `skills`: growth choices taken.)

## 8. What the data says

Numbers are the 100-run figures; the 800-run check agrees within 2 points unless noted.

1. **The story is consistent.** 100/100 runs of all four goals and all five professions reach a real ending through chapter 8; no dead end, no broken link, no step cap (also 800/800). `test/sim_playthroughs_test.dart` pins this.
2. **Fights are still hard, and the wall is still chapter 5.** Overall 39% of attempts are won (v1.228.0: 34%). Chapter 1 is 83%, chapter 2 74%, then 41%, 38%, **24% in chapter 5** (16.9 attempts and 12.8 failed attempts per run, the most of any chapter), 32% in chapter 6, 19% in chapter 7, 23% in chapter 8. Every chapter from 2 on is 4 to 8 points easier than in v1.228.0 (chapter 5: 18% to 24%), but the shape is the same: a wall at chapter 5 and a second trough in chapter 7.
3. **Melee classes still trail the casters by about 16 points.** Warrior 29%, rogue 32%, ranger 32% against cleric 50% and mage 45% (800 runs; 27% to 36% against 48% to 59% in the 100). The casters also end about 3 levels higher (cleric 12.7 and mage 11.8, against 8.9 to 10.0), and level matters: attempt win rate is 15% at level 5 or less, 25% at 6 to 8, 34% at 9 to 11, 49% at 12 or more (800 runs). So the gap compounds: a class that wins more levels faster. Caveat, as before: the simulator plays spells for casters and a plain dice policy for the others, so part of the gap is the policy; it still says melee classes have no comparable engine in the sim. The warrior's chapter 3 (14%), chapter 5 (11%) and chapters 7 and 8 (9%) are the lowest cells of the table.
4. **Grinding raises level, barely odds.** The maximize-gold goal fights about 50% more (95 attempts a run against 64 to 65), ends at level 12.8 against 10.3 to 10.9 and with 1.7 to 2.3 times the gold, yet wins 39% of attempts against 38% to 40% (800 runs: 37% against 36% to 38%). Two levels buy nothing measurable.
5. **Nine enemies are nearly unbeatable for this character** (share of encounters lost, 800 runs): void archon 96%, hollow court inquisitor 92%, claimant Vane 87%, tear herald 87%, rime bailiff 85% (26 encounters; new since v1.228.0), claimant Tallis 84%, void sovereign 84%, white admiral 82%, bone warden 82%. They are bosses and mini-bosses, so some of that is meant; but the hollow court inquisitor and bone warden are chapter 4 fights, the void stalker (chapter 3) is lost 72% of the time, and the void hound, an ordinary chapter 5 enemy met 3 times a run, is lost 58% of the time (2 633 encounters).
6. **Easy enemies are trivial.** Wreck scavenger, sore loser, den looter and den bouncer: 0 losses in 260 to 446 encounters each (800 runs); harbor rat 4 losses in 1 631, slum thug 6 in 1 004, street bandit 9 in 1 736.
7. **Gold is not spent.** A run ends with 3 100 gold in the median (p90 5 400) and visits 1.2 shops; the late gold sinks exist but the simulated character does not use them, so this measures the simulator's policy as much as the economy.
8. **Alignment goals work.** Favor good ends at +84, favor evil at -48, the others at +20 to +39; the endings do not differ (one ending).

## 9. Not measured here

The Journey map and fight lab changes, ship battles, and the player's own choices of dice faces and loadouts. A human who reads telegraphs and picks faces will do better than this policy, so treat the absolute rates as a floor and the comparisons between classes, chapters and goals as the signal. Nothing in this report proposes a balance change; what to tune is a decision for after reading it.
