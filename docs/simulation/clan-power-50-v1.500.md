# Clan power over 50 playthroughs, re-run at v1.500

The same 50 runs as QA's [clan-power-50](../qa/clan-power-50.md): seeds 7000 to 7049, with the same strategy, profession and race rotation. They ran on `main` at v1.499 (before) and on the wave 16 simulator (after). Since v1.500 the simulator plays the seat crisis and keeps its gifts to the patron and its allies; see [sim-gaps.md](sim-gaps.md). No game number changed, so this is a pure A/B test of the simulated player. The harness is `test/qa_clan_power_50_test.dart` and the report is `tool/clan_power_report.py`. The raw data (after) is [clan-power-50-v1.500.json](clan-power-50-v1.500.json).

## Before and after

| Clan | end power | at 0 at the end (of 50) | patron falls | backed: end power (runs) | gift points a run |
|---|---|---|---|---|---|
| Dominion | 78.7 → 73.3 | 0 → 0 | 0 → 0 | 96.9 (7) → 100 (3) | +6.2 → +3.4 |
| Vigil | 31.6 → 46.0 | 4 → 2 | 2 → 0 | 53.1 (15) → 65.7 (18) | +18.6 → +27.1 |
| Compact | 60.7 → 63.9 | 0 → 0 | 0 → 0 | 90.0 (11) → 98.4 (9) | +21.0 → +23.8 |
| Mire | 9.1 → 11.8 | 39 → 37 | 0 → 0 | 66.3 (3) → 88.3 (3) | +8.0 → +8.9 |
| Crows | 65.3 → 45.0 | 0 → 0 | 0 → 0 | 94.0 (8) → 100 (5) | +15.8 → +6.3 |
| Penitents | 18.4 → 20.7 | 12 → 12 | 1 → 3 | 69.8 (6) → 61.8 (12) | +14.8 → +16.2 |

"Patron falls" counts the runs whose patron at the end (the sworn clan) fell during the run: 3 before and 3 after. "Backed" is the end power in the runs that clan was the patron.

**Shares of all the points moved** (main clans, absolute) hold: holding 28% → 27%, neglect 34% → 35%, gifts 27% → 27%, claims, wars and falls 9% → 9%, quests 1% → 1%, story 0% → 1%. The harness labels each step by the size of its change, so the paid crises' place moves probably count as story.

**Gift points a run:** 35.2 → 41.4 to the run's patron, 50.3 → 44.4 to the other clans, many of them its allies. Of the 2,443 cards taken after the change, 206 came before the run had a patron, 1,165 from the patron, 886 from its allies, 128 were neutral (the wayfarer, your own hand) and 58 from another clan (when nothing else was left).

**Crises:** 2 in 50 runs. Both were defended and lost, then paid.

## What it says

- **Patrons barely fell even before.** At v1.499 only 3 of the 50 runs saw their patron fall, against 9 in QA's v1.453 study. Both Vigil falls are gone: in run 40 the Vigil keeps Rimewell, and run 35 now backs the Penitents. The 3 Penitent falls after the change came while the run's main clan was still the Vigil (standing 87 to 100, not yet sworn to the Penitents), so no crisis was due, as in the app. The Penitents had taken the Mire's Court and lost it to the Dominion's war.
- **Patron gifts move who leads.** Keeping to the patron makes the early patron stick, so the Vigil, the first clan many runs befriend, is backed in 18 runs instead of 15. The Penitents go from 6 to 12 and the Crows from 8 to 5. The Vigil ends 14 points higher. The Crows lose about 10 gift points a run and end 20 lower. The Dominion ends 5 lower.
- **Backed clans end near the cap** (Dominion, Compact and Crows at 98 to 100), except the Vigil (66) and the Penitents (62), whose seats the Dominion wars on.

## The fights moved (seed 7, 400 runs)

The simulated player who skips other clans' cards is weaker late in the run. Encounter win within 3 tries, by profession: cleric 70.8 → 67.9, mage 65.8 → 67.8, ranger 68.7 → 64.5, rogue 66.1 → 67.7, warrior 69.9 → 66.2. The spread is 5.0 → 3.4 points, inside `qa_sim_spread_test`'s 8.

The boss mean (the 11 bosses of `boss_balance_test`) went from 52.9% to 48.4%, inside the 42% to 58% band. The late bosses dropped: White Admiral 47.7 → 35.7, the claimants 44 to 49 → 37 to 42, Tear Herald 38.3 → 35.0, Void Sovereign 35.9 → 23.1. The Void Sovereign is now at the bottom of its band (35% ± 12). The crisis alone moves nothing: with the old gift rule, the boss mean is 53.2 and the professions are within 0.8 of before. Every bound still holds, but the chapter 8 bosses have little margin left.
