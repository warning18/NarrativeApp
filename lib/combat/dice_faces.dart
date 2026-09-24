import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import 'combat_engine.dart';

/// How strongly a skill works when it is set on a basic face (Attack,
/// Guard, Heal) instead of a skill face: its damage and healing are scaled
/// by this, never below what the face itself would have done. A skill face
/// casts at full power. Keeps every face open to skills without letting a
/// die of six top skills outclass the dice built around them.
const double channeledSkillPower = channeledPower;

/// The basic actions a face can carry on its own.
const Set<String> basicFaceTypes = {'Attack', 'Defend', 'Heal'};

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

/// A skill's name for the player, built from its id.
String skillDisplayName(String skillId) {
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

/// Whether the player may set a skill on [face]. Open: skill faces with no
/// skill of their own or the generic Heavy Attack, and every basic face.
/// Fixed: a skill face's signature skill, Mana and blank faces, and any
/// face the die marks `fixed`.
bool isAssignableFace(Map<String, dynamic> face) {
  if (face['fixed'] == true) return false;
  final type = face['type']?.toString() ?? '';
  final linked = face['linkedSkillID']?.toString() ?? '';
  if (type == 'Skill') return linked.isEmpty || linked == 'heavy_attack';
  return basicFaceTypes.contains(type);
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
  if (skillId != null) return skillDisplayName(skillId);
  return trFor(language, basicFaceLabelKey(face['type']?.toString() ?? ''));
}

/// The same name for a rolled face.
String rolledFaceName(DiceFaceResult face, AppLanguage language) {
  if (face.type == 'Skill') {
    return skillDisplayName(
        face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID);
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

/// The signature skills [die] carries on its fixed skill faces. Whoever
/// holds the die can cast them, unlocked or not -- a bought die's Meteor
/// face works for a warrior too, instead of fizzling.
List<String> dieSignatureSkillIds(Map<String, dynamic>? die) {
  final faces = (die?['faces'] as List?)?.cast<Map<String, dynamic>>() ??
      const <Map<String, dynamic>>[];
  return [
    for (final face in faces)
      if (face['type'] == 'Skill' && !isAssignableFace(face))
        face['linkedSkillID'].toString(),
  ];
}

/// A die's name for the player: "iron_die" reads "Iron Die".
String dieDisplayName(String diceId) => diceId
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

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
