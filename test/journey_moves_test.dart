// The Journey walks the party only where the story does (v1.224): a way
// that keeps the party where it stands (working the
// Blind Beggar's table it stands at) leaves it on its mark; a way that
// carries it somewhere (out the back door, into the streets) walks it there.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('only a way that carries the party somewhere walks it there',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'flags': ['casino_tables'],
        })));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);

    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('106');
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);

    // Two ways: the next table (the party stays at the tables) and the way
    // out the back, into the streets.
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_2')), findsNothing);

    // The way out walks the party there.
    await tester.tap(find.byKey(const ValueKey('journey_step_1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_traveller')), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _settle(tester);
    expect(container.read(storyPlayProvider).currentNodeId, '250');

    // A way taken where the party already stands (working the table it is
    // at) keeps it there: no walk.
    play.jumpTo('110');
    await _settle(tester);
    if (find.byKey(const ValueKey('journey_continue')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('journey_continue')));
      await _settle(tester);
    }
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(const ValueKey('journey_step_0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('journey_traveller')), findsNothing);
    }
    await _settle(tester);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}
