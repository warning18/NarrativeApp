// The travel-history map's data (travel_history.dart): the places reached in
// order, the roads taken, what is only heard of, and the story chart it is
// drawn on, from the story's record alone.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/travel_history_provider.dart';

void main() {
  // The wreck of the Lark, the Sleeper's Face, the White Wells.
  const history = ['965', '1100', '1120', '1130', '1200'];

  test('the places reached, once each, in the order first reached', () {
    final travels =
        travelHistoryOf(history: [...history, '1100'], currentNodeId: '1210');
    expect([for (final s in travels.stops) s.landmarkId],
        ['crash', 'sleeper', 'wells']);
    expect(travels.stops.first.firstNodeId, '965');
    expect(travels.currentId, 'wells');
  });

  test('every move is a leg on its road, a road walked twice two legs', () {
    final travels =
        travelHistoryOf(history: [...history, '1120'], currentNodeId: '1200');
    expect([for (final l in travels.legs) '${l.fromId}>${l.toId}'],
        ['crash>sleeper', 'sleeper>wells', 'wells>sleeper', 'sleeper>wells']);
    expect(travels.legs.first.roadIds, ['crash_sleeper']);
    expect(travels.legs.first.kind, RoadKind.land);
  });

  test('a jump over places goes by the shortest way along the roads', () {
    final travels = travelHistoryOf(history: ['965'], currentNodeId: '1200');
    expect(travels.legs.single.roadIds, ['crash_sleeper', 'sleeper_wells']);
  });

  test('the far ends of known roads are heard of, the rest unseen', () {
    final travels = travelHistoryOf(history: history, currentNodeId: '1200');
    expect(travels.visited, {'crash', 'sleeper', 'wells'});
    // Alster behind the wreck, the upper town past the wells.
    expect(travels.heardOf, containsAll(['alster', 'upper']));
    expect(travels.heardOf.intersection(travels.visited), isEmpty);
    expect(travels.shows('camp'), isFalse);
  });

  test('a scene read but gone from history still counts as visited', () {
    final travels = travelHistoryOf(
        history: const [], currentNodeId: '1200', visitedNodeIds: ['965']);
    expect(travels.visited, containsAll(['crash', 'wells']));
  });

  test('every landmark has a spot on the story chart, which the looks skip',
      () {
    final chart = chartOf(MapShape.story);
    for (final landmark in worldMapLandmarks) {
      expect(chart.places[landmark.id], isNotNull, reason: landmark.id);
    }
    expect(chart.features, isNotEmpty);
    expect(mapLookShapes, isNot(contains(MapShape.story)));
  });

  test('the provider follows the story as it moves', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(overrides: [
      storyPlayProvider.overrideWith((ref) => StoryPlayNotifier('965')),
    ]);
    addTearDown(container.dispose);
    expect(container.read(travelHistoryProvider).currentId, 'crash');
    container.read(storyPlayProvider.notifier)
      ..choose('1120')
      ..choose('1200');
    final travels = container.read(travelHistoryProvider);
    expect([for (final s in travels.stops) s.landmarkId],
        ['crash', 'sleeper', 'wells']);
    expect(travels.currentId, 'wells');
    expect(container.read(storyChartProvider).places, contains('wells'));
  });
}
