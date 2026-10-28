// The inventory with tabs (v1.594, lib/widgets/inventory_parts.dart,
// lib/screens/inventory_screen.dart): tabs only for the kinds the bag holds,
// six slot tiles with the die by its name, one quiet line and one labelled
// button on a row, a gold dot for what is new, and the compare behind a long
// press.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'package:narrative_data_app/widgets/inventory_parts.dart';

import 'player_session_provider_test.dart' show baseSession;

Future<ProviderContainer> _mount(
  WidgetTester tester, {
  required List<String> bag,
  List<String> worn = const [],
  List<String>? dice,
  String? die,
  Map<String, Object> prefs = const {},
  AppLanguage language = AppLanguage.en,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(appLanguageProvider);
  final notifier = container.read(playerSessionProvider.notifier);
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.runAsync(() => notifier.loadSession(baseSession().copyWith(
        inventoryItemIds: bag,
        equippedItemIds: worn,
        ownedDiceIds: dice ?? const ['starter_die'],
        equippedDiceId: die ?? 'starter_die',
      )));
  if (language != AppLanguage.en) {
    container.read(appLanguageProvider.notifier).state = language;
  }
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: InventoryScreen()),
  ));
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the kinds', () {
    test('every item type of items.json falls in exactly one tab', () {
      final items =
          jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
              as Map<String, dynamic>;
      final types = {for (final i in items.values) (i as Map)['itemType']};
      expect(types, isNotEmpty);
      for (final type in types) {
        final kind = inventoryKindOf({'itemType': type});
        expect(kind, isNotNull, reason: '$type has a tab');
        expect(kind, isNot(InventoryTab.all));
      }
      // Every tab has strings in both languages.
      for (final tab in InventoryTab.values) {
        final key = inventoryTabLabelKey(tab);
        expect(trFor(AppLanguage.en, key), isNot(key));
        expect(trFor(AppLanguage.fr, key), isNot(key));
      }
    });

    test('newest is the one last in the bag; rarity puts a Relic first', () {
      final items = {
        'a': {'itemName': 'Axe', 'rarity': 'Common'},
        'b': {'itemName': 'Bow', 'rarity': 'Relic'},
        'c': {'itemName': 'Cap', 'rarity': 'Rare'},
      };
      const pack = ['b', 'a', 'c', 'a'];
      List<String> sorted(InventorySort s) =>
          sortInventoryIds(['a', 'b', 'c'], items, s, pack);
      expect(sorted(InventorySort.newest), ['a', 'c', 'b']);
      expect(sorted(InventorySort.rarity), ['b', 'c', 'a']);
      expect(sorted(InventorySort.name), ['a', 'b', 'c']);
    });
  });

  group('the screen', () {
    // Each test mounts the app on the bundle afresh.
    setUp(rootBundle.clear);

    testWidgets('only the kinds the bag holds get a tab, with counts',
        (tester) async {
      await _mount(tester, bag: ['sword_001', 'armor_leather', 'potion_minor']);
      expect(find.byKey(const Key('inv_tab_all')), findsOneWidget);
      expect(find.byKey(const Key('inv_tab_gear')), findsOneWidget);
      expect(find.byKey(const Key('inv_tab_potions')), findsOneWidget);
      expect(find.byKey(const Key('inv_tab_charms')), findsNothing);
      expect(find.byKey(const Key('inv_tab_books')), findsNothing);
      expect(
          find.descendant(
              of: find.byKey(const Key('inv_tab_all')),
              matching: find.text('3')),
          findsOneWidget);
      await tester.tap(find.byKey(const Key('inv_tab_potions')));
      await tester.pump();
      expect(find.byKey(const Key('inv_row_potion_minor')), findsOneWidget);
      expect(find.byKey(const Key('inv_row_sword_001')), findsNothing);
    });

    testWidgets('the die is named, not its id', (tester) async {
      await _mount(tester, bag: ['sword_001']);
      expect(find.text('Lucky Die'), findsOneWidget);
      expect(find.text('starter_die'), findsNothing);
    });

    testWidgets('Equip wears the piece and the row offers Take off',
        (tester) async {
      final c = await _mount(tester, bag: ['armor_leather']);
      expect(find.text('Common'), findsNothing,
          reason: 'a Common is not worth a word');
      expect(find.textContaining('goes on the Body'), findsOneWidget);
      await tester.tap(find.byKey(const Key('inv_action_armor_leather')));
      await tester.pump();
      expect(c.read(playerSessionProvider).equippedItemIds,
          contains('armor_leather'));
      expect(find.text('Take off'), findsOneWidget);
      expect(find.textContaining('worn on the Body'), findsOneWidget);
      await tester.tap(find.byKey(const Key('inv_action_armor_leather')));
      await tester.pump();
      expect(c.read(playerSessionProvider).equippedItemIds, isEmpty);
    });

    testWidgets('a gold dot marks what came since the last visit',
        (tester) async {
      await _mount(tester, bag: [
        'sword_001',
        'armor_leather'
      ], prefs: {
        'inventory_seen': ['sword_001']
      });
      expect(find.byKey(const Key('inv_new_armor_leather')), findsOneWidget);
      expect(find.byKey(const Key('inv_new_sword_001')), findsNothing);
    });

    testWidgets('the first visit marks nothing as new', (tester) async {
      await _mount(tester, bag: ['sword_001', 'armor_leather']);
      expect(find.byKey(const Key('inv_new_armor_leather')), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('inventory_seen'),
          ['armor_leather', 'sword_001']);
    });

    testWidgets('the last tab is remembered', (tester) async {
      await _mount(tester,
          bag: ['sword_001', 'potion_minor'],
          prefs: {'inventory_tab': 'potions'});
      expect(find.byKey(const Key('inv_row_potion_minor')), findsOneWidget);
      expect(find.byKey(const Key('inv_row_sword_001')), findsNothing);
      await tester.tap(find.byKey(const Key('inv_tab_gear')));
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('inventory_tab'), 'gear');
    });

    testWidgets('a long press starts the compare from that piece',
        (tester) async {
      await _mount(tester, bag: ['sword_001', 'armor_leather']);
      await tester.longPress(find.byKey(const Key('inv_row_sword_001')));
      await tester.pump();
      expect(find.text(trFor(AppLanguage.en, 'compare_first_selected')),
          findsOneWidget);
      expect(find.byKey(const Key('inv_action_sword_001')), findsNothing,
          reason: 'no buttons while comparing');
    });

    testWidgets('the Dice tile picks among the dice owned, by name',
        (tester) async {
      final c = await _mount(tester,
          bag: ['sword_001'], dice: ['starter_die', 'iron_die']);
      expect(find.byKey(const Key('inv_tab_dice')), findsNothing,
          reason: 'dice are in their slot, not in the bag');
      await tester.tap(find.byKey(const Key('slot_Dice')));
      await tester.pumpAndSettle();
      expect(find.text('Iron Die'), findsOneWidget);
      await tester.tap(find.text('Iron Die'));
      await tester.pumpAndSettle();
      expect(c.read(playerSessionProvider).equippedDiceId, 'iron_die');
      expect(find.text('Iron Die'), findsOneWidget, reason: 'now in its slot');
    });

    testWidgets('French tabs and lines', (tester) async {
      await _mount(tester,
          bag: ['armor_leather', 'potion_minor'], language: AppLanguage.fr);
      expect(find.text('Équipement'), findsWidgets);
      expect(find.text('Potions'), findsOneWidget);
      expect(find.text('Retirer'), findsNothing);
      expect(find.text('Équiper'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
