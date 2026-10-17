# Rooms, town services and the move on the world chart (wave 14), Core → UX

Three pieces of data for the Journey: a building's own plan when the story
walks into one, fixed service pins in every town with a plan, and the path of
a move between two places on the real world chart. Core stores and serves
them. UX draws them. Narrative words the names.

## 1. Building maps on arrival

The Journey already draws a building's rooms (v1.207, `journey_screen.dart`,
`RoomPlan`) whenever the scene's place is a geography.json **building**. What
was missing was data: of the 99 scenes whose text sets them indoors, only the
Blind Beggar's 7 stood in a building, so the rest showed streets.

### How a scene gets its building

`Geography.placeOfNode(node)` returns the scene's `location`, as the story
file (`assets/Cleaned_Narrative_DAG.json`) gives it. When that place has
`level: "building"`, the Journey calls it `hereBuilding` and draws
`RoomPlan.ofBuilding(id, kind, name)`. The scene's `spot`, if it has one,
puts the party at a named spot of that plan ('altar', 'counter', 'cells'…).
Without a spot, the party stands on the floor. So the link from a scene to
its building is the scene's own `location` field. No other mapping exists.

### What changed

- **geography.json**: 28 new buildings (30 in all). Each building record
  has: `level: building`, `parent` (a district, or a location with no
  districts: the Spire of Judgment and the Hollow Court), `kind` (one of
  `geoBuildingKinds`), and `name`, `name_fr`, `blurb`, `blurb_fr`. Kinds
  used: prison, temple, library, forge, hall, house, cellar, warehouse,
  shop. No new RoomKind was needed: every kind already has a plan.
- **Story file**: 76 scenes now have a building as their `location`, and
  46 of those also have a `spot`. These are non-text fields. Narrative
  may move any of them.
- **`RoomPlan.ofBuilding(id, kind, name)`** and **`RoomPlan.seedOf(text)`**
  (`lib/data/room_plan.dart`) build the plan the Journey draws: the seed
  comes from the id, and the kind from `RoomKind.resolve(kind, name)`.
  `journey_screen.dart` now calls these, so tests and screen share one
  plan.
- On a city plan, a way into a building now stands in that building's
  district (`districtOfPlace`), not in the scene's own district.

```json
"spire_hall_of_records": {
  "level": "building", "parent": "spire_of_judgment", "kind": "library",
  "name": "The Hall of Records", "name_fr": "La Salle des Archives", ...
}
// story: "3040": { "location": "spire_hall_of_records", "spot": "counter", ... }
```

### Coverage

| | interior scenes | in a building |
|---|---|---|
| before | 99 | 7 (the Blind Beggar) |
| after | 99 | 76 |

The list is `_interiorScenes` in `test/building_interiors_test.dart`. That
test checks four things: every scene on the list stands in a building;
every `spot` is a spot of its building's plan; every building has a kind
with a plan and holds a scene; and a building in a city with districts
stands in one of them.

### Not yet: 23 scenes have a building but still stand at their district (`_waiting` in the test)

- **Narrative seats them elsewhere** (`tool/city_plans/district_seats.json`).
  Moving them would contradict a seat Narrative already chose.
  - `6010_lysa_dead`: seated in the Chapels, but its chapel (the chapel
    with the chair) holds the Quarter's other chair scenes.
  - `6010_record`: the muniment room.
  - `5200_house_returned`: the long room under the hill.
  - `7590_*` (7 crowning scenes): their text says "the Lantern Hall's
    floor", but they are seated on the Lantern Cliff. If Narrative agrees
    with the text, link them to `candlehold_throne_room`, spot `dais`.
- **11 Black Reliquary scenes** go to buildings in the Reliquary's new
  districts (`reliquary_chapels`, `reliquary_frost_line`). Those districts
  have no world-map landmark yet, and a landmark's scenes must stand at or
  inside its home. Link them when the landmark lands:
  - the Tribunal's chapel
  - the chapel of the Hammer
  - the chart-keeper's chapel
  - the parish chapel
  - the muniment room
- **2 scenes on either side of a roll** (`3100_house_anvil_deaf_failed`,
  and `5200`, where `5200_house_barkbleeders` ends on a success): linking
  them would make the roll's other branch move the party with no note.
  They need a `failNote` from Narrative first (see `party_trail_test`).
- Two indoor scenes have no building: `2015_informant_trap` (a warehouse)
  and `5100_clan_dominion_1_lit` (the cliff light's lamp-room). Their
  rolls' branches also need a note first.
- **The city plans are not regenerated yet.** `gen_city_plans.dart` would
  join each building's scenes onto one lot of the city plan ("a building
  is one stop") and name that lot after the building. That would also drop
  Narrative's names for the lots it frees. Run it once Narrative agrees.
  Until then, a building's ways may stand on several lots of the city
  chart. Looking out of a room shows that chart.

### For UX and Narrative

- **UX**: nothing to change. A room appears as soon as a scene stands in a
  building. Kinds new to the story so far: prison (the Black Hold's cells),
  library (the Hall of Records, the Quarter's archive, the muniment room)
  and forge (the cold forge, Tetsu's forge). Their plans already exist.
- **Narrative**: the 28 building names and blurbs are Core's first draft,
  to be reworded. Also say which way the waiting scenes above should go.

## 2. Service spots in towns

Each record in `assets/gamedata/city_plans.json` (all 16 towns that have a
city plan) gains a `services` list:

```json
"services": [
  {"id": "saltmouth_notice_board", "kind": "notice_board", "at": [411, 379], "district": "saltmouth_landward_gate"},
  {"id": "saltmouth_market", "kind": "market", "at": [602, 429], "district": "saltmouth_wharf"},
  {"id": "saltmouth_tavern", "kind": "tavern", "at": [682, 405], "district": "saltmouth_card_row"},
  ...
]
```

- **Units**: the record's own 1000 x 1000 square (as `city-plan-record.md`).
- **kind**: `notice_board | market | tavern | temple | forge | harbour`, in
  that order (`townServiceKinds`).
  - Every town has a notice board, a market, a tavern and a temple.
  - A town has a harbour when its plan has a quay square.
  - Five towns have a forge, each in the district the story puts its
    smiths: Saltmouth (the Wharf), the Ashen Quarter (Cinder Row),
    Emberwick (Smithy Lane), Akagiri (the Forge Terrace) and the White
    Anchorage (the Hull Town).
- **at**: where each pin stands.
  - The market, the harbour and the notice board stand on a square: the
    market square's middle, the quay's middle, and the plaza's middle (or,
    with no plaza, the market's north side).
  - The tavern, the temple and the forge each take a building lot: the
    nearest lot of the right kind, a temple lot for the temple. A lot that
    carries no way's pin comes first.
- **district**: the district the pin lies in (`record.districtAt(at)`).
- The pins are laid by `placeTownServices` (`lib/data/town_service_pins.dart`)
  and written by `dart run tool/city_plans/place_services.dart`.
  `gen_city_plans.dart` lays them again on any new layout.
  `test/town_services_test.dart` checks that each pin falls on a square or
  a lot of its own record, in its district, and that the stored pins are
  what the plan lays out.

### What each opens

Read them through **`townServicesProvider(cityId)`**, or through
**`currentTownServicesProvider`** for the town the story is in
(`lib/providers/town_services_provider.dart`). Each entry is a
`TownService`: its `pin` (a `CityServicePin`: `id`, `kind`, `at` as an
Offset, `district`) and its `opens`, a list of
`(action, id, unlocked)`. `opensSomething` is true when one of them is
unlocked. The same pins are on the record as `CityPlanRecord.services`.

| kind | opens | screen or action |
|---|---|---|
| notice_board | `bountyBoard`, id `bounty_board` | `BountyBoard` (lib/widgets/bounty_board.dart, contracts.dart). Today it is the camp's board. |
| market | `shop`, one per shop the town offers, minus the forge's | `ShopDetailScreen(shopId:)`. `unlocked` = the session's `unlockedShopIds` |
| forge | `shop`, for the town's `weaponsmith_forge`, `hammersmith_forge` or `shieldwrights_hall` | `ShopDetailScreen(shopId:)` |
| tavern | `rest`, id `rest_night` | `restTheNight` (lib/widgets/road_panel.dart) |
| harbour | `port`, the port a settlement of the town names as its `portId` | `PortScreen(portId:)` |
| temple | **nothing** | no temple screen exists yet |

A town's shops and ports come from the story (`StoryStops.servicesAt`),
and only the town's own count:

- a shop that a choice in one of the town's scenes unlocks (`unlockShopId`);
- the port a settlement of the town names as its `portId`, with the shops
  ports.json lists for it.

A `landingPortId` does not count. It is where the Rusty Eel puts in for a
place whose port is elsewhere: Wrack's End lands at the Drowned Stair, for
example. Pass `story:` to `townServicesOf` to tell the two apart; the
provider does this.

What opens today:

- **Saltmouth**: the market (4 shops), the forge (`weaponsmith_forge`,
  `shieldwrights_hall`) and the harbour (`port_smugglers_wharf`).
- **The Drowned Cloister, the Black Reliquary and the White Anchorage**:
  one shop each at the market (`ossuary_relics`, `last_lantern`,
  `anchorage_chandlery`).
- **Everywhere**: the notice board and the tavern.

### Not covered

- **The temple has no screen.** Its `opens` is empty.
- **A market or forge with no shop of the town's own opens nothing yet.**
  That is the market of 12 towns and the forge of 4 (all but Saltmouth's).
- **A harbour opens nothing outside Saltmouth.** The other towns have only a
  landing port, or none. Their voyage belongs to the Ship tab
  (ShipScreen); `PortScreen` is only used in play for the Smugglers' Wharf.
- **The trainer** (`890_trainer`, Alster's High Quay) is a story scene, not
  a screen, so it has no pin.
- **The notice board shows the camp's contracts.** A town's own bounty
  board would be a new system; ask through the manager.

## 3. The move on the real world view

Today the Journey walks a leg (`_Step.route`, from
`chartRoadsBetween(chart, standing.id, target.id)`) on the Journey's own
chart. The ids are **world_map.dart landmark ids**: `standing` is
`landmarkOfScene(current scene)`, and `target` is `landmarkOfScene(the
scene the way ends at)`. The new API takes the same ids and lays the path
on the **story chart** (`storyChartProvider`, `chartOf(MapShape.story)`),
the one `full_map_screen.dart` draws.

```dart
WorldLegPath worldLegPath(ChartGeography chart, String fromId, String toId,
    {AppLanguage language = AppLanguage.en});
WorldLegPath? worldLegPathForScenes(ChartGeography chart, String fromNodeId,
    String toNodeId, {AppLanguage language});   // null: no landmark, or the same one
final worldLegPathProvider =
    Provider.family<WorldLegPath, ({String from, String to})>(...);  // story chart, language read
```

`lib/data/world_leg_path.dart`, `lib/providers/travel_history_provider.dart`.

A `WorldLegPath` has these fields:

- **points**: the polyline, in the chart's coordinates (the same space as
  `chart.places`), from A's spot to B's.
- **kind**: `road` (land roads only), `sea` (sea lanes only) or `crossing`
  (both, or a fallback line that leaves the land).
- **segments**: one per road, each with `from`, `to`, `roadId`, `kind`, and
  `start` and `end` (indices into `points`). Use them to change the walker
  to a boat on a sea segment.
- **stops**: the named stops passed (`ChartRouteStop`: `at`, `name`, and
  `along`, from 0 to 1).
- **routed**: false for the fallback.
- **length**, and **at(t)**: the point a fraction `t` of the way along,
  for a timed walk.

**Route sources.** `roadRoute` finds the shortest way over `worldRoads`
(`lib/data/world_roads.dart`: every land road and sea lane, kind `land` or
`sea`, with their stops). `land_routes.json` names the same roads by id.
Each road is laid the way the full map lays a walked leg:
`windingRoad(of(a), of(b), seed: chartSeed('a-b'))`, with 3 bends on land
and 2 at sea. Those are the same corners the painter smooths (`_smooth`),
so a one-road leg lies on the road the map then draws. UX may smooth
`points` the same way.

**Fallback.** When no road joins A and B, or an id is not a landmark of
the chart, the path is a straight line `[A, B]` with `routed: false`. Its
kind comes from the land under it: `sea` if either end is a landmark at
sea, `crossing` if the line leaves `chart.lands` on the way, and `road`
otherwise. A place the chart doesn't know stands at the chart's middle.
A → A is one point.

**Not covered.**
- **The full map draws a walked leg as one road between its two ends.** A
  long way through other landmarks (A to C through B) is drawn as a single
  road A–C on the map, while the walk follows the roads through B. To make
  the drawn road match, the painter could draw `worldLegPath(...).points`.
  That is UX's call.
- **The full map's own sea legs** use `atSea` or shore→Candlehold, not the
  road's kind. A few legs may wind with land's 3 bends on one and the
  sea's 2 on the other.
- The camera, the speed and tap-to-skip are UX's.
