# The travel-history map: what the view needs

UX to Core, through the manager. The view is built and tested
(`lib/widgets/travel_map_view.dart`, `test/travel_map_test.dart`); it takes plain
values, so what follows is what Core's provider must hand it, nothing more.

## What the map shows

- The story-world chart (the one drawn in `tool/fmg_chart/chart_story.dart`,
  `chartWorldStory`), under the fog of an unfinished chart: a dotted coast and
  the lands' names, no place the party has not heard of.
- The places been to, **numbered in the order first reached**, joined by the
  road taken leg by leg (a road gone back along bows the other way, so it does
  not hide under itself), an arrow at the middle of each leg.
- The places heard of and not reached, as a **"?"** (no name).
- The party's own place, ringed.
- Pinch to zoom, drag to pan, buttons for zoom and "bring me to the party". It
  opens framed on the road taken. Names are laid out by the view, one clear of
  the next, so the crowded north continent stays readable (a name that cannot
  fit at a zoom shows when the chart comes closer).
- A tap on a place calls back with its id and `visited` or `known`.

## What the view takes today

```dart
TravelMapView(
  geography: ChartGeography,        // the story world
  palette: ChartPalette.of(look),
  language: AppLanguage,
  visited: List<String>,            // landmark ids, in the order reached
  known: Set<String>,               // landmark ids heard of, not reached
  here: String?,                    // landmark id of the party's place
  nameOf: (id) => landmarkById(id)?.nameEn ?? id,
  onTapPlace: (id, TravelPlaceState state) { ... },
)
```

`visited` can come from `journeyOf(history, currentNodeId)` as it is today.

## What I need from Core

1. **The chart in `lib/data`**: `chartWorldStory` (a `ChartGeography`) with the
   keys of `places` equal to the landmark ids of `world_map.dart` (they are).
   Its `leftLabels`, `labels`, `zones` as they are in the preview.
2. **A provider** (any name) with, for the player's session:
   - `visited`: the ordered landmark ids, a place gone back to repeated (so the
     legs are the consecutive pairs);
   - `known`: the landmark ids the story has named or a map has shown, minus
     `visited` (what shows as "?");
   - `here`: the landmark id the party stands at.
3. **Travel from camp** (later): `canTravelTo(id)` (false for a place still
   unknown, a place with no road, or when the party cannot leave) and
   `travel(id)`. The view only reports the tap; the camp decides, and says why
   in its own words when it cannot.

## Entry point (for the user to choose)

- **A. A map button in the Journey's header**, beside the chart's layers button:
  opens the travel map as a page. The map is a view of the Journey's world, so
  it sits with the Journey. (Recommended.)
- **B. In the Camp header** as "Travel": the map opens in "pick a place" mode
  (the "?" and the known places tappable, the rest dimmed). It is where travel
  starts, so it sits with the camp.
- Both can open the same page; only the mode differs (read it, or pick from it).

## Not decided

- Whether a "?" place shows a hint of where it lies (a faint ring) or only the
  mark; the view draws the mark at the place's real position today.
- Whether the roads taken keep their order numbers at the world zoom (they show
  from the second zoom today, to keep the first one clean).
