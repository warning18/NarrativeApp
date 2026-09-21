import 'dart:math';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import 'status_effect.dart';

/// Reads a skill or enemy-move record's `inflictsStatus`/`statusDuration`/
/// `statusMagnitude` fields into a [StatusEffect], or null if the record
/// doesn't inflict anything (the common case — most skills are plain
/// damage/heal). Shared by [resolvePlayerFace]'s Skill case and
/// [resolveEnemyMove] so both sides read the same three field names the
/// same way.
StatusEffect? _inflictedStatusFrom(Map<String, dynamic> record) {
  final type = statusEffectTypeFromString(record['inflictsStatus']?.toString());
  if (type == null) return null;
  final duration = (record['statusDuration'] as num?)?.toInt() ?? 0;
  if (duration <= 0) return null;
  return StatusEffect(
    type: type,
    remainingTurns: duration,
    magnitude: (record['statusMagnitude'] as num?)?.toInt() ?? 0,
  );
}

/// Maps an `element` value (as used on dice faces, skills, and enemy
/// moves — see [elementOptions] in `lib/gamedata/db_schema.dart`, kept in
/// sync with this map by hand since the schema layer deliberately doesn't
/// depend on gameplay code) to the item-field prefix items.json already
/// stores elemental gear bonuses under (e.g. `fireDmgBonus`/`fireResist`).
/// 'None' has no entry — it never earns a bonus or suffers a resist.
const Map<String, String> elementFieldPrefixes = {
  'Fire': 'fire',
  'Wind': 'wind',
  'Earth': 'earth',
  'Water': 'water',
  'Electricity': 'elec',
  'Void': 'void',
  'Ice': 'ice',
  'Light': 'light',
};

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
  final weights =
      faces.map((f) => (f['weight'] as num?)?.toDouble() ?? 1.0).toList();
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
    this.inflictedStatus,
  });

  final int damageDealt;
  final int healingDone;
  final int blockAmount;
  final String message;

  /// A status effect this face's skill inflicts on the enemy, if any —
  /// only Skill faces can carry one (see the skill's own
  /// `inflictsStatus`/`statusDuration`/`statusMagnitude` fields).
  final StatusEffect? inflictedStatus;
}

PlayerActionResult resolvePlayerFace(
  DiceFaceResult face,
  Map<String, dynamic> skills,
  int baseDamage, {
  AppLanguage language = AppLanguage.en,
  List<StatusEffect> activeEffects = const [],
  int wisdomHealBonus = 0,
}) {
  String t(String key) => trFor(language, key);
  switch (face.type) {
    case 'Attack':
      final damage = applyWeaken(baseDamage + face.value, activeEffects);
      return PlayerActionResult(
        damageDealt: damage,
        healingDone: 0,
        blockAmount: 0,
        message:
            '${face.faceName}: ${t('you_deal_prefix')} $damage ${t('damage_word')}.',
      );
    case 'Defend':
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: 0,
        blockAmount: face.value,
        message:
            '${face.faceName}: ${t('you_brace_prefix')} ${face.value} ${t('block_word')}.',
      );
    case 'Skill':
      final effectiveSkillId =
          face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID;
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
      final baseHealAmount = (skill['healAmount'] as num?)?.toInt() ?? 0;
      final healAmount =
          baseHealAmount > 0 ? baseHealAmount + wisdomHealBonus : 0;
      final damage = applyWeaken(
        ((baseDamage + damageMod) * multiplier).round(),
        activeEffects,
      );
      final flavor = skill['battleMessage']?.toString() ?? '${face.faceName}!';
      // Standard dice faces (Attack/Defend/Heal) always spell out the exact
      // numbers in their preview message; skill faces should be no
      // different, on top of whatever flavor text the skill defines.
      final statParts = <String>[
        if (damage > 0) '${t('you_deal_prefix')} $damage ${t('damage_word')}',
        if (healAmount > 0)
          '${t('you_recover_prefix')} $healAmount ${t('hp_label')}',
      ];
      final message =
          statParts.isEmpty ? flavor : '$flavor ${statParts.join(', ')}.';
      return PlayerActionResult(
        damageDealt: damage,
        healingDone: healAmount,
        blockAmount: 0,
        message: message,
        inflictedStatus: _inflictedStatusFrom(skill),
      );
    case 'Heal':
      final healAmount = face.value + wisdomHealBonus;
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: healAmount,
        blockAmount: 0,
        message:
            '${face.faceName}: ${t('you_recover_prefix')} $healAmount ${t('hp_label')}.',
      );
    case 'Empty':
    default:
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: 0,
        blockAmount: 0,
        message:
            '${face.faceName.isEmpty ? t('miss_label') : face.faceName}: ${t('nothing_happens')}',
      );
  }
}

class EnemyMoveResult {
  const EnemyMoveResult({
    required this.damage,
    required this.message,
    this.inflictedStatus,
    this.element = 'None',
  });

  final int damage;
  final String message;

  /// A status effect this move inflicts on its target, if any — read from
  /// the referenced skill's own `inflictsStatus` fields; a move with no
  /// `skillID` (a plain attack) never inflicts one.
  final StatusEffect? inflictedStatus;

  /// The element this move hits with — the referenced skill's own
  /// `element` field, or 'None' for a plain base attack. Lets the caller
  /// apply the target's matching `<prefix>Resist` gear bonus the same way
  /// it already applies armor/block.
  final String element;
}

EnemyMoveResult resolveEnemyMove({
  required Map<String, dynamic> enemy,
  required Map<String, dynamic> skills,
  required int enemyCurrentHealth,
  required int enemyMaxHealth,
  required Random random,
  AppLanguage language = AppLanguage.en,
  List<StatusEffect> activeEffects = const [],
  Set<String> elementsHitThisRound = const {},
}) {
  String t(String key) => trFor(language, key);
  final moves =
      (enemy['skillMoves'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final healthPercent =
      enemyMaxHealth <= 0 ? 100.0 : (enemyCurrentHealth / enemyMaxHealth) * 100;
  final enemyName = enemy['enemyName']?.toString() ?? t('the_enemy_label');
  final baseDamage = (enemy['damage'] as num?)?.toInt() ?? 0;

  final sortedMoves = [...moves]..sort((a, b) {
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
      case 'OnHitByElement':
        matches = elementsHitThisRound
            .contains(move['requiredElement']?.toString() ?? '');
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
      final damage = applyWeaken(
        (baseDamage + (damageMod * multiplier)).round(),
        activeEffects,
      );
      return EnemyMoveResult(
        damage: damage,
        message: skill['battleMessage']?.toString() ??
            '$enemyName ${t('attacks_suffix')}',
        inflictedStatus: _inflictedStatusFrom(skill),
        element: skill['element']?.toString() ?? 'None',
      );
    }
    break;
  }

  return EnemyMoveResult(
      damage: applyWeaken(baseDamage, activeEffects),
      message: '$enemyName ${t('attacks_suffix')}');
}

/// Skill tiers run 0 (just unlocked, base numbers) through [maxSkillTier]
/// (fully upgraded). Each tier above 0 costs [skillTierUpgradeCost] essence.
const int maxSkillTier = 3;

/// Cost, in skill essence, to go from [currentTier] to `currentTier + 1`.
/// Rising cost per tier (3/6/9) makes maxing out one skill a real
/// commitment rather than something every skill gets by mid-run.
int skillTierUpgradeCost(int currentTier) => (currentTier + 1) * 3;

/// Returns a copy of [skill] with its combat numbers boosted for [tier] —
/// +25% damageMod/healAmount and +0.1 damageMultiplier per tier. Never
/// mutates the shared skills-db record itself (enemies read from the same
/// table via their own skillID references), so callers apply this to a
/// per-actor copy right before resolving a face, not to the db in place.
Map<String, dynamic> applySkillTier(Map<String, dynamic> skill, int tier) {
  if (tier <= 0) return skill;
  final damageMod = (skill['damageMod'] as num?)?.toInt() ?? 0;
  final healAmount = (skill['healAmount'] as num?)?.toInt() ?? 0;
  final multiplier = (skill['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
  return {
    ...skill,
    'damageMod': (damageMod * (1 + 0.25 * tier)).round(),
    'healAmount': (healAmount * (1 + 0.25 * tier)).round(),
    'damageMultiplier': multiplier + 0.1 * tier,
  };
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

/// Percentage-point drop-rate bonus (same units as the flat luck bonus a
/// win's loot roll already adds) for a loot item whose own `scalingStat`
/// matches the player's profession's `preferredScalingStat` — a Mage sees
/// noticeably more staves than a Warrior would off the exact same enemy,
/// without any single drop ever becoming guaranteed. 0 for a non-matching
/// item, an item with no scalingStat, or a profession with no affinity
/// (e.g. Cleric, whose dominant stat is Wisdom, which nothing scales
/// with).
int professionLootAffinityBonus(
  Map<String, dynamic>? item,
  String preferredScalingStat,
) {
  if (preferredScalingStat.isEmpty) return 0;
  final itemScalingStat = item?['scalingStat']?.toString() ?? '';
  return itemScalingStat == preferredScalingStat ? 20 : 0;
}
