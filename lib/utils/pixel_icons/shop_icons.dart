/// Icon paths for shops (generated from shops.json).
class ShopIcons {
  ShopIcons._();

  static String pathFor(String shopId) =>
      'assets/icons/shops/${_borrowed[shopId] ?? shopId}.png';

  /// Shops drawn with another's icon until they have their own (none since
  /// v1.197: every shop hangs its own sign).
  static const Map<String, String> _borrowed = {};

  static const List<String> allIds = [
    'anchorage_chandlery',
    'apothecary_row',
    'arcane_academy',
    'arcane_bazaar',
    'black_market_docks',
    'blind_beggar_stall',
    'hammersmith_forge',
    'last_lantern',
    'ossuary_relics',
    'sharpweave_den',
    'shieldwrights_hall',
    'smugglers_vault',
    'wayfarer_caravan',
    'weaponsmith_forge',
  ];
}
