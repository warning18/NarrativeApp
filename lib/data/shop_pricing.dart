import 'dart:math';

/// What a shop charges (v1.160): a silver tongue haggles. Each point of
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

/// Item types a shop restocks every chapter (v1.160): the things that get
/// used up. Gear stays one of a kind.
const Set<String> restockingItemTypes = {'Potion', 'Scroll'};

/// The key a purchase of [itemId] at [shopId] is counted under: gear once
/// for the whole run, a restocking type once per [chapter].
String stockKeyFor(String shopId, String itemId,
        {String? itemType, required int chapter}) =>
    restockingItemTypes.contains(itemType)
        ? '$shopId::$itemId@$chapter'
        : '$shopId::$itemId';
