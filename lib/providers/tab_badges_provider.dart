import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_grid_layout.dart';
import '../data/quest_objectives.dart';
import '../data/zone_gating.dart';
import '../gamedata/db_schema.dart';
import '../screens/camp_screen.dart' show campChapter;
import 'game_db_providers.dart';
import 'player_session_provider.dart';
import 'story_providers.dart';

/// Stat or skill points waiting to be spent on the character sheet.
bool hasPointsToSpend(PlayerSession session) =>
    session.statPoints + session.skillPoints > 0;

/// The houses whose Build button is live: not built yet, their required
/// flags met, and the purse covers them.
List<String> affordableHouseIds(
  PlayerSession session,
  Map<String, dynamic> houses,
) =>
    [
      for (final entry in houses.entries)
        if (entry.value is Map<String, dynamic> &&
            !session.builtHouseIds.contains(entry.key) &&
            meetsRequiredFlags(
                entry.value as Map<String, dynamic>, session.flags) &&
            session.gold >=
                (((entry.value as Map<String, dynamic>)['buildCost'] as num?)
                        ?.toInt() ??
                    0))
          entry.key,
    ];

/// The active quests whose Complete button is live: every objective met.
List<String> questsReadyToTurnIn(
  PlayerSession session,
  Map<String, dynamic> quests,
) =>
    [
      for (final questId in session.activeQuestIds)
        if (quests[questId] is Map<String, dynamic> &&
            allObjectivesMet(
                questId, quests[questId] as Map<String, dynamic>, session))
          questId,
    ];

/// Which in-game tabs have something waiting: a dot on Character for
/// unspent points, on Camp for a house the purse covers (once the camp is
/// open), on Other for a quest ready to turn in.
class TabBadges {
  const TabBadges({
    this.character = false,
    this.camp = false,
    this.readyQuestCount = 0,
  });

  final bool character;
  final bool camp;
  final int readyQuestCount;

  bool get other => readyQuestCount > 0;
}

final tabBadgesProvider = Provider<TabBadges>((ref) {
  final session = ref.watch(playerSessionProvider);
  final chapter = chapterOfNode(ref.watch(storyPlayProvider).currentNodeId);
  final houses = ref.watch(gameDbProvider(housesSchema)).value ?? const {};
  final quests = ref.watch(gameDbProvider(questsSchema)).value ?? const {};
  return TabBadges(
    character: hasPointsToSpend(session),
    camp: chapter >= campChapter &&
        affordableHouseIds(session, houses).isNotEmpty,
    readyQuestCount: questsReadyToTurnIn(session, quests).length,
  );
});

/// The quests in progress and which of them are ready to turn in: the
/// shell watches it to announce a goal reached (see HomeShell).
class QuestReadiness {
  const QuestReadiness({
    this.active = const {},
    this.ready = const {},
    this.loaded = true,
  });

  final Set<String> active;
  final Set<String> ready;

  /// False until the quests table has loaded: readiness is unknown then.
  final bool loaded;

  /// The quests [next] has ready that were already in progress, but not
  /// ready, in [previous]: a goal just reached. A quest that only now
  /// appears (a save just loaded), or readiness only now known (the
  /// quests table just loaded), says nothing.
  static List<String> newlyReady(
          QuestReadiness previous, QuestReadiness next) =>
      !previous.loaded || !next.loaded
          ? const []
          : [
              for (final id in next.ready)
                if (previous.active.contains(id) &&
                    !previous.ready.contains(id))
                  id,
            ];
}

final questReadinessProvider = Provider<QuestReadiness>((ref) {
  final session = ref.watch(playerSessionProvider);
  final quests = ref.watch(gameDbProvider(questsSchema)).value;
  if (quests == null) return const QuestReadiness(loaded: false);
  return QuestReadiness(
    active: session.activeQuestIds.toSet(),
    ready: questsReadyToTurnIn(session, quests).toSet(),
  );
});
