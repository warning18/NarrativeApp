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

## v1.545: the Grey Sands, and the cliffs' last two events (wave 17 item 4)

Core's part of `docs/proposals/wave17-core.md` §4, on Narrative's four `glass_*` events (`wave17-glass-shore.md`, numbers as written).

| Route | Chapter | Road | Biome / scene | Days | Events (weight) | Ruler |
|---|---|---|---|---|---|---|
| `anchorage_to_grave` | 6 | `anchorage_wreck` (the Glass Shoals), from the landing at the White Anchorage | `tear` (the Grey Sands' zone) / the desert kit | 2 | `glass_fulgurite` 2, `glass_hull_shelter` 1, `glass_drowned_well` 1, `glass_tear_pull` 1 | `rulerOneIn: 3`, but none at the start |
| `lantern_cliffs` | 7 | unchanged | unchanged | 2 | `cliff_salt_wind`, `cliff_tide_stair`, now `cliff_wrecker_lamp`, `cliff_gulls`, 1 each | `rulerOneIn: 0` |

Chapter 6's main quest (`7001#0`, "Sail for the White Fleet's grave") sails to the Anchorage and crosses the dunes to the Grave before `7300`, as chapters 4 and 7 cross from their landing.

**The ruler.** Nobody holds the Anchorage or the Grave at the start, and the Hollow Cape has no ruler, so `landRouteRuler` gives `''`, `rulerPool` is empty and the crossing draws only its biome: nothing new was needed. Once a clan holds the Anchorage, or most of its districts (the Penitents and the Dominion both claim its chapel), it rules the road and one day in three is its event (56% of two-day crossings). The Vigil's claim on the Hollow Shore's battlefield is not on this road.

**The cliffs' new events are mild.** Each has a sure way at no cost (the wreckers' cut, +25 gold; leaving the gulls be). A failed check costs 12% (lamp) or 10% (gulls), under the salt wind's 14%, so both keep weight 1.

**One crossing, 2,000 draws** (health 100, every ability +2, its chapter's checks; the headless walk's choices):

| Route | Average health lost | Worst | Arrived | Ruler met |
|---|---|---|---|---|
| `anchorage_to_grave`, unheld | 2.5% | 6% | 100% | 0% |
| `anchorage_to_grave`, a clan holds the Anchorage | 1.5% (friend, neutral) / 3.5% (hostile) | 7% | 100% | 56% |
| `lantern_cliffs`, four events | 1.5% (was 1.5%) | 3% | 100% | 0% |

**400 runs, attempt win % by chapter, v1.533 → with the route and the cliffs:**

| Seed | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 |
|---|---|---|---|---|---|
| 7 | 29.5 → 29.5 | 36.6 → 36.6 | 27.8 → 27.7 | 26.1 → 26.1 | 25.6 → 26.8 |
| 11 | 29.1 → 29.1 | 37.3 → 37.3 | 28.7 → 28.7 | 28.4 → 28.1 | 26.0 → 26.2 |
| 23 | 28.3 → 28.3 | 33.9 → 33.9 | 26.2 → 26.1 | 23.4 → 23.5 | 22.9 → 22.9 |

Chapters 1 to 5 do not move. By profession (seed 7): cleric 39.7 → 39.7, mage 36.4 → 36.6, ranger 36.1 → 36.1, rogue 33.1 → 33.2, warrior 34.8 → 35.1. Chapters 6 and 7 move by 0.3 points at most. Every run reaches an ending.
