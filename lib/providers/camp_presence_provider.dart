import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_state.dart';
import '../data/settlements.dart';
import '../gamedata/db_schema.dart';
import 'chapter_loop_provider.dart';
import 'game_db_providers.dart';
import 'player_session_provider.dart';
import 'story_providers.dart';

/// Whether the party is at the camp: the story at a camp's scene (not a
/// detour from it). While it is, the Story tab gives way to the camp.
final partyAtCampProvider = Provider<bool>((ref) {
  final play = ref.watch(storyPlayProvider);
  final story = ref.watch(storyDataProvider).value;
  return partyAtCamp(story?.nodeFor(play.currentNodeId),
      inExcursion: play.isInExcursion);
});

/// Where the party stands relative to its camp (see [CampPresence]).
final campPresenceProvider = Provider<CampPresence>((ref) {
  final chapter = ref.watch(reachedChapterProvider);
  final ports = ref.watch(gameDbProvider(portsSchema)).value ?? const {};
  final savedPortId =
      ref.watch(playerSessionProvider.select((s) => s.currentPortId));
  return campPresenceFor(
    chapter: chapter,
    atCampScene: ref.watch(partyAtCampProvider),
    ports: ports,
    savedPortId: savedPortId,
    campFounded: ref.watch(
        playerSessionProvider.select((s) => s.flags.contains(campFoundedFlag))),
  );
});
