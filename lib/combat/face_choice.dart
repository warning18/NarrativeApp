/// The skill choice helper (C): what setting a skill on one face of a die
/// would change, for the dice screen to say before the player commits.
/// The face is resolved the way a fight resolves it (applyFaceAssignment,
/// then resolvePlayerFace, with no critical), once as it is and once with
/// the candidate, so the numbers are the fight's own.
library;

import 'combat_engine.dart';
import 'dice_faces.dart';

/// What one face does when it lands (no critical, no status on the party).
class FaceOutput {
  const FaceOutput({
    this.skillId,
    this.damage = 0,
    this.heal = 0,
    this.block = 0,
    this.mana = 0,
    this.status,
  });

  /// The skill the face casts, or null for a basic action.
  final String? skillId;
  final int damage;
  final int heal;
  final int block;
  final int mana;

  /// The status it inflicts, if any (its StatusEffectType's name).
  final String? status;

  /// One number to compare two faces by, weighted as the playthrough
  /// simulator weighs skills (sim_growth.dart's simSkillScore): damage,
  /// then healing at 0.7, a guard at 0.5, mana at 2 a point, and 1 for a
  /// status (a point of damage on the fight's small scale).
  double get score =>
      damage + heal * 0.7 + block * 0.5 + mana * 2 + (status == null ? 0 : 1);
}

/// Whether the candidate helps, hurts, or changes nothing (see
/// [FaceSkillChoice.delta]).
enum FaceChoiceEffect { gain, loss, same }

/// Why the candidate can't go on the face.
enum FaceChoiceBlock {
  /// The face is fixed, or a skill face of the die's own.
  notOpen,

  /// The candidate is already on this face.
  alreadyThere,

  /// The candidate is already on as many of the die's other faces as its
  /// rarity allows ([FaceSkillChoice.usedFaces] of [maxFaces]).
  rarityLimit,
}

/// What setting [candidateId] on face [faceIndex] would do.
class FaceSkillChoice {
  const FaceSkillChoice({
    required this.faceIndex,
    required this.candidateId,
    required this.before,
    required this.after,
    required this.usedFaces,
    required this.maxFaces,
    this.block,
  });

  final int faceIndex;
  final String candidateId;

  /// The face as it is now, and with the candidate on it.
  final FaceOutput before;
  final FaceOutput after;

  /// The die's other faces already casting the candidate, and how many its
  /// rarity allows.
  final int usedFaces;
  final int maxFaces;

  /// Why it can't be set, or null when it can.
  final FaceChoiceBlock? block;

  bool get allowed => block == null;

  /// The candidate already fills every face its rarity allows.
  bool get full => usedFaces >= maxFaces;

  /// The change in [FaceOutput.score].
  double get delta => after.score - before.score;

  FaceChoiceEffect get effect => delta.abs() < 0.05
      ? FaceChoiceEffect.same
      : delta > 0
          ? FaceChoiceEffect.gain
          : FaceChoiceEffect.loss;
}

/// What face [faceIndex] of a die of [faces] does with [skillId] on it
/// (null: as the die has it), for a party dealing [baseDamage].
FaceOutput faceOutputWith(
  List<Map<String, dynamic>> faces,
  int faceIndex,
  String? skillId,
  Map<String, dynamic> skills, {
  required int baseDamage,
  int armor = 0,
}) {
  final raw = faces[faceIndex];
  final face = applyFaceAssignment(faceFromJson(raw, faceIndex), raw, skillId);
  final result = resolvePlayerFace(face, skills, baseDamage, armor: armor);
  final status = result.inflictedStatus;
  return FaceOutput(
    skillId: face.type == 'Skill'
        ? (face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID)
        : null,
    damage: result.damageDealt,
    heal: result.healingDone,
    block: result.blockAmount,
    mana: result.manaGained,
    status: status?.type.name,
  );
}

/// What setting [candidateId] on face [faceIndex] would do, given the
/// die's [faces], the player's [assignments] (face index -> skill id) and
/// the [skills] table (each at the tier the player fights it at, see
/// applySkillTier): before and after, the gain or loss, the rarity limit,
/// and why it can't be set if it can't.
FaceSkillChoice faceSkillChoice({
  required List<Map<String, dynamic>> faces,
  required Map<String, String> assignments,
  required int faceIndex,
  required String candidateId,
  required Map<String, dynamic> skills,
  required int baseDamage,
  int armor = 0,
}) {
  final kept = limitedFaceAssignments(faces, assignments, skills);
  final current = kept['$faceIndex'];
  final before = faceOutputWith(faces, faceIndex, current, skills,
      baseDamage: baseDamage, armor: armor);
  final after = faceOutputWith(faces, faceIndex, candidateId, skills,
      baseDamage: baseDamage, armor: armor);
  final used = facesCastingSkill(candidateId, faces, assignments, skills,
      exceptIndex: faceIndex);
  final max = maxFacesForSkill(skills[candidateId] as Map<String, dynamic>?,
      faceCount: faces.length);
  final FaceChoiceBlock? block;
  if (!isAssignableFace(faces[faceIndex])) {
    block = FaceChoiceBlock.notOpen;
  } else if (current == candidateId) {
    block = FaceChoiceBlock.alreadyThere;
  } else if (used >= max) {
    block = FaceChoiceBlock.rarityLimit;
  } else {
    block = null;
  }
  return FaceSkillChoice(
    faceIndex: faceIndex,
    candidateId: candidateId,
    before: before,
    after: block == FaceChoiceBlock.notOpen ? before : after,
    usedFaces: used,
    maxFaces: max,
    block: block,
  );
}
