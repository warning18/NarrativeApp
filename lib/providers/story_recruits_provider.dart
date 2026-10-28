// The story's own companions joining (v1.601, story_companions.dart): Vica
// joins every hero when the story reaches her scene (or the White Wells),
// and a save already past it gets her on its next step. Watched once by the
// home shell; it listens to the story's visited scenes.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/story_companions.dart';
import '../gamedata/db_schema.dart';
import 'game_db_providers.dart';
import 'player_session_provider.dart';
import 'story_providers.dart';

final storyRecruitsProvider = Provider<void>((ref) {
  Map<String, dynamic>? table(DbSchema schema) =>
      ref.watch(gameDbProvider(schema)).value;
  final companions = table(companionsSchema);
  final races = table(racesSchema);
  final professions = table(professionsSchema);
  final dice = table(diceSchema);
  final houses = table(housesSchema);
  if (companions == null ||
      races == null ||
      professions == null ||
      dice == null ||
      houses == null) {
    return;
  }
  var busy = false;
  void check() {
    final notifier = ref.read(playerSessionProvider.notifier);
    if (busy || !notifier.isLoaded) return;
    final session = ref.read(playerSessionProvider);
    final visited = ref.read(storyPlayProvider).visitedNodeIds;
    final due = storyRecruitsDue(companions,
        visited: visited,
        recruited: [for (final a in session.recruitedAllies) a.companionId],
        gone: [...session.lostAllyIds, ...session.departedAllyIds]);
    if (due.isEmpty) return;
    busy = true;
    unawaited(notifier
        .recruitStoryCompanions(visited,
            companions: companions,
            races: races,
            professions: professions,
            dice: dice,
            houses: houses)
        .whenComplete(() => busy = false));
  }

  ref.listen(storyPlayProvider.select((p) => p.visitedNodeIds),
      (previous, next) => check());
  // A save already past her scene: once the tables are in.
  Future.microtask(check);
});
