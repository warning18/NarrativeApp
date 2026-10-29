// The map on a phone (v1.350): the sphere is where zooming out lands, its
// ball fills the box, the + and − buttons climb a ladder (world, land,
// district, closest), and the names are set large with a halo, the crowded
// ones left for a closer look.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/travel_history_provider.dart';
import 'package:narrative_data_app/screens/full_map_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
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

  test('the zoom ladder climbs world, land, district, closest', () {
    const z = JourneyWorldMapZoom.stops;
    expect(z, [1, JourneyWorldMapZoom.land, JourneyWorldMapZoom.district, 8]);
    expect(JourneyWorldMapZoom.stepIn(1), JourneyWorldMapZoom.land);
    expect(JourneyWorldMapZoom.stepIn(JourneyWorldMapZoom.land),
        JourneyWorldMapZoom.district);
    expect(JourneyWorldMapZoom.stepIn(JourneyWorldMapZoom.district),
        JourneyWorldMapZoom.max);
    expect(JourneyWorldMapZoom.stepIn(JourneyWorldMapZoom.max),
        JourneyWorldMapZoom.max);
    expect(JourneyWorldMapZoom.stepOut(JourneyWorldMapZoom.max),
        JourneyWorldMapZoom.district);
    expect(JourneyWorldMapZoom.stepOut(JourneyWorldMapZoom.land), 1);
    expect(JourneyWorldMapZoom.stepOut(1), 1);
    // Between rungs: the next one up or down, never the same.
    expect(JourneyWorldMapZoom.stepIn(1.5), JourneyWorldMapZoom.land);
    expect(JourneyWorldMapZoom.stepOut(4), JourneyWorldMapZoom.land);
  });

  testWidgets('the map opens on the sphere, and − comes back to the whole',
      (tester) async {
    final container = await open(tester);
    expect(container.read(chartGlobeProvider), isTrue);
    final globe = find.byKey(const ValueKey('journey_globe_canvas'));
    expect(globe, findsOneWidget);
    expect(find.byKey(const ValueKey('journey_world_canvas')), findsNothing);
    // The ball fills the box's short side (it was a 250 px ball).
    final box = tester.getSize(globe);
    expect(box.width, 360);
    await tester.tap(find.byKey(const Key('journey_zoom_in')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('journey_zoom_out')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the flat chart is still a choice, and is kept', (tester) async {
    final container = await open(tester, prefs: {chartGlobePrefsKey: false});
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(chartGlobeProvider), isFalse);
    expect(find.byKey(const ValueKey('journey_world_canvas')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_globe_canvas')), findsNothing);
  });

  testWidgets('a sphere paints on a tiny canvas without a name too wide',
      (tester) async {
    await open(tester);
    tester.view.physicalSize = const Size(140, 300);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
