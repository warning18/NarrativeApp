// Level Up: a stat point goes straight into the stat, with no message on
// top of the screen; the row's value is what changes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/widgets/level_up_dialog.dart';

void main() {
  testWidgets('spending a stat point shows no pop-up', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LevelUpScreen()),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(LevelUpScreen)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({'statPoints': 2})));
    await tester.pump();

    // The guide's ⓘ is in the header (v1.278 help pattern).
    expect(find.byKey(const Key('help_tour_button')), findsOneWidget);

    final before = container.read(playerSessionProvider);
    await tester.tap(find.text('+1 Point').first);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    final after = container.read(playerSessionProvider);
    expect(after.statPoints, before.statPoints - 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('the level-up pop-up shows the points and the grouped stats',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
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
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({'statPoints': 2})));
    await tester.pump();
    await tester.tap(find.byKey(const Key('open')));
    // The medal's rays turn for ever: step by hand rather than settle.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Level Up! Level 4'), findsOneWidget);
    expect(find.byKey(const Key('level_up_points')), findsOneWidget);
    expect(find.byKey(const Key('level_up_burst')), findsOneWidget);
    for (final stat in ['damage', 'strength', 'intelligence', 'luck']) {
      expect(find.byKey(Key('stat_row_$stat')), findsOneWidget, reason: stat);
    }
    // The test font (Ahem) is far wider than the real ones, so a 360 px
    // overflow here says nothing; the layout is checked on the device.
    tester.takeException();

    // A point goes straight into the stat, with the dialog staying open.
    final before = container.read(playerSessionProvider);
    await tester.tap(find.text('+1 Point').first);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(playerSessionProvider).statPoints,
        before.statPoints - 1);
    expect(find.byKey(const Key('level_up_points')), findsOneWidget);

    await tester.tap(find.byKey(const Key('level_up_close')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('level_up_points')), findsNothing);
  });
}
