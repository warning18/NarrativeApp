import 'dart:math' show max, min;

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../l10n/dice_names_fr.dart';
import '../l10n/skill_names_fr.dart';
import 'combat_engine.dart';

/// How strongly a skill works when it is set on a basic face (Attack,
/// Guard, Heal) instead of a skill face: its damage and healing are scaled
/// by this, never below what the face itself would have done. A skill face
/// casts at full power. Keeps every face open to skills without letting a
/// die of six top skills outclass the dice built around them.
const double channeledSkillPower = channeledPower;

/// The basic actions a face can carry on its own: the plain numbered
/// faces. A skill set on one of them is channeled (see
/// [channeledSkillPower]).
const Set<String> basicFaceTypes = {'Attack', 'Defend', 'Heal', 'Mana'};

/// Race and profession prefixes on skill ids, dropped from the name shown
/// to the player ("warrior_shield_bash" reads "Shield Bash").
const List<String> _skillIdPrefixes = [
  'human_',
  'elf_',
  'dwarf_',
  'orc_',
  'voidkin_',
  'warrior_',
  'mage_',
  'rogue_',
  'cleric_',
  'ranger_',
];

/// Whether [skill] is one of the enemies' own moves (skills.json
/// `enemyOnly`): never listed, unlocked or set on a die by the party.
bool isEnemyOnlySkill(Map<String, dynamic>? skill) =>
    skill?['enemyOnly'] as bool? ?? false;

/// A skill's name for the player: its French name in French (see
/// [skillNamesFr]), otherwise built from its id.
String skillDisplayName(String skillId,
    {AppLanguage language = AppLanguage.en}) {
  if (language == AppLanguage.fr) {
    final french = skillNamesFr[skillId];
    if (french != null) return french;
  }
  var id = skillId;
  for (final prefix in _skillIdPrefixes) {
    if (id.startsWith(prefix) && id.length > prefix.length) {
      id = id.substring(prefix.length);
      break;
    }
  }
  return id
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Whether the player may set a skill on [face] (docs/proposals/
/// dice-sizes.md §2): every face of a die is a slot, a Skill face (its
/// signature skill included, which the pick replaces) and every plain
/// numbered face (Attack, Defend, Heal, Mana). Only a blank face and a face
/// the die marks `fixed` stay as they are.
bool isAssignableFace(Map<String, dynamic> face) {
  if (face['fixed'] == true) return false;
  final type = face['type']?.toString() ?? '';
  return type == 'Skill' || basicFaceTypes.contains(type);
}

/// Whether [face] is a Skill face with a signature skill of its own (not
/// empty, not the generic Heavy Attack): the die's identity, which a pick
/// may replace and which casts while nothing is set on it.
bool isSignatureFace(Map<String, dynamic> face) {
  if (face['type'] != 'Skill') return false;
  final linked = face['linkedSkillID']?.toString() ?? '';
  return linked.isNotEmpty && linked != 'heavy_attack';
}

/// Whether [face] is an open Skill face: a Skill face with no skill of its
/// own (or the generic Heavy Attack), not fixed. Where the simulator's
/// players put their learned skills.
bool isOpenSkillFace(Map<String, dynamic> face) =>
    face['type'] == 'Skill' && face['fixed'] != true && !isSignatureFace(face);

/// The skill [face] casts while nothing is set on it and that counts
/// against the copy limits: its signature skill, or what a fixed Skill face
/// casts. Null for an open face left as it is.
String? _ownCountedSkill(Map<String, dynamic> face) {
  if (!isAssignableFace(face)) return faceSkillId(face, null);
  return isSignatureFace(face) ? face['linkedSkillID'].toString() : null;
}

/// How rare a skill is: the rarer, the fewer faces of one die it may take
/// (see [skillRarityFaceLimits]), so a die can't be six of the same skill.
enum SkillRarity { common, uncommon, rare, epic, legendary }

/// Faces of one die a skill of each rarity may take.
const Map<SkillRarity, int> skillRarityFaceLimits = {
  SkillRarity.common: 3,
  SkillRarity.uncommon: 2,
  SkillRarity.rare: 2,
  SkillRarity.epic: 1,
  SkillRarity.legendary: 1,
};

/// [skill]'s rarity (skills.json `rarity`); a skill without one is rated
/// by its strength, its `cost`: 0–1 common, 2 uncommon, 3 rare, 4–5 epic,
/// 6 and up legendary.
SkillRarity skillRarity(Map<String, dynamic>? skill) {
  final named = skill?['rarity']?.toString() ?? '';
  for (final rarity in SkillRarity.values) {
    if (rarity.name == named) return rarity;
  }
  final cost = (skill?['cost'] as num?)?.toInt() ?? 0;
  if (cost <= 1) return SkillRarity.common;
  if (cost == 2) return SkillRarity.uncommon;
  if (cost == 3) return SkillRarity.rare;
  if (cost <= 5) return SkillRarity.epic;
  return SkillRarity.legendary;
}

/// The copies of one skill a die of [faceCount] faces may hold: one per
/// four slots from the d8 up (a d8 two, a d12 three, a d20 five), two on a
/// d6 so today's dice stay varied, one on a d4. Keeps a die from being the
/// same skill on every face.
int maxCopiesOnDie(int faceCount) =>
    faceCount == 6 ? 2 : max(1, faceCount ~/ 4);

/// Faces of one die [skill] may take: its rarity's limit, and on a die of
/// [faceCount] faces no more than [maxCopiesOnDie].
int maxFacesForSkill(Map<String, dynamic>? skill, {int? faceCount}) {
  final byRarity = skillRarityFaceLimits[skillRarity(skill)]!;
  return faceCount == null
      ? byRarity
      : min(byRarity, maxCopiesOnDie(faceCount));
}

/// The player's picks that hold on a die of [faces], face by face: a skill
/// already on as many faces as [maxFacesForSkill] allows (the die's own
/// signature and fixed faces left as they are counted first, then the picks
/// in face order) goes no further, and the faces past that do their own
/// action. An open face left as it is (Heavy Blow) doesn't count. Keeps a
/// save from before the limits to them.
Map<String, String> limitedFaceAssignments(
  List<Map<String, dynamic>> faces,
  Map<String, String> assignments,
  Map<String, dynamic> skills,
) {
  bool hasPick(int i) {
    final id = assignments[i.toString()];
    return id != null && id.isNotEmpty && isAssignableFace(faces[i]);
  }

  final counts = <String, int>{};
  for (var i = 0; i < faces.length; i++) {
    if (hasPick(i)) continue;
    final own = _ownCountedSkill(faces[i]);
    if (own != null) counts[own] = (counts[own] ?? 0) + 1;
  }
  final kept = <String, String>{};
  for (var i = 0; i < faces.length; i++) {
    if (!hasPick(i)) continue;
    final picked = assignments[i.toString()]!;
    final used = counts[picked] ?? 0;
    if (used >=
        maxFacesForSkill(skills[picked] as Map<String, dynamic>?,
            faceCount: faces.length)) {
      continue;
    }
    counts[picked] = used + 1;
    kept[i.toString()] = picked;
  }
  return kept;
}

/// Faces of a die of [faces] that count against [skillId]'s limit with
/// [assignments]: its fixed and signature faces left as they are and the
/// picks that hold, leaving out face [exceptIndex] when given.
int facesCastingSkill(
  String skillId,
  List<Map<String, dynamic>> faces,
  Map<String, String> assignments,
  Map<String, dynamic> skills, {
  int? exceptIndex,
}) {
  final kept = limitedFaceAssignments(faces, assignments, skills);
  var count = 0;
  for (var i = 0; i < faces.length; i++) {
    if (i == exceptIndex) continue;
    final counted = kept[i.toString()] ??
        (assignments[i.toString()]?.isNotEmpty == true &&
                isAssignableFace(faces[i])
            ? null
            : _ownCountedSkill(faces[i]));
    if (counted == skillId) count++;
  }
  return count;
}

/// Whether [skillId] may go on face [faceIndex]: an open face, and the
/// skill on fewer of the die's other faces than [maxFacesForSkill] allows
/// (its rarity, and one copy per four faces, two on a d6).
bool canSetSkillOnFace(
  String skillId,
  int faceIndex,
  List<Map<String, dynamic>> faces,
  Map<String, String> assignments,
  Map<String, dynamic> skills,
) {
  if (faceIndex < 0 ||
      faceIndex >= faces.length ||
      !isAssignableFace(faces[faceIndex])) {
    return false;
  }
  return facesCastingSkill(skillId, faces, assignments, skills,
          exceptIndex: faceIndex) <
      maxFacesForSkill(skills[skillId] as Map<String, dynamic>?,
          faceCount: faces.length);
}

/// Whether a skill on [face] works at [channeledSkillPower].
bool isBasicFace(Map<String, dynamic> face) =>
    basicFaceTypes.contains(face['type']?.toString() ?? '');

/// The skill [face] casts once the player's pick ([assignedSkillId]) is
/// applied, or null for a face that does a basic action.
String? faceSkillId(Map<String, dynamic> face, String? assignedSkillId) {
  if (assignedSkillId != null &&
      assignedSkillId.isNotEmpty &&
      isAssignableFace(face)) {
    return assignedSkillId;
  }
  if (face['type'] != 'Skill') return null;
  final linked = face['linkedSkillID']?.toString() ?? '';
  return linked.isEmpty ? 'heavy_attack' : linked;
}

/// The label key of a basic action.
String basicFaceLabelKey(String type) => switch (type) {
      'Attack' => 'face_attack_label',
      'Defend' => 'face_guard_label',
      'Heal' => 'face_heal_label',
      'Mana' => 'face_mana_label',
      _ => 'miss_label',
    };

/// A face's name: the skill it casts, or its basic action ("Attack",
/// "Guard", "Heal", "Mana", "Miss"). The die's own flavor name is not
/// shown -- a face is whatever skill it carries.
String faceDisplayName(
  Map<String, dynamic> face, {
  String? assignedSkillId,
  required AppLanguage language,
}) {
  final skillId = faceSkillId(face, assignedSkillId);
  if (skillId != null) return skillDisplayName(skillId, language: language);
  return trFor(language, basicFaceLabelKey(face['type']?.toString() ?? ''));
}

/// The same name for a rolled face.
String rolledFaceName(DiceFaceResult face, AppLanguage language) {
  if (face.type == 'Skill') {
    return skillDisplayName(
        face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID,
        language: language);
  }
  return trFor(language, basicFaceLabelKey(face.type));
}

/// Applies the player's skill pick to a rolled [face]: a skill face takes
/// the picked skill, a basic face channels it (see [channeledSkillPower]),
/// and a fixed face ignores it. [rawFace] is the die's face record, which
/// says whether the face is open. The result is named after what it does.
DiceFaceResult applyFaceAssignment(
  DiceFaceResult face,
  Map<String, dynamic>? rawFace,
  String? assignedSkillId, {
  AppLanguage language = AppLanguage.en,
}) {
  var result = face;
  final open = rawFace == null || isAssignableFace(rawFace);
  if (open && assignedSkillId != null && assignedSkillId.isNotEmpty) {
    if (face.type == 'Skill') {
      result = face.withLinkedSkillID(assignedSkillId);
    } else if (basicFaceTypes.contains(face.type)) {
      result = face.channeling(assignedSkillId);
    }
  }
  return result.withFaceName(rolledFaceName(result, language));
}

List<String> _idList(Map<String, dynamic>? record, String key) =>
    (record?[key] as List?)
        ?.map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList() ??
    const [];

/// The professions [die] is made for (dice.json `professions`); empty
/// means anyone.
List<String> dieProfessionIds(Map<String, dynamic>? die) =>
    _idList(die, 'professions');

/// The races [die] is made for (dice.json `races`); empty means anyone.
List<String> dieRaceIds(Map<String, dynamic>? die) => _idList(die, 'races');

/// Whether a character of [professionId] and [raceId] may buy and roll
/// [die]: a Mage's apprentice die is no use to a Warrior, a dwarf's stone
/// die no use to an elf.
bool dieUsableBy(Map<String, dynamic>? die,
    {required String professionId, required String raceId}) {
  final professions = dieProfessionIds(die);
  final races = dieRaceIds(die);
  return (professions.isEmpty || professions.contains(professionId)) &&
      (races.isEmpty || races.contains(raceId));
}

/// "Mage, Cleric": who [die] is made for, named from the localized
/// professions and races tables; '' for a die anyone can use.
String dieMadeForLabel(Map<String, dynamic>? die,
    Map<String, dynamic> professions, Map<String, dynamic> races) {
  final names = [
    for (final id in dieProfessionIds(die))
      (professions[id] as Map<String, dynamic>?)?['professionName']
              ?.toString() ??
          id,
    for (final id in dieRaceIds(die))
      (races[id] as Map<String, dynamic>?)?['raceName']?.toString() ?? id,
  ];
  return names.join(', ');
}

/// The signature skills [die] carries on its fixed skill faces. Whoever
/// holds the die can cast them, unlocked or not -- a bought die's Meteor
/// face works for a warrior too, instead of fizzling.
List<String> dieSignatureSkillIds(Map<String, dynamic>? die) {
  final faces = (die?['faces'] as List?)?.cast<Map<String, dynamic>>() ??
      const <Map<String, dynamic>>[];
  return [
    for (final face in faces)
      if (face['type'] == 'Skill' &&
          (isSignatureFace(face) || !isAssignableFace(face)))
        face['linkedSkillID'].toString(),
  ];
}

/// A die's name for the player: "iron_die" reads "Iron Die"; in French,
/// its name from [diceNamesFr].
/// Dice whose English name is not simply their id's words (see
/// [dieDisplayName]): the starting die is the old bone die from the blind
/// beggar's memory, the lucky charm the story's first fight reveals.
const Map<String, String> diceNamesEn = {'starter_die': 'Lucky Die'};

String dieDisplayName(String diceId, {AppLanguage language = AppLanguage.en}) {
  if (language == AppLanguage.fr) {
    final french = diceNamesFr[diceId];
    if (french != null) return french;
  }
  final english = diceNamesEn[diceId];
  if (english != null) return english;
  return diceId
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Every face of [die] by name, with its number where it has one:
/// "Attack 6 · Guard 5 · Heavy Attack · ...".
String dieFacesSummary(Map<String, dynamic>? die, AppLanguage language) {
  final faces = (die?['faces'] as List?)?.cast<Map<String, dynamic>>() ??
      const <Map<String, dynamic>>[];
  return faces.map((face) {
    final name = faceDisplayName(face, language: language);
    final value = (face['value'] as num?)?.toInt() ?? 0;
    return face['type'] == 'Skill' || value == 0 ? name : '$name $value';
  }).join(' · ');
}
