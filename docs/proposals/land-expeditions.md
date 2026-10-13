# Proposal: land expeditions in side view

Core, for the manager. Approved, with the user's amendments (v1.275): the party's health plays the hull (no water, no food), and **the crash is the first expedition**. Last in Core's queue.

## What

A long land route is played like a voyage. When the party leaves a place on a long land route, the Journey map gives way to a side view of the party on the road. A short chain of events is drawn once at departure, and each event asks what the party does. The crossing ends with arrival on the far side, or with a turn back. It follows the shape of `voyage_screen.dart` and `sea_events.dart`, on land.

## The first expedition: the crash

**Confirmed by the user.** Chapter 1 plays in Alster on the Journey map, then the escape on the Lark (scenes 891–898), then the crash (1100, the wreck of the Lark).

- From the wreck, the crossing to the White Wells plays as the first side-view expedition: the Wreck of the Lark (`crash`), the Sleeper's Face (`sleeper`, 1140), then the White Wells (`wells`). It uses the existing roads `crash_sleeper` and `sleeper_wells`.
- The town before the crash stays on the Journey map.
- The tutorial introduces the expedition screen at the wreck: a topic in `lib/tutorial/`, Narrative's text and UX's step.

**Saves (the cheaper way).** The crossing starts from the wreck's way out, a `landRouteId` on the choice that leaves 1100. Its middle scenes (1120–1140) stay in the story graph, as the crossing's fixed beats.

| where the save is | what happens |
|---|---|
| before the crash (chapter 1, or the Lark) | meets the new crossing when it leaves the wreck |
| at the wreck (1100) | the same: the crossing starts there |
| in the middle (1120 to 1140) | keeps the old scene flow: those scenes' own choices still lead to the Wells, so the save walks on as before and never sees the crossing |
| past the crash | unaffected |

This needs no migration code and no save field. The alternative, resuming the crossing from the wreck, would need a check on load and could replay a beat the player has already read.

## What plays the hull

On a voyage, the Rusty Eel's hull is what runs out. On land, **the party's health** does:
- A crossing's events and fights cost health: a sandstorm pushed through, a dry well, a fall, raiders fought.
- Some events give health back: shade found, a spring, a caravan's healer for gold.
- Nothing heals on its own between events, and potions work as they do anywhere.
- When the party's health runs out, the crossing fails. The party is carried back to where it set out, the way a sunk hull brings the Eel home: alive but wounded (at the floor `hungerShare` already uses), with the days spent.

There is no water and no food, and no meter of its own; the bar the side view shows is the party's own health. The road's existing provisions rule (`provisionsLeft`) keeps working as it does today and is not part of the crossing.

## The data each route needs

A new `land_routes.json` (Core) holds one entry per route:

```json
"crash_to_wells": {
  "from": "crash", "to": "wells", "roads": ["crash_sleeper", "sleeper_wells"],
  "days": 4, "biome": "desert",
  "events": {"sandstorm": 2, "dry_well": 1, "spring": 1, "mirage": 1, "raiders": 1},
  "fixed": [{"day": 2, "event": "sleeper_face"}],
  "enemyPool": ["wreck_scavenger", "street_bandit"],
  "chapter": 1
}
```

- `days` sets how many events are drawn. `events` are draw weights, like the sea's. `fixed` puts a story beat on a given day (here the Sleeper's Face, so the landmark is still visited in the story's order).
- Each event's health cost or gain sits in `land_events.json`, scaled by chapter. The event texts in that file (English and French) are Narrative's words; the numbers are Core's.
- A story choice names its route with `landRouteId`, the way a node's `portId` names a port today. Without one, the Journey's ordinary walk is unchanged, so every existing route keeps working.

## Save impact

**No new save field.**
- Health is already saved.
- A crossing is not saved part-way. Like a voyage, it is played in one sitting; leaving the app mid-crossing resumes at its start, so the event chain needs no save.
- The landmarks a crossing passes are marked visited exactly as the walk marks them today, so the travel-history map (v1.272) shows the route.
- Old saves: see the table under "The first expedition" (a save in the middle of the crossing keeps the old scene flow).

## Work, by session

- **Core:**
  - `land_routes.json` and the numbers in `land_events.json`
  - the event engine (a sibling of `sea_events.dart`)
  - the health rule and the turn-back on failure
  - the simulator playing crossings
- **UX:** the side-view screen, the voyage screen's layout on land: dunes, the party walking, the health bar; the tutorial's step on it.
- **Narrative:** the event texts, the crash crossing's beats, and the tutorial text at the wreck.
- **QA:** L2 (a new screen, combat on the road).
