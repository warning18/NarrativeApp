# Proposal: places only heard of (H)

Core, for the manager and UX (board 8, the full map's sheet). Prep only;
it becomes a PR after the weekly reset.

## Today

- `travelHistoryProvider.heardOf` lists every landmark at the far end of a
  `worldRoads` road from a visited one. The map draws it as "?".
- The sheet can only travel to `travelTargets`: visited places that the
  camp lists (`knownPlacesProvider`).
- Of the 34 landmarks, **19 have no place scene**: no settlement node, so
  `travelToPlace` has nowhere to go. They are the story's own spots: the
  Blind Beggar to the White Wells (chapter 1), the Spire, the Court, the
  Dead Heart, the wreck, the last battle.
- The other 15 are towns, villages, a site and the camp. From chapter 3 on,
  most of them are `mustDiscover`: only an expedition's find
  (`placeFoundFlag`) opens them today.

## The rule

A heard-of landmark offers **Set out** when all of these hold:

1. **It has a place scene:** a settlement node, not the camp, with a
   `chapter` (the `loopPlaces` set).
2. **Its chapter is open:** that chapter is at or below
   `reachedChapterProvider`.
3. **A road leads there now:** one of its roads starts at a visited
   landmark, and is a land road, or a sea road with the harbour built
   (`harbourAwaited` false, v1.283).
4. **The camp stands** (`camp_founded`). Before it, chapters 1–2, the story
   leads and there is no free travel.
5. **The party is free:** not in a fight and not on an expedition (the same
   check as "Travel here").

Otherwise it offers **Mark as goal**, with the first reason that applies:

| reason | when | what the sheet can say |
|---|---|---|
| `storyOnly` | no place scene (the 19, plus the two places without a `chapter`: Smugglers' Wharf and Candlehold) | "The story will take you there." |
| `laterChapter` | its chapter is after the reached one | "Not yet: chapter N." |
| `needsHarbour` | only sea roads lead there, and the harbour is not built | "The Eel must sail: build the harbour." |
| `noCamp` | before the camp | "Not while the story leads." |

The table is by data, not by hand. A place that gains a scene, or a road
that opens, changes the answer on its own.

## What "Set out" does

It is the camp's own `travelToPlace(place)`, with one step first: **a
must-discover place is found by walking to it.** `placeFoundFlag(place.id)`
is set before the trip, so the place joins `knownPlaces` and the camp's
list from then on. The trip itself is today's:
- a walk (`walkRoadStep`, a road event or encounter on the way) or a
  voyage (`sailParty`, behind the harbour lock);
- then the place's arrival scene the first time (`arrivalNodeFor`), the
  place itself after.

The warning on the button is the only new text: "You have only heard of
it: the road may hold anything." It is UX's line to place and Narrative's
to word.

Effect on balance: a party can now find a chapter's villages without that
chapter's expeditions. The expeditions still pay their XP, materials and
loot, and the chapter's main quest still needs its places visited
(`missingMainQuestPlaces`), so walking there counts as visiting. If the
user would rather keep the expeditions as the only way to find a place,
rule 1 can add "and found" for must-discover places. Those places then
show **Mark as goal** with a fifth reason, `notFound` ("An expedition may
find the way.").

## What "Mark as goal" does

- **One goal at a time.** It is stored as a flag, `map_goal:<landmarkId>`,
  so there is no new save field. Setting a new goal removes the old flag,
  and so does reaching the landmark.
- The Journey and the camp can show it ("Goal: the Spire"). That part is
  UX's.

## For UX: the data and providers

```dart
enum HeardOfAction { setOut, markGoal }
enum HeardOfReason { storyOnly, laterChapter, needsHarbour, noCamp }

class HeardOfPlace {
  final String landmarkId;
  final HeardOfAction action;
  final HeardOfReason? reason;   // null when action == setOut
  final String? placeNodeId;     // the settlement node, for travelToPlace
  final int? chapter;            // the place's chapter (laterChapter's N)
  final List<String> roadIds;    // the roads to it from visited landmarks
  final bool bySea;              // every one of those roads is a sea road
}

// lib/providers/travel_history_provider.dart
final heardOfPlacesProvider = Provider<Map<String, HeardOfPlace>>(...);
final mapGoalProvider = Provider<String?>(...);   // landmark id or null

// lib/widgets/camp_travel.dart (Core)
Future<void> setOutToHeardOf(BuildContext, WidgetRef, HeardOfPlace place);
// PlayerSessionNotifier
Future<void> setMapGoal(String? landmarkId);      // null clears it
```

The pure part, `heardOfPlacesOf(history, story, chapter, flags,
harbourBuilt, campFounded)`, sits in `travel_history.dart` beside
`travelHistoryOf` and is tested on the real data. The tests cover:
- the 19 story-only landmarks;
- a chapter-4 village heard of in chapter 3;
- a sea-only place before and after the harbour;
- the goal flag replaced, and cleared on arrival.

## Work, by session

- **Core:** the rule and provider above, `setOutToHeardOf`, the goal flag
  and the tests.
- **UX:** the sheet's two buttons, the warning's place and the goal's mark
  on the map.
- **Narrative:** the warning and the four reasons' lines, English and
  French.
- **QA:** L1.
