# Tower: snakes and ladders (Core proposal)

The user asked whether the climb of the Tower could borrow from snakes and
ladders. This note measures three ways to do it, lightest to deepest, with
the bot (`playTowerRun`'s loop) on seeds 1–2000, with no unlocks and with all
unlocks. It was measured on PR #965's head (dice gained go to the bag, the
bot tries a die before it rolls it).

Nothing here is built. The prototype was a throwaway change to
`lib/data/tower/` and a throwaway test.

## The Tower today

- 30 floors, in order, one fight each. Wardens on 5, 15, 25; bosses on 10,
  20, 30.
- Boons after 5–25 (the gates), oaths on about a third of the floors,
  spoils after every floor.
- Levels by floors cleared (`towerLevelAfter`), 30% health back per floor.
- A lost fight ends the run. Marks by floors cleared.

## Results

"Fights" counts every fight, refights included. "Gate death" is deaths on
that kind of floor over fights fought there. "Marks" is the rule proposed
below (by height); "by fights" is what a rule paying only floors won would
give.

### No unlocks

| Option | Top | Fights mean / med | Floor med | Warden death | Boss death | Marks (by fights) |
|---|---|---|---|---|---|---|
| A board only | 22.1% | 21.1 / 21 | 21 | 2.2% | 1.6% | 35.2 (35.2) |
| B1 ladder earned, health ≥ 60% | 22.4% | 18.8 / 18 | 21 | 2.5% | 1.7% | 35.2 (32.9) |
| B1 ladder earned, health ≥ 75% | 22.0% | 19.2 / 18 | 21 | 2.5% | 1.7% | 35.1 (33.2) |
| B1 ladder earned, flawless | 21.9% | 20.1 / 19 | 21 | 2.3% | 1.7% | 35.1 (34.1) |
| B2 ladder offered, bot at ≥ 60% | 22.4% | 18.1 / 17 | 21 | 3.0% | 2.8% | 35.2 (32.2) |
| B2 ladder offered, bot at ≥ 85% | 21.8% | 18.4 / 18 | 20 | 2.7% | 2.4% | 34.9 (32.3) |
| S1 2 snakes, 50% health, refights heal | 35.5% | 26.6 / 28 | 25 | 3.1% | 2.0% | 41.7 |
| S1 2 snakes, 50% health, refights don't heal | 30.6% | 25.8 / 26 | 22 | 2.7% | 1.8% | 39.6 |
| S1 2 snakes, 30% health, no refight heal | 28.3% | 25.2 / 25 | 21 | 2.6% | 1.8% | 38.7 |
| S1 1 snake, 50% health, no refight heal | 27.8% | 24.0 / 24 | 22 | 2.5% | 1.8% | 38.2 |
| B1 (60%) + S1 1 snake | 27.8% | 21.4 / 21 | 22 | 2.9% | 1.8% | 38.2 (35.8) |
| C full board (d3) | 23.4% | 12.8 / 12 | 21 | 5.2% | 5.5% | 36.1 (26.1) |
| C, refights don't heal | 21.1% | 12.6 / 12 | 21 | 5.3% | 5.8% | 35.1 (25.3) |

### All unlocks

| Option | Top | Fights mean / med | Floor med | Warden death | Boss death | Marks (by fights) |
|---|---|---|---|---|---|---|
| A board only | 38.5% | 23.7 / 25 | 25 | 2.2% | 1.2% | 41.9 (41.9) |
| B1 earned ≥ 60% | 39.0% | 21.1 / 22 | 25 | 2.4% | 1.5% | 42.1 (39.4) |
| B1 earned ≥ 75% | 38.4% | 21.5 / 23 | 25 | 2.4% | 1.4% | 41.9 (39.7) |
| B1 flawless | 37.9% | 22.4 / 24 | 25 | 2.3% | 1.2% | 41.7 (40.5) |
| B2 offered ≥ 60% | 37.1% | 20.2 / 21 | 25 | 3.1% | 2.2% | 41.5 (38.1) |
| B2 offered ≥ 85% | 37.1% | 20.6 / 22 | 25 | 2.8% | 1.8% | 41.4 (38.4) |
| S1 2 snakes, refights heal | 59.1% | 28.6 / 30 | 30 | 2.7% | 1.4% | 49.5 |
| S1 2 snakes, no refight heal | 53.6% | 28.1 / 30 | 30 | 2.7% | 1.3% | 47.7 |
| S1 1 snake, no refight heal | 48.3% | 26.5 / 30 | 29 | 2.5% | 1.3% | 45.9 |
| B1 (60%) + S1 1 snake | 48.4% | 23.6 / 25 | 29 | 2.6% | 1.7% | 45.8 (43.1) |
| C full board (d3) | 39.5% | 14.5 / 15 | 25 | 4.5% | 3.7% | 42.7 (31.5) |

### Where runs die (share of all deaths, no unlocks)

| Option | Top five floors | f20 | f25 |
|---|---|---|---|
| A | f17 11.7, f18 9.8, f19 8.3, f21 6.6, f11 6.1 | 4.8% | 7.7% |
| B1 ≥ 60% | f17 12.2, f18 8.4, f21 8.2, f19 7.9, f11 6.6 | 5.0% | 8.5% |
| B2 ≥ 60% | f17 11.8, f21 8.1, f18 7.4, f19 6.8, f11 6.6 | 7.7% | 9.9% |
| S1 1 snake | f17 14.7, f18 8.9, f21 8.7, f22 7.1, f11 6.1 | 5.0% | 8.0% |
| C | f20 10.4, f15 7.7, f18 7.5, f25 6.8, f21 6.6 | 14.0% | 15.1% |

The f20 and f25 columns are the death rate of each fight there.

### Sanity and degenerate cases

- A: the harness's loop gave the same run as `playTowerRun` on all 2000
  seeds, both configs (floor, status, health, marks). Numbers equal the
  baseline.
- Refights must draw a fresh fight stream. With the floor's own stream a
  refight replays the loss, and S1 measured +0.3 points only: an artefact.
- C looped on a first layout (three snakes in one stretch: every roll from
  the tail hit one); 12 of 4000 runs hit the 200-fight guard. With one snake
  per stretch between gates, and no snake just after a ladder's foot, the
  longest run was 36 fights and none looped.
- No option reached 0% or 100%. No run went on forever after the fix.

## What the numbers say

- **Ladders are neutral.** With levels granted on arrival, skipping a floor
  trades its fight for its spoils and card: the top moves by under a point.
  Ladders shorten the climb by 2–3 fights. The harder arrival of B2 shows
  up only as more deaths at the gates (f20 4.8% to 7.7%).
- **Snakes are extra lives**, and strong ones: one snake lifts the top by
  6 points (none) and 10 (all); two by 8 and 15. A refight that heals is
  worth another 5 points and is the farmable part.
- **The full board halves the run** (13–15 fights) but loses about half the
  spoils and oaths. Gates become the killers: f20 and f25 death rates triple.
  The top stays near baseline only because levels come by height.

## A. Board only

- Player: sees the floors as a board, the hero on a square, one square a win.
- Rules: none.
- Core: none. UX-2: the board view (30 squares, gates marked, the hero's
  square from `run.floor`).
- Retune #5: independent.

## B. Ladders and snakes as events

Pick: **B1, a ladder earned by winning with 60% health or more**, and
**S1, one snake a run**.

- Player: two or three squares carry a ladder. Win there with 60% of your
  health and you may climb 2–4 floors, up to the next warden or boss (never
  past one). Lose an ordinary fight once and a snake drops you 2–4 floors, no
  lower than the floor after the last gate, at half health; the second loss
  ends the run. A warden or boss loss always ends it.
- Why B1 over B2: same top, no hidden harder fight, and the condition is
  visible on the screen. "Flawless" fires on a third of ladders only.
- Why S1 over S2: the bot always swears an oath, so S2 never fires for it;
  for a player it punishes a choice the Tower rewards with a mark. S1 reads
  as the board game: a fall, not a death.
- Skipped floors: levels granted on arrival (by height); their spoils and
  cards are lost; marks paid by height.
- Floors met twice: the same foes (the floor is drawn from the seed), a
  fresh fight. No spoils, no card, no recovery a second time. Height (a new
  `crest` field) never goes down, so levels and marks can't be farmed.
- Gates: never skipped; a ladder stops at one.
- Old saves: `crest` absent reads 0. The ladders come from a new stream,
  `TowerStream.board`, added last (no other draw moves). A run saved before
  carries no board version and plays as today.
- Core PRs: 2. (1) `crest`, the revisit rule, the snake on a loss, the bot.
  (2) Ladders: the layout, the earned check (the fight's health left, kept
  on the run while choosing), the take or decline move, the bot. Tests for
  both, and the simulator report.
- UX-2: the board with ladder and snake squares (from the seed), the hero's
  square, the height reached; a "Climb the ladder?" card after a won fight;
  the snake's fall; refights marked "no reward".
- Retune #5: tune once with the snake in. One snake is worth +6/+10 points
  at the top, about what less healing would take away; ladders change
  nothing to tune.

## C. Full board

- Player: after a win, roll a d3 and move 1–3 squares; the move stops at a
  warden or boss. Ladders climb, snakes slide, rests heal 40%. Every square
  landed on is a fight; squares passed are not fought.
- Rules: the move die, the layout (3 ladders, 3 snakes, 3 rests a run),
  levels and marks by height, revisits pay nothing. Shops were not
  prototyped (the Tower has no gold; marks could pay).
- Measured: 13–15 fights, top near baseline, gate deaths up to 15%. Spoils
  and oaths a run fall by about half.
- Core PRs: 3–4 (board model and save, move die and squares, layout rules
  against loops, rewards retune, bot and simulator).
- UX-2: the whole board screen, the move die and its animation, ladders,
  snakes and rests drawn, the path of each move.
- Retune #5: tune with it; it changes where the run is hard (the gates),
  so a retune made before it would not hold.

## Recommendation

B: an earned ladder (60% health) and one snake a run, built as two Core PRs
with the board view of A as UX-2's part. Tune #5 once, with the snake in.
Leave C for later: it halves the run, cuts the rewards, and needs layout
rules to avoid loops.

## Order with #5 (the curve retune)

- **If the user picks B:**
  1. Build B's first PR: the snake, the height, and refights paying nothing.
  2. Re-run #5's tuning once with the snake in, and ship the two together.
  - The #5 candidate (heal 30% to 15%, reshaped extras) is a good starting
    point. The snake gives about +6 points at the top, so the retune mostly
    needs a slightly harder curve on top of it.
  - Tuning #5 now and again after the snake would tune twice.
- **If the user picks A or nothing:** #5's candidate ships as it is, after
  #965.
- **C:** a retune made before it would not hold. Tune with the board in, if
  it is ever picked.
