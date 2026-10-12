# A story-true world for the chart

A preview, not a change to the game (nothing in `lib/` reads it). The world is drawn from what the story says and
where the globe puts it, instead of from a generator's atlas. Everything is in `tool/fmg_chart/`:

- `story_world.py` holds the design (lands, places, zones, ranges, rivers) and writes `chart_story.dart`
  (`chartWorldStory`, a `ChartGeography`, and `storyFeatureAt`, where the features that have a story role stand).
  `python3 tool/fmg_chart/story_world.py > tool/fmg_chart/chart_story.dart && dart format tool/fmg_chart/chart_story.dart`
  (needs numpy, scipy, scikit-image, shapely and PIL).
- `preview_test.dart` paints it with the game's own `ChartMapPainter` next to chart B, flat and on the globe, and prints what the
  game's `ChartClimate` makes of each place: `flutter test tool/fmg_chart/preview_test.dart`.
- Images (chart B on the left, the story world on the right): `story-night.jpg`, `story-parchment.jpg` (flat). On the globe:
  `story-globe-whole.jpg` (and `-whole-parchment`), `story-globe-turn.gif` (a turn of the sphere), and views
  turned toward each part: `-north`, `-south`, `-west`, `-east`, `-crossing`.

I did not use the Fantasy Map Generator this time. Its lands can't be placed to a latitude without fighting it, and the
brief wants simple lands with only the detail the story needs, so the lands are drawn by hand as rough outlines and then
grown with noise (distance to the outline plus three octaves of value noise, contoured). That keeps the coasts complex
(bays, headlands, a cove) while I choose exactly where each land goes. The painter then breaks them up further, as it does for every chart.

## The world

| Land | Where | Why there |
|---|---|---|
| the Ashen Continent | the north, lat 26° to 67°N, a long land running east to west | cold; the Cove Camp on its south coast faces the Old Continent across the crossing |
| the Old Continent | the south, lat 2°S to 57°S | Alster's vale about 42°S, the Waste in the dry belt 26°S to 32°S, Saltmouth on the northern headland at 10°S |
| the Lantern Isles | the west, between them, lat 3°S to 17°N | reached by sea from the Cove Camp; kept off the straight crossing so no road crosses it |

Three lands for the story, and **four empty archipelagos** for ship content (voyages, wrecks, hunts, later):

| Archipelago (`storyArchipelagoLands`) | Where | Islands |
|---|---|---|
| `south_west` | the open sea south-west of the Lantern Isles, west of Alster (lat 20°S to 55°S, lon 90°W to 65°W) | 5 |
| `mid_west` | the Narrow Sea's western end, between the Lantern Isles and the Old Continent | 4 |
| `east_narrows` | the Narrow Sea east of the crossing | 4 |
| `south_east` | the Open Water off the Old Continent's east coast | 5 |

They hold no place, zone or feature (plain land), each sits clear of the crossing, every sea road and the chart's edges
(at least 6 units from any land, 9 from an edge), and none is named: names are Narrative's. In `chartWorldStory.lands`
the three story lands come first (indices 0 to 2) and the islands follow; `storyArchipelagoLands` gives each
archipelago's indices, so ship content can find them. Apart from these, no other islands are drawn into the data
(the painter adds a few skerries off the coasts of any chart; see "For Core").

## How each constraint is met

1. **The globe.** The chart is 256 x 176 units for 225 degrees by 140. Lands stay clear of every edge: the top is 8 units
   (lat 66.6°N) from the 70°N edge, the bottom 20, the left 33 and the right 23 (chart B: 4, 2, 6, 6). The generator code
   forces open sea within 9 units of any edge. On the sphere (`story-globe.jpg`, whole sphere at zoom 1) the three lands
   show, with the Cove Camp at longitude 6°W, so the base is at the centre of the first view.
2. **Latitude sets the climate.** The game's own `ChartClimate` on this chart (place, latitude, biome, temperature in the
   chart's mild season, humidity 0 to 1, and for chart B in brackets):

   | Place | Lat | Biome | Temperature | Humidity |
   |---|---|---|---|---|
   | The Black Reliquary | 56°N | frost | -7 °C (B: -4) | 0.20 |
   | Highhearth | 57°N | frost | -7 °C (B: -9) | 0.59 |
   | Rimewell | 47°N | frost | -5 °C (B: -3) | 0.13 |
   | Spire of Judgment | 49°N | ashlands | 13 °C (B: 12) | 0.46 |
   | Ashen Quarter | 44°N | ashlands | 15 °C (B: 20) | 0.37 |
   | Akagiri (Red Hills) | 41°N | volcanic | 14 °C (B: 23) | 0.44 |
   | The Cove Camp | 35°N | sea cliffs | 13 °C (B: 19) | 0.92 |
   | Hollow Shore | 48°N | tear | 4 °C | 0.30 |
   | Kindly Hill / Cloister (the fen) | 40°N / 34°N | fen | 15 / 18 °C | 0.81 / 1.00 |
   | Candlehold | 9°N | sea cliffs | 14 °C | 0.64 |
   | Alster (the family's house) | 42°S | temperate | 14 °C (B: 21) | 0.95 |
   | The Wreck of the Lark | 32°S | desert | 27 °C (B: 19) | 0.04 (B: 0.29) |
   | The Sleeper's Face | 26°S | desert | 29 °C (B: 15) | 0.25 |
   | The White Wells | 32°S | desert | 27 °C (B: 18) | 0.26 |
   | Saltmouth (Smugglers' Wharf) | 10°S | arid coast | 28 °C (B: 20) | 0.50 |

   The Waste is now hot and bone dry (B: mild), Alster a cool wet vale, the Frost Reach below freezing, the fen wet.
   One miss: the Red Hills are meant to be "the only warm place on the Ashen Coast", and the model puts Akagiri at 14 °C,
   level with the flats (13 to 15 °C). Its volcanic biome adds +6 °C but its height (elevation 0.43) takes about 9 °C
   off. Making it warm is a change to `climate.dart` (Core): a stronger volcanic term (+12 would do) or no height penalty for it.
3. **The Ashen Continent is cold, in the story's order.** The Frost Reach is the northern strip (56°N to 66°N), with the
   Rime Teeth beside it and Highhearth below the Frost Quarry. The Ash Flats lie between the Cove Camp and the Spire; the
   Red Hills are behind them to the east. The Grey Fen is "three days along the coast" west of the Cove Camp, in the
   story's order: Wrack's End and its cliffs come first (27 units from the camp), then the fen (Kindly Hill 47, the
   Drowned Cloister 61, the Hollow Court 74 units). The Hollow Cape is a spit running east from the north-eastern end, "where
   the charts showed only sea", with open water beyond it for the tear and the White Fleet's Grave.
4. **The Old Continent.** Alster is a river city on the south-western coast with its harbour on the west coast and the
   stone giant at the harbour mouth; its river comes down from the Alster Downs (the hills, north of the city) through
   the city to the harbour. East of the hills the dunes run "from Alster's hills to the sea": the Waste fills the
   interior, with the Lark's wreck nearest Alster, then the Sleeper's Face, then the White Wells, and the road
   goes on to Saltmouth's landward gate. Saltmouth crowns a brown headland on the northern coast, where the desert meets the sea,
   with a stone giant in the harbour mouth and the Salt Pans on the flats below it.
5. **The crossing.** Saltmouth (the wharf) to the Cove Camp is 67 units, about 5,900 km at the chart's scale
   (a unit is 0.8° of latitude, about 88 km), which is three weeks at 11 km/h: three weeks of open sea. The Crossing
   (`storm`) sits at sea in the middle of it, on the route, with nothing between.
6. **The Lantern Isles** lie across the sea from the Cove Camp (65 units west and 33 south), off both the crossing and any
   other road. They are one island (see "Choices to confirm"), with Candlehold on its high cliffs.
7. **Only what the story needs.** 34 places (every landmark), 3 lands (plus the 4 empty archipelagos, 18 islands, asked for
   separately), 2 rivers (Alster's, the freshwater burn at the
   Cove), 4 mountain ranges (the Rime Teeth, the Firebacks of the Red Hills, the Alster Downs, the Lantern Cliffs), 11 zones
   (the story's own biome zones) and 23 features (below). Chart B has 8 lands, 2 rivers, 6 ranges and 55 features.

## Features kept and dropped

Kept (23): the clan seats (the 12 that the clan system points at: the Lantern Throne, the Spire of Judgment, Anvil Gate,
the Heron's Wake, the Brig, the Vigil's Wall, the Exorcists' Gate, Highhearth, Akagiri, the Kindly Hill, Lowtide, the Open
Hand's hall), the two stone giants (Alster's harbour and Saltmouth's harbour mouth, both in the story's blurbs), the
Stone Bridge, and the places the story's own blurbs name or describe: Tallow Street, the Salt Pans, the Salt Marsh, the Hot Springs,
the False Lamps, the Frost Quarry, the Exorcists' Road, the Slag Kilns. Each keeps chart B's names, notes and clan; only
its position is new (`storyFeatureAt`).

Dropped (32): the villages and works the story never names (Hedgefold, Millbrook, the Veiled Camp, the Reed Gate...),
four of B's five bridges, the other quest sites, and B's 44 trade roads. All are in chart B and can come back one by one if
Narrative says they have a role.

## Choices to confirm

- **One Lantern island.** "Isles" is plural, so a second small island could be added; the brief said no extra islands, so there is one.
- **The Hollow Cape** is a spit at the north-east end (lon 55° to 93°E), close to the right limb of the globe at the default
  view; it comes round with a turn of the sphere.
- **Place spacing** is at least 11 units (chart B: 10.6), but Ashen places still crowd in the north: when every place is read the
  labels overlap, as on B. The painter shows names of read places only.
- The story names the Frost Reach but not where along the north the Black Reliquary stands; I put it at the middle.

## For Core, if this becomes a playable chart (`lib/data/`)

- A fourth value `MapShape.story` (the name is Core's), `chartWorldStory` in `chart_worlds.dart` (the generated Dart is
  ready: `places`, `lands`, `rivers`, `labels`, `zones`, `ranges`), the 23 `features` (names and notes from B, positions from
  `storyFeatureAt`), and `chartOf` for the new shape. No trade roads.
- `map_charts_test.dart` wants every landmark to have a spot on each chart: all 34 do.
- One new optional field would give a cleaner map: `ChartGeography.islets` (default true) so the painter's own skerries,
  which the painter adds off every coast, can be turned off here.
- One line in `climate.dart` for the Red Hills (a stronger volcanic warmth), above.
- Narrative: the zone names are B's (and French names for The Ashen Coast and The Throne's Demesne are not needed
  here: this world uses B's 11 zone names, French included). The ranges keep B's names.
