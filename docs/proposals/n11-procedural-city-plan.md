# N11: what removing the procedural city plan changes (note, v1.788)

The user approved N11 (`core-improvements-2.md`) in principle, with one condition: this note comes first. It answers three questions:

- which places would lose their layout;
- whether any screen changes;
- what else reads the procedural plan.

Nothing is removed until the manager and UX-2 have read it. UX-2 checks it with pictures.

## 1. Which places have a stored plan

`geography.json` has 23 locations: 4 cities, 3 towns, 8 villages, 1 camp, 5 sites and 2 seas.

- **All 15 cities, towns and villages have a stored plan** in `city_plans.json`:
  - cities: Alster, Black Reliquary, Candlehold, Saltmouth;
  - towns: Ashen Quarter, Drowned Cloister, White Anchorage;
  - villages: Akagiri, Emberwick, Greyhithe, Highhearth, Kindly Hill, Rimewell, White Wells, Wrack's End.
- **The camp has a stored plan too** (the Cove Camp, 4 districts), but nothing draws it (see §3).
- **The 7 places with no stored plan never get a city plan.** These are the sites (the Hollow Court, the Hollow Shore, the Wreck of the Lark, the Sleeper’s Face, the Spire of Judgment) and the seas (the Crossing, the White Fleet’s Grave). The Journey only builds a plan for a city, town or village (`journey_screen.dart:1441`); these draw the generic place picture (`PlacePlanPainter`), now and after N11.

**No place loses its layout.**

## 2. When the procedural plan is drawn today

The Journey builds `CityPlan.of(...)` for every city, town and village visit (`journey_screen.dart:1456`). It is replaced by the stored record as soon as `cityPlanRecordsProvider` has loaded (`:1488–1546`).

So the procedural streets are on screen only in two cases:

1. **The first moments of a visit, while `city_plans.json` loads.** The file is decoded in an isolate since v1.741 (P3). On a cold start this can show the procedural streets for a few frames before the stored chart replaces them.
2. **A city, town or village without a record.** There is none today. One added to `geography.json` later without a `city_plans.json` entry would be drawn procedurally.

**What would visibly change after N11:**

- In case 1, the city page would show the generic place picture (or nothing) for those frames, instead of a different street plan that then jumps to the real one. That is arguably better (no jump), but it is a visible change. UX-2 should look at it on a cold start.
- In case 2, a future city without a record would get the generic place picture. The tool that writes `city_plans.json` (`tool/city_plans/gen_city_plans.dart`) would need to run for every new city. A guard test could require a record for every city, town and village; Core would add it.

**No other screen changes.** The stored chart (`CityChart.fromRecord`), the district walk, the doorsteps, the found districts, the town services and the town rulers all read the record, not the procedural plan.

## 3. What else reads the procedural plan

| Reader | What it uses | After N11 |
|---|---|---|
| `journey_screen.dart:1441–1470` | builds `CityPlan.of` for every city visit | removed |
| `journey_screen.dart:1488` | `plan != null` gates the stored-record branch, i.e. "this is a city" | the gate becomes "this is a city, town or village" (`citySize != null`) |
| `journey_screen.dart:1718` | `plan != null` gates "the city's plans are still loading" (no ways lock until then) | the same gate, kept |
| `journey_screen.dart:3119–3866` | `_plan` feeds `CityPlanPainter` when there is no chart | removed, with the painter |
| `lib/widgets/city_plan_painter.dart` (UX, 751 lines) | paints a `CityPlan` | removed (UX's file) |
| `lib/data/place_plan.dart` | the `PlacePlan` interface `CityPlan` and `CityPlanRecord` share | stays (the record still implements it) |
| `test/city_plan_test.dart` (5 tests), `test/chart_weather_test.dart` (5 uses of `CityPlan.of` for the climate) | the procedural plan's own tests | removed; the climate tests move to the record's chart if they still matter |
| `tool/city_plans/` | does **not** use `CityPlan` (it has its own generator) | unchanged |

**One finding along the way: Cove Camp's stored plan is never drawn.** A camp gets no procedural plan, and the record branch only runs when one exists (`plan != null`). The same change that replaces the gate (row 2) would draw Cove Camp from its record for the first time. That is a visible change; the user decides whether they want it.

## 4. Size

- `lib/data/city_plan.dart`: 1,200 lines (Core). It also holds `CityClimate`, `CitySize` and `CityDistrict`, which the Journey uses; those small types would move.
- `lib/widgets/city_plan_painter.dart`: 751 lines (UX).
- In all about 1,950 lines plus their tests.

## 5. Proposed steps, after this note is read

1. **Core:** replace the `plan != null` gates with "is a city, town or village", keep the small types, add the guard test (every city, town and village has a record), and stop building `CityPlan.of`.
   - Cove Camp stays undrawn unless the user wants it.
   - One version; the stored chart must be identical in every city.
2. **UX:** remove `city_plan_painter.dart` and the Journey's procedural branch (UX's lines in a shared screen), after looking at a cold start.
3. **Core:** delete `city_plan.dart` and its tests.
