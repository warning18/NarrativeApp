// Smoke test for the actual app. The previous version of this file was
// still Flutter's default counter-app template, testing a widget that
// hasn't existed in this project for a long time — it passed on every run
// regardless of whether the app itself still built or rendered.
//
// This pumps the real widget tree (ProviderScope > MyApp > the main menu,
// then HomeShell, which eagerly builds every tab via an IndexedStack) with
// SharedPreferences mocked to an empty store, and checks it renders its
// main chrome without throwing. It deliberately uses bounded pump()s
// rather than pumpAndSettle(), since the tree contains an unbounded
// Future.delayed animation trigger that pumpAndSettle would wait on
// forever.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'app opens on the main menu; Edit Mode and a new game open the game',
      (WidgetTester tester) async {
    // Resetting the session reads the game data off the asset bundle,
    // real I/O the fake test clock doesn't advance: each step lets it run.
    Future<void> pumpABit() async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await pumpABit();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
    // A fresh install: no story to continue, no New Game+ yet.
    expect(find.byKey(const Key('menu_new_game')), findsOneWidget);
    expect(find.byKey(const Key('menu_continue')), findsNothing);
    expect(find.byKey(const Key('menu_new_game_plus')), findsNothing);
    expect(find.byKey(const Key('menu_load')), findsOneWidget);
    expect(find.byKey(const Key('menu_settings')), findsOneWidget);
    expect(find.byKey(const Key('menu_edit_mode')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // Edit Mode: Story, Play, Generate, Data, and the map in the header.
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await pumpABit();
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Generate'), findsOneWidget);
    expect(find.byTooltip('Story Map'), findsOneWidget);

    // Back to the menu from the header.
    await tester.tap(find.byTooltip('Main menu'));
    await pumpABit();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('menu_edit_mode')), findsOneWidget);

    // A new game plays: Story, Character, Camp, Other (under character
    // creation, which the first scene opens).
    await tester.tap(find.byKey(const Key('menu_new_game')));
    await pumpABit();
    expect(tester.takeException(), isNull);
    final bar = find.byType(NavigationBar, skipOffstage: false);
    expect(find.byType(NavigationDestination, skipOffstage: false),
        findsNWidgets(4));
    for (final label in ['Character', 'Camp', 'Other']) {
      expect(
          find.descendant(
              of: bar, matching: find.text(label, skipOffstage: false)),
          findsOneWidget,
          reason: label);
    }
    expect(find.text('Generate', skipOffstage: false), findsNothing);
  });
}
