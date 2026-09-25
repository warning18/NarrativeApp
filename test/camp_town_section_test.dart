// The camp's build tray: Build raises a house or an addition on the town,
// a locked house says what it waits on, and one out of reach says what
// gold is missing.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/camp_town_section.dart';

void main() {
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
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({'gold': 400})));
    await tester.pump();

    // A house behind a zone waits on it; one out of reach says so.
    await tester.drag(find.byType(ListView), const Offset(-900, 0));
    await tester.pump();
    expect(find.textContaining('Requires'), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(900, 0));
    await tester.pump();

    await tester.tap(find.byKey(const Key('town_build_keldas_hall')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    var session = container.read(playerSessionProvider);
    expect(session.builtHouseIds, ['keldas_hall']);
    expect(session.gold, 250);
    expect(find.textContaining('goes up on the quay'), findsOneWidget);
    // The notice that the house is built covers the screen for a moment.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

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
    await build('add_store');
    session = container.read(playerSessionProvider);
    expect(session.townPieces,
        ['keldas_hall', 'add_floor', 'add_store', 'add_store']);
    expect(session.gold, 30);
    // 30 gold left: nothing more can go up, and the cards say what is
    // missing.
    expect(find.byKey(const Key('town_build_add_floor')), findsNothing);
    expect(find.textContaining('need'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
