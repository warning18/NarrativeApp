// The feature ladder for the UI (feature_unlocks.dart): what is open, and
// what has just opened and waits for its card (UX's unlock moment,
// docs/proposals/unlock-moment-ux.md). Ids are GameFeature's.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feature_unlocks.dart';
import 'player_session_provider.dart';

/// The ids of the features open now.
final _unlockedFeaturesProvider = Provider<Set<String>>((ref) {
  final ladder = ref.watch(playerSessionProvider.select((s) => s.ladder));
  return {for (final f in unlockedFeatures(ladder)) f.id};
});

/// The ids of the features opened and not yet told of, in the ladder's
/// order: one card at a time, then the session's acknowledgeFeature.
final newlyUnlockedProvider = Provider<List<String>>((ref) {
  final session = ref.watch(playerSessionProvider);
  return [
    for (final f
        in newlyUnlockedFeatures(session.ladder, session.acknowledgedFeatures))
      f.id,
  ];
});

/// Whether the feature [id] is open (an unknown id is).
bool isFeatureUnlocked(WidgetRef ref, String id) =>
    gameFeatureNamed(id) == null ||
    ref.watch(_unlockedFeaturesProvider).contains(id);
