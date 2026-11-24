# Simulator truth (Wave 5)

What changed in the simulator, why, and what it moved. Measured on v1.1009
(`ce64ede6`), 100 typical (T) + 100 competent (C) runs per seed, seeds 1 and
2, the balance plan (the goals in turn, the professions rotating).

## 1. What was wrong

- **The bot valued a die without its keywords.** `simFaceValue` counted a
  face's type and number only: Pain, Cleave, Pierce, Steady and Growth were
  worth nothing. The Headsman (Cleave, Pain, Steady) was valued 7.77 at
  damage 8, under the starter die's 7.89, so the typical player never rolled
  it, though the competent player's die trials (12 real fights each way) kept
  picking it.
- **The fights never played Growth.** The fight screen adds `growthStep`
  each time a Growth face is played; the simulator's fights did not, so a
  Growth face was a plain face there.
- **Politics events: already fired.** `SimGrowth.runEvents` has fired the
  due events at each scene since v1.915 (about 20 a run). Nothing to do.
  (The v1.998 PR said otherwise; that was wrong.)
- **Batches ran on one core.**

## 2. The keyword values (`lib/data/sim_policy.dart`)

Measured on 100 T + 100 C runs (seed 1), with counters that are not in the
code:

| Measure | Value | Constant |
|---|---|---|
| Other foes standing when the hero strikes | 0.17 | `simCleaveOthers` |
| Share of a strike a guard, a guard's cover and Armored take off | 2% | `simPierceKept` |
| Rounds in a fight | 6.8 | `simFightRounds` |
| Hero max health per point of damage (ch1 7.0 … ch8 6.6) | 6.5 | `simHealthPerDamage` |

A face's worth (`simFaceValue`), keywords counted as the fights play them:

- **Pain:** the blow × 2, less 8% of max health at 0.7 a point (a Heal
  face's rate). The hero's own max health where the caller has it.
- **Cleave:** + the blow × 0.5 × 0.17.
- **Pierce:** + the blow × 0.02.
- **Steady:** + 1 on an Attack, Defend or Heal face's number.
- **Growth:** + the mean gain over a fight: the face is played 6.8 × its
  share of the die's weight; each play after the first is 1 stronger. A d4
  face gains about 0.35; a d12 face (played less than once a fight) nothing.
- **Echo:** counted as the face (it copies another party member's face).

## 3. Growth in the fights (`lib/data/sim_combat/`)

The hero's Growth faces gain `growthStep` per earlier play in the fight
(Attack, Defend and Heal faces, as Steady is applied). Companions' dice play
neither Steady nor Growth in the simulator (unchanged).

## 4. Die values (no skills learned, damage 8)

| Die | Keywords | Before | After |
|---|---|---|---|
| berserker | pain | 10.22 | 12.58 |
| shadow | pierce | 11.60 | 11.68 |
| **headsman** | cleave, pain, steady | **7.77** | **10.34** |
| ossuary | growth, pain | 8.43 | 9.48 |
| lantern | none | 8.72 | 8.72 |
| grosh | pain | 6.88 | 8.70 |
| tally | growth (d12) | 8.50 | 8.50 |
| court | pierce | 8.45 | 8.49 |
| cinder | pierce, steady | 8.15 | 8.30 |
| starter | none | 7.89 | 7.89 |
| tearglass | pain, pierce | 6.00 | 6.41 |
| greenwood | growth ×4 (d12) | 4.78 | 4.78 |

Pain is the keyword that moves values: it doubles the blow for about a third
of a blow's worth in health.

## 5. Before → after (same main, seeds 1 and 2)

| | T seed 1 | T seed 2 | C seed 1 | C seed 2 |
|---|---|---|---|---|
| Fight win % | 92.1 → 93.1 | 91.9 → 93.4 | 94.9 → 95.8 | 94.0 → 95.2 |
| Tear Herald beaten | 88 → 93 | 87 → 92 | 93 → 93 | 89 → 92 |
| Runs reaching an ending | 100 → 100 | 100 → 100 | 100 → 100 | 100 → 100 |
| C die trials passed (the valuation agrees with real fights) | — | — | 40.5% → 45.1% | 38.3% → 43.8% |

**Final die (runs ending on it):**

| Die | T s1 | T s2 | C s1 | C s2 |
|---|---|---|---|---|
| **headsman** | 4 → **76** | 0 → **78** | 1 → **31** | 2 → **35** |
| shadow | 18 → 16 | 18 → 15 | 17 → 14 | 15 → 12 |
| starter | 21 → 0 | 27 → 0 | 16 → 6 | 19 → 7 |
| court (clan) | 9 → 0 | 10 → 0 | 17 → 9 | 20 → 10 |
| cinder (clan) | 6 → 0 | 10 → 0 | 9 → 5 | 13 → 6 |
| ossuary (clan) | 12 → 2 | 2 → 0 | 1 → 6 | 1 → 4 |
| tally (clan) | 5 → 0 | 8 → 0 | 4 → 1 | 0 → 0 |
| lantern (clan) | 3 → 0 | 9 → 0 | 3 → 2 | 1 → 0 |
| berserker | 5 → 6 | 2 → 5 | 7 → 8 | 8 → 10 |

**Reading it.**
- The competent player's trials (12 real fights with each die) agree with the
  new values about 5 points more often: the values are truer.
- The Headsman really is strong. Valued as it fights, it becomes the typical
  player's die in three runs of four, and a third of the competent player's.
  The clan dice lose their place to it.
- That is a balance question, not a simulator one: **the Headsman (180 gold,
  any profession) may be too strong** now that the simulator sees it. The
  user's open question on the Headsman stands; these numbers are its evidence.

## 6. Batches on several cores

`simulatePlaythroughs(firstRun:)` numbers a plan's runs from `firstRun`, so a
batch split in slices plays exactly the runs it would in one piece.
`test/sim_batch_test.dart` runs the balance batch in isolates side by side
(skipped unless `SIM_BATCH_OUT` is set) and checks, always, that two slices
equal the batch in one piece:

```
SIM_BATCH_OUT=/tmp/batch.json SIM_BATCH_RUNS=100 SIM_BATCH_SEED=1 \
SIM_BATCH_POLICY=typical,competent SIM_BATCH_CORES=4 \
flutter test test/sim_batch_test.dart
```

100 typical runs: 21.2 s on one core, 7.9 s on four (2.7×), the same runs.
