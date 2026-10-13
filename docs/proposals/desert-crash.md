# Outline: the desert crossing after the crash (project L)

Narrative, for the manager. **Outline only**: nothing here is built or
written until the user approves project L. It builds on Core's
[land-expeditions.md](land-expeditions.md) (the system) and gives it a story:
what the crossing from the wreck of the Lark to the White Wells holds, beat by
beat, and what it takes the place of.

## What stays

Chapter 1 in Alster (the Journey map) and the escape on the Lark (scenes
891–898, 965) stay as they are. So does the White Wells (1200 and its
second beats). The crossing replaces only the walk between them.

## What it replaces today

| Scene | Today | In the crossing |
|---|---|---|
| `1100` lark_wreck | the wreck: touch the tear, bury the crew, follow the tracks | **stays a story scene**; its choices still set their flags, and one new last choice leaves for the crossing (`landRouteId`) |
| `1101`, `1101_scarred` | the tear's glance (luck check) and its scar | stay (still reached from `1100`) |
| `1120` | "the heat is a place": a Constitution check, or lie up and walk by night | **becomes the crossing's weather**: the sandstorm / heat events (see below) |
| `1125` | heatstruck, crawl into the shade | **becomes the failure edge**: health runs low, the party is found in the Face's shade |
| `1130` | the Sleeper's Face: drink, take offerings, leave a coin | **stays**, as the crossing's fixed beat (Core's `fixed: day 2`) |
| `1140`, `1140_spotted` | the looters' camp: fight, slip past, go round | **stay**, as the last fixed beat before the Wells |
| `1200` | the White Wells | unchanged: the crossing ends here |

Saves in the middle of `1120`–`1140` keep the old scene flow (Core's table),
so those scenes must keep working as story scenes. The crossing adds events
around them rather than removing them.

## The shape: four days, health as the hull

Core's example route is four days, weights `sandstorm 2, dry_well 1, spring 1,
mirage 1, raiders 1`, with the Face fixed on day 2. The party's health is the
bar; there is no water or food. Narrative's job is to make each of those draws
read as the same walk, not as a random table.

| Day | Beat | Kind | What the player feels |
|---|---|---|---|
| 0 | the wreck (`1100`) | story scene | grief and the first small choices (the crew, the tracks, the tear) |
| 1 | the dunes | event draw | the heat starts to cost; first decision on the road |
| 2 | **the Sleeper's Face** (`1130`) | fixed | the one landmark; the world admits it is old |
| 3 | the long south slope | event draw | tired, and the lights not yet in sight |
| 4 | **the looters' camp** (`1140`), then the lights | fixed | a last fight or a last sneak, then the oasis |

Total length: about four events plus two fixed beats. The player reads or
chooses on every day; no day is a bare timer.

## Events to write (EN + FR)

Each event is a short passage plus two or three choices, each choice with a
health consequence Core sets in `land_events.json` (the numbers are Core's).
Narrative writes the words. The variants below are the minimum; each type
wants two or three phrasings so a second crossing does not read the same.

| Event | Passage in one line | Choices (the shape, not the words) |
|---|---|---|
| `sandstorm` | a wall of sand with a sound like cloth tearing | push through (health cost) / dig in and wait (a day's cost, less health) |
| `dry_well` | a well the map swore by, dry, with someone's bucket still hanging | search the sand for water / move on |
| `spring` | green and wrong in a hollow: a seep under a rock | drink and rest (health back) / take a skinful and go |
| `mirage` | the Lark's sail, whole and flying, on the next dune | walk to it (a cost, a small find) / refuse it (a cost to nerve, not health) |
| `raiders` | a scout from the looters' trade, alone, on a ridge | fight / bribe / let him follow (the camp is warned) |

Two extra events would pay off the wreck: `the_crew` (a body the dunes have
uncovered; only if the crew was *not* buried) and `the_tracks` (the sledge
tracks again; only if they were followed, a shortcut with a price).

## Memory: what the wreck changes on the road

Every flag set at `1100` should be read once on the road, so nothing is wasted:

| Flag (from `1100`) | On the road |
|---|---|
| `crew_buried` | a line at the Face: the party has someone to leave a coin for |
| `tracks_followed` | the `the_tracks` event is offered; the looters' camp is no surprise |
| `tear_touched` / `tear_refused` | `mirage` reads differently: the tear's thread hums, or does not |
| `void_marked` | the Face's carving is warm to the touch; read again by Vess at the Wells (`1210`, as today) |

New flags are added only if a later scene reads them (the story rules).

## Moods and places

The crossing uses the moods added in v1.273: `desperate` for the heat,
`uncanny` for the Face and the tear, `wry` for the narrator's dry asides,
`tense` for the looters, `wondrous` for the first sight of the Wells' lights.
The place tag (`place_*`) is the existing desert one; no new theme is needed.

## Tutorial line at the wreck

A one-sentence tutorial topic introduces the expedition screen as the party
leaves `1100`, in the narrator's voice, not the rule-book's:

> "Nothing here had a road, only the lack of one. From now on the Journey would
> show it as it was: a day at a time, and my own strength for a water-skin."

(The French twin will follow the same rule: no "tu", a plain «vous».) The
step on the screen itself is UX's.

## Writing rules to keep

- First person, past tense, the narrator of the other scenes; dry, not jokey.
- Choices of 55 characters or fewer; every flag set is read somewhere.
- Both languages for every string, French typography (NBSP, curly
  apostrophes) as the lint expects.
- No name or place beyond the geography already on the chart: the crash,
  the Sleeper's Face, the White Wells, the Lark.

## What this needs from other sessions

- **Core:** `land_routes.json` / `land_events.json` and the engine
  (land-expeditions.md). Narrative needs the event ids it should write for, and
  the field names for an event's text (`passage`, `choices[].text`, French
  twins) so the files can be written once.
- **UX:** the side view, and the tutorial step at the wreck.
- **QA:** a crossing walked in the simulator; old saves in the middle
  of `1120`–`1140`.

## Questions for the user (when L is approved)

1. Is the Face's riddle-less visit (drink, take, leave a coin) enough, or should
   the crossing add a short exchange with the veiled looters before the camp?
2. Should the crossing be survivable by any party (the failure edge only costs
   days), as Core proposes, or should a failed crossing leave a mark (`heatstruck`)
   that the Wells remember?
3. The two extra events (`the_crew`, `the_tracks`): worth the extra writing?

*Size of the work when approved:* about 5 event types × 2–3 variants × (a
passage and 2–3 choices) in two languages, the 1100 exit choice and its tutorial
line, and the flag reads above.
