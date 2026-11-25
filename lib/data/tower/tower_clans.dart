// The clans in the Tower (docs/simulation/tower-clan-offers.md): the story's
// suitors brought up the stairs. On the floors where an oath used to come,
// up to three clans of the run's pool each offer a gift, a skill of a branch
// the clan sponsors for the hero (or, when it has none left, one of the
// Tower's own). A gift taken raises standing with its clan for the rest of
// the run (and its allies', and lowers its rivals'); at [towerOathStep] the
// clan's oath is dealt. Standing is never saved: it is replayed from the
// cards taken (TowerReward.clan), so a save from before needs nothing.

import 'dart:math';

import '../skill_tree.dart' show skillBranchesFor;
import 'tower_rewards.dart' show TowerReward;
import 'tower_tables.dart';

/// What the clans' offers read of the game's tables: the branches each clan
/// sponsors (factions.json `sponsors`), the steps between the clans
/// (relations.json `pairs`) and the skill trees (skill_trees.json).
class TowerClanTables {
  const TowerClanTables({
    this.sponsors = const {},
    this.relations = const {},
    this.skillTrees = const {},
  });

  /// From the raw tables (factions.json, relations.json, skill_trees.json).
  factory TowerClanTables.fromTables({
    Map<String, dynamic> factions = const {},
    Map<String, dynamic> relations = const {},
    Map<String, dynamic> skillTrees = const {},
  }) =>
      TowerClanTables(
        sponsors: {
          for (final MapEntry(:key, :value) in factions.entries)
            if (value is Map && value['sponsors'] is List)
              key: {
                for (final b in value['sponsors'] as List) b.toString(),
              },
        },
        relations: {
          for (final pair in (relations['pairs'] as List?) ?? const [])
            if (pair is Map && pair['step'] is num)
              _pairKey('${pair['a']}', '${pair['b']}'):
                  (pair['step'] as num).toInt(),
        },
        skillTrees: skillTrees,
      );

  /// Clan -> the branch ids it sponsors.
  final Map<String, Set<String>> sponsors;

  /// The step between two clans (1 blood feud .. 7 allies), by
  /// [_pairKey].
  final Map<String, int> relations;
  final Map<String, dynamic> skillTrees;

  /// The step between [a] and [b], or null when relations.json has none.
  int? stepBetween(String a, String b) => relations[_pairKey(a, b)];
}

String _pairKey(String a, String b) => a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

/// What a gift of [clanId] moves (§1 of the plan): [towerGiftStanding] to
/// the clan, [towerAllyStanding] to each ally among [towerClans], and
/// minus [towerRivalStanding] to each rival (at Heat [heat], Ash's
/// towerRivalStandingOf). The clan first, then the others in [towerClans]'
/// order.
Map<String, int> towerClanRipple(String clanId, TowerClanTables tables,
        {int heat = 0}) =>
    {
      clanId: towerGiftStanding,
      for (final other in towerClans)
        if (other != clanId)
          if (tables.stepBetween(clanId, other) case final step?)
            if (step >= towerAllyRelationStep)
              other: towerAllyStanding
            else if (step <= towerRivalRelationStep)
              other: -towerRivalStandingOf(heat),
    };

/// Standing with each of [towerClans] after [cards] (in the order they
/// were taken): each clan's gift's ripple ([towerClanRipple]), clamped to
/// 0..[towerOathStep] after each card. A card with no clan moves nothing.
/// [heat] is the run's (TowerRun.heat: Ash's rival ripple).
Map<String, int> towerStandingFrom(
    Iterable<TowerReward> cards, TowerClanTables tables,
    {int heat = 0}) {
  final standing = {for (final c in towerClans) c: 0};
  for (final card in cards) {
    if (card.clan.isEmpty) continue;
    for (final MapEntry(:key, :value)
        in towerClanRipple(card.clan, tables, heat: heat).entries) {
      standing[key] = ((standing[key] ?? 0) + value).clamp(0, towerOathStep);
    }
  }
  return standing;
}

/// The deepest skill (its index on a branch) a clan at [standing] gives:
/// the story's tiers (offers.dart's _skillIndexCapFor) on the Tower's six
/// steps: 0-1 the first, 2-3 the second, 4-5 the third, 6 the fourth.
int towerGiftDepthFor(int standing) => min(3, max(0, standing) ~/ 2);

/// The skills [clanId] can give now (§1): on each branch it sponsors for
/// the hero (skillBranchesFor of [raceId] and [professionId], in their
/// order), the first not known whose turn has come (the one before it on
/// the branch known, its `requiredSkillID` known), no deeper than
/// [towerGiftDepthFor] of [standing]. [unlocked] are the skills known.
List<String> towerClanSkillsFor(
  String clanId, {
  required String raceId,
  required String professionId,
  required int standing,
  required Set<String> unlocked,
  required Map<String, dynamic> skills,
  required TowerClanTables tables,
}) {
  final sponsored = tables.sponsors[clanId] ?? const <String>{};
  if (sponsored.isEmpty) return const [];
  final cap = towerGiftDepthFor(standing);
  final out = <String>[];
  for (final branch in skillBranchesFor(tables.skillTrees,
      raceId: raceId, professionId: professionId)) {
    if (!sponsored.contains(branch.id)) continue;
    for (var i = 0; i < branch.skillIds.length && i <= cap; i++) {
      final id = branch.skillIds[i];
      if (unlocked.contains(id)) continue;
      if (i > 0 && !unlocked.contains(branch.skillIds[i - 1])) break;
      final skill = skills[id];
      if (skill is! Map) break;
      final required = skill['requiredSkillID']?.toString() ?? '';
      if (required.isNotEmpty && !unlocked.contains(required)) break;
      if (!out.contains(id)) out.add(id);
      break;
    }
  }
  return out;
}
