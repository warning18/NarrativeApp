import 'dart:math';

import '../combat/gear_effects.dart';

/// Level-up perks (v1.163): every second level (2, 4, 6...) offers three
/// perks to choose one from, on top of the stat points. (One a level made
/// fights noticeably easier in the playthrough simulator; one every other
/// level keeps them where they were.) Most can be taken more
/// than once, up to their [PerkInfo.maxRank]; each rank adds the same again.
/// Perks are kept through permadeath, like levels and stats; a New Game+
/// starts without them.
enum Perk {
  steadyHands,
  apothecary,
  keenEye,
  lightFeet,
  heavyHand,
  ironHide,
  vigor,
  battleRhythm,
  plunderer,
  quickStudy,
  leader,
  deepWell,
  lastStand,
}

class PerkInfo {
  const PerkInfo(this.maxRank);

  final int maxRank;
}

const Map<Perk, PerkInfo> perkInfo = {
  Perk.steadyHands: PerkInfo(1),
  Perk.apothecary: PerkInfo(3),
  Perk.keenEye: PerkInfo(3),
  Perk.lightFeet: PerkInfo(3),
  Perk.heavyHand: PerkInfo(3),
  Perk.ironHide: PerkInfo(3),
  Perk.vigor: PerkInfo(3),
  Perk.battleRhythm: PerkInfo(1),
  Perk.plunderer: PerkInfo(3),
  Perk.quickStudy: PerkInfo(2),
  Perk.leader: PerkInfo(2),
  Perk.deepWell: PerkInfo(2),
  Perk.lastStand: PerkInfo(1),
};

Perk? perkFromName(String name) =>
    Perk.values.where((p) => p.name == name).firstOrNull;

/// The l10n keys naming and describing [perk].
String perkNameKey(Perk perk) => 'perk_${perk.name}';
String perkDescKey(Perk perk) => 'perk_${perk.name}_desc';

/// Per rank of each perk.
const int potionBonusPerRank = 10;
const double critPerRank = 5;
const double dodgePerRank = 4;
const int damagePerRank = 2;
const int armorPerRank = 2;
const int vigorHealthPerRank = 15;
const int goldPercentPerRank = 10;
const int xpPercentPerRank = 10;
const int leaderPercentPerRank = 5;
const int manaPerRank = 2;

/// How many perks a level-up offers to choose from.
const int perkOfferSize = 3;

/// What a set of perk ranks adds up to.
class PerkEffects {
  const PerkEffects({
    this.extraRolls = 0,
    this.potionBonus = 0,
    this.critChance = 0,
    this.dodgeChance = 0,
    this.attackDamage = 0,
    this.armor = 0,
    this.maxHealth = 0,
    this.momentumDrop = 0,
    this.goldPercent = 0,
    this.xpPercent = 0,
    this.allyDamagePercent = 0,
    this.maxMana = 0,
    this.secondWind = false,
  });

  static const PerkEffects none = PerkEffects();

  final int extraRolls;
  final int potionBonus;
  final double critChance;
  final double dodgeChance;
  final int attackDamage;
  final int armor;
  final int maxHealth;
  final int momentumDrop;
  final int goldPercent;
  final int xpPercent;
  final int allyDamagePercent;
  final int maxMana;
  final bool secondWind;

  int scaleGold(int gold) => gold * (100 + goldPercent) ~/ 100;
  int scaleXp(int xp) => xp * (100 + xpPercent) ~/ 100;
  int scaleAllyDamage(int damage) => damage * (100 + allyDamagePercent) ~/ 100;

  /// [gear] with the perks that act like gear laid over it: damage, armor,
  /// crit and dodge, and the last stand (a second wind).
  GearEffects over(GearEffects gear) => GearEffects(
        attackDamage: gear.attackDamage + attackDamage,
        armor: gear.armor + armor,
        critChance: gear.critChance + critChance,
        dodgeChance: gear.dodgeChance + dodgeChance,
        lifestealPercent: gear.lifestealPercent,
        thorns: gear.thorns,
        manaOnHit: gear.manaOnHit,
        secondWind: gear.secondWind || secondWind,
      );
}

PerkEffects perkEffectsFor(Map<String, int> ranks) {
  int rank(Perk perk) =>
      min(perkInfo[perk]!.maxRank, max(0, ranks[perk.name] ?? 0));
  return PerkEffects(
    extraRolls: rank(Perk.steadyHands),
    potionBonus: potionBonusPerRank * rank(Perk.apothecary),
    critChance: critPerRank * rank(Perk.keenEye),
    dodgeChance: dodgePerRank * rank(Perk.lightFeet),
    attackDamage: damagePerRank * rank(Perk.heavyHand),
    armor: armorPerRank * rank(Perk.ironHide),
    maxHealth: vigorHealthPerRank * rank(Perk.vigor),
    momentumDrop: rank(Perk.battleRhythm),
    goldPercent: goldPercentPerRank * rank(Perk.plunderer),
    xpPercent: xpPercentPerRank * rank(Perk.quickStudy),
    allyDamagePercent: leaderPercentPerRank * rank(Perk.leader),
    maxMana: manaPerRank * rank(Perk.deepWell),
    secondWind: rank(Perk.lastStand) > 0,
  );
}

/// Perks that can still be taken with [ranks].
List<Perk> perksAvailable(Map<String, int> ranks) => [
      for (final perk in Perk.values)
        if ((ranks[perk.name] ?? 0) < perkInfo[perk]!.maxRank) perk,
    ];

/// Up to [perkOfferSize] different perks still available, drawn at random.
List<Perk> rollPerkOffer(Map<String, int> ranks, Random random) =>
    (perksAvailable(ranks)..shuffle(random)).take(perkOfferSize).toList();

/// Levels that bring a perk to choose: every [perkLevelStep]th.
const int perkLevelStep = 2;

/// Perk picks a level-up from [levelBefore] to [levelAfter] brings: one per
/// perk level (see [perkLevelStep]) reached on the way.
int perkPicksFor(int levelBefore, int levelAfter) {
  var picks = 0;
  for (var level = max(1, levelBefore) + 1; level <= levelAfter; level++) {
    if (level % perkLevelStep == 0) picks++;
  }
  return picks;
}
