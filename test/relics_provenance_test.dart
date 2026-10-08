// Relics, lore and provenance (v1.204): a Relic sits with the Rares in
// the chest and reads heroic to the clans; where each item came from is
// kept on the session, first acquisition wins, and the save round-trips
// (an older save has none); the inventory's detail dialog shows an
// item's lore, its rarity tag and the "Yours since" line.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/loot_box.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart' show SignRarity;
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/item_origin.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'package:narrative_data_app/widgets/item_lore.dart';

import 'player_session_provider_test.dart' show baseSession, notifierWith;

Map<String, dynamic> _gear(String id,
        {String rarity = 'Rare', int lootChapter = 1}) =>
    {
      'id': id,
      'itemName': id,
      'itemType': 'Weapon',
      'isEquippable': true,
      'equipSlot': 'Weapon',
      'rarity': rarity,
      'lootChapter': lootChapter,
    };

const LootContext _context = LootContext(chapter: 5);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('relics', () {
    test('the chest draws a Relic with the Rares, and it never ages out', () {
      expect(gearRaritiesFor(ChestTier.gold), contains('Relic'));
      expect(gearRaritiesFor(ChestTier.voidTier), contains('Relic'));
      expect(gearRaritiesFor(ChestTier.silver), isNot(contains('Relic')));
      expect(
          gearRaritiesFor(ChestTier.wooden, rareOnly: true), {'Rare', 'Relic'});
      final items = {
        'relic': _gear('relic', rarity: 'Relic', lootChapter: 1),
        'old_rare': _gear('old_rare', lootChapter: 1),
        'old_common': _gear('old_common', rarity: 'Common', lootChapter: 1),
      };
      final weights = gearWeightsFor(_context, items, ChestTier.gold);
      expect(weights.keys, containsAll(['relic', 'old_rare']));
      expect(weights.keys, isNot(contains('old_common')));
      expect(rarityOptions, contains('Relic'));
    });

    test('a Relic reads heroic to the clans', () {
      expect(rarityOfItem(const {'rarity': 'Relic'}), SignRarity.heroic);
      expect(rarityOfItem(const {'rarity': 'Rare'}), SignRarity.epic);
      expect(rarityOfItem(const {'rarity': 'Common'}), SignRarity.common);
    });

    test('the rarity has its words and its colour', () {
      expect(itemRarityLabelFor(AppLanguage.en, 'Relic'), 'Relic');
      expect(itemRarityLabelFor(AppLanguage.fr, 'Relic'), 'Relique');
      expect(itemRarityLabelFor(AppLanguage.fr, 'Uncommon'), 'Peu commun');
      expect(itemRarityLabelFor(AppLanguage.en, ''), '');
      expect(itemRarityLabelFor(AppLanguage.en, 'Mythic'), 'Mythic');
      const scheme = ColorScheme.light();
      expect(itemRarityColor(scheme, 'Relic'), relicColor);
      expect(itemRarityColor(scheme, 'Common'), scheme.onSurfaceVariant);
      expect(itemRarityColor(scheme, 'Rare'), scheme.tertiary);
    });
  });

  group('provenance', () {
    const here = ItemOrigin(placeId: 'alster_lower_town', chapter: 1);
    const later = ItemOrigin(placeId: 'saltmouth_wharf', chapter: 2);

    test('the first acquisition wins, and nothing is written without one', () {
      final once = withItemOrigins(const {}, ['sword'], here);
      expect(once, {'sword': here});
      final again = withItemOrigins(once, ['sword', 'helm'], later);
      expect(again, {'sword': here, 'helm': later});
      expect(identical(withItemOrigins(again, ['sword'], later), again), isTrue,
          reason: 'nothing new: the same map');
      expect(identical(withItemOrigins(again, ['axe'], null), again), isTrue);
      expect(withItemOrigins(const {}, ['', 'x'], here), {'x': here});
    });

    test('every adding method records it once', () async {
      final notifier = await notifierWith(
          baseSession(activeQuestIds: ['q_a', 'q_b'], gold: 500));
      await notifier.completeQuest('q_a', rewardItemId: 'sword', origin: here);
      expect(notifier.state.itemOrigins, {'sword': here});
      // The same sword a second time keeps the first origin.
      await notifier.completeQuest('q_b', rewardItemId: 'sword', origin: later);
      expect(notifier.state.itemOrigins, {'sword': here});
      expect(notifier.state.inventoryItemIds, ['sword', 'sword']);
      await notifier.applyChoiceEffects(itemId: 'charm', origin: later);
      await notifier.applyCombatResult(
          hpAfter: 50, itemsGained: const ['helm', 'sword'], origin: later);
      await notifier.completeZone('z', rewardItemId: 'ring', origin: later);
      await notifier.buyItem('shop', 'cloak', 10, 5, origin: later);
      expect(notifier.state.itemOrigins, {
        'sword': here,
        'charm': later,
        'helm': later,
        'ring': later,
        'cloak': later,
      });
      // A potion becomes charges, never a pack entry: no origin.
      await notifier.completeQuest('q_c',
          rewardItemId: 'potion_minor',
          rewardItem: const {'itemType': 'Potion'},
          origin: later);
      expect(notifier.state.itemOrigins.containsKey('potion_minor'), isFalse);
    });

    test('the save round-trips, and an older save has none', () {
      final session = baseSession().copyWith(
          inventoryItemIds: const ['sword'], itemOrigins: {'sword': here});
      final json = jsonDecode(jsonEncode(session.toJson()));
      final back = PlayerSession.fromJson(json as Map<String, dynamic>);
      expect(back.itemOrigins, {'sword': here});
      expect(json['itemOrigins'], {
        'sword': {'placeId': 'alster_lower_town', 'chapter': 1}
      });
      final old = Map<String, dynamic>.from(json)..remove('itemOrigins');
      expect(PlayerSession.fromJson(old).itemOrigins, isEmpty);
      expect(PlayerSession.fromJson(old).inventoryItemIds, ['sword']);
      // seenNpcIds (the People badge) rides along the same way.
      final seen = baseSession().copyWith(seenNpcIds: const ['lysa']);
      expect(PlayerSession.fromJson(seen.toJson()).seenNpcIds, ['lysa']);
      expect(PlayerSession.fromJson(old).seenNpcIds, isEmpty);
    });

    test('the line names the place mid-sentence, or the chapter alone', () {
      final geography = Geography.parse(geography: {
        'alster_lower_town': {
          'level': 'district',
          'name': 'The Lower Town',
          'name_fr': 'La Ville basse',
        },
      });
      expect(itemOriginLineFor(here, geography, AppLanguage.en),
          'Yours since the Lower Town, chapter 1');
      expect(itemOriginLineFor(here, geography, AppLanguage.fr),
          'À vous depuis la Ville basse, chapitre 1');
      expect(itemOriginLineFor(later, geography, AppLanguage.en),
          'Yours since chapter 2');
      expect(itemOriginLineFor(later, geography, AppLanguage.fr),
          'À vous depuis le chapitre 2');
      expect(itemOriginLineFor(null, geography, AppLanguage.en), isNull);
    });

    testWidgets('the inventory dialog shows lore, rarity and provenance',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'en',
        'tutorial_enabled': false,
        'gamedb_items': jsonEncode({
          'saint_bone': {
            'id': 'saint_bone',
            'itemName': 'Saint’s Knucklebone',
            'itemType': 'Artifact',
            'isEquippable': true,
            'equipSlot': 'Accessory',
            'rarity': 'Relic',
            'cost': 300,
            'description': 'A finger-bone the Reliquary swore it had burned.',
          },
        }),
        'gamedb_item_sets': jsonEncode(<String, dynamic>{}),
        'gamedb_geography': jsonEncode({
          'alster_lower_town': {'level': 'district', 'name': 'The Lower Town'},
        }),
        'gamedb_biomes': jsonEncode(<String, dynamic>{}),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appLanguageProvider);
      final notifier = container.read(playerSessionProvider.notifier);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.runAsync(() => notifier.loadSession(baseSession().copyWith(
            inventoryItemIds: const ['saint_bone'],
            itemOrigins: {'saint_bone': here},
          )));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: InventoryScreen()),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();

      // The tile carries the rarity tag.
      expect(find.byKey(const Key('rarity_tag_saint_bone')), findsOneWidget);
      expect(find.text('Relic'), findsOneWidget);
      await tester.ensureVisible(find.text('Saint’s Knucklebone'));
      await tester.tap(find.text('Saint’s Knucklebone'));
      await tester.pumpAndSettle();
      expect(find.text('A finger-bone the Reliquary swore it had burned.'),
          findsOneWidget);
      expect(find.byKey(const Key('detail_note')), findsOneWidget);
      expect(
          find.text('Yours since the Lower Town, chapter 1'), findsOneWidget);
      expect(find.text('Rarity'), findsOneWidget);
      expect(find.text('Relic'), findsNWidgets(2), reason: 'tag and row');
      expect(tester.takeException(), isNull);
    });
  });
}
