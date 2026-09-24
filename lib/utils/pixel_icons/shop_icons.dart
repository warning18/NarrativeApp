/// Icon paths for shops (generated from shops.json).
class ShopIcons {
  ShopIcons._();

  static String pathFor(String shopId) => 'assets/icons/shops/$shopId.png';

  static const List<String> allIds = [
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
    'weaponsmith_forge',
  ];
}
