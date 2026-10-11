import 'factions.dart';
import 'offers.dart' show sponsorsOfSkill;
import 'skill_tree.dart';

/// The clans' favorability matrix (v1.232): which peoples and which classes
/// each clan grows. It is read off the branches a clan sponsors
/// (factions.json `sponsors`), so the data stays the one source: a heritage
/// branch is a race's, a class has three branches.
class ClanAffinityMatrix {
  const ClanAffinityMatrix({
    required this.clanIds,
    required this.raceIds,
    required this.professionIds,
    required this.races,
    required this.professions,
  });

  final List<String> clanIds;
  final List<String> raceIds;
  final List<String> professionIds;

  /// Per clan, per race: 1 when the clan sponsors the race's heritage.
  final Map<String, Map<String, int>> races;

  /// Per clan, per class: how many of the class's three branches it
  /// sponsors.
  final Map<String, Map<String, int>> professions;

  int raceLevel(String clanId, String raceId) => races[clanId]?[raceId] ?? 0;

  int professionLevel(String clanId, String professionId) =>
      professions[clanId]?[professionId] ?? 0;

  /// The clans that sponsor [raceId]'s heritage.
  List<String> clansOfRace(String raceId) => [
        for (final c in clanIds)
          if (raceLevel(c, raceId) > 0) c
      ];

  /// The clans that sponsor at least one branch of [professionId].
  List<String> clansOfProfession(String professionId) => [
        for (final c in clanIds)
          if (professionLevel(c, professionId) > 0) c
      ];

  /// What breaks the matrix's consistency, in words: a clan with no people
  /// or no class, a people with fewer than two clans (a character always
  /// has a fallback patron), a class with fewer than three clans (its
  /// three branches stay with three different patrons).
  List<String> issues() => [
        for (final c in clanIds) ...[
          if (raceIds.every((r) => raceLevel(c, r) == 0))
            'Clan "$c" favors no race.',
          if (professionIds.every((p) => professionLevel(c, p) == 0))
            'Clan "$c" favors no class.',
        ],
        for (final r in raceIds)
          if (clansOfRace(r).length < 2)
            'Race "$r" has fewer than two clans behind it.',
        for (final p in professionIds)
          if (clansOfProfession(p).length < 3)
            'Class "$p" has fewer than three clans behind it.',
      ];
}

/// The matrix of [data]'s clans over [raceIds] and [professionIds], from
/// the branches in [skillTrees] (skill_trees.json).
ClanAffinityMatrix buildAffinityMatrix({
  required ClanData data,
  required Map<String, dynamic> skillTrees,
  required List<String> raceIds,
  required List<String> professionIds,
}) {
  final clans = [
    for (final f in data.clans)
      if (f.sponsors.isNotEmpty) f
  ];
  final races = <String, Map<String, int>>{};
  final professions = <String, Map<String, int>>{};
  for (final clan in clans) {
    final r = <String, int>{};
    final p = <String, int>{};
    for (final id in clan.sponsors) {
      final record = skillTrees[id];
      if (record is! Map<String, dynamic>) continue;
      final branch = SkillBranch.fromRecord(id, record);
      final race = record['raceId']?.toString() ?? '';
      final profession = record['professionId']?.toString() ?? '';
      if (branch.heritage && race.isNotEmpty) r[race] = 1;
      if (profession.isNotEmpty) p[profession] = (p[profession] ?? 0) + 1;
    }
    races[clan.id] = r;
    professions[clan.id] = p;
  }
  return ClanAffinityMatrix(
    clanIds: [for (final c in clans) c.id],
    raceIds: raceIds,
    professionIds: professionIds,
    races: races,
    professions: professions,
  );
}

/// A fusion or an ascension in the skills table, with the clans behind it
/// for a character of its class.
class ClanCardSkill {
  const ClanCardSkill({
    required this.skillId,
    required this.professionId,
    required this.parents,
    required this.clanIds,
    required this.ascension,
  });

  final String skillId;
  final String professionId;

  /// The two skills a fusion needs, or the one an ascension raises.
  final List<String> parents;

  /// The clans that offer it: both of a fusion, the one of an ascension.
  final List<String> clanIds;
  final bool ascension;
}

/// Every fusion and ascension in [skills], for a character of its class
/// (and [raceId]'s heritage), with the clans that offer it.
List<ClanCardSkill> clanCardSkills({
  required ClanData data,
  required Map<String, dynamic> skills,
  required Map<String, dynamic> skillTrees,
  String raceId = 'human',
}) {
  final out = <ClanCardSkill>[];
  for (final entry in skills.entries) {
    final skill = entry.value;
    if (skill is! Map<String, dynamic>) continue;
    final fusion = skill['fusionOf'] is List
        ? [for (final p in skill['fusionOf'] as List) p.toString()]
        : const <String>[];
    final base = skill['ascendsSkillID']?.toString() ?? '';
    if (fusion.isEmpty && base.isEmpty) continue;
    final profession = skill['restrictedProfessionID']?.toString() ?? '';
    final parents = fusion.isNotEmpty ? fusion : [base];
    final clans = <String>[];
    for (final parent in parents) {
      for (final id in sponsorsOfSkill(parent,
          data: data,
          skillTrees: skillTrees,
          raceId: raceId,
          professionId: profession,
          skills: skills)) {
        if ((data.faction(id)?.isClan ?? false) && !clans.contains(id)) {
          clans.add(id);
        }
      }
    }
    out.add(ClanCardSkill(
      skillId: entry.key,
      professionId: profession,
      parents: parents,
      clanIds: clans,
      ascension: fusion.isEmpty,
    ));
  }
  return out;
}
