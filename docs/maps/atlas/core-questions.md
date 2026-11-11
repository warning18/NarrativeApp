# Two questions for Core (proposals C and F)

Nothing here is built. Core only needs to confirm or correct.

## For C: one world on the sphere and on the flat chart

**What Maps would change:** the flat chart draws the story world (`chartOf(MapShape.story)`), as the sphere does,
instead of the world picked in the look (`mapShapeProvider`, the ring by default).

**Who reads a place's position on the ring world today** (every `chartOf(ref.…(mapShapeProvider))`):

| Call site | What it does | Rule or drawing |
|---|---|---|
| `lib/providers/climate_provider.dart:46-49` (`skyHereProvider`) | the weather where the party stands: `ChartClimate.of(chart)` at `chart.of(standing)` | **a rule's input** |
| ↳ `lib/screens/fight/fight_setup.dart:50` | the weather's effects in a fight | rule |
| ↳ `lib/data/road_hazards.dart:111`, `lib/screens/story_player/story_choice_flow.dart:844` | the weather's road odds | rule |
| ↳ `lib/screens/land_crossing_screen.dart:800`, `story_choice_widgets.dart:502`, `weather_chip.dart:90`, `journey_screen.dart:1373, 5851` | the weather shown | drawing |
| `lib/screens/journey_screen.dart:1367-1370, 1496-1504` | which way a way out points (bearing), and its target on the chart | drawing |
| `lib/screens/journey_screen.dart:2052` | the neighbour places' marks round the party | drawing |
| `lib/data/road_chart.dart:66-67` (geography handed in by the Journey) | the bent line of a road between two places | drawing |
| `lib/screens/epilogue_map_screen.dart:97` | the epilogue map | drawing |
| `lib/screens/world_map_screen.dart:103, 307-308` | Edit Mode's world map page and its shape picker | drawing |
| `lib/widgets/journey_world_map.dart:32-33, 441` | the flat chart itself | drawing (Maps) |

Already on the story world: `lib/providers/travel_history_provider.dart:33`, `lib/providers/region_strips_provider.dart:15`.

**The questions.**
1. The weather is the only rule that reads the ring world. If the flat chart shows the story world, the weather
   should come from the story world too, or the sky drawn will not match the land under it. That changes which
   weather falls on which place (fights and road odds). `tool/fmg_chart/story_world.py` says the story world was
   laid out "so each land sits where its weather should be". Does Core agree to read the story world in
   `skyHereProvider`, and does the simulator or the balance report depend on today's weather per place?
2. Is there any other rule reading a ring-world position that this grep missed (something that goes through
   `worldMapLandmarks` positions in `world_map.dart` and not through `chartOf`)?
3. May the three older worlds (A, B, C) stay for Edit Mode only?

## For F: the sea on the side where the chart puts it

**What is there today.** `tool/city_plans/city_plan_generator.dart`: a plan is a 1000 x 1000 square; `shoreY` puts
the sea **below** the shore, `riverX` brings the river in **from the north**, the gates are named
`northwest, north, northeast, east, west`, the arena is north-east of the market. So every coastal plan has its
sea at the bottom.

**On the story chart** (nearest coast from the place's spot, chart 256 units wide):

| City | Plan | Chart |
|---|---|---|
| Saltmouth | sea south | coast to the north, 8 units away |
| Candlehold | sea south | coast to the west, 11 units |
| Greyhithe | sea south | coast to the north-west, 10 units |
| Drowned Cloister, White Anchorage, Wrack's End, Cove Camp, Kindly Hill | sea south | not checked: the chart has no place under these ids |

**What a "sea side" could look like.** One field on the spec in `gen_city_plans.dart`:
`seaSide: south | west | north | east` (south by default, so nothing changes until it is set). The generator
builds the plan as today, then turns every point a quarter, a half or three quarters of a turn round (500, 500)
before writing it: sea, rivers, islands, canals, wall, avenues, streets, bridges, squares, districts, buildings,
anchors, services. The square stays a square, so the record and the painter need no change.

**The questions.**
1. Is a quarter-turn after generation acceptable, or does Core prefer the generator to lay the shore on any side?
2. The gate ids are compass names. After a turn, do the ids stay (a "north" gate that now faces east) or turn
   with the plan? Do any scenes or `way_places` refer to a gate or a side by its compass name?
3. Narrative: does any scene's text say where the sea, the river or a gate lies in a town (north, south, landward)?
   Those towns would need a read.
4. Saltmouth's spot is 8 units inland on the chart, for a port. Moving the spot to the coast is Maps' data
   (`chart_story.dart`); does a rule read the distance to the coast?
