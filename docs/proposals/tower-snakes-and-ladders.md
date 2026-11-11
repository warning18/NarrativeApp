# Tower: floor events that move the climb (Core proposal, v2)

The user's ask: "For the ladder and snake it is only as mechanic, not
graphics. Some floors may propose tougher opponents but skip levels, some
may bring you back to a down level if failed a skill test." The board picture
of v1 (options A, B, C) was dropped at the user's request. Nothing is drawn.
These are floor events.

Measured with the bot on seeds 1–2000, no unlocks and all unlocks, on the #5
curve candidate (2f46d3ad, on PR #965). Nothing here is built. The prototype
was a throwaway change to `lib/data/tower/` and a throwaway test.

## Shared rules (every event)

- **Height.** A new field `crest` holds the highest floor cleared. Levels,
  the hero's replay, stat picks and marks read `max(floorsCleared, crest)`.
  A fall never takes a level or a mark away.
- **A floor met again** (any floor at or below `crest`): same foes, a fresh
  fight stream, no spoils, no card, no healing, no event.
- **Gates are never skipped or fallen past.** A skip stops on the floor
  before the next warden or boss. A fall stops on the floor after the last
  gate beaten.
- **Skipped floors.** Their level-ups arrive on landing (their max health is
  added). Their spoils and cards are lost. Marks are paid by height.
- **Events** are drawn per ordinary floor from a new stream,
  `TowerStream.board`, added last, so no other draw moves. One event at most
  per floor, played once.

## Harness

Baseline equals `playTowerRun` on 2000/2000 seeds, both configs: top 13.6%
(none), 28.7% (all), as expected. A refight draws `floor + 1000 × attempt`
on the fight stream. Every walk stops at 120 fights; none came near it (most
was 36).

Columns: top; fights mean / median; deaths over fights at wardens f5 / f15 /
f25 and bosses f10 / f20 / f30; the worst ordinary floor (the
shortcut fights themselves left out); mean health share entering floors
21–30; marks per run.

### No unlocks

| Event | Top | Fights | Wardens 5/15/25 | Bosses 10/20/30 | Worst ordinary | HP 21–30 | Marks |
|---|---|---|---|---|---|---|---|
| #5 baseline | 13.6% | 18.1 / 17 | 1.7 / 9.0 / 12.2 | 9.0 / 11.9 / 22.8 | f27 8.2% | 0.74 | 28.6 |
| Shortcut Elite, bot ≥ 70% | 11.1% | 16.4 / 15 | 2.0 / 8.7 / 13.0 | 10.5 / 11.8 / 21.1 | f26 13.5%* | 0.73 | 27.4 |
| Shortcut Elite, ≥ 80% | 11.5% | 16.7 / 16 | 2.0 / 8.4 / 12.2 | 10.3 / 11.7 / 22.0 | f28 9.2% | 0.73 | 27.6 |
| Shortcut Elite, ≥ 90% | 11.7% | 16.9 / 16 | 1.9 / 8.4 / 12.7 | 10.2 / 11.7 / 22.8 | f26 12.0%* | 0.74 | 27.7 |
| Shortcut pack of 2, ≥ 70% | 11.2% | 16.3 / 15 | 1.9 / 8.5 / 12.9 | 10.6 / 11.9 / 19.7 | f26 12.5%* | 0.73 | 27.4 |
| Shortcut pack of 2, ≥ 90% | 11.9% | 16.8 / 16 | 1.8 / 8.3 / 12.6 | 10.4 / 11.5 / 21.7 | f26 11.2%* | 0.74 | 27.7 |
| Shortcut Elite ≥ 70%, soft loss | 12.8% | 16.9 / 16 | 2.0 / 8.8 / 12.9 | 10.5 / 11.7 / 21.6 | f28 9.8%* | 0.72 | 28.3 |
| Shortcut Elite ≥ 80%, card on landing | 11.6% | 16.7 / 15 | 2.0 / 8.6 / 11.6 | 10.5 / 11.3 / 22.7 | f28 9.1% | 0.73 | 27.6 |
| Setback, d20 check, cap 1 | 12.8% | 18.9 / 18 | 1.6 / 9.6 / 12.2 | 9.0 / 12.2 / 23.1 | f28 8.2% | 0.74 | 28.1 |
| Setback, d20 check, cap 2 | 12.4% | 19.3 / 18 | 1.6 / 9.3 / 11.9 | 8.9 / 12.4 / 22.2 | f28 8.8% | 0.73 | 27.9 |
| Setback, face in 2 rolls, cap 1 | 12.8% | 19.1 / 18 | 1.6 / 9.3 / 13.2 | 9.2 / 11.3 / 23.2 | f24 8.1% | 0.74 | 28.0 |
| Setback, face in 2 rolls, cap 2 | 10.9% | 19.5 / 18 | 1.6 / 9.0 / 14.3 | 9.7 / 12.6 / 24.8 | f28 9.5% | 0.73 | 27.1 |
| Setback, goal ≥ 50% health, cap 1 | 11.6% | 18.4 / 17 | 1.6 / 9.0 / 12.2 | 10.4 / 11.0 / 23.2 | f26 8.8% | 0.73 | 27.5 |
| Setback, goal ≥ 50% health, cap 2 | 10.5% | 18.4 / 17 | 1.6 / 9.2 / 13.0 | 10.1 / 11.2 / 23.6 | f26 8.5% | 0.73 | 27.0 |
| Setback, goal ≤ 3 rounds, cap 2 | 10.5% | 18.8 / 17 | 1.6 / 9.5 / 12.9 | 11.7 / 11.6 / 21.9 | f17 8.8% | 0.72 | 26.2 |
| Gamble, forced | 12.4% | 17.9 / 17 | 1.9 / 9.1 / 12.9 | 9.4 / 11.9 / 23.7 | f28 8.8% | 0.74 | 28.1 |
| Gamble, bot ≥ 70% | 13.0% | 18.0 / 17 | 1.9 / 9.3 / 12.5 | 9.4 / 11.1 / 23.1 | f28 9.3% | 0.74 | 28.3 |
| Rest, down a floor, bot < 70% | 13.6% | 18.4 / 17 | 1.7 / 8.7 / 11.8 | 8.8 / 11.9 / 22.3 | f27 7.9% | 0.75 | 28.6 |
| Rest, lose next card, bot < 50% | 14.0% | 18.2 / 17 | 1.7 / 8.7 / 12.7 | 8.9 / 11.7 / 22.4 | f27 7.8% | 0.75 | 28.8 |
| Rival, win in ≤ 3 rounds | 13.3% | 17.4 / 16 | 1.9 / 9.0 / 12.3 | 9.4 / 11.2 / 23.1 | f28 8.8% | 0.74 | 28.4 |

### All unlocks

| Event | Top | Fights | Wardens 5/15/25 | Bosses 10/20/30 | Worst ordinary | HP 21–30 | Marks |
|---|---|---|---|---|---|---|---|
| #5 baseline | 28.7% | 22.1 / 24 | 0.3 / 7.2 / 11.9 | 4.1 / 8.2 / 19.1 | f28 5.1% | 0.80 | 37.5 |
| Shortcut Elite, ≥ 70% | 21.8% | 19.5 / 19 | 0.3 / 7.0 / 12.4 | 4.7 / 10.2 / 20.3 | f26 9.9%* | 0.79 | 34.8 |
| Shortcut Elite, ≥ 80% | 23.4% | 20.0 / 20 | 0.3 / 6.7 / 11.8 | 4.7 / 9.9 / 20.8 | f17 5.8% | 0.79 | 35.5 |
| Shortcut Elite, ≥ 90% | 25.2% | 20.6 / 21 | 0.3 / 6.8 / 11.6 | 4.6 / 9.1 / 19.9 | f27 7.2%* | 0.79 | 36.2 |
| Shortcut pack of 2, ≥ 70% | 22.9% | 19.8 / 20 | 0.3 / 7.0 / 12.1 | 4.4 / 9.8 / 20.2 | f26 9.9%* | 0.79 | 35.6 |
| Shortcut pack of 2, ≥ 90% | 25.7% | 20.7 / 21 | 0.3 / 6.8 / 11.7 | 4.2 / 9.0 / 19.9 | f27 7.0%* | 0.79 | 36.6 |
| Shortcut Elite ≥ 70%, soft loss | 26.3% | 20.5 / 21 | 0.3 / 6.9 / 12.0 | 4.7 / 10.1 / 21.2 | f27 6.8% | 0.78 | 36.7 |
| Shortcut Elite ≥ 80%, card on landing | 23.3% | 20.0 / 20 | 0.3 / 6.9 / 11.9 | 4.7 / 10.2 / 20.3 | f17 5.9% | 0.79 | 35.4 |
| Setback, d20 check, cap 1 | 27.4% | 23.0 / 24 | 0.3 / 6.9 / 12.1 | 4.5 / 8.5 / 20.1 | f28 5.3% | 0.80 | 36.9 |
| Setback, d20 check, cap 2 | 26.2% | 23.4 / 24 | 0.3 / 6.9 / 12.1 | 4.6 / 8.5 / 20.6 | f28 5.8% | 0.79 | 36.4 |
| Setback, face in 2 rolls, cap 1 | 27.6% | 23.2 / 24 | 0.3 / 7.1 / 12.2 | 4.1 / 8.6 / 19.7 | f28 5.2% | 0.80 | 36.8 |
| Setback, face in 2 rolls, cap 2 | 26.0% | 23.9 / 25 | 0.3 / 7.3 / 12.5 | 4.2 / 8.8 / 20.2 | f21 5.1% | 0.79 | 36.2 |
| Setback, goal ≥ 50% health, cap 1 | 26.3% | 22.4 / 23 | 0.3 / 7.2 / 12.5 | 4.2 / 7.8 / 20.2 | f28 5.4% | 0.79 | 36.4 |
| Setback, goal ≥ 50% health, cap 2 | 24.3% | 22.5 / 23 | 0.3 / 7.2 / 13.0 | 4.2 / 8.0 / 21.7 | f17 5.5% | 0.78 | 35.7 |
| Setback, goal ≤ 3 rounds, cap 2 | 23.9% | 23.3 / 23 | 0.3 / 7.1 / 12.5 | 4.2 / 8.8 / 20.7 | f21 5.4% | 0.78 | 35.1 |
| Gamble, forced | 28.4% | 22.0 / 23 | 0.3 / 7.1 / 11.5 | 4.1 / 8.0 / 20.1 | f28 5.2% | 0.79 | 37.4 |
| Gamble, bot ≥ 70% | 28.7% | 22.1 / 24 | 0.3 / 7.2 / 11.4 | 4.1 / 8.4 / 19.9 | f28 5.2% | 0.79 | 37.5 |
| Rest, down a floor, bot < 70% | 28.6% | 22.3 / 24 | 0.3 / 7.3 / 11.7 | 4.2 / 7.6 / 19.1 | f28 5.2% | 0.81 | 37.3 |
| Rest, lose next card, bot < 50% | 28.6% | 22.1 / 24 | 0.3 / 7.1 / 11.9 | 4.1 / 8.4 / 19.6 | f28 5.1% | 0.80 | 37.5 |
| Rival, win in ≤ 3 rounds | 28.6% | 21.4 / 23 | 0.3 / 7.5 / 11.7 | 4.5 / 8.5 / 19.5 | f28 5.3% | 0.80 | 37.3 |

\*: measured before the harness split the shortcut fights out, so the
figure includes them (a shortcut fight on f26 is a choice, not an ordinary
floor). With them split out (the ≥ 80% rows), ordinary floors reach 9.2%
(none) and 5.8% (all). Note #5 itself already has f27 at 8.2% (none).

## 1. Shortcut floors (the "ladder")

- **Rule.** On 1 in 5 ordinary floors (seeded; only where a skip is possible,
  so about 1.5 a run), before the fight: "Fight an Elite instead, and skip
  k floors" (k = 1–3, shown). Win: the floor's own spoils and card, then land
  k floors up, never past the floor before the gate. Lose: the run ends.
- Toughness: (a) the floor's foe as an Elite (`eliteStatMultiplier` 1.35;
  a pack floor gets one more foe); (b) a pack of 2 (the lone foe doubled).
  Both kill about 8–9% of the shortcut fights; (b) is a hair kinder.
- Taken and won (none / all): ≥ 70%: taken 70% / 78% of offers, won 91% /
  90%. ≥ 80%: 57% / 64%, won 92% / 91%. ≥ 90%: 47% / 52%, won 93% / 92%.
  About 1.0–1.5 floors skipped a run, 1.5–2.5 fights fewer.
- **It costs the top**: −2 points (none), −3 to −7 (all). The fight is a
  boss-sized risk, and the skipped spoils leave the hero lighter for the next
  gate (f10 boss 9.0 → 10.5%). It is a real choice, not a free ladder.
- **Card on landing**: measured neutral (11.6 vs 11.5, 23.3 vs 23.4). Give it
  (the floor below the landing deals its offer): it reads fairer and costs
  nothing. Spoils stay lost.
- **Soft loss** (lose: fall one floor at half the health you entered with)
  takes the cost back (12.8 / 26.3) but makes the offer close to free. Keep
  the hard loss: the user's "tougher opponents" reads as a real stake.

## 2. Setback floors (the "snake")

- **The skill test** reuses the story's check (`lib/data/ability_check.dart`):
  a d20 plus `checkBonusFor(score)` (`SimCharacter.abilityBonus`) against a
  DC, a natural 1 failing and a natural 20 passing (`checkPasses`). The odds
  are `checkChance`, which the screen can show. Kind by floor: strength,
  dexterity or wisdom; DC 10 + (floor − 1) ÷ 6 (10 to 14).
- **Rule.** On 1 in 4 ordinary floors, after the win and the card: the test.
  Pass: a potion (to the bag, or drunk if full). Fail: go down 1–3 floors
  (drawn, shown before the roll), never below the floor after the last gate.
  Setbacks a run: 1. With none left, the test is not offered.
- Measured tests:

| Test | Pass (none / all) | Runs set back | Refights a run | Top none / all |
|---|---|---|---|---|
| (a) d20 + stat, cap 1 | 71% / 71% | 63% / 71% | 1.0 / 1.2 | 12.8 / 27.4 |
| (a) d20 + stat, cap 2 | 71% / 71% | 63% / 71% | 1.5 / 1.8 | 12.4 / 26.2 |
| (b) die shows face X in 2 rolls, cap 1 | 52% / 51% | 79% / 86% | 1.3 / 1.4 | 12.8 / 27.6 |
| (b) same, cap 2 | 51% / 51% | 79% / 86% | 2.1 / 2.4 | 10.9 / 26.0 |
| (c) won with ≥ 50% health, cap 1 | 83% / 86% | 48% / 50% | 0.8 / 0.8 | 11.6 / 26.3 |
| (c) same, cap 2 | 80% / 83% | 48% / 50% | 1.1 / 1.1 | 10.5 / 24.3 |
| (c) won in ≤ 3 rounds, cap 2 | 58% / 57% | 73% / 82% | 1.9 / 2.3 | 10.5 / 23.9 |

- Pick **(a), cap 1**. It is the story's check, with odds a player can read;
  it costs about a point (−0.8 / −1.3) and a fight; refights kill 2–3%.
- (b) depends on the die more than the hero (a die without the face type
  fails), and half the runs fail it. (c) health punishes a hero already
  hurt: its refights kill 7–9%, a spiral. (c) rounds overlaps the rival.

## 3. Others

- **Rival** (keep). On 1 in 10 ordinary floors where a skip fits: win within
  3 rounds and skip the next floor. Beaten 53–56% of the time. Top −0.3 /
  −0.1, 0.7 fights shorter. Rewards a fast fight; no farming (once a floor).
- **Gamble** (drop). After the win, roll a d6: 5–6 skip a floor, 1–2 down
  one. Neutral (−1.2 / −0.3 forced, −0.6 / 0 opt-in): a coin with no
  decision in it.
- **Rest** (drop). Heal to full, then go down a floor (or lose the next
  card). With 15% healing it fires rarely for the bot (0.05–0.3 a run) and
  moves nothing (13.6 / 28.6). The "lose a card" form is a no-brainer when
  low. It adds a rule without changing the climb.

## Recommended set, measured together

Shortcut (Elite, k 1–3, card on landing, hard loss) on 15% of ordinary
floors; setback (d20 check, cap 1) on 20%; rival (≤ 3 rounds) on 10%. Bot
takes the shortcut at ≥ 80% health.

| Set | Top none / all | Fights none / all | Bosses 10/20/30 (none) | Bosses (all) | Worst ordinary none / all | HP 21–30 | Marks |
|---|---|---|---|---|---|---|---|
| #5 baseline | 13.6 / 28.7 | 18.1 / 22.1 | 9.0 / 11.9 / 22.8 | 4.1 / 8.2 / 19.1 | 8.2 / 5.1 | 0.74 / 0.80 | 28.6 / 37.5 |
| Set on #5 | 12.0 / 23.3 | 17.3 / 20.8 | 10.2 / 10.8 / 21.8 | 4.8 / 10.2 / 20.7 | 9.1 / 6.0 | 0.73 / 0.79 | 27.7 / 35.4 |
| Set, foes ×0.98 | 13.9 / 26.9 | 17.8 / 21.4 | 8.6 / 9.3 / 21.3 | 3.2 / 8.2 / 19.2 | 7.7 / 5.4 | 0.74 / 0.79 | 28.8 / 37.1 |
| Set, soft loss, ×0.98 | 15.1 / 29.9 | 18.2 / 22.0 | 8.7 / 9.5 / 21.4 | 3.2 / 8.1 / 19.1 | 7.7 / 5.9 | 0.73 / 0.79 | 29.4 / 38.2 |

- In the set: about 0.6–0.8 shortcuts taken a run (won 91%), 1.75–2.0
  tests (pass 71%, 52–57% of runs set back), 0.7–0.8 rivals (55% beaten).
- On #5 as it stands the set stays inside the top bands (12.0 / 23.3), but
  the f10 boss sits on its 10% edge and the worst ordinary floor reaches 9.1%.
- **Smallest #5 adjustment**: foe scale 1.14 → 1.12 (×0.98). It brings the
  top back to 13.9 / 26.9, f10 to 8.6%, f20 9.3% (just under the 10–15%
  band; all 8.2%), f30 21.3%, every ordinary floor under 8%.
- Wardens unchanged (f25 ~11–12%). No run near the guard (most 36 fights).

## Order with #5

Ship #5 first, then the events in one or two Core PRs, the last carrying the
foe scale 1.14 → 1.12 and the re-set QA bands. Cheaper because:
- the events move the top by 1.6 / 5.4 points, and one constant takes it
  back. #5's own shape (healing, extras, profession scales) holds with them.
- tuning once would hold #5, already measured, behind two more PRs, and its
  QA bands would be re-set anyway when the events land.
(v1 said the opposite for its snake: an extra life moved the top by +6 / +10,
too much for one knob. These events are small.)

PRs: (1) `crest`, the revisit rule, `TowerStream.board`, the event draw, the
setback test, the rival; (2) the shortcut (a choice before the fight: a new
saved field), the card on landing, the bot, the foe scale, the simulator
report and QA bands.

## State for UX-2 (the floor screen)

A view, `TowerEventView`, from `towerEventOf(run, data)` (null: no event, or
a floor met again):
- `kind`: shortcut, test, rival; `floor`.
- shortcut offer: `foeIds`, `elite` (or the pack), `skip` (k), `landsOn`
  (floor), `lossEndsRun` (true), `accepted` (null until chosen).
- test: `ability` (strength / dexterity / wisdom), `dc`, `modifier`,
  `chance` (`checkChance`), `fallTo` (floor on a fail), `gain` (potion).
- rival: `rounds` (3), `landsOn`.
- result (after it resolves): `roll`, `total`, `passed`, `landedOn`.
- `setbacksLeft`; `revisit` (this floor pays nothing: the "no reward" line).

On `TowerRun` (saved):
- `crest` (int, absent 0);
- `events` (int version, absent 0: no events);
- `setbacks` (int used);
- `shortcut` (bool?, the choice on the current floor);
- `lastEvent` (the result shown on the next floor: kind, roll, total,
  passed, from, to).
The "where you land" line reads `landsOn` / `fallTo`; the panel look is
UX-2's.

## Save compatibility

A run saved before has no `events` key: it reads 0, `towerEventOf` returns
null on every floor, and the run plays as today. `crest` absent reads 0, so
`heightCleared` equals `floorsCleared`. The board stream is added last: no
existing draw moves (2000/2000 seeds identical with events off).

## Notes for the build

- Stat picks of skipped floors are taken on landing; the replay
  (`towerHeroOf`) should draw them at the landing floor, as the screen does,
  or the replayed offers may differ.
- The health of the skipped floors' level-ups is added on landing.
- Events never sit on floors at or below `crest`, so none can be replayed.
