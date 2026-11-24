/// Places only heard of (docs/proposals/heard-of-places.md): what the full
/// map's sheet offers for a landmark the party has heard of but not
/// reached. "Set out" when it can be gone to now, straight there or by the
/// expedition that finds it; else "Mark as goal", with the reason.
library;

import '../models/story_node.dart';
import 'chapter_loop.dart' show loopPlaces, zoneDiscoveries;
import 'port_helpers.dart' show homePortId, portZoneIds;
import 'settlements.dart' show campFoundedFlag;
import 'story_repository.dart' show StoryData;
import 'travel_history.dart';
import 'world_map.dart' show landmarkOfScene;
import 'world_roads.dart';
import 'zone_gating.dart' show meetsRequiredFlags, requiredFlagsOf;

/// What the sheet offers for a place heard of.
enum HeardOfAction { setOut, markGoal }

/// Why a place heard of can't be set out for yet.
enum HeardOfReason {
  /// No place scene to arrive at: the story takes the party there.
  storyOnly,

  /// Its chapter (or its expedition's) is after the one reached.
  laterChapter,

  /// Only the sea leads there (or to its expedition), and the harbour is
  /// not built.
  needsHarbour,

  /// Before the camp: the story leads, there is no free travel.
  noCamp,

  /// Not found yet, and the expedition that finds it is not open: it waits
  /// on another expedition ([HeardOfPlace.waitsOnFlags]).
  needsExpedition,
}

/// A landmark heard of, and what the sheet offers for it.
class HeardOfPlace {
  const HeardOfPlace({
    required this.landmarkId,
    required this.action,
    this.reason,
    this.placeNodeId,
    this.chapter,
    this.roadIds = const [],
    this.bySea = false,
    this.expeditionId,
    this.expeditionPortId,
    this.waitsOnFlags = const [],
  });

  final String landmarkId;
  final HeardOfAction action;

  /// Why it is [HeardOfAction.markGoal]; null for [HeardOfAction.setOut].
  final HeardOfReason? reason;

  /// Its settlement node (for travelToPlace), if it has one.
  final String? placeNodeId;

  /// The chapter it (or, not yet found, its expedition) comes in.
  final int? chapter;

  /// The roads to it from visited landmarks.
  final List<String> roadIds;

  /// Every one of [roadIds] is a sea road.
  final bool bySea;

  /// Not found yet: the expedition (zones.json id) that finds it, which
  /// "Set out" launches instead of travelling there.
  final String? expeditionId;

  /// The port [expeditionId] sets out from (the camp's own shore, or a
  /// port sailed to first).
  final String? expeditionPortId;

  /// With [HeardOfReason.needsExpedition]: the flags its expedition still
  /// waits on (see zone_gating.dart's lockRequirementName for the name).
  final List<String> waitsOnFlags;

  bool get setsOut => action == HeardOfAction.setOut;

  /// "Set out" launches the expedition that finds it, not a trip there.
  bool get byExpedition => setsOut && expeditionId != null;
}

/// The flag "Mark as goal" sets: one goal at a time (see [mapGoalIn]).
const String mapGoalPrefix = 'map_goal:';

String mapGoalFlag(String landmarkId) => '$mapGoalPrefix$landmarkId';

/// The goal marked on the map among [flags], unless [visited] already
/// holds it (reaching it ends it).
String? mapGoalIn(Iterable<String> flags, Set<String> visited) {
  for (final flag in flags) {
    if (!flag.startsWith(mapGoalPrefix)) continue;
    final id = flag.substring(mapGoalPrefix.length);
    return visited.contains(id) ? null : id;
  }
  return null;
}

/// [flags] with [landmarkId] as the one map goal (null: none).
List<String> withMapGoal(Iterable<String> flags, String? landmarkId) => [
      for (final flag in flags)
        if (!flag.startsWith(mapGoalPrefix)) flag,
      if (landmarkId != null) mapGoalFlag(landmarkId),
    ];

/// What the sheet offers for each of [history]'s places heard of, in
/// [chapter] with [flags] held: see docs/proposals/heard-of-places.md.
/// [zones] and [ports] are zones.json and ports.json; [harbourBuilt] says
/// the Eel can sail from the camp (harbour.dart).
Map<String, HeardOfPlace> heardOfPlacesOf({
  required TravelHistory history,
  required StoryData story,
  required int chapter,
  required Iterable<String> flags,
  required bool harbourBuilt,
  required Map<String, dynamic> zones,
  required Map<String, dynamic> ports,
  Iterable<String> completedZoneIds = const [],
}) {
  final held = flags.toSet();
  final campFounded = held.contains(campFoundedFlag);
  final completed = completedZoneIds.toSet();
  final home = homePortId(ports);

  final placeOf = <String, StoryNode>{};
  for (final place in loopPlaces(story)) {
    final landmark = landmarkOfScene(place.id) ??
        landmarkOfScene(place.settlement?.arrivalNodeId ?? '');
    if (landmark != null) placeOf.putIfAbsent(landmark.id, () => place);
  }

  String? portOf(String zoneId) {
    for (final MapEntry(:key, :value) in ports.entries) {
      if (value is Map<String, dynamic> &&
          portZoneIds(value).contains(zoneId)) {
        return key;
      }
    }
    return null;
  }

  final result = <String, HeardOfPlace>{};
  for (final id in history.heardOf.toList()..sort()) {
    final roads = [
      for (final road in roadsAt(id))
        if (history.visited.contains(road.other(id))) road,
    ];
    final bySea =
        roads.isNotEmpty && roads.every((r) => r.kind == RoadKind.sea);
    final place = placeOf[id];
    HeardOfPlace goal(HeardOfReason reason,
            {int? inChapter,
            String? expeditionId,
            String? portId,
            List<String> waits = const []}) =>
        HeardOfPlace(
          landmarkId: id,
          action: HeardOfAction.markGoal,
          reason: reason,
          placeNodeId: place?.id,
          chapter: inChapter ?? place?.settlement?.chapter,
          roadIds: [for (final r in roads) r.id],
          bySea: bySea,
          expeditionId: expeditionId,
          expeditionPortId: portId,
          waitsOnFlags: waits,
        );

    if (place == null) {
      result[id] = goal(HeardOfReason.storyOnly);
      continue;
    }
    if (!campFounded) {
      result[id] = goal(HeardOfReason.noCamp);
      continue;
    }
    final placeChapter = place.settlement!.chapter!;
    if (placeChapter > chapter) {
      result[id] = goal(HeardOfReason.laterChapter);
      continue;
    }
    final found = !place.settlement!.mustDiscover ||
        held.contains(placeFoundFlag(place.id));
    if (found) {
      result[id] = bySea && !harbourBuilt
          ? goal(HeardOfReason.needsHarbour)
          : HeardOfPlace(
              landmarkId: id,
              action: HeardOfAction.setOut,
              placeNodeId: place.id,
              chapter: placeChapter,
              roadIds: [for (final r in roads) r.id],
              bySea: bySea,
            );
      continue;
    }

    // Not found: the expedition that finds it (one not yet cleared first).
    final finders = [
      for (final MapEntry(:key, :value) in zones.entries)
        if (value is Map<String, dynamic> &&
            zoneDiscoveries(value).contains(place.id))
          key,
    ]..sort((a, b) {
        final byDone =
            (completed.contains(a) ? 1 : 0) - (completed.contains(b) ? 1 : 0);
        return byDone != 0 ? byDone : a.compareTo(b);
      });
    if (finders.isEmpty) {
      result[id] = goal(HeardOfReason.storyOnly);
      continue;
    }
    final zoneId = finders.first;
    final zone = zones[zoneId] as Map<String, dynamic>;
    final zoneChapter = (zone['chapter'] as num?)?.toInt() ?? 1;
    final portId = portOf(zoneId);
    if (zoneChapter > chapter) {
      result[id] = goal(HeardOfReason.laterChapter,
          inChapter: zoneChapter, expeditionId: zoneId, portId: portId);
      continue;
    }
    if (portId != null && portId != home && !harbourBuilt) {
      result[id] = goal(HeardOfReason.needsHarbour,
          expeditionId: zoneId, portId: portId);
      continue;
    }
    if (!meetsRequiredFlags(zone, held)) {
      result[id] = goal(HeardOfReason.needsExpedition,
          expeditionId: zoneId,
          portId: portId,
          waits: [
            for (final flag in requiredFlagsOf(zone))
              if (!held.contains(flag)) flag,
          ]);
      continue;
    }
    result[id] = HeardOfPlace(
      landmarkId: id,
      action: HeardOfAction.setOut,
      placeNodeId: place.id,
      chapter: placeChapter,
      roadIds: [for (final r in roads) r.id],
      bySea: bySea,
      expeditionId: zoneId,
      expeditionPortId: portId,
    );
  }
  return result;
}
