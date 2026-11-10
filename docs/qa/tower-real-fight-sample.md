# The Tower bot's headless fight against the real fight screen: a 10-floor sample (v1.864)

QA, round 3 idea 7 (`docs/proposals/qa-ideas-round-3.md`). `test/qa_tower_real_fight_sample_test.dart`, only with `QA_REAL_SAMPLE=<out.json>` (about 3 minutes; `QA_SAMPLE_FLOORS`, `QA_SAMPLE_REAL`, `QA_SAMPLE_SIM`, `QA_SAMPLE_SEED` set the sample).

**What it does.** The Tower's balance batch plays Core's bot on the headless fight (`simulateSimFight`: no affixes, no clan-die resonance, no specialisations). This takes 10 floors the bot died on (spread over floors 1 to 29, seeds 1 to 400), puts the hero as it stood on that floor at full health, and fights the floor two ways: 100 times on the headless fight (the bot's own call), and 6 times on the real `FightScreen` (the floor's foes with their affixes and the Tower's modifiers, the hero's own session), played the naive way: Roll Dice, then Confirm, until the fight ends.

## Result

| Floor | Calling | Foes | Affixes | Headless win | Real win | Health left (headless) | Health left (real, wins) |
|---|---|---|---|---|---|---|---|
| 1 | mage | angel_sentinel | - | 100% | 2 of 6 (33%) | 79% | 21% |
| 8 | mage | angel_sentinel | - | 59% | 1 of 6 (17%) | 43% | 31% |
| 11 | mage | catacomb_ghoul | skittish | 88% | 6 of 6 (100%) | 51% | 36% |
| 13 | mage | catacomb_ghoul | skittish | 52% | 4 of 6 (67%) | 54% | 46% |
| 15 | warrior | hollow_court_inquisitor | frenzied | 70% | 2 of 6 (33%) | 40% | 18% |
| 17 | warrior | drowned_pilgrim | frenzied | 59% | 1 of 6 (17%) | 24% | 14% |
| 17 | warrior | drowned_pilgrim, drowned_pilgrim, catacomb_ghoul | skittish | 3% | 1 of 6 (17%) | 32% | 2% |
| 20 | rogue | claimant_morrow | - | 83% | 3 of 6 (50%) | 52% | 49% |
| 21 | rogue | hollow_reflection, drowned_pilgrim, catacomb_ghoul | armored | 80% | 3 of 6 (50%) | 50% | 56% |
| 29 | mage | drowned_pilgrim, catacomb_ghoul | venomous, frenzied | 84% | 3 of 6 (50%) | 39% | 12% |
**Mean win rate: headless 67.8%, real 43.3% (26 of 60). The mean gap per floor is 33 points** (the headless fight is easier on 7 of 10 floors; harder on 3: floors 11 and 13, the skittish Catacomb Ghoul, and floor 17's pack of three, where the headless fight wins 3% and the real one 1 in 6).

## What this does and does not say

- **The real fights are played naively** (no keeps, rerolls, skill or spell picks, no targeting): they measure what Roll Dice and Confirm win, not what a player wins. The headless fight picks its dice with the engine's own rules. **Floor 1 has no affix and one foe: headless 100%, real 33%**, so most of the gap is the play, not the affixes. The two cannot be separated by this sample.
- Six real fights a floor give about +/- 20 points on each floor (one standard error); the mean over 60 fights is about +/- 6 points.
- The floors are those the bot died on, the hero set to full health there: the sample leans to hard floors for the bot, but its headless win rate there is still 68% (a single try is a coin).
- Health left is the hero's health at the end of a won fight (the session's), as a share of its maximum.
- A boss beaten opens the clans' offer over the fight ("Victory!"): the driver counts that as the win (it first read those as stuck).

## What to take from it

The balance report's figures (floor 20 boss lost by 27% of those who reach it, and so on) are for the headless fight. A real fight, even a naive one, is **harder than the headless one on most of these floors by a wide margin**, and a player who keeps and rerolls plays better than Roll Dice and Confirm: the truth lies between. To pin it down, the real fight needs a driver that plays as the bot decides (the dice's picks and the targets), which is a bigger job and wants Core's view of the bot's rules (`lib/data/tower/tower_bot.dart`, `sim_fight_party_turn.dart`).
