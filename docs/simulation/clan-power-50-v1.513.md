# Clan power over 50 playthroughs, re-run at v1.513 ("clan power that moves")

The same 50 runs as QA's [clan-power-50](../qa/clan-power-50.md) and the [v1.500 study](clan-power-50-v1.500.md): seeds 7000 to 7049, with the same strategy, profession and race rotation. "Before" is `main` at v1.512. It already holds Narrative's 19 choice `power` blocks and the two upheaval events (#466), but its simulator fires no politics event. "After" is this change. The harness is `test/qa_clan_power_50_test.dart`; it now loads `politics_events` and writes the events fired and the power choices taken. The report is `tool/clan_power_report.py`. The raw data (after) is [clan-power-50-v1.513.json](clan-power-50-v1.513.json).

## What changed

- **(a) Story choices with power** already worked end to end in the app and the simulator. A choice's `power` is applied once under its key, a raise spares the clan that chapter's neglect, and the save keeps it. Nothing to build.
- **(c) The upheavals** already fired in the app, with their variants and the `anyPowerAtLeast` half-size gate. Two gaps are closed:
  - **The simulator fired no politics event**: not the two new ones, nor the 26 older ones. It now fires them as the app does, at each scene the walk enters, after a new chapter's turn (`SimGrowth.runEvents`). A choice's `event` fires too. A choice's `control` gives the place through `givePlace`.
    - Every simulator test now loads `politics_events`, and `qa_sim_tables_test` requires it. `clash_balance_test` (`simulateFightsByChapter`, outside that guard) still runs without it.
  - **`wrack_vote_result` fired in every run that reached chapter 5.** With no vote, it took its last variant, "refused". The trigger now asks for `vote_carried` or `vote_refused`.
- **(b) The war turn** (`territoryTurn`, clan_power.dart):
  - **The spoils:** the clan that takes a place in war gains **5** power (`warSpoils`); the loser loses **8** (`warLoss`) unless it falls.
  - **Seats:** taking a clan's seat in war needs a lead of **25** (`seatLead`), against **15** for its other places. Seats fall to war only at the turns of **chapters 6 and 7** (`seatWarFromChapter`, `seatWarToChapter`): the story names the seats in chapters 3 to 5, and chapter 8 is the last battle.
  - **The Dominion's seat is guarded:** no claim or war takes Candlehold (`guardedSeatClans = {'dominion'}`, `seatGuarded`), so the Dominion never falls. Chapters 7 and 8 need it standing. A story choice or an event could still give Candlehold away; none does.
  - **The fallen regroup:** a fallen clan's survivors win back **+5** a chapter (`fallenRegroup`), up to **20** (`fallenRegroupCap`). The character's help is still needed to reach Rising (25). Back at Rising, a fallen clan takes its seat back unless the holder is 25 stronger.
- **Softened data** (`politics_events.json`, numbers only): `returned_taken`'s relation step, Dominion and Mire, is **0** (was −1). The Inquisition taking the Returned leaves the two Hostile instead of at War. Its news line is unchanged.

## Before and after

| Clan | end power | at 0 at the end (of 50) | fell | patron falls | backed: end power (runs) | backed ends first |
|---|---|---|---|---|---|---|
| Dominion | 72.9 → 66.7 | 0 → 0 | 0 → 0 | 0 → 0 | 100 (6) → 95.3 (7) | 6 of 6 → 6 of 7 |
| Vigil | 43.5 → 40.8 | 0 → 0 | 0 → 1 | 0 → 0 | 60.3 (15) → 73.7 (15) | 6 of 15 → 3 of 15 |
| Compact | 58.3 → 55.8 | 0 → 0 | 0 → 10 | 0 → 1 | 94.8 (11) → 84.5 (10) | 10 of 11 → 8 of 10 |
| Mire | 11.4 → 17.2 | **34 → 0** | 34 → 20 | 0 → 0 | 42.0 (4) → 71.5 (2) | 0 of 4 → 1 of 2 |
| Crows | 48.1 → 49.3 | 0 → 0 | 0 → 0 | 0 → 0 | 98.4 (5) → 100 (7) | 4 of 5 → 7 of 7 |
| Penitents | 27.6 → 33.9 | 10 → 1 | 10 → 2 | 1 → 0 | 80.9 (9) → 86.1 (9) | 8 of 9 → 7 of 9 |

- "Fell" counts the runs in which the clan fell at least once.
- "Patron falls" counts the runs whose patron at the end fell during the run.
- **The seats:** the Mire's Court falls in 34 → **20** runs: to the Penitents in 19, to the Dominion in 1. Emberwick, the Compact's seat, falls in 0 → **10**. Candlehold falls in none.

**Power at the start of each chapter** (mean):

| Clan | | c2 | c3 | c4 | c5 | c6 | c7 | c8 |
|---|---|---|---|---|---|---|---|---|
| Dominion | before | 63 | 65 | 66 | 68 | 70 | 71 | 73 |
| | after | 63 | 65 | 64 | 66 | 68 | 70 | 67 |
| Vigil | before | 28 | 30 | 34 | 35 | 40 | 41 | 42 |
| | after | 28 | 30 | 34 | 35 | 40 | 39 | 39 |
| Compact | before | 39 | 41 | 46 | 50 | 55 | 57 | 57 |
| | after | 39 | 41 | 45 | 48 | 51 | 52 | 55 |
| Mire | before | 23 | 19 | 16 | 14 | 16 | 15 | 11 |
| | after | 23 | 22 | 21 | 19 | 17 | 15 | 17 |
| Crows | before | 45 | 45 | 46 | 48 | 50 | 49 | 48 |
| | after | 45 | 45 | 47 | 50 | 52 | 51 | 49 |
| Penitents | before | 23 | 22 | 24 | 24 | 26 | 27 | 27 |
| | after | 23 | 22 | 23 | 28 | 33 | 34 | 33 |

**The map moves more:**
- **Places changing hands:** 4.4 → **5.0** a run (2 to 9), of which wars 72 → 89.
- **Big swings:** a clan's net change in one chapter is 8 points or more in 12% → 14% of the clan-chapters.
- **The lead** changes hands during the run in 42 → 41 runs of 50.
- **The story's share** of the points moved (choices and events) is 4%.

**The upheavals:**
- **The vote's result** fires in the 18 runs that voted.
- **The Conclave** fires in all 50, always at full size, since the Dominion keeps 50 or more:
  - in 21 runs `way_force` gives the Lantern Hall to the claimed clan (12 of them the Open Hand);
  - in 6 `way_quiet` raises the Dominion;
  - in 8 the Dominion's own claimant;
  - in 11 `way_hard`;
  - in 4 `way_friends`.

## What it says

- **Before, the old simulator understated the wars.** It played no politics event, so the Dominion never went to War with the Mire (`returned_taken`) or the Compact (`coal_stops`, `charter_reopened`). Played as the app plays them, the unsoftened events cost the Mire its Court in about 46 runs of 50, nearly all to the Dominion in chapter 4.
  - Softened, with the seats safe until chapter 6, the Mire falls in 20 runs, mostly to the Penitents, its blood feud from the start.
  - Emberwick falls in 10.
- **No clan is pinned at 0:** the Mire ends at 0 in no run (34 before), and the Penitents in 1 (10 before).
- **A backed clan reaches the top:**
  - always: the Crows (7 of 7);
  - mostly: the Compact (8 of 10), the Penitents (7 of 9), the Dominion (6 of 7);
  - rarely: the Vigil (3 of 15), the Mire (1 of 2).
- **The patron rarely falls:** 1 run of 50, a Compact run.
- **The Dominion never falls**, by the guard. It still ends 30 runs with fewer places than it started: Alster's Black Hold (22), the Lantern Hall at the Conclave (21), the Spire Stair (11), the Spire of Judgment (3).

## The fights (seed 7, 400 runs, `boss_balance_test`'s plan)

Before is `main` at v1.512 without events. After is this branch with `politics_events` loaded, as the balance tests now run.

| | before | after |
|---|---|---|
| cleric | 68.6 | 67.0 |
| mage | 68.7 | 67.6 |
| ranger | 67.2 | 64.9 |
| rogue | 69.3 | 69.1 |
| warrior | 64.4 | 63.2 |
| Aurel Vane (75) | 79.1 | 79.1 |
| Void Stalker (65) | 69.2 | 67.7 |
| Hollow Court Inquisitor (55) | 61.9 | 59.1 |
| Bone Warden (55) | 55.9 | 55.0 |
| Void Archon (50) | 56.4 | 52.2 |
| White Admiral (45) | 38.4 | 38.9 |
| Claimant Vane (40) | 42.4 (125 met) | 39.3 (61 met) |
| Claimant Tallis (40) | 40.7 (135) | 35.6 (264) |
| Claimant Morrow (40) | 40.7 (140) | 48.0 (75) |
| Tear Herald (35) | 40.8 | 39.0 |
| Void Sovereign (35) | 43.2 | 37.7 |
| boss mean | 51.7 | 50.1 |

- **Encounter win by profession** (the first five rows) is within 3 tries; the professions spread over 5.9 points, inside the limit of 8.
- **Every boss is inside its band** (target ± 12), and the boss mean inside 42 to 58.
- **The claimants are met differently.** With the events, Tallis is the commonest claimant (`the_throne_filled` and the chapter-7 politics move the claims). The bands of all three hold.
- **No bound changed.** `boss_balance`, `nemesis_quests`, `clash_balance` and every simulator test pass.
