# The five deadliest story fights, played for real (v1.940)

QA, on main v1.940. Core's request (#8 of the difficulty review, "measure a
real player"): play the five deadliest story fights on the REAL fight screen,
with the "typical" heroes of `docs/simulation/typical-player-builds.json`
(`claude/core-typical`, #1017), N = 12 runs a fight, and report wins, median
rounds and how each ended. Driver: `test/qa_five_fights_test.dart` (inert
unless `QA_FIVE=<folder>`). Raw rows: `five-fights-1.940/five-fights.json`.

## The numbers

The build played is the file's `mostCommonProfession` of each fight. A run
loads the build's `save` with `PlayerSession.fromJson`, opens `FightScreen`
on the fight's foes in the build's chapter, and plays with `Random(1000 * id
+ run)` for the dice: each run can be played again alone.

| fight | foes | hero | won of 12 | lost | median rounds (won / lost) |
|---|---|---|---|---|---|
| 3200 (ch 3) | inquisition soldier + auxiliary | mage | **8** | 4 | 7 / 4 |
| 5100 (ch 4) | drowned pilgrim x2 | warrior | **12** | 0 | 5 / - |
| 6200 (ch 5) | void hound x2 | rogue | **5** | 7 | 10 / 9 |
| 7002 (ch 6) | hollow reflection x2 | warrior | **12** | 0 | 3 / - |
| 7810 (ch 8) | tear herald | warrior | **10** | 2 | 12 / 12 |

Every row is a LOWER bound on the player: the dice are played in the most
basic way (roll, confirm: no rerolls, no choosing of faces, no spells), the
potions are not drunk, and a pick or an offer after a win is the first one.
It is the fight of "a player who does not think", with a typical hero.

## What it can and cannot say

- **It says the fight can be won, and how fast.** 6200 is the only fight a
  basic player loses more often than not (7 of 12): the void hounds are the
  hardest of the five on this hero (12 rounds a fight, 270 health each).
  3200 is a coin with a lean (8 of 12), its losses come early (a median of 4
  rounds: the hero falls first while both allies are up, the soldier and the
  auxiliary hit hard together).
- **It does NOT say how often the story's player dies there.** The driver
  opens the fight on the foes and the chapter only: the scene's place, zone,
  anomaly, goal and every other modifier a story scene adds are NOT set, so
  7002 (3 rounds, 12 of 12) and 5100 (12 of 12) are very likely easier than
  the same scenes in the game. The 1.932 review's naive-player runs lose 5100
  about half the time (31 of 61) and 7002 about half (46 of 87); this driver
  loses neither once. That gap is the modifiers and the hero's "typical"
  gear, not a better player: do not read 12 of 12 as "the fight is easy".
  The honest use: compare the same fight before and after a change to the
  data, on the same seeds.
- **N = 12 is small.** A share of 8 of 12 is 67% with a standard error of
  about 14 points; only the gaps (5100 and 7002 at 12, 6200 at 5) are firm.
  A fight near half (6200) would want N = 30 (about 8 minutes).

## Findings

| # | what | where | severity | owner |
|---|---|---|---|---|
| 1 | 21 of the 25 saves of `typical-player-builds.json` could not load (`diceSkillAssignments` flat, the session wants it nested under the die) | the builds file / exporter | Medium (blocked this check) | Core: fixed in #1023; my driver nests the map itself, so the numbers above do not depend on it |
| 2 | Core's list of foes for 7002 is two hollow reflections; the review names `7002:hollow_reflection` as one fight | the builds file | Info | Core to confirm |
| 3 | After a win the screen can hold a level-up dialog (stat pick, "pop-up only closes once none are left") and then the clans' offer: both need answering before Return works, by design; the driver answers them | fight end | Info | none |
| 4 | A lost fight's button reads "Retreat" in the story and "Face what comes" in the Tower | fight end | Info | none |

## The driver

`QA_FIVE=<folder> flutter test test/qa_five_fights_test.dart` (variables in
its header: `QA_FIVE_BUILDS`, `QA_FIVE_N`, `QA_FIVE_IDS`, `QA_FIVE_PROF`).
It writes `five-fights.json` after each fight and a picture of any run that
stays stuck. About 7 minutes for 60 fights.
