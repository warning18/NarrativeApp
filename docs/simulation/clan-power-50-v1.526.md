# Clan power over 50 playthroughs, re-run at v1.526 ("the Mire keeps its Court")

The same 50 runs as the [v1.513 study](clan-power-50-v1.513.md): seeds 7000 to 7049, the same strategy, profession and race rotation, `test/qa_clan_power_50_test.dart` and `tool/clan_power_report.py`. "Before" is `main` (v1.523). "After" is this change alone. "After + beat" adds Narrative's Reedholm beat as shipped on `claude/narrative-feud` (it merges right after this). The raw data (after + beat) is [clan-power-50-v1.526.json](clan-power-50-v1.526.json).

## What changed

- **The Mire and the Penitents start at Hostile (step 3)**, not at Blood feud (1). `relations.json`, the number only (wave 17, item 2).
- **The feud comes back through the story** (Narrative): `reedholm_anniversary` (chapter 5) has four peace variants (both `maren_absolved` and `liora_met`, then each of `maren_absolved`, `liora_met` and `refugees_aboard`: one step warmer) and a default that drops the pair 2 steps, back to Blood feud.

## Before and after

| | before (Blood feud) | after (Hostile) | after + beat |
|---|---|---|---|
| The feud comes back at Reedholm | n/a | n/a | **23 of 50** |
| The Mire's Court falls | 20 (19 to the Penitents) | 1 (to the Dominion) | **10** (9 to the Penitents) |
| Emberwick falls | 10 (all to the Dominion) | 10 | 10 |
| Candlehold falls | 0 | 0 | 0 |
| The Mire at 0 at the end | 0 | 0 | 0 |
| The Penitents at 0 at the end | 1 | 0 | 1 |
| The patron falls | 1 | 1 | 1 |
| Places changing hands a run | 5.04 (2 to 9) | 4.48 (1 to 8) | 4.74 (2 to 8) |
| Places taken in war a run | 1.84 | 1.36 | 1.60 |
| The lead changes hands (runs) | 41 | 41 | 42 |
| Mire end power | 17.2 | 16.7 | 16.7 |
| Penitents end power | 33.9 | 33.6 | 33.2 |

- **The beat's variants:** peace in 27 runs (`maren_absolved` 4, `liora_met` 8, `refugees_aboard` 15, never both of the first two), the feud back in 23.
- **On target:** the Court falls in 10 of 50 (aim 8 to 10) and the war moves stay at 1.60 a run (aim 1.6 or more). Emberwick is unchanged.
- **The beat's first version** (peace only with both flags) fired its default in all 50 runs: the same runs as before.
- **Power at the start of each chapter** (mean): within 1.1 points of before for every clan and chapter.

## The fights (seed 7, 400 runs, `boss_balance_test`'s plan, `politics_events` loaded)

| | before | after | after + beat |
|---|---|---|---|
| cleric | 67.0 | 67.0 | 67.1 |
| mage | 67.6 | 67.5 | 67.8 |
| ranger | 64.9 | 64.9 | 65.1 |
| rogue | 69.1 | 69.3 | 69.5 |
| warrior | 63.2 | 63.2 | 63.2 |
| White Admiral (45) | 38.9 | 39.0 | 40.9 |
| Claimant Vane (40) | 39.3 (61 met) | 36.7 (60) | 39.7 (63) |
| Claimant Tallis (40) | 35.6 (264) | 35.6 (264) | 35.2 (261) |
| Claimant Morrow (40) | 48.0 (75) | 48.7 (76) | 47.4 (76) |
| Tear Herald (35) | 39.0 | 38.5 | 39.5 |
| Void Sovereign (35) | 37.7 | 37.8 | 37.0 |
| boss mean | 50.1 | 49.9 | 50.2 |

- The chapter 1 to 5 bosses do not move. Every boss is in its band; no bound changed.
- `boss_balance`, `nemesis_quests`, the clan and politics tests, `qa_sim_tables` and the simulator tests pass.
- **`clash_balance_test` fails at seed 11**: chapter 2's gap goes from 0.029 to 0.114 (limit 0.10), because `relations` is in its tables and the seeded stream shifts. Wave 17 item 3 (pooled seeds) is the planned fix.
