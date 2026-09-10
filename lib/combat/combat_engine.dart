import 'dart:math';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';

class DiceFaceResult {
  const DiceFaceResult({
    required this.faceIndex,
    required this.faceName,
    required this.type,
    required this.value,
    required this.linkedSkillID,
    required this.element,
  });

  final int faceIndex;
  final String faceName;
  final String type;
  final int value;
  final String linkedSkillID;
  final String element;

  DiceFaceResult withLinkedSkillID(String linkedSkillID) => DiceFaceResult(
        faceIndex: faceIndex,
        faceName: faceName,
        type: type,
        value: value,
        linkedSkillID: linkedSkillID,
        element: element,
      );
}

DiceFaceResult rollDie(List<Map<String, dynamic>> faces, Random random) {
  final weights = faces.map((f) => (f['weight'] as num?)?.toDouble() ?? 1.0).toList();
  final totalWeight = weights.fold<double>(0, (sum, w) => sum + w);

  var roll = totalWeight <= 0 ? 0.0 : random.nextDouble() * totalWeight;
  for (var i = 0; i < faces.length; i++) {
    roll -= weights[i];
    if (roll <= 0) {
      return _faceFromJson(faces[i], i);
    }
  }
  return _faceFromJson(faces.last, faces.length - 1);
}

DiceFaceResult _faceFromJson(Map<String, dynamic> face, int index) {
  return DiceFaceResult(
    faceIndex: index,
    faceName: face['faceName']?.toString() ?? '',
    type: face['type']?.toString() ?? 'Empty',
    value: (face['value'] as num?)?.toInt() ?? 0,
    linkedSkillID: face['linkedSkillID']?.toString() ?? '',
    element: face['element']?.toString() ?? 'None',
  );
}

class PlayerActionResult {
  const PlayerActionResult({
    required this.damageDealt,
    required this.healingDone,
    required this.blockAmount,
    required this.message,
  });

  final int damageDealt;
  final int healingDone;
  final int blockAmount;
  final String message;
}

PlayerActionResult resolvePlayerFace(
  DiceFaceResult face,
  Map<String, dynamic> skills,
  int baseDamage, {
  AppLanguage language = AppLanguage.en,
}) {
  String t(String key) => trFor(language, key);
  switch (face.type) {
    case 'Attack':
      final damage = baseDamage + face.value;
      return PlayerActionResult(
        damageDealt: damage,
        healingDone: 0,
        blockAmount: 0,
        message: '${face.faceName}: ${t('you_deal_prefix')} $damage ${t('damage_word')}.',
      );
    case 'Defend':
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: 0,
        blockAmount: face.value,
        message: '${face.faceName}: ${t('you_brace_prefix')} ${face.value} ${t('block_word')}.',
      );
    case 'Skill':
      final effectiveSkillId = face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID;
      final skill = skills[effectiveSkillId] as Map<String, dynamic>?;
      if (skill == null) {
        return PlayerActionResult(
          damageDealt: 0,
          healingDone: 0,
          blockAmount: 0,
          message: t('skill_fizzles'),
        );
      }
      final damageMod = (skill['damageMod'] as num?)?.toInt() ?? 0;
      final multiplier = (skill['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
      final healAmount = (skill['healAmount'] as num?)?.toInt() ?? 0;
      final damage = ((baseDamage + damageMod) * multiplier).round();
      return PlayerActionResult(
        damageDealt: damage,
        healingDone: healAmount,
        blockAmount: 0,
        message: skill['battleMessage']?.toString() ?? '${face.faceName}!',
      );
    case 'Heal':
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: face.value,
        blockAmount: 0,
        message: '${face.faceName}: ${t('you_recover_prefix')} ${face.value} ${t('hp_label')}.',
      );
    case 'Empty':
    default:
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: 0,
        blockAmount: 0,
        message: '${face.faceName.isEmpty ? t('miss_label') : face.faceName}: ${t('nothing_happens')}',
      );
  }
}

class EnemyMoveResult {
  const EnemyMoveResult({required this.damage, required this.message});

  final int damage;
  final String message;
}

EnemyMoveResult resolveEnemyMove({
  required Map<String, dynamic> enemy,
  required Map<String, dynamic> skills,
  required int enemyCurrentHealth,
  required int enemyMaxHealth,
  required Random random,
  AppLanguage language = AppLanguage.en,
}) {
  String t(String key) => trFor(language, key);
  final moves = (enemy['skillMoves'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final healthPercent =
      enemyMaxHealth <= 0 ? 100.0 : (enemyCurrentHealth / enemyMaxHealth) * 100;
  final enemyName = enemy['enemyName']?.toString() ?? t('the_enemy_label');
  final baseDamage = (enemy['damage'] as num?)?.toInt() ?? 0;

  final sortedMoves = [...moves]
    ..sort((a, b) {
      final priorityA = (a['priority'] as num?)?.toInt() ?? 0;
      final priorityB = (b['priority'] as num?)?.toInt() ?? 0;
      return priorityB.compareTo(priorityA);
    });

  for (final move in sortedMoves) {
    final condition = move['condition']?.toString() ?? 'Always';
    final chance = (move['chance'] as num?)?.toDouble() ?? 100;
    final healthThreshold = (move['healthThreshold'] as num?)?.toDouble() ?? 0;

    bool matches;
    switch (condition) {
      case 'Always':
        matches = true;
        break;
      case 'Chance':
        matches = random.nextDouble() * 100 <= chance;
        break;
      case 'OnLowHealth':
        matches = healthPercent <= healthThreshold;
        break;
      default:
        matches = false;
        break;
    }

    if (!matches) continue;

    final skillId = move['skillID']?.toString() ?? '';
    if (skillId.isNotEmpty && skills.containsKey(skillId)) {
      final skill = skills[skillId] as Map<String, dynamic>;
      final damageMod = (skill['damageMod'] as num?)?.toInt() ?? 0;
      final multiplier = (skill['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
      final damage = (baseDamage + (damageMod * multiplier)).round();
      return EnemyMoveResult(
        damage: damage,
        message: skill['battleMessage']?.toString() ?? '$enemyName ${t('attacks_suffix')}',
      );
    }
    break;
  }

  return EnemyMoveResult(damage: baseDamage, message: '$enemyName ${t('attacks_suffix')}');
}

int scaledMaxHealth(int base, int playerLevel) {
  return (base * (1 + 0.12 * (playerLevel - 1))).round();
}

int scaledDamage(int base, int playerLevel) {
  return (base * (1 + 0.08 * (playerLevel - 1))).round();
}

int scaledReward(int base, int playerLevel) {
  return (base * (1 + 0.10 * (playerLevel - 1))).round();
}
