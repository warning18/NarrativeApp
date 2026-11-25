// The Tower's rewards (docs/proposals/tower-mechanics.md §5). From v1.860
// (the main game's earning offers, the user's call): every floor won drops
// the story's spoils chest (its gear and potions, never its gold), a boon
// floor (towerBoonFloors) offers a choose-one of a skill, a die and a
// spell, and a clan may offer its oath after the spoils. All drawn from the
// floor's own streams.

import 'dart:math';

import '../../combat/combat_engine.dart' show applySkillTier, maxSkillTier;
import '../../combat/loot_box.dart';
import '../sim_growth.dart' show simSkillScore;
import '../sim_policy.dart' show simSkillAssignments;
import 'tower_clans.dart';
import 'tower_floors.dart';
import 'tower_tables.dart';

/// One card: what it gives. [id] is the item, die, skill or spell (empty
/// for a heal, and for a clan gift that is a stat point); [amount] is a
/// heal's percent of max health, or a clan gift's stat points. [clan] is
/// the clan whose gift it is (a skill or a rank-up of the clans' offers,
/// docs/simulation/tower-clan-offers.md), '' for any other card: taken,
/// it moves the run's standing (towerStandingOf). Saved only when set, so
/// a card saved before reads as no clan's.
class TowerReward {
  const TowerReward(this.kind, {this.id = '', this.amount = 0, this.clan = ''});

  factory TowerReward.fromJson(Map<String, dynamic> json) => TowerReward(
        TowerRewardKind.values.byName(json['kind'] as String),
        id: json['id']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        clan: json['clan']?.toString() ?? '',
      );

  final TowerRewardKind kind;
  final String id;
  final int amount;
  final String clan;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        if (id.isNotEmpty) 'id': id,
        if (amount != 0) 'amount': amount,
        if (clan.isNotEmpty) 'clan': clan,
      };

  @override
  bool operator ==(Object other) =>
      other is TowerReward &&
      other.kind == kind &&
      other.id == id &&
      other.amount == amount &&
      other.clan == clan;

  @override
  int get hashCode => Object.hash(kind, id, amount, clan);

  @override
  String toString() => 'TowerReward(${kind.name}${id.isEmpty ? '' : ' $id'}'
      '${amount == 0 ? '' : ' $amount'}${clan.isEmpty ? '' : ' @$clan'})';
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
    this.diceFaces = const [],
    this.diceSkillAssignments = const {},
    this.skillTiers = const {},
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

  /// The die in play's faces and the skills on them (face index -> skill
  /// id), and the tiers of the skills ranked up (v2.4.0): a skill card
  /// that would land on no face is a rank-up instead ([towerRankUpFor]).
  final List<Map<String, dynamic>> diceFaces;
  final Map<String, String> diceSkillAssignments;
  final Map<String, int> skillTiers;
}

/// The skill a rank-up card raises instead of [skillId] (v2.4.0, brief 2 of
/// docs/simulation/tower-roguelike-briefs.md), or null when [skillId]
/// would sit on a face of [hero]'s die (simSkillAssignments with the
/// hero's tiers, as it is placed when taken) or no skill on the die has a
/// tier left: the best of the skills on the die now (simSkillScore at its
/// tier, ties by id) below [maxSkillTier]. Only a skill on the die (the
/// user's call, #1147), and the skill it raises stays there: the ranked
/// keep their faces when the die's skills are placed again. With none to
/// raise (every skill on the die at the last tier, or none on it) the card
/// stays the skill card it was.
String? towerRankUpFor(
    String skillId, TowerHeroView hero, Map<String, dynamic> skills) {
  if (hero.diceFaces.isEmpty) return null;
  final placed = simSkillAssignments(
      faces: hero.diceFaces,
      current: hero.diceSkillAssignments,
      unlocked: {...hero.unlockedSkillIds, skillId},
      skills: skills,
      tiers: hero.skillTiers);
  if (placed.values.contains(skillId)) return null;
  double score(String id) => simSkillScore(applySkillTier(
      skills[id] as Map<String, dynamic>, hero.skillTiers[id] ?? 0));
  final onDie = [
    for (final id in hero.diceSkillAssignments.values.toSet())
      if (skills[id] is Map<String, dynamic> &&
          (hero.skillTiers[id] ?? 0) < maxSkillTier)
        id,
  ]..sort((a, b) {
      final byScore = score(b).compareTo(score(a));
      return byScore != 0 ? byScore : a.compareTo(b);
    });
  return onDie.isEmpty ? null : onDie.first;
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
/// each has one to give. On another, the clans (docs/simulation/
/// tower-clan-offers.md): always when [clansDue] (the first floor won),
/// else on [towerOathChance] of the floors (the oath's stream, as the oath
/// came before), up to [towerSuitorsPerOffer] clans of [clanPool], each a
/// gift ([towerClanGiftFor]); and, whenever [oathOpen] (no oath sworn yet:
/// one a run, the user's call), the oath of each clan of [clanPool] at
/// [towerOathStep] in [standing] (a card of its own, first, beside the
/// gifts or alone); from [towerPityOathFloor], with none of those due, the
/// oath of the highest-standing clan ([towerPityOathClan]). Often nothing:
/// the floor's spoils ([towerSpoilsFor]) are its reward. At Heat [heat]
/// (TowerRun.heat), Pyre's empty floors and late oath
/// (towerHeatEmptyFloorsOf, towerPityOathFloorOf).
List<TowerReward> towerOfferFor({
  required int seed,
  required int floor,
  required TowerHeroView hero,
  List<String> clanPool = const [],
  Map<String, int> standing = const {},
  bool oathOpen = true,
  bool clansDue = false,
  int heat = 0,
  TowerClanTables clans = const TowerClanTables(),
  required Map<String, dynamic> items,
  required Map<String, dynamic> dice,
  required Map<String, dynamic> skills,
  required Map<String, dynamic> spells,
}) {
  final random = towerRandom(seed, floor, TowerStream.offer);

  String? pick(List<String> pool) {
    final fresh = [
      for (final id in pool)
        if (!hero.takenIds.contains(id)) id,
    ]..sort();
    return fresh.isEmpty ? null : fresh[random.nextInt(fresh.length)];
  }

  // A skill of the Tower's pool at the floor's rarity (or below), none of
  // [besides].
  String? poolSkill({Set<String> besides = const {}}) {
    for (var step = towerRarityStep(floor, random); step >= 0; step--) {
      final id = pick([
        for (final MapEntry(:key, :value) in skills.entries)
          if (value is Map &&
              !besides.contains(key) &&
              towerSkillRarities[step].contains(value['rarity']) &&
              !hero.unlockedSkillIds.contains(key) &&
              _restrictionAllows(
                  value['restrictedProfessionID'], hero.professionId) &&
              _restrictionAllows(value['restrictedRaceID'], hero.raceId) &&
              _prerequisiteMet(value['requiredSkillID'], hero))
            key,
      ]);
      if (id != null) return id;
    }
    return null;
  }

  TowerReward? draw(TowerRewardKind kind) {
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
        final id = poolSkill();
        if (id == null) return null;
        // A skill with no face to land on: a tier for one on the die.
        if (towerRankUpFor(id, hero, skills) case final up?) {
          return TowerReward(TowerRewardKind.rankUp, id: up);
        }
        return TowerReward(kind, id: id);
      case TowerRewardKind.spell:
        final id = pick([
          for (final MapEntry(:key, :value) in spells.entries)
            if (value is Map &&
                value['professionID']?.toString() == hero.professionId &&
                !hero.knownSpellIds.contains(key))
              key,
        ]);
        return id == null ? null : TowerReward(kind, id: id);
      // A boon is a skill, a die or a spell (v1.860); the clans' cards are
      // dealt apart, below.
      case TowerRewardKind.clanOath:
      case TowerRewardKind.rankUp:
        return null;
    }
  }

  // Pyre's floors (towerHeatEmptyFloorsOf): nothing at all, no boon and
  // no clan's card in its place.
  if (towerHeatEmptyFloorsOf(heat).contains(floor)) return const [];
  if (towerBoonFloorsOf(heat).contains(floor)) {
    return [
      for (final kind in towerBoonKinds)
        if (draw(kind) case final card?) card,
    ];
  }
  // The oaths due: a clan at the oath's step, while none is sworn.
  final oaths = [
    if (oathOpen && hero.clanIds.isEmpty)
      for (final clan in clanPool)
        if ((standing[clan] ?? 0) >= towerOathStep)
          TowerReward(TowerRewardKind.clanOath, id: clan),
  ];
  // From [towerPityOathFloor] (#1153, the user's call): a climb with no
  // oath due nor sworn is offered the oath of its highest-standing clan.
  if (oaths.isEmpty &&
      oathOpen &&
      hero.clanIds.isEmpty &&
      floor >= towerPityOathFloorOf(heat)) {
    if (towerPityOathClan(clanPool, standing) case final clan?) {
      oaths.add(TowerReward(TowerRewardKind.clanOath, id: clan));
    }
  }
  if (clanPool.isEmpty) return oaths;
  // The clans' offer, on the oath's own stream (where the oath came).
  final oathRandom = towerRandom(seed, floor, TowerStream.oath);
  if (!clansDue && oathRandom.nextDouble() >= towerOathChance) return oaths;
  final suitors = [...clanPool]..sort();
  final cards = <TowerReward>[];
  final given = <String>{};
  while (suitors.isNotEmpty && cards.length < towerSuitorsPerOffer) {
    final clan = suitors.removeAt(random.nextInt(suitors.length));
    final id = towerClanGiftFor(clan,
            hero: hero,
            standing: standing[clan] ?? 0,
            besides: given,
            skills: skills,
            tables: clans,
            random: random) ??
        poolSkill(besides: given);
    if (id == null) continue;
    given.add(id);
    // A skill with no face to land on: a tier for one on the die, still
    // the clan's gift (its standing moves the same).
    cards.add(switch (towerRankUpFor(id, hero, skills)) {
      final up? => TowerReward(TowerRewardKind.rankUp, id: up, clan: clan),
      null => TowerReward(TowerRewardKind.skill, id: id, clan: clan),
    });
  }
  return [...oaths, ...cards];
}

/// The clan whose oath a climb with none due is offered from
/// [towerPityOathFloor]: the one of [clanPool] with the highest [standing],
/// the first in [clanPool]'s order on a tie; null when the pool is empty.
String? towerPityOathClan(List<String> clanPool, Map<String, int> standing) {
  String? best;
  for (final clan in clanPool) {
    if (best == null || (standing[clan] ?? 0) > (standing[best] ?? 0)) {
      best = clan;
    }
  }
  return best;
}

/// The skill [clanId] gives [hero] at [standing] (towerClanSkillsFor: the
/// next on a branch it sponsors for the hero), drawn with [random] among
/// those not in [besides]; null when it has none (the offer then gives one
/// of the Tower's pool in its name).
String? towerClanGiftFor(
  String clanId, {
  required TowerHeroView hero,
  required int standing,
  Set<String> besides = const {},
  required Map<String, dynamic> skills,
  required TowerClanTables tables,
  required Random random,
}) {
  final options = [
    for (final id in towerClanSkillsFor(clanId,
        raceId: hero.raceId,
        professionId: hero.professionId,
        standing: standing,
        unlocked: hero.unlockedSkillIds,
        skills: skills,
        tables: tables))
      if (!besides.contains(id) && !hero.takenIds.contains(id)) id,
  ];
  return options.isEmpty ? null : options[random.nextInt(options.length)];
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
