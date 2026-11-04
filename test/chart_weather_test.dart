// The climate on the map (v1.204): the height, humidity and warmth
// calques paint flat and on the sphere, the weather layer paints and
// moves, the Layers sheet turns them on, the chip over the Journey names
// the sky.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/chart_globe.dart';
import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/climate_provider.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';
import 'package:narrative_data_app/widgets/chart_weather.dart';
import 'package:narrative_data_app/widgets/journey_fx.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

ChartMapPainter _painter(ChartCalque calque, {GlobeView? globe}) =>
    ChartMapPainter(
      frame: ValueNotifier(0),
      walk: const AlwaysStoppedAnimation(0),
      geography: chartOf(MapShape.archipelago),
      palette: ChartPalette.of(MapLook.night),
      language: AppLanguage.en,
      discovered: {for (final l in worldMapLandmarks) l.id},
      legs: const [],
      ahead: null,
      selectedId: '',
      here: worldMapLandmarks.first,
      walking: false,
      walkPath: const [],
      chapterFilter: 0,
      reduceMotion: true,
      chapterColor: (_) => Colors.red,
      calque: calque,
      globe: globe,
    );

void main() {
  group('climate calques', () {
    test('tints run low to high, dry to wet, cold to warm', () {
      expect(ChartMapPainter.climateTint(ChartCalque.height, 0),
          isNot(ChartMapPainter.climateTint(ChartCalque.height, 1)));
      expect(ChartMapPainter.climateTint(ChartCalque.height, 1),
          const Color(0xFFF2F2F2));
      expect(ChartMapPainter.climateTint(ChartCalque.humidity, 0),
          const Color(0xFFCB9A55));
      expect(ChartMapPainter.climateTint(ChartCalque.warmth, 1),
          const Color(0xFFBF3A2B));
      expect(ChartMapPainter.warmthScale(-15), 0);
      expect(ChartMapPainter.warmthScale(30), 1);
      expect(ChartMapPainter.warmthScale(7.5), closeTo(0.5, 1e-9));
      expect(ChartCalque.height.climate, isTrue);
      expect(ChartCalque.clans.climate, isFalse);
    });

    for (final calque in [
      ChartCalque.height,
      ChartCalque.humidity,
      ChartCalque.warmth,
    ]) {
      testWidgets('${calque.name} paints flat and on the sphere',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Column(children: [
            SizedBox(
                width: 256,
                height: 176,
                child: CustomPaint(painter: _painter(calque))),
            SizedBox(
                width: 256,
                height: 256,
                child: CustomPaint(
                    painter: _painter(calque,
                        globe: GlobeView.at(const Offset(128, 88), 1.2,
                            const Offset(128, 128))))),
          ]),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the weather layer', () {
    testWidgets('paints the sky, then holds still: no frame is asked for',
        (tester) async {
      final geo = chartOf(MapShape.archipelago);
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: ChartWeather(
            size: const Size(256, 176),
            geography: geo,
            palette: ChartPalette.of(MapLook.night),
            day: 4,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      // The fade done, the sky asks for no more frames: time stands still
      // until the story's day turns (v1.210).
      expect(tester.binding.hasScheduledFrame, isFalse);
      // On the sphere, too.
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: ChartWeather(
            size: const Size(300, 300),
            geography: geo,
            palette: ChartPalette.of(MapLook.parchment),
            day: 4,
            globe: GlobeView.at(
                const Offset(100, 60), 1.5, const Offset(150, 150)),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    test('the Journey draws what the sky brings, and the burning ash', () {
      expect(journeyWeatherOf(WeatherKind.rain, 1), JourneyWeather.rain);
      expect(journeyWeatherOf(WeatherKind.snow, 5), JourneyWeather.snow);
      expect(journeyWeatherOf(WeatherKind.dust, 4), JourneyWeather.dust);
      expect(journeyWeatherOf(WeatherKind.fog, 4), JourneyWeather.fog);
      expect(journeyWeatherOf(WeatherKind.ash, 6), JourneyWeather.ash);
      expect(journeyWeatherOf(WeatherKind.clear, 1), JourneyWeather.ash);
      expect(journeyWeatherOf(WeatherKind.cloud, 2), JourneyWeather.ash);
      expect(journeyWeatherOf(WeatherKind.clear, 4), JourneyWeather.none);
      expect(journeyWeatherOf(null, 5), JourneyWeather.none);
    });

    testWidgets(
        'the fog clears the lands reached and the roads walked, and fades in',
        (tester) async {
      final walked = [
        (worldMapLandmarks[0], worldMapLandmarks[1]),
        (worldMapLandmarks[1], worldMapLandmarks[2]),
      ];
      for (final fogOf in [0.0, 0.5, 1.0]) {
        final painter = ChartMapPainter(
          frame: ValueNotifier(0),
          walk: const AlwaysStoppedAnimation(0),
          geography: chartOf(MapShape.archipelago),
          palette: ChartPalette.of(MapLook.night),
          language: AppLanguage.en,
          discovered: {
            for (final (a, b) in walked) ...[a.id, b.id]
          },
          legs: walked,
          ahead: null,
          selectedId: '',
          here: worldMapLandmarks[2],
          walking: false,
          walkPath: const [],
          chapterFilter: 0,
          reduceMotion: true,
          chapterColor: (_) => Colors.red,
          fog: ChartFog.uncharted,
          fogOf: () => fogOf,
        );
        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
              width: 256, height: 176, child: CustomPaint(painter: painter)),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'fog $fogOf');
      }
    });

    testWidgets('a sky kept to the world zoom paints nothing closer in',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: ChartWeather(
            size: const Size(256, 176),
            geography: chartOf(MapShape.archipelago),
            palette: ChartPalette.of(MapLook.night),
            day: 4,
            showOf: () => false,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('dust and fog paint over the Journey', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CustomPaint(
          size: const Size(300, 300),
          painter: _FxProbe(),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the Layers sheet turns the calques and the weather on',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester, overrides: [storedCityPlans]);
    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('2001');
    await settleApp(tester);
    play.jumpTo('2005');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);

    // The sky over the party, named in a chip on the place map.
    expect(container.read(skyHereProvider), isNotNull);
    final chip = find.byKey(const ValueKey('journey_weather_chip'));
    expect(chip, findsOneWidget);
    final text = tester.widget<Text>(chip).data!;
    expect(text, contains('°'));
    expect(text, matches(RegExp(r'\d+ m')));

    // Out to the world: the weather layer moves over the chart until it
    // is turned off, and the choice is kept.
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await settleApp(tester);
    // A city looked out from shows the whole town first (v1.350), then the
    // land.
    // (A scene inside a building steps out into its streets first.)
    for (var i = 0;
        i < 3 && find.byType(JourneyWorldMap).evaluate().isEmpty;
        i++) {
      await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
      await settleApp(tester);
    }
    expect(find.byType(JourneyWorldMap), findsOneWidget);
    expect(find.byType(ChartWeather), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_layers')));
    await settleApp(tester);
    expect(find.byKey(const Key('journey_weather')), findsOneWidget);
    // With the weather on, it can be kept to the world zoom; the choice
    // is kept.
    expect(find.byKey(const Key('journey_weather_world_only')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_weather_world_only')));
    await settleApp(tester);
    expect(container.read(chartWeatherWorldOnlyProvider), isTrue);
    await tester.tap(find.byKey(const Key('journey_weather')));
    await settleApp(tester);
    expect(container.read(chartWeatherProvider), isFalse);
    expect(find.byKey(const Key('journey_weather_world_only')), findsNothing);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getBool(chartWeatherPrefsKey), isFalse);
    expect(prefs.getBool(chartWeatherWorldOnlyPrefsKey), isTrue);
    // The Clans calque (the sheet keeps the plain map, Clans and chapters).
    await tester.scrollUntilVisible(find.byKey(const Key('calque_clans')), 80,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const Key('calque_clans')));
    await settleApp(tester);
    expect(container.read(chartCalqueProvider), ChartCalque.clans);
    // The sheet closed (it can fill the screen, so a tap above it
    // would land on it).
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settleApp(tester);
    expect(find.byType(ChartWeather), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

/// Paints every Journey weather once, the new ones included.
class _FxProbe extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final w in JourneyWeather.values) {
      paintJourneyWeather(canvas, size, 3.2, w, const Color(0xFFC9A46A));
    }
  }

  @override
  bool shouldRepaint(_FxProbe old) => false;
}
