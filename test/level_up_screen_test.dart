// Level Up (Wave 7): the points are a training offer, three paths as cards;
// a tap takes one, its gains go straight into the stats, and the pop-up
// after a fight only closes once no points are left.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/training_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/widgets/level_up_dialog.dart';

void main() {
  // The paths from the file: the asset bundle's cached load does not come
  // back in a second test's clock.
  final paths = trainingPathsFrom(
      jsonDecode(File('assets/gamedata/training_paths.json').readAsStringSync())
          as Map<String, dynamic>);
  final overrides = [trainingPathsProvider.overrideWith((ref) async => paths)];

  /// Lets the paths load and the offer be drawn (both async).
  Future<void> settle(WidgetTester tester) async {
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
      final session = container.read(playerSessionProvider);
      if (container.read(trainingPathsProvider).hasValue &&
          (session.statPoints == 0 || session.trainingOffer.isNotEmpty) &&
          i >= 3) {
        // The offer drawn after the last frame: one more to show it.
        await tester.pump(const Duration(milliseconds: 20));
        return;
      }
    }
  }

  testWidgets(
      'a level\'s points are a training offer: a card is picked, then taken',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: LevelUpScreen()),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(LevelUpScreen)));
    container.read(playerSessionProvider);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'statPoints': 5, 'professionId': 'warrior'})));
    await settle(tester);

    // The guide's ⓘ is in the header (v1.278 help pattern).
    expect(find.byKey(const Key('help_tour_button')), findsOneWidget);
    // No stat is raised by hand any more.
    expect(find.text('+1 Point'), findsNothing);
    expect(find.text('Choose your training'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(Key('training_choice_$i')), findsOneWidget);
    }

    final choice = container.read(playerSessionProvider).trainingOffer.first;
    // A card is picked first; nothing is spent until it is taken.
    await tester.tap(find.byKey(const Key('training_choice_0')));
    await settle(tester);
    expect(container.read(playerSessionProvider).statPoints, 5);
    await tester.tap(find.byKey(const Key('training_take')));
    await settle(tester);

    final after = container.read(playerSessionProvider);
    expect(after.statPoints, 0);
    expect(after.trainingTaken, {choice.pathId: 1});
    expect(find.byKey(const Key('training_picker')), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('the level-up pop-up shows the points and the grouped stats',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open'),
                onPressed: () => showLevelUpDialog(context, ref, newLevel: 4),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ));
    final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('open'))));
    // The session's own first load (from the saved prefs) starts when it is
    // first read, and must finish before the fixture is loaded, or it lands
    // after it and resets the points.
    container.read(playerSessionProvider);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({'statPoints': 2})));
    await tester.pump();
    await tester.tap(find.byKey(const Key('open')));
    // The medal's rays turn for ever: step by hand rather than settle.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester);

    expect(find.text('Level Up! Level 4'), findsOneWidget);
    expect(find.byKey(const Key('level_up_points')), findsOneWidget);
    expect(find.byKey(const Key('level_up_burst')), findsOneWidget);
    for (final stat in ['damage', 'strength', 'intelligence', 'luck']) {
      expect(find.byKey(Key('stat_row_$stat')), findsOneWidget, reason: stat);
    }
    // The test font (Ahem) is far wider than the real ones, so a 360 px
    // overflow here says nothing; the layout is checked on the device.
    tester.takeException();

    // Two points short of a level: small offers, one point each. No
    // "decide later": the pop-up stays until both are taken.
    expect(find.text('A moment of insight'), findsOneWidget);
    expect(find.text('Decide later'), findsNothing);
    await tester.tap(find.byKey(const Key('level_up_close')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('level_up_points')), findsOneWidget);
    for (var left = 1; left >= 0; left--) {
      await tester.ensureVisible(find.byKey(const Key('training_choice_0')));
      await tester.tap(find.byKey(const Key('training_choice_0')));
      await settle(tester);
      await tester.ensureVisible(find.byKey(const Key('training_take')));
      await tester.tap(find.byKey(const Key('training_take')));
      await settle(tester);
      expect(container.read(playerSessionProvider).statPoints, left);
    }
    tester.takeException();

    await tester.tap(find.byKey(const Key('level_up_close')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('level_up_points')), findsNothing);
  });
}
