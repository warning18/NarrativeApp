import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/choice_flow.dart';
import '../data/scene_presentation.dart';
import '../gamedata/db_schema.dart';
import 'city_provider.dart';
import 'game_db_providers.dart';
import 'geography_provider.dart';
import 'story_providers.dart';

/// The story's stops, hubs and errands (see choice_flow.dart), worked out
/// once per story, geography and city plans; null until the story, the
/// geography and the city plans have loaded (built once, not once without
/// the plans and again with them).
final storyStopsProvider = Provider<StoryStops?>((ref) {
  final story = ref.watch(storyDataProvider).value;
  final geography = ref.watch(geographyProvider);
  final cityPlans = ref.watch(cityPlanRecordsProvider).value;
  if (story == null || geography.isEmpty || cityPlans == null) return null;
  return StoryStops.of(
    story: story,
    geography: geography,
    cityPlans: cityPlans,
    ports: ref.watch(gameDbProvider(portsSchema)).value ?? const {},
  );
});

/// The view each scene opens in (scene_presentation.dart): null until the
/// story's stops are known.
final scenePresentationProvider = Provider<ScenePresentation?>((ref) {
  final stops = ref.watch(storyStopsProvider);
  final story = ref.watch(storyDataProvider).value;
  if (stops == null || story == null) return null;
  return ScenePresentation.of(
      story: story, geography: ref.watch(geographyProvider), stops: stops);
});

/// The last one-tap return to a town hub (see FlowReturnToHub): the hub's
/// scene and stop, and the scene of the errand it came back from. The
/// Journey sets it when it lands at the hub, for UX's "You came back to
/// `<place>`" notice; whoever shows the notice clears it (null).
final lastReturnProvider =
    StateProvider<({String hubNodeId, String hubStop, String fromNodeId})?>(
        (ref) => null);
