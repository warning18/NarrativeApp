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
