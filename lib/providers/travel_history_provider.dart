import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_state.dart' show harborHouseId;
import '../data/heard_of.dart';
import '../data/map_charts.dart';
import '../data/travel_history.dart';
import '../gamedata/db_schema.dart';
import 'chapter_loop_provider.dart'
    show knownPlacesProvider, reachedChapterProvider;
import 'game_db_providers.dart';
import 'player_session_provider.dart';
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

/// What the full map's sheet offers for each place only heard of (see
/// heard_of.dart): "Set out" there or by the expedition that finds it, or
/// "Mark as goal" with the reason.
final heardOfPlacesProvider = Provider<Map<String, HeardOfPlace>>((ref) {
  final story = ref.watch(storyDataProvider).value;
  if (story == null) return const {};
  final session = ref.watch(playerSessionProvider);
  return heardOfPlacesOf(
    history: ref.watch(travelHistoryProvider),
    story: story,
    chapter: ref.watch(reachedChapterProvider),
    flags: session.flags,
    harbourBuilt: session.builtHouseIds.contains(harborHouseId),
    zones: ref.watch(gameDbProvider(zonesSchema)).value ?? const {},
    ports: ref.watch(gameDbProvider(portsSchema)).value ?? const {},
    completedZoneIds: session.completedZoneIds,
  );
});

/// The landmark marked as the map's goal, until it is reached (see
/// mapGoalIn); null when there is none.
final mapGoalProvider = Provider<String?>((ref) => mapGoalIn(
    ref.watch(playerSessionProvider.select((s) => s.flags)),
    ref.watch(travelHistoryProvider).visited));
