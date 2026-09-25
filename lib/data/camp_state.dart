import '../models/story_node.dart';
import 'port_helpers.dart';

/// The chapter the camp opens in: before it there is no camp and no boat
/// (see the in-game Camp tab and the Play tab).
const int campChapter = 3;

/// The camp's own house that refits the Rusty Eel: once built, the camp
/// opens the Harbor (hull repairs and the shipwright's parts).
const String harborHouseId = 'harbor';

/// Where the party stands relative to its camp, which decides what the
/// in-game Camp tab shows.
enum CampPresence {
  /// Before chapter 3: there is no camp yet.
  notYet,

  /// The story is at the camp and the Rusty Eel is moored in its cove: the
  /// camp itself, and the story waits until the party leaves it.
  atCamp,

  /// The story is at the camp, but the party has sailed out to another
  /// port for its expeditions: the ship, until it sails back.
  sailedOut,

  /// The story has taken the party away from the camp: the ship is all
  /// the party has of it until the story comes back.
  away,
}

/// Whether the story stands at the camp itself: a camp's scene, not a
/// detour on the road from it.
bool storyAtCamp(StoryNode? node, {required bool inExcursion}) =>
    !inExcursion && (node?.settlement?.isCamp ?? false);

CampPresence campPresenceFor({
  required int chapter,
  required bool atCampScene,
  required Map<String, dynamic> ports,
  required String savedPortId,
}) {
  if (!atCampScene) {
    return chapter < campChapter ? CampPresence.notYet : CampPresence.away;
  }
  final home = homePortId(ports);
  final moored = currentPortIdFor(ports, savedPortId);
  return home == null || moored == null || moored == home
      ? CampPresence.atCamp
      : CampPresence.sailedOut;
}

/// The camp's own expeditions still to clear before the story can leave
/// it: every zone on the camp's shore (the home port's) from the chapters
/// the story has reached. Empty when the party may go.
List<String> campExitBlockers({
  required Map<String, dynamic> ports,
  required Map<String, dynamic> zones,
  required int chapter,
  required Iterable<String> completedZoneIds,
}) {
  final home = homePortId(ports);
  final homePort = home == null ? null : ports[home] as Map<String, dynamic>?;
  if (homePort == null) return const [];
  final done = completedZoneIds.toSet();
  return [
    for (final zoneId in portZoneIds(homePort))
      if (zones[zoneId] is Map<String, dynamic> &&
          (((zones[zoneId] as Map<String, dynamic>)['chapter'] as num?)
                      ?.toInt() ??
                  1) <=
              chapter &&
          !done.contains(zoneId))
        zoneId,
  ];
}

/// Whether a camp house is on offer: a house tied to one ally (their own
/// hall) is shown only once that ally has joined.
bool houseDiscovered(
  Map<String, dynamic> house,
  Iterable<String> recruitedAllyIds,
) {
  final allyId = house['requiredAllyId']?.toString() ?? '';
  return allyId.isEmpty || recruitedAllyIds.contains(allyId);
}
