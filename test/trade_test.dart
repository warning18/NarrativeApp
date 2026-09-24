// Selling back and forging: a copy nobody wears sells for two fifths of
// its price (or its own sale value) and goes back on the shelf it came
// from; the forge turns iron ore and gold into gear.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';

Future<PlayerSessionNotifier> _notifierWith(Map<String, dynamic> json) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(PlayerSession.fromJson(json));
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sale prices', () {
    test('two fifths of the price, at least one gold', () {
      expect(sellPriceFor({'cost': 100}), 40);
      expect(sellPriceFor({'cost': 1}), 1);
      expect(sellPriceFor({'cost': 0}), 1);
    });

    test('an item\'s own sale value wins', () {
      expect(sellPriceFor({'cost': 90, 'sellValue': 60}), 60);
    });

    test('quest items are never sold', () {
      expect(canSellItem({'itemType': 'Quest'}), isFalse);
      expect(canSellItem({'itemType': 'Weapon'}), isTrue);
      expect(canSellItem(null), isFalse);
    });
  });

  group('selling', () {
    test('a sold copy pays and goes back on its shelf', () async {
      final notifier = await _notifierWith({
        'gold': 10,
        'inventoryItemIds': ['sword_t1', 'sword_t1'],
        'shopPurchaseCounts': {'weaponsmith_forge::sword_t1': 2},
      });
      expect(
          await notifier.sellItem('sword_t1',
              price: 16, shopId: 'weaponsmith_forge'),
          isTrue);
      expect(notifier.state.gold, 26);
      expect(notifier.state.inventoryItemIds, ['sword_t1']);
      expect(
          notifier.state.shopPurchaseCounts['weaponsmith_forge::sword_t1'], 1);
    });

    test('a worn copy cannot be sold', () async {
      final notifier = await _notifierWith({
        'gold': 0,
        'inventoryItemIds': ['sword_t1'],
        'equippedItemIds': ['sword_t1'],
      });
      expect(await notifier.sellItem('sword_t1', price: 16), isFalse);
      expect(notifier.state.inventoryItemIds, ['sword_t1']);
      expect(notifier.state.gold, 0);
    });
  });

  group('forging', () {
    final recipe = {
      'craftedAt': 'hammersmith_forge',
      'craftGold': 60,
      'craftMaterials': {'material_iron_ore': 3},
    };

    test('materials are read from the recipe', () {
      expect(craftMaterialsFor(recipe), {'material_iron_ore': 3});
      expect(craftMaterialsFor({'cost': 5}), isEmpty);
      expect(
          recipesAt('hammersmith_forge', {
            'x': recipe,
            'y': {'cost': 5}
          }),
          ['x']);
    });

    test('forging takes the ore and the gold and gives the piece', () async {
      final notifier = await _notifierWith({
        'gold': 100,
        'inventoryItemIds': [
          'material_iron_ore',
          'material_iron_ore',
          'material_iron_ore',
          'material_iron_ore',
        ],
      });
      expect(await notifier.craftItem('greaves_iron', recipe), isTrue);
      expect(notifier.state.gold, 40);
      expect(notifier.state.inventoryItemIds,
          ['material_iron_ore', 'greaves_iron']);
    });

    test('nothing is forged without enough ore or gold', () async {
      final notifier = await _notifierWith({
        'gold': 100,
        'inventoryItemIds': ['material_iron_ore', 'material_iron_ore'],
      });
      expect(notifier.canCraft(recipe), isFalse);
      expect(await notifier.craftItem('greaves_iron', recipe), isFalse);
      expect(notifier.state.gold, 100);

      final poor = await _notifierWith({
        'gold': 10,
        'inventoryItemIds': List.filled(3, 'material_iron_ore'),
      });
      expect(poor.canCraft(recipe), isFalse);
    });
  });
}
