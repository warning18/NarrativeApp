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

## The rule (the user's decision, v1.285 prep)

A heard-of landmark offers **Set out** in two ways:

- **Straight there,** with the camp's own `travelToPlace`, when:
  - it has a place scene: a settlement node, not the camp, with a
    `chapter` (the `loopPlaces` set);
  - that chapter is at or below `reachedChapterProvider`;
  - it is found: not `mustDiscover`, or `found_<id>` is held;
  - a road leads there from a visited landmark that is a land road, or a
    sea road with the harbour built;
  - the camp stands (`camp_founded`).
- **By its expedition,** when the place is a village not found yet. **A
  village not found can only be reached by its expedition.** "Set out"
  launches the expedition that finds it: the zone whose
  `discoversPlaceIds` names it, an uncleared one first. If that zone sets
  out from another port, the Eel sails there first. Once the place is
  found, "Set out" travels straight there.

Otherwise it offers **Mark as goal**, with the first reason that applies:

| reason | when | what the sheet can say |
|---|---|---|
| `storyOnly` | no place scene (19 of the 34 landmarks, plus Smugglers' Wharf and Candlehold), or no expedition finds it | "The story will take you there." |
| `noCamp` | before the camp | "Not while the story leads." |
| `laterChapter` | its chapter, or its expedition's, is after the reached one (`chapter` gives N) | "Not yet: chapter N." |
| `needsHarbour` | only sea roads lead there, or its expedition sets out from another port, and the harbour is not built | "The Eel must sail: build the harbour." |
| `needsExpedition` | not found, and the expedition that finds it is still shut (`waitsOnFlags`: the expedition to clear first, named with `lockRequirementName`) | "First: the Cinder Row." |

On the real data, in chapter 3 with the camp founded:
- the Ashen Quarter is set out for by the Cinder Row;
- Emberwick and Akagiri wait on the Cinder Row being cleared
  (`needsExpedition`);
- the chapter-4 villages are `laterChapter`.

In chapter 4, Kindly Hill's expedition (the Changeling Fen) sets out from
the Drowned Stair, so it is `needsHarbour` until the harbour stands.

## What "Mark as goal" does

- **One goal at a time.** It is stored as a flag, `map_goal:<landmarkId>`,
  with no new save field. A new goal replaces the old flag
  (`PlayerSessionNotifier.setMapGoal`). The goal ends once the landmark is
  reached (`mapGoalProvider` returns null).
- The Journey and the camp can show it ("Goal: the Spire"). That part is
  UX's.

## For UX: the data and providers (prototyped on claude/core)

```dart
// lib/data/heard_of.dart (pure, tested on the real data)
enum HeardOfAction { setOut, markGoal }
enum HeardOfReason { storyOnly, laterChapter, needsHarbour, noCamp, needsExpedition }

class HeardOfPlace {
  final String landmarkId;
  final HeardOfAction action;
  final HeardOfReason? reason;     // null when setting out
  final String? placeNodeId;       // its settlement node
  final int? chapter;              // laterChapter's N
  final List<String> roadIds;      // roads to it from visited landmarks
  final bool bySea;
  final String? expeditionId;      // not found: the zone that finds it
  final String? expeditionPortId;  // where that zone sets out from
  final List<String> waitsOnFlags; // needsExpedition: what it waits on
  bool get setsOut;
  bool get byExpedition;           // Set out launches the expedition
}

// lib/providers/travel_history_provider.dart
final heardOfPlacesProvider = Provider<Map<String, HeardOfPlace>>(...);
final mapGoalProvider = Provider<String?>(...);

// lib/screens/heard_of_travel.dart
Future<void> setOutToHeardOf(BuildContext, WidgetRef, HeardOfPlace place);
// PlayerSessionNotifier
Future<void> setMapGoal(String? landmarkId);   // null clears it
```

The button can read "Set out" or "Set out on the Cinder Row" when
`byExpedition` (the zone's `zoneName`). The warning ("You have only heard
of it: the road may hold anything") applies to the straight trip only.

## Work, by session

- **Core:** the rule and provider above, `setOutToHeardOf`, the goal flag
  and the tests: prototyped on claude/core; the PR follows the reset.
- **UX:** the sheet's two buttons, the warning's place and the goal's mark
  on the map.
- **Narrative:** the warning and the five reasons' lines, English and
  French: done, in `app_strings.dart` as `heard_reason_<reason>` (`{n}` the
  chapter, `{zone}` the expedition's name) and `heard_setout_warning`.
- **QA:** L1.
