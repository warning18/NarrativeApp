# L3 preparation: the 1.285.0 baseline

Prepared for the L3 that was postponed (it ran at 1.274.0 last time; the next
is due now and runs first after the weekly reset). Head measured: `5a416c6`
(#215), v1.285.0+321, 2026-10-13, **Android only**. The sims below are the
comparison point; the L3 itself adds format, analyze and the full suite, and
the read-through of the screens listed here.

## Simulator baseline, 1.285.0

Same commands as `docs/simulation/report-100-runs.md` (seeds 7, 11, 23; four
goals; 20 runs per profession in the 100-run batch). 100/100 and 800/800 runs
reach an ending.

| measure | 1.264.0 | 1.270.0 | 1.274.0 | **1.285.0** |
|---|---|---|---|---|
| attempt win, 100 runs | 36% | 38.1% | 41.3% | **45.9%** |
| attempt win, 800-run check | 36.7% | 40.0% | 39.8% | **45.0%** |
| level at the end (100 runs) | 10.9 | 11.4 | 11.9 | 13.1 |
| gold at the end (100 runs) | 3698 | 3732 | 3774 | 4286 |
| warrior / rogue / ranger, 800 runs | 28/33/33% | 31/36/36% | 30/36/35% | **30 / 42 / 40%** |
| cleric / mage, 800 runs | 47/45% | 52/49% | 54/49% | **62 / 56%** |
| chapters 1 to 4, 800 runs | | 84/74/40/36% | 84/73/41/35% | 90 / 74 / 44 / 45% |
| chapters 5 to 8, 800 runs | | 31/31/17/21% | 31/30/17/20% | 35 / 36 / 23 / 27% |

The rise since 1.274.0 (39.8% to 45.0%) is the boss curve (#210) and the
richer arrival of "Play to chapter" (not the simulator). The boss curve holds
on these seeds: the per-boss win average is **47.9%** (Aurel Vane 78, Void
Stalker 63, Hollow Court Inquisitor 57, Bone Warden 58, Void Archon 50, White
Admiral 44, the three claimants 33 to 45, Tear Herald 33, Void Sovereign 31).
Two things to look at in the L3: the **warrior stays at 30%** while the cleric
is at 62% (a gap of 32 points, 20 at 1.264.0), and the crossing from the wreck
rolls on its own random stream, so the walk's other results stay comparable but
the crossing's own numbers are separate.

Coverage (`sim_coverage_test`, 300 runs a batch, seed 7): 426 scenes, exploring
runs visit 413 (97%), random 391; 0 statically unreachable; the same 13
scenes unvisited as at 1.264.0, 1.270.0 and 1.274.0. Quests seen 39 of 43.

## Screens changed since 1.274.0 (read at the L3)

| PR | version | what | files |
|---|---|---|---|
| #203 | 1.277.0 | dice loadout card keeps one height; camp house cards (status above the name); cove camp page scrolls; Shroud card as six banners; help ⓘ pattern; voyage rain over the water only; Journey badge and weather line; camp town tap | `dice_loadout_screen.dart`, `camp_town_section.dart`, `character_screen.dart`, `story_player_screen.dart`, `voyage_screen.dart`, `weather_chip.dart`, `journey_screen.dart`, `help_hint.dart` |
| #207 | 1.278.0 | the jungle biome on the story chart | `chart_relief.dart`, `chart_story.dart`, `climate.dart`, `biomes.json` |
| #208 | 1.279.0 | twelve story achievements | `achievements.json`, `achievements_screen.dart` (list grows) |
| #210 | 1.280.0 | the boss curve | `enemies.json` (11 bosses) |
| #211 | 1.281.0 | materials: ten items, camp building cards with materials, shops and drops | `camp_town_section.dart`, shops, `items.json`, `houses.json` |
| #212 | 1.282.0 | the full map (Journey chart page, place sheet, legend, story, journeys), help ⓘ on ten more pages, weather chip as an icon under 340 px, stat point singular | `full_map_screen.dart`, `calques_sheet.dart`, `map_legend_sheet.dart`, `journey_world_map.dart`, `journey_screen.dart`, ten page headers |
| #213 | 1.283.0 | the harbour: built from the story's grant, the camp's harbour card and tour, the Eel waits on it | `camp_screen.dart`, `harbour.dart`, `ship_widgets.dart` |
| #214 | 1.284.0 | the harbour's story text (camp scene, tour step) | `Cleaned_Narrative_DAG.json`, `app_strings.dart` |
| #215 | 1.285.0 | the land crossing screen from the wreck of the Lark, its tutorial | `land_crossing_screen.dart`, `land_crossing.dart`, `story_player_screen.dart` |

Read, at 360 and 320 px with the bundled fonts, English and French: the full
map (sheet, legend, journeys) and its toolbar; the camp (harbour card, Town
with materials on the cards, the tour's first step); the dice loadout header
card; the crossing screen (event, result, arrived, carried back, turned back);
the Journey header; one of the ten pages with the new ⓘ. Also by eye: the
voyage's storm over the water only; the jungle on the story chart.

## Save versions to check

- **3 to 4 (materials):** a save older than version 4 gets, once, one rare
  material for each tier its story has passed (clock chapter 5 or later: tier 2;
  7 or later: tier 3). Guarded in `qa_harbour_crossing_test`.
- **4 to 5 (the harbour):** a save older than version 5 that has passed the
  camp's founding gets the harbour built on load, once. Guarded.
- Real old saves: `test/fixtures/session_v1_198.json` and `session_v1_204.json`
  both load, round-trip and get nothing twice. A save of version 5 past the
  founding without a harbour is "awaiting" it, not built for.

## Guards added since 1.274.0 (on `claude/qa`)

`qa_full_map_test` (25 cases: the full map on real walks at 360 and 320 px in
English and French; the place sheet's states; Travel here disabled during a
fight and during an expedition; Go travels and closes the map, repeated for the
no-encounter walk), `qa_harbour_crossing_test` (15 cases: the founding grant is
exactly the harbour's cost; a voyage is refused while the harbour is awaited
and affordable, with the notice; the boat sails anyway when the materials are
gone, when it is built, and before the founding; 0 health carries the party
back at half and the choice is not taken; turning back applies nothing; the
route data, wreck choices and the 3 to 4 and 4 to 5 save versions),
`qa_autoplay_build_test` (16, merged), `qa_travel_history_test` (merged). The
travel map guard went with the page (#212).

## Observations (not findings)

- A crossing that runs the party out of health carries it back at half health
  even when it set out below half (5 of 100 wakes at 50): failing the road is a
  free rest for a spent party. Pinned in `qa_harbour_crossing_test` so a change
  is noticed; Core's call.
- The warrior's gap, above.
