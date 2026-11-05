// The Tower's reward cards (v1.845, docs/proposals/tower-mechanics.md §5):
// after a win, 3 cards of different kinds, drawn from the floor's own
// stream; never gold.

import 'dart:math';

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

/// The cards on the table after floor [floor] is won (§5): [towerOfferSize]
/// of different kinds while the kinds last, a heal always among them when
/// the hero is below [towerHealFloor] of its health. A clan of [oaths] (the
/// clans still to swear to) offers its oath (v1.855): always when
/// [oathDue] (the first floor won), else on [towerOathChance] of offers;
/// one oath an offer at most.
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
  final big = towerBudgetOf(floor).kind != TowerFloorKind.fight;
  final heal = TowerReward(TowerRewardKind.heal,
      amount: ((big ? towerBigHealShare : towerHealShare) * 100).round());

  TowerReward? draw(TowerRewardKind kind) {
    String? pick(List<String> pool) {
      final fresh = [
        for (final id in pool)
          if (!hero.takenIds.contains(id)) id,
      ]..sort();
      return fresh.isEmpty ? null : fresh[random.nextInt(fresh.length)];
    }

    switch (kind) {
      case TowerRewardKind.heal:
        return heal;
      case TowerRewardKind.item:
        // The floor's rarity, else the nearest one below it that has any.
        for (var step = towerRarityStep(floor, random); step >= 0; step--) {
          final id = pick([
            for (final MapEntry(:key, :value) in items.entries)
              if (value is Map &&
                  value['isEquippable'] == true &&
                  value['rarity'] == towerItemRarities[step] &&
                  !hero.equippedItemIds.contains(key))
                key,
          ]);
          if (id != null) return TowerReward(kind, id: id);
        }
        return null;
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
      case TowerRewardKind.clanGift:
        // A gift comes from a clan sworn: none before the first oath.
        if (hero.clanIds.isEmpty) return null;
        for (final clan in hero.clanIds) {
          final die = towerClanDieOf(clan, dice);
          if (die != null &&
              !hero.ownedDiceIds.contains(die) &&
              !hero.takenIds.contains(die)) {
            return TowerReward(kind, id: die);
          }
        }
        return const TowerReward(TowerRewardKind.clanGift, amount: 1);
      case TowerRewardKind.clanOath:
        // Dealt apart, below (its own stream).
        return null;
    }
  }

  final offer = <TowerReward>[];
  final kinds = {...towerRewardWeights};
  if (hero.health < hero.maxHealth * towerHealFloor) {
    offer.add(heal);
    kinds.remove(TowerRewardKind.heal);
  }
  // A clan's oath, from its own stream (the other cards draw as before).
  final free = [
    for (final clan in oaths)
      if (!hero.clanIds.contains(clan)) clan,
  ]..sort();
  if (free.isNotEmpty) {
    final oathRandom = towerRandom(seed, floor, TowerStream.oath);
    if (oathDue || oathRandom.nextDouble() < towerOathChance) {
      offer.add(TowerReward(TowerRewardKind.clanOath,
          id: free[oathRandom.nextInt(free.length)]));
    }
  }
  while (offer.length < towerOfferSize && kinds.isNotEmpty) {
    final total = kinds.values.fold(0, (a, b) => a + b);
    var roll = random.nextInt(total);
    late TowerRewardKind kind;
    for (final MapEntry(:key, :value) in kinds.entries) {
      if (roll < value) {
        kind = key;
        break;
      }
      roll -= value;
    }
    kinds.remove(kind);
    final card = draw(kind);
    if (card != null) offer.add(card);
  }
  return offer;
}

bool _restrictionAllows(Object? restricted, String id) {
  final r = restricted?.toString() ?? '';
  return r.isEmpty || r == id;
}

bool _prerequisiteMet(Object? required, TowerHeroView hero) {
  final r = required?.toString() ?? '';
  return r.isEmpty || hero.unlockedSkillIds.contains(r);
}
