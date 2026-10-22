# Land crossings by who holds the land (wave 16 item 3)

Core's part of `docs/proposals/wave16-core.md` §3. Three new routes in `land_routes.json`. The chapter 4 and 5 routes have `rulerOneIn: 3`; one day in three is the road's ruler's event, at the band the party's standing puts it in (`landRouteRuler`, `rulerPool`, `drawCrossing` in `lib/data/land_crossing.dart`).

| Route | Chapter | Road | Biome | Ruler at the start of a run |
|---|---|---|---|---|
| `stair_to_court` | 4 | `cloister_court` | fen | Mire (the Drowned Cloister's one held district) |
| `reliquary_to_heart` | 5 | `reliquary_heart` | frost | Dominion (the Frost Reach's ruler) |
| `lantern_cliffs` | 7 | `camp_candlehold`, from the landing | sea cliffs | Dominion (Candlehold) |

Measured with Narrative's `land_events.json` from `claude/narrative-land-events` (draft numbers unchanged).

**One crossing, 2,000 draws** (health 100, every ability +2, its chapter's checks):

| Route | Average health lost (no gold / 100 gold) | Worst | Arrived | Ruler met |
|---|---|---|---|---|
| `stair_to_court` | 3–8% / 2% | 22% | 100% | 71% |
| `reliquary_to_heart` | 6–10% / 4–5% | 22% | 100% | 71% |
| `lantern_cliffs` | 2–4% / 2% | 8% | 100% | 56%, now 0% |

**Chapter 7's cliffs meet no ruler** (`rulerOneIn: 0`, set after these runs): only Narrative's two mild cliff events, as chapter 7 already reads hard. The Dominion's toll there cost at most 4% health or 30 gold, so the runs below hold or slightly understate chapter 7.

A headless walk takes the way round: at chapter 7 the cliffs' checks are DC 18, so it waits for the ebb and goes inland (1–2%).

**400 runs, attempt win % by chapter, main → with the crossings:**

| Seed | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 |
|---|---|---|---|---|---|
| 7 | 29.6 → 29.6 | 37.0 → 37.0 | 28.8 → 28.9 | 26.3 → 26.5 | 26.4 → 27.5 |
| 11 | 27.5 → 27.4 | 34.7 → 34.7 | 28.2 → 28.2 | 24.6 → 23.2 | 23.1 → 23.5 |
| 23 | 28.1 → 28.1 | 35.3 → 35.2 | 27.4 → 27.7 | 24.2 → 23.4 | 24.1 → 25.0 |

Chapters 1 to 3 do not move. By profession (seed 7): cleric 38.0 → 37.9, mage 37.4 → 37.6, ranger 36.5 → 36.4, rogue 34.7 → 35.0, warrior 35.2 → 35.6. Chapter 7 moves −1.4 to +0.2 across the seeds (noise: the crossing's rolls come from their own stream but the walk diverges after it). `boss_balance`, `nemesis_quests` and `clash_balance` stay green with no bound changed.
