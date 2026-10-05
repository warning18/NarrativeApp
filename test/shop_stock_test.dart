// Shops v1.197: a wandering shop draws its shelf from a pool each chapter
// (the same draw everywhere, one thing from the chapter ahead), and the
// keeper speaks by the standing with the shop's faction.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/shop_stock.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final shops = _json('shops');
  final items = _json('items');
  final caravan = shops['wayfarer_caravan'] as Map<String, dynamic>;

  test('the caravan draws six of its pool, the same for a chapter', () {
    final pool = (caravan['stockPool'] as List).cast<String>();
    final ch2 = shopStockWithAhead(caravan, chapter: 2, items: items);
    expect(ch2.length, 6);
    expect(ch2.toSet().length, 6);
    expect(pool, containsAll(ch2));
    expect(shopStockWithAhead(caravan, chapter: 2, items: items), ch2);
    final ch3 = shopStockWithAhead(caravan, chapter: 3, items: items);
    expect(ch3, isNot(ch2), reason: 'the mules decide again');
    // One thing from the chapter ahead.
    int loot(String id) =>
        ((items[id] as Map<String, dynamic>)['lootChapter'] as num).toInt();
    expect(ch2.any((id) => loot(id) > 2), isTrue);
    expect(allShopStock(caravan), pool);
  });

  test('a settled shop sells its stock, every id real, no two shops alike', () {
    final forge = shops['weaponsmith_forge'] as Map<String, dynamic>;
    expect(shopStockFor(forge, chapter: 4), forge['initialStock']);
    final seen = <String, String>{};
    for (final e in shops.entries) {
      for (final id in allShopStock(e.value as Map<String, dynamic>)) {
        expect(items.containsKey(id), isTrue, reason: '${e.key}: $id');
        // Potions and salves may sit on several shelves; gear on one.
        final type = (items[id] as Map<String, dynamic>)['itemType'];
        if (const {'Potion', 'Charm', 'Tome', 'Material', 'Scroll'}
            .contains(type)) {
          continue;
        }
        expect(seen.containsKey(id), isFalse,
            reason: '$id at ${e.key} and ${seen[id]}');
        seen[id] = e.key;
      }
    }
  });

  test('tiers 4 and 5 and the Harborwatch set have a shop', () {
    final sold = {
      for (final v in shops.values) ...allShopStock(v as Map<String, dynamic>),
    };
    for (final id in [
      'sword_t4',
      'spear_t5',
      'dagger_t4',
      'harborwatch_coat',
      'harborwatch_lantern',
      'armor_leather',
      'cultist_hood',
      'hollow_court_seal',
    ]) {
      expect(sold, contains(id));
    }
  });

  test('the keeper speaks by standing', () {
    final forge = shops['weaponsmith_forge'] as Map<String, dynamic>;
    expect(shopKeeperName(forge, AppLanguage.en), 'Orrin Vell');
    expect(shopKeeperLine(forge, AppLanguage.en, tier: StandingTier.known),
        startsWith('Steel for honest coin'));
    expect(shopKeeperLine(forge, AppLanguage.en, tier: StandingTier.wary),
        contains('hasn’t chosen you'));
    expect(shopKeeperLine(forge, AppLanguage.en, tier: StandingTier.hostile),
        contains('hasn’t chosen you'));
    expect(shopKeeperLine(forge, AppLanguage.en, tier: StandingTier.trusted),
        contains('fifteen off'));
    // In « vous », like every French line in the game (v1.201.2).
    expect(shopKeeperLine(forge, AppLanguage.fr, tier: StandingTier.sworn),
        contains('Nommez la lame'));
    // A free trader has one line for everyone.
    final bazaar = shops['arcane_bazaar'] as Map<String, dynamic>;
    expect(shopKeeperLine(bazaar, AppLanguage.en, tier: null),
        shopKeeperLine(bazaar, AppLanguage.en, tier: StandingTier.sworn));
    // Every shop has a keeper, a line, and (but the free traders) a clan.
    for (final e in shops.entries) {
      final shop = e.value as Map<String, dynamic>;
      expect(shopKeeperName(shop, AppLanguage.fr), isNotNull, reason: e.key);
      expect(shopKeeperLine(shop, AppLanguage.fr), isNotNull, reason: e.key);
    }
  });
}
