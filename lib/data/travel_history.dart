import '../models/story_node.dart';
import 'world_map.dart';
import 'world_roads.dart';

/// The travel-history map's data (v1.27x): where the party has been, in
/// order, the roads it took, and what it has only heard of, read from the
/// story's own record (the scenes left, in order, see `StoryPlayState`)
/// with no save field of its own. Drawn on the story world's chart
/// (`MapShape.story`) beside the Journey; a known place is also a way to
/// travel from camp (see [TravelHistory.travelTargets]).

/// A place the party has reached, as it first reached it.
class TravelStop {
  const TravelStop({
    required this.landmarkId,
    required this.chapter,
    required this.firstNodeId,
  });

  /// A [worldMapLandmarks] id.
  final String landmarkId;

  /// The landmark's chapter (see [Landmark.chapter]).
  final int chapter;

  /// The first scene read there.
  final String firstNodeId;
}

/// One move between two places, in the order taken.
class TravelLeg {
  const TravelLeg({
    required this.fromId,
    required this.toId,
    required this.roadIds,
    required this.kind,
    required this.chapter,
  });

  final String fromId;
  final String toId;

  /// The [worldRoads] the move went by: the road joining the two places,
  /// or, for a move between places no single road joins (the story moved
  /// on by more than one stretch at once), the shortest way along the
  /// roads ([roadRoute]); empty when no road leads there.
  final List<String> roadIds;

  /// By sea when any of its roads is a sea road.
  final RoadKind kind;

  /// The chapter of the place arrived at.
  final int chapter;
}

/// The party's travels so far (see [travelHistoryOf]).
class TravelHistory {
  const TravelHistory({
    required this.stops,
    required this.legs,
    required this.visited,
    required this.heardOf,
    required this.currentId,
    required this.travelTargets,
  });

  static const empty = TravelHistory(
    stops: [],
    legs: [],
    visited: {},
    heardOf: {},
    currentId: null,
    travelTargets: {},
  );

  /// The places reached, each once, in the order first reached.
  final List<TravelStop> stops;

  /// Every move between two places, in order (a road walked twice is two
  /// legs).
  final List<TravelLeg> legs;

  /// The landmarks with a scene read.
  final Set<String> visited;

  /// Places not reached but at the far end of a road from one that was:
  /// drawn as "?" until reached. Every other place stays off the map.
  final Set<String> heardOf;

  /// Where the story stands now.
  final String? currentId;

  /// The reached places the party can travel to now, landmark id to the
  /// place's own scene (a settlement node, see `knownPlaces`): the map's
  /// tap goes there with `travelToPlace`, the camp's own way to travel.
  final Map<String, String> travelTargets;

  /// Whether [landmarkId] is drawn on the map at all.
  bool shows(String landmarkId) =>
      visited.contains(landmarkId) || heardOf.contains(landmarkId);
}

/// The party's travels from the story's record: [history], the scenes
/// left in order, and [currentNodeId]; [visitedNodeIds], every scene read
/// (an old save or a manual slot may hold places its history no longer
/// does); [knownPlaces], the places the camp can travel to now (see
/// `knownPlaces` in chapter_loop.dart).
TravelHistory travelHistoryOf({
  required List<String> history,
  required String currentNodeId,
  Iterable<String> visitedNodeIds = const [],
  Iterable<StoryNode> knownPlaces = const [],
}) {
  final journey = journeyOf(history, currentNodeId);
  final stops = <TravelStop>[];
  final reached = <String>{};
  for (final nodeId in [...history, currentNodeId]) {
    final landmark = landmarkOfScene(nodeId);
    if (landmark == null || !reached.add(landmark.id)) continue;
    stops.add(TravelStop(
      landmarkId: landmark.id,
      chapter: landmark.chapter,
      firstNodeId: nodeId,
    ));
  }

  final legs = <TravelLeg>[
    for (var i = 0; i + 1 < journey.length; i++)
      _legBetween(journey[i], journey[i + 1]),
  ];

  final visited = {
    ...reached,
    ...discoveredLandmarkIds([...visitedNodeIds, currentNodeId]),
  };
  final heardOf = <String>{
    for (final id in visited)
      for (final road in roadsAt(id))
        if (!visited.contains(road.other(id))) road.other(id),
  };

  final targets = <String, String>{};
  for (final place in knownPlaces) {
    final landmark = landmarkOfScene(place.id) ??
        landmarkOfScene(place.settlement?.arrivalNodeId ?? '');
    if (landmark == null || !visited.contains(landmark.id)) continue;
    targets.putIfAbsent(landmark.id, () => place.id);
  }

  return TravelHistory(
    stops: stops,
    legs: legs,
    visited: visited,
    heardOf: heardOf,
    currentId: currentLandmark(currentNodeId, history)?.id,
    travelTargets: targets,
  );
}

TravelLeg _legBetween(Landmark from, Landmark to) {
  final direct = roadBetween(from.id, to.id);
  final roads = direct != null
      ? [direct]
      : [
          for (final leg in roadRoute(from.id, to.id)?.legs ?? const [])
            leg.road,
        ];
  return TravelLeg(
    fromId: from.id,
    toId: to.id,
    roadIds: [for (final r in roads) r.id],
    kind:
        roads.any((r) => r.kind == RoadKind.sea) ? RoadKind.sea : RoadKind.land,
    chapter: to.chapter,
  );
}
