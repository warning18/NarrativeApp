// The map on a phone (v1.350): the sphere is where zooming out lands, its
// ball fills the box, the + and − buttons climb a ladder (world, land,
// district, closest), and the names are set large with a halo, the crowded
// ones left for a closer look.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/chart_globe.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/travel_history_provider.dart';
import 'package:narrative_data_app/screens/full_map_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  final travels = travelHistoryOf(
    history: const ['965', '1100', '1120', '1130'],
    currentNodeId: '1200',
  );

  Future<ProviderContainer> open(WidgetTester tester,
      {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        travelHistoryProvider.overrideWithValue(travels),
        storyDataProvider.overrideWith((ref) async => const StoryData({})),
      ],
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)),
        home: const FullMapScreen(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    return ProviderScope.containerOf(
        tester.element(find.byType(FullMapScreen)));
  }

  test('the zoom ladder climbs whole ball, filling, district, closest', () {
    const fill = 1.8;
    const z = JourneyWorldMapZoom.district;
    expect(JourneyWorldMapZoom.stopsFor(fill),
        [1, fill, z, JourneyWorldMapZoom.max]);
    expect(JourneyWorldMapZoom.stepIn(1, fill), fill);
    expect(JourneyWorldMapZoom.stepIn(fill, fill), z);
    expect(JourneyWorldMapZoom.stepIn(z, fill), JourneyWorldMapZoom.max);
    expect(JourneyWorldMapZoom.stepIn(JourneyWorldMapZoom.max, fill),
        JourneyWorldMapZoom.max);
    expect(JourneyWorldMapZoom.stepOut(JourneyWorldMapZoom.max, fill), z);
    expect(JourneyWorldMapZoom.stepOut(z, fill), fill);
    expect(JourneyWorldMapZoom.stepOut(fill, fill), 1);
    expect(JourneyWorldMapZoom.stepOut(1, fill), 1);
    // Between rungs (a pinch): the next rung either way.
    expect(JourneyWorldMapZoom.stepIn(1.5, fill), fill);
    expect(JourneyWorldMapZoom.stepOut(4, fill), fill);
  });

  test('the filling zoom covers the box, corners included', () {
    // A 360 x 480 box and a ball 324 px across at zoom 1.
    const box = Size(360, 480);
    final fill = JourneyWorldMapZoom.fillFor(box, 324);
    expect(fill * 324, closeTo(600, 0.01));
    // Never under the whole ball, never past its cap.
    expect(JourneyWorldMapZoom.fillFor(const Size(100, 100), 324), 1);
    expect(JourneyWorldMapZoom.fillFor(const Size(3000, 3000), 324),
        JourneyWorldMapZoom.fillMax);
    expect(JourneyWorldMapZoom.fillMax, lessThan(JourneyWorldMapZoom.district));
  });

  testWidgets('the map opens on the sphere filling its box, on the party',
      (tester) async {
    await open(tester);
    final globe = find.byKey(const ValueKey('journey_globe_canvas'));
    expect(globe, findsOneWidget);
    expect(find.byKey(const ValueKey('journey_world_canvas')), findsNothing);
    final box = tester.getSize(globe);
    expect(box.width, 360);
    final map = find.byType(JourneyWorldMap);
    GlobeView view() => journeyGlobeOf(tester.element(map))!;
    final k = box.shortestSide * 0.9 / (2 * GlobeView.baseRadius);
    // The ball's diameter is the box's diagonal: no empty corner.
    expect(view().radius * k * 2,
        closeTo(Offset(box.width, box.height).distance, 0.5));
    // Turned to the party: its place is at the middle of the box.
    final here = tester.widget<JourneyWorldMap>(map).here!;
    final story = chartOf(MapShape.story);
    expect(
        (view().clamp(story.of(here)) - view().centre).distance, lessThan(1));
    final opened = view().zoom;
    // − shows the whole ball, + comes back to the filling zoom.
    await tester.tap(find.byKey(const Key('journey_zoom_out')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(view().zoom, closeTo(1, 0.01));
    await tester.tap(find.byKey(const Key('journey_zoom_in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(view().zoom, closeTo(opened, 0.01));
    // Five buttons a thumb can hit: no pole buttons.
    expect(find.byKey(const Key('journey_pole_north')), findsNothing);
    for (final key in [
      'journey_layers',
      'journey_zoom_in',
      'journey_zoom_out'
    ]) {
      expect(tester.getSize(find.byKey(Key(key))), const Size(44, 44));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the fog lies on the sphere from its first frame',
      (tester) async {
    await open(tester);
    final painter = tester
        .widgetList<CustomPaint>(find.descendant(
            of: find.byKey(const ValueKey('journey_globe_canvas')),
            matching: find.byType(CustomPaint)))
        .map((c) => c.painter)
        .whereType<ChartMapPainter>()
        .single;
    // Nothing fades the fog in: a null reads as all of it.
    expect(painter.fogOf, isNull);
    // Names stop short of the button column.
    expect(painter.labelInsetRight, greaterThanOrEqualTo(44 + 8));
  });

  testWidgets('a sphere paints on a tiny canvas without a name too wide',
      (tester) async {
    await open(tester);
    tester.view.physicalSize = const Size(140, 300);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
