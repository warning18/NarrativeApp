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

  /// The story is at the camp and the Rusty Eel is moored in its cove: the
  /// camp itself, with its expeditions, its places and its main quest.
  atCamp,

  /// The party is at the camp, but has sailed out to another port for its
  /// expeditions: the ship, until it sails back.
  sailedOut,

  /// The party is where the story has taken it, away from the camp: from a
  /// place it can go back.
  away,
}

/// Whether the story stands at the camp itself: a camp's scene, not a
/// detour on the road from it.
bool storyAtCamp(StoryNode? node, {required bool inExcursion}) =>
    !inExcursion && (node?.settlement?.isCamp ?? false);

/// Whether the party is at the camp: the story at a camp's scene. From
/// chapter 3 the camp is where the story stands between trips; a place is
/// somewhere the party travels to from it, and comes back from.
bool partyAtCamp(StoryNode? node, {required bool inExcursion}) =>
    storyAtCamp(node, inExcursion: inExcursion);

/// Whether the party can go back to the camp from [node]: one of the open
/// chapters' places, once the camp stands.
bool canReturnToCampFrom(
  StoryNode? node, {
  required bool inExcursion,
  required Iterable<String> flags,
}) {
  final settlement = node?.settlement;
  return !inExcursion &&
      settlement != null &&
      !settlement.isCamp &&
      settlement.chapter != null &&
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
  // The story at a camp's scene.
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

/// Whether a camp house is on offer: a house tied to one ally (their own
/// hall) is shown only once that ally has joined.
bool houseDiscovered(
  Map<String, dynamic> house,
  Iterable<String> recruitedAllyIds,
) {
  final allyId = house['requiredAllyId']?.toString() ?? '';
  return allyId.isEmpty || recruitedAllyIds.contains(allyId);
}
