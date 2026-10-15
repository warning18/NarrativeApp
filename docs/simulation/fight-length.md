# Fight length: the default rules and the Tide (v1.351)

These rules are from docs/proposals/profession-clan-mechanics.md (v5.2, "Fight length"). They are in lib/combat/fight_length.dart and play in every fight. The live fight runs them in fight_goals.dart, fight_rounds.dart, fight_queries.dart and fight_actions.dart; the simulator runs them in sim_combat.dart.

| Rule | What it does |
|---|---|
| Healing fatigue | Each heal a member gives in a fight heals 5% less than the one before, never under 30%. Spells count. |
| Execute | A foe struck this round and left under 10% of its health falls. Never a boss: its last phase is the fight's. |
| Morale | A hurt foe, under 25% of its health, flees at 50% each round. A fled foe pays part of its spoils, as a Skittish one does. |
| The pack breaks | When a pack's leader falls (its biggest that isn't a boss), each other foe flees at 70%. A Rout keeps its own captain rule. Neither morale nor the pack break plays in a boss's fight: its escort stands by it. |
| The Tide | From round 8, the party's blows grow 20% a round and the enemies' 10%, adding up. In a boss's fight the boss's side grows 18%, so the boss curve (boss_balance_test) holds. For now it covers every fight. The context rules of the place and the foe (step 4 of the proposal) will take its place where they apply. |

**Turning them off.** Each rule can be switched off in the simulator through `clashOff`: `fatigue`, `execute`, `morale`, `packBreak`, `tide`.

## Measured

200 seeded runs (seed 11), 40 per profession, random strategy:

```
FIGHT_LENGTH_RUNS=200 flutter test test/fight_length_test.dart
```

| | Rounds per fight | Fights won |
|---|---|---|
| Without the rules | 16.5 | 54.0% |
| **With the rules** | **10.1** | **53.4%** |

| Profession | Rounds, without → with | Won, without → with |
|---|---|---|
| Cleric | **37.3 → 13.5** | 75.0% → 40.2% |
| Mage | 8.3 → 6.8 | 63.2% → 67.2% |
| Ranger | 13.3 → 10.0 | 47.8% → 60.1% |
| Rogue | 13.4 → 9.9 | 48.4% → 57.9% |
| Warrior | 14.5 → 10.0 | 39.0% → 42.4% |

**What it shows:**
- **Fights come down to about 10 rounds, at today's win rate.** The cleric's fights fall from 37 rounds to 13.5: healing fatigue ends the endless sustain.
- **The bosses keep their curve:**
  - no execute;
  - no flight from their escort;
  - a Tide almost even for both sides.
- **The cleric pays most:** 75% → 40%.
  - Its core, the Watchfire (v1.352: every heal from the die also burns the enemy), is what gives it back its way to win.
  - The warrior (42%) waits on Fury the same way.
- **Next steps:**
  - the profession cores (v1.352) are tuned against these numbers;
  - the context rules (step 4) replace the Tide by place and foe.
