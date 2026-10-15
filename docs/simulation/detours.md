# Detours: the Wave 11 engine

This is the engine side of docs/proposals/detours-wave11.md (section 6 [C]), with the user's decisions D1, D2 and D8 from the 50-run audit.
- `lib/data/detour_scenes.dart`: Narrative's written scenes, from `assets/gamedata/detour_scenes.json`.
- `lib/data/detour_pacing.dart`: when a detour comes.
- The story's roads and the camp's trips share one roll (`startRoadEncounter` in `story_player_screen.dart`), and the playthrough simulator plays the same rules.

## Which roads roll

| Rule | What it does |
|---|---|
| **A change of place** (D1) | A walk from one place to another, or between two districts of one city, rolls. A move between two scenes of the same place (location and district) holds nothing: no detour, no hunter, no familiar face. |
| **Any scene, not only the spine** | The chapter is the one the party has reached, wherever the road starts: a spine beat, a town's scene or the camp. Before, only roads leaving one of the ~44 spine beats rolled. |
| **Chapter 4** (D2) | The camp's trips roll as the story's roads do, and so do the Drowned Cloister's districts. Its three places all land at the Drowned Stair: from the cove camp the trip is a voyage, but between the three it is a walk, and rolls. Chapter 4 now gets 0.90 detours a run in the simulator, against none before (the walk sails each place from the camp, so a player who walks between them meets more). |
| **No detours in the last chapter** (D8) | Detours run from chapter 2 to `lastDetourChapter` (7). Hunters and familiar faces still come in chapter 8. |
| **Set pieces** | A road into or out of a `noDetour` scene holds nothing and owes nothing. Before, set pieces were 83% of owed detours. |
| **A crisis** (both scenes tense) | Holds nothing, but what it rolls is owed. It is paid on the next road at rest of the same chapter, after the cooldown, and lapses when the chapter ends. Before, 87% were paid a chapter or more later. |
| **The camp's trips** | They follow the same checks as the story's roads (they used to skip the mood and `noDetour` checks). The place a detour is set at is where the road leads, not the camp. |

## When a detour comes

| Rule | Value |
|---|---|
| Pity timer | 8% a road, plus 6% for each quiet road since the last detour, up to 45% (v1.361; it was 20%, 10% and 60%) |
| Cooldown | 1 road at rest after a detour, a hunter or a familiar face, with none of them. Hunters roll first and keep their own cooldown. |
| A city's streets | odds × 0.5 |
| A long road (two watches or more) | odds × 1.3 |
| A deadline a day or less away | odds × 0.3 (`daysToSpare`; no story road carries a deadline yet) |
| Order on a road | road event, the landmark when due, hunter, cooldown, owed detour, familiar face, pity timer (v1.361: a due landmark comes before a hunter) |
| A voyage's landing | rolls as a road arriving there would (v1.361): the sailed trips of chapters 4 to 7, the march to Candlehold among them |
| The landmark | Each chapter's scene tagged `landmark` comes once, on the chapter's first road at rest that nothing else holds, cooldown or not. Chapters 4 and 5 walk only two to four such roads, so it can't wait. |
| The roll | The road's own dice (`detourRandomFor`: from, to, the step and the run's seed). A road chosen the same way holds the same detour, so the journey panel can show it before the party sets out. Hunters and familiar faces stay surprises. |

## What the detour is

- **A written scene** that fits the road:
  - its chapter and its `requires` flag;
  - its place (the road's destination and every place above it) or the road's biome;
  - a city scene only in the streets, a road scene only on roads;
  - never one met before (the met scenes are saved with the session).
- **How it is drawn:** by length, with about 30% one beat, 45% two, and 25% three or four. A length with no scene that fits gives its share to the others.
- **With no scene that fits:** today's chain, worded from the pools of where the road leads.
- **A scene plays as an excursion**, beat after beat:
  - each beat's rule is the expedition's: the chapter's DC, a rest's heal, foes by the pack rule;
  - a discovery finds a cache of the chapter's gold;
  - each choice's note opens the next beat.
- **"Leave it and go on"** on the first beat backs away at no cost.
- **Cost:** going in costs one watch when the scene has a check or a fight. A stop costs nothing, and no scene eats a ration.

## The other fixes from the audit

| Finding | Fix |
|---|---|
| Line memory of 1, so a two-line pool alternates | The memory is of the lines themselves. A line comes back only after the rest of its pool has, whichever pool answers. |
| The pools' enemy lines never showed | A place's own enemy line now opens the fight, then the foe's own line. The themes pool answers when it is filled (place_pools_test covers it). |
| The quest-chain comment said 4–7 nodes | Fixed: 3–4, or 1–2 without a quest (a hunt adds 2). |
| Chapter 2's fourth spine beat (2030/2040/2070), skipped by 26 of 50 runs | Dropped from the spine: it is a branch. |

## Measured

**v1.361 (the user: "a bit more, 7 to 10")**
- **Setup:** 200 seeded runs (seed 11), 50 per strategy, the professions in turn.
- **Chapter 7:** `7500` is taken without its `noDetour`, as Narrative is lifting it.
- **What changed:**
  - landings roll;
  - a due landmark comes before a hunter;
  - the pity timer starts lower.

| Chapter | Roads at rest a run | Detours a run | Runs with one | Landmark met | Familiar faces a run |
|---|---|---|---|---|---|
| 2 | 10.1 | 1.44 | 100% | 100% | 1.26 |
| 3 | 12.7 | 1.61 | 100% | 100% | 2.35 |
| 4 | 8.8 | 1.52 | 100% | 100% | 1.34 |
| 5 | 8.0 | 1.52 | 100% | 100% | 1.13 |
| 6 | 12.1 | 2.13 | 100% | 100% | 0.70 |
| 7 | 1.0 | 1.00 | 100% | 100% | 0 |
| 8 | 0 | 0 | 0% | – | 0 |

- **Per run:** 9.2 detours on average (median 9, 6 to 15), against 6.8 in v1.356 and 3.4 before Wave 11.
- **Spread:** 1.4 to 2.1 a chapter from 2 to 6, where v1.356 had chapters 2 and 3 at 1.8 to 2.0 and chapters 4 and 5 at 0.9.
- **Every landmark is met in every run**, chapter 7's included, on the landing at Candlehold.
- **No two in a row**, and no detour between two scenes of one place (D1): the test checks every road of every run.

To print the table again: `DETOUR_RUNS=200 flutter test test/detour_engine_test.dart`. It also prints the scenes met and the transcript of run 0.

**v1.356**, for comparison:

| Chapter | Detours a run | Runs with one | Landmark met |
|---|---|---|---|
| 2 | 1.79 | 100% | 100% |
| 3 | 1.95 | 100% | 100% |
| 4 | 0.90 | 84% | 84% |
| 5 | 0.90 | 90% | 90% |
| 6 | 1.25 | 100% | 100% |
| 7 | 0 | 0% | 0% |

### Chapter 7

- **The road:** the march to Candlehold (`7400` to `7500`) is a voyage. Its landing now rolls.
- **The user's decision:** `7500` loses its `noDetour` (Narrative's DAG change), so the landing can hold the chapter's landmark, *The Banner on the Hill*.
- **Until that change merges,** the landing is still a set piece, and chapter 7 holds no detour.

## The simulator

- **Rolls:** the walk rolls every road by the same rules: its story roads, and the camp tour's trips. A place reached by sea has no road and no road event, but its landing rolls (v1.361).
- **Records:** each road is recorded in `SimRunSummary.roads`, with its chapter, ends, whether it is a street, whether it is at rest, what it held, the scene, landmark, and owed.
- **Not played:** a detour is still passed by, as before, so the balance numbers don't move. Its scene and its foe are in the transcript.
- **The transcript:** `simulatePlaythroughs(..., transcripts: true)` gives each run's transcript (`SimRunSummary.transcript`). It holds, in order:
  - each scene with the choice taken, and the fight and how it went;
  - the camp's trips, detours, familiar faces, hunters, temptations, owed detours and road events;
  - at each chapter, the character (level, health, gold), the clans' standing, and the flags gained.

  The walk keeps no companions, so the party is the character.
