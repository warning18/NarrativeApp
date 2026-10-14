/// The camp's works as the building screen reads them (docs/proposals/
/// building-screen.md): each house of houses.json in a category, with the
/// chapter it comes in (its tier's, see materials.dart), its state, and
/// what it still needs and where that is found. Pure: the screen's
/// provider feeds it the session and the tables.
library;

import 'materials.dart';
import 'shop_stock.dart' show allShopStock;
import 'zone_gating.dart' show missingRequiredFlags, unlockedByFlagsOf;

/// The building screen's sections, in the order they are listed.
enum WorkCategory { sea, company, workshops, greatWorks }

/// Where a house stands: not come yet ([locked]), seen but short of
/// something ([shown]), ready to go up ([buildable]), or up ([built]).
enum WorkState { locked, shown, buildable, built }

/// What a house can wait on.
enum WorkNeedKind { chapter, ally, flag, gold, material }

/// One thing a house still needs: [have] of [need], and where to get it
/// ([zoneIds], the expeditions that set the flag or pay the material;
/// [shopIds], the shops that stock it).
class WorkNeed {
  const WorkNeed({
    required this.kind,
    this.id = '',
    this.have = 0,
    this.need = 0,
    this.zoneIds = const [],
    this.shopIds = const [],
  });

  final WorkNeedKind kind;
  final String id;
  final int have;
  final int need;
  final List<String> zoneIds;
  final List<String> shopIds;
}

/// One house as the building screen lists it.
class CampWork {
  const CampWork({
    required this.houseId,
    required this.category,
    required this.tier,
    required this.chapter,
    required this.state,
    this.needs = const [],
  });

  final String houseId;
  final WorkCategory category;

  /// Its materials' highest tier (1 for none).
  final int tier;

  /// The chapter it comes in: its tier's first.
  final int chapter;
  final WorkState state;

  /// What it still needs: empty once buildable or built.
  final List<WorkNeed> needs;
}

/// [house]'s category: its `category` field, else read from what it gives
/// (a shop, room in the party or a companion's home, the Eel's refit, or
/// the party's lasting bonuses).
WorkCategory workCategoryOf(String houseId, Map<String, dynamic> house) {
  final named = house['category']?.toString() ?? '';
  for (final category in WorkCategory.values) {
    if (category.name == named) return category;
  }
  if (houseId == 'harbor') return WorkCategory.sea;
  if ((house['unlocksShopId']?.toString() ?? '').isNotEmpty ||
      house['unlocksCraft'] == true) {
    return WorkCategory.workshops;
  }
  if ((house['requiredAllyId']?.toString() ?? '').isNotEmpty ||
      ((house['partyCapacityBonus'] as num?) ?? 0) > 0) {
    return WorkCategory.company;
  }
  return WorkCategory.greatWorks;
}

/// The tier of material [itemId] (see [materialTiers]), or null.
int? materialTierOf(String itemId) {
  for (final MapEntry(key: tier, value: (:commons, :rare))
      in materialTiers.entries) {
    if (commons.contains(itemId) || rare == itemId) return tier;
  }
  return null;
}

/// [house]'s tier: its highest material's, 1 for a house of none.
int workTierOf(Map<String, dynamic> house) {
  var tier = 1;
  for (final id in materialCountsOf(house, 'materialCost').keys) {
    final t = materialTierOf(id) ?? 1;
    if (t > tier) tier = t;
  }
  return tier;
}

/// The first chapter of [tier] (tier 1 is chapters 1-2, tier 2 is 3-4...).
int tierFirstChapter(int tier) => 2 * tier - 1;

/// Every house of [houses] as the building screen lists it, by category
/// ([WorkCategory]'s order), each in tier order then by gold cost, ties to
/// the id.
Map<WorkCategory, List<CampWork>> campWorksOf({
  required Map<String, dynamic> houses,
  required Map<String, dynamic> zones,
  required Map<String, dynamic> shops,
  required int chapter,
  required Iterable<String> flags,
  required int gold,
  required List<String> inventory,
  required Iterable<String> builtHouseIds,
  required Iterable<String> recruitedAllyIds,
}) {
  final held = flags.toSet();
  final built = builtHouseIds.toSet();
  final allies = recruitedAllyIds.toSet();

  List<String> zonesSetting(String flag) => [
        for (final MapEntry(:key, :value) in zones.entries)
          if (value is Map && value['rewardFlag']?.toString() == flag) key,
      ]..sort();
  List<String> zonesPaying(String itemId) => [
        for (final MapEntry(:key, :value) in zones.entries)
          if (value is Map<String, dynamic> &&
              materialCountsOf(value, 'rewardMaterials').containsKey(itemId))
            key,
      ]..sort();
  List<String> shopsStocking(String itemId) => [
        for (final MapEntry(:key, :value) in shops.entries)
          if (value is Map<String, dynamic> &&
              allShopStock(value).contains(itemId))
            key,
      ]..sort();

  final works = <CampWork>[];
  for (final MapEntry(key: id, :value) in houses.entries) {
    if (value is! Map<String, dynamic>) continue;
    final category = workCategoryOf(id, value);
    final tier = workTierOf(value);
    final comesIn = tierFirstChapter(tier);
    if (built.contains(id)) {
      works.add(CampWork(
          houseId: id,
          category: category,
          tier: tier,
          chapter: comesIn,
          state: WorkState.built));
      continue;
    }

    final allyId = value['requiredAllyId']?.toString() ?? '';
    final locks = [
      if (chapter < comesIn)
        WorkNeed(
            kind: WorkNeedKind.chapter,
            id: '$comesIn',
            have: chapter,
            need: comesIn),
      if (allyId.isNotEmpty && !allies.contains(allyId))
        WorkNeed(kind: WorkNeedKind.ally, id: allyId),
    ];
    if (locks.isNotEmpty) {
      works.add(CampWork(
          houseId: id,
          category: category,
          tier: tier,
          chapter: comesIn,
          state: WorkState.locked,
          needs: locks));
      continue;
    }

    final cost = (value['buildCost'] as num?)?.toInt() ?? 0;
    final materials = materialCountsOf(value, 'materialCost');
    final short = missingMaterials(inventory, materials);
    final needs = [
      for (final flag in missingRequiredFlags(value, held))
        WorkNeed(kind: WorkNeedKind.flag, id: flag, zoneIds: [
          ...zonesSetting(flag),
          // Clearing any of these opens it too.
          for (final other in unlockedByFlagsOf(value)) ...zonesSetting(other),
        ]),
      if (gold < cost)
        WorkNeed(kind: WorkNeedKind.gold, have: gold, need: cost),
      for (final MapEntry(key: itemId, value: need) in materials.entries)
        if (short.containsKey(itemId))
          WorkNeed(
            kind: WorkNeedKind.material,
            id: itemId,
            have: need - short[itemId]!,
            need: need,
            zoneIds: zonesPaying(itemId),
            shopIds: shopsStocking(itemId),
          ),
    ];
    works.add(CampWork(
      houseId: id,
      category: category,
      tier: tier,
      chapter: comesIn,
      state: needs.isEmpty ? WorkState.buildable : WorkState.shown,
      needs: needs,
    ));
  }

  int costOf(CampWork w) =>
      ((houses[w.houseId] as Map?)?['buildCost'] as num?)?.toInt() ?? 0;
  works.sort((a, b) {
    final byTier = a.tier.compareTo(b.tier);
    if (byTier != 0) return byTier;
    final byCost = costOf(a).compareTo(costOf(b));
    return byCost != 0 ? byCost : a.houseId.compareTo(b.houseId);
  });
  return {
    for (final category in WorkCategory.values)
      category: [
        for (final w in works)
          if (w.category == category) w
      ],
  };
}
