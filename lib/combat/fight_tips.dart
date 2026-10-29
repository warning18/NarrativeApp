import 'battlefield_condition.dart';
import 'doctrine.dart';
import 'fight_goal.dart';

/// One-time fight tips: the first fight that shows a goal (Hold the line…),
/// an enemy doctrine (the Short Con…) or a situation (an Ambush…) explains
/// it, once per save (see PlayerSession.seenFightTipIds). Every tip that is
/// due in a fight is shown in one pass, one after another, on the setup
/// screen. Pure, like fight_goal.dart.
///
/// A tip's id names what it explains: `goal_hold`, `doctrine_crows`,
/// `situation_ambush`. Its text is the l10n key `tip_fight_<id>`.

/// The tip id of a goal; null for the plain slaughter, which needs none.
String? _fightGoalTipId(FightGoalKind kind) =>
    kind == FightGoalKind.slay ? null : 'goal_${kind.name}';

/// The tip id of the doctrine of [factionId]'s fighters.
String _fightDoctrineTipId(String factionId) => 'doctrine_$factionId';

/// The tip id of a battlefield condition ("situation"): `situation_ambush`,
/// `situation_high_ground`…
String _fightSituationTipId(BattlefieldCondition condition) =>
    'situation_${conditionLabelKey(condition).substring('condition_'.length)}';

/// The l10n key of a tip's text.
String fightTipTextKey(String id) => 'tip_fight_$id';

/// The tips a fight shows the player, in the order its setup screen shows
/// the banners: the goal, the doctrine, then the situation.
List<String> fightTipIdsFor({
  required FightGoalKind goal,
  String? doctrineFactionId,
  BattlefieldCondition? condition,
}) =>
    [
      if (_fightGoalTipId(goal) case final id?) id,
      if (doctrineFactionId != null) _fightDoctrineTipId(doctrineFactionId),
      if (condition != null) _fightSituationTipId(condition),
    ];

/// The tips of [shown] the player has not had yet ([seen]), in [shown]'s
/// order; none when tutorials are off ([enabled] false).
List<String> dueFightTips({
  required List<String> shown,
  required Iterable<String> seen,
  required bool enabled,
}) {
  if (!enabled) return const [];
  final had = seen.toSet();
  return [
    for (final id in shown)
      if (!had.contains(id)) id,
  ];
}

/// Every fight tip the game can show: one per goal but the slaughter, per
/// doctrine and per situation.
List<String> get allFightTipIds => [
      for (final kind in FightGoalKind.values)
        if (_fightGoalTipId(kind) case final id?) id,
      for (final factionId in doctrines.keys) _fightDoctrineTipId(factionId),
      for (final condition in BattlefieldCondition.values)
        _fightSituationTipId(condition),
    ];

/// The l10n key of the name of what tip [id] explains: the goal's, the
/// doctrine's or the situation's own label ("Hold the line", "The Short
/// Con", "Ambush").
String fightTipNameKey(String id) => id.startsWith('situation_')
    ? 'condition_${id.substring('situation_'.length)}'
    : id;
