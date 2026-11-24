// What the Skills screen shows, worked out once and away from the widgets:
// every skill the character can see, where it stands (known, next on its
// branch, waiting on the one before it, out of reach), which clans offer
// it (v1.194: the player learns no skill with points, see offers.dart; a
// companion still does, one point each), its tier and what raising it
// costs in essence. The tree, the
// My skills list and the skill sheet all read the same entries, so they
// never disagree, and the rules are unit-tested here (see
// test/skills_view_model_test.dart).

import '../../combat/combat_engine.dart';
import '../../data/factions.dart';
import '../../data/offers.dart' show sponsorsOfSkill;
import '../../data/skill_tree.dart';
import '../../providers/player_session_provider.dart';
import '../../utils/face_style.dart';

/// Where a skill stands for the character.
enum SkillStatus {
  /// Known: learned, or everyone's from the start.
  known,

  /// Next on its branch: a companion learns it with a point (maybe not yet
  /// afforded: see [SkillEntry.affordable]); for the player, the clans
  /// sponsoring it may offer it (see [SkillEntry.sponsors]).
  ready,

  /// The skill before it on its branch comes first ([SkillEntry.after]),
  /// or the character's reputation does not allow it yet.
  locked,
}

/// One skill as the screen shows it.
class SkillEntry {
  const SkillEntry({
    required this.id,
    required this.record,
    required this.status,
    required this.cost,
    required this.affordable,
    this.branch,
    this.index = 0,
    this.after,
    this.tier = 0,
    this.fightTier = 0,
    this.tierable = false,
    this.sponsors = const [],
  });

  final String id;
  final Map<String, dynamic> record;
  final SkillStatus status;

  /// Skill points it costs to learn.
  final int cost;

  /// Whether the points are there to learn it (only meaningful when
  /// [status] is [SkillStatus.ready]).
  final bool affordable;

  /// The branch it grows on, and its place there; null off the tree.
  final SkillBranch? branch;
  final int index;

  /// The skill that must be known first, when it waits on one.
  final String? after;

  /// Its own tier (raised with essence), and the tier it fights at (one
  /// more on the mastered branch).
  final int tier;
  final int fightTier;

  /// Whether essence can raise it: a skill the character learned (the
  /// basic strike everyone has has no tiers).
  final bool tierable;

  /// The factions that offer it (the player's tree: the clans sponsoring
  /// its branch, see offers.dart), in the data's order.
  final List<String> sponsors;

  FaceKind get kind => skillKind(record);
  bool get known => status == SkillStatus.known;
  bool get readyNow => status == SkillStatus.ready && affordable;
  bool get maxed => tier >= maxSkillTier;

  /// Essence to raise it one tier; null when it can't be raised.
  int? get upgradeCost =>
      tierable && !maxed ? skillTierUpgradeCost(tier) : null;
}

/// The whole screen's worth of skills for the player or a companion.
class SkillsModel {
  SkillsModel._({
    required this.isPlayer,
    required this.skillPoints,
    required this.essence,
    required this.branches,
    required this.masteredBranchId,
    required this.entries,
    required this.reputationIds,
    required this.knownIds,
  });

  /// The player's: their tree (class branches and heritage), the
  /// reputation skills their class may take, and everything they know;
  /// [clans] names who offers each skill not yet known.
  factory SkillsModel.forPlayer({
    required PlayerSession session,
    required Map<String, dynamic> skills,
    required Map<String, dynamic> trees,
    ClanData clans = ClanData.empty,
  }) {
    final branches = skillBranchesFor(trees,
        raceId: session.raceId, professionId: session.professionId);
    final known = knownSkillIds(skills, session.unlockedSkillIds);
    final tiers = effectiveSkillTiers(
        session.skillTiers, trees, session.masteredBranchId);
    final entries = <String, SkillEntry>{};

    SkillEntry entry(String id, {SkillBranch? branch, int index = 0}) {
      final record = skills[id] as Map<String, dynamic>? ?? const {};
      final cost = branch == null ? 1 : branchSkillPointCost(index);
      final SkillStatus status;
      String? after;
      if (known.contains(id)) {
        status = SkillStatus.known;
      } else if (canLearnWithPoints(id,
          branches: branches,
          known: known,
          skills: skills,
          alignmentScore: session.alignmentScore)) {
        status = SkillStatus.ready;
      } else {
        status = SkillStatus.locked;
        if (branch != null && index > 0) after = branch.skillIds[index - 1];
      }
      return SkillEntry(
        id: id,
        record: record,
        status: status,
        cost: cost,
        // The player learns with no points: the clans offer.
        affordable: false,
        branch: branch,
        index: index,
        after: after,
        tier: session.skillTiers[id] ?? 0,
        fightTier: tiers[id] ?? 0,
        tierable: session.unlockedSkillIds.contains(id),
        sponsors: known.contains(id)
            ? const []
            : sponsorsOfSkill(id,
                data: clans,
                skillTrees: trees,
                skills: skills,
                raceId: session.raceId,
                professionId: session.professionId),
      );
    }

    for (final branch in branches) {
      for (var i = 0; i < branch.skillIds.length; i++) {
        final id = branch.skillIds[i];
        if (skills[id] is! Map<String, dynamic>) continue;
        entries[id] = entry(id, branch: branch, index: i);
      }
    }
    // Skills off the tree the class may earn by reputation.
    final reputationIds = <String>[
      for (final e in skills.entries)
        if (e.value is Map<String, dynamic> &&
            !entries.containsKey(e.key) &&
            isReputationSkill(e.value as Map<String, dynamic>) &&
            (e.value as Map<String, dynamic>)['enemyOnly'] != true &&
            _fits(e.value as Map<String, dynamic>, session.raceId,
                session.professionId))
          e.key,
    ]..sort();
    for (final id in reputationIds) {
      entries[id] = entry(id);
    }
    // Everything else they know (the basic strike, crafted skills, a
    // die's kit).
    for (final id in known) {
      if (entries.containsKey(id)) continue;
      final record = skills[id];
      if (record is! Map<String, dynamic> || record['enemyOnly'] == true) {
        continue;
      }
      entries[id] = entry(id);
    }
    return SkillsModel._(
      isPlayer: true,
      skillPoints: 0,
      essence: session.skillEssence,
      branches: branches,
      masteredBranchId: session.masteredBranchId,
      entries: entries,
      reputationIds: reputationIds,
      knownIds: [
        for (final e in entries.values)
          if (e.known) e.id
      ],
    );
  }

  /// A companion's: their own class's skills, in any order, one point
  /// each (see [allySkillIds]); no tree, no tiers, no essence.
  factory SkillsModel.forAlly({
    required int skillPoints,
    required List<String> unlockedSkillIds,
    required String professionId,
    required Map<String, dynamic> skills,
  }) {
    final known = knownSkillIds(skills, unlockedSkillIds);
    final ids = allySkillIds(skills,
        professionId: professionId, known: unlockedSkillIds)
      ..sort((a, b) {
        final k = (known.contains(a) ? 0 : 1) - (known.contains(b) ? 0 : 1);
        return k != 0 ? k : a.compareTo(b);
      });
    final entries = <String, SkillEntry>{
      for (final id in ids)
        id: SkillEntry(
          id: id,
          record: skills[id] as Map<String, dynamic>? ?? const {},
          status: known.contains(id) ? SkillStatus.known : SkillStatus.ready,
          cost: 1,
          affordable: skillPoints >= 1,
        ),
    };
    return SkillsModel._(
      isPlayer: false,
      skillPoints: skillPoints,
      essence: 0,
      branches: const [],
      masteredBranchId: '',
      entries: entries,
      reputationIds: const [],
      knownIds: [
        for (final e in entries.values)
          if (e.known) e.id
      ],
    );
  }

  final bool isPlayer;
  final int skillPoints;
  final int essence;
  final List<SkillBranch> branches;
  final String masteredBranchId;

  /// Every skill shown, by id: the tree's, the reputation ones, the known.
  final Map<String, SkillEntry> entries;
  final List<String> reputationIds;
  final List<String> knownIds;

  SkillEntry? operator [](String id) => entries[id];

  List<SkillBranch> get classBranches =>
      branches.where((b) => !b.heritage).toList();
  List<SkillBranch> get heritageBranches =>
      branches.where((b) => b.heritage).toList();

  /// Skills the points can learn right now.
  int get readyCount => entries.values.where((e) => e.readyNow).length;

  /// The cheapest tier raise among the known skills, for the essence bar;
  /// null when nothing can be raised.
  int? get nextUpgradeCost {
    final costs = [
      for (final e in entries.values)
        if (e.known && e.upgradeCost != null) e.upgradeCost!
    ];
    if (costs.isEmpty) return null;
    return costs.reduce((a, b) => a < b ? a : b);
  }

  /// Known skills of [branch], learned in its order.
  int knownOn(SkillBranch branch) =>
      branch.skillIds.where((id) => entries[id]?.known ?? false).length;

  /// Whether [branch] can be mastered now (with essence, see
  /// branchMasteryEssenceCost).
  bool canMaster(SkillBranch branch) => canMasterBranch(branch,
      known: knownIds.toSet(),
      masteredBranchId: masteredBranchId,
      essence: essence);

  bool isComplete(SkillBranch branch) =>
      branchComplete(branch, knownIds.toSet());
}

/// What the character knows: what they learned, and the skills everyone
/// has from the start (`isUnlocked`).
Set<String> knownSkillIds(
        Map<String, dynamic> skills, Iterable<String> unlockedSkillIds) =>
    {
      ...unlockedSkillIds,
      for (final entry in skills.entries)
        if (entry.value is Map<String, dynamic> &&
            (entry.value as Map<String, dynamic>)['isUnlocked'] == true)
          entry.key,
    };

bool _fits(Map<String, dynamic> skill, String raceId, String professionId) {
  final race = skill['restrictedRaceID']?.toString() ?? '';
  final profession = skill['restrictedProfessionID']?.toString() ?? '';
  return (race.isEmpty || race == raceId) &&
      (profession.isEmpty || profession == professionId);
}

/// A skill's numbers at each tier from 0 to [maxSkillTier]: what raising
/// it buys. Only the numbers the skill has (damage, multiplier, healing,
/// mana) are listed.
List<({String key, List<String> values})> tierTable(
    Map<String, dynamic> skill) {
  final tiers = [
    for (var t = 0; t <= maxSkillTier; t++) applySkillTier(skill, t)
  ];
  num n(Map<String, dynamic> s, String k, num fallback) =>
      (s[k] as num?) ?? fallback;
  final rows = <({String key, List<String> values})>[];
  if (n(skill, 'damageMod', 0) > 0) {
    rows.add((
      key: 'damage_mod_label',
      values: [for (final s in tiers) '+${n(s, 'damageMod', 0)}'],
    ));
  }
  if (n(skill, 'damageMultiplier', 1) > 1 || n(skill, 'damageMod', 0) > 0) {
    rows.add((
      key: 'damage_multiplier_label',
      values: [
        for (final s in tiers)
          '×${n(s, 'damageMultiplier', 1).toDouble().toStringAsFixed(1)}'
      ],
    ));
  }
  if (n(skill, 'healAmount', 0) > 0) {
    rows.add((
      key: 'heal_amount',
      values: [for (final s in tiers) '${n(s, 'healAmount', 0)}'],
    ));
  }
  return rows;
}

/// A short line of what [skill] does at [tier]: "+6 damage · ×1.4",
/// "heals 15 · Earth". [t] reads the labels.
String skillSummary(
    Map<String, dynamic> skill, int tier, String Function(String key) t) {
  final s = applySkillTier(skill, tier);
  final damage = (s['damageMod'] as num?)?.toInt() ?? 0;
  final multiplier = (s['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
  final heal = (s['healAmount'] as num?)?.toInt() ?? 0;
  final mana = (s['manaGain'] as num?)?.toInt() ?? 0;
  final element = s['element']?.toString() ?? 'None';
  return [
    if (damage > 0) t('summary_damage').replaceAll('{n}', '$damage'),
    if (multiplier > 1.0) '×${multiplier.toStringAsFixed(1)}',
    if (heal > 0) t('summary_heal').replaceAll('{n}', '$heal'),
    if (mana > 0) t('summary_mana').replaceAll('{n}', '$mana'),
    if (element != 'None' && element.isNotEmpty) element,
  ].join(' · ');
}
