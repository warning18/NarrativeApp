import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_state.dart';
import '../data/chapter_grid_layout.dart';
import '../gamedata/db_schema.dart';
import 'game_db_providers.dart';
import 'player_session_provider.dart';
import 'story_providers.dart';

/// Whether the story stands at the camp (a camp's scene, not a detour
/// from it). While it does, the Story tab gives way to the camp.
final storyAtCampProvider = Provider<bool>((ref) {
  final play = ref.watch(storyPlayProvider);
  final story = ref.watch(storyDataProvider).value;
  return storyAtCamp(story?.nodeFor(play.currentNodeId),
      inExcursion: play.isInExcursion);
});

/// Where the party stands relative to its camp (see [CampPresence]).
final campPresenceProvider = Provider<CampPresence>((ref) {
  final chapter = chapterOfNode(
      ref.watch(storyPlayProvider.select((s) => s.currentNodeId)));
  final ports = ref.watch(gameDbProvider(portsSchema)).value ?? const {};
  final savedPortId =
      ref.watch(playerSessionProvider.select((s) => s.currentPortId));
  return campPresenceFor(
    chapter: chapter,
    atCampScene: ref.watch(storyAtCampProvider),
    ports: ports,
    savedPortId: savedPortId,
  );
});
