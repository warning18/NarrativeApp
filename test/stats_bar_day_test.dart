// The top bar from chapter 2 (v1.186 kept two clocks there): the day
// shows once, as the world clock, red while the chapter's enemies gather
// and saying so, with the rations beside it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/player_stats_bar.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the day shows once, red while the chapter\'s enemies gather',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
        overrides: [reachedChapterProvider.overrideWithValue(3)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
        home: const Scaffold(body: SafeArea(child: PlayerStatsBar())),
      ),
    ));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    Future<void> day(int day, {required int from}) async {
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'day': day,
            'clockChapter': 3,
            'chapterStartDay': from,
          })));
      await _settle(tester);
    }

    final scheme =
        Theme.of(tester.element(find.byType(PlayerStatsBar))).colorScheme;
    Text clock() => tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('stats_clock')), matching: find.byType(Text)));
    String clockTip() => tester
        .widget<Tooltip>(find.descendant(
            of: find.byKey(const Key('stats_clock')),
            matching: find.byType(Tooltip)))
        .message!;

    // Eleven days into chapter 3, three past its grace of eight: +9%.
    await day(12, from: 1);
    expect(find.text('J12'), findsOneWidget);
    // Once: the road's own "Jour 12" is gone.
    expect(find.textContaining('Jour'), findsNothing);
    expect(clock().style?.color, scheme.error);
    expect(clockTip(), contains('Jour 12'));
    expect(clockTip(), contains('Vos ennemis se rassemblent (+9 %)'));
    // The rations still show beside it.
    expect(find.byIcon(Icons.restaurant), findsOneWidget);

    // Within the grace, the clock is its usual self.
    await day(4, from: 1);
    expect(find.text('J4'), findsOneWidget);
    expect(clock().style?.color, isNot(scheme.error));
    expect(clockTip(), isNot(contains('ennemis')));
    expect(tester.takeException(), isNull);
  });
}
