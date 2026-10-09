// The Journey map's motion: its effects run only while the tab is on
// screen, never with the system's reduced motion, and each chapter has
// its weather.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/journey_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
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

  test('the effects layer redraws on a rebuild only for a change (v1.209)', () {
    final clock = ValueNotifier<double>(0);
    JourneyFxPainter painter({
      Offset here = const Offset(40, 300),
      JourneyWeather weather = JourneyWeather.ash,
      List<JourneyFxStep> steps = const [
        JourneyFxStep(
            centre: Offset(60, 120),
            kind: JourneyStepKind.fight,
            colour: Color(0xFFAA3333),
            locked: false,
            row: 0),
      ],
      int? selected,
      (Offset, double)? rattle,
      ValueNotifier<double>? time,
    }) =>
        JourneyFxPainter(
          time: time ?? clock,
          steps: steps,
          here: here,
          hereRadius: 26,
          stepRadius: 22,
          mark: const Color(0xFF102030),
          fog: const Color(0xFFEEEEEE),
          weather: weather,
          weatherColour: const Color(0xFF8FC3CF),
          selected: selected,
          rattle: rattle,
        );
    final same = painter();
    // The same fields, the same clock: the ticks redraw it, a rebuild
    // need not.
    expect(painter().shouldRepaint(same), isFalse);
    // Anything it draws from changing must.
    expect(painter(here: const Offset(41, 300)).shouldRepaint(same), isTrue);
    expect(painter(weather: JourneyWeather.rain).shouldRepaint(same), isTrue);
    expect(painter(selected: 0).shouldRepaint(same), isTrue);
    expect(painter(rattle: (const Offset(60, 120), 1.5)).shouldRepaint(same),
        isTrue);
    expect(painter(steps: const []).shouldRepaint(same), isTrue);
    expect(
        painter(steps: const [
          JourneyFxStep(
              centre: Offset(60, 120),
              kind: JourneyStepKind.fight,
              colour: Color(0xFFAA3333),
              locked: true,
              row: 0),
        ]).shouldRepaint(same),
        isTrue);
    expect(painter(time: ValueNotifier<double>(0)).shouldRepaint(same), isTrue);
  });

  testWidgets('the effects run only while the Journey tab is on screen',
      (tester) async {
    final container = await _openJourney(tester);
    void show(int tab) =>
        container.read(homeTabIndexProvider.notifier).state = tab;
    // On another tab, the Journey map (kept behind it) draws nothing.
    show(1);
    await _settle(tester);
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
    show(1);
    await _settle(tester);
    expect(_fx, findsNothing);
  });
}
