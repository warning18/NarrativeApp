// The Tower's rules 2 (docs/simulation/tower-levelup-loot.md, the user's
// decisions on Core's proposal): Level Up gives cards, floors give loot.
//
// - Tower XP: each floor won pays [towerXpFor] (2 an ordinary floor, 3 an
//   Elite, 4 a warden or a boss); a level every [towerXpPerLevel], from
//   [towerXpStart]. The XP a level is the power knob.
// - A level gained is a Level Up table: three distinct cards, one clan's
//   gift, a skill or a rank-up, a die or a spell (towerOfferFor's levelUp).
//   A skill or a rank-up taken nudges its stat by one ([towerNudgeStatOf]),
//   at most [towerNudgeStatCap] in a stat and [towerNudgeClimbCap] a climb.
//   No stat picks.
// - A floor won is a loot table: three distinct cards drawn by weight among
//   gear, a bundle of potions and a purse of coins, at the tier of the
//   story's chest roll shifted by the floor's band ([towerLootFor]). Pyre's
//   floors 13 and 23 deal none.
// - The clans' tables and the boon floors are gone: one clan's card sits on
//   every Level Up table. The oath keeps today's rules
//   ([towerOathInLevelUp]).
//
// Only a climb with TowerRun.rules 2 plays these; a climb on rules 1 (every
// one saved before the field) plays the stat picks, the spoils chest, the
// boons and the clans' tables as before. Pure, as the rest of the Tower.

import 'dart:math';

import '../../combat/fight_numbers.dart' show potionHealAmount;
import '../../combat/loot_box.dart';
import '../../combat/stat_rules.dart' show damageStatOf;
import '../sim_combat.dart' show SimCharacter;
import 'tower_coins.dart';
import 'tower_events.dart' show towerAfterEvent, towerOpenStore;
import 'tower_floors.dart';
import 'tower_hero.dart';
import 'tower_rewards.dart';
import 'tower_run.dart';
import 'tower_tables.dart';

// ---------------------------------------------------------------------------
// Tower XP and the levels.

/// The Tower XP a climb starts with on rules 2: with [towerXpPerLevel] 4,
/// the first floor won is the first level, and the climb gains about
/// today's 17 levels by floor 29.
const int towerXpStart = 2;

/// The Tower XP a level costs on rules 2: the power knob (3, about 23 Level
/// Ups a climb; 4, today's 17; 5, about 14).
const int towerXpPerLevel = 4;

/// Rules 3, the survival curve (docs/simulation/tower-difficulty-survival.md):
/// no Tower XP at the start, so the first Level Up comes after floor 3; the
/// first level costs [towerSurvivalXpPerLevel] and each level after it one
/// more every [towerSurvivalXpGrowthEvery] levels (5, 6, 6, 7, 7, 8 ...):
/// about 9 Level Ups for a climb that wins.
const int towerSurvivalXpStart = 0;
const int towerSurvivalXpPerLevel = 5;
const int towerSurvivalXpGrowthEvery = 2;

/// The Tower XP a climb on rules [rules] starts with.
int towerXpStartOf(int rules) =>
    rules >= towerSurvivalRules ? towerSurvivalXpStart : towerXpStart;

/// The Tower XP level [level] costs to leave on rules [rules] (level 1 to 2
/// is level 1's): [towerXpPerLevel] on rules 2, growing on rules 3.
int towerXpCostOf(int level, {required int rules}) =>
    rules >= towerSurvivalRules
        ? towerSurvivalXpPerLevel + level ~/ towerSurvivalXpGrowthEvery
        : towerXpPerLevel;

/// The Tower XP an ordinary floor won pays, an Elite's (a lone foe made
/// Elite by the floor, a shortcut's Elite or Elite pack), a warden's and a
/// boss's.
const int towerXpFight = 2;
const int towerXpElite = 3;
const int towerXpWarden = 4;
const int towerXpBoss = 4;

/// The Tower XP [floor] pays when won for the first time. (An Elite the
/// fight rolls on its own, beside the floor's, is not known here: it pays
/// as an ordinary floor.)
int towerXpFor(TowerFloor floor) => switch (floor.kind) {
      TowerFloorKind.warden => towerXpWarden,
      TowerFloorKind.boss => towerXpBoss,
      TowerFloorKind.fight =>
        floor.elite || floor.elitePack ? towerXpElite : towerXpFight,
    };

/// The level a climb on rules [rules] stands at with [xp] Tower XP (its
/// start included).
int towerXpLevelOf(int xp, {required int rules}) {
  if (rules < towerSurvivalRules) return 1 + max(0, xp) ~/ towerXpPerLevel;
  var level = 1, need = towerXpCostOf(1, rules: rules);
  while (xp >= need) {
    level++;
    need += towerXpCostOf(level, rules: rules);
  }
  return level;
}

/// [run]'s Tower XP: the start and every floor's.
int towerXpOf(TowerRun run) =>
    towerXpStartOf(run.rules) + run.xp.values.fold<int>(0, (n, x) => n + x);

/// The Level Ups [run] has been dealt (each a card taken, refused, or an
/// oath in its place).
int towerLevelUpsTaken(TowerRun run) =>
    run.levelUps.values.fold<int>(0, (n, cards) => n + cards.length);

/// The Level Ups [run] has earned and not yet been dealt: on rules 2 only.
int towerLevelUpsPending(TowerRun run) => run.rules < 2 || run.isOver
    ? 0
    : max(
        0,
        towerXpLevelOf(towerXpOf(run), rules: run.rules) -
            1 -
            towerLevelUpsTaken(run));

/// The draw of [run]'s next Level Up table on TowerStream.boon (its number
/// in the climb): the same table on a reload.
int towerLevelUpDraw(TowerRun run) => towerLevelUpsTaken(run) + 1;

// ---------------------------------------------------------------------------
// The stat nudges.

/// The most points the nudges give one stat, and a climb, on rules 2.
const int towerNudgeStatCap = 4;
const int towerNudgeClimbCap = 10;

/// The same on rules 3 (the survival curve: 3 and 6).
const int towerSurvivalNudgeStatCap = 3;
const int towerSurvivalNudgeClimbCap = 6;

/// The most points the nudges give one stat on rules [rules].
int towerNudgeStatCapOf(int rules) =>
    rules >= towerSurvivalRules ? towerSurvivalNudgeStatCap : towerNudgeStatCap;

/// The most points the nudges give a climb on rules [rules].
int towerNudgeClimbCapOf(int rules) => rules >= towerSurvivalRules
    ? towerSurvivalNudgeClimbCap
    : towerNudgeClimbCap;

/// The stat a skill of [skill]'s record nudges for a hero of
/// [professionId] (the first rule that matches): a support skill (it heals,
/// blocks, guards, cleanses or reflects, and hits at ×1.0 or less)
/// Constitution, Wisdom if Light or Water; Weaken, Perception; a calling's
/// own skill, that calling's damage stat; Fire, Electricity, Void, Ice and
/// Water, Intelligence; Wind, Dexterity; Earth, Strength; Light, Wisdom;
/// then Poison, Dexterity; Stun, Strength; else the hero's damage stat
/// ([fallback] for a calling with none).
String towerNudgeStatOf(Map<String, dynamic> skill, String professionId,
    {String fallback = 'wisdom'}) {
  num n(String key) => (skill[key] as num?) ?? 0;
  bool set(String key) {
    final v = skill[key];
    return v != null && v != false && v != '' && v != 0;
  }

  final element = skill['element']?.toString() ?? '';
  final support = (n('healAmount') > 0 ||
          set('healAll') ||
          n('blockAmount') > 0 ||
          n('guardMultiplier') > 0 ||
          set('cleanse') ||
          n('reflectMagnitude') > 0 ||
          n('reflectDuration') > 0) &&
      ((skill['damageMultiplier'] as num?) ?? 1.0) <= 1.0;
  if (support) {
    return element == 'Light' || element == 'Water' ? 'wisdom' : 'constitution';
  }
  final statuses = {
    skill['inflictsStatus']?.toString() ?? '',
    skill['inflictsStatus2']?.toString() ?? '',
  };
  if (statuses.contains('Weaken')) return 'perception';
  final calling = skill['restrictedProfessionID']?.toString() ?? '';
  if (calling.isNotEmpty) {
    final stat = damageStatOf(calling);
    return stat.isEmpty ? fallback : stat;
  }
  switch (element) {
    case 'Fire' || 'Electricity' || 'Void' || 'Ice' || 'Water':
      return 'intelligence';
    case 'Wind':
      return 'dexterity';
    case 'Earth':
      return 'strength';
    case 'Light':
      return 'wisdom';
  }
  if (statuses.contains('Poison')) return 'dexterity';
  if (statuses.contains('Stun')) return 'strength';
  final own = damageStatOf(professionId);
  return own.isEmpty ? fallback : own;
}

/// [hero] given the nudge of [card] (a skill or a rank-up; any other card
/// none): one point to its stat ([towerNudgeStatOf]) while that stat has
/// had fewer than its cap and the climb fewer than its cap on rules
/// [rules] ([towerNudgeStatCapOf], [towerNudgeClimbCapOf]; counted in SimCharacter.pickedPoints, which rules
/// 2 keeps for the nudges alone). Returns the stat raised, or null.
String? towerNudgeOn(SimCharacter hero, TowerReward card, TowerData data,
    {required int rules}) {
  if (card.kind != TowerRewardKind.skill &&
      card.kind != TowerRewardKind.rankUp) {
    return null;
  }
  final skill = data.skills[card.id];
  if (skill is! Map<String, dynamic>) return null;
  final stat =
      towerNudgeStatOf(skill, hero.professionId, fallback: hero.preferredStat);
  final total = hero.pickedPoints.values.fold<int>(0, (n, p) => n + p);
  if (total >= towerNudgeClimbCapOf(rules) ||
      (hero.pickedPoints[stat] ?? 0) >= towerNudgeStatCapOf(rules)) {
    return null;
  }
  hero.pickedPoints[stat] = (hero.pickedPoints[stat] ?? 0) + 1;
  hero.addAbilities({stat: 1});
  return stat;
}

// ---------------------------------------------------------------------------
// The loot table.

/// The cards a loot table deals.
const int towerLootCards = 3;

/// The weights a loot card is drawn with: gear, a bundle, a purse (one
/// purse a table at most; a kind with none left gives its draw to the
/// others).
/// (The proposal's 45 / 30 / 25 took the coins a climb from 49 to 87 with
/// every unlock: 50 / 35 / 15 and the small purses below keep them near
/// 60.)
const int towerLootGearWeight = 50;
const int towerLootBundleWeight = 35;
const int towerLootPurseWeight = 15;

/// The tier steps a loot table's chest roll is raised, by band (floors
/// 1-10, 11-20, 21-29) on rules 2: the gear knob.
const List<int> towerLootTierShift = [0, 1, 2];

/// The same on rules 3 (the survival curve).
const List<int> towerSurvivalLootTierShift = [0, 0, 1];

/// The tier shift by band on rules [rules].
List<int> towerLootTierShiftOf(int rules) => rules >= towerSurvivalRules
    ? towerSurvivalLootTierShift
    : towerLootTierShift;

/// The bundles by chest tier (wooden to void): two of each, the second
/// dealt only beside the first. Potions as the story counts them (a major
/// two), then antidotes.
const List<List<(int, int)>> towerLootBundles = [
  [(1, 0), (0, 1)],
  [(1, 1), (2, 0)],
  [(3, 0), (2, 1)],
  [(4, 0), (3, 1)],
  [(4, 1), (5, 0)],
];

/// A purse's coins by chest tier (wooden to void), and the coins it adds
/// for each band above the first (0: the tier shift by band raises it
/// already). The proposal's 3 / 4 / 6 / 9 / 12 and +2 a band nearly tripled
/// the coins a climb; these keep them near today's (the floors' own coins,
/// towerCoinsFor, unchanged).
const List<int> towerLootPurse = [1, 1, 2, 2, 3];
const int towerLootPurseBand = 0;

/// The id of the bundle of [potions] and [antidotes] ("p2a1").
String towerBundleId(int potions, int antidotes) => 'p${potions}a$antidotes';

/// The potions and antidotes of bundle [id] (towerBundleId); none for an id
/// that is not one.
({int potions, int antidotes}) towerBundleOf(String id) {
  final m = RegExp(r'^p(\d+)a(\d+)$').firstMatch(id);
  if (m == null) return (potions: 0, antidotes: 0);
  return (potions: int.parse(m.group(1)!), antidotes: int.parse(m.group(2)!));
}

/// The band (0, 1, 2) of [floor] for the loot: floors 1-10, 11-20, 21-30.
int towerLootBandOf(int floor) => ((floor - 1) ~/ 10).clamp(0, 2);

/// The chest context of [floor]'s loot for a hero of [luck] (the story's
/// chest roll: an Elite or a warden as an Elite, a boss's never below
/// Gold), its tier raised [towerLootTierShiftOf] its rules for the band.
LootContext towerLootContextOf(TowerFloor floor,
        {int luck = 0,
        Iterable<String> ownedItemIds = const [],
        String preferredScalingStat = ''}) =>
    LootContext(
      chapter: floor.chapter,
      playerLuck: luck,
      isElite:
          floor.elite || floor.elitePack || floor.kind == TowerFloorKind.warden,
      hasBossOrUnique: floor.kind == TowerFloorKind.boss,
      enemyCount: floor.enemyIds.length,
      affixCount: floor.affixes.length,
      tierShift:
          towerLootTierShiftOf(floor.rules)[towerLootBandOf(floor.floor)],
      preferredScalingStat: preferredScalingStat,
      ownedItemIds: ownedItemIds.toList(),
    );

/// The loot table of [floor] won: its tier from the story's chest roll
/// (towerLootContextOf, d100 drawn with [random], the floor's spoils stream
/// when not given), then [towerLootCards] cards, each drawn by weight among
/// gear (gearWeightsFor the tier, not owned, not on the table), a bundle
/// (the tier's, [towerLootBundles]) and a purse ([towerLootPurse], one a
/// table): never the same card twice, always three (the two bundles and
/// the purse are always there to give). [avoid] (a reroll's last cards)
/// keeps those gear pieces off while others are left.
List<TowerReward> towerLootFor({
  required int seed,
  required TowerFloor floor,
  int luck = 0,
  Iterable<String> ownedItemIds = const [],
  String preferredScalingStat = '',
  required Map<String, dynamic> items,
  Random? random,
  Set<String> avoid = const {},
}) {
  final drawn = random ?? towerRandom(seed, floor.floor, TowerStream.spoils);
  final context = towerLootContextOf(floor,
      luck: luck,
      ownedItemIds: ownedItemIds,
      preferredScalingStat: preferredScalingStat);
  final tier = towerLootTierFor(context, drawn);
  final weights = gearWeightsFor(context, items, tier);
  final gear = (weights.keys.where((id) => !avoid.contains(id)).isEmpty
      ? weights.keys.toList()
      : weights.keys.where((id) => !avoid.contains(id)).toList())
    ..sort();
  final bundles = [
    for (final (p, a) in towerLootBundles[tier.index]) towerBundleId(p, a),
  ];
  final cards = <TowerReward>[];
  var purse = false;
  while (cards.length < towerLootCards) {
    final options = <TowerRewardKind, int>{
      if (gear.isNotEmpty) TowerRewardKind.gear: towerLootGearWeight,
      if (bundles.isNotEmpty) TowerRewardKind.bundle: towerLootBundleWeight,
      if (!purse) TowerRewardKind.purse: towerLootPurseWeight,
    };
    if (options.isEmpty) break;
    final total = options.values.fold<int>(0, (n, w) => n + w);
    var roll = drawn.nextInt(total);
    var kind = options.keys.first;
    for (final MapEntry(:key, :value) in options.entries) {
      if (roll < value) {
        kind = key;
        break;
      }
      roll -= value;
    }
    switch (kind) {
      case TowerRewardKind.gear:
        final id = _pickWeighted(gear, weights, drawn);
        gear.remove(id);
        cards.add(TowerReward(TowerRewardKind.gear, id: id));
      case TowerRewardKind.bundle:
        cards.add(TowerReward(TowerRewardKind.bundle,
            id: bundles.removeAt(0), amount: tier.index));
      default:
        purse = true;
        cards.add(TowerReward(TowerRewardKind.purse,
            amount: towerPurseCoinsOf(tier, floor.floor)));
    }
  }
  return cards;
}

/// The chest tier of a loot table in [context], d100 drawn with [random].
ChestTier towerLootTierFor(LootContext context, Random random) => finalTierFor(
    context, tierForRoll(fortuneRollFor(context, 1 + random.nextInt(100))));

/// A purse's coins at [tier] on [floor]: [towerLootPurse], and
/// [towerLootPurseBand] for each band above the first.
int towerPurseCoinsOf(ChestTier tier, int floor) =>
    towerLootPurse[tier.index] + towerLootPurseBand * towerLootBandOf(floor);

String _pickWeighted(
    List<String> ids, Map<String, double> weights, Random random) {
  final total = ids.fold<double>(0, (n, id) => n + (weights[id] ?? 0));
  var r = random.nextDouble() * total;
  for (final id in ids) {
    r -= weights[id] ?? 0;
    if (r <= 0) return id;
  }
  return ids.last;
}

/// The loot table of [run]'s floor (towerLootFor with its hero: Luck, the
/// gear owned, the calling's stat), as the floor was fought (a shortcut's
/// Elite too). [random] and [avoid] as towerLootFor's.
List<TowerReward> towerRunLootFor(
        TowerRun run, TowerData data, SimCharacter hero,
        {Random? random, Set<String> avoid = const {}}) =>
    towerLootFor(
      seed: run.seed,
      floor: towerFloorOf(run, data),
      luck: hero.luck,
      ownedItemIds: hero.ownedItemIds,
      preferredScalingStat:
          (data.professions[run.professionId] as Map?)?['preferredScalingStat']
                  ?.toString() ??
              '',
      items: data.items,
      random: random,
      avoid: avoid,
    );

// ---------------------------------------------------------------------------
// The oath.

/// Where the oath is dealt on rules 2 (the user's open question): false,
/// as today, on every floor won once it is due (standing [towerOathStep],
/// or the late oath of towerPityOathFloorOf): in front of that floor's
/// first Level Up table when one is dealt (taken, it takes that level's
/// card, as it took the clans' gifts), else on a table of its own after
/// the loot (taken, it costs nothing; refused, a mark, as today). True:
/// only in front of a Level Up table, never alone.
const bool towerOathInLevelUp = false;

// ---------------------------------------------------------------------------
// The moves.

/// [run] after its fight of its floor was won on rules 2 (towerAfterFight;
/// [leveled] is [run] choosing, its rival's result set): the floor's Tower
/// XP paid (its levels' max health added to [healthLeft]), its coins, the
/// recovery, then the first table dealt ([towerDealTable] from the loot).
TowerRun towerAfterFightRules2(TowerRun run, TowerRun leveled, TowerData data,
    {required int healthLeft,
    required int maxHealthBefore,
    required int potions,
    required int antidotes}) {
  final fought = towerFloorOf(run, data);
  final paid = leveled.copyWith(
    xp: {...run.xp, run.floor: towerXpFor(fought)},
    potions: potions,
    antidotes: antidotes,
  );
  final hero = towerHeroOf(paid, data);
  final coins = towerCoinsFor(fought);
  final health = (healthLeft +
          hero.maxHealth -
          maxHealthBefore +
          (hero.maxHealth * towerRecoveryShareFor(run.heat, rules: run.rules))
              .round() +
          (hero.maxHealth * towerSecondWindShareOf(run)).round())
      .clamp(1, hero.maxHealth);
  hero.currentHealth = health;
  return towerDealTable(
      paid.copyWith(
          coins: run.coins + coins,
          coinsEarned: run.coinsEarned + coins,
          health: health),
      data,
      hero,
      TowerTableKind.loot);
}

/// [run] (choosing) with the next table of its floor on it, from [from]:
/// the loot table (none on Pyre's empty floors), then a Level Up table
/// while one is earned and not dealt (the oaths due in front unless
/// [oathShown], the floor's oath already dealt), then the oath alone
/// ([towerOathInLevelUp] false, the floor's oath not yet dealt, not on
/// Pyre's empty floors). The offer empty (TowerRun.table null) when none is
/// left: towerPick then moves on. [hero] is [run]'s hero as it stands.
TowerRun towerDealTable(
    TowerRun run, TowerData data, SimCharacter hero, TowerTableKind from,
    {bool oathShown = false}) {
  final empty = towerHeatEmptyFloorsOf(run.heat).contains(run.floor);
  if (from == TowerTableKind.loot && !empty) {
    final cards = towerRunLootFor(run, data, hero);
    if (cards.isNotEmpty) {
      return run.copyWith(offer: cards, table: TowerTableKind.loot);
    }
  }
  if (from != TowerTableKind.oath && towerLevelUpsPending(run) > 0) {
    final cards = towerRunOfferFor(run, data, run.floor, hero,
        levelUp: true, levelUpOaths: !oathShown);
    if (cards.isNotEmpty) {
      return run.copyWith(offer: cards, table: TowerTableKind.levelUp);
    }
  }
  if (!oathShown && !towerOathInLevelUp && !empty) {
    final oaths = towerOathCardsFor(
      hero: towerHeroView(run, hero),
      clanPool: run.clanPool,
      standing: towerStandingOf(run, data),
      oathOpen: run.clanIds.isEmpty,
      floor: run.floor,
      heat: run.heat,
      oathSooner: run.wears(towerPerkEarlyWord) ? towerEarlyWordFloors : 0,
    );
    if (oaths.isNotEmpty) {
      return run.copyWith(offer: oaths, table: TowerTableKind.oath);
    }
  }
  return run.copyWith(offer: const [], clearTable: true);
}

/// The cards of [run]'s table drawn again with [random] (towerReroll on
/// rules 2): the loot table's, or the Level Up table's (its oaths dealt
/// again in front: the reroll keeps those on the table); the cards shown
/// kept off while others are left.
List<TowerReward> towerRedrawTable(
    TowerRun run, TowerData data, SimCharacter hero, Random random) {
  final avoid = {for (final c in run.offer) c.id};
  return switch (run.table) {
    TowerTableKind.loot =>
      towerRunLootFor(run, data, hero, random: random, avoid: avoid),
    TowerTableKind.levelUp => towerRunOfferFor(run, data, run.floor, hero,
        levelUp: true, random: random, avoid: avoid),
    _ => const [],
  };
}

/// [run] with loot card [card] taken: gear to the hero (worn when better),
/// a bundle's potions to the bag (what passes towerBagCapOf drunk at once,
/// each healing the story's potion) and its antidotes, a purse's coins in
/// hand (and earned). [hero] is given the gear and the healing.
TowerRun towerTakeLoot(
    TowerRun run, TowerReward card, SimCharacter hero, TowerData data) {
  var next = run.copyWith(loot: {...run.loot, run.floor: card});
  switch (card.kind) {
    case TowerRewardKind.gear:
      towerApplyReward(hero, card, data);
    case TowerRewardKind.bundle:
      final bundle = towerBundleOf(card.id);
      final bag = run.potions + bundle.potions;
      final drunk = max(0, bag - towerBagCapOf(run));
      hero.currentHealth =
          min(hero.maxHealth, hero.currentHealth + drunk * potionHealAmount);
      next = next.copyWith(
          potions: bag - drunk, antidotes: run.antidotes + bundle.antidotes);
    case TowerRewardKind.purse:
      next = next.copyWith(
          coins: run.coins + card.amount,
          coinsEarned: run.coinsEarned + card.amount);
    default:
      break;
  }
  return next;
}

/// [run] after its table on rules 2 (towerPick): card [index] taken, or
/// none (null). The loot table's card goes to the hero (towerTakeLoot; all
/// refused, a mark), then the Level Ups. A Level Up's card is given with
/// its nudge (towerNudgeOn); an oath in front is sworn in its place (the
/// level's card gone); refused, the level is spent. The oath alone sworn,
/// or refused for a mark. Then the next table ([towerDealTable]); with none
/// left, on to the next floor, its event and store as on rules 1.
TowerRun towerPickRules2(TowerRun run, TowerData data, int? index,
    {SimCharacter? hero}) {
  final built = hero ?? towerHeroOf(run, data);
  final card = index != null && index >= 0 && index < run.offer.length
      ? run.offer[index]
      : null;
  var next = run;
  TowerTableKind? from;
  var oathShown = false;
  void refuse() {
    if (run.offer.isNotEmpty) {
      next = next.copyWith(refused: {...run.refused, run.floor});
    }
  }

  switch (run.table) {
    case TowerTableKind.loot:
      if (card == null) {
        refuse();
      } else {
        next = towerTakeLoot(run, card, built, data);
      }
      from = TowerTableKind.levelUp;
    case TowerTableKind.levelUp:
      final level = [...?run.levelUps[run.floor]];
      if (card != null && card.kind == TowerRewardKind.clanOath) {
        towerApplyReward(built, card, data, bag: run.dieChoice != null);
        level.add(null);
        next = run.copyWith(taken: {...run.taken, run.floor: card});
      } else {
        level.add(card);
        if (card != null) {
          towerApplyReward(built, card, data, bag: run.dieChoice != null);
          towerNudgeOn(built, card, data, rules: run.rules);
        }
      }
      next = next.copyWith(levelUps: {...run.levelUps, run.floor: level});
      from = TowerTableKind.levelUp;
      oathShown = true;
    case TowerTableKind.oath:
      if (card == null) {
        refuse();
      } else {
        towerApplyReward(built, card, data, bag: run.dieChoice != null);
        next = run.copyWith(taken: {...run.taken, run.floor: card});
      }
    case null:
      break;
  }
  next = next.copyWith(health: built.currentHealth.clamp(1, built.maxHealth));
  if (from != null) {
    final dealt = towerDealTable(next, data, built, from, oathShown: oathShown);
    if (dealt.offer.isNotEmpty) return dealt;
    next = dealt;
  }
  return towerOpenStore(
      run,
      towerAfterEvent(
          run,
          next.copyWith(
            status: TowerStatus.climbing,
            floor: run.floor + 1,
            offer: const [],
            clearTable: true,
            clearShortcut: true,
            clearParley: true,
          ),
          data));
}
