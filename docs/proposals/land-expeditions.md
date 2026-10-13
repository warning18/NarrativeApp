# Proposal: land expeditions in side view

Core, for the manager. Nothing is built yet; this is for a decision.

## What

A land crossing played like a voyage. When the party leaves a place on a long land route, the Journey map gives way to a side view of the party on the road: a short chain of events drawn once at departure, each asking what the party does, and arrival on the far side or a turn back. It uses the shape of `voyage_screen.dart` and `sea_events.dart`, on land. The first one is the opening crash: from the Wreck of the Lark (`crash`) across the Waste to the White Wells (`wells`), the oasis, by the Sleeper's Face (`sleeper`). The roads exist: `crash_sleeper`, `sleeper_wells`.

## What plays the hull

On a voyage the Rusty Eel's hull is what runs out. On land it is **water and food**, two meters on one bar:

- **Water**: the desert's clock. A day in an arid biome (`desert`, `arid_coast`) costs 2, elsewhere 1. At 0, each day costs health (as `hungerShare` does on the road today), and from the second dry day the party fights thirsty (a new condition: one face of the die goes blank, Core).
- **Food**: the existing provisions (`provisionsLeft`, max 8), eaten one a day as on the road. No new rule, just shown on the bar.

Events spend or refill them: a dry well (−water), a cache found (+food), a caravan met (trade gold for water), a sandstorm (shelter a day, or push on and lose water), raiders (fight, pay or flee), a mirage (an ability check, or lose a day). Arrival refills both at a settlement. Running dry doesn't end the crossing at once: it ends it when health hits its floor, and the party is carried back to where it set out (as a sunk hull brings the Eel back), wounded, with the days spent.

For the crash, the party starts with little: 3 water, 2 food, which is what was saved from the wreck. That makes the first crossing a lesson in the meters, the way the first voyage is about the hull.

## The data each route needs

A new `land_routes.json` (Core), one entry a route:

```json
"crash_to_wells": {
  "from": "crash", "to": "wells", "roads": ["crash_sleeper", "sleeper_wells"],
  "days": 4, "biome": "desert",
  "events": {"sandstorm": 2, "dry_well": 1, "cache": 1, "mirage": 1, "raiders": 1},
  "fixed": [{"day": 2, "event": "sleeper_face"}],
  "startWater": 3, "startFood": 2,
  "enemyPool": ["wreck_scavenger", "street_bandit"],
  "chapter": 1
}
```

- `days` and `biome` set the water cost; `events` are draw weights (as the sea's); `fixed` places a story beat on a day (the Sleeper's Face here, so the landmark is still visited in the story's order).
- `startWater` / `startFood` override the party's own only for scripted crossings like the crash.
- Event texts (English and French) go in a `land_events.json` beside it: Narrative's words, Core's numbers.
- The story node that leaves for the route names it: a `landRouteId` on the choice, as a node's `portId` names a port today. Without one, the Journey's ordinary walk is unchanged, so every existing route keeps working.

## Save impact

One new field, `waterLeft` (int, default full in `fromJson`), beside `provisionsLeft`. An expedition in progress is not saved mid-way. Like a voyage, it is played in one sitting, and leaving the app mid-crossing resumes at its start; this needs no save of the event chain. Old saves load with full water and never meet the crash crossing again, because they are past it. A new game meets it after the wreck scene. The landmarks the crossing passes are marked visited exactly as the walk marks them today, so the travel-history map (task 2) shows the route.

## Work, by session

- Core: `land_routes.json`, `land_events.json`'s numbers, the event engine (a sibling of `sea_events.dart`), the water rule in `journey_rules.dart`, the save field, the simulator playing crossings.
- UX: the side-view screen (the voyage screen's layout on land: dunes, the party walking, the meters' bar).
- Narrative: the event texts, and the crash crossing's beats.
- QA: L2 (save data, a new screen).

Open question for the manager: should water exist only in arid biomes (simpler: the bar shows it only there), or everywhere?
