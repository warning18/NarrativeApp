// The Journey map at rest (v1.209): once nothing on it moves, its clock
// stops and the map holds its frame; the next moment (coming back to the
// tab) starts it again. Its own file, as journey_motion_still_test is:
// two Journeys opened in one process do not start alike.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart'
    show debugJourneyMapsTicking;
import 'package:narrative_data_app/widgets/journey_fx.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _fx = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is JourneyFxPainter);

Future<ProviderContainer> _openJourney(WidgetTester tester) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
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
  await tester.runAsync(() =>
      container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson(
          {'raceId': 'human', 'professionId': 'warrior'})));
  await tester.runAsync(
      () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
  await _settle(tester);
  final play = container.read(storyPlayProvider.notifier);
  play.jumpTo('2001');
  await _settle(tester);
  play.jumpTo('2005');
  await _settle(tester);
  return container;
}

void main() {
  testWidgets('the map holds its frame once nothing on it moves (v1.209)',
      (tester) async {
    final container = await _openJourney(tester);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await _settle(tester);
    // Opened: the unroll, the ways inking in, the stamp. It moves.
    expect(_fx, findsOneWidget);
    expect(debugJourneyMapsTicking.value, greaterThan(0));
    // Past every moment (the stamp fades by 4.2 s, the settling window
    // after the last event is 3.8 s): the clock stops, the layer stays.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(debugJourneyMapsTicking.value, 0);
    expect(_fx, findsOneWidget);
    // Nothing wakes it on its own.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(debugJourneyMapsTicking.value, 0);
    // Coming back to the tab is a moment (the map unrolls): the clock
    // runs again, then rests.
    container.read(homeTabIndexProvider.notifier).state = 1;
    await _settle(tester);
    expect(debugJourneyMapsTicking.value, 0);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await tester.pump(const Duration(milliseconds: 100));
    expect(debugJourneyMapsTicking.value, greaterThan(0));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(debugJourneyMapsTicking.value, 0);
    expect(tester.takeException(), isNull);
  });
}
