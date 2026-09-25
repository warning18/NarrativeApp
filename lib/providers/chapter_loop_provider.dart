import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_loop.dart';
import '../gamedata/db_schema.dart';
import '../models/story_node.dart';
import 'game_db_providers.dart';
import 'player_session_provider.dart';
import 'story_providers.dart';

/// The open chapters (chapters.json), in the reader's language.
final chapterLoopsProvider = Provider<List<ChapterLoop>>((ref) {
  final chapters =
      ref.watch(localizedDbProvider(chaptersSchema)).value ?? const {};
  return chapterLoopsFrom(chapters);
});

/// The open chapter the story is in (see [currentLoop]), if any.
final currentLoopProvider = Provider<ChapterLoop?>((ref) {
  final play = ref.watch(storyPlayProvider);
  return currentLoop(
    currentNodeId: play.currentNodeId,
    history: play.history,
    loops: ref.watch(chapterLoopsProvider),
  );
});

/// The camp the story comes back to (see [currentCampNodeId]).
final currentCampNodeIdProvider = Provider<String?>((ref) {
  final play = ref.watch(storyPlayProvider);
  return currentCampNodeId(
    currentNodeId: play.currentNodeId,
    history: play.history,
    loops: ref.watch(chapterLoopsProvider),
  );
});

/// The chapter the party has reached (see [reachedChapter]): what the
/// chart, the expeditions and the places open to.
final reachedChapterProvider = Provider<int>((ref) {
  final play = ref.watch(storyPlayProvider);
  return reachedChapter(
    currentNodeId: play.currentNodeId,
    history: play.history,
    loops: ref.watch(chapterLoopsProvider),
    story: ref.watch(storyDataProvider).value,
  );
});

/// Where the open chapter stands: its activities done, its goal, and
/// whether its main quest is open.
class ChapterProgress {
  const ChapterProgress({
    required this.loop,
    required this.done,
    required this.missingPlaceIds,
  });

  final ChapterLoop loop;
  final int done;

  /// Places the main quest still needs visited.
  final List<String> missingPlaceIds;

  int get goal => loop.activityGoal;

  bool get mainQuestOpen => done >= goal && missingPlaceIds.isEmpty;
}

final chapterProgressProvider = Provider<ChapterProgress?>((ref) {
  final loop = ref.watch(currentLoopProvider);
  final story = ref.watch(storyDataProvider).value;
  if (loop == null || story == null) return null;
  final flags = ref.watch(playerSessionProvider.select((s) => s.flags));
  final visited = ref.watch(storyPlayProvider.select((p) => p.visitedNodeIds));
  final completedZoneIds =
      ref.watch(playerSessionProvider.select((s) => s.completedZoneIds));
  final zones = ref.watch(gameDbProvider(zonesSchema)).value ?? const {};
  return ChapterProgress(
    loop: loop,
    done: chapterActivityCount(
      story: story,
      chapter: loop.chapter,
      flags: flags,
      completedZoneIds: completedZoneIds,
      zones: zones,
    ),
    missingPlaceIds:
        missingMainQuestPlaces(loop, story, flags, visitedNodeIds: visited),
  );
});

/// The places the party can travel to now (see [knownPlaces]).
final knownPlacesProvider = Provider<List<StoryNode>>((ref) {
  final story = ref.watch(storyDataProvider).value;
  if (story == null) return const [];
  return knownPlaces(
    story,
    chapter: ref.watch(reachedChapterProvider),
    flags: ref.watch(playerSessionProvider.select((s) => s.flags)),
  );
});

/// The known places with a companion still to meet there (see
/// [placeCompanionLeads]): place id to the companions' ids. The camp says
/// so, so a party in a hurry does not walk past them.
final companionLeadsProvider = Provider<Map<String, List<String>>>((ref) {
  final story = ref.watch(storyDataProvider).value;
  if (story == null) return const {};
  final quests = ref.watch(gameDbProvider(questsSchema)).value ?? const {};
  final session = ref.watch(playerSessionProvider);
  final unavailable = [
    for (final ally in session.recruitedAllies) ally.companionId,
    ...session.lostAllyIds,
  ];
  final leads = <String, List<String>>{};
  for (final place in ref.watch(knownPlacesProvider)) {
    final allies = placeCompanionLeads(place, story, quests,
        flags: session.flags,
        alignmentScore: session.alignmentScore,
        charisma: session.charisma,
        unavailableAllyIds: unavailable);
    if (allies.isNotEmpty) leads[place.id] = allies;
  }
  return leads;
});
