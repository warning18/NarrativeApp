# Towns tinted by the ruling clan (wave 15), Core → UX

UX tints each town on the maps by the clan that rules it. Core supplies
which clan rules each town and each of its districts now, and the clan's
colours. UX draws the tint. Core changes nothing that is drawn.

## Which places are towns

`townIds(geography, planIds:)` in `lib/data/town_rulers.dart`: every
geography.json **location** of kind `city`, `town` or `village`
(`townKinds`), plus every place with a city plan record (city_plans.json),
which adds the cove camp. That makes **16 towns**, the same 16 that have a
city plan. Their **59 districts** (the `district` children of a town) get an
entry each.

## Who rules them

The live territory state: `holderOf(placeId, geography, politics)` in
`clan_power.dart`. That is geography.json's `controller` overridden by
`PoliticsState.control` as places change hands at a chapter's turn, and
taken from the nearest place up the chain that has one.

- **A town** takes `holderOf(town)`. When that is empty, it takes the clan
  that holds the most of its districts. A tie, or no held district, is
  neutral.
- **A district** takes `holderOf(district)`: its own holder, otherwise its
  town's. So Cinder Row (Compact) and Spire Stair (Dominion) report their
  own rulers whoever holds the Ashen Quarter, and they change with
  `control`.

## Colours

The data already had them: each faction in `factions.json` has a `color`
(`"#RRGGBB"`), parsed as `Faction.color` (ARGB int). The clan cards
(`people_widgets.dart`, `clan_widgets.dart`) and the chart's seats and
influence calque (`journey_world_map.dart` builds `clanColours` from
`factions[id].patron.color` and passes it to `chart_map_painter.dart`)
already read it. UX has no separate palette, so there is nothing to drift
and no colour was added.

- `color`: the clan's `color`. A neutral place gets `townNeutralColor`
  (`0xFF7C766B`, a dull warm grey).
- `accent`: `color` darkened by 35% (`shadeColor`, `townAccentShade`), for a
  border. It is computed from the data, not stored.

The clans that can hold places today (geography controllers, seats and
claims) are dominion, vigil, compact, mire, crows, penitents, giants, oni,
tidekin and kindly. All of them have their own colour. Compact (#B86B3C)
and Crows (#B0303F) are the closest pair among the main clans, about 60
apart in RGB.

## API

```dart
// lib/data/town_rulers.dart (pure)
Map<String, TownRuler> townRulers(Geography, PoliticsState,
    Map<String, Faction> factions, {Iterable<String> planIds});
List<String> townIds(Geography, {Iterable<String> planIds});
int townColorOf(String clanId, Map<String, Faction> factions);

class TownRuler {
  String placeId;   // the town or district
  String cityId;    // its town (itself for a town)
  bool isDistrict;
  String clanId;    // '' = neutral (isNeutral)
  TownRulerSource source; // own | above | districts | none
  int color, accent;      // ARGB
  bool mixed;       // a town only: one of its districts has another ruler
}

// lib/providers/town_rulers_provider.dart
final townRulersProvider;                 // Map<String, TownRuler>
TownRuler? rulerOfTown(WidgetRef ref, String placeId);
```

`townRulersProvider` watches geography, `politicsProvider`,
`factionsProvider` and `cityPlanRecordsProvider`, so a place that changes
hands gets a new tint at once. The cove camp, a town only through its plan,
appears once the plans have loaded.

## At the start of the game

| Town | Ruler | Source |
|---|---|---|
| Candlehold | dominion | own |
| Emberwick | compact | own |
| Akagiri, Kindly Hill, Highhearth | oni, kindly, giants | own |
| Saltmouth | crows (2 districts against tidekin's 1), mixed | districts |
| Drowned Cloister | mire (Mire Court), mixed | districts |
| Alster, Ashen Quarter | neutral (district tie), mixed | none |
| the rest | neutral | none |

## Not covered

- Locations of kind `site`, `camp` (except the cove camp), `sea` and `wild`
  (the Spire of Judgment is held by the Dominion but isn't a town), and
  buildings.
- Zones and countries: a country's `ruler` doesn't count as holding a place,
  the same as in `holderOf`.
- How strongly a clan holds a place (power, a contested claim). Only the
  holder is given.
