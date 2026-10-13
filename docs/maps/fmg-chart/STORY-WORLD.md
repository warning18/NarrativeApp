# A story-true world for the chart

Since v1.272.0 the game reads it: `lib/data/chart_story.dart` is the travel-history map's chart (`MapShape.story`, kept out of the map-look setting). The world is drawn from what the story says and
where the globe puts it, with Earth's climate bands. Everything is in `tool/fmg_chart/`:

- `story_world.py` holds the design (lands, places, zones, ranges, rivers, archipelagos) and writes `chart_story.dart`
  (`chartWorldStory`, a `ChartGeography`, plus `storyFeatureAt`, `storyEmptyLands` and `storyArchipelagoLands`).
  `python3 tool/fmg_chart/story_world.py > lib/data/chart_story.dart && dart format lib/data/chart_story.dart`
  (needs numpy, scipy, scikit-image, shapely and PIL).
- `preview_test.dart` paints it with the game's own `ChartMapPainter` next to chart B, flat and on the globe, and prints what the
  game's `ChartClimate` makes of each place and of each band: `flutter test tool/fmg_chart/preview_test.dart`.
- Images (chart B on the left, the story world on the right): `story-night.jpg`, `story-parchment.jpg` (flat). On the globe:
  `story-globe-whole.jpg` (and `-whole-parchment`), `story-globe-turn.gif` (and `-turn-parchment.gif`: a turn of the
  sphere), and views turned toward each part: `-north`, `-south`, `-west`, `-east`, `-crossing`, `-polar-south`.

The lands are drawn by hand as rough outlines and grown with noise (distance to the outline plus three octaves of value noise,
contoured), so the coasts are complex (bays, headlands, a cove) and I choose exactly where each land goes. The painter then
breaks them up further, as it does for every chart.

## The world

The chart is a band of 225° of longitude by 140° of latitude (70°N to 70°S), 256 x 176 units; latitude sets the climate
(`climate.dart`: warmth falls from 24 °C at the equator to −2 °C at the edge, and each biome adds or takes some). The lands
are laid out the way Earth's are: cold at both poles, the hot belt about the equator, temperate lands between.

| Band | What lies there |
|---|---|
| north pole (above 58°N) | the top of the Ashen Continent: the Frost Reach, frost, −8 °C |
| cold and temperate north (30° to 58°N) | the Ashen Continent's ash flats, the red hills, the fen and the cove (13 to 18 °C); the north-west archipelago |
| tropics (15°N to 15°S) | the Lantern Isles (9°N, 19 °C); the east land's jungle on the equator (22 °C, a green land) and its dry north at 16°N (desert, 29 °C); the Old Continent's north coast: Saltmouth at 2°S (arid coast, 28 °C) |
| subtropical dry belt (15° to 30°S) | the Waste (desert, 29 to 31 °C, humidity 0.03 to 0.26); the west land's dry coast (32 °C) |
| temperate south (30° to 45°S) | Alster's vale (16 °C, humidity 0.91, a cool river vale); the west land's south; the Old Continent's south (temperate) |
| south pole (below 55°S) | the south polar land (frost, −8 °C) |

Lands: the Ashen Continent, the Old Continent and the Lantern Isles (the story's), and three **empty lands** for what comes later
(`storyEmptyLands`): the **east land** (lat 23°N to 29°S: dry north, a jungle on the equator, temperate south), the **west
land** (lat 9°S to 49°S: a hot dry coast, then temperate), and the **south polar land** (frost). The
empty lands have zones with no name (names are Narrative's) and no place or feature.

Four **empty archipelagos** for ship content (`storyArchipelagoLands`: id to the indices of its islands in `lands`; none named):

| Archipelago | Where | Islands |
|---|---|---|
| `north_west` | cold seas west of the Ashen Continent | 3 |
| `mid_sea` | the Narrow Sea, between the Lantern Isles and the Old Continent | 3 |
| `east_narrows` | the Narrow Sea east of the crossing, between the Old Continent and the east land | 5 |
| `south_east` | the warm sea south of the east land | 3 |

Each sits clear of the crossing, the sea roads and the edges (at least 6 units from any land, 9 from an edge).

**How full the globe is.** Land is 41 % of the chart (chart B 54 %); by thirds of longitude 34 % west, 59 % middle, 31 % east;
no band of latitude is bare of land except the narrow strip along each pole's sea edge. Before the empty lands and the second
set of archipelagos the three story lands covered 30 %.

The jungle needs a biome: the painter and `climate.dart` know ten biomes and none is a jungle, so the east land's jungle is
drawn as `temperate` (green, woods) in a hot place. A real one would add `biomes.json` (`jungle`), colours and dense canopy
with palms in `chart_relief.dart`, and a climate row (warmth +3 °C, moisture 0.9), all Core's.

## How each story constraint is met

1. **The globe.** Lands stay off every edge (top 8 units, bottom 9, left 13, right 12; chart B 4, 2, 6, 6). The generator code
   forces open sea within 9 units of any edge. On the sphere the lands show all round, and the Cove Camp (longitude 6°W)
   is at the centre of the first view; the Hollow Cape and the east land come round with a turn.
2. **Latitude sets the climate**, from the game's own `ChartClimate` (chart B in brackets):

   | Place | Lat | Biome | Temperature | Humidity |
   |---|---|---|---|---|
   | The Black Reliquary | 56°N | frost | −7 °C (B: −4) | 0.20 |
   | Highhearth | 57°N | frost | −8 °C (B: −9) | 0.61 |
   | Rimewell | 47°N | frost | −5 °C (B: −3) | 0.13 |
   | Spire of Judgment | 49°N | ashlands | 13 °C (B: 12) | 0.46 |
   | Ashen Quarter | 44°N | ashlands | 15 °C (B: 20) | 0.42 |
   | Akagiri (Red Hills) | 41°N | volcanic | 14 °C (B: 23) | 0.43 |
   | The Cove Camp | 35°N | sea cliffs | 14 °C (B: 19) | 0.92 |
   | Hollow Shore | 48°N | tear | 4 °C | 0.30 |
   | Kindly Hill / Cloister (the fen) | 40°N / 34°N | fen | 15 / 18 °C | 0.83 / 0.87 |
   | Candlehold | 9°N | sea cliffs | 19 °C | 0.45 |
   | Alster (the family's house) | 34°S | temperate | 16 °C (B: 21) | 0.91 |
   | The Wreck of the Lark | 24°S | desert | 29 °C (B: 19) | 0.03 (B: 0.29) |
   | The Sleeper's Face | 18°S | desert | 31 °C (B: 15) | 0.25 |
   | The White Wells | 24°S | desert | 30 °C (B: 18) | 0.26 |
   | Saltmouth (Smugglers' Wharf) | 2°S | arid coast | 28 °C (B: 20) | 0.49 |

   The Waste is now hot and bone dry (B: mild), Alster a cool wet vale, the Frost Reach below freezing, the fen wet.
   One miss: the Red Hills are meant to be "the only warm place on the Ashen Coast", and the model puts Akagiri at 14 °C,
   level with the flats (13 to 16 °C). Its volcanic biome adds +6 °C but its height (elevation 0.43) takes about 9 °C off.
   Making it warm is a change to `climate.dart` (Core): a stronger volcanic term (+12 would do) or no height penalty for it.
3. **The Ashen Continent is cold, in the story's order.** The Frost Reach is the northern strip (56°N to 66°N), with the
   Rime Teeth beside it and Highhearth below the Frost Quarry. The Ash Flats lie between the Cove Camp and the Spire; the
   Red Hills are behind them to the east. The Grey Fen is "three days along the coast" west of the Cove Camp, in the
   story's order: Wrack's End and its cliffs come first (27 units from the camp), then the fen (Kindly Hill 47, the
   Drowned Cloister 61, the Hollow Court 74 units). The Hollow Cape is a spit running east from the north-eastern end, "where
   the charts showed only sea", with open water beyond it for the tear and the White Fleet's Grave.
4. **The Old Continent.** Alster is a river city on the south-western coast, its harbour on the west coast with the stone giant
   at the harbour mouth; its river comes down from the Alster Downs through the city to the harbour. East of the hills the
   dunes run "from Alster's hills to the sea": the Waste fills the interior, with the Lark's wreck nearest Alster, then the
   Sleeper's Face, then the White Wells, and the road goes on to Saltmouth's landward gate. Saltmouth crowns a brown headland
   on the northern coast at the equator's edge, where the desert meets the sea, with a stone giant in the harbour mouth
   and the Salt Pans on the flats below it.
5. **The crossing.** Saltmouth (the wharf) to the Cove Camp is 59 units, about 5,200 km (a unit is 0.8° of latitude, about
   88 km): three weeks at 10 km/h. The Crossing (`storm`) sits at sea on the route, with nothing between.
6. **The Lantern Isles** lie across the sea from the Cove Camp (73 units away, south-west), off the crossing and every
   other road, one island with Candlehold on its cliffs.
7. **Only what the story needs, where the story is.** 34 places (every landmark), 2 rivers, 4 mountain ranges, 11 named zones and
   23 features, all in the three story lands. The empty lands and archipelagos carry nothing; chart B has 8 lands, 2 rivers, 6
   ranges and 55 features.

## Features kept and dropped

Kept (23): the 12 clan seats (the Lantern Throne, the Spire of Judgment, Anvil Gate, the Heron's Wake, the Brig, the Vigil's
Wall, the Exorcists' Gate, Highhearth, Akagiri, the Kindly Hill, Lowtide, the Open Hand's hall), the two stone giants
(Alster's harbour, Saltmouth's harbour mouth), the Stone Bridge, and the places the story's own blurbs name or describe: Tallow
Street, the Salt Pans, the Salt Marsh, the Hot Springs, the False Lamps, the Frost Quarry, the Exorcists' Road, the Slag
Kilns. Each keeps chart B's names, notes and clan; only its position is new (`storyFeatureAt`).

Dropped (32): the villages and works the story never names, four of B's five bridges, the other quest sites, and B's 44 trade
roads. All are in chart B and can come back one by one if Narrative says they have a role.

## Choices to confirm

- The empty lands and archipelagos are a first placement; each can move, grow or go.
- **One Lantern island**: "Isles" is plural, so a second small island could be added.
- **Place spacing** is at least 11 units (chart B: 10.6); the north's labels still crowd when every place is read, as on B.
- The story does not say where along the north the Black Reliquary stands; I put it at the middle.
- **Land share** is 41 % against B's 54 %: if the globe still feels sparse, the empty lands can grow.

## For Core, if this becomes a playable chart (`lib/data/`)

- A fourth value `MapShape.story` (the name is Core's), `chartWorldStory` in `chart_worlds.dart` (the generated Dart is
  ready: `places`, `lands`, `rivers`, `labels`, `zones`, `ranges`), the 23 `features` (names and notes from B, positions from
  `storyFeatureAt`), and `chartOf` for the new shape. No trade roads.
- `map_charts_test.dart` wants every landmark to have a spot on each chart: all 34 do.
- A `jungle` biome (above) if the east land is to look like one.
- One optional field would give a cleaner map: `ChartGeography.islets` (default true) so the painter's own skerries, which it
  adds off every coast, can be turned off here.
- One line in `climate.dart` for the Red Hills (a stronger volcanic warmth), above.
- Narrative: the zone names are B's (French included); the empty lands' zones and the archipelagos have none yet. The ranges keep B's names.
