// A city's districts at play (board 15): which district a scene stands in,
// which of a scene's ways lead into a given district ("show the party's
// district's ways"), and which districts the party has found (the rest are
// fogged on the city plan). Walking from one district to another is free
// (no story choice, no time, no road): the screen sets the party's district
// (see city_provider.dart), and a district walked into is found for good
// through a flag (see districtFoundFlag).
import 'dart:ui' show Offset;

import '../models/story_node.dart';
import 'city_plan_record.dart';
import 'geography.dart';
import 'story_repository.dart' show StoryData;

/// The flag a quest taken sets (quests.json's Accept choice).
String questAcceptedFlag(String questId) => '${questId}_accepted';

/// Whether district [districtId] is locked (wave 18): it has a `lock` in
/// geography.json whose quest has not reached its stage yet, taken
/// ([geoLockOpensOnAccepted], its `<quest>_accepted` flag among [flags])
/// or done ([geoLockOpensOnDone], among [completedQuestIds]). A locked
/// district shows on the plan with its lock and lockedText, is never
/// found, and the party can't walk into it. No timeout: a quest that can
/// no longer be taken leaves it locked.
bool districtLocked(
  Geography geo,
  String? districtId,
  Iterable<String> flags,
  Iterable<String> completedQuestIds,
) {
  final place = geo.place(districtId);
  if (place == null || !place.hasLock) return false;
  if (completedQuestIds.contains(place.lockQuest)) return false;
  if (place.lockOpensOn == geoLockOpensOnAccepted &&
      flags.contains(questAcceptedFlag(place.lockQuest))) {
    return false;
  }
  return true;
}

/// The locked districts of [cityId] (see [districtLocked]), in
/// geography.json's order.
List<String> lockedDistrictsOf(
  Geography geo,
  String cityId,
  Iterable<String> flags,
  Iterable<String> completedQuestIds,
) =>
    [
      for (final d in districtsOfCity(geo, cityId))
        if (districtLocked(geo, d.id, flags, completedQuestIds)) d.id,
    ];

/// The ways of [node] that lead into a locked district other than the one
/// [node] stands in (see [wayDistricts], [districtLocked]), as indices
/// into [StoryNode.choices], in order: the ways a screen may show greyed.
List<int> lockedWays(
  Geography geo,
  StoryData story,
  StoryNode node,
  Iterable<String> flags,
  Iterable<String> completedQuestIds,
) {
  final own = districtOfNode(geo, node)?.id;
  return [
    for (final MapEntry(:key, :value) in wayDistricts(geo, story, node).entries)
      if (value != null &&
          value != own &&
          districtLocked(geo, value, flags, completedQuestIds))
        key,
  ]..sort();
}

/// The flag a district walked into is remembered by (found, unfogged).
String districtFoundFlag(String districtId) => 'district_found:$districtId';

/// The district (geography.json's level 'district') [placeId] stands in,
/// or null (a location with no districts, a place not on file).
GeoPlace? districtOfPlace(Geography geo, String? placeId) =>
    geo.ancestorAt(placeId, GeoLevel.district);

/// The district scene [node] happens in, or null.
GeoPlace? districtOfNode(Geography geo, StoryNode? node) =>
    districtOfPlace(geo, geo.placeOfNode(node)?.id);

/// Where a scene played at a building's doorstep (v1.542, see
/// GeoPlace.doorstep) stands on its town's stored plan: the building on
/// the plan, the party's spot at its door, and a spot in the street round
/// it for each of the scene's ways that stay there.
class SceneDoorstep {
  const SceneDoorstep({
    required this.buildingId,
    required this.districtId,
    required this.at,
    required this.spotOfWay,
  });

  /// The building on the plan (city_plans.json's id): the scene's own
  /// anchor when it has one in the district, else one picked for it.
  final String buildingId;
  final String districtId;

  /// The party's spot: the street before the building's door.
  final Offset at;

  /// By way index, where the pin of a way that stays at the door stands.
  final Map<int, Offset> spotOfWay;
}

/// [node]'s doorstep on [record] (see [SceneDoorstep]), or null when the
/// scene is not played at a building's doorstep, or the building's district
/// is not on the plan. [waysHere] are the indices of the scene's ways that
/// stay where the party stands (no other building or district of the town).
SceneDoorstep? sceneDoorstep(
  Geography geo,
  CityPlanRecord record,
  StoryNode? node, {
  Iterable<int> waysHere = const [],
}) {
  final building = geo.doorstepOfNode(node);
  if (building == null) return null;
  final district = districtOfPlace(geo, building.id)?.id;
  if (district == null || !record.districts.containsKey(district)) {
    return null;
  }
  final onPlan = record.buildingOfWay(node!.id, district);
  if (onPlan == null) return null;
  final ways = waysHere.toList();
  final spots = record.streetSpotsAround(onPlan.id, ways.length);
  return SceneDoorstep(
    buildingId: onPlan.id,
    districtId: district,
    at: record.doorstepOf(onPlan.id),
    spotOfWay: {for (final (k, i) in ways.indexed) i: spots[k]},
  );
}

/// The view of a town's plan a move shows (v1.534): the whole town, or the
/// district.
enum JourneyTownView { town, district }

/// What the Journey shows after the party moves from place [fromId] to
/// place [toId] (districts or buildings): a move inside one town with
/// districts is a walk on its plan, on the whole town when it crosses into
/// another district, on the district when it stays in the same one. Null
/// for anything else (a journey between towns, a town with no districts,
/// a first placing): the world's roads, or the view as it was.
JourneyTownView? townMoveView(Geography geo, String? fromId, String? toId) {
  if (fromId == null || toId == null) return null;
  final from = geo.locationOf(fromId), to = geo.locationOf(toId);
  if (from == null || to == null || from.id != to.id) return null;
  final a = districtOfPlace(geo, fromId), b = districtOfPlace(geo, toId);
  if (a == null || b == null) return null;
  return a.id == b.id ? JourneyTownView.district : JourneyTownView.town;
}

/// [cityId]'s districts, in geography.json's order.
List<GeoPlace> districtsOfCity(Geography geo, String cityId) => [
      for (final child in geo.childrenOf(cityId))
        if (child.level == GeoLevel.district) child,
    ];

/// The district each of [node]'s ways leads into, by the way's index in
/// [StoryNode.choices]: the district of the scene it leads to when that
/// lies in [node]'s own city; a way that leaves the city (or leads to a
/// scene the world doesn't place) stands where [node] does.
Map<int, String?> wayDistricts(Geography geo, StoryData story, StoryNode node) {
  final here = geo.locationOfNode(node);
  final own = districtOfNode(geo, node)?.id;
  return {
    for (final (i, choice) in node.choices.indexed)
      i: () {
        final target = story.nodeFor(choice.nextId);
        final city = geo.locationOfNode(target);
        if (here == null || city?.id != here.id) return own;
        return districtOfNode(geo, target)?.id ?? own;
      }(),
  };
}

/// The ways of [node] that lead into [districtId] (see [wayDistricts]),
/// as indices into [StoryNode.choices], in order.
List<int> waysInDistrict(
        Geography geo, StoryData story, StoryNode node, String districtId) =>
    [
      for (final MapEntry(:key, :value)
          in wayDistricts(geo, story, node).entries)
        if (value == districtId) key,
    ]..sort();

/// The districts of [cityId] the party has found: one a scene it played
/// stands in ([visitedNodeIds]), one it walked into ([flags], see
/// [districtFoundFlag]), and the one it stands in now ([currentNodeId]).
/// A locked district (see [districtLocked], with [completedQuestIds]) is
/// never found, whatever says so.
Set<String> foundDistricts(
  Geography geo,
  StoryData story, {
  required String cityId,
  required Iterable<String> visitedNodeIds,
  required String currentNodeId,
  required Iterable<String> flags,
  Iterable<String> completedQuestIds = const [],
}) {
  final held = flags.toSet();
  final done = completedQuestIds.toSet();
  final ids = {
    for (final d in districtsOfCity(geo, cityId))
      if (!districtLocked(geo, d.id, held, done)) d.id,
  };
  return {
    for (final id in [...visitedNodeIds, currentNodeId])
      if (districtOfNode(geo, story.nodeFor(id))?.id case final d?
          when ids.contains(d))
        d,
    for (final d in ids)
      if (held.contains(districtFoundFlag(d))) d,
  };
}
