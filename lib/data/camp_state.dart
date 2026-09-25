import '../models/story_node.dart';
import 'port_helpers.dart';
import 'settlements.dart';

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

  /// The party is at the camp (its scene in the story, or gone back to it
  /// from a town) and the Rusty Eel is moored in its cove: the camp itself,
  /// and the story waits until the party leaves it.
  atCamp,

  /// The party is at the camp, but has sailed out to another port for its
  /// expeditions: the ship, until it sails back.
  sailedOut,

  /// The party is where the story has taken it, away from the camp: from a
  /// town it can go back.
  away,
}

/// Whether the story stands at the camp itself: a camp's scene, not a
/// detour on the road from it.
bool storyAtCamp(StoryNode? node, {required bool inExcursion}) =>
    !inExcursion && (node?.settlement?.isCamp ?? false);

/// Whether the party is at the camp: the story at a camp's scene, or the
/// party gone back to the camp from the town where the story waits (see
/// PlayerSession.campVisitFromNodeId).
bool partyAtCamp(
  StoryNode? node, {
  required bool inExcursion,
  required String campVisitFromNodeId,
}) =>
    storyAtCamp(node, inExcursion: inExcursion) ||
    (!inExcursion &&
        node != null &&
        campVisitFromNodeId.isNotEmpty &&
        campVisitFromNodeId == node.id);

/// Whether the party can go back to the camp from [node]: a town, once the
/// camp stands. The story waits in the town until the party sets out again.
bool canReturnToCampFrom(
  StoryNode? node, {
  required bool inExcursion,
  required Iterable<String> flags,
}) {
  final settlement = node?.settlement;
  return !inExcursion &&
      settlement != null &&
      !settlement.isCamp &&
      flags.contains(campFoundedFlag);
}

/// The port the Rusty Eel puts in at for [settlement] (a voyage between it
/// and the camp): its landing, else its own port. Null when the place is a
/// walk from the camp: no port at all, or the camp's own shore.
String? landingPortIdFor(Settlement? settlement, Map<String, dynamic> ports) {
  final id = settlement?.landingPortId ?? settlement?.portId;
  if (id == null) return null;
  final port = ports[id];
  if (port is! Map<String, dynamic> || portIsHome(port)) return null;
  return id;
}

CampPresence campPresenceFor({
  required int chapter,
  // The party at the camp: its scene, or a visit from a town.
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
