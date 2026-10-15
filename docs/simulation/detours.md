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
| Pity timer | 20% a road, plus 10% for each quiet road since the last detour, up to 60% |
| Cooldown | 1 road at rest after a detour, a hunter or a familiar face, with none of them. Hunters roll first and keep their own cooldown. |
| A city's streets | odds × 0.5 |
| A long road (two watches or more) | odds × 1.3 |
| A deadline a day or less away | odds × 0.3 (`daysToSpare`; no story road carries a deadline yet) |
| Order on a road | road event, hunter, the landmark when due, cooldown, owed detour, familiar face, pity timer |
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

200 seeded runs (seed 11), 50 per strategy, the professions in turn:

```
DETOUR_RUNS=200 flutter test test/detour_engine_test.dart
```

The run prints this table, the scenes met and the transcript of run 0.

| Chapter | Roads (any) | Detours a run | Runs with one | Written / drawn | Landmark met | Familiar faces | Hunters & temptations | Road events |
|---|---|---|---|---|---|---|---|---|
| 2 | 12.1 | 1.79 | 100% | 341 / 17 | 100% | 10.3% | 6.5% | 0.8% |
| 3 | 13.7 | 1.95 | 100% | 389 / 1 | 100% | 16.9% | 7.7% | 4.0% |
| 4 | 4.0 | 0.90 | 84% | 180 / 0 | 84% | 6.0% | 4.3% | 0.0% |
| 5 | 4.0 | 0.90 | 90% | 179 / 0 | 90% | 0.0% | 3.4% | 13.8% |
| 6 | 6.1 | 1.25 | 100% | 248 / 1 | 100% | 11.9% | 7.3% | 10.4% |
| 7 | 3.0 | 0 | 0% | – | 0% | – | – | – |
| 8 | 3.0 | 0 | 0% | – | – | – | – | – |

- **Per run:** 6.78 detours on average (median 7, max 12), against 3.43 before. 36 scenes (#281 and #286): only 20 detours of 1,356 fell back to today's chain. Most of the rise is chapters 2 and 3, where the hub's errands cross a city's districts. Chapter 4 went from 0 to 0.90.
- **Familiar faces:** 8.3% of all roads, against 32.6% of free roads before. They now share the cooldown with detours.
- **No two in a row:** the test checks every road of every run.
- **Chapter 4:** runs with no detour are the ones that never walked the Drowned Cloister's districts.

### Chapter 7 has no road at rest

The walk to Candlehold (`7400` to `7500`) goes into a set piece. Every road inside the city runs between two tense scenes, and the camp's errands at `7400` are moves inside one place (D1). So chapter 7 holds no detour, and its landmark (*The Banner on the Hill*, at `candlehold_gates`) can't come.

This needs a story-data decision, as chapter 4 did (D2). Either:
- `7500` loses its `noDetour`, so the march to the gates can hold the landmark; or
- chapter 7 gets a place or a calm district scene off the camp.

The engine needs no change for either.

## The simulator

- **Rolls:** the walk rolls every road by the same rules: its story roads, and the camp tour's trips on foot (a place reached by sea is a voyage, with no road).
- **Records:** each road is recorded in `SimRunSummary.roads`, with its chapter, ends, whether it is a street, whether it is at rest, what it held, the scene, landmark, and owed.
- **Not played:** a detour is still passed by, as before, so the balance numbers don't move. Its scene and its foe are in the transcript.
- **The transcript:** `simulatePlaythroughs(..., transcripts: true)` gives each run's transcript (`SimRunSummary.transcript`). It holds, in order:
  - each scene with the choice taken, and the fight and how it went;
  - the camp's trips, detours, familiar faces, hunters, temptations, owed detours and road events;
  - at each chapter, the character (level, health, gold), the clans' standing, and the flags gained.

  The walk keeps no companions, so the party is the character.
