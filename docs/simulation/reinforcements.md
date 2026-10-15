# Reinforcements (v5.2 step 6, PR 3)

The rules are in `lib/combat/context_rules.dart` (`Reinforcement`, `allyStrike`, `foeStrike`) and `lib/data/clan_power.dart` (`reinforcementAt`). The plan is `docs/proposals/territory-power-nemesis.md` §4, deferred from v5.2 step 4; the user asked for "gentle, within +5".

## The rule

- **Where:** in a place a clan holds (`holderOf`: the place's own holder, or its city's).
- **When:** from round 8, each round.
- **Who comes:**
  - **Allies,** when you stand Friend or better with the holder: each foe takes 5% of its max health.
  - **Foes,** when the holder hunts you (Hunted) or is your nemesis: each of the party takes 5% of their max health.
- **Limits:**
  - never in a boss's fight;
  - never the finishing blow (a strike leaves at least 1 health; the execute finishes);
  - on top of the fight's context rule (the Tide, the ground, the watch).
- **The log** says it each round: "The people of the Lantern Dominion join the fight: 9 to each foe."

## Measured

100 runs per cell (seed 11), with the given reinforcement in **every** fight. In play, only fights in held places get them. Each cell is fights won / rounds a fight. `REINFORCE_RUNS=100 flutter test test/reinforcements_test.dart`.

| Profession | None | Allies | Foes |
|---|---|---|---|
| Cleric | 57.6% / 14.4 | 60.5% / 13.9 (+2.9) | 55.6% / 14.2 (−2.0) |
| Mage | 81.9% / 7.0 | 83.2% / 6.9 (+1.3) | 82.5% / 6.9 (+0.6) |
| Ranger | 75.1% / 9.5 | 76.4% / 9.4 (+1.3) | 73.0% / 9.4 (−2.1) |
| Rogue | 74.3% / 9.0 | 73.9% / 8.9 (−0.4) | 71.7% / 9.0 (−2.6) |
| Warrior | 70.2% / 8.0 | 72.6% / 8.0 (+2.4) | 69.1% / 7.9 (−1.1) |

- **Within +5 everywhere:** allies are worth up to +2.9 (the cleric, whose fights run longest) and foes cost up to −2.6.
- The mage's foes cell (+0.6) and the rogue's allies cell (−0.4) are noise. Their fights are mostly over by round 8.
- **2.5% a round was tried first:** allies came to +0.2 to +0.9, too faint to feel. 5% is the proposal's own number. It measured +5 to +21 under v5.2's first rules; with the fight-length defaults now in play it lands inside the band.
- **The boss curve is untouched:** reinforcements never join a boss's fight, and `boss_balance_test` passes unchanged.
