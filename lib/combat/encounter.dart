import '../models/story_node.dart';
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
    this.isHunt = false,
    this.isHunterAmbush = false,
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

  /// A hunt's named-variant fight (see SubNodeEngine's hunt chain).
  final bool isHunt;

  /// An alignment hunter's ambush (see alignment_events.dart).
  final bool isHunterAmbush;

  bool get isDefault =>
      forcedAffixes.isEmpty &&
      namedEnemyName == null &&
      chestTierFloor == null &&
      rewardMultiplier == 1.0 &&
      healthMultiplier == 1.0 &&
      !isHunt &&
      !isHunterAmbush;

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
    return none;
  }
}
