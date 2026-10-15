# Clan power and territory (v5.2 step 6, PR 1)

The rules are in `lib/data/clan_power.dart`. The plan is `docs/proposals/territory-power-nemesis.md`, and the words are Narrative's, in `docs/proposals/territory-texts.md`. This PR changes no fight.

## The rules as built

- **Power** runs from 0 to 100, starting from `factions.json`'s `power`:

  | Clan | Dominion | Crows | Compact | Vigil | Penitents | Mire |
  |---|---|---|---|---|---|---|
  | Start | 60 | 45 | 40 | 30 | 25 | 25 |

  The minor holders also have a little power, but no neglect: the giants 20, the oni 15, the Tide-Kin 15, the Kindly 10.
- **Tiers:** Minor below 25, Rising from 25, Dominant from 50, Ascendant from 75.
- **Raised by:**
  - a gift taken from the clan: +2, or +4 for a heroic one;
  - a quest whose outcome raises its standing by 5 or more: +5;
  - a story choice's or politics event's `power`.
- **Each chapter's turn** (at the chapter's offer, live and in the simulator):
  - **Holdings:** +1 for each place the clan holds.
  - **Neglect:** −5 for a main clan the character did nothing for that chapter. A clan never falls more than 20 below its start this way.
  - **Claims:** a clan risen a tier above its start takes its next claim, if the place is free or its holder is weaker.
  - **Wars:** two clans at relation step 2 (War) or 1 (Blood feud) fight over places. A clan 15 or more points stronger takes one of the other's places: its own claims first, the seat last.
  - At most one change per clan per chapter.
- **A place changing hands:**
  - the old and new holders' relation drops a step;
  - a news line goes out (Narrative's 2a to 2d);
  - the clan log gets a "Territory" line (2e).
- **The fall:** a main clan left with no place falls, and its power goes to 0. Back at Rising, it may take one claim again, its seat first, which ends the fall.
- **The live holder** (`holderOf`) replaces the starting map wherever a holder is read: shop prices and the place card.
- **Not in this PR:**
  - power from fights in held lands and from subclan boons (they come with reinforcements, PR 3);
  - the crisis before your own clan's seat falls (PR 2b).

## Measured

200 runs (seed 23), `POWER_RUNS=200 flutter test test/clan_power_test.dart`.

Each power column is the clan's average power at the run's end, grouped by the clan the run was sworn to. "Changes" is the average number of places changed per run. "Fallen" is the number of runs in which some clan fell.

| Sworn to | Runs | Dominion | Vigil | Compact | Mire | Crows | Penitents | Changes | Fallen |
|---|---|---|---|---|---|---|---|---|---|
| (none) | 4 | 68 | 10 | 41 | 8 | 58 | 17 | 2.3 | 1 |
| Compact | 39 | 77 | 28 | **88** | 19 | 71 | 7 | 3.8 | 3 |
| Crows | 26 | 74 | 17 | 54 | 25 | **97** | 22 | 4.3 | 1 |
| Dominion | 27 | **91** | 20 | 63 | 15 | 71 | 10 | 3.9 | 2 |
| Mire | 16 | 62 | 23 | 77 | **61** | 76 | 5 | 4.3 | 1 |
| Penitents | 36 | 67 | 33 | 32 | 6 | 64 | **63** | 3.5 | 4 |
| Vigil | 52 | 65 | **55** | 61 | 14 | 48 | 27 | 2.9 | 4 |

- **The map moves 3 to 4 times a run**, inside the 2 to 6 aimed for. 3 runs of 200 see no change; the most in one run is 7. Of all the changes, 642 were claims and 81 were wars.
- **The clan you back grows:** it ends 25 to 50 points above where it started.
- **The ones nobody backs shrink:** the Mire and the Penitents end at 5 to 25 unless backed. The Penitents lose places to the Dominion, with which they start at War.
- **The commonest changes:**
  - the Crows take the Lantern Alleys (147 runs) and the High Quay (87);
  - the Compact takes the Ash-Market (134) and the Ship-breaker's Yard (69);
  - the Dominion takes the Landward Gate (56);
  - the Vigil takes Rimewell (52);
  - the Penitents take the Wall of Names (36).
