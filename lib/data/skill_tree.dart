// The skill tree: each class has three branches to grow along, and each
// race a heritage branch. A branch's skills are learned in order, one skill
// point each; completing a class branch lets the character master it, and
// only one branch is ever mastered -- the specialisation. A mastered
// branch's skills fight one tier above their own.
//
// Companions stay simpler: they learn their own class's skills, in any
// order, and nothing else (see [allySkillIds]).

import 'dart:math';

/// Skill points it costs to master a completed branch.
const int branchMasteryCost = 2;

/// Tiers a mastered branch adds to each of its skills in a fight.
const int branchMasteryTierBonus = 1;

class SkillBranch {
  const SkillBranch({
    required this.id,
    required this.name,
    required this.description,
    required this.skillIds,
    required this.heritage,
    required this.order,
  });

  factory SkillBranch.fromRecord(String id, Map<String, dynamic> record) =>
      SkillBranch(
        id: id,
        name: record['branchName']?.toString() ?? id,
        description: record['description']?.toString() ?? '',
        skillIds: [
          for (final skillId in (record['skillIds'] as List?) ?? const [])
            skillId.toString(),
        ],
        heritage: (record['raceId']?.toString() ?? '').isNotEmpty,
        order: (record['order'] as num?)?.toInt() ?? 1,
      );

  final String id;
  final String name;
  final String description;

  /// In the order they are learned: each after the one before it.
  final List<String> skillIds;

  /// A race's heritage branch: learned the same way, never mastered.
  final bool heritage;
  final int order;
}

/// A character's tree: their class's branches in order, then their race's
/// heritage branch.
List<SkillBranch> skillBranchesFor(
  Map<String, dynamic> trees, {
  required String raceId,
  required String professionId,
}) {
  final branches = [
    for (final entry in trees.entries)
      if (entry.value is Map<String, dynamic>)
        if (_belongsTo(entry.value as Map<String, dynamic>,
            raceId: raceId, professionId: professionId))
          SkillBranch.fromRecord(
              entry.key, entry.value as Map<String, dynamic>),
  ];
  branches.sort((a, b) {
    if (a.heritage != b.heritage) return a.heritage ? 1 : -1;
    return a.order != b.order
        ? a.order.compareTo(b.order)
        : a.id.compareTo(b.id);
  });
  return branches;
}

bool _belongsTo(Map<String, dynamic> record,
    {required String raceId, required String professionId}) {
  final profession = record['professionId']?.toString() ?? '';
  final race = record['raceId']?.toString() ?? '';
  if (profession.isNotEmpty) return profession == professionId;
  return race.isNotEmpty && race == raceId;
}

/// The branch [skillId] grows on in [branches], and its place there.
({SkillBranch branch, int index})? branchPlaceOf(
    String skillId, List<SkillBranch> branches) {
  for (final branch in branches) {
    final index = branch.skillIds.indexOf(skillId);
    if (index >= 0) return (branch: branch, index: index);
  }
  return null;
}

/// A skill that waits on the character's reputation rather than a
/// branch (its `requiredAlignmentMin`/`Max`): learned outside the tree.
bool isReputationSkill(Map<String, dynamic>? skill) =>
    skill != null &&
    (skill['requiredAlignmentMin'] != null ||
        skill['requiredAlignmentMax'] != null);

bool reputationAllows(Map<String, dynamic> skill, int alignmentScore) {
  final min = (skill['requiredAlignmentMin'] as num?)?.toInt();
  final max = (skill['requiredAlignmentMax'] as num?)?.toInt();
  return (min == null || alignmentScore >= min) &&
      (max == null || alignmentScore <= max);
}

enum SkillNodeState {
  /// Learned already.
  known,

  /// The skill before it on its branch is known: one point learns it.
  learnable,

  /// The skill before it on its branch comes first.
  locked,
}

SkillNodeState skillNodeState(
  SkillBranch branch,
  int index,
  Set<String> known,
) {
  if (known.contains(branch.skillIds[index])) return SkillNodeState.known;
  return index == 0 || known.contains(branch.skillIds[index - 1])
      ? SkillNodeState.learnable
      : SkillNodeState.locked;
}

/// Whether the character can spend a skill point on [skillId] now: the
/// next skill on its branch, or a reputation skill their standing allows.
/// Any other skill (another class's, or one only a die or a recipe gives)
/// is not learned with points.
bool canLearnWithPoints(
  String skillId, {
  required List<SkillBranch> branches,
  required Set<String> known,
  required Map<String, dynamic> skills,
  required int alignmentScore,
}) {
  if (known.contains(skillId)) return false;
  final place = branchPlaceOf(skillId, branches);
  if (place != null) {
    return skillNodeState(place.branch, place.index, known) ==
        SkillNodeState.learnable;
  }
  final skill = skills[skillId] as Map<String, dynamic>?;
  return isReputationSkill(skill) && reputationAllows(skill!, alignmentScore);
}

bool branchComplete(SkillBranch branch, Set<String> known) =>
    branch.skillIds.every(known.contains);

/// Whether [branch] can be mastered now: a class branch, every skill on it
/// known, no branch mastered yet, and the points to spend.
bool canMasterBranch(
  SkillBranch branch, {
  required Set<String> known,
  required String masteredBranchId,
  required int skillPoints,
}) =>
    !branch.heritage &&
    masteredBranchId.isEmpty &&
    branchComplete(branch, known) &&
    skillPoints >= branchMasteryCost;

/// The tiers skills fight at: their own ([tiers]), one higher on the
/// mastered branch.
Map<String, int> effectiveSkillTiers(
  Map<String, int> tiers,
  Map<String, dynamic> trees,
  String masteredBranchId,
) {
  final record = trees[masteredBranchId];
  if (masteredBranchId.isEmpty || record is! Map<String, dynamic>) {
    return tiers;
  }
  final branch = SkillBranch.fromRecord(masteredBranchId, record);
  return {
    ...tiers,
    for (final id in branch.skillIds)
      id: max(0, tiers[id] ?? 0) + branchMasteryTierBonus,
  };
}

/// A companion's skills: their own class's (learned with their points, in
/// any order), plus whatever they already know (their die's kit). Never
/// another class's, a race's or the general ones.
List<String> allySkillIds(
  Map<String, dynamic> skills, {
  required String professionId,
  required Iterable<String> known,
}) {
  final knownSet = known.toSet();
  return [
    for (final entry in skills.entries)
      if (entry.value is Map<String, dynamic> &&
          (entry.value as Map<String, dynamic>)['enemyOnly'] != true &&
          ((entry.value as Map<String, dynamic>)['restrictedProfessionID']
                      ?.toString() ==
                  professionId ||
              knownSet.contains(entry.key)))
        entry.key,
  ]..sort();
}
