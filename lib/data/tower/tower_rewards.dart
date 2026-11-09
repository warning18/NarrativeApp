// The Tower's rewards (docs/proposals/tower-mechanics.md §5). From v1.860
// (the main game's earning offers, the user's call): every floor won drops
// the story's spoils chest (its gear and potions, never its gold), a boon
// floor (towerBoonFloors) offers a choose-one of a skill, a die and a
// spell, and a clan may offer its oath after the spoils. All drawn from the
// floor's own streams.

import 'dart:math';

import '../../combat/loot_box.dart';
import 'tower_floors.dart';
import 'tower_tables.dart';

/// One card: what it gives. [id] is the item, die, skill or spell (empty
/// for a heal, and for a clan gift that is a stat point); [amount] is a
/// heal's percent of max health, or a clan gift's stat points.
class TowerReward {
  const TowerReward(this.kind, {this.id = '', this.amount = 0});

  factory TowerReward.fromJson(Map<String, dynamic> json) => TowerReward(
        TowerRewardKind.values.byName(json['kind'] as String),
        id: json['id']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
      );

  final TowerRewardKind kind;
  final String id;
  final int amount;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        if (id.isNotEmpty) 'id': id,
        if (amount != 0) 'amount': amount,
      };

  @override
  bool operator ==(Object other) =>
      other is TowerReward &&
      other.kind == kind &&
      other.id == id &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(kind, id, amount);

  @override
  String toString() => 'TowerReward(${kind.name}${id.isEmpty ? '' : ' $id'}'
      '${amount == 0 ? '' : ' $amount'})';
}

/// What the offer needs to know of the hero.
class TowerHeroView {
  const TowerHeroView({
    required this.raceId,
    required this.professionId,
    this.clanIds = const [],
    required this.health,
    required this.maxHealth,
    this.equippedItemIds = const {},
    this.ownedDiceIds = const {},
    this.unlockedSkillIds = const {},
    this.knownSpellIds = const {},
    this.takenIds = const {},
  });

  final String raceId;
  final String professionId;

  /// The clans sworn, the first (the main one) first (v1.855).
  final List<String> clanIds;

  /// The main clan, '' while none is sworn.
  String get clanId => clanIds.isEmpty ? '' : clanIds.first;
  final int health;
  final int maxHealth;
  final Set<String> equippedItemIds;
  final Set<String> ownedDiceIds;
  final Set<String> unlockedSkillIds;
  final Set<String> knownSpellIds;

  /// The ids of every card taken this run (none is offered twice).
  final Set<String> takenIds;
}

/// The rarity step (0..3) a card of [floor] draws with [random].
int towerRarityStep(int floor, Random random) {
  final band = ((floor - 1) ~/ 10).clamp(0, towerRarityOdds.length - 1);
  final odds = towerRarityOdds[band];
  var roll = random.nextDouble();
  var step = odds.length - 1;
  for (var i = 0; i < odds.length; i++) {
    if (roll < odds[i]) {
      step = i;
      break;
    }
    roll -= odds[i];
  }
  final kind = towerBudgetOf(floor).kind;
  return kind == TowerFloorKind.fight ? step : min(step + 1, odds.length - 1);
}

bool _allows(List? list, String id) =>
    list == null || list.isEmpty || list.map((e) => e.toString()).contains(id);

/// The clan's own die (dice.json `clan`), or null.
String? towerClanDieOf(String clanId, Map<String, dynamic> dice) {
  for (final MapEntry(:key, :value) in dice.entries) {
    if (value is Map && value['clan']?.toString() == clanId) return key;
  }
  return null;
}

/// The cards on the table after floor [floor] is won (v1.860): on a boon
/// floor ([towerBoonFloors]) a skill, a die and a spell, one of each while
/// each has one to give; on another, a clan of [oaths] (the clans still to
/// swear to) offering its oath (v1.855): always when [oathDue] (the first
/// floor won), else on [towerOathChance] of the floors. Often nothing: the
/// floor's spoils ([towerSpoilsFor]) are its reward.
List<TowerReward> towerOfferFor({
  required int seed,
  required int floor,
  required TowerHeroView hero,
  List<String> oaths = const [],
  bool oathDue = false,
  required Map<String, dynamic> items,
  required Map<String, dynamic> dice,
  required Map<String, dynamic> skills,
  required Map<String, dynamic> spells,
}) {
  final random = towerRandom(seed, floor, TowerStream.offer);

  TowerReward? draw(TowerRewardKind kind) {
    String? pick(List<String> pool) {
      final fresh = [
        for (final id in pool)
          if (!hero.takenIds.contains(id)) id,
      ]..sort();
      return fresh.isEmpty ? null : fresh[random.nextInt(fresh.length)];
    }

    switch (kind) {
      case TowerRewardKind.die:
        final id = pick([
          for (final MapEntry(:key, :value) in dice.entries)
            if (value is Map &&
                key != 'starter_die' &&
                !towerExcludedDice.contains(key) &&
                (value['clan'] == null || value['clan'].toString().isEmpty) &&
                !hero.ownedDiceIds.contains(key) &&
                _allows(value['professions'] as List?, hero.professionId) &&
                _allows(value['races'] as List?, hero.raceId))
              key,
        ]);
        return id == null ? null : TowerReward(kind, id: id);
      case TowerRewardKind.skill:
        for (var step = towerRarityStep(floor, random); step >= 0; step--) {
          final id = pick([
            for (final MapEntry(:key, :value) in skills.entries)
              if (value is Map &&
                  towerSkillRarities[step].contains(value['rarity']) &&
                  !hero.unlockedSkillIds.contains(key) &&
                  _restrictionAllows(
                      value['restrictedProfessionID'], hero.professionId) &&
                  _restrictionAllows(value['restrictedRaceID'], hero.raceId) &&
                  _prerequisiteMet(value['requiredSkillID'], hero))
                key,
          ]);
          if (id != null) return TowerReward(kind, id: id);
        }
        return null;
      case TowerRewardKind.spell:
        final id = pick([
          for (final MapEntry(:key, :value) in spells.entries)
            if (value is Map &&
                value['professionID']?.toString() == hero.professionId &&
                !hero.knownSpellIds.contains(key))
              key,
        ]);
        return id == null ? null : TowerReward(kind, id: id);
      // A boon is a skill, a die or a spell (v1.860); an oath is dealt
      // apart, below (its own stream). The heal, item and clan-gift cards
      // are no longer dealt (an old save's offer may still hold one:
      // towerApplyReward takes it).
      case TowerRewardKind.heal ||
            TowerRewardKind.item ||
            TowerRewardKind.clanGift ||
            TowerRewardKind.clanOath:
        return null;
    }
  }

  if (towerBoonFloors.contains(floor)) {
    return [
      for (final kind in towerBoonKinds)
        if (draw(kind) case final card?) card,
    ];
  }
  // A clan's oath, from its own stream.
  final free = [
    for (final clan in oaths)
      if (!hero.clanIds.contains(clan)) clan,
  ]..sort();
  if (free.isEmpty) return const [];
  final oathRandom = towerRandom(seed, floor, TowerStream.oath);
  if (!oathDue && oathRandom.nextDouble() >= towerOathChance) return const [];
  return [
    TowerReward(TowerRewardKind.clanOath,
        id: free[oathRandom.nextInt(free.length)]),
  ];
}

/// The spoils chest of floor [floor] won (v1.860): the story's own chest
/// (rollLootBox: its tier from the fortune roll of a hero of [luck], a boss
/// floor's never below Gold, a warden's and an Elite's raised as an
/// Elite's), from the floor's own stream; its gear and its potions, never
/// its gold (nor its charms, tomes or materials, which the Tower has no
/// use for). From v1.865 the chest draws those slots as gear or a potion
/// instead (rollLootBox's gearAndPotionsOnly): no chest is empty.
List<String> towerSpoilsFor({
  required int seed,
  required TowerFloor floor,
  int luck = 0,
  Iterable<String> ownedItemIds = const [],
  String preferredScalingStat = '',
  required Map<String, dynamic> items,
}) {
  final chest = rollLootBox(
    LootContext(
      chapter: floor.chapter,
      playerLuck: luck,
      isElite: floor.elite || floor.kind == TowerFloorKind.warden,
      hasBossOrUnique: floor.kind == TowerFloorKind.boss,
      enemyCount: floor.enemyIds.length,
      affixCount: floor.affixes.length,
      preferredScalingStat: preferredScalingStat,
      ownedItemIds: ownedItemIds.toList(),
      signatureItemIds: const [],
    ),
    items,
    towerRandom(seed, floor.floor, TowerStream.spoils),
    // Every slot gear or a potion (v1.865): no empty chest.
    gearAndPotionsOnly: true,
  );
  return [
    for (final id in chest.itemIds)
      if ((items[id] as Map?)?['isEquippable'] == true ||
          towerSpoilsPotions.containsKey(id) ||
          id == towerSpoilsAntidote)
        id,
  ];
}

bool _restrictionAllows(Object? restricted, String id) {
  final r = restricted?.toString() ?? '';
  return r.isEmpty || r == id;
}

bool _prerequisiteMet(Object? required, TowerHeroView hero) {
  final r = required?.toString() ?? '';
  return r.isEmpty || hero.unlockedSkillIds.contains(r);
}
