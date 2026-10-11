# Simulation report: 100 playthroughs (v1.228.0)

> Run before the simulator rolled ability checks (1.229.0). With them the attempt win rate is 31% instead of 34%; see section 5 of `report-branches.md` for the updated headline.

Harness: `simulatePlaythroughs` in `lib/screens/playthrough_simulator_screen.dart` (the in-app simulator's walk and fight model, run headless). Seed 7, 100 runs from the first scene to the end, 25 per goal (strategy), professions rotated so every one is played 20 times, race drawn at random. A lost fight is retried up to 3 times, then the walk moves on counting it lost (so reaching the end says nothing about difficulty). "Attempt" = one try at a fight; "encounter" = one fight scene (up to 3 attempts). A 800-run check (seeds 11 and 23, 400 each) gives the same picture; its figures are quoted where they differ by more than 2 points.

What it does **not** cover: quest rewards (not read by the simulator), the Journey map, the fight lab, ship battles on voyages, the player's real choices of dice faces and loadouts.

## 1. Headline

- Ended in a real ending: **100/100** (dead ends: 0, broken links: 0, step cap: 0). All 100 reach chapter 8 and the same ending, "Begin again, changed".
- Fights: 7536 attempts over 3967 encounters (75 attempts and 39.7 encounters per run). **Attempt win rate 34%; encounter win rate 64%** (an encounter is lost after 3 failed attempts). 800-run check: 33% / 64%.
- Level at the end: mean 8.6, p10/p50/p90 = 5/8/13. Gold at the end: mean 2716 (p10/p50/p90 1476/2331/4695).
- Runs with no lost encounter: 0%; runs with 5 or more lost attempts: 99%.

## 2. By goal (strategy)

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| random | 25 | 7.5 | 2043 | 8 | 203 | 67 | 32% | 208 | 11.5 | 1.0 | 20 | 2.8 |
| favorGood | 25 | 7.5 | 1748 | 65 | 203 | 65 | 34% | 195 | 10.8 | 1.1 | 20 | 2.4 |
| favorEvil | 25 | 8.0 | 2443 | -59 | 205 | 68 | 34% | 224 | 11.3 | 1.3 | 21 | 2.7 |
| maximizeGold | 25 | 11.1 | 4628 | -10 | 208 | 102 | 35% | 377 | 11.6 | 0.8 | 28 | 3.4 |

Goal meaning: random picks any open choice; favorGood / favorEvil take the choice that moves alignment up / down; maximizeGold takes the choice that pays most (which also means taking every fight that pays).

## 3. By profession (20 runs each)

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cleric | 20 | 10.2 | 2952 | -1 | 205 | 66 | 45% | 944 | 11.2 | 0.8 | 26 | 2.5 |
| mage | 20 | 10.4 | 2767 | -2 | 205 | 68 | 45% | 308 | 11.3 | 1.2 | 28 | 2.7 |
| ranger | 20 | 7.2 | 2598 | -1 | 207 | 82 | 29% | 0 | 11.3 | 1.1 | 19 | 3.4 |
| rogue | 20 | 8.3 | 2581 | 6 | 205 | 80 | 29% | 3 | 11.6 | 1.1 | 21 | 2.9 |
| warrior | 20 | 6.7 | 2680 | 3 | 202 | 81 | 25% | 0 | 11.2 | 1.0 | 18 | 2.8 |

800-run check, attempt win rate: cleric 43%, mage 45%, ranger 28%, rogue 27%, warrior 27%.

## 4. By race

| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| dwarf | 20 | 9.9 | 2593 | -2 | 206 | 71 | 40% | 200 | 11.3 | 1.3 | 25 | 3.0 |
| elf | 19 | 8.4 | 2564 | 6 | 206 | 75 | 35% | 224 | 11.4 | 1.1 | 22 | 2.6 |
| human | 24 | 7.5 | 2908 | -4 | 203 | 82 | 27% | 245 | 11.0 | 0.8 | 20 | 2.5 |
| orc | 19 | 8.4 | 2782 | 3 | 207 | 70 | 36% | 275 | 11.8 | 1.1 | 22 | 3.2 |
| voidkin | 18 | 8.7 | 2687 | 3 | 203 | 76 | 34% | 319 | 11.2 | 0.9 | 22 | 3.1 |

800-run check: dwarf 36%, elf 36%, human 32%, orc 32%, voidkin 31% (the 100-run spread of 27% to 40% is mostly noise; the profession gap is not).

## 5. By chapter

| chapter | runs | encounters | attempts | attempts/run | encounter win | attempt win | failed attempts/run |
|---|---|---|---|---|---|---|---|
| Chapter 1 | 100 | 396 | 424 | 4.2 | 90% | 84% | 0.7 |
| Chapter 2 | 100 | 772 | 1100 | 11.0 | 94% | 66% | 3.7 |
| Chapter 3 | 100 | 491 | 965 | 9.7 | 66% | 34% | 6.4 |
| Chapter 4 | 100 | 602 | 1178 | 11.8 | 61% | 31% | 8.1 |
| Chapter 5 | 100 | 803 | 1883 | 18.8 | 43% | 18% | 15.4 |
| Chapter 6 | 100 | 411 | 837 | 8.4 | 57% | 28% | 6.0 |
| Chapter 7 | 100 | 139 | 340 | 3.4 | 35% | 14% | 2.9 |
| Chapter 8 | 100 | 353 | 809 | 8.1 | 41% | 18% | 6.6 |

Chapter by goal (attempt win / attempts per run):

| goal | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 |
|---|---|---|---|---|---|---|---|---|
| random | 87% / 3 | 64% / 9 | 32% / 8 | 32% / 11 | 16% / 16 | 27% / 8 | 9% / 3 | 18% / 8 |
| favorGood | 89% / 4 | 72% / 9 | 35% / 8 | 35% / 9 | 17% / 16 | 26% / 8 | 9% / 3 | 14% / 8 |
| favorEvil | 89% / 5 | 65% / 9 | 33% / 9 | 27% / 10 | 17% / 17 | 32% / 8 | 12% / 3 | 21% / 7 |
| maximizeGold | 74% / 5 | 65% / 16 | 34% / 13 | 31% / 17 | 22% / 26 | 28% / 10 | 24% / 4 | 18% / 9 |

Chapter by profession (attempt win):

| profession | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 |
|---|---|---|---|---|---|---|---|---|
| cleric | 86% | 72% | 56% | 45% | 27% | 48% | 15% | 26% |
| mage | 87% | 81% | 61% | 41% | 31% | 34% | 33% | 20% |
| ranger | 79% | 58% | 26% | 24% | 15% | 20% | 9% | 14% |
| rogue | 83% | 55% | 21% | 25% | 15% | 28% | 13% | 21% |
| warrior | 88% | 69% | 19% | 24% | 9% | 15% | 5% | 10% |


## 6. Every enemy met (encounter loss = all 3 attempts failed)

| enemy | first chapter | HP | damage | encounters | lost | loss rate |
|---|---|---|---|---|---|---|
| void_archon | 5 | 380 | 32 | 75 | 73 | 97% |
| hollow_court_inquisitor | 4 | 340 | 33 | 91 | 86 | 95% |
| claimant_vane | 7 | 365 | 33 | 31 | 29 | 94% |
| white_admiral | 6 | 395 | 32 | 79 | 72 | 91% |
| bone_warden | 4 | 320 | 30 | 53 | 48 | 91% |
| void_sovereign | 6 | 390 | 30 | 80 | 72 | 90% |
| tear_herald | 8 | 345 | 27 | 100 | 88 | 88% |
| claimant_tallis | 7 | 300 | 23 | 33 | 27 | 82% |
| aurel_vane | 1 | 165 | 18 | 32 | 26 | 81% |
| void_stalker | 3 | 200 | 23 | 38 | 30 | 79% |
| tear_spawn | 5 | 300 | 28 | 57 | 44 | 77% |
| claimant_morrow | 7 | 390 | 22 | 36 | 27 | 75% |
| void_hound | 5 | 155 | 20 | 314 | 200 | 64% |
| masked_penitent | 5 | 250 | 25 | 55 | 33 | 60% |
| drowned_pilgrim | 5 | 165 | 21 | 89 | 51 | 57% |
| inquisition_penitent | 5 | 260 | 26 | 74 | 39 | 53% |
| void_manifestation | 5 | 165 | 21 | 100 | 48 | 48% |
| unmade_knight | 6 | 175 | 23 | 23 | 11 | 48% |
| hollow_reflection | 6 | 180 | 22 | 213 | 97 | 46% |
| inquisition_high_warden | 3 | 170 | 19 | 100 | 42 | 42% |
| inquisition_soldier | 2 | 150 | 18 | 214 | 73 | 34% |
| iron_golem | 3 | 180 | 21 | 43 | 14 | 33% |
| hollow_court_zealot | 4 | 160 | 20 | 113 | 33 | 29% |
| white_soldier | 1 | 80 | 19 | 48 | 13 | 27% |
| inquisition_auxiliary | 3 | 120 | 14 | 189 | 50 | 26% |
| catacomb_ghoul | 4 | 145 | 18 | 107 | 25 | 23% |
| bone_sexton | 4 | 150 | 19 | 105 | 19 | 18% |
| smuggler_captain | 2 | 135 | 16 | 42 | 5 | 12% |
| void_wisp | 3 | 121 | 14 | 137 | 11 | 8% |
| plague_hound | 2 | 130 | 16 | 149 | 10 | 7% |
| dock_overseer | 2 | 112 | 14 | 118 | 6 | 5% |
| inquisition_warden | 1 | 111 | 17 | 104 | 5 | 5% |
| rat_matriarch | 2 | 150 | 18 | 68 | 2 | 3% |
| cultist_acolyte | 3 | 100 | 11 | 123 | 2 | 2% |
| street_bandit | 1 | 78 | 10 | 219 | 3 | 1% |
| slum_thug | 1 | 56 | 9 | 123 | 1 | 1% |
| harbor_rat | 2 | 62 | 9 | 222 | 0 | 0% |
| wreck_scavenger | 1 | 85 | 12 | 70 | 0 | 0% |
| den_bouncer | 1 | 44 | 8 | 36 | 0 | 0% |
| sore_loser | 1 | 44 | 8 | 32 | 0 | 0% |
| den_looter | 1 | 44 | 8 | 32 | 0 | 0% |

## 7. Distributions across the 100 runs

| measure | min | p10 | median | p90 | max | mean |
|---|---|---|---|---|---|---|
| level | 3 | 5 | 8 | 13 | 18 | 8.6 |
| gold | 944 | 1476 | 2331 | 4695 | 6296 | 2715.8 |
| alignment | -75 | -63 | -1 | 67 | 83 | 1.1 |
| steps | 190 | 194 | 205 | 218 | 224 | 204.8 |
| unique | 129 | 133 | 138 | 145 | 151 | 138.5 |
| encounters | 27 | 30 | 37 | 55 | 63 | 39.8 |
| won | 9 | 14 | 23 | 41 | 54 | 25.5 |
| lost | 4 | 28 | 49 | 79 | 113 | 49.8 |
| casts | 0 | 0 | 0 | 802 | 2017 | 250.9 |
| potions | 3 | 3 | 5 | 9 | 15 | 5.7 |
| quests | 6 | 8 | 11 | 14 | 19 | 11.3 |
| shops | 0 | 0 | 1 | 2 | 4 | 1.0 |
| flags | 116 | 123 | 131 | 139 | 147 | 131.0 |
| signs | 4 | 7 | 12 | 18 | 22 | 12.2 |
| offers | 11 | 13 | 21 | 34 | 43 | 22.1 |
| skills | 0 | 1 | 3 | 5 | 8 | 2.8 |

(`won`/`lost` are attempts won / lost; `steps` scenes walked; `unique` distinct scenes; `signs`, `offers`, `skills`: growth choices taken.)


## 8. What the data says

Numbers are the 100-run figures; the 800-run check agrees within 2 points unless noted.

1. **The story is consistent.** 100/100 runs of all four goals and all five professions reach a real ending through chapter 8; no dead end, no broken link, no step cap (also 800/800). `test/sim_playthroughs_test.dart` now pins this.
2. **Fights are hard, and the wall is chapter 5.** Overall 34% of attempts are won (the previous clash-rules batch of 9 October measured 31%, so no drift). Chapter 1 is 84%, chapter 2 66%, then 34%, 31%, **18% in chapter 5** (18.8 attempts and 15.4 failed attempts per run, the most of any chapter), 28% in chapter 6, 14% in chapter 7, 18% in chapter 8. Chapter 2 was 38% in the 9 October batch: the "lighter Chapter 2 bosses" of 1.216 did that, with 24 attempts per run falling to 11.
3. **Melee classes trail the casters by about 17 points.** Warrior 27%, rogue 27%, ranger 28% against cleric 43% and mage 45% (800 runs; 25% to 29% against 45% in the 100). The casters also end 3 levels higher (10.0 against 7.1 to 7.5), and level matters: attempt win rate is 19% at level 5 or less, 28% at 6 to 8, 40% at 9 to 11, 50% at 12 or more. So the gap compounds: a class that wins more levels faster. Caveat: the simulator plays spells for casters and a plain dice policy for the others, so part of the gap is the policy; it still says melee classes have no comparable engine in the sim.
4. **Grinding raises level, barely odds.** The maximize-gold goal fights 50% more (102 attempts a run against 65 to 68), ends at level 11.1 against 7.5 to 8.0 and with twice the gold, yet wins 35% of attempts against 32% to 34%. Three and a half levels buy about 3 points.
5. **Eight enemies are nearly unbeatable for this character**: void archon 98% of encounters lost, hollow court inquisitor 94%, bone warden 92%, tear herald 92%, white admiral 89%, claimant Vane 89%, void sovereign 88%, claimant Tallis 84%. They are bosses and mini-bosses, so some of that is meant; but the hollow court inquisitor and bone warden are chapter 4 fights at 94% and 92%, and the void hound, an ordinary chapter 5 enemy met 3 times a run, is lost 64% of the time.
6. **Easy enemies are trivial.** Den looter, den bouncer, wreck scavenger and sore loser: 0 losses in 258 to 608 encounters each (slum thug 4 in 980; 800 runs).
7. **Gold is not spent.** A run ends with 2 300 gold in the median (p90 4 700) and visits 1.0 shop; the late gold sinks exist but the simulated character does not use them, so this measures the simulator's policy as much as the economy.
8. **Alignment goals work.** Favor good ends at +65, favor evil at -59, the others near 0; the endings do not differ (one ending).

## 9. Not measured here

Quest rewards (the simulator does not read quests.json, so the 1.226 rescale is not exercised), the Journey map and fight lab changes, ship battles and the player's own choices of dice faces and loadouts. A human who reads telegraphs and picks faces will do better than this policy, so treat the absolute rates as a floor and the comparisons between classes, chapters and goals as the signal.
