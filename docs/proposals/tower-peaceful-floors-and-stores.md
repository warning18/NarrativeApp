# Tower: floors without a fight, and stores (Core proposal)

The user's ask: "Also add to the tower some stages where not fighting is
possible, or some special stores." This follows
`tower-snakes-and-ladders.md` (the shortcut, the setback and the rival).

I measured everything with the bot on seeds 1–2000, with no unlocks and with
all unlocks, with the floor events on (`events: 1`, on 523a516c, floor
events PR 2). Nothing here is built. The prototype was a throwaway test plus
two throwaway hooks in `lib/data/tower/`. A copy is in
`docs/proposals/tower-peaceful-harness.dart.txt`.

## What the Tower sells today

Nothing during a run. The Tower has no coin you spend during a run.
- **Given, not sold, during a run:**
  - Each floor won gives a spoils chest (`towerSpoilsFor`, shown in
    `TowerSpoilsView`). The gear in it is worn if it beats what you have.
    Its potions go to the bag (`towerBagCap` 5, extra potions are drunk on
    the spot), and so do its antidotes.
  - A flask of 1 potion refills every fight (`towerFlask`, plus 1 potion
    for every 5 unlocks owned).
  - Cards (`TowerOfferView`): a clan's oath and that clan's die on floor 1,
    then on 35% of floors. A boon (a skill, a die or a spell) on floors 5,
    10, 15, 20 and 25.
  - You can switch to any die in your bag for free (`tower_dice_panel.dart`,
    `towerChooseDie`).
- **Between runs, for marks:** marks are banked when a run ends
  (`TowerEndScreen`, `TowerProgress.marks`). A run earns 1 a floor, 2 a
  warden, 5 a boss, 15 for the top, and 1 for each card refused. They buy
  the ten unlocks on `TowerMarksScreen` (`towerProvider.buy`, `towerUnlocks`),
  210 marks in all:
  - start dice: flame 10, tide 20, tearglass 40;
  - clans: crows 10, vigil 20, compact 30;
  - start items: shield 15, sword 25;
  - professions: cleric 15, ranger 25.

  Each unlock owned also gives 3% more max health. The bot banks about
  30 marks a run with no unlocks and 37 with all.

So marks are the Tower's only coin today, and you only spend them between
runs.

## Shared rules (every new floor)

- **Where.** Ordinary floors 2 to 29 only. Never a warden or a boss, never
  floor 1 (its first oath), never a floor that already has an event, never
  a floor you meet again. One kind per floor at most.
- **The draw.** One new draw per floor on the board stream, at index
  `3000 + floor` (`towerRandom(seed, 3000 + floor, TowerStream.board)`). No
  stream is added and no existing draw moves. With the new kinds off, all
  2000 seeds play exactly as `playTowerRun(events: 1)` does, in both
  configs.
- **A floor you get past without fighting** still gives its level. Levels
  come by height (`towerHeroOf` reads `heightCleared`), and skipped floors
  already give theirs, so one rule covers both. The marks are paid by
  height too. You give up the floor's spoils chest, its card (and so the
  oath it might offer), and the 15% of health a win gives back. That is
  the price of not fighting. Measured, getting past every floor you can is
  no better than fighting (below).
- **A store** opens on the landing after an ordinary floor's win and its
  card, before the next fight. It takes no floor of its own: the climb
  stays 30 floors and the gates stay where they are.

## Harness

The harness is `playTowerRun`'s loop with hooks for the new floors. It calls
the real `towerAfterFight`, `towerPick`, `towerChooseShortcut` and
`towerBotFight`. With the new kinds off it matches `playTowerRun(events: 1)`
on all 2000 seeds in both configs (13.5% / 25.3%). Throwaway hooks: a
per-seed bonus applied at the end of `towerHeroOf` (stat points, a change
to max health), and `towerEventsFoeScale` made a variable. Every walk stops
at 150 fights. None came near that (the most was 33).

Each candidate is on 15% of eligible floors (about 1.3 a run with no
unlocks, 1.6 with all, since unlocked runs climb further).

Columns:
- **Top**: share of runs that win floor 30, with the count.
- **Fights**: mean / median a run.
- **Wardens, bosses**: deaths ÷ fights at floors 5 / 15 / 25 and 10 / 20 / 30.
- **Worst ordinary**: the ordinary floor that kills the largest share of
  the fights on it (shortcut fights left out).
- **HP 21–30**: mean health share entering floors 21–30.
- **Marks**: banked a run (earned less spent).
- **Used**: times a run the option was used: floors passed, or for a store,
  marks spent or bargains taken.

### No unlocks

| Candidate | Top | Fights | Wardens 5/15/25 | Bosses 10/20/30 | Worst ordinary | HP 21–30 | Marks | Used |
|---|---|---|---|---|---|---|---|---|
| **Baseline**: events on, scale 1.14 | 13.5% (270) | 18.5 / 18 | 1.2 / 7.5 / 13.7 | 5.7 / 13.5 / 24.6 | f21 8.4% | 0.74 | 30.0 | – |
| Events off (v1.922 + PR 2's f27/f28) | 12.9% (258) | 19.0 / 19 | 0.9 / 7.5 / 15.0 | 5.9 / 13.6 / 26.1 | f28 9.3% | 0.73 | 29.9 | – |
| Toll 20% health, bot < 50% | 13.4% (268) | 18.4 / 18 | 1.2 / 7.9 / 13.8 | 5.7 / 13.1 / 24.1 | f21 8.8% | 0.73 | 30.0 | 0.06 |
| Toll 20% health, bot < 70% | 12.7% (254) | 17.9 / 17 | 1.2 / 8.5 / 13.8 | 6.2 / 13.8 / 24.6 | f21 9.8% | 0.71 | 29.5 | 0.39 |
| Toll 15% health, always | 11.9% (238) | 16.8 / 16 | 1.5 / 8.3 / 14.3 | 6.7 / 15.7 / 25.9 | f26 10.5% | 0.71 | 29.0 | 1.31 |
| Toll 1 bag potion, bot < 50% | 13.5% (270) | 18.4 / 18 | 1.2 / 7.8 / 13.8 | 5.7 / 13.2 / 24.6 | f21 8.6% | 0.74 | 30.1 | 0.05 |
| Parley, bot < 50% | 13.6% (271) | 18.4 / 18 | 1.2 / 7.7 / 13.4 | 5.7 / 13.3 / 23.7 | f21 8.7% | 0.74 | 30.1 | 0.04 |
| Parley, bot < 70% | 13.4% (267) | 18.2 / 18 | 1.2 / 7.9 / 12.9 | 6.0 / 12.6 / 24.1 | f21 9.3% | 0.73 | 30.0 | 0.31 |
| Parley, always | 13.1% (261) | 17.3 / 17 | 1.3 / 8.1 / 12.9 | 6.3 / 13.3 / 25.6 | f22 9.9% | 0.73 | 29.8 | 1.08 |
| Parley, always, a fail costs 10% | 12.8% (257) | 17.3 / 17 | 1.3 / 8.0 / 12.9 | 6.3 / 13.4 / 26.6 | f22 10.1% | 0.73 | 29.7 | 1.08 |
| Oath guardian alone, always | 13.5% (270) | 17.9 / 17 | 1.2 / 8.0 / 13.5 | 6.0 / 13.3 / 23.9 | f26 9.1% | 0.73 | 30.0 | 0.56 |
| Rest: heal 30% or +1 stat | 18.8% (375) | 18.1 / 18 | 1.2 / 6.5 / 11.1 | 4.8 / 11.4 / 20.4 | f28 8.5% | 0.77 | 32.7 | 1.43 |
| Rest: heal 30% only | 14.8% (296) | 17.4 / 17 | 1.2 / 8.1 / 11.7 | 6.3 / 13.6 / 26.0 | f26 8.9% | 0.76 | 30.7 | 1.36 |
| Merchant, marks, whetstone 6 | 20.8% (416) | 19.4 / 19 | 1.2 / 6.4 / 9.6 | 4.9 / 9.8 / 13.5 | f21 7.5% | 0.77 | 25.2 | 7.6 marks |
| Merchant, whetstone 12 | 18.3% (366) | 19.0 / 19 | 1.2 / 6.8 / 10.3 | 5.4 / 10.9 / 15.5 | f28 8.3% | 0.76 | 22.7 | 9.0 marks |
| Merchant paid in potions (whetstone 2) | 17.0% (339) | 18.9 / 19 | 1.3 / 6.8 / 10.6 | 5.4 / 10.2 / 17.9 | f22 8.3% | 0.74 | 31.3 | 1.18 bought |
| Quartermaster (sworn, half price, whetstone) | 21.5% (430) | 19.6 / 19 | 1.1 / 6.5 / 9.7 | 4.5 / 9.8 / 13.3 | f28 7.1% | 0.77 | 28.6 | 4.6 marks |
| Merchant, salve and potions only | 14.8% (295) | 18.7 / 18 | 1.2 / 7.1 / 13.0 | 5.4 / 12.1 / 24.0 | f26 7.8% | 0.75 | 29.2 | 1.5 marks |
| Same, half price if sworn to its clan | 14.8% (296) | 18.7 / 18 | 1.2 / 7.1 / 13.0 | 5.4 / 12.2 / 23.9 | f26 7.8% | 0.75 | 29.5 | 1.2 marks |
| Bargain: −10% max health, +2 stat | 18.8% (376) | 19.4 / 19 | 1.0 / 5.8 / 11.0 | 4.2 / 8.6 / 17.2 | f28 8.8% | 0.77 | 32.7 | 1.36 |
| Bargain: −15% max health, +1 stat | 12.0% (240) | 18.1 / 17 | 1.1 / 7.5 / 14.2 | 4.9 / 15.1 / 22.1 | f28 10.0% | 0.77 | 29.3 | 1.26 |
| Bargain: −10% max health, +1 stat | 14.1% (282) | 18.6 / 18 | 1.1 / 7.2 / 12.8 | 4.8 / 13.0 / 20.6 | f28 9.8% | 0.77 | 30.5 | 1.30 |

### All unlocks

| Candidate | Top | Fights | Wardens 5/15/25 | Bosses 10/20/30 | Worst ordinary | HP 21–30 | Marks | Used |
|---|---|---|---|---|---|---|---|---|
| **Baseline**: events on, scale 1.14 | 25.3% (506) | 21.6 / 22 | 0.1 / 5.8 / 8.8 | 2.6 / 11.9 / 21.3 | f21 5.2% | 0.79 | 37.2 | – |
| Events off | 27.4% (548) | 22.3 / 23 | 0.1 / 5.7 / 11.1 | 3.1 / 12.3 / 22.3 | f26 5.2% | 0.80 | 37.5 | – |
| Toll 20%, < 50% | 25.1% (502) | 21.6 / 22 | 0.1 / 5.9 / 8.8 | 2.6 / 12.0 / 21.7 | f21 5.3% | 0.79 | 37.2 | 0.05 |
| Toll 20%, < 70% | 25.1% (503) | 21.3 / 21 | 0.1 / 5.8 / 9.1 | 2.7 / 12.5 / 21.7 | f21 5.3% | 0.77 | 37.2 | 0.32 |
| Toll 15%, always | 24.2% (484) | 20.0 / 20 | 0.1 / 6.4 / 8.9 | 3.1 / 13.8 / 23.4 | f26 6.3% | 0.76 | 36.9 | 1.58 |
| Toll 1 potion, < 50% | 25.1% (501) | 21.6 / 22 | 0.1 / 5.9 / 8.7 | 2.6 / 11.9 / 21.8 | f21 5.3% | 0.79 | 37.2 | 0.05 |
| Parley, < 50% | 25.1% (503) | 21.6 / 22 | 0.1 / 5.8 / 8.8 | 2.6 / 11.8 / 21.9 | f21 5.2% | 0.79 | 37.2 | 0.05 |
| Parley, < 70% | 25.5% (510) | 21.4 / 22 | 0.1 / 5.9 / 9.1 | 2.6 / 12.2 / 22.6 | f21 5.3% | 0.78 | 37.4 | 0.29 |
| Parley, always | 25.1% (503) | 20.4 / 21 | 0.1 / 6.4 / 9.3 | 2.9 / 12.6 / 23.2 | f22 6.0% | 0.78 | 37.4 | 1.40 |
| Parley, always, a fail costs 10% | 25.1% (502) | 20.3 / 21 | 0.1 / 6.4 / 9.2 | 2.9 / 12.7 / 23.1 | f22 5.9% | 0.78 | 37.3 | 1.40 |
| Oath guardian alone, always | 25.1% (502) | 20.8 / 21 | 0.1 / 6.6 / 9.1 | 2.7 / 12.9 / 22.9 | f21 5.7% | 0.78 | 37.3 | 0.97 |
| Rest: heal 30% or +1 stat | 34.0% (680) | 20.9 / 22 | 0.1 / 5.0 / 6.4 | 2.4 / 10.7 / 14.8 | f22 4.8% | 0.81 | 40.2 | 1.65 |
| Rest: heal 30% only | 26.3% (525) | 20.3 / 21 | 0.1 / 6.2 / 8.4 | 2.8 / 12.3 / 23.0 | f26 5.8% | 0.80 | 37.8 | 1.59 |
| Merchant, whetstone 6 | 32.5% (650) | 22.2 / 23 | 0.1 / 5.1 / 7.2 | 2.2 / 10.1 / 13.9 | f19 4.7% | 0.81 | 31.1 | 8.3 marks |
| Merchant, whetstone 12 | 30.6% (613) | 22.0 / 23 | 0.1 / 5.4 / 7.4 | 2.6 / 10.8 / 15.1 | f21 4.9% | 0.80 | 27.7 | 11.0 marks |
| Merchant paid in potions | 31.8% (635) | 22.2 / 23 | 0.1 / 4.5 / 6.9 | 2.3 / 10.4 / 14.9 | f23 4.4% | 0.79 | 39.3 | 1.51 bought |
| Quartermaster, whetstone | 33.4% (667) | 22.4 / 24 | 0.1 / 4.8 / 7.2 | 2.2 / 10.0 / 13.7 | f19 4.3% | 0.81 | 34.8 | 4.9 marks |
| Merchant, salve and potions | 25.9% (519) | 21.7 / 22 | 0.1 / 5.9 / 8.6 | 2.6 / 11.8 / 20.6 | f21 5.4% | 0.80 | 36.6 | 0.8 marks |
| Same, half price if sworn | 25.9% (519) | 21.6 / 22 | 0.1 / 5.9 / 8.6 | 2.6 / 11.8 / 20.6 | f21 5.4% | 0.80 | 36.7 | 0.7 marks |
| Bargain −10%, +2 | 30.8% (615) | 22.2 / 23 | 0.1 / 4.8 / 7.8 | 2.0 / 10.0 / 14.6 | f21 5.9% | 0.82 | 39.2 | 1.58 |
| Bargain −15%, +1 | 21.9% (437) | 20.9 / 21 | 0.2 / 5.7 / 9.2 | 2.8 / 16.0 / 21.5 | f21 6.1% | 0.82 | 35.7 | 1.48 |
| Bargain −10%, +1 | 25.9% (517) | 21.5 / 22 | 0.1 / 5.5 / 7.5 | 2.5 / 13.2 / 18.2 | f28 5.3% | 0.81 | 37.2 | 1.52 |

What the tables say:
- **A stat point is the strongest thing a floor can give.** Each +1 to the
  calling's damage stat a run (1.0–1.5 of them) is worth +5 to +8 points of
  the top. Whetstones, a rest that gives a point, and a bargain worth two
  points all break the curve, even at 12 marks. Stat points stay with the
  level-up, with one exception: the bargain, priced in max health.
- **Getting past a floor costs about what it saves.** The spoils and the 15%
  recovery are worth about as much as the health a fight takes. A bot that
  passes every floor it can (parley always: 1.1–1.4 floors a run) ends 0.2
  to 0.4 points under the baseline, inside the noise. That is what the ask
  needs: a real choice, not the best line.
- **The bot is seldom hurt when it enters a floor.** With the 15% recovery
  and the flask, it is under 50% health on about 0.05 floors a run, so the
  "pass when low" policies hardly fire. The "always" rows are the
  informative ones.

## 1. Floors where not fighting is possible

- **Parley** (keep). Before the fight, a guardian bars the way. You choose:
  talk, or fight.
  - Talking is the setback's d20 check (`checkPasses`, `checkChance`,
    shown), using an ability drawn by floor: charisma, wisdom or dexterity.
    The DC is the setback's (10 + (floor − 1) ÷ 6). Pass: you go on with no
    fight. Fail: the fight, as it would have been.
  - **The oath reason:** the guardian belongs to a clan drawn from the six.
    Sworn to that clan, you pass with no roll. That happens 0.56 times a run with
    no unlocks and 0.97 with all, so the oaths matter outside the fight too.
  - Bot (always talking): the modifier averages +3.6, a talk passes 67% of
    the time (0.52 of 0.78 a run), and oaths pass 0.56 a run.
  - The fail costs nothing more: the extra 10% the "foe strikes first"
    variant takes cost another 0.3 points and pushed f22 to 10.1%, over the
    10% an ordinary floor may kill. The fight you could not avoid is the
    stake.
- **Oath guardian alone** (merged into parley). Measured neutral (13.5 /
  25.1). On its own it does nothing for a run with no clan sworn to the
  guardian's clan. Inside parley, it is the reason the talk can be skipped.
- **Toll** (drop). Paying health and losing the spoils is worse than the
  fight: −1.6 / −1.1 when always paid, and f26 at 10.5%. Paid in a potion,
  it is a potion drunk for nothing. It is a trap, not a choice.
- **Rest floor** (drop from the first set, see "Recommended set"). There
  is no foe, so there is nothing to decide. Heal only is +1.3 / +1.0; with a
  stat point it is +5.3 / +8.7. The merchant's salve is the same heal, as a
  choice.

## 2. Special stores

**Currency: the run's own marks.** You spend them in the store, and the end
screen banks what is left. There is no new coin, nothing new to drop and
one number to learn. It is a real trade (power now against unlocks later)
that the bot cannot weigh, so the "Marks" column is what it costs. Cost to
build: one saved int, `marksSpent`, which `TowerRun.marks` subtracts, plus
its line on the end screen. A new run-only coin would need drops on every
floor, a second counter, a save field and a screen of its own, for the same
effect.

- **Merchant** (keep). It has a small stock for this run only:
  - a salve, 3 marks: heals 40% of max health;
  - a potion bundle, 4 marks: +2 to the bag, up to 5.

  It belongs to a clan drawn from the six. Sworn to that clan, everything is
  half price (rounded up): this is the quartermaster, folded into the
  merchant. Bot: buys the salve under 60% health, and the bundle with 3 or
  fewer potions in the bag. Measured +1.3 / +0.6 alone, spending 1.2 / 0.7
  marks a run.
  - Dropped: the whetstone (a stat point for the run): +7.3 / +7.2 at
    6 marks and +4.8 / +5.3 even at 12. A die-face swap would be the
    natural rare item, but it is not measured. It should come later, as its
    own measured change.
- **Bargain** (the dark trade, keep). Lose 10% of your max health for the
  rest of the run, for +1 to the calling's damage stat. Taken or refused,
  once. Bot: always takes it. Measured +0.6 / +0.6, about even, so a player
  who takes it trades a cushion for a faster kill. At 15% it costs −1.5 /
  −3.4 and the f20 boss rises to 15–16%. At +2 it is +5.3 / +5.5.
- **Quartermaster** (merged into the merchant, as its sworn discount).

**How often.** On 15% of eligible floors for the merchant and 10% for the
bargain: 1.3 / 1.6 merchants and 0.85 / 1.05 bargains a run (none / all).
Stores sit between floors. They never replace a fight.

## Recommended set, measured together

Floor events (shortcut 15%, setback 20%, rival 10% of ordinary floors) plus
parley 15%, merchant 15% and bargain 10% of eligible floors.

Bot policies:
- **Shortcut:** at ≥ 80% health, as today.
- **Parley:** talks under 70% health; passes on the oath under 70%.
- **Merchant:** as above.
- **Bargain:** always takes it.

| Set | Top none | Top all | Fights none / all | Bosses 10/20/30 none | Bosses all | Wardens 25 none / all | Worst ordinary none / all | HP 21–30 | Marks |
|---|---|---|---|---|---|---|---|---|---|
| v1.922, events off | 12.6% | 26.8% | – | – | – | – | – | – | – |
| Baseline, events on, 1.14 | 13.5% (270) | 25.3% (506) | 18.5 / 21.6 | 5.7 / 13.5 / 24.6 | 2.6 / 11.9 / 21.3 | 13.7 / 8.8 | f21 8.4 / f21 5.2 | 0.74 / 0.79 | 30.0 / 37.2 |
| Set, 1.14 | 15.0% (301) | 27.1% (542) | 18.6 / 21.6 | 4.3 / 12.6 / 22.8 | 2.0 / 12.2 / 19.0 | 13.2 / 8.7 | f17 8.6 / f26 5.6 | 0.76 / 0.81 | 29.8 / 37.3 |
| **Set, 1.15** | **14.0% (279)** | **24.8% (496)** | 18.5 / 21.3 | 4.6 / 13.1 / 23.8 | 2.4 / 13.0 / 22.0 | 14.3 / 9.9 | f17 8.4 / f26 5.9 | 0.75 / 0.81 | 29.3 / 36.5 |
| Set, 1.16 | 13.3% (265) | 23.6% (472) | 18.2 / 21.1 | 5.1 / 12.6 / 24.3 | 2.6 / 13.6 / 23.5 | 14.6 / 9.9 | f22 8.7 / f22 5.6 | 0.75 / 0.80 | 28.8 / 35.9 |
| Set, 1.15, bot always talks | 14.4% (288) | 25.1% (503) | 17.6 / 20.4 | 5.0 / 13.2 / 21.5 | 2.5 / 13.3 / 23.3 | 13.8 / 9.5 | f22 9.3 / f26 6.0 | 0.76 / 0.80 | 29.2 / 36.7 |

(The v1.922 row is from `tower-snakes-and-ladders.md`. On this branch,
events off now read 12.9% / 27.4%, after PR 2's f27/f28 change.)

- **What pays for the help is `towerEventsFoeScale`: 1.14 → 1.15.** The set
  adds +1.5 / +1.8 points at 1.14. At 1.15 it is 14.0% / 24.8%, against the
  baseline's 13.5% / 25.3%: both within half a point, with a standard error
  of about 0.8 on 2000 seeds. One step (+0.01) moves the top about 1 point
  with no unlocks and 2.3 with all. 1.16 overshoots the unlocked runs
  (23.6%).
- The gates hold their bands: f10 4.6% (it was 5.7%), f20 13.1% (10–15%),
  f30 23.8%. Every ordinary floor stays under 10% (worst f17 8.4%). The
  f25 warden rises to 14.3% with no unlocks (it was 13.7%).
- A player who talks at every guardian does no better (14.4 / 25.1), so
  fighting stays the default.
- Run length is unchanged (18.5 / 21.3 fights). A run gets past about 0.25
  floors with the bot's policy, and 1.1–1.4 if it always talks. It meets
  1.3–1.6 parleys, 1.3–1.5 merchants and 0.85–1.05 bargains.

## The final list

Three new kinds, one of each purpose, on top of the three events:
1. **Parley**: get past a guardian by talking (a check, odds shown), or
   with no roll if sworn to its clan. Otherwise you fight.
2. **Merchant**: salve and potions for this run's marks, half price from
   your own clan.
3. **Bargain**: max health for one stat point.

I dropped toll (worse than the fight), the rest floor (no decision; it can
come back later as a parley's "rest" result if the user wants a pure
breather), and the whetstone and quartermaster (too strong, or merged).
Six kinds in all, each with one line of rules, and a full climb meets
nearly all of them once.

## Build order (after floor events PR 1 and PR 2)

- **PR 3, parley.** `TowerEventKind.parley`, the draw at `3000 + floor`,
  `towerChooseParley(run, data, talk)`, the pass (its level, no spoils, no
  card, no recovery), the bot's policy, simulator report columns.
- **PR 4, stores.** `merchant` and `bargain`, `marksSpent`, `bought`, the
  store's open state, `towerBuy` and `towerLeaveStore`, the bargain applied
  in `towerHeroOf`, the bot, `towerEventsFoeScale` 1.14 → 1.15 and the re-set
  QA bands. The scale goes last, with the whole set, as PR 2 did.
- UX-2's panel after each PR (or one panel after PR 4). `towerEventsLive`
  stays 0 until the user turns the events on.

## For Narrative (EN and FR, slots only)

- Parley: a floor name; an intro line for the guardian of each of the six
  clans; a line each for a talk passed, a talk failed (the fight follows) and
  passing on the oath; three short verbs for the check by ability (charisma,
  wisdom, dexterity).
- Merchant: a floor name; a greeting; a line for the sworn discount; a name
  and a one-line description for each of the salve and the potion bundle; a
  goodbye.
- Bargain: a floor name; the offer line; a line each for taken and refused.
- `app_strings.dart` keys (UX adds them, Narrative words them): Talk, Fight,
  Buy, Leave, Accept, Refuse, "Sworn: no roll", "Half price", "Marks to
  spend: {n}", "You pass: no spoils, no card".

## State for UX-2 (towerEventOf)

Extend `TowerEventKind` (added last): `parley`, `merchant`, `bargain`.

`TowerEventView` gains:
- **parley:** `ability`, `dc`, `modifier`, `chance` (reused), `clanId`
  (the guardian's), `oathPass` (bool: sworn, no roll), `accepted` (reused:
  null until you choose talk or fight), `landsOn` (floor + 1), `forgoes`
  (`['spoils', 'card']`, the "you give up" line).
- **merchant:** `clanId`, `discount` (bool, sworn), `wallet` (int, marks
  left to spend: `marks − marksSpent`), `stock`
  (`List<TowerStockView>`: `id`, `kind` (salve / potions), `price`,
  `amount` (health healed or potions given), `bought`, `affordable`).
- **bargain:** `maxHealthCost` (int, 10% of max health now), `stat` (the
  calling's damage stat), `points` (1), `accepted`.
- `storeOpen` (bool), so the panel shows on the landing before the next
  fight.

`TowerEventResult` gains: `bought` (`List<String>`), `paid` (marks),
`healed` (int). For a parley, `roll` / `total` / `passed` are reused, and
`to` is the next floor.

On `TowerRun` (saved, absent reads empty):
- `parley` (bool?, the choice on this floor, like `shortcut`);
- `marksSpent` (int);
- `bought` (`Map<int, List<String>>`: floor → stock or bargain ids, which
  `towerHeroOf` replays for the bargains);
- `store` (int?, the floor whose store is open, cleared by
  `towerLeaveStore` or the next fight).

## Save compatibility

A run saved before has none of the new fields: no marks spent, nothing
bought, no store open, and plays as before. The new draw is its own index
on the board stream, so no existing draw moves. With the new kinds off, the
harness matches `playTowerRun(events: 1)` on all 2000 seeds, in both
configs.

## Notes for the build

- A floor passed by parley counts toward `crest`, like a skip's floors, so
  `towerHeroOf` levels it and pays its marks. Its pick is taken on the next
  floor.
- A shortcut or rival that skips a parley or store floor skips its offer too,
  like the spoils.
- The bargain is a fixed max-health cut saved with the floor. It is
  applied after the levels, so later levels don't bring it back.
- Not measured: a die-face swap item, and how spending marks slows the
  unlock tree (about 1 mark a run at the bot's policy, 3–4% of a run's
  marks).
