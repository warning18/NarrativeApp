# Core: improvement ideas, round 4

Core's fourth round (the manager's brief of 2026-11-10): new items only, in
Core's scope (rules, numbers, state, Journey, the simulator), with removing,
simplifying and optimizing first. Nothing here repeats `core-improvements.md`
(P1–P6, R1–R5, B1–B4), `core-improvements-2.md` (N1–N11),
`cleanup-improvements.md`, `core-ideas-round-3.md` (1–6), or anything merged
or held.

Measured on main at 8321e8bb (v1.875), with `boss_balance_test`'s batch
(400 runs, seed 7) unless a line says otherwise.

## Ranked

| # | Idea | Kind | Size | Risk | What the user would notice |
|---|---|---|---|---|---|
| 1 | The simulator fights on the ground the fight screen picks | simplify | M | medium | nothing in play; the simulator's numbers describe the fights they play |
| 2 | Find where the story simulator spends 86% of its time | optimize | M | low | nothing (every simulator test in CI runs faster) |
| 3 | Close the mage's lead | number | S | low | the mage stops being the easy pick (about 5 points less likely to win an encounter) |
| 4 | A profession spread guard that can fail | simplify | S | low | nothing |
| 5 | Split `_simulate` (1,925 lines, one function) | simplify | M | medium | nothing |

My recommendation is 1, then 3 and 4 together (one balance PR, measured on
the simulator that item 1 made truthful), then 2 and 5 together (the split
gives the profile its names).

## 1. The simulator fights on the ground the fight screen picks (M, medium)

**What.** On the fight screen, `fight_ground.dart` picks each fight's ground
from its place:

- the town watch in a city;
- the sanctified ground in a holy place;
- the desert heat on dunes and salt flats;
- the rising water on the waves, cliffs, a ship's deck or in a hall;
- the marsh mist in the reeds;
- the Tide anywhere else, and in every boss fight.

The story simulator never picks one. `sim_fight_setup.dart` sets
`ctx = context ?? ContextRule.tide`, and no caller passes a `context`.

The idea is to move the screen's two private helpers, `_stageHere` and
`_contextRuleHere`, into one pure function in `lib/combat/`, for example
`fightGroundAt(geography, node, {forcedStage, bossFight})`. It would
return the stage and the rule. The screen and the simulator would both call
it; the simulator already has the geography and the node
(`geography.placeOfNode(node)` is all the screen uses).

**Why.**

- **Measured:** in the 400-run batch, all 46,063 fights and all 454,000
  heals were on the Tide. The Tide's heal rule changes nothing, so the
  grounds' heal rules never ran there.
- This is why #869 (the Cleric's spell takes the ground's rule) left the
  batch identical to the decimal. The fix was right, but the simulator has
  no ground to apply it to.
- The grounds do more than heal. The desert and the sanctified ground cut
  healing as the fight goes on, the rising water strengthens late blows,
  and the mist and heat tick damage. None of that is in any balance number
  today.
- One function instead of two copies is the same lesson as round 3's
  healing rule.

**Size and risk.**

- M: the new function and its table test, the screen's two helpers
  replaced, and the simulator passing `context:`.
- Medium risk: the ordinary encounters' win rates will move. The healers on
  desert and holy ground will lose a little, and the warriors on rising
  water will gain a little.
- The boss curve shouldn't move: a boss fight is always the Tide. Re-run
  the boss bands and the spread anyway, and report before and after.

**The user notices:** nothing in play. The balance numbers stop
describing a game without grounds.

## 2. Find where the story simulator spends 86% of its time (M, low)

**What.** The 400-run batch takes 64.9 s in `simulatePlaythroughs`, but its
46,063 fights take only 9.1 s of that (14%). The other 56 s, about 140 ms
per run, is the walk: offers, story nodes, detours, roads, camps and quests.

I haven't found the hot spot. `_simulate` is one function of 1,925 lines
(see item 5), so a stopwatch split needs it cut first. The idea is to:

- profile one batch;
- fix the top one or two costs;
- show the runs are byte-identical, the same check as the Tower hero copy
  (#878: 300 runs compared with `cmp`).

**Why.**

- Twenty-two test files run the story simulator, `boss_balance_test` alone
  for a minute. Every CI build pays that cost four runners wide.
- My balance measures (three seeds × 400 runs) take several minutes each.

**Size and risk.**

- M, until the profile says otherwise.
- Low risk: a byte-identical check proves the results haven't changed.

**The user notices:** nothing. CI runs faster.

## 3. Close the mage's lead (S, low)

**What.** Encounter win by profession, in the 400-run batch:

| Profession | Win rate | Standard error |
|---|---|---|
| Mage | 82.1% | 1.2 |
| Rogue | 77.1% | 1.4 |
| Cleric | 74.9% | 1.5 |
| Ranger | 74.0% | 1.3 |
| Warrior | 72.4% | 1.5 |

The spread is 9.7 points, above QA's limit of 8. The mage has led since the
1.696 L3 (7.9 points then). Its edge is its spells, not its sheet: it starts
with 5 HP less than the base. The idea is one mage number, chosen on three
seeds:

- its spell damage step;
- or its mana at the start;
- or its first training path's order.

**Why.** The mage is the profession a new player is most likely to find too
easy, and the gap has held for 180 versions.

**Size and risk.**

- S: one number in `professions.json` or `training_paths.json`.
- Low risk: the boss bands and the spread guard measure it.
- Best done after item 1, since the grounds move the healers and the
  warriors.

**The user notices:** the mage wins about 5 points less often.

## 4. A profession spread guard that can fail (S, low)

**What.** `boss_balance_test` allows a spread of 8 points plus three
standard errors of the gap: 8 + 5.8 = 13.8 in today's batch. That's why
the 9.7-point spread above passes. The test can only fail at a gap 1.7
times its own limit.

The idea, once item 3 brings the spread under 8, is:

- allow two standard errors (3.9) instead of three;
- or pool seed 7 with a second seed, which halves the noise but doubles the
  test's time;
- either way, print the spread and the allowance in the test's output.

I recommend two standard errors: it costs nothing.

**Why.** A guard that passes at 9.7 when its limit is 8 tells nobody
anything.

**Size and risk.**

- S: one line of `boss_balance_test.dart`.
- Low risk: at two standard errors, a story PR that shifts the seeded
  stream fails it about one time in 40, against one in 700 now. If that
  proves noisy, go back to three.

**The user notices:** nothing.

## 5. Split `_simulate` (M, medium)

**What.** `lib/screens/playthrough_simulator/sim_engine.dart`'s `_simulate`
runs from line 505 to line 2,430, as one function with nested closures:

- the choice loop;
- the challenge loop;
- the shops;
- the roads;
- the run's finish.

The idea is to cut it into a `_SimWalk` class with one method per stage,
the way N10 cut `_settleFight`. The run's state becomes fields instead of
captured locals.

**Why.**

- Item 2 needs names to profile.
- Every simulator change (the companions, the die trial, the heals) has
  had to find its place in 1,900 lines.

**Size and risk.**

- M: a mechanical move, but a large one.
- Medium risk, guarded the same way as item 2: the 400 runs must stay
  byte-identical.

**The user notices:** nothing.

## Looked at and dropped

- **A shared baseline batch for the simulator's on/off tests.** Eight test
  files run a seed-11 batch with one rule on and off. Each test file runs
  in its own process, so an in-memory cache can't share a batch between
  them. The suite's speed is QA's area.
- **Battlefield conditions and field anomalies in the simulator.** The
  simulator leaves them out on purpose (`sim_combat.dart`'s header: no
  affixes, Elites or battlefield conditions). Item 1 is the ground's rule
  only, which applies to every fight.
- **Merging `ship_battle.dart` (2,105 lines) and `ship_combat.dart`
  (1,188).** Both are in use. One holds the room rules and the other the
  battle around them, a layering that holds.
- **Dead public symbols in Core's folders.** A scan found many symbols used
  only inside their own file, but that isn't dead code, and R4's four
  batches already removed the dead ones.
