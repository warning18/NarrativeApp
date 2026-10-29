// The move over the world chart (wave 14): the party walks the road Core's
// worldLegPath lays on the chart, slowly, while the camera closes in on it,
// follows, and pulls back out at the end.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_leg_path.dart';
import 'package:narrative_data_app/data/world_map.dart' show MapLook;
import 'package:narrative_data_app/providers/map_look_provider.dart'
    show chartGlobeProvider;
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';

void main() {
  final chart = chartOf(MapShape.story);

  test('a move takes longer than the Journey\'s short walks', () {
    final saved = worldMoveTimeScale;
    addTearDown(() => worldMoveTimeScale = saved);
    worldMoveTimeScale = 1;
    final short = worldLegPath(chart, 'crash', 'sleeper');
    final long = worldLegPath(chart, 'alster', 'candlehold');
    expect(worldMoveDuration(short),
        greaterThanOrEqualTo(const Duration(seconds: 6)));
    expect(worldMoveDuration(long),
        lessThanOrEqualTo(const Duration(seconds: 13)));
    expect(worldMoveDuration(long),
        greaterThanOrEqualTo(worldMoveDuration(short)));
  });

  test('the walker takes the bends: smoothed, the ends kept', () {
    final path = worldLegPath(chart, 'alster', 'candlehold');
    final smooth = smoothedWalkPoints(path.points);
    expect(smooth.first, path.points.first);
    expect(smooth.last, path.points.last);
    expect(smooth.length, greaterThan(path.points.length));
  });

  Future<AnimationController> pumpMove(WidgetTester tester,
      {required bool sphere}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(
        () => container.read(chartGlobeProvider.notifier).choose(sphere));
    final path = worldLegPath(chart, 'alster', 'candlehold');
    final clock = AnimationController(
        vsync: tester, duration: const Duration(seconds: 10));
    addTearDown(clock.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 500,
            child: JourneyWorldMap(
              level: JourneyMapLevel.world,
              palette: ChartPalette.of(MapLook.night),
              here: null,
              discovered: const {},
              legs: const [],
              ahead: null,
              shopPlaces: const {},
              campPlaces: const {},
              chapterColor: (_) => Colors.amber,
              onLayers: () {},
              move: path,
              moveClock: clock,
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    return clock;
  }

  testWidgets('the camera closes in on the party, follows, pulls back out',
      (tester) async {
    final clock = await pumpMove(tester, sphere: false);
    double scale() => tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .getMaxScaleOnAxis();

    // At the start the whole world is in view.
    expect(scale(), closeTo(1, 0.01));
    // Mid-move the camera is on the party at the land's zoom.
    clock.value = 0.5;
    await tester.pump();
    expect(scale(), closeTo(JourneyWorldMapZoom.land, 0.01));
    // Closing in on the way there.
    clock.value = 0.09;
    await tester.pump();
    expect(scale(), inExclusiveRange(1.1, JourneyWorldMapZoom.land - 0.1));
    // Arrived: the whole world again.
    clock.value = 1;
    await tester.pump();
    expect(scale(), closeTo(1, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a drag or a zoom takes the camera; recentre gives it back',
      (tester) async {
    final clock = await pumpMove(tester, sphere: false);
    double scale() => tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .getMaxScaleOnAxis();

    clock.value = 0.5;
    await tester.pump();
    expect(scale(), closeTo(JourneyWorldMapZoom.land, 0.01));
    // The player zooms out: the follow lets go and the camera stays put.
    await tester.tap(find.byKey(const Key('journey_zoom_out')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final taken = scale();
    expect(taken, lessThan(JourneyWorldMapZoom.land - 0.2));
    clock.value = 0.6;
    await tester.pump();
    expect(scale(), closeTo(taken, 0.01));
    // Recentre: the camera is on the party again.
    await tester.tap(find.byKey(const Key('journey_recentre')));
    await tester.pump();
    expect(scale(), closeTo(JourneyWorldMapZoom.land, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('on the sphere the globe turns with the party', (tester) async {
    final clock = await pumpMove(tester, sphere: true);
    expect(find.byKey(const ValueKey('journey_globe_canvas')), findsOneWidget);
    for (final t in [0.0, 0.1, 0.3, 0.5, 0.8, 1.0]) {
      clock.value = t;
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'at $t');
    }
  });
}
