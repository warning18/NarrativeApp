# Dice swapped per fight (measured)

Follow-up to proposal 1 of `combinations-review.md` (row A8).

## What changed in the simulator

`simulatePlaythroughs(..., swapDiePerFight: true)` makes the hero hold,
before each fight try, the owned die that fits the foes best, as the fight
setup screen lets a player do (`SimCharacter.holdDieAgainst`,
`lib/data/sim_combat.dart`):

- Candidates: the die in play, plus every owned die with a striking face
  (Attack or Skill) whose element some foe is `weakTo`.
- Each is scored with `simDieValueAgainst` (`lib/data/sim_policy.dart`):
  `simDieValue` with each striking face times its element's mean multiplier
  over the foes (x3 weak, x0.5 resisted).
- The best one is rolled for that try only; the policy's die comes back
  after. If no owned die matches, the die in play is kept.
- Only the hero swaps. Companions have one signature die each.

The flag is off by default, so every guard and CI band is unchanged.
`onFightDie` reports each try (die, rounds, won, match, swap) for
measuring.

## Batch

**DS977**: v1.977.0 (main c60f21b5), seeds 1..100, one run per seed, the
25 race x profession pairs x 4 goals (the B976 plan, see
`difficulty-review-1.914/story_runs_test.dart.txt`). Typical (T) and
competent (C) policies, swap off and on: 4 x 100 runs. Throwaway harness
`test/zz_dieswap_test.dart`, now deleted. "Fights" means fight tries,
retries counted, as in B976.

## Results (DS977)

| | T off | T on | C off | C on |
|---|---|---|---|---|
| Runs that reach an ending | 100 | 100 | 100 | 100 |
| Fight win %, whole run | 93.0 | 95.2 | 93.8 | 95.8 |
| Fight win %, chapter 8 | 78.5 | 85.6 | 80.5 | 86.8 |
| Tear Herald tries won % | 62.9 (143 tries) | 79.7 (123) | 66.4 (137) | 76.4 (123) |
| Runs that beat the Tear Herald | 90 | 98 | 91 | 94 |
| Mean rounds per fight | 6.86 | 6.57 | 6.56 | 6.36 |
| Mean rounds, Tear Herald | 12.82 | 11.19 | 11.85 | 11.33 |
| Fights where an owned die hits a weakness | 40.5% | 39.2% | 32.4% | 30.0% |
| ... in chapter 8 | 54.2% | 49.7% | 43.1% | 39.8% |
| ... at the Tear Herald | 72.0% | 65.0% | 52.6% | 48.8% |
| Fights where a swap happened | 0 | 28.4% | 0 | 13.4% |
| ... in chapter 8 / at the Tear Herald | 0 / 0 | 43.1% / 54.5% | 0 / 0 | 23.6% / 28.5% |

Chapters 1 to 3 do not move. The gain is in chapters 4 to 8: T ch5
91.1 to 94.4, ch6 90.5 to 93.6, ch7 90.2 to 94.7; C ch6 90.4 to 95.5.

**Swapped fights, same foes.** Over the 2196 T fights where a swap
happened, the same foes took 7.30 rounds with the swap off and 6.46 with
it on (C: 1003 fights, 7.13 to 6.60). Wins in 2 rounds or fewer: 4.8% of
swapped T fights, against 5.5% of matched fights with the swap off (C 5.0%
against 7.8%). No foe becomes trivial.

**Dice swapped to (T).** `vigil_die` 1412 (6 of 8 faces Light),
`cinder_die` 397, `apprentice_die` 152, `court_die` 80, `ossuary_die` 42,
`lantern_die` 32. C: `vigil_die` 387, `cinder_die` 240, `apprentice_die` 110,
`starter_die` 90.

### Per profession (DS977)

| Profession | T fight win off / on | T swapped | C fight win off / on | C swapped |
|---|---|---|---|---|
| Cleric | 95.4 / 96.5 | 31% | 91.0 / 94.5 | 14% |
| Mage | 86.0 / 90.8 | 27% | 91.8 / 94.7 | 19% |
| Ranger | 96.4 / 96.4 | 23% | 95.6 / 96.4 | 15% |
| Rogue | 93.0 / 95.6 | 30% | 91.7 / 94.3 | 13% |
| Warrior | 94.8 / 97.0 | 31% | 99.0 / 99.2 | 6% |

The mage gains most (T +4.8). The rogue gains too (T +2.6), so proposal 10
(rogue against the ch8 bosses) matters less once players swap.

## Verdict on x3

Not too strong. Swapping lifts chapter 8 by about 7 points of fight win
and the Tear Herald by 10 to 17, but swapped fights are only 7 to 12%
shorter and none become a walkover. A die carries the weak element on a
few faces only, and Defend, Heal and guard dilute it. The x3 is a fair
reward for reading the foe.

## Duo-eligible parties (DS977, swap off)

Parties are the active companions before each fight. "Today's list" is
`duoTechniques` (`lib/combat/duo_techniques.dart`, 9 pairs); "+2" adds
Kelda+Maren and Maren+Sable.

| | T | C |
|---|---|---|
| At the Tear Herald, today's list | 14 | 12 |
| At the Tear Herald, +2 pairs | 79 | 76 |
| At any point of the run, today's list | 24 | 24 |
| At any point of the run, +2 pairs | 95 | 94 |
| At the Tear Herald, both at approval 5+ (friendly), today | 11 | 8 |
| At the Tear Herald, both at approval 5+, +2 pairs | 71 | 66 |

This confirms the review's "14% to 79%" (B976: 14 T, 11 C). Approval is
easy to read: the run save the walk builds (`simSessionSave`) gives each
companion's approval, and with the friendly check about 9 runs in 10 of
those parties still qualify. With the swap on the counts move by 1 to 3
runs (noise).
