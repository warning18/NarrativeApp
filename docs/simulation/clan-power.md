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

## PR 2b: the crisis and the fall (v1.394)

The rules are in `lib/data/clan_crisis.dart`, with Narrative's words from `territory-texts.md` 3 and 4.

- **The crisis.** At a chapter's turn, a change that would take your main clan's seat, or its last place, waits. Your main clan is the one you are sworn to, else your patron. A scene comes on the next road at rest, before any hunter:
  - **Defend:** a fight with the attacker's hunter.
    - Won: the seat holds, the attacker loses 10 power, your clan gains 5 power and 5 standing.
    - Lost: you are still at the scene, and may pay or refuse.
  - **Pay:** 40 gold a chapter, offered only when you have it. The attacker takes a lesser place of your clan instead, if it has one.
  - **Refuse:** −10 standing, and the seat falls.

  Only one crisis waits at a time.
- **The fall.** When your main clan is left with no place, a scene asks you to choose:
  - **Bend the knee:** your standing with the fallen clan moves to the winner, so you are sworn to it if you were Sworn. The fallen clan drops to Resented, and the winner takes a fifth of your gold.
  - **Stay of the fallen clan:** no new oath, no patron's stats, and the clan's gifts kept. The winner is your nemesis, whatever its power. Raising your own banner (the Open Hand's `banner_raised`) ends it, and the fallen clan pledges to your Host; so does the clan rising again.
- **The Mire's seat** is the Mire's Court, a district of the Drowned Cloister with Narrative's name and blurb. The Mire now holds it from the start.
- **The simulator** plays no crisis: with no one to ask, seats fall as before. (Since v1.500 it does: see [sim-gaps.md](sim-gaps.md).)

## PR 4: offers, the throne, the materials price, the survivors (v1.400)

- **Power caps the signs a clan gives.** A Minor clan (under 25) gives signs up to epic; a Rising or stronger one, heroic too. Skills and objects keep their own rarity.
  - First planned: rare for Minor, epic for Rising. That put Claimant Tallis at 55.1% (target 40 ±12), against 50.7% before this PR.
  - With the softer cap, every boss is in its band. Tallis is at 49.6%.
- **The holder of the place comes more often:** in an offer made in a place a clan holds, its suitor weighs ×1.5 (`heldPlaceSuitorWeight`). The offer dialog reads the holder where the story stands (`holderHereProvider`).
- **A fallen clan sends no one,** except to the character who stayed of it: its survivors still come, and their gifts follow the standing as ever.
- **The Host:** a fallen clan comes only if it pledged. The Character tab's climb now breaks a tie on standing by power. An Ascendant clan's weight at the chapter-7 decision is the story's to write with the events' new `powerAtLeast` condition.
- **The crisis paid in materials:** "Send timber and stone" (3 timber and 2 cut stone, Narrative's line) is offered when the pack holds them. It settles the crisis like the gold: the attacker takes a lesser place instead. A choice's negative `grantMaterials` now takes the materials from the pack.

Per-profession win rates (100 runs, seed 11, no reinforcements), before → after: cleric 57.6 → 57.2, mage 81.9 → 81.5, ranger 75.1 → 74.9, rogue 74.3 → 73.7, warrior 70.2 → 69.9. All within 1 point, all slightly down (weaker signs from weak clans).

## Clan power that moves (v1.513)

The user's three levers (`docs/proposals/clan-power-story.md`). Narrative's 19 story choices with `power` and its two upheavals (`wrack_vote_result`, `conclave_counts`) were already live in the app. This change adds the war rules below and makes the simulator fire the politics events. The 50-run study is [clan-power-50-v1.513.md](clan-power-50-v1.513.md).

- **Wars swing harder.** A place taken in war: the taker gains 5 power (`warSpoils`), the loser loses 8 (`warLoss`) unless it falls.
- **Seats hold longer.**
  - Taking a seat in war needs a lead of 25 (`seatLead`); other places need 15.
  - Seats fall to war only at the turns of chapters 6 and 7 (`seatWarFromChapter`, `seatWarToChapter`).
  - **The Dominion never falls:** Candlehold is guarded from every claim and war (`guardedSeatClans`, `seatGuarded`). Empty the set to lift the guard.
- **The fallen regroup.**
  - A fallen clan gains 5 a chapter (`fallenRegroup`) up to 20 (`fallenRegroupCap`), short of Rising: rising again still takes the character's help.
  - Back at Rising, its seat rises for it unless the holder is 25 stronger.
- **Data (numbers only):**
  - `wrack_vote_result` fires from chapter 5 once `vote_carried` or `vote_refused` is set (before, every run got the "refused" variant).
  - `returned_taken` leaves the Dominion and the Mire Hostile instead of at War (relation step 0, was −1).
- **The simulator fires the politics events** as the app does. Every simulator test loads `politics_events`, and `qa_sim_tables_test` requires it.

In the 50 runs:
- the Mire's Court falls in 20 runs (34 at v1.512), Emberwick in 10, Candlehold never;
- no clan ends at 0 but the Penitents in one run;
- 5.0 places change hands a run;
- the patron falls in 1 run.

The fights hold: with the events, the boss mean is 50.1 (51.7 before), the professions are 5.9 points apart, and every band holds.
