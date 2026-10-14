import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_charts.dart';
import '../data/travel_history.dart';
import 'chapter_loop_provider.dart' show knownPlacesProvider;
import 'story_providers.dart';

/// The party's travels so far, for the travel-history map (see
/// travel_history.dart): the places reached in order, the roads taken,
/// the places only heard of, and where a tap can travel to from camp.
/// Read from the story's own record; no save field of its own.
final travelHistoryProvider = Provider<TravelHistory>((ref) {
  final play = ref.watch(storyPlayProvider);
  return travelHistoryOf(
    history: play.history,
    currentNodeId: play.currentNodeId,
    visitedNodeIds: play.visitedNodeIds,
    knownPlaces: ref.watch(knownPlacesProvider),
  );
});

/// The chart the travel-history map is drawn on: the story world
/// ([MapShape.story]), whatever look the world map is set to.
final storyChartProvider =
    Provider<ChartGeography>((ref) => chartOf(MapShape.story));
