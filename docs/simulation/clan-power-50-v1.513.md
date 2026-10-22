# Clan power over 50 playthroughs, re-run at v1.513 ("clan power that moves")

The same 50 runs as QA's [clan-power-50](../qa/clan-power-50.md) and the [v1.500 study](clan-power-50-v1.500.md): seeds 7000 to 7049, with the same strategy, profession and race rotation. "Before" is `main` at v1.509, which already holds Narrative's 19 choice `power` blocks and the two upheaval events (#466). "After" is this change: the simulator fires the politics events, the vote's result waits for a vote, and the war turn swings harder. A middle column, "events", is the simulator change and the trigger fix without the new war rules, to tell the two apart. All three ran on top of v1.509 (v1.512's land crossings came later). The harness is `test/qa_clan_power_50_test.dart` (it now loads `politics_events` and writes the events fired and the power choices taken) and the report is `tool/clan_power_report.py`. The raw data (after) is [clan-power-50-v1.513.json](clan-power-50-v1.513.json).

## What was missing

- **(a) Story choices with power** worked end to end in the app and the simulator: a choice's `power` goes through `applyStoryPolitics`, is applied once under its key, raises spare the clan's neglect, and the save keeps it. Nothing to build.
- **(c) The upheavals** fired in the app (on the chapter change and the day's tick, `runCoastEvents`), with their variants and the `anyPowerAtLeast` half-size gate. Two gaps:
  - **The simulator fired no politics event at all**, the two new ones nor the 26 older ones (`lantern_bearer_dies`, `returned_taken`, `coal_stops`...). It now does, as the app: at each scene the walk enters, after a new chapter's turn (`SimGrowth.runEvents`, with `politics_events` in its tables; the simulator screen loads it too). A choice's `event` fires there too, and a choice's `control` goes through `givePlace` (news, relations, the fall) as in the app.
  - **`wrack_vote_result` fired in every run reaching chapter 5**, and with no vote it took its last variant, "refused" (Dominion −8, the Spire Stair to the Compact). `5100_vote` is a branch: 32 of the 50 runs never see it. The trigger now asks for `vote_carried` or `vote_refused` (a list of two triggers), so it fires in the 19 runs that voted, whenever the vote is cast from chapter 5 on.
- **(b) The war turn** (`territoryTurn`, clan_power.dart), new:
  - a place taken in war: the taker **+5** (`warSpoils`), the loser **−8** (`warLoss`) unless it falls;
  - taking a clan's **seat** in war needs a lead of **25** (`seatLead`); its other places still 15 (`warLead`);
  - a **fallen clan's survivors regroup**: +5 a chapter (`fallenRegroup`), up to 20 (`fallenRegroupCap`), just short of Rising, so rising again still takes the character's help (a gift, a quest, a choice);
  - a fallen clan back at Rising **takes its seat back** unless its holder is 25 stronger (before: only from a weaker holder).

## Before and after

| Clan | end power | at 0 at the end (of 50) | fell | patron falls | backed: end power (runs) | backed ends first |
|---|---|---|---|---|---|---|
| Dominion | 72.7 → 69.2 → 70.4 | 0 → 0 → 1 | 0 → 0 → 1 | 0 → 0 → 0 | 99.8 (5) → 100 (4) | 5 of 5 → 4 of 4 |
| Vigil | 44.2 → 42.0 → 40.6 | 0 → 1 → 2 | 0 → 1 → 2 | 0 → 0 → 0 | 60.9 (17) → 80.4 (12) | 5 of 17 → 4 of 12 |
| Compact | 58.5 → 48.6 → 51.3 | 0 → 14 → 5 | 0 → 14 → 16 | 0 → 0 → 0 | 96.2 (10) → 99.1 (8) | 9 of 10 → 8 of 8 |
| Mire | 11.0 → 4.9 → 22.8 | **35 → 43 → 0** | 35 → 48 → 46 | 0 → 4 → 3 | 49.3 (3) → 49.0 (5) | 0 of 3 → 1 of 5 |
| Crows | 48.7 → 49.0 → 49.0 | 0 → 0 → 0 | 0 → 0 → 0 | 0 → 0 → 0 | 99.0 (6) → 100 (9) | 5 of 6 → 9 of 9 |
| Penitents | 28.0 → 34.6 → 35.4 | 9 → 1 → 0 | 9 → 2 → 1 | 2 → 1 → 0 | 71.7 (9) → 81.8 (12) | 7 of 9 → 7 of 12 |

Before → events → after; the backed columns are before → after. "Fell" counts the runs in which the clan fell at least once; "patron falls" the runs whose patron at the end fell during the run.

**Power at the start of each chapter** (mean, and at the run's end):

| Clan | | c2 | c3 | c4 | c5 | c6 | c7 | c8 | end |
|---|---|---|---|---|---|---|---|---|---|
| Dominion | before | 63 | 65 | 66 | 67 | 70 | 71 | 73 | 72.7 |
| | after | 63 | 65 | 68 | 71 | 73 | 73 | 70 | 70.4 |
| Vigil | before | 28 | 30 | 34 | 35 | 40 | 41 | 42 | 44.2 |
| | after | 28 | 30 | 34 | 35 | 40 | 42 | 40 | 40.6 |
| Compact | before | 39 | 41 | 46 | 50 | 56 | 57 | 58 | 58.5 |
| | after | 39 | 41 | 44 | 42 | 49 | 52 | 51 | 51.3 |
| Mire | before | 23 | 19 | 16 | 14 | 16 | 15 | 11 | 11.0 |
| | after | 23 | 22 | 7 | 10 | 14 | 18 | 23 | 22.8 |
| Crows | before | 45 | 45 | 46 | 48 | 50 | 50 | 49 | 48.7 |
| | after | 45 | 45 | 47 | 50 | 51 | 50 | 49 | 49.0 |
| Penitents | before | 23 | 22 | 24 | 24 | 26 | 27 | 27 | 28.0 |
| | after | 23 | 22 | 24 | 29 | 33 | 33 | 34 | 35.4 |

**The map moves more:** 4.5 → 5.7 → 5.8 places change hands a run (2 to 10; Core's aim is 2 to 6), wars 73 → 132 → 126 of them. One chapter's net change of a clan is 8 points or more in 12% → 14% → 16% of the clan-chapters; the largest fall in one chapter is −43 → −68. The share of the points moved by the story (choices and events) is 2% → 5% → 4%. The lead changes hands during the run in 41 to 45 runs of 50 in all three.

**The upheavals:** the vote's result fired in 19 runs (carried and read 7, carried 6, refused 6); the Conclave in all 50, always full size (the Dominion never drops under 50 before chapter 7 here). In 22 runs `way_force` moved the Lantern Hall (11 of them to the Open Hand), in 11 `way_quiet` raised the Dominion. Of Narrative's 19 choices, the walk takes 12: the most taken are `5004_altar` "Wake them first" (29 runs) and `4999_standard` "Cut it free" (21).

## What it says

- **The events, not the war rules, are most of the change.** `returned_taken` (chapter 3) puts the Dominion at War with the Mire, `coal_stops` and `charter_reopened` with the Compact. With those firing, the Dominion takes the Mire's Court in chapter 4 in 40 runs and Emberwick, the Compact's seat, in 16. This is what the app already does; the simulator didn't play it before.
- **No clan is pinned at 0.** The Mire still falls in most runs (46), but its survivors regroup to 20 by the end, so it ends at 0 in no run (35 before). In runs 11 and 26 the Mire, backed late, fell in chapter 4 and rose again by chapter 8. The Compact, fallen in 16 runs, ends at 0 in 5 (fallen in chapter 8).
- **A backed clan reaches the top:** the Crows and the Compact always, the Dominion always, the Penitents in 7 of 12, the Vigil in 4 of 12, the Mire in 1 of 5. In run 21 (Compact) the Compact takes four Dominion places in war plus the Lantern Hall at the Conclave, and the Dominion falls in chapter 8: the one run of 50 where it does.
- **The patron rarely falls:** 3 runs of 50, all Mire runs where the player's standing with the Mire was still low (7 to 33) when the Dominion took its seat in chapter 4.
- **The seat lead** keeps a backed clan's seat a little longer: the Penitents fall in 1 run (9 before). It doesn't save the unbacked Mire, 35 to 45 points under the Dominion.

## The fights did not move (seed 7, 400 runs)

`boss_balance_test`'s 400 runs, before and after (the balance tests don't load `politics_events`, so this is the war turn alone): encounter win within 3 tries, cleric 69.0 → 68.2, mage 68.6 → 69.3, ranger 67.1 → 67.3, rogue 69.4 → 69.5, warrior 64.2 → 63.9. The boss mean is 51.5 → 51.5; the largest single move is Claimant Vane 42.1 → 39.4. `boss_balance`, `nemesis_quests` and `clash_balance` pass, with no bound changed.

With `politics_events` loaded as well (the simulator screen's own tables now), the professions are 68.4, 68.7, 63.8, 68.3, 63.8 (spread 4.9) and the boss mean 50.6: every bound holds, but the claimants are met differently (Vane 56 times instead of 137, Tallis 272 at 35.3%, Morrow 72 at 54.2%) and the Void Sovereign drops to 33.3% (35 ± 12). Whether the balance tests should load the events is QA's and the user's call.
