# The context rules (v5.2 step 4)

A fight now plays **one rule from its place**, on top of the default rules (healing fatigue, execute, morale, the pack breaks) and **on top of the Tide**, which rises under every rule from round 8. The rules are in `lib/combat/context_rules.dart`, and the live fight and the simulator play them alike.

| Rule | Where | What it does |
|---|---|---|
| Marsh mist | reeds (fens, marshes) | From round 6, both sides lose 1% of max health per level, each round. It never finishes anyone. |
| Desert heat | dunes, salt flats | The same drain, and healing is cut 20%. |
| Rising water / collapse | waves, cliffs, halls | From round 8 (the Tide's): the party strikes and heals +10% per level, the enemies strike +5% per level, up to 3 levels. |
| Sanctified ground | places tagged holy | From round 6: heals fade 10% per level, and Light strikes 10% harder per level. |
| Town guards | city, town and district places | At round 6 the watch breaks the fight up. The side ahead on health share wins it (the foes scatter). Otherwise both walk away: nothing won, nothing lost. |
| The Tide alone | everywhere else, and every boss fight | As before. A boss's fight keeps the Tide's own boss step, said in the log as "the boss grows enraged". |

- **The fight log:** an omen the round before each rule rises, then a line each round as it grows.
- **The fight screen's marks:** UX's.
- **Test fights and the tutorial:** keep the Tide alone.

## Measured

- **Setup:** `CONTEXT_RUNS=60 flutter test test/context_rules_test.dart`, with each rule played in every fight: 60 seeded runs per cell, random strategy, the cores and every rule of the fight-length family on.
- **Cells:** fights won % / rounds a fight.
- **Town guards:** not measured, because the simulator has no cities.

| | Tide alone | Marsh mist | Desert heat | Rising water | Sanctified |
|---|---|---|---|---|---|
| Cleric | 55.9 / 14.0 | 66.9 / 12.4 | 69.7 / 12.4 | 57.7 / 13.2 | 59.4 / 13.9 |
| Mage | 74.6 / 7.1 | 78.4 / 6.8 | 78.5 / 6.8 | 78.3 / 6.9 | 76.3 / 7.0 |
| Ranger | 75.1 / 9.4 | 77.4 / 8.6 | 75.9 / 8.6 | 79.7 / 9.0 | 76.0 / 9.3 |
| Rogue | 72.0 / 9.0 | 75.4 / 8.3 | 74.6 / 8.4 | 73.6 / 8.6 | 74.2 / 8.5 |
| Warrior | 68.5 / 8.0 | 69.9 / 7.4 | 70.7 / 7.6 | 69.1 / 7.7 | 68.4 / 7.6 |

- **Every profession fights 7 to 14 rounds** under every rule. Most rules shorten fights a little.
- **No cell falls under 55%.**
- **The places favour professions differently:** the marsh and the desert help a healer (cleric +11 to +14), and the other rules move every profession by −0 to +5.

## How it got here

- **Replacing the Tide (first try).** Each rule replaced the Tide instead of adding to it. Enemies stopped escalating, and the cleric's healing won 95% in the mist or the heat; on holy ground its fights ran 24 rounds.
- **Rising water, first version.** As first designed (both sides +10% a level from round 6, no cap), it took the cleric to 47%. The manager asked for no cell under about 55%. The water now starts with the Tide, stops at +30%, gives the enemies half of it, and lifts heals too: 57.7%.
- **Boss enrage, dropped.** On its own (a boss +50% from round 10, in place of the Tide's boss step), it made boss fights 21 rounds long and cost every profession 5 to 14 points. The Tide's boss step (+18% a round) already is the enrage.

## Deferred

- **Reinforcements in clan-held zones:** they need territory, which is step 6.
- **Beasts tire and the dead crumble:** they need a kind for each foe, proposed for Narrative in `docs/proposals/foe-kinds.md`. They come after step 5.
