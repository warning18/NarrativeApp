# Town plans for every town: what UX has checked, and what UX needs from Core

From UX, answering the manager's note (a town map for every town; Core generates city plans for Alster, the Ashen Quarter, the Drowned Cloister, the Black Reliquary, the White Anchorage and Candlehold, then the 8 villages and the Cove Camp).

## Checked: the painters take any record

- `journey_screen.dart` looks the stored plan up by the party's location id (`cityPlanRecordsProvider` → `records[hereLocation.id]`) and builds the chart from it: no hard-coded place. The districts' names come from geography.json, the ways are pinned in the record's districts, and a way into a district the record doesn't have is pinned where the party stands.
- `CityChart.fromRecord`, `CityChartPainter` and `CityChartView` read everything from the record (wall, avenues, streets, bridges, squares, districts, buildings, anchors, names). The only mention of Saltmouth is `CityChart.saltmouthStub`, used by the standalone debug screen `city_chart_screen.dart`, not by the game.
- **A place with no record is not empty.** It falls back to the generated plan (`CityPlan.of`: streets, houses, gates by the nearest places), drawn under the same pins and tabs. Screenshot of the Ashen Quarter's gate (node 3005), District and Town tabs, with Core's stored plan missing: the plan is generic but the ways, the party and the tabs all work. So the first stored record for a place replaces a generated plan; it does not fill an empty view.

## A village style

UX will draw a village differently (no wall, a palisade of stakes, fewer and smaller houses, a green or square in the middle) when the record says so. Proposed fields, so Core and UX agree:

- `"style": "village"` at the top of the record (absent or `"city"` keeps today's look).
- `"wall": {"kind": "palisade", "points": [...]}`: a wall with no `kind`, or `"stone"`, is drawn as today; `"palisade"` as a ring of short stakes with gaps at the gates; `"none"` (or no wall) draws nothing.

Until Core's records carry them UX changes nothing, and once they do it is a painter-only change (`city_chart_painter.dart`). Say if the names should be different.

## World tab into a place

Zooming the World tab into a place with no plan already lands on its generated streets (see above), not an empty District view. If you meant a place with no districts at all (a camp, a road), tell me which one: today it shows a ring of its ways round the party on the land's ground, and UX can show the place card instead there.
