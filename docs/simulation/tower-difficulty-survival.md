# Tower: a survival climb (proposal, rules 2 only)

Core's proposal for the user's request: "the improvements should be small;
for example almost all of the 1st to the 4th enemy are one-shotted.
Furthermore the player gains 2 levels too quickly. Make it like a roguelike
survival: the user should struggle from the beginning and difficulty
increases going higher. Since he may improve his character from the marks,
it should be really hard to finish on first try and even to reach the 2nd
boss."

Nothing is built. The knobs were tried in a scratch worktree; the code is
kept as a patch for the code PR: `docs/simulation/tower-difficulty-survival.patch`
(`lib/data/tower/` only, every change behind `rules >= 2`). Numbers: Core's
bot (`playTowerRun`), seeds 1 to 2000, floor events 2, no perk, the bot's
full coins, from main v2.10.26 (7818c043).

## Recommendation

Ship the knobs below together. The XP change alone makes the Tower much
**easier** (top with no unlocks 13.9% to 54%): the foes grow with the hero's
level (`enemyScaledMaxHealth` +16% health a level, `scaledDamage` +8%), and a
Level Up card gives less than that. So the slower levels and the new foe
curve only work as one change.

| Knob (file) | Before | After |
|---|---|---|
| Tower XP at the start, `towerXpStart` (tower_levelup_loot.dart) | 2 | **0** |
| XP a level, `towerXpPerLevel` + new `towerXpGrowthEvery`, `towerXpCostOf` | 4 flat | **5, 6, 6, 7, 7, 8, 8 ...** (+1 every 2 levels) |
| Nudge caps, `towerNudgeStatCap` / `towerNudgeClimbCap` | 4 / 10 | **3 / 6** |
| Loot tier shift by band, `towerLootTierShift` | 0 / +1 / +2 | **0 / 0 / +1** |
| Recovery after a floor, new `towerLootRecoveryShare(Of)` (tower_tables.dart) | 15% (Heat 3+: 5%) | **10%** (Heat 3+: 5%, unchanged) |
| Foe curve by floor, new `towerSurvivalScale` (in `towerRulesScaleOf`, now given the floor) | 1 | f1 **3.0**, f2 **4.2**, f3 **4.5**, f4 **3.0**, f5 warden **2.1**, f6-9 **2.1**, f10 boss **1.8**, f11-14 **1.5**, f15 warden **1.6**, f16-19 **1.53**, f20 boss **1.78**, f21-24 **1.56**, f25 warden **1.66**, f26-29 **1.56**, f30 boss **1.75** (on top of `towerLootFoeScale` 0.85, kept) |
| Calling pass, `towerLootProfessionScale` | cleric 1.05, ranger 1.02, rogue 0.97 | cleric **0.95**, ranger **0.96**, rogue **0.93**, mage **0.96**, warrior **1.04** |
| Calling pass from floor 10, new `towerLootProfessionUpperScale` | none | warrior **0.90**, mage **1.04** |
| Health an unlock gives, new `towerLootHealthPerUnlockScale` × `towerHealthPerUnlockOf` (`towerHealthPerUnlockFor`, tower_hero.dart / tower_run.dart pass the rules) | 3% (dwarf 1.5%, elf 1%) | **×5.33**: 16% (dwarf 8%, elf 5.3%) |
| ... its calling share, new `towerLootProfessionHealthPerUnlock` | none | cleric **0.90**, rogue **0.75**, mage **1.15**, warrior **0.85** |

Unchanged: the XP a floor pays (2 / 3 / 4), the Level Up table, the loot
weights and purses, the flask, the potions per 5 unlocks, Heat, perks,
the floors' extras and budgets, every rules-1 number.

## Reach and win per band (Heat 0)

"reach / beat": share of climbs that reach the floor / get past it (f30:
win the top).

| | f5 | f10 (1st boss) | f15 | f20 (2nd boss) | f25 | f30 (top) | median floor |
|---|---|---|---|---|---|---|---|
| Target, no unlocks | | ~30 / ~15 | | ~3 | | < 0.5 won | |
| No unlocks, before | 99.7 / 99.5 | 93.8 / 89.9 | 73.8 / 69.0 | 50.1 / 44.0 | 33.5 / 29.3 | 21.1 / **13.9** | 20 |
| No unlocks, after | 76.2 / 66.5 | **29.2 / 17.2** | 9.8 / 8.4 | **4.2** / 2.2 | 1.1 / 0.8 | 0.4 / **0.1** | 8 |
| Target, every unlock | | | | | | ~10 won | |
| Every unlock, before | 99.9 / 99.9 | 96.8 / 96.0 | 83.2 / 79.5 | 62.0 / 56.3 | 46.6 / 42.1 | 33.2 / **22.7** | 23 |
| Every unlock, after | 98.8 / 98.3 | 81.5 / 73.0 | 64.2 / 57.2 | 45.0 / 34.0 | 27.2 / 22.9 | 18.9 / **10.5** | 18 |

Heat 3:

| | f5 | f10 | f15 | f20 | f25 | f30 | median |
|---|---|---|---|---|---|---|---|
| No unlocks, before | 99.5 / 98.8 | 89.6 / 78.8 | 58.4 / 52.9 | 33.5 / 25.9 | 17.8 / 14.6 | 9.4 / **4.8** | 16 |
| No unlocks, after | 71.5 / 55.4 | 20.9 / 9.5 | 5.4 / 4.0 | 1.5 / 0.8 | 0.6 / 0.3 | 0.2 / **0.1** | 6 |
| Every unlock, before | 99.9 / 99.8 | 95.9 / 91.5 | 75.2 / 69.4 | 50.0 / 39.9 | 30.8 / 26.6 | 19.4 / **11.1** | 20 |
| Every unlock, after | 98.3 / 97.1 | 76.0 / 58.8 | 48.5 / 41.8 | 30.4 / 20.5 | 15.4 / 12.2 | 9.2 / **5.0** | 14 |

Heat 3 still halves the top with every unlock, as today (22.7 to 11.1
before, 10.5 to 5.0 after).

Deaths per fight by band (no unlocks; a fight lost of those fought):

| | f1-4 | f5 W | f6-9 | f10 B | f11-14 | f15 W | f16-19 | f20 B | f21-24 | f25 W | f26-29 | f30 B |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| before | 0.1 | 0.3 | 1.5 | 4.2 | 5.0 | 6.4 | 7.9 | 12.3 | 6.8 | 12.5 | 8.3 | 34.0 |
| after | 6.7 | 12.9 | 16.9 | 41.1 | 13.7 | 14.7 | 16.9 | 46.4 | 15.2 | 30.4 | 16.7 | 62.5 |
| after, every unlock | 0.3 | 0.5 | 4.6 | 10.3 | 3.3 | 10.9 | 5.9 | 24.6 | 5.6 | 16.0 | 5.0 | 44.3 |

## Floors 1 to 4

| No unlocks | before | after |
|---|---|---|
| Rounds a fight (mean) | 1.9 | **4.4** |
| Fights won in 1 round | 42% | **2%** |
| HP lost a fight won (share of max; f1 / f2 / f3 / f4) | 5.8% (5.7 / 3.5 / 2.1 / 10.4) | **18.0%** (21.2 / 17.4 / 12.5 / 19.4) |
| Fights lost | 0.1% | 6.7% |
| Every unlock: rounds / HP lost | 1.6 / 3.3% (63% in 1 round) | 3.7 / 12.5% (5% in 1 round) |

The HP lost is after the flask's potion. Floors 2 and 3 start at 85% and
78% health (the 10% recovery), so their fights cost a little less but the
climb carries the wound.

## Levels and healing

| | before | after |
|---|---|---|
| First Level Up | floor 1 (and a second by floor 3 in 92% of climbs) | **floor 3** (never two by floor 3) |
| Level Ups by floors 5 / 10 / 20 (climbs past them) | 3 / 6.3 / 12.6 | 2 / 4 / 7 |
| Level Ups a climb that wins | 17.7 | **9** |
| Level Ups a climb, no unlocks / every unlock | 11.8 / 13.2 | 2.4 / 5.7 (climbs end sooner) |
| Health back after a floor won, no unlocks (recovery + the level's +3) | 15.6% | 12.7% |
| Same, Heat 3 | 9.1% | 8.4% |
| Coins earned a climb, no unlocks / every unlock (a climb that wins) | 51 / 63 (93) | 12 / 45 (88 to 93) |

## Callings

Top won (%) / reach f10 / reach f20, Heat 0. With no unlocks the top is too
rare to compare (0 to 0.3%), so the callings were evened on floors 10 to 20.

| | cleric | mage | ranger | rogue | warrior |
|---|---|---|---|---|---|
| No unlocks, before (top) | | 14.2 | | 8.9 | 18.3 |
| No unlocks, after (reach f10 / f15 / f20) | | 27 / 10 / 4.7 | | 30 / 9 / 3.0 | 30 / 10 / 4.8 |
| Every unlock, before (top) | 20.1 | 22.2 | 24.5 | 25.3 | 21.1 |
| Every unlock, after (top) | **10.4** | **11.0** | **10.9** | **9.6** | **10.6** |
| Heat 3, every unlock, after (top) | 5.5 | 8.8 | 3.6 | 2.5 | 4.5 |

One scale a calling could not even both states (the rules-2 note's open
point): the warrior was ahead with no unlocks and behind with all, the rogue
the other way. The fix is two knobs: the calling's foe scale (and an
upper scale from floor 10 for the warrior and the mage) sets the no-unlocks
climb, and the calling's share of the unlock health sets the climb with
unlocks. At Heat 3 the spread is wider (2.5 to 8.8, today 7.6 to 13.6).

## Each unlock alone

No unlocks but this one (Heat 0). Reach f10 / reach f20 / top won.

| Unlock | after | before (f20 / top) |
|---|---|---|
| none | 29.2 / 4.2 / 0.1 | 50.1 / 13.9 |
| flame_die | 34.0 / 6.2 / 0.6 | 51.5 / 14.7 |
| crows | 33.6 / 6.0 / 0.3 | 50.4 / 13.4 |
| shield_t5 | **50.6 / 10.3 / 1.1** | 53.3 / 16.1 |
| cleric (a calling more) | 38.8 / 8.6 / 0.6 | 51.9 / 15.1 |
| tide_die | 33.5 / 5.5 / 0.5 | 51.0 / 14.2 |
| vigil | 32.6 / 4.8 / 0.5 | 51.2 / 14.8 |
| sword_t4 | **47.6 / 8.7 / 0.8** | 54.4 / 15.0 |
| ranger (a calling more) | 32.5 / 5.3 / 0.5 | 50.1 / 17.6 |
| compact | 33.4 / 6.0 / 0.5 | 50.8 / 14.6 |
| tearglass_die | 35.1 / 6.0 / 0.4 | 51.0 / 14.2 |
| every unlock | 81.5 / 45.0 / 10.5 | 62.0 / 22.7 |

Every unlock is now felt: +3 to +21 points at floor 10, +0.6 to +6 at floor
20 (before: +0 to +4 at floor 20). Most of it is the health (+16% each); the
two start items are the strongest. Together they compound: none 0.1% to
all 10.5%.

Perks (one worn, no unlocks), reach f10 / f20 / top: purse 29.6 / 4.2 /
0.2, deep_pockets 29.4 / 4.7 / 0.1, early_word 29.2 / 4.2 / 0.1, old_friend
29.6 / 4.2 / 0.1, second_wind 29.9 / 5.0 / 0.4, keen_eye 30.4 / 4.1 / 0.2,
free_hand 29.1 / 4.3 / 0.1, fourth_card 29.1 / 4.3 / 0.2. **The perks are
barely felt** by the bot, before as after (before: top 13.9% to 14.0-14.8%
for all eight). Not tuned here: a separate pass (Second wind on every floor
on rules 2, Fourth card and Keen eye on later tables now that the first
Level Up comes on floor 3) is the next option.

## QA guards to re-band (not changed here)

Measured on the guard seeds (1 to 500) with the patch.

| File | Guard | Today | Measured | Proposed |
|---|---|---|---|---|
| `test/qa_tower_sim_test.dart` | `_medianFloor` (no unlocks) | 14 to 20 | 8 (events off 8) | 6 to 10 |
| same | `_floor20` (no unlocks) | 0.33 to 0.53 | 4.4% (events off 2.6%) | 0.02 to 0.08 |
| same | `_topNone` | 0.07 to 0.20 | 0.0% (events off 0.4%) | 0.0 to 0.01 |
| same | `_topAll` | 0.18 to 0.32 | 10.2% (events off 8.4%) | 0.06 to 0.15 |
| same | "the top is reachable ... no unlock is needed": a no-unlocks win in 500 seeds, every floor reached with no unlocks | holds | **0 wins** in 500 (2 in 2,000) | top reachable with every unlock; no unlocks must reach floor 20; "every floor reached" read on every unlock |
| `test/qa_tower_live_pin_test.dart` | pins (top, floor 20, floor sum) | none 66 / 253 / 10117, all 109 / 307 / 11127 | none **0 / 22 / 3981**, all **51 / 217 / 8991** | the measured values |

Core's own tests that the code PR updates (`test/tower_levelup_loot_test.dart`):
"Tower XP ... 4 a level", "a climb to the top gets about today's 17 Level
Ups" (now 9), "the band raises the tier" ([0, 0, 1]), "rules 2 lowers the
foes" (`towerRulesScaleOf` takes the floor), and five that expect a Level Up
table on floor 1 ("a loot card taken", Fourth card, Keen eye, Free hand, "a
rules-2 climb saves and loads every field"). Every other `*tower*` test
passed with the patch (324 passed, 14 failed: the ones above).

## Story and rules 1

- Story: none. Every knob is in `lib/data/tower/` and read only on rules 2.
  The shared rules the Tower leans on (`enemyScaledMaxHealth`,
  `scaledDamage`, `levelHealthGain`, the chapter curve) are not touched.
- Rules 1: the QA batch on rules 1 (`TOWER_RULES=1`, seeds 1 to 1000) gives
  a byte-identical JSON with and without the patch.

## Risks and uncertainties

- **Bot, not a player.** A player plays the potions, the shortcuts and the
  cards better or worse than the bot; the first hand test decides. The
  curve is one list (`towerSurvivalScale`): a band is easy to move.
- **Early deaths.** 24% of climbs with no unlocks end before floor 5, and
  floor 1 alone loses 1 fight in 15. That is the "struggle from the
  beginning"; if it reads as unfair, lower floors 2 and 3 (4.2 and 4.5)
  first. The HP lost on floors 1 to 4 (18% a fight) sits just under the
  20 to 35% asked: more would kill more climbs before floor 5.
- **Ramp shape.** The foes rise steadily in absolute terms, but those who
  survive are the stronger builds, so the death rate a fight is about flat
  (14 to 17%) from floor 6, with peaks at the wardens and bosses (41% at
  floor 10, 46% at floor 20). A steeper late ramp would need floors 6 to 9
  easier, which lifts the floor-10 reach above 30%.
- **The unlocks' health is large and visible**: with every unlock a hero has
  2.2 to 2.8 times the start health (rogue 2.2, warrior 2.4, cleric 2.4,
  ranger 2.6, mage 2.8; a dwarf or an elf less). The start screen
  should say what an unlock gives. An invisible lever (foes weaker per
  unlock) was not tried.
- **Climbs in progress on rules 2** (since v2.10.25): their level is rebuilt
  from their XP, so after the update a hero can stand a few levels lower
  (3 HP a level, and weaker foes); the Level Ups taken stay. Tower climbs are
  short, so this looks acceptable; a rules 3 would avoid it at the cost of a
  third path.
- **Coins** fall with the floors cleared (no unlocks 51 to 12 a climb); the
  stall's prices are unchanged, so the coins and their perks matter less.
- **Noise.** 2,000 seeds: about ±0.7 points at 10%, ±0.45 at 4%; a calling
  with every unlock is about 400 climbs (±1.5 points).
- The per-unlock and perk rows were measured with the prototype's knobs
  (unlock health ×5.333, the patch rounds it to 5.33); the main rows were
  re-run with the patch and match the prototype exactly.

## How it was measured

`TOWER_OUT=… TOWER_SEEDS=2000 [TOWER_HEAT=3] flutter test
test/qa_tower_sim_test.dart --plain-name batch` for the guard numbers, and a
scratch test (not committed) that played the same bot with a log of each
fight (floor, rounds, health before and after, health after the recovery)
for the fight lengths, HP lost, Level Ups and healing.
