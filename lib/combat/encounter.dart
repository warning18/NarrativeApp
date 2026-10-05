import 'dart:math';

import '../models/story_node.dart';
import 'battlefield_condition.dart';
import 'combat_engine.dart' show zoneTierMultiplier;
import 'enemy_affix.dart';
import 'loot_box.dart';

/// Per-encounter overrides a caller hands FightScreen alongside the enemy
/// records themselves -- a hunt's named quarry with its forced affixes and
/// guaranteed Gold chest, or an alignment hunter's Silver floor. The
/// default ([EncounterModifiers.none]) is every fight the game ran before
/// these existed: affixes and the chest tier roll normally.
/// A road champion's health over an ordinary Elite's (road_events.dart):
/// with it, a champion lasts about half again as long as a story fight
/// (the playthrough simulator, v1.177).
const double championHealthMultiplier = 1.25;

/// The share of the first enemy's health the lucky die's sign takes when
/// it rolls loose in the story's first fight (see
/// [EncounterModifiers.luckyDieReveal]).
const double luckyDieStrikeShare = 0.4;

/// The most of the player's health the opening blow of the lucky die's
/// fight can take: a first wound, never a crippling one.
const double luckyDieBlowShare = 0.2;

/// The enemy's opening blow in the lucky die's fight: its own damage, at
/// most [luckyDieBlowShare] of the player's health, and never enough to
/// knock them down.
int luckyDieOpeningBlow({
  required int enemyDamage,
  required int playerHealth,
  required int playerMaxHealth,
}) {
  final cap = max(1, (playerMaxHealth * luckyDieBlowShare).round());
  return max(0, min(min(enemyDamage, cap), playerHealth - 1));
}

/// What the lucky die's sign takes off an enemy of [enemyMaxHealth].
int luckyDieStrike(int enemyMaxHealth) =>
    max(1, (enemyMaxHealth * luckyDieStrikeShare).round());

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
    this.forcedCondition,
    this.forceElite = false,
    this.keepWounds = false,
    this.tutorial = false,
    this.luckyDieReveal = false,
    this.hostFight = false,
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

  /// The battlefield condition this fight is forced into (a sneak gone
  /// wrong is an ambush), instead of rolling one.
  final BattlefieldCondition? forcedCondition;

  /// A lone enemy that is Elite for certain (a road event's champion, see
  /// road_events.dart), instead of rolling for it.
  final bool forceElite;

  /// A link in a no-healing chain (see [StoryChoice.noHeal]): a level-up,
  /// a potion from the spoils chest or a sign does not mend the party
  /// after it, and a loss leaves the player's wounds as they are.
  final bool keepWounds;

  /// A lesson (see [StoryChoice.tutorialFight]): never Elite, no affixes,
  /// no battlefield condition and no threat.
  final bool tutorial;

  /// The first fight's lucky die (see [StoryChoice.luckyDieReveal]).
  final bool luckyDieReveal;

  /// One of the last battles (v1.196, a `hostFight` choice's fight or its
  /// zone's): the Host the character raised fights beside the party (see
  /// throne.dart's hostEffects).
  final bool hostFight;

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
      !isTest &&
      forcedCondition == null &&
      !forceElite &&
      !keepWounds &&
      !tutorial &&
      !luckyDieReveal &&
      !hostFight;

  /// The same modifiers stamped with a fight's chapter and/or zone-tier
  /// multiplier (an expedition applies its zone's to every draw), or made
  /// one of the last battles ([hostFight]).
  EncounterModifiers copyWith(
          {int? chapter, double? difficultyMultiplier, bool? hostFight}) =>
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
        forcedCondition: forcedCondition,
        forceElite: forceElite,
        keepWounds: keepWounds,
        tutorial: tutorial,
        luckyDieReveal: luckyDieReveal,
        hostFight: hostFight ?? this.hostFight,
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
  /// A choice marked [StoryChoice.hostFight] makes its fight one of the
  /// last battles.
  factory EncounterModifiers.fromChoice(StoryChoice choice) {
    final modifiers = EncounterModifiers._ofChoice(choice);
    return choice.hostFight ? modifiers.copyWith(hostFight: true) : modifiers;
  }

  factory EncounterModifiers._ofChoice(StoryChoice choice) {
    // What any choice may carry whatever its fight's kind (v1.201.2): the
    // loss branch, a forced condition, kept wounds, the lesson and the
    // lucky die's reveal hold for a road's champion, an ambush and a hunt
    // too (a hunt with a loss branch is no permadeath).
    final own = EncounterModifiers(
      lossContinues: choice.hasLossBranch,
      forcedCondition: battlefieldConditionFromName(choice.forcedCondition),
      keepWounds: choice.noHeal,
      tutorial: choice.tutorialFight,
      luckyDieReveal: choice.luckyDieReveal,
    );
    if (choice.roadEvent == 'elite') {
      // A road's champion (road_events.dart): an Elite a quarter tougher
      // still, and an ambush when the party failed to slip past it.
      return own._asKind(
        forceElite: true,
        chestTierFloor: ChestTier.silver,
        rewardMultiplier: 1.25,
        healthMultiplier: championHealthMultiplier,
      );
    }
    if (choice.isHunterAmbush) {
      return own._asKind(
        chestTierFloor: ChestTier.silver,
        rewardMultiplier: 1.25,
        isHunterAmbush: true,
      );
    }
    final huntName = choice.huntName;
    if (huntName != null && huntName.isNotEmpty) {
      return own._asKind(
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
    return own.isDefault ? none : own;
  }

  /// These modifiers made a fight of one kind (a champion, an ambush, a
  /// hunt), keeping what the choice itself carries.
  EncounterModifiers _asKind({
    List<EnemyAffix>? forcedAffixes,
    String? namedEnemyName,
    ChestTier? chestTierFloor,
    double? rewardMultiplier,
    double? healthMultiplier,
    bool? isHunt,
    bool? isHunterAmbush,
    bool? forceElite,
  }) =>
      EncounterModifiers(
        forcedAffixes: forcedAffixes ?? this.forcedAffixes,
        namedEnemyName: namedEnemyName ?? this.namedEnemyName,
        chestTierFloor: chestTierFloor ?? this.chestTierFloor,
        rewardMultiplier: rewardMultiplier ?? this.rewardMultiplier,
        healthMultiplier: healthMultiplier ?? this.healthMultiplier,
        difficultyMultiplier: difficultyMultiplier,
        chapter: chapter,
        isHunt: isHunt ?? this.isHunt,
        isHunterAmbush: isHunterAmbush ?? this.isHunterAmbush,
        isZoneBoss: isZoneBoss,
        lossContinues: lossContinues,
        isTest: isTest,
        forcedCondition: forcedCondition,
        forceElite: forceElite ?? this.forceElite,
        keepWounds: keepWounds,
        tutorial: tutorial,
        luckyDieReveal: luckyDieReveal,
        hostFight: hostFight,
      );
}
