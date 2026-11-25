# Tower: Heat levels (v2.9.0, tentative)

Core's design note. **Nothing is built and no number has moved.** It builds
on brief 7 of `docs/simulation/tower-briefs-6-7-8-spec.md` (heat 1-3, one
foe factor a level, measured) and adds named curses and two more levels.
Tags: **(M)** measured by the bot, seeds 1-2000; **(C)** arithmetic on
measured numbers; **(guess)** to be tuned by bot batches.

## The Tower today (main, v2.8.1)

| What | Now |
|---|---|
| Floors | 30; wardens 5, 15, 25; bosses 10, 20; the top boss 30 |
| Boons (skill / die / spell) | floors 5, 10, 13, 15, 20, 23, 25, 28 |
| Forced affixes on the strongest foe | 0 on floors 1-10, 1 on 11-25, 2 on 26-29 |
| Elite chance (a lone foe) | .12 (4-14), .15 (16-19), .20 (21-24), .25 (26-29) |
| Foe scale | `towerFoeScale` 1.24 (1.22 with events, 1.23 peaceful), × `towerClimbScale` 1.08 (11-20), 1.06 (21-30) |
| Healing | 15% of max after each floor won, 1 potion a fight + 1 per 5 unlocks |
| Clans | standing 0-6, gift +2 / ally +1 / rival -1, oath at 6, late oath from 15 |
| Rates (M, v2.8.0) | top 11% (no unlocks) / 24% (all); floor 30 won by 75% / 80% of those reaching it |

## What brief 7 measured (M, v2.4.0, all unlocks)

| Factor on every floor | top | median floor | clear floor 10 | reach floor 20 |
|---|---|---|---|---|
| heat 0 | 25.4% | 21 | 94% | 60% |
| ×1.05 | 18.8% | 20 | 92% | 52% |
| ×1.10 | 13.0% | 18 | 90% | 44% |
| ×1.15 | 9.4% | 17 | 85% | 39% |
| ×1.20 | 5.8% | 16 | 79% | 33% |

Each 5% of foe strength costs about 6, 6, 4, 4 points of top. That is the
yardstick for every curse below.

## What is new here

1. **Curses, not only a factor**: each level past 1 adds one named rule from
   a lever the Tower already has, so a level reads differently, not just
   "foes hit harder".
2. **Five levels**, not three: brief 7's ×1.15 heat 3 is still inside the
   no-unlock band (9.4%), so there is room above it.
3. **Floors 1-10 kept gentle**: the factor stays at ×1.05 from Heat 1 on
   (measured), and the curses touch floors 11-30, plus warden 5 and boss 10.

## The rules (as brief 7)

- Heat 1 opens when the top is won once at Heat 0; Heat n+1 when the top is
  won at Heat n. A save with `wins > 0` opens Heat 1 at once.
- Chosen on the Tower door before Climb, the highest open by default, fixed
  for the run. Hidden until Heat 1 opens.
- Curses add up. Same seed, same tower (no new random stream).
- The daily climb (brief 8, if built) is always Heat 0.

## The ladder

| Heat | Name | Curse added | Lever | Top, all unlocks |
|---|---|---|---|---|
| 1 | Embers | foes ×1.05, every floor | brief 7's factor | **19%** (M: 18.8 on v2.4.0) |
| 2 | Smoke | +1 forced affix on wardens and bosses (5, 10, 15, 20, 25, 30) | `minAffixes`/`maxAffixes` +1 on six budgets | 15% (guess) |
| 3 | Flame | healing after a floor 15% → 8%; Elite chance +.05 on fight floors 11-29 | `towerRecoveryShare`, `eliteChance` | 11% (guess) |
| 4 | Pyre | boons 13 and 23 gone (8 → 6); the late oath from floor 18, not 15 | `towerBoonFloors`, `towerPityOathFloor` | 8% (guess) |
| 5 | Ash | foes ×1.10 on floors 11-30 (×1.05 below); a gift lowers each rival clan by 2, not 1 | the factor, `towerRivalStanding` | 5% (guess) |

Sanity checks (C): Heat 3 sits between measured ×1.10 (13%) and ×1.15
(9.4%); Heat 5 near measured ×1.20 (5.8%). Brief 3 measured two boons at
about 1.3 points of top, so Heat 4's cut is mostly the late oath.

## Rewards

| Heat | Marks banked | Won run, about (C: 59 before the bonus, M) | Record |
|---|---|---|---|
| 0 | ×1.0 | 59 | — |
| 1 | ×1.25 | 74 | flame badge 1 |
| 2 | ×1.5 | 89 | badge 2 |
| 3 | ×1.75 | 104 | badge 3 |
| 4 | ×2.0 | 118 | badge 4 |
| 5 | ×2.25 | 133 | badge 5 and the Ash trim on the Tower banner |

Brief 7's +25% a level, carried on. The multiplier is on `marksEarned`
(floors, wardens, bosses, top, "Not now"), rounded down; the stall's spend
comes off after. Marks only matter while the shop has something to sell:
see `tower-coins.md`.

## How it meets the other systems

| System | At Heat |
|---|---|
| Unlocks | all apply (health per unlock, potion per 5, start dice, items, callings, clans). Heat is aimed at players who own them. |
| Clan offers | offer floors (35%), three suitors, gift depth unchanged. Heat 5's rival -2 punishes gifts from rival clans; one clan's way still reaches 6. |
| Oath | still at 6, one a run. Heat 4: late oath 15 → 18 (first offer after floor 19). |
| Coins / perks (`tower-coins.md`) | worn at every Heat; the targets are measured with the bot's perks worn. |
| Daily | Heat 0 only. |

## Target rates (all unlocks, the bot)

| Heat | Top | Floor 30 won, of those reaching it | Reach floor 20 | Clear floor 10 |
|---|---|---|---|---|
| 0 (M) | 24% | 80% | 61% | 96% |
| 1 | 19% | 78% | 53% | 93% |
| 2 | 15% | 72% | 50% | 92% |
| 3 | 11% | 68% | 44% | 92% |
| 4 | 8% | 65% | 40% | 92% |
| 5 | 5% | 60% | 33% | 91% |

Guard bands: each level costs **3 to 6 points**; Heat 5 **3 to 7%**; no
ordinary floor loses over **13%** at Heat 3 or less; every calling wins at
least **5%** at Heat 3 (the cleric fell to 5.7% at ×1.15, M).

**Tuning with the bot.** Add `heat` to `playTowerRun`; seeds 1-2000 at Heat
0-5, none and all (12 batches, about 30 s each, M). Keep the curses; tune
only Heat 5's ×1.10 and Heat 3's 8% recovery. Check by calling and clan,
then seeds 10001-12000; a guard pins the bands on 500 seeds.

## Size

| Part | Size | What |
|---|---|---|
| Core | **M** | brief 7's data (`heat` on `TowerRun`, `heatWon` on `TowerProgress`, `towerHeatMarks` .25) plus `towerHeatCurses` and five hooks (`_floorOf` factor and affixes, recovery, Elite, boon floors and late oath, rival ripple); bot, batches, guard |
| UX | **M** | brief 7's screens, six steps instead of four, plus a curse list |
| Narrative | **S** | names (the draft's Embers / Flame / Pyre, two more) and five curse lines, EN/FR |

**Screens (pictures first):** Heat picker on the Tower door (six steps,
locked ones dimmed "Win the top at Heat n", marks ×); a curse list sheet
(every curse in force, the new one marked); a flame chip in the floor
header; on the end screen "Heat 3 · marks ×1.75", "Heat 4 is open" and the
badge on the record.

## Open questions for the user

New here:
1. **Curses or a factor.** **A. Five levels, a named curse each, adding up
   (recommended: each level feels different, every lever exists).** B.
   Brief 7 as specced: three levels, ×1.05 / 1.10 / 1.15. C. Pick-your-own
   curses for points.
2. **How many levels.** **A. Five (recommended).** B. Three.

Still open from brief 7 (§7 of the spec):
3. **Factors**: **A. ×1.05 then curses (recommended)**; B. ×1.05 / 1.10 /
   1.15; C. steeper top (×1.20).
4. **Which floors**: **A. floors 1-10 at ×1.05 only, curses on 11-30
   (recommended)**; B. all 30 alike.
5. **Marks**: **A. +25% a level (recommended)**; B. none, badge only.
6. **Picker**: **A. any open level (recommended)**; B. highest only.
