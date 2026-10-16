# The nemesis and the alignment hunters (v5.2 step 6, PR 2)

The rules are in `lib/data/nemesis.dart`, `lib/data/rival_hunters.dart` and `lib/data/alignment_events.dart`. The plan is `docs/proposals/territory-power-nemesis.md` (its addendum, B); the hunters and their lines are Narrative's, from `docs/proposals/territory-texts.md` 5a–5c.

## The rules as built

- **The nemesis.** At most one: the strongest main clan with power 25 or more that you stand Hostile or Hunted with.
  - It rises at a chapter's turn, with a news line, and stays until you climb back to Wary or it falls.
  - **It hunts you, sworn or not,** at the Hunted odds (8% a road at rest), through the rival hunters' roll: the same 15% cap, cooldown, mercy and betrayal.
  - **At war it goes first,** and fights your patron from Hostile (step 3), not only at War.
  - **It offers nothing:** Hostile already does that.
  - **Breaking it** (`breakNemesis`, for its quest in PR 5): it loses a tier of power, the hunt ends, and it can't be your nemesis again for 2 chapters.
- **The alignment hunters for everyone.**
  - **Under ±20:** 2% a road at rest plus 0.2% a point, meeting today's 6% at the border. The side is drawn by the lean, so a character at 0 meets either. Temptations stay.
  - **At ±20 and past:** unchanged (6%, +0.15% a point, up to 15%).
- **Who hunts.**
  - The good orders hunt an Evil character: the Vigil's candle-bearer Ysel, the spearman Halvard (in place of the Inquisition soldier) and the masked penitent, with their battle cries.
  - The evil forces hunt a Good character: the cultist acolyte, the Hollow Court zealot and the void hound (from chapter 5; the void stalker is the Scaffold Yards' boss, so it stays one), at alignment −25 to −35 so a high Perception reads them Evil.
  - The angels and the demons keep their own lines; the six take Narrative's.
  - The six are still met as ordinary foes on the roads (`hunterOnly: false`).
  - Hunters now wait for their own `minChapter`.
- **The order on a road** is as before: a betrayal that is due, the alignment hunters, then the clan hunters (rivals and the nemesis).

## Measured

200 runs (seed 17), `HUNT_RUNS=200 flutter test test/nemesis_test.dart`. The counts are hunters per run, grouped by the run's final alignment. "Nemesis hunters" are hunters of the clan that was the nemesis when they came.

| Final alignment | Runs | Alignment hunters | Clan hunters | Nemesis hunters | Betrayals | All | Runs with a nemesis | Roads at rest |
|---|---|---|---|---|---|---|---|---|
| Neutral (under ±20) | 22 | **1.00** (0 before) | 0.82 | 1.05 | 0.18 | 3.05 | 19 | 60.5 |
| Leaning (±20 to ±49) | 38 | 1.79 (0.68) | 0.66 | 1.11 | 0.32 | 3.87 | 37 | 58.9 |
| Strong (±50 and past) | 140 | 2.43 (2.21) | 0.49 | 0.96 | 0.06 | 3.95 | 127 | 58.3 |

- **Every alignment is hunted:** 3 to 4 hunters a run, out of about 60 roads at rest.
- **Neutral characters,** never hunted before, meet about one alignment hunter a run.
- **The nemesis is nearly always the Dominion:** it is a nemesis in 183 of 200 runs (Dominion 178, Compact 4, Vigil 3, Crows 3, Penitents 2, Mire 1). The story itself drives standing with the Dominion to Hostile or Hunted for nearly everyone not sworn to it.
  - Requiring Hunted instead of Hostile barely changes that: 147 runs with the Dominion as nemesis.
  - This is left for the user to decide (see the PR).
