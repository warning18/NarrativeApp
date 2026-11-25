# The Tower's real fights against the bot's numbers (v2.8.1)

QA, asked by the Manager (Core's note: bot 68% against 43% for real play). `test/qa_tower_real_fight_sample_test.dart`, run with `QA_REAL_SAMPLE=<out.json> QA_SAMPLE_PLAY=naive|rerolls|full QA_SAMPLE_FLOORS=12 QA_SAMPLE_REAL=8 QA_SAMPLE_SIM=100`. No `lib/` edit. Raw rows: the three `.json` outputs are in the run's scratch folder; the table below is all of them.

**Method.** 12 floors the bot died on (spread over floors 4 to 30, seeds 1 to 400); the hero as it stood there at full health. Each floor: 100 headless fights (the bot's own) and 8 fights on the real `FightScreen` (the floor's foes, affixes and Tower modifiers) for each of three ways to play:
- **naive**: Roll Dice, then Confirm (what the old sample did, and what Core's 43% is);
- **rerolls**: as naive, and a die that landed empty is rolled again while Reroll is enabled (the bot's base rule);
- **full**: as rerolls, and before each roll it casts the first spell it can pay for.

## Result

| Floor | Calling | Foes | Affixes | Bot (headless) | Real, naive | Real, rerolls | Real, rerolls + spells |
|---|---|---|---|---|---|---|---|
| 4 | mage | inquisition_soldier | - | 92% | 2/8 | 2/8 | **8/8** |
| 10 | mage | inquisition_legate | - | 95% | 0/8 | 0/8 | **7/8** |
| 11 | warrior | bone_sexton | frenzied | 96% | 7/8 | 7/8 | 7/8 |
| 12 | rogue | catacomb_ghoul | armored | 92% | 4/8 | 4/8 | 4/8 |
| 13 | mage | white_soldier | skittish | 98% | 6/8 | 6/8 | 8/8 |
| 15 | mage | knell_keeper | armored | 57% | 1/8 | 1/8 | 3/8 |
| 16 | mage | angel_sentinel | armored | 86% | 0/8 | 0/8 | 6/8 |
| 18 | warrior | drowned_pilgrim, bone_sexton | frenzied | 98% | 6/8 | 6/8 | 6/8 |
| 20 | rogue | claimant_morrow | - | 99% | 7/8 | 7/8 | 7/8 |
| 22 | mage | 2 hollow_reflection, slum_thug | armored, packLeader | 42% | 1/8 | 1/8 | not played |
| 25 | mage | white_admiral | venomous | 93% | 1/8 | 1/8 | **8/8** |
| 30 | warrior | void_sovereign | - | 99% | 7/8 | 7/8 | 7/8 |

| Way | Wins | Rate |
|---|---|---|
| Bot, 12 floors | - | 87.3% (90.5% on the 11 floors below) |
| Real, naive | 42 of 96 | **43.8%** (Core's 43% again) |
| Real, rerolls | 42 of 96 | 43.8% (identical to naive, see below) |
| Real, rerolls + spells (11 floors) | 71 of 88 | **80.7%** |

## What it says

1. **Most of the 68% / 43% gap is the driver, not the game.** Naive play never casts. The 7 mage floors fail 0 to 2 times in 8 naive and win 3 to 8 of 8 once the mage casts (floors 4, 10, 16, 25: from 0-2/8 to 6-8/8). Mage floors, bot against real with spells: 86.8% against 83.3% (40 of 48).
2. **The remaining gap is on non-casters.** Warrior and rogue floors (11, 12, 18, 20, 30; no spell to add): bot 96.8%, real 77.5% (31 of 40). The gap is about 19 points, a smaller but real one. It is largest on floor 12 (rogue, armored catacomb ghoul): bot 92%, real 50%.
3. **Floor 15 (knell_keeper, armored) is hard for both**: bot 57%, real 38% (3 of 8) even with spells.
4. The affix floors (frenzied, armored, skittish, venomous) show no gap beyond the calling's: the affixes do not explain it.

## Limits

- **Rerolls changed nothing**: same counts as naive on every floor, the same seeds. Either the die rarely lands empty here or the check (`Die3D.fx == fizzle`) never fires; I did not chase it. A player who keeps and rerolls weak faces (the bot's `rerollWeakFaces`) is not measured.
- **Floor 22 (three foes) was not played in `full`**: the driver stalls there ("Roll the party's dice, then keep or reroll", no Confirm), probably needing a target pick it does not make. Its naive row (1/8) is not a real-play number.
- 8 fights a floor is about +/-17 points (one standard error) per floor; 96 fights about +/-5 points overall.
- "Full" casts the first affordable spell, not the best one, and never keeps, targets or uses skills or potions. It is still a floor on what a player wins.

## For Core

Calibrate the bot against the **caster-aware** sample, not the naive one: with spells the real mage matches the bot within 3 points; the open gap is warriors and rogues (about 19 points), and floor 12's armored ghoul for the rogue.
