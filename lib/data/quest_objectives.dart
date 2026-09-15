import '../providers/player_session_provider.dart';

/// One [ObjectiveStatus] per entry in a quest's `objectives` array — quests
/// with more than one are, in effect, split into sub-quests already: no
/// separate "quest group" concept was needed, since `objectives` was
/// always a list (see docs/quest-progress-tracking.md), just one every
/// current quest happens to use with a single entry. A quest whose design
/// calls for several distinct beats (e.g. "recover 3 relics, then report
/// back") is authored as several objectives on the one quest, and the
/// Quests tab renders each as its own checklist line.
class ObjectiveStatus {
  const ObjectiveStatus({
    required this.description,
    required this.current,
    required this.required,
    required this.met,
  });

  final String description;

  /// Progress toward [required] — for display only (e.g. "2/3"); whether
  /// the objective actually gates completion is [met].
  final int current;
  final int required;
  final bool met;
}

/// [questRecord]'s objectives against [session], one [ObjectiveStatus]
/// each, in order. [questId] is required separately (rather than read out
/// of [questRecord]) because a pre-this-feature save's already-active
/// quests are grandfathered past real checking via
/// [PlayerSession.grandfatheredQuestIds] — see that field's doc comment.
List<ObjectiveStatus> objectiveStatusesFor(
  String questId,
  Map<String, dynamic> questRecord,
  PlayerSession session,
) {
  final grandfathered = session.grandfatheredQuestIds.contains(questId);
  final objectives =
      (questRecord['objectives'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
  return [
    for (final objective in objectives)
      _statusFor(objective, session, grandfathered: grandfathered),
  ];
}

/// Whether every one of [questRecord]'s objectives is met — the gate for
/// the Quests tab's Complete button. A quest with no objectives at all
/// (nothing to enforce) is always met, same as one with none of its
/// objectives carrying real target data.
bool allObjectivesMet(
  String questId,
  Map<String, dynamic> questRecord,
  PlayerSession session,
) =>
    objectiveStatusesFor(questId, questRecord, session)
        .every((status) => status.met);

ObjectiveStatus _statusFor(
  Map<String, dynamic> objective,
  PlayerSession session, {
  required bool grandfathered,
}) {
  final description = objective['description']?.toString() ?? '';
  final requiredAmount = (objective['requiredAmount'] as num?)?.toInt() ?? 1;
  if (grandfathered) {
    return ObjectiveStatus(
      description: description,
      current: requiredAmount,
      required: requiredAmount,
      met: true,
    );
  }

  switch (objective['type']?.toString()) {
    case 'Kill':
      final targetEnemyId = objective['targetEnemyID']?.toString() ?? '';
      // No target data to gate on -- treat as flavor text, not enforceable.
      if (targetEnemyId.isEmpty) {
        return ObjectiveStatus(
          description: description,
          current: requiredAmount,
          required: requiredAmount,
          met: true,
        );
      }
      final current = session.enemyKillCounts[targetEnemyId] ?? 0;
      return ObjectiveStatus(
        description: description,
        current: current > requiredAmount ? requiredAmount : current,
        required: requiredAmount,
        met: current >= requiredAmount,
      );

    case 'Fetch':
      final targetItemId = objective['targetItemID']?.toString() ?? '';
      if (targetItemId.isEmpty) {
        return ObjectiveStatus(
          description: description,
          current: 1,
          required: 1,
          met: true,
        );
      }
      final met = session.inventoryItemIds.contains(targetItemId);
      return ObjectiveStatus(
        description: description,
        current: met ? 1 : 0,
        required: 1,
        met: met,
      );

    default:
      // Talk (no target data at all yet -- see
      // docs/quest-progress-tracking.md's convention question) and any
      // other/future type stay ungated until their own signal is decided.
      return ObjectiveStatus(
        description: description,
        current: requiredAmount,
        required: requiredAmount,
        met: true,
      );
  }
}
