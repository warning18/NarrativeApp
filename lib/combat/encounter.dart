import '../models/story_node.dart';
import 'combat_engine.dart' show zoneTierMultiplier;
import 'enemy_affix.dart';
import 'loot_box.dart';

/// Per-encounter overrides a caller hands FightScreen alongside the enemy
/// records themselves -- a hunt's named quarry with its forced affixes and
/// guaranteed Gold chest, or an alignment hunter's Silver floor. The
/// default ([EncounterModifiers.none]) is every fight the game ran before
/// these existed: affixes and the chest tier roll normally.
class EncounterModifiers {
  const EncounterModifiers({
    this.forcedAffixes = const [],
    this.namedEnemyName,
    this.chestTierFloor,
    this.rewardMultiplier = 1.0,
    this.healthMultiplier = 1.0,
    this.difficultyMultiplier = 1.0,
    this.chapter,
    this.isHunt = false,
    this.isHunterAmbush = false,
    this.isZoneBoss = false,
    this.lossContinues = false,
    this.isTest = false,
  });

  static const EncounterModifiers none = EncounterModifiers();

  /// Affixes forced onto the FIRST enemy of the fight (the named quarry);
  /// empty rolls affixes normally for every enemy.
  final List<EnemyAffix> forcedAffixes;

  /// A display name replacing the first enemy's own ("Merrick the
  /// Half-Faced" over "Street Bandit").
  final String? namedEnemyName;

  /// The spoils chest is never below this tier.
  final ChestTier? chestTierFloor;

  /// Gold/XP multiplier on every defeated enemy's reward.
  final double rewardMultiplier;

  /// Max-health multiplier on the first enemy (a hunt's quarry is a
  /// tougher specimen of its kind).
  final double healthMultiplier;

  /// Health AND damage multiplier on every enemy of the fight -- a zone's
  /// tier (see [zoneTierMultiplier]); stacks with the chapter curve.
  final double difficultyMultiplier;

  /// The story chapter this fight belongs to, for the chapter difficulty
  /// curve and the chest's loot window; null derives it from the current
  /// story node (every fight launched from the story itself).
  final int? chapter;

  /// A hunt's named-variant fight (see SubNodeEngine's hunt chain).
  final bool isHunt;

  /// An alignment hunter's ambush (see alignment_events.dart).
  final bool isHunterAmbush;

  /// A zone's boss fight, guarding the zone's banked reward (see
  /// ExpeditionScreen and zones.json's `bossEnemyId`).
  final bool isZoneBoss;

  /// A story fight with a defeat branch (see [StoryChoice.loseNextId]):
  /// losing is a scene, not a retreat, and the end button says so.
  final bool lossContinues;

  /// An Edit Mode test fight (see FightLabScreen): a loss never runs the
  /// permadeath flow, whatever the setting.
  final bool isTest;

  bool get isDefault =>
      forcedAffixes.isEmpty &&
      namedEnemyName == null &&
      chestTierFloor == null &&
      rewardMultiplier == 1.0 &&
      healthMultiplier == 1.0 &&
      difficultyMultiplier == 1.0 &&
      chapter == null &&
      !isHunt &&
      !isHunterAmbush &&
      !isZoneBoss &&
      !lossContinues &&
      !isTest;

  /// The same modifiers stamped with a fight's chapter and/or zone-tier
  /// multiplier (an expedition applies its zone's to every draw).
  EncounterModifiers copyWith({int? chapter, double? difficultyMultiplier}) =>
      EncounterModifiers(
        forcedAffixes: forcedAffixes,
        namedEnemyName: namedEnemyName,
        chestTierFloor: chestTierFloor,
        rewardMultiplier: rewardMultiplier,
        healthMultiplier: healthMultiplier,
        difficultyMultiplier: difficultyMultiplier ?? this.difficultyMultiplier,
        chapter: chapter ?? this.chapter,
        isHunt: isHunt,
        isHunterAmbush: isHunterAmbush,
        isZoneBoss: isZoneBoss,
        lossContinues: lossContinues,
        isTest: isTest,
      );

  /// A zone boss: never below a Gold chest, half again the reward, at the
  /// zone's own chapter and tier.
  factory EncounterModifiers.zoneBoss({
    required int chapter,
    double difficultyMultiplier = 1.0,
  }) =>
      EncounterModifiers(
        chestTierFloor: ChestTier.gold,
        rewardMultiplier: 1.5,
        difficultyMultiplier: difficultyMultiplier,
        chapter: chapter,
        isZoneBoss: true,
      );

  /// The modifiers a generated story choice carries (see
  /// [StoryChoice.huntName] and friends); [none] for an ordinary choice.
  factory EncounterModifiers.fromChoice(StoryChoice choice) {
    if (choice.isHunterAmbush) {
      return const EncounterModifiers(
        chestTierFloor: ChestTier.silver,
        rewardMultiplier: 1.25,
        isHunterAmbush: true,
      );
    }
    final huntName = choice.huntName;
    if (huntName != null && huntName.isNotEmpty) {
      return EncounterModifiers(
        forcedAffixes: [
          for (final name in choice.huntAffixes)
            if (affixFromName(name) != null) affixFromName(name)!,
        ],
        namedEnemyName: huntName,
        chestTierFloor: chestTierFromName(choice.chestFloor) ?? ChestTier.gold,
        rewardMultiplier: 1.5,
        healthMultiplier: 1.2,
        isHunt: true,
      );
    }
    if (choice.hasLossBranch) {
      return const EncounterModifiers(lossContinues: true);
    }
    return none;
  }
}
