// The camp's building tray (v1.350): Houses and Additions as tabs, filters
// for what is ready, what can be afforded, what stands and the category,
// an empty state that clears them, and the "built / limit" slot.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_works.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/camp_build_tray.dart';
import 'package:narrative_data_app/widgets/camp_town_section.dart';

CampWork _work(WorkState state,
        {List<WorkNeed> needs = const [],
        WorkCategory category = WorkCategory.sea}) =>
    CampWork(
        houseId: 'h',
        category: category,
        tier: 1,
        chapter: 1,
        state: state,
        needs: needs);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final f in Directory('assets/gamedata').listSync()) {
      if (f.path.endsWith('.json')) await rootBundle.loadString(f.path);
    }
  });

  test('the filters keep what they say', () {
    final ready = _work(WorkState.buildable);
    final built = _work(WorkState.built);
    final locked = _work(WorkState.locked,
        needs: const [WorkNeed(kind: WorkNeedKind.chapter, id: '3')]);
    final noGold = _work(WorkState.shown, needs: const [
      WorkNeed(kind: WorkNeedKind.gold, have: 1, need: 50),
    ]);
    final noFlag = _work(WorkState.shown,
        needs: const [WorkNeed(kind: WorkNeedKind.flag, id: 'f')]);
    expect(workPasses(ready), isTrue);
    expect(workPasses(ready, filter: BuildFilter.ready), isTrue);
    expect(workPasses(noFlag, filter: BuildFilter.ready), isFalse);
    // Affordable: the gold and the pack are there; a flag may still wait.
    expect(workPasses(noFlag, filter: BuildFilter.affordable), isTrue);
    expect(workPasses(noGold, filter: BuildFilter.affordable), isFalse);
    expect(workPasses(locked, filter: BuildFilter.affordable), isFalse);
    expect(workPasses(built, filter: BuildFilter.affordable), isFalse);
    expect(workPasses(built, filter: BuildFilter.built), isTrue);
    expect(workPasses(ready, filter: BuildFilter.built), isFalse);
    expect(workPasses(ready, category: WorkCategory.sea), isTrue);
    expect(workPasses(ready, category: WorkCategory.company), isFalse);
    final cut = filteredWorks({
      WorkCategory.sea: [ready, built],
      WorkCategory.company: [locked],
    }, filter: BuildFilter.built);
    expect(cut.keys, [WorkCategory.sea]);
    expect(cut[WorkCategory.sea], [built]);
  });

  test('the slot says built over limit, or a count with no limit', () {
    expect(slotText(0, 1), '0/1');
    expect(slotText(2, 3), '2/3');
    expect(slotText(0, null), isNull);
    expect(slotText(2, null), '×2');
  });

  testWidgets('tabs, filters, the empty state and the slot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1400);
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
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
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

    Finder card(String id) => find.byKey(Key('town_card_$id'));
    Future<void> tap(String key) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await tester.pump(const Duration(milliseconds: 200));
    }

    // The slot: Kelda's hall is unique, none standing yet.
    await tester.ensureVisible(card('keldas_hall'));
    expect(
        find.descendant(
            of: find.byKey(const Key('town_slot_keldas_hall')),
            matching: find.text('0/1')),
        findsOneWidget);

    // Ready: only what can go up now.
    expect(find.textContaining('Ready 1'), findsOneWidget);
    await tap('town_filter_ready');
    expect(card('keldas_hall'), findsOneWidget);
    expect(card('harbor'), findsNothing);
    await tap('town_filter_ready');
    // A category.
    await tap('town_category_sea');
    expect(card('harbor'), findsOneWidget);
    expect(card('keldas_hall'), findsNothing);
    await tap('town_category_sea');
    // Built: nothing stands, so the empty state offers a way back.
    await tap('town_filter_built');
    expect(find.byKey(const Key('town_filter_empty')), findsOneWidget);
    await tap('town_filter_clear');
    expect(find.byKey(const Key('town_filter_empty')), findsNothing);
    expect(card('keldas_hall'), findsOneWidget);

    // Additions: a tab of their own, with their slots (the watchtower is
    // unique, the floors have none).
    await tap('town_tab_additions');
    expect(card('add_tower'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('town_slot_add_tower')),
            matching: find.text('0/1')),
        findsOneWidget);
    expect(find.byKey(const Key('town_slot_add_floor')), findsNothing);
    // The category chips belong to the houses only.
    expect(find.byKey(const Key('town_category_sea')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
