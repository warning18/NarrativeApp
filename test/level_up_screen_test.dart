// Level Up: a stat point goes straight into the stat, with no message on
// top of the screen; the row's value is what changes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';

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

    final before = container.read(playerSessionProvider);
    await tester.tap(find.text('+1 Point').first);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    final after = container.read(playerSessionProvider);
    expect(after.statPoints, before.statPoints - 1);
    expect(find.byType(SnackBar), findsNothing);
  });
}
