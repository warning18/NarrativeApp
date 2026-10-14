import '../providers/player_session_provider.dart';
import 'quest_objectives.dart';

// What the player follows and has discovered: the followed quest and its
// current goal, and which quests, creatures and people a play-mode list
// may show.

/// The quest shown above the story: the one the player follows while it
/// is active, else the most recently taken active quest, else none.
String? followedQuestIdOf(PlayerSession session) {
  if (session.activeQuestIds.contains(session.trackedQuestId)) {
    return session.trackedQuestId;
  }
  return session.activeQuestIds.isEmpty ? null : session.activeQuestIds.last;
}

/// Where a quest stands for the player: its next unmet objective (with
/// progress), or [ready] once every objective is met and it can be
/// turned in.
class QuestGoal {
  const QuestGoal({
    required this.description,
    required this.current,
    required this.required,
    required this.ready,
  });

  final String description;
  final int current;
  final int required;
  final bool ready;

  /// "Defeat catacomb ghouls (1/3)", or the bare description when one is
  /// enough.
  String get label =>
      required > 1 ? '$description ($current/$required)' : description;

  /// A short fingerprint of the goal's state, to notice progress.
  String get signature => '$description|$current|$required|$ready';
}

/// [quest]'s current goal for [session]: the first objective not met yet,
/// or the last one marked [QuestGoal.ready] when all are met (a quest with
/// no objectives is ready at once).
QuestGoal questGoalFor(
    String questId, Map<String, dynamic> quest, PlayerSession session) {
  final statuses = objectiveStatusesFor(questId, quest, session);
  for (final status in statuses) {
    if (!status.met) {
      return QuestGoal(
        description: status.description,
        current: status.current,
        required: status.required,
        ready: false,
      );
    }
  }
  final last = statuses.isEmpty ? null : statuses.last;
  return QuestGoal(
    description: last?.description ?? '',
    current: last?.current ?? 0,
    required: last?.required ?? 0,
    ready: true,
  );
}

/// Whether the player has come across [questId]: offered, taken on or
/// done. A play-mode quest list shows nothing else.
bool questDiscovered(String questId, PlayerSession session) =>
    session.activeQuestIds.contains(questId) ||
    session.completedQuestIds.contains(questId) ||
    session.unlockedQuestIds.contains(questId);

/// Whether the party has met [enemyId]: beaten it in the story or on an
/// expedition. The bestiary shows nothing else in play.
bool enemyDiscovered(String enemyId, PlayerSession session) =>
    session.unlockedEnemyIds.contains(enemyId) ||
    (session.enemyKillCounts[enemyId] ?? 0) > 0;

/// Whether [npc] can appear in the play-mode People list (v1.204):
/// spoken to already; or the shop they keep (`shopId`) found
/// ([unlockedShopIds], the session's when null); or one of the scenes
/// meeting them (`metNodes`) stood in ([visitedNodeIds]: the nodes
/// visited and the current one); or one of their `metFlags` held. A
/// record from before the codex, with none of the three, is known the old
/// way: its `requiredFlag` held (or empty) and the story at its chapter
/// ([currentChapter]).
bool npcDiscovered(String npcId, Map<String, dynamic> npc,
    PlayerSession session, int currentChapter,
    {Iterable<String> visitedNodeIds = const [],
    Iterable<String>? unlockedShopIds}) {
  if (session.talkedToNpcIds.contains(npcId)) return true;
  List<String> list(String key) => [
        for (final e in (npc[key] as List?) ?? const [])
          if (e.toString().trim().isNotEmpty) e.toString().trim(),
      ];
  final metNodes = list('metNodes');
  final metFlags = list('metFlags');
  final shopId = npc['shopId']?.toString().trim() ?? '';
  if (metNodes.isEmpty && metFlags.isEmpty && shopId.isEmpty) {
    final flag = npc['requiredFlag']?.toString() ?? '';
    if (flag.isNotEmpty && !session.flags.contains(flag)) return false;
    final chapter = (npc['chapter'] as num?)?.toInt() ?? 1;
    return currentChapter >= chapter;
  }
  if (shopId.isNotEmpty &&
      (unlockedShopIds ?? session.unlockedShopIds).contains(shopId)) {
    return true;
  }
  if (metNodes.isNotEmpty) {
    final visited =
        visitedNodeIds is Set<String> ? visitedNodeIds : visitedNodeIds.toSet();
    if (metNodes.any(visited.contains)) return true;
  }
  return metFlags.any(session.flags.contains);
}

/// The order a play-mode quest list shows [questIds] in: the followed
/// quest, then quests ready to turn in, then the rest in progress, then
/// those offered but not taken, then finished ones -- each group by id.
List<String> questDisplayOrder(Iterable<String> questIds,
    Map<String, dynamic> quests, PlayerSession session) {
  final followed = followedQuestIdOf(session);
  int rank(String id) {
    if (id == followed) return 0;
    if (session.activeQuestIds.contains(id)) {
      final quest = quests[id] as Map<String, dynamic>?;
      final ready = quest != null && allObjectivesMet(id, quest, session);
      return ready ? 1 : 2;
    }
    if (session.completedQuestIds.contains(id)) return 4;
    return 3;
  }

  return questIds.toList()
    ..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.compareTo(b);
    });
}
