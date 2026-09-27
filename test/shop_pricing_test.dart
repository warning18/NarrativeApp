// Shop prices and restocking (v1.160): Charisma haggles the price down, and
// potions and scrolls come back every chapter while gear stays one of a kind.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/shop_pricing.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shopPriceFor', () {
    test('each point of Charisma takes 2% off', () {
      expect(shopPriceFor(100, 0), 100);
      expect(shopPriceFor(100, 1), 98);
      expect(shopPriceFor(100, 5), 90);
    });

    test('the discount stops at 20%', () {
      expect(shopPriceFor(100, 10), 80);
      expect(shopPriceFor(100, 25), 80);
      expect(charismaDiscountFor(99), maxCharismaDiscount);
    });

    test('never free, and a negative Charisma is no surcharge', () {
      expect(shopPriceFor(1, 10), 1);
      expect(shopPriceFor(0, 10), 0);
      expect(shopPriceFor(100, -3), 100);
    });
  });

  group('stockKeyFor', () {
    test('gear is counted once for the run', () {
      expect(
          stockKeyFor('smithy', 'iron_sword', itemType: 'Weapon', chapter: 2),
          'smithy::iron_sword');
      expect(stockKeyFor('smithy', 'iron_sword', chapter: 5),
          'smithy::iron_sword');
    });

    test('potions and scrolls are counted per chapter', () {
      for (final type in restockingItemTypes) {
        final ch2 = stockKeyFor('apothecary', 'x', itemType: type, chapter: 2);
        final ch3 = stockKeyFor('apothecary', 'x', itemType: type, chapter: 3);
        expect(ch2, isNot(ch3), reason: type);
        expect(ch2, 'apothecary::x@2');
      }
    });
  });

  test('a bought-out potion is back on the shelf next chapter', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await notifier.loadSession(baseSession(gold: 1000));

    final ch2 = stockKeyFor('apothecary', 'health_potion',
        itemType: 'Potion', chapter: 2);
    final ch3 = stockKeyFor('apothecary', 'health_potion',
        itemType: 'Potion', chapter: 3);
    await notifier.buyItem('apothecary', 'health_potion', 20, 1, stockKey: ch2);
    expect(notifier.state.gold, 980);
    // Sold out for chapter 2...
    await notifier.buyItem('apothecary', 'health_potion', 20, 1, stockKey: ch2);
    expect(notifier.state.gold, 980);
    // ...and restocked in chapter 3.
    await notifier.buyItem('apothecary', 'health_potion', 20, 1, stockKey: ch3);
    expect(notifier.state.gold, 960);
  });
}
