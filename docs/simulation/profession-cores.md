# The professions' cores (v1.352)

These are from docs/proposals/profession-clan-mechanics.md (v5.2). The rules are in `lib/combat/profession_cores.dart`. The hero plays their profession's core, in the live fight (fight_dice_rules.dart, fight_rounds.dart, fight_actions.dart, fight_rewards.dart) and in the simulator (sim_combat.dart). Companions keep their dice as they are.

| Profession | Core | What it does |
|---|---|---|
| Warrior | **Fury** | Each hit landed, and each blow that gets through, adds 1 Fury. At 5, the next damaging face is a heavy blow worth ×2.5, and it spends all of it. |
| Cleric | **The Watchfire** | Every heal from the die also burns the enemy for twice its amount. Healing past full feeds a fire (up to half your max health) that takes blows first; what is left at the round's turn burns the first enemy standing for ×2. The cleric's heals don't tire: healing fatigue is the Watchfire's to answer. |
| Mage | **The Ash Well** | The well starts each fight empty. Mana from the die comes double. Spells cost 1 less (never under 1). Mana left after a win heals 2% of your max health a point. |
| Rogue | **Flurry** | A damaging face strikes twice at 55% each, each strike rolling its own critical. |
| Ranger | **The Trail** | The die is a deck: each run deals 5 of its 6 faces, one sitting out at random, and none comes twice. The ranger sees the next face (the fight log names it). |

**Turning them off.** In the simulator, `clashOff: {'cores'}` leaves the cores out.

## Measured

200 seeded runs (seed 11), 40 per profession, random strategy, with the fight-length rules and the Tide on:

```
CORES_RUNS=200 flutter test test/profession_cores_test.dart
```

| Profession | Won, without core → with | Rounds per fight |
|---|---|---|
| Cleric | 39.5% → **52.9%** | 13.5 → 14.0 |
| Mage | 66.4% → **72.0%** | 6.9 → 6.9 |
| Ranger | 59.2% → **65.4%** | 10.2 → 9.8 |
| Rogue | 56.2% → **63.6%** | 10.0 → 9.9 |
| Warrior | 42.4% → **63.2%** | 10.0 → 9.4 |

**What it shows:**
- **The spread between professions narrows.** Today it is 37 points (warrior 37% to cleric 74%). With the rules and the cores it is 19 points (cleric 53% to mage 72%). Every profession fights 7 to 14 rounds.
- **The cleric stays the lowest.** Healing fatigue and the Tide take its old endless fights away. Its specialisations (step 2: Long Vigil, Ember Sister, Lantern Cantor) are where it gains next.

## Rebalanced alongside

The cores make every hero stronger, so these enemies were raised to keep the boss curve (boss_balance_test: every boss within its target, mean 50.5%) and the chapter-1 chain (chapter_one_fights_test):

| Enemy | Was | Now |
|---|---|---|
| void_archon (ch5) health | 282 | 330 |
| claimant_vane (ch7) health | 317 | 370 |
| claimant_tallis (ch7) health | 248 | 380 |
| claimant_morrow (ch7) health | 398 | 560 |
| white_soldier damage (ch1) | 19 | 21 |
