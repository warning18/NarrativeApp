// A city's districts at play (board 15): which district a scene stands in,
// which of a scene's ways lead into a given district ("show the party's
// district's ways"), and which districts the party has found (the rest are
// fogged on the city plan). Walking from one district to another is free
// (no story choice, no time, no road): the screen sets the party's district
// (see city_provider.dart), and a district walked into is found for good
// through a flag (see districtFoundFlag).
import '../models/story_node.dart';
import 'geography.dart';
import 'story_repository.dart' show StoryData;

/// The flag a district walked into is remembered by (found, unfogged).
String districtFoundFlag(String districtId) => 'district_found:$districtId';

/// The district (geography.json's level 'district') [placeId] stands in,
/// or null (a location with no districts, a place not on file).
GeoPlace? districtOfPlace(Geography geo, String? placeId) =>
    geo.ancestorAt(placeId, GeoLevel.district);

/// The district scene [node] happens in, or null.
GeoPlace? districtOfNode(Geography geo, StoryNode? node) =>
    districtOfPlace(geo, geo.placeOfNode(node)?.id);

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
Set<String> foundDistricts(
  Geography geo,
  StoryData story, {
  required String cityId,
  required Iterable<String> visitedNodeIds,
  required String currentNodeId,
  required Iterable<String> flags,
}) {
  final ids = {for (final d in districtsOfCity(geo, cityId)) d.id};
  final held = flags.toSet();
  return {
    for (final id in [...visitedNodeIds, currentNodeId])
      if (districtOfNode(geo, story.nodeFor(id))?.id case final d?
          when ids.contains(d))
        d,
    for (final d in ids)
      if (held.contains(districtFoundFlag(d))) d,
  };
}
