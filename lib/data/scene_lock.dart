// The scene lock (v1.553, then narrowed): a scene the story brought the
// party to holds the Journey on its page until a way is taken, but only
// when none of its ways has a place on the map. A way the map draws (a pin
// on the place chart, a way on the city chart, a spot in a room's plan, a
// road or a World move) stays on the map and is taken from it; a scene
// with one such way never locks. Only a scene whose every takeable way is
// acted out on the spot, drawn by no map view, shows its ways as cards
// with the map, its tabs and "Back to the map" waiting ("Choose first").
// A card goes on to the next scene, which locks in turn if it is lockable.
//
// The decision is state-based: it reads the scene's ways and the play
// state, not how the party got there, so a save picked back up on such a
// scene opens on its page too. Where the story brought the party (a pin, a
// card, a new game's first scene, a save loaded) is the Journey's to say;
// a jump (Edit Mode, a test) never locks.
import '../models/story_node.dart';
import 'geography.dart';
import 'quest_hints.dart' show hubChoiceCount;
import 'world_map.dart' show currentLandmark;

/// One way out of a scene, as the lock weighs it: whether it is acted out
/// where the party stands ([here], see choice_shape.dart), whether it can
/// be taken now ([takeable]: not shut by its conditions; a hidden way is
/// left out of the list), and whether a map view draws it ([mapped]: a pin,
/// a way on the city chart, a spot in a room, a road or a World move).
typedef LockWay = ({bool here, bool takeable, bool mapped});

/// Whether a scene with [ways] holds the party on its page: something can
/// be taken, and every way that can is acted out here with no place on the
/// map. A scene with a takeable way on the map never locks (that way is
/// taken from the map; its on-the-spot choices stay cards under the scene).
/// Never a hub ([hub], see [isHubScene]), an ending ([ending]), a
/// scene with nothing takeable, or in Edit Mode.
bool sceneLocked({
  required List<LockWay> ways,
  required bool hub,
  required bool ending,
  required bool editMode,
}) {
  if (editMode || hub || ending) return false;
  final open = ways.where((w) => w.takeable);
  return open.isNotEmpty && open.every((w) => w.here && !w.mapped);
}

/// Whether the Journey's map draws every way of [node], whatever its
/// shape: on the road (no landmark where the party stands, every
/// way a pin), inside a building's room (every way a spot in its plan), or
/// in a city, town or village with a stored plan (every way on its city
/// chart). Elsewhere (a place up close with no city chart) a way acted out
/// here is a card that no map view draws.
///
/// The Journey knows its placements once its map is built; this reads the
/// same data (the geography, the stored city plans) for a scene seen
/// before that, a save picked back up. [cityPlans] are the ids of the
/// cities with a stored plan, null while they load: every way counts as on
/// the map then (and while the places load), so nothing locks before the
/// chart is known.
bool mapDrawsEveryWay(
  StoryNode node, {
  required List<String> history,
  required Geography world,
  required Set<String>? cityPlans,
}) {
  if (world.isEmpty) return true;
  final standing = currentLandmark(node.id, history);
  if (standing == null) return true;
  final here = world.placeOfNode(node) ?? world.placeOfLandmark(standing.id);
  if (here != null &&
      here.isBuilding &&
      !here.doorstep.contains(node.id) &&
      !node.sceneInStreet) {
    return true;
  }
  final location = world.locationOf(here?.id);
  if (location == null) return false;
  if (!const {'city', 'town', 'village'}.contains(location.kind)) {
    return false;
  }
  return cityPlans == null || cityPlans.contains(location.id);
}

/// Whether [node] is a hub: a town's or the camp's scene (a settlement), or
/// one with more choices than a decision has (the story view's own rule).
/// Its choices are things to do there, in any order: it never locks.
bool isHubScene(StoryNode node) =>
    node.settlement != null || node.choices.length > hubChoiceCount;

/// One way out of a scene, as the page's way back to the map weighs it:
/// whether the page lists it as a card ([card]), whether it can be taken
/// now ([takeable]), and the place it leads to ([to]: its geography id,
/// null when the world doesn't know it).
typedef ExitWay = ({bool card, bool takeable, String? to});

/// Whether the page of a scene the story brought the party to has nothing
/// to go back to the map for (the user's call, v1.565): its cards hold every
/// move the map would offer. That is: something can be taken as a card, and
/// every takeable way that is not one (a pin on the map) leads to a place a
/// card leads to as well ("Cut it free" and "Leave them both" in the
/// Weaver's Alley both end at the family house). Its "Back to the map" (and
/// the corner map button) go; the pins are listed as road cards under the
/// others, so no way is lost. A pin to a place no card reaches, or one the
/// world doesn't place, keeps the button; so does a hub (its ways are things
/// to do in any order), an ending, Edit Mode. A walk to another district
/// of the town is no way of the scene's and doesn't count. A scene that
/// locks ([sceneLocked]) has no way back already.
bool pageExitHidden({
  required List<ExitWay> ways,
  required bool hub,
  required bool ending,
  required bool editMode,
}) {
  if (editMode || hub || ending) return false;
  final open = [
    for (final w in ways)
      if (w.takeable) w,
  ];
  final reached = {
    for (final w in open)
      if (w.card && w.to != null) w.to,
  };
  if (!open.any((w) => w.card)) return false;
  return open.every((w) => w.card || (w.to != null && reached.contains(w.to)));
}
