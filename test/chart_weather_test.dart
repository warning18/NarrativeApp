// The climate on the map (v1.204): the height, humidity and warmth
// calques paint flat and on the sphere, the weather layer paints and
// moves, the Layers sheet turns them on, the chip over the Journey names
// the sky, and a town is laid out for its climate.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/chart_globe.dart';
import 'package:narrative_data_app/data/city_plan.dart';
import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/climate_provider.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';
import 'package:narrative_data_app/widgets/chart_weather.dart';
import 'package:narrative_data_app/widgets/journey_fx.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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

  group('a town laid out for its climate', () {
    const districts = <CityDistrict>[];
    test('a dry land has scrub for trees and no fields', () {
      final wet = CityPlan.of(
          seed: 9,
          size: CitySize.town,
          water: '',
          districts: districts,
          climate: const CityClimate(
              elevation: 0.2, humidity: 0.9, temperature: 15));
      final dry = CityPlan.of(
          seed: 9,
          size: CitySize.town,
          water: '',
          districts: districts,
          climate: const CityClimate(
              elevation: 0.2, humidity: 0.1, temperature: 25));
      expect(identical(wet, dry), isFalse);
      expect(dry.trees.length, lessThan(wet.trees.length));
      expect(dry.buildings.where((b) => b.kind == CityBuildingKind.field),
          isEmpty);
      expect(wet.buildings.where((b) => b.kind == CityBuildingKind.field),
          isNotEmpty);
      expect(dry.climate.dry, isTrue);
    });

    test('a day of warmth does not lay the town out again', () {
      final a = CityPlan.of(
          seed: 11,
          size: CitySize.village,
          water: 'river',
          districts: districts,
          climate: const CityClimate(
              elevation: 0.3, humidity: 0.62, temperature: 12));
      final b = CityPlan.of(
          seed: 11,
          size: CitySize.village,
          water: 'river',
          districts: districts,
          climate: const CityClimate(
              elevation: 0.3, humidity: 0.64, temperature: 9));
      expect(identical(a, b), isTrue);
      final snow = CityPlan.of(
          seed: 11,
          size: CitySize.village,
          water: 'river',
          districts: districts,
          climate: const CityClimate(
              elevation: 0.3, humidity: 0.62, temperature: -4));
      expect(identical(a, snow), isFalse);
      expect(snow.climate.snow, isTrue);
      expect(
          CityClimate.of(ChartClimate.of(chartOf(MapShape.archipelago))
                  .sample(const Offset(60, 60)))
              .humidity,
          inInclusiveRange(0, 1));
    });
  });

  testWidgets('the Layers sheet turns the calques and the weather on',
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
    await tester.tap(find.text('Journey'));
    await _settle(tester);
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);

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
    await _settle(tester);
    expect(find.byType(JourneyWorldMap), findsOneWidget);
    expect(find.byType(ChartWeather), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_layers')));
    await _settle(tester);
    expect(find.byKey(const Key('journey_weather')), findsOneWidget);
    // With the weather on, it can be kept to the world zoom; the choice
    // is kept.
    expect(find.byKey(const Key('journey_weather_world_only')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_weather_world_only')));
    await _settle(tester);
    expect(container.read(chartWeatherWorldOnlyProvider), isTrue);
    await tester.tap(find.byKey(const Key('journey_weather')));
    await _settle(tester);
    expect(container.read(chartWeatherProvider), isFalse);
    expect(find.byKey(const Key('journey_weather_world_only')), findsNothing);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getBool(chartWeatherPrefsKey), isFalse);
    expect(prefs.getBool(chartWeatherWorldOnlyPrefsKey), isTrue);
    // The height calque, with its legend.
    await tester.scrollUntilVisible(find.byKey(const Key('calque_height')), 80,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const Key('calque_height')));
    await _settle(tester);
    expect(container.read(chartCalqueProvider), ChartCalque.height);
    // The sheet closed (it can fill the screen, so a tap above it
    // would land on it).
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);
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
