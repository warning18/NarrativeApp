// The UX pass of v1.201: sections fold and remember it, the inventory
// lays its slots out in boxes at phone width, the Character tab keeps
// its titles behind a fold and has no Clans card.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/character_screen.dart';
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'package:narrative_data_app/widgets/ink_fold.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a fold hides its body, and the choice is kept', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: InkFold(
            id: 'demo',
            title: 'Places you know',
            count: 2,
            children: [Text('Alster'), Text('The cove')],
          ),
        ),
      ),
    ));
    expect(find.text('Alster'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('fold_demo')));
    await tester.pumpAndSettle();
    expect(find.text('Alster'), findsNothing);
    final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('fold_demo'))));
    expect(container.read(foldedSectionsProvider), contains('demo'));
    await tester.tap(find.byKey(const Key('fold_demo')));
    await tester.pumpAndSettle();
    expect(find.text('Alster'), findsOneWidget);
  });

  testWidgets('the inventory lays its slots out in boxes at phone width',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: InventoryScreen()),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(InventoryScreen)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'inventoryItemIds': ['sword_001', 'armor_leather'],
          'equippedItemIds': ['sword_001'],
        })));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('slot_Weapon')), findsOneWidget);
    expect(find.byKey(const Key('slot_Top')), findsOneWidget);
    expect(find.text('EQUIPMENT'), findsOneWidget);
    expect(
        find.textContaining(RegExp('equipped', caseSensitive: false),
            skipOffstage: false),
        findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Character tab folds its titles and has no Clans card',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: CharacterScreen(embedded: true))),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(CharacterScreen)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('character_clans'), skipOffstage: false),
        findsNothing);
    final fold =
        find.byKey(const Key('fold_character_titles'), skipOffstage: false);
    expect(fold, findsOneWidget);
    expect(
        find.byKey(const Key('fold_body_character_titles'),
            skipOffstage: false),
        findsNothing);
    await tester.ensureVisible(fold);
    await tester.tap(fold);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('fold_body_character_titles'),
            skipOffstage: false),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
