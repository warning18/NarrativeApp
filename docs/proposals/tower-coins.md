# Tower: coins and the shop (v2.10.0, tentative)

Core's design note. **Nothing is built and no number has moved.** It builds
on brief 6 of `docs/simulation/tower-briefs-6-7-8-spec.md` (in-run coins:
reroll, banish, a boon at the merchant, measured) and answers what marks
buy once the unlock tree is full. Tags: **(M)** measured, **(C)**
arithmetic, **(guess)** to be tuned by bot batches. Read with
`tower-heat.md`.

## The problem: marks run out after about 7 climbs

| Marks earned | |
|---|---|
| a floor 1, a warden +2, a boss +5, the top +15, "Not now" +1 | |
| a won run | 61 (59 after the stall, M) |
| mean a run (M) | 25.9 (no unlocks) / 34.5 (all) |
| the ten unlocks, all | **210** (10 to 40 each) |
| climbs to buy the tree (M, brief 9) | **about 7** |

After that marks pile up and buy nothing, and Heat's +25% (`tower-heat.md`)
has nothing to speed up.

## Recommendation: two currencies, each with one job

| | Coins (brief 6) | Marks (today) |
|---|---|---|
| Lasts | **one climb**, lost at the end | **between climbs** |
| Earned | fixed table per floor (below) | today's table, × Heat |
| Buys | reroll, banish, the stall (salve, potions, a boon) | the unlock tree, **then the new perks and looks** |

So coins do **not** replace marks: marks stay the lasting currency and get
a second shop **after the tree**; coins are brief 6's run purse, as
specced. With brief 6's option A the stall takes coins only, so marks are
never spent inside a run (+8% / +3% marks banked a run, C).

## Part 1: coins in the run (brief 6, as specced)

| Floor won | 1-10 | 11-20 | 21-29 |
|---|---|---|---|
| ordinary | 1 | 2 | 3 |
| Elite | +1 | +2 | +3 |
| warden | 3 | 6 | 9 |
| boss | 5 | 10 | — |

Measured (M): 37.8 / 47.8 coins a run (none / all), 16 in hand at a merchant
(median), 1.6 / 1.9 merchants a run.

| Buy | Price |
|---|---|
| reroll the table | 3, +2 each further reroll of it |
| banish a card | 4; one a table, 5 a run |
| salve / potion bundle | 4 / 5 (today 3 / 4 marks) |
| a boon at the stall | **15** (new here; spec offered 10) |

At 10 the boon measured the top 14.5% / 29.2% (+1.5 / +3.8 points over the
base, M), over both bands; 15 buys about one a run (C). Not measured: the
boon at 15, reroll and banish (the bot cannot judge a table; under a point,
C).

## Part 2: the shop after the tree (new)

**Perks** (marks, bought once, **two worn a climb**, chosen on the door; they
do not count for the +3% health per unlock):

| Perk | Effect | Price (guess) | Lever |
|---|---|---|---|
| Purse | start the climb with 5 coins | 30 | brief 6 coins |
| Deep pockets | bag 5 → 6 | 30 | `towerBagCap` |
| Early word | late oath from floor 12, not 15 | 35 | `towerPityOathFloor` |
| Old friend | +2 standing with one clan of the run's pool at the start (ripple to allies and rivals) | 40 | `towerClanRipple` |
| Second wind | +15% max health back after a warden or boss | 40 | recovery |
| Keen eye | the floor-5 boon one rarity step up | 45 | `towerRarityStep` |
| Free hand | the first reroll of each climb costs nothing | 45 | brief 6 reroll |
| Fourth card | the first two boon tables show a fourth card | 60 | `towerOfferFor` |

**Looks** (no power): five banner trims at 10 each (50); the Heat 5 trim is
earned, never sold.

**Not sold:** races (all open already), oaths (standing 6 stays the only way),
stats or levels (foes follow the hero's level, v1.848), starting gold (the
Tower has none; Purse gives coins instead).

**First-win bonuses** (marks, once): first win +30; first win at each Heat
+20 (guess).

## Pace

| Shop | Marks | Climbs, about (C, guess past the tree) |
|---|---|---|
| unlock tree | 210 | 7 (M) |
| + perks | 535 | 15 |
| + looks | 585 | 17 |
| with Heat 1-3 (×1.25-1.75) and the bonuses | | **15-20** |
| Heat 0 only | | 20-24 |

Target: everything in **15 to 25 climbs**, the first perk 1-2 climbs after
the tree.

## How it meets the other systems

| System | Rule |
|---|---|
| Heat | multiplies marks, never coins (coins buy in-run power; more at high Heat would undo the curse). Perks are worn at every Heat; Heat targets are measured with two perks. |
| Oaths, clan offers | Old friend starts one clan at 2 (one gift less to 6); Early word, the late oath 3 floors sooner. Still one oath a climb. Rerolling an oath table redraws the gifts, never removes a due oath. Banish cannot take an oath. |
| The stall | coins only (brief 6 option A); a sworn clan halves it, as now. |
| Daily (brief 8) | no unlocks, no perks, coins as any run. |

## Anti-snowball

Band to hold: **top 18-32% with all unlocks** (24% now, M).

| Source | Top, all unlocks |
|---|---|
| today | 24% (M) |
| + the boon at 15 | about 26-27% (guess: between +0 and the +3.8 of 10 coins) |
| + reroll, banish | under +1 (C) |
| + the two strongest perks | +2-4 (guess) |
| total | **about 29-32%**, at the top of the band |

Limits: **two perk slots** whatever is owned; only the ten unlocks give
health; coins lost at the end of the climb. If the bot finds the band
broken: one slot, or the boon to 20, never the foe scale (newcomers at
Heat 0 stay as they are). Batches: each perk alone and the best two, none
and all, seeds 1-2000; a guard pins the band on 500 seeds.

## Size

| Part | Size | What |
|---|---|---|
| Core | **M** for brief 6, **S-M** for the shop | brief 6's data (`coins`, `coinsEarned`, `rerolls`, `banished` on `TowerRun`, `TowerStream.reroll`); `perks` and `worn` on `TowerProgress`, `worn` on `TowerRun`; eight perk hooks; first-win bonuses; the bot's perk pick; batches and guard |
| UX | **M** | screens below, pictures first |
| Narrative | **S** | brief 6's coin keys, eight perk names and lines, five trims |
| Art | **S** | eight perk icons, five trims (asked through the manager) |

**Screens (pictures first):** coin chip in the floor header; "+2 coins" on the
spoils; Reroll · 3 and Banish · 4 on the card table; the stall in coins with
the boon line; the marks screen grown to three tabs (Unlocks / Perks /
Looks); two perk slots on the door beside the Heat picker; the end tally
(floors, wardens, bosses, top, refusals, Heat ×, first-win bonus, total
banked, "coins left: 9 (lost)", "next perk: 12 more").

## Open questions for the user

New here:
1. **Coins and marks.** **A. Coins last one climb (brief 6), marks stay and
   buy perks after the tree (recommended: each currency one job, nothing
   to convert).** B. Coins replace marks: one lasting coin for everything.
   C. Marks only; no in-run coins.
2. **Perk slots.** **A. Two (recommended, the band is tight).** B. Three.
   C. No perks, looks only.
3. **Pace.** **A. About 20 climbs for everything (recommended).** B. 10.
   C. 30.
4. **First-win bonuses.** **A. +30, and +20 a Heat (recommended).** B. None.

Still open from brief 6 (§6 of the spec):
5. **Earning**: **A. the fixed table (recommended)**; B. chest gold ÷ 5.
6. **The stall**: **A. all in coins, marks for the shop only
   (recommended)**; B. marks for salve and potions, coins for the rest.
7. **The boon's price**: **A. 15 (recommended)**; B. 10 with harder floors
   11-20; C. 10 (over the bands, M).
8. **More merchants**: **A. as today, after 10 and 20 (recommended)**; B.
   after the wardens too (+1.8 / +0.7 points alone, M).
9. **End screen**: **A. show "coins left (lost)" (recommended)**; B. nothing.
