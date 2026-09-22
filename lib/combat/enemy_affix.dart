import 'dart:math';

import 'combat_engine.dart';

/// A one-word modifier an enemy can spawn with, changing how the fight
/// plays without touching the enemy's own tuned record -- the same idea as
/// an Elite promotion, but varied: two Harbor Rats with different affixes
/// are two different fights. Rolled per enemy in
/// [rollEncounterAffixes]; applied by FightScreen's turn loop.
enum EnemyAffix {
  /// Its plain attacks poison whoever they hit.
  venomous,

  /// Shrugs off the first few points of every Attack-face hit -- Skill
  /// faces cut straight through.
  armored,

  /// Flees the fight once badly hurt, taking part of the spoils with it.
  skittish,

  /// Hits far harder once below half health.
  frenzied,

  /// Pack fights only: while it stands, every other pack member hits
  /// harder. Kill it first.
  packLeader,
}

/// Odds a solo, non-boss, non-Elite enemy spawns with one affix.
const double affixChanceSolo = 0.20;

/// Odds each member of a pack spawns with one affix, rolled independently.
const double affixChancePackMember = 0.15;

/// Flat damage an [EnemyAffix.armored] enemy ignores from each Attack face
/// (never below 1 damage dealt).
const int armoredFlatReduction = 4;

/// The health fraction under which an [EnemyAffix.skittish] enemy flees at
/// the end of a party round.
const double skittishFleeThreshold = 0.25;

/// Reward share (gold/XP) a fled Skittish enemy still yields.
const double skittishFledRewardShare = 0.5;

/// Damage multiplier for an [EnemyAffix.frenzied] enemy below
/// [frenziedHealthThreshold].
const double frenziedDamageMultiplier = 1.4;
const double frenziedHealthThreshold = 0.5;

/// Damage multiplier every OTHER living pack member gets while an
/// [EnemyAffix.packLeader] stands, and the leader's own extra health.
const double packLeaderAllyDamageMultiplier = 1.25;
const double packLeaderHealthMultiplier = 1.2;

/// Added to the spoils-chest fortune roll per affixed enemy defeated.
const int affixFortuneBonus = 10;

/// l10n key of the affix's one-word display name ("Venomous").
String affixLabelKey(EnemyAffix affix) => switch (affix) {
      EnemyAffix.venomous => 'affix_venomous',
      EnemyAffix.armored => 'affix_armored',
      EnemyAffix.skittish => 'affix_skittish',
      EnemyAffix.frenzied => 'affix_frenzied',
      EnemyAffix.packLeader => 'affix_pack_leader',
    };

/// l10n key of the affix's one-line rules text.
String affixDescriptionKey(EnemyAffix affix) => '${affixLabelKey(affix)}_desc';

/// Parses an affix by its enum name (as stored on a generated
/// StoryChoice's `huntAffixes`); null for an unknown name.
EnemyAffix? affixFromName(String name) {
  for (final affix in EnemyAffix.values) {
    if (affix.name == name) return affix;
  }
  return null;
}

/// Rolls the affix list for every enemy of an encounter, in [enemyIds]
/// order. A [soloOnlyEnemyIds] boss/unique never gets one (those fights
/// stay exactly as tuned), nor does a solo Elite (Elite and affixes are
/// two separate variance mechanics, deliberately never combined). A solo
/// enemy may draw one of the four solo affixes; each pack member may draw
/// one of all five, with [EnemyAffix.packLeader] appearing at most once
/// per pack.
List<List<EnemyAffix>> rollEncounterAffixes({
  required List<String> enemyIds,
  required bool isElite,
  required Random random,
  double soloChance = affixChanceSolo,
  double packChance = affixChancePackMember,
}) {
  final isPack = enemyIds.length > 1;
  var leaderTaken = false;
  final result = <List<EnemyAffix>>[];
  for (final id in enemyIds) {
    if (soloOnlyEnemyIds.contains(id) || (!isPack && isElite)) {
      result.add(const []);
      continue;
    }
    final chance = isPack ? packChance : soloChance;
    if (random.nextDouble() >= chance) {
      result.add(const []);
      continue;
    }
    final pool = <EnemyAffix>[
      EnemyAffix.venomous,
      EnemyAffix.armored,
      EnemyAffix.skittish,
      EnemyAffix.frenzied,
      if (isPack && !leaderTaken) EnemyAffix.packLeader,
    ];
    final picked = pool[random.nextInt(pool.length)];
    if (picked == EnemyAffix.packLeader) leaderTaken = true;
    result.add([picked]);
  }
  return result;
}

/// Two distinct affixes for a hunt's named variant -- never Skittish (a
/// hunted quarry that runs would be a cheat) and never Pack Leader (it
/// fights alone).
List<EnemyAffix> rollNamedVariantAffixes(Random random) {
  final pool = <EnemyAffix>[
    EnemyAffix.venomous,
    EnemyAffix.armored,
    EnemyAffix.frenzied,
  ]..shuffle(random);
  return pool.take(2).toList();
}
