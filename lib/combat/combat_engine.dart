import 'dart:math';

class DiceFaceResult {
  const DiceFaceResult({
    required this.faceName,
    required this.type,
    required this.value,
    required this.linkedSkillID,
    required this.element,
  });

  final String faceName;
  final String type;
  final int value;
  final String linkedSkillID;
  final String element;
}

DiceFaceResult rollDie(List<Map<String, dynamic>> faces, Random random) {
  final weights = faces.map((f) => (f['weight'] as num?)?.toDouble() ?? 1.0).toList();
  final totalWeight = weights.fold<double>(0, (sum, w) => sum + w);

  var roll = totalWeight <= 0 ? 0.0 : random.nextDouble() * totalWeight;
  for (var i = 0; i < faces.length; i++) {
    roll -= weights[i];
    if (roll <= 0) {
      return _faceFromJson(faces[i]);
    }
  }
  return _faceFromJson(faces.last);
}

DiceFaceResult _faceFromJson(Map<String, dynamic> face) {
  return DiceFaceResult(
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
  int baseDamage,
) {
  switch (face.type) {
    case 'Attack':
      final damage = baseDamage + face.value;
      return PlayerActionResult(
        damageDealt: damage,
        healingDone: 0,
        blockAmount: 0,
        message: '${face.faceName}: you deal $damage damage.',
      );
    case 'Defend':
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: 0,
        blockAmount: face.value,
        message: '${face.faceName}: you brace for ${face.value} block.',
      );
    case 'Skill':
      final skill = skills[face.linkedSkillID] as Map<String, dynamic>?;
      if (skill == null) {
        return const PlayerActionResult(
          damageDealt: 0,
          healingDone: 0,
          blockAmount: 0,
          message: 'The skill fizzles.',
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
        message: '${face.faceName}: you recover ${face.value} HP.',
      );
    case 'Empty':
    default:
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: 0,
        blockAmount: 0,
        message: '${face.faceName.isEmpty ? 'Miss' : face.faceName}: nothing happens.',
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
}) {
  final moves = (enemy['skillMoves'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final healthPercent =
      enemyMaxHealth <= 0 ? 100.0 : (enemyCurrentHealth / enemyMaxHealth) * 100;
  final enemyName = enemy['enemyName']?.toString() ?? 'The enemy';
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
        message: skill['battleMessage']?.toString() ?? '$enemyName attacks!',
      );
    }
    break;
  }

  return EnemyMoveResult(damage: baseDamage, message: '$enemyName attacks!');
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
