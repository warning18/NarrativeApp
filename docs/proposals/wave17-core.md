# Wave 17 on the rules side (Core, proposal)

Design only: nothing here is in the game yet. Written on v1.516.

Wave 16 made the clans move. Wave 17 should fix what the new numbers show: chapter 7 is two professions' wall, one starting feud costs the Mire its Court, and one balance test can't run on the real walk. Four items, each 1 to 2 PRs. Two need nothing from Narrative or UX. The user picks; the order at the end is my advice.

Unless said otherwise, numbers are from 400 runs at seed 7 with `boss_balance_test`'s plan (politics events loaded), measured on v1.516 with a throwaway harness that is not committed.

## 1. Chapter 7: the claimants stop walling the cleric and the warrior

**What the player gets.** A cleric or a warrior can take the Lantern Hall. Today they almost never do.

**Why now.** Wave 16 dropped this item because the claimants "sit on their target". That is only true on average. Split by profession, they are a wall for two of the five:

| Chapter 7 | Cleric | Warrior | Rogue | Ranger | Mage | All |
|---|---|---|---|---|---|---|
| Claimants won (80 met each) | **7.5%** | **16.2%** | 51.2% | 56.3% | 61.3% | 38.5% |
| Regular fights won | 63.5% | 71.2% | 76.3% | 67.7% | 75.4% | 71.1% |

- The claimants are 400 of chapter 7's 704 encounters (57%). The chapter is won 52.6%.
- The cleric beats Vane in 0 of 14 runs and Tallis in 5% of 57. The warrior beats Vane in 0 of 10 and Morrow in 0 of 13.
- This is also why the warrior is the lowest profession overall (63.2%, a spread of 5.9; `clan-power-50-v1.513.md`).

**Two levers I tried** (harness only, nothing shipped):
- **The claimants without their heals** (each one's phase heal of 8–12%, plus `second_wind` or `bind_wounds` at low health):
  - claimants 38.5 → 46.0%, chapter 7 52.6 → 56.8%;
  - warrior 16 → 30%, but the cleric only 7.5 → 8.8%;
  - Morrow goes to 53.3%, just over his band (28–52).
- **Tallis without her Light resist:** the cleric against her goes 5.3 → 12.3%. Not the answer either.

So the heals are the warrior's problem. The cleric's is something else: I suspect `edict_of_silence` and the hex on a caster who needs long fights.

**The rules.**
- First, a fight log of the cleric against each claimant (rounds, silenced turns, heals taken). Then fix that cause on the claimants, not on the cleric. The cleric wins 67.0% of its encounters over the whole run.
- Each claimant heals once a fight: its phase heal or its low-health move, not both. Morrow keeps 10 more health so he stays inside his band.
- Aim: every profession wins the claimants at 25% or more, and the claimants average about 45 (target 40, band 28–52, so no test target changes).

**Size.** S to M: 1 PR (numbers in `enemies.json`, and an enemy-move rule in `lib/combat/` only if "once a fight" needs one), measured at seeds 7, 11 and 23.

**From Narrative.** Nothing. **From UX.** Nothing.

**Risks.**
- The boss mean rises about 2 points (50.1 → about 52), still inside 42–58.
- The mage gains too (61 → 72% on the claimants without heals), so the spread in the boss test must stay under 8.
- Claimant bands at seeds 11 and 23. No save change.

## 2. The Mire keeps its Court: the Reedholm feud becomes a story beat

**What the player gets.** The Mire's Court falls when the story makes it fall, not because of a number set at the start.

**Why now.** In the 50-run clan study (`docs/simulation/clan-power-50-v1.513.md`), the Mire's Court falls in 20 runs, 19 of them to the Penitents. The cause is `relations.json`: Mire and Penitents start at Blood feud (step 1, "Reedholm"), so they are at war from the first chapter. The war rule (`warStep` 2) does the rest once the Penitents are 25 stronger at the chapter 6 or 7 turn. Emberwick falls in 10, all to the Dominion, through the wars that `coal_stops` and `charter_reopened` declare.

**What I tried** (the same 50 runs, harness only):

| | Mire's Court falls | Emberwick falls | Places taken in war a run | Mire end power | Penitents end power |
|---|---|---|---|---|---|
| v1.516 | 20 (19 to the Penitents) | 10 | 1.84 | 17.2 | 33.9 |
| Mire and Penitents start Hostile (3) | 1 | 10 | 1.32 | 16.7 | 33.6 |
| `seatLead` 25 → 30 | 16 | 10 | 1.66 | 17.0 | 34.0 |

The relation is the lever; the seat lead hardly moves anything. Starting Hostile goes too far: it takes back a third of wave 16's war moves.

**The rules.**
- Mire and Penitents start at Hostile (step 3).
- The feud comes back through the story: one chapter-4 or chapter-5 event (or one choice) drops them to Blood feud, so roughly half the runs see it. It is a `relation` step, which both the app and the simulator already apply.
- Aim: the Mire's Court falls in about 8 to 10 runs of 50, and the war moves stay at 1.6 or more.
- **Emberwick: leave it.** Its 10 falls come from wars the story declares, so they read as earned.
- **The Dominion's guard (`guardedSeatClans`): my advice is to keep it and close the question.** Seats fall to war only at the turns of chapters 6 and 7 (`seatWarFromChapter`, `seatWarToChapter`). Lifting the guard would only matter on those two turns, which are exactly the ones where chapters 7 and 8 need Candlehold standing. The user decides.

**Size.** S: 1 PR (`relations.json`, the step on Narrative's event, the 50-run study re-run).

**From Narrative.** The pair's new `reason` (EN and FR) for Hostile. Which event or choice brings back the feud, with its news line: Reedholm remembered, in chapter 4 or 5.

**Risks.**
- The Penitents gain less from war; their end power barely moves (33.9 → 33.6).
- `qa_sim_tables_test` and the clan tables in `docs/simulation/` shift.
- No fight moves. No save change: relations live in the politics state, and old saves keep their step.

## 3. `clash_balance_test` runs on the real walk

**What the player gets.** Nothing on screen. The last balance test that runs on an old walk moves to the walk the game actually plays.

**Why now.** `clash_balance_test` (`simulateFightsByChapter`) loads 18 tables: no `politics_events`, quests, houses or land crossings. It is the only simulator test outside `qa_sim_tables_test`'s guard (`sim-gaps.md`). With `politics_events` loaded (150 runs, the attempts won with the clash rules minus without them):

| Seed | Ch 2 | Ch 3 | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 | Mean, ch 2–8 |
|---|---|---|---|---|---|---|---|---|
| 11 | **0.105** | 0.063 | 0.053 | 0.056 | 0.046 | 0.063 | 0.042 | 0.061 |
| 7 | 0.080 | 0.084 | 0.086 | 0.080 | 0.077 | **0.113** | 0.052 | 0.082 |
| 23 | 0.082 | 0.065 | 0.029 | 0.056 | 0.060 | 0.068 | 0.035 | 0.056 |

- The clash rules are kinder in every chapter at every seed, by 6 to 8 points. That is systematic.
- Which chapter crosses the 0.10 limit is noise: it changes with the seed.
- I turned the clash rules off one at a time (seeds 7 and 11). No single rule causes the gap.
  - `execute` cut the mean gap to 0.033 at seed 11, but not at seed 7.
  - `goal` cut it to 0.034 at seed 7, but not at seed 11.
  - Every other rule moved each chapter's gap by up to ±0.04 in either direction: the noise of a 150-run sample.

**The rules.**
- Load the same tables as `boss_balance_test`, `politics_events` included.
- Pool seeds 7, 11 and 23 at 100 runs each (300 runs, against 150 today), and keep the 0.10 limit. The three seeds above, pooled, peak at 0.089 (chapter 2) and 0.081 (chapter 7).
- Add a guard on the mean gap over chapters 2–8 (under 0.08), so a rule that makes every fight kinder is caught even when no single chapter crosses 0.10.
- No game number changes. If the user would rather the clash rules be less kind, that is a separate tuning of `execute` and the goals, measured on this test.

**Size.** S: 1 PR, the test file only.

**From Narrative.** Nothing. **From UX.** Nothing. **For QA:** about twice the runs, so the test takes about twice as long. I'll report its time in the PR.

**Risks.** If the pooled numbers land near 0.10 after item 1 or 2, item 3 merges first and the others are measured against it. No save change.

## 4. A chapter 6 crossing, and the cliffs' last two events

**What the player gets.** A road of the Glass Shore plays as a crossing, and the Lantern Cliffs get their wrecker's lamp and gull colony.

**Why now.**
- `land_routes.json` has 6 routes. Chapter 6 and chapter 8 have none.
- Narrative's `cliff_wrecker_lamp` and `cliff_gulls` are written but unused: `lantern_cliffs` draws only `cliff_salt_wind` and `cliff_tide_stair`, because chapter 7 read hard (`docs/simulation/land-crossings.md`).
- A crossing costs 2–10% health and moved attempt wins by chapter by under 1.5 points. Chapter 8 is the last battle and stays without one.
- The 18 ruler events (6 clans, 3 bands) already exist, so a new route only needs its biome pool.

**The rules.**
- A chapter 6 route on an existing road of the Glass Shore (the dunes between the landing and the White Fleet's Grave; the PR picks the road), with a glass-shore biome pool of about 4 events.
- `rulerOneIn: 3` only once a clan holds the land (the Vigil claims the Hollow Shore's battlefield). At the start of a run nobody does, and the route draws only its biome.
- After item 1 lands, the cliffs draw all four of their events (wrecker's lamp: 12% on a failed check; gulls: +8 / −10), still with `rulerOneIn: 0`.
- Measure attempt wins by chapter at seeds 7, 11 and 23, as `land-crossings.md` did.

**Size.** M: 2 to 3 PRs. Core's route and the cliffs' pool (1), Narrative's glass-shore events (1), UX's backdrop (1, if no existing one fits).

**From Narrative.** About 4 glass-shore events, EN and FR, with their choices. **From UX.** A glass-shore backdrop for the side view, unless the sea-cliffs or arid-coast one can serve.

**Risks.** Chapter 6 is won 56.8% of encounters (seed 7; chapter 7 52.6, chapter 8 49.3), so the route stays mild (worst event about 10%). `story_graph_integrity` for the route's entry. A save made in the middle of a crossing keeps the old flow.

## Not proposed

- **Warding the road** works as planned: about 1.7 wards a run, stat-pick bans 10.4 → 9.2, every profession within 0.8 points. Nothing to fix.
- **The fall's scene** (bend the knee or stay) is the one gap left in `sim-gaps.md`. With the patron falling in 1 run of 50, it is not worth a PR yet.
- **The Void Sovereign** (37.7, target 35) and the boss mean (50.1) are fine.

## Order

1. **`clash_balance_test` on the real walk** (S). First, because items 1 and 2 are measured against it, and it changes no game number.
2. **Chapter 7's claimants** (S to M). The biggest gain a player will feel: two of the five professions can win the chapter.
3. **The Reedholm feud** (S), once Narrative has its event. It can go in parallel with item 2: no fight moves.
4. **The chapter 6 crossing and the cliffs** (M). Last: it needs chapter 7 settled and work from Narrative and UX.

**If only two fit: the claimants (§1) and the Reedholm feud (§2).** The claimants fix the worst thing a cleric or warrior player meets in the whole game. The feud costs Narrative one event and makes the Mire's fate a story beat instead of a starting number.
