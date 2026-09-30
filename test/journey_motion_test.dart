// The Journey map's motion: its effects run only while the tab is on
// screen, never with the system's reduced motion, and each chapter has
// its weather.
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
import 'package:narrative_data_app/screens/journey_screen.dart';
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
  test('each chapter has its weather', () {
    expect(journeyWeatherFor(1), JourneyWeather.ash);
    expect(journeyWeatherFor(2), JourneyWeather.ash);
    expect(journeyWeatherFor(4), JourneyWeather.rain);
    expect(journeyWeatherFor(5), JourneyWeather.snow);
    expect(journeyWeatherFor(0), JourneyWeather.none);
  });

  testWidgets('the effects run only while the Journey tab is on screen',
      (tester) async {
    final container = await _openJourney(tester);
    void show(int tab) =>
        container.read(homeTabIndexProvider.notifier).state = tab;
    // On the Story tab, the Journey map (kept behind it) draws nothing.
    expect(_fx, findsNothing);
    show(journeyTabIndex);
    // Past the unroll and the new chapter burning open.
    await _settle(tester);
    await _settle(tester);
    expect(_fx, findsOneWidget);
    // Picking a step and a shut way's rattle don't get in the way.
    await tester.tap(find.byKey(const ValueKey('journey_step_0')),
        warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    show(0);
    await _settle(tester);
    expect(_fx, findsNothing);
  });
}
