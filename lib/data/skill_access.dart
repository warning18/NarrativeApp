// Which skills a character can ever hold: its own class's and race's,
// and the general ones anyone can learn -- never another class's.

/// Whether a character of [raceId] and [professionId] could ever learn
/// [skill]: a skill reserved for another race (`restrictedRaceID`) or
/// another profession (`restrictedProfessionID`) is not theirs. An
/// alignment gate is not a class gate: a skill waiting on the character's
/// reputation still counts.
bool skillFitsCharacter(Map<String, dynamic>? skill,
    {required String raceId, required String professionId}) {
  if (skill == null) return false;
  final race = skill['restrictedRaceID']?.toString() ?? '';
  final profession = skill['restrictedProfessionID']?.toString() ?? '';
  return (race.isEmpty || race == raceId) &&
      (profession.isEmpty || profession == professionId);
}

/// Whether the merge-only [resultId] can ever be crafted by this
/// character: every skill_merges.json recipe that yields it needs inputs
/// the character can learn.
bool mergeResultFitsCharacter(
  String resultId,
  Map<String, dynamic> merges,
  Map<String, dynamic> skills, {
  required String raceId,
  required String professionId,
}) {
  for (final recipe in merges.values) {
    final map = recipe as Map<String, dynamic>;
    if (map['resultSkillID']?.toString() != resultId) continue;
    final inputs =
        (map['inputSkillIDs'] as List?)?.map((e) => e.toString()) ?? const [];
    if (inputs.every((id) => skillFitsCharacter(
        skills[id] as Map<String, dynamic>?,
        raceId: raceId,
        professionId: professionId))) {
      return true;
    }
  }
  return false;
}

/// The skill ids a character of [raceId]/[professionId] can see in their
/// skill list: every non-enemy skill that fits them (see
/// [skillFitsCharacter]); merge-only skills only when some recipe for
/// them fits too.
List<String> skillIdsForCharacter(
  Map<String, dynamic> skills,
  Map<String, dynamic> merges, {
  required String raceId,
  required String professionId,
}) {
  return [
    for (final entry in skills.entries)
      if (entry.value is Map<String, dynamic> &&
          (entry.value as Map<String, dynamic>)['enemyOnly'] != true &&
          skillFitsCharacter(entry.value as Map<String, dynamic>,
              raceId: raceId, professionId: professionId) &&
          ((entry.value as Map<String, dynamic>)['unlockedViaMergeOnly'] !=
                  true ||
              mergeResultFitsCharacter(entry.key, merges, skills,
                  raceId: raceId, professionId: professionId)))
        entry.key,
  ]..sort();
}
