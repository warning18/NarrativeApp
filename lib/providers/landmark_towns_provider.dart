// The ruling clan of each world-chart landmark that is a town (wave 15):
// townRulersProvider says who rules each town by its geography id; the
// world chart draws landmarks, each standing for the places of its scenes.
// A landmark is the town most of its scenes happen in, when that is a town
// someone rules.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/town_rulers.dart';
import '../data/world_map.dart';
import 'geography_provider.dart';
import 'story_providers.dart';
import 'town_rulers_provider.dart';

/// The ruler of the town each landmark stands in, by landmark id; a landmark
/// that is no town, or a town no clan rules, has none.
final landmarkRulersProvider = Provider<Map<String, TownRuler>>((ref) {
  final story = ref.watch(storyDataProvider).value;
  final rulers = ref.watch(townRulersProvider);
  if (story == null || rulers.isEmpty) return const {};
  final geography = ref.watch(geographyProvider);
  final out = <String, TownRuler>{};
  for (final landmark in worldMapLandmarks) {
    final votes = <String, int>{};
    for (final scene in landmark.scenes) {
      final town = geography.locationOfNode(story.nodeFor(scene))?.id;
      if (town != null && rulers.containsKey(town)) {
        votes[town] = (votes[town] ?? 0) + 1;
      }
    }
    if (votes.isEmpty) continue;
    final town = (votes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
    final ruler = rulers[town]!;
    if (!ruler.isNeutral) out[landmark.id] = ruler;
  }
  return out;
});
