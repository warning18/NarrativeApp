# Clan power over 50 playthroughs, re-run at v1.526 ("the Mire keeps its Court")

The same 50 runs as the [v1.513 study](clan-power-50-v1.513.md): seeds 7000 to 7049, the same strategy, profession and race rotation, `test/qa_clan_power_50_test.dart` and `tool/clan_power_report.py`. "Before" is `main` (v1.519). "After" is this change. The raw data (after) is [clan-power-50-v1.526.json](clan-power-50-v1.526.json).

## What changed

- **The Mire and the Penitents start at Hostile (step 3)**, not at Blood feud (1). `relations.json`, the number only (wave 17, item 2).
- **The feud comes back through the story** (Narrative, `claude/narrative-feud`, merges after this): `reedholm_anniversary` (chapter 5), default variant, drops the pair 2 steps, back to Blood feud. The peace variant needs both `maren_absolved` and `liora_met`.

## Before and after

| | before (Blood feud) | after (Hostile) | after + Narrative's beat | after + beat, peace on one of three flags (local test) |
|---|---|---|---|---|
| The feud comes back at Reedholm | n/a | n/a | **50 of 50** | 23 of 50 |
| The Mire's Court falls | 20 (19 to the Penitents) | 1 (to the Dominion) | 20 (19) | **10** (9) |
| Emberwick falls | 10 | 10 | 10 | 10 |
| Candlehold falls | 0 | 0 | 0 | 0 |
| The Mire at 0 at the end | 0 | 0 | 0 | 0 |
| The patron falls | 1 | 1 | 1 | 1 |
| Places changing hands a run | 5.04 (2 to 9) | 4.48 (1 to 8) | 5.04 | 4.74 (2 to 8) |
| Places taken in war a run | 1.84 | 1.36 | 1.84 | 1.60 |
| The lead changes hands (runs) | 41 | 41 | 41 | 42 |
| Mire end power | 17.2 | 16.7 | 17.2 | 16.7 |
| Penitents end power | 33.9 | 33.6 | 33.9 | 33.2 |

- **Narrative's beat as written fires its default variant in every run.** In the 50 runs, at the start of chapter 5, `maren_absolved` is set in 4 and `liora_met` in 8, never both. So the feud always comes back, and the runs are the same as before: the beat only moves the war from chapter 1 to chapter 5, and the seats cannot fall to war before chapter 6.
- **Peace on either flag** (`maren_absolved` or `liora_met`): 12 of 50 at peace, the feud back in 38 (76%).
- **The last column** adds `refugees_aboard` (16 of 50, the refugees' skiff taken aboard in chapter 2) as a third way to peace, one variant a flag: the feud comes back in 23 of 50, the Court falls in 10, the war moves stay at 1.60. It is a measurement only; Narrative picks the condition. Other flags set in about half the runs by chapter 5: `court_never_woke` (22, the union with the two flags gives the feud in 22), `court_fled` (21, 23).

**Power at the start of each chapter** (mean): within 2 points of before for every clan and chapter. The Mire ends chapter 7 at 17 against 15, chapter 8 at 16 against 17.

## The fights (seed 7, 400 runs, `boss_balance_test`'s plan, `politics_events` loaded)

| | before | after | after + beat |
|---|---|---|---|
| cleric | 67.0 | 67.0 | 67.0 |
| mage | 67.6 | 67.5 | 67.7 |
| ranger | 64.9 | 64.9 | 64.9 |
| rogue | 69.1 | 69.3 | 69.1 |
| warrior | 63.2 | 63.2 | 63.2 |
| Claimant Vane (40) | 39.3 (61 met) | 36.7 (60) | 39.3 (61) |
| Claimant Morrow (40) | 48.0 (75) | 48.7 (76) | 48.7 (76) |
| Tear Herald (35) | 39.0 | 38.5 | 39.3 |
| boss mean | 50.1 | 49.9 | 50.2 |

- The other bosses move by 0.1 or less. Every boss is in its band; no bound changed.
- `boss_balance`, `nemesis_quests`, the clan and politics tests, `qa_sim_tables` and the simulator tests pass.
- **`clash_balance_test` fails at seed 11**: chapter 2's gap goes from 0.029 to 0.114 (limit 0.10), because `relations` is in its tables and the seeded stream shifts. Wave 17 item 3 (pooled seeds) is the planned fix.
