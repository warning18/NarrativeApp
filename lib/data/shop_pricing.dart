import 'dart:math';

import 'factions.dart';

/// What a shop charges (v1.162): a silver tongue haggles. Each point of
/// Charisma takes [charismaDiscountPerPoint] off the listed price, up to
/// [maxCharismaDiscount].
const double charismaDiscountPerPoint = 0.02;
const double maxCharismaDiscount = 0.20;

double charismaDiscountFor(int charisma) =>
    min(maxCharismaDiscount, max(0, charisma) * charismaDiscountPerPoint);

/// [cost] after the buyer's [charisma] discount; never below 1 for
/// anything that had a price.
int shopPriceFor(int cost, int charisma) {
  if (cost <= 0) return cost;
  return max(1, (cost * (1 - charismaDiscountFor(charisma))).round());
}

/// The faction a shop belongs to (shops.json `faction`, v1.193), '' for
/// none: its prices follow the character's standing with them.
String shopFactionId(Map<String, dynamic>? shop) =>
    shop?['faction']?.toString().trim() ?? '';

/// [price] at the shop of a faction the character stands at [tier] with
/// (see tierPriceFactor: +40% Hostile ... -25% Sworn), never below 1 for
/// anything that had a price. A shop of no faction ([tier] null) charges
/// [price]; null when the faction hunts the character: no trade.
int? factionPriceFor(int price, StandingTier? tier) {
  if (tier == null || price <= 0) return price;
  final factor = tierPriceFactor(tier);
  if (factor == null) return null;
  return max(1, (price * factor).round());
}

/// Whether a shop of a faction the character stands at [tier] with
/// refuses to trade at all (buying, selling, the forge): a Hunted one.
bool shopRefusesTrade(StandingTier? tier) =>
    tier != null && tierPriceFactor(tier) == null;

/// Item types a shop restocks every chapter (v1.162): the things that get
/// used up. Gear stays one of a kind.
const Set<String> restockingItemTypes = {'Potion', 'Scroll'};

/// The key a purchase of [itemId] at [shopId] is counted under: gear once
/// for the whole run, a restocking type once per [chapter].
String stockKeyFor(String shopId, String itemId,
        {String? itemType, required int chapter}) =>
    restockingItemTypes.contains(itemType)
        ? '$shopId::$itemId@$chapter'
        : '$shopId::$itemId';
