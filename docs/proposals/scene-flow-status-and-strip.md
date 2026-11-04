# Scene transitions: what of the scene-or-map rule is built, and a position strip for UX-2

Core, 2026-11-04. Docs only, nothing built. This answers the manager's two
questions. It was checked against `main` at v1.808, by reading the code and
the merge history, not by playing the app.

## 1. Was the rule in `scene-vs-map-flow.md` built?

**Partly.** The classification was built in full. The part the user would
notice, "a choice that stays in the same place keeps you in the scene,
without the map", was not built as written.

### What exists

| Piece of the rule | Built in | State |
|---|---|---|
| A scene's stop: its building, else its district, else its location | v1.444 (#364), `lib/data/choice_flow.dart` (`StoryStops`) | built |
| Four kinds of flow after a choice: `FlowStay` (same stop), `FlowMap` (a plain way to another stop), `FlowTripThenArrive` (acted out here, aftermath elsewhere), `FlowReturnToHub` (an errand's way back to its hub) | v1.444 | built, and the Journey computes it after every choice (`_flowAfter` in `journey_screen.dart`) |
| Carried trips after an action, and the one-tap return to a hub with its "You came back to…" notice | v1.444 | built |
| Main-story scenes read full screen (S1), everything else in a sheet over the map (S2) | v1.444, `arrivalViewOf` in `arrival_sheet.dart` | built |
| The map shows only the ways that move the party; choices acted out here are cards | v1.418, v1.680 (in-place choices) | built |
| The read-through stops at a change of district | v1.444 | built |
| Service pins (`servicesAt`) | v1.444 | built |
| The prologue with no map | v1.541, v1.692 | built |
| A scene "locks" (no way back to the map) when every one of its ways is acted out on the spot | v1.555, narrowed in v1.563 | built |
| One-card pages and the intro hide "Back to the map" and the top bar's map button | v1.692, v1.702 | built |

### What was not built

**`FlowStay` doesn't keep the scene.** `_take` in `journey_screen.dart`
treats every choice that moves the story the same way, whatever its flow:

1. It opens the next scene full screen (main story) or in the sheet (anything else).
2. *Continue* brings the map back.

`arrivalViewOf` looks only at whether the flow is a return to the hub. It
never checks `FlowStay`. So a choice that leads to the next scene **in the
same place** still goes out to the map and back, which is disagreement D1
of the review (729 of the 1,061 choices then). The only exception is a
scene that locks, where every way is acted out on the spot. A scene that
mixes ways on the map with cards (most town scenes) goes back to the map
after each card.

That is very likely what the user means by "scene transitions that make
sense". The page and the map take turns even while nothing has moved.

### What finishing the rule would take (for when it is assigned)

- **Behaviour (Core, shared file `journey_screen.dart`, a few lines in `_take` and the build):**
  - after a `FlowStay`, keep the scene view open on the new scene: its words, then its cards and rings, with no *Continue* back to the map;
  - offer the map only when the new scene has a way that moves (`FlowMap`), or on request through the top bar's button.
- **Look (UX):** how the scene view holds a run of scenes in one place: replacing the text or appending it, and a short beat between scenes.
- **Tests:** the Journey's flow tests would change. "Continue goes back to the map" becomes "a same-place step stays in the scene".
- **Risk:** medium. It touches the Journey's main loop. The scene lock and the one-card rules already cover part of it, and would become special cases of this one.

## 2. Can Core give UX-2 a position table: a long strip per region, the camera set by position?

**Yes.** It can be derived from what Core already has, with no new data:

| Needed | Exists |
|---|---|
| Where each scene happens | `StoryStops` (a building, district or location per scene) and `Geography.placeOfNode` |
| Which region a place is in | `Geography.ancestorAt(id, GeoLevel.zone)` or `.country` (levels: continent, country, zone, location, district, building) |
| Where each landmark is | the story chart's landmark positions (`map_charts.dart`, `storyChartProvider`) |
| How landmarks join | `world_roads.dart` (roads with their named stops, land or sea) and `world_leg_path.dart` (the polyline of a move between two landmarks) |
| Where districts are inside a town | `city_plan_record.dart` (each district's label point and shape, in the plan's 1000 × 1000 square) |

### Proposed shape (one pure file, for example `lib/data/region_strip.dart`)

```dart
/// One region laid out as a line: its places in order along it, each at a
/// position from 0 (the strip's start) to [length] (its end).
class RegionStrip {
  final String regionId;          // a zone (or a country, by choice)
  final double length;            // in chart units along the roads
  final List<StripStop> stops;    // in order along the strip
  double? positionOf(String placeId);   // a landmark, district or building
}

class StripStop {
  final String placeId;           // the landmark (location)
  final double at;                // its position on the strip
  final Map<String, double> districts;  // district id -> position, around [at]
}

/// Every region's strip, and the strip and position of a scene.
class RegionStrips {
  RegionStrip? stripOf(String regionId);
  ({String regionId, double at})? positionOfNode(String nodeId);
  /// The positions a move passes, start to end, for the camera to follow
  /// (from world_leg_path's polyline, projected on the strip).
  List<double> pathOn(String regionId, String fromPlace, String toPlace);
}
```

### How the positions are laid out

**The spine.** Within a region, the strip follows the roads in the order
the main story first reaches each landmark. A place's position is the
road distance from the strip's start (`world_leg_path`'s polyline length),
so the camera moves in proportion to the real walk.

**Places off the spine.** A side site or a branch road is placed at the
spine point nearest to it, with its own short offset. The strip stays a
single line.

**Districts.** They are spread around their town's position in the order
of their x position on the city plan, or in story order if UX-2 prefers.
Their spread is scaled to the town's share of the strip.

**Between regions.** A sea crossing or a land route (`landRouteId`) ends
one strip and starts the next. Its own screen already plays the move.

**A region with no roads.** Its landmarks are ordered by x on the chart.

### Open choices for UX-2 and the manager

- Should the region be the zone or the country?
- Should positions be road distances (true to the map) or even steps (each place one step)?
- Should districts be ordered along the plan or by story order?

**Size:** one file of roughly 200–300 lines, plus a test that checks:

- every scene has a position;
- positions grow along the main story within each region;
- every move's path stays inside its region's strip.

**Risk:** low. It's a new query and changes no existing code.

## References

- `docs/proposals/scene-vs-map-flow.md`: the review, with the user's answers.
- `lib/data/choice_flow.dart`, `lib/widgets/arrival_sheet.dart` (`arrivalViewOf`), `lib/screens/journey_screen.dart` (`_take`, `_flowAfter`).
- `lib/data/geography.dart`, `lib/data/world_roads.dart`, `lib/data/world_leg_path.dart`, `lib/data/map_charts.dart`, `lib/data/city_plan_record.dart`.
