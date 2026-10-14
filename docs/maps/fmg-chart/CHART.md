# The generated world through the game's own chart painter

A preview, not a change to the game. `tool/fmg_chart/fmg_to_chart.py` converts the generated world
(`docs/maps/fmg-seed102` on `claude/fmg-map-experiment`) into a `ChartGeography`
(`tool/fmg_chart/chart_fmg.dart`), and `tool/fmg_chart/preview_test.dart` draws it with
`ChartMapPainter` beside chart B (`flutter test tool/fmg_chart/preview_test.dart`, PNGs in `build/fmg_chart/`).

- `compare-night.jpg`, `compare-parchment.jpg`: chart B (today) on the left, the generated world on the right,
  both painted by the same code, every place read, no fog.

## What the converter does

| From the generated world | To the chart (256 x 176 units) |
|---|---|
| the three lands' coasts (662 / 467 / 488 points) | simplified to 94 / 83 / 88 points (Douglas-Peucker, 1.1 units); the painter still breaks them into bays |
| the 34 places | scaled so the lands' bounding box fills the chart (6 units of sea kept round it), then spread apart: chart B's closest two places are 10.6 units apart, the generated ones were 1.4, so a relaxation pushes places apart to about 10.8 units, on land (sea places stay at sea), with a light pull back to where the generator put them |
| 12 rivers | simplified, source to mouth |
| the regions of `spec.json` `countries` | 8 zones: each country's share of its land (the land split between its places, Voronoi), with the game's biome ids (temperate, desert, arid_coast, ashlands, fen, frost, tear, sea_cliffs) |
| the relief icons of the SVG | 4 mountain ranges (the icons that are mountains, clustered, one line fitted through each), named after chart B's ranges |
| (none) | 3 sea names, set in the open water furthest from land |
| chart B's 55 features and 44 trade roads | carried over: each moved by the shift of the nearest landmarks (inverse-distance weighting), nudged onto land |

The scale is 0.174 horizontally and 1.25 times that vertically: the generated lands are wider than the chart
(1405 x 663 px against 256 x 176 units), and a uniform scale leaves 40 units of empty sea. That is a 25 % squash of the
geography; set `STRETCH = 1.0` in the script for none.

## What doesn't fit the game's look yet

1. **The shape of the world.** Chart B is a ring round an inner sea: the lands fill the chart and the Lantern Isles sit in
   the middle. The generated world is two big lands far apart with open sea around, so the chart's lands are small and the
   Ashen Continent holds 18 places in a small area. Labels pile up there (the Reliquary cluster, the Spire, Emberwick) far
   worse than on B. The painter's `leftLabels` and a wider spacing would fix some; the generator's seed or the Ashen
   Continent's size (a bigger island, or fewer districts on it) fixes it properly.
2. **Place spacing.** After relaxing, the closest pairs are still 7.6 units (Greyhithe/the White Anchorage, the ship-breaker's
   yard/Tern Row), under B's 10.6, because those places sit on a narrow coast. Chart B was drawn with room for names.
3. **Biome zones.** Each region is one Voronoi share, so the borders are straight lines across a land, not following the
   generated biomes (desert, taiga, wetland). On B the zone tints read as terrain; here they are faint and the regions are
   not always where a player would expect them (the Waste's name sits at the south tip of the Old Continent, below its own places).
   Better: regions from the generator's biome cells (the SVG's `biomes` group) merged by the nearest country, then smoothed.
4. **Mountain ranges.** Only 4 clusters of 6 or more icons were found and one (94 icons) is a long ridge along the Frost
   Reach; B has 6 named, short, spaced ranges. Needs a cap on cluster length (split long ones) and the names (the Rime
   Teeth, the Scaffold Crags...) placed by Narrative where they now fall.
5. **Roads.** The generated roads were routed over the terrain on the generator's canvas; once places are spread apart those
   lines no longer touch their places, so the preview lets the painter bend a road between two places as it does today.
   The better road is the routed one: it needs a field that carries a polyline per road id.
6. **Features carried from B.** 3 of the 55 land off the coast (the False Lamps, the Brig, the stone giant of Alster's
   harbour) and many sit at a village's distance from the wrong place after the warp. The 44 trade roads follow the
   warp and cross the sea in places. They should be re-placed by hand, or auto-placed from the generator's own burgs
  .
7. **Empty extra islands.** The PNG's extra islets (and the second and third small lands) are not in
   `game-map-data.json` (only the three continents are), so the chart has none. The painter draws its own islets off the
   coasts; the generator's can be added as short `lands` loops (6 to 10 points each) if they are wanted.
8. **Seas.** B names an Inner Sea in the middle; the generated world has no inner sea, so only the Narrow Sea (between the two
   lands, at the place `storm`), an Open Water and a Grey Water are labelled. `chartWorldFmg` has no lake (the generator has
   a large lake on the Old Continent that the chart cannot draw: it needs a `lakes` list, see below).
9. **Style.** The painter already gives the game's look to any geography (cased roads, pixel-style marks, relief shading, the
   compass), so nothing in the generator's atlas style carries over or needs repainting. What does not carry over is the
   atlas's own detail: its forests, its hills, its labels.

## What a real, playable chart needs (for Core: `lib/data/`)

A fourth value of `MapShape` (call it `generated`), `chartWorldFmg` in `chart_worlds.dart` (the generated file is
ready: `places`, `lands`, `rivers`, `labels`, `zones`, `ranges`), and `chartOf(MapShape.generated)`; then, by hand or from the
generator, each of the following.

- **`features`**: the villages, works, bridges, giants, seats and quest sites, placed on this geography (55 on B).
- **`tradeRoads`**: the grey roads between places (B has 44).
- **`zones`**: the `influence` lists (the clans' writ per zone) that B's zones carry for the clans calque.
- **Test data**: `map_charts_test.dart` wants every landmark to have a spot on each chart (the generated one has all 34).
- **Optional new fields** if the generator's detail is wanted: `ChartGeography.roadLines` (`Map<String, List<Offset>>`: road id
  to a routed polyline, used by `chart_map_painter.dart` instead of bending a line between two places), and
  `ChartGeography.lakes` (closed loops, drawn like the sea).
- Narrative: names (FR included) for the new places the converter had to invent: the zones (The Ashen Coast and The
  Throne's Demesne have no French name yet) and the mountain ranges.
