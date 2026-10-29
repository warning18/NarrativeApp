// The camp's build tray: Build raises a house or an addition on the town,
// a locked house says what it waits on, and one out of reach says what
// gold is missing.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/camp_town_section.dart';

/// Waits for the tables the building list reads (houses, zones, shops,
/// chapters: they load from the bundle).
Future<void> _loadTables(
    WidgetTester tester, ProviderContainer container) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The tables load from the bundle: read them once for real.
    for (final f in Directory('assets/gamedata').listSync()) {
      if (f.path.endsWith('.json')) await rootBundle.loadString(f.path);
    }
  });

  testWidgets('building from the tray raises houses and additions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final houses =
        json.decode(File('assets/gamedata/houses.json').readAsStringSync())
            as Map<String, dynamic>;

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CampTownSection(
              houses: houses,
              shops: const {},
              zones: const {},
              achievements: const {},
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(CampTownSection)));
    await _loadTables(tester, container);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          // Kelda's hall costs 100 gold and 2 timber (v1.281.0, materials).
          'gold': 350,
          'inventoryItemIds': ['material_timber', 'material_timber'],
          // Her hall waits for her (v1.287.0, camp_works.dart).
          'recruitedAllies': [
            {'companionId': 'kelda'},
          ],
        })));
    await tester.pump();

    // A house of a later chapter is a silhouette with one reason (here, in
    // chapter 1, the later tiers' "Chapter 3").
    expect(
        find.byKey(const Key('works_silhouette_hammersmith')), findsOneWidget);
    expect(find.text('Chapter 3'), findsWidgets);

    final buildKelda = find.byKey(const Key('town_build_keldas_hall'));
    await tester.ensureVisible(buildKelda);
    await tester.pump();
    await tester.tap(buildKelda);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    var session = container.read(playerSessionProvider);
    expect(session.builtHouseIds, ['keldas_hall']);
    expect(session.gold, 250);
    expect(find.textContaining('goes up on the quay'), findsOneWidget);
    // The notice that the house is built covers the screen for a moment.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('town_tab_additions')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('town_tab_additions')));
    await tester.pump();
    Future<void> build(String id) async {
      final button = find.byKey(Key('town_build_$id'));
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    await build('add_floor');
    session = container.read(playerSessionProvider);
    expect(session.townPieces, ['keldas_hall', 'add_floor']);
    expect(session.gold, 210);
    expect(find.textContaining('need'), findsNothing);
    await build('add_store');
    // One house up: one storehouse at most (cliff_town.dart's limits), so
    // its card says so and the watchtower goes up instead.
    expect(find.textContaining('Limit reached: 1 of 1'), findsOneWidget);
    expect(find.byKey(const Key('town_build_add_store')), findsNothing);
    await build('add_tower');
    session = container.read(playerSessionProvider);
    expect(session.townPieces,
        ['keldas_hall', 'add_floor', 'add_store', 'add_tower']);
    expect(session.gold, 0);
    // No gold left: nothing more can go up, and the cards say what is
    // missing.
    final floor = find.byKey(const Key('town_build_add_floor'));
    await tester.ensureVisible(floor);
    expect(tester.widget<FilledButton>(floor).onPressed, isNull);
    expect(find.textContaining('need'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a house shows what it costs beside gold as chips, short in count',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final houses =
        json.decode(File('assets/gamedata/houses.json').readAsStringSync())
            as Map<String, dynamic>;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CampTownSection(
              houses: houses,
              shops: const {},
              zones: const {},
              achievements: const {},
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(CampTownSection)));
    // Kelda's hall costs 2 timber: one is held.
    await _loadTables(tester, container);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'gold': 350,
          'inventoryItemIds': ['material_timber'],
          'recruitedAllies': [
            {'companionId': 'kelda'},
          ],
        })));
    await tester.pump();
    final chips = find.descendant(
        of: find.byKey(const Key('town_materials_keldas_hall')),
        matching: find.byKey(const Key('town_material_material_timber')));
    await tester.ensureVisible(chips);
    expect(chips, findsOneWidget);
    expect(
        find.descendant(of: chips, matching: find.text('1/2')), findsOneWidget);
    // The card names the first thing missing, and the sheet where to find it.
    final first = find.byKey(const Key('works_first_need_keldas_hall'));
    expect(first, findsOneWidget);
    expect(tester.widget<Text>(first).data, contains('1/2'));
    // The Parley Tent (v1.477) pushed Kelda's Hall below the window.
    await tester.ensureVisible(find.byKey(const Key('town_card_keldas_hall')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('town_card_keldas_hall')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('works_sheet')), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('works_sheet_build')))
            .onPressed,
        isNull);
    await tester.tap(find.byKey(const Key('works_sheet_close')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Held in full, the chip is the plain count.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'gold': 350,
          'inventoryItemIds': ['material_timber', 'material_timber'],
          'recruitedAllies': [
            {'companionId': 'kelda'},
          ],
        })));
    await tester.pump();
    expect(
        find.descendant(of: chips, matching: find.text('2')), findsOneWidget);
    // Ready: the sheet names the cost and the button carries the price.
    await tester.tap(find.byKey(const Key('town_card_keldas_hall')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        find.byKey(const Key('works_sheet_cost_keldas_hall')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('works_sheet_build')),
            matching: find.textContaining(' G')),
        findsOneWidget);
  });

  testWidgets('a missing material says in plain text where to find it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Map<String, dynamic> table(String name) =>
        json.decode(File('assets/gamedata/$name.json').readAsStringSync())
            as Map<String, dynamic>;
    final zones = table('zones');
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CampTownSection(
              houses: table('houses'),
              shops: table('shops'),
              zones: zones,
              achievements: const {},
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(CampTownSection)));
    await _loadTables(tester, container);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({'gold': 10})));
    await tester.pump();

    // The Barracks Annex is short of gold and materials in a bare pack.
    final card = find.byKey(const Key('town_card_barracks_annex'));
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    final sheet = find.byKey(const Key('works_sheet'));
    expect(sheet, findsOneWidget);
    expect(
        find.descendant(
            of: sheet,
            matching: find.byWidgetPredicate((w) =>
                w is RichText &&
                w.text.toPlainText().startsWith('Expeditions:'))),
        findsWidgets);
    expect(find.descendant(of: sheet, matching: find.textContaining('G more')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the built Skillwright carries the way into the craft',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Map<String, dynamic> table(String name) =>
        json.decode(File('assets/gamedata/$name.json').readAsStringSync())
            as Map<String, dynamic>;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CampTownSection(
              houses: table('houses'),
              shops: table('shops'),
              zones: table('zones'),
              achievements: const {},
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(CampTownSection)));
    await _loadTables(tester, container);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'builtHouseIds': ['skillwright'],
          'unlockedSkillIds': ['fireball', 'shadow_step'],
        })));
    await tester.pump();

    final craft = find.byKey(const Key('works_craft_skillwright'));
    await tester.ensureVisible(craft);
    await tester.pump();
    await tester.tap(craft);
    await tester.pump();
    // The recipes load behind the open bench.
    await _loadTables(tester, container);
    await tester.pumpAndSettle();
    // The bench opens on its recipes, a ready one with its Merge.
    expect(find.byKey(const Key('merge_blazing_shadow')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
