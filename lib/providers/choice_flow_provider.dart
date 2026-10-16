import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/choice_flow.dart';
import '../gamedata/db_schema.dart';
import 'city_provider.dart';
import 'game_db_providers.dart';
import 'geography_provider.dart';
import 'story_providers.dart';

/// The story's stops, hubs and errands (see choice_flow.dart), worked out
/// once per story, geography and city plans; null until the story and the
/// geography have loaded.
final storyStopsProvider = Provider<StoryStops?>((ref) {
  final story = ref.watch(storyDataProvider).value;
  final geography = ref.watch(geographyProvider);
  if (story == null || geography.isEmpty) return null;
  return StoryStops.of(
    story: story,
    geography: geography,
    cityPlans: ref.watch(cityPlanRecordsProvider).value ?? const {},
    ports: ref.watch(gameDbProvider(portsSchema)).value ?? const {},
  );
});

/// The last one-tap return to a town hub (see FlowReturnToHub): the hub's
/// scene and stop, and the scene of the errand it came back from. The
/// Journey sets it when it lands at the hub, for UX's "You came back to
/// `<place>`" notice; whoever shows the notice clears it (null).
final lastReturnProvider =
    StateProvider<({String hubNodeId, String hubStop, String fromNodeId})?>(
        (ref) => null);
