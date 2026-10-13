// The full-screen map (v1.279): the Journey's own chart on a page, a tap on
// a place opening its sheet (where the party stands, the offer to travel,
// or why it cannot), opened on a place asked for, and the Journey's chart
// offering the page from its controls.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/map_charts.dart' show ChartPalette;
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/providers/combat_active_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/travel_history_provider.dart';
import 'package:narrative_data_app/screens/full_map_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  // The wreck of the Lark, the Sleeper's Face, the White Wells.
  final travels = travelHistoryOf(
    history: const ['965', '1100', '1120', '1130'],
    currentNodeId: '1200',
  );
  final withTarget = TravelHistory(
    stops: travels.stops,
    legs: travels.legs,
    visited: travels.visited,
    heardOf: travels.heardOf,
    currentId: travels.currentId,
    travelTargets: const {'sleeper': 'no_such_scene'},
  );

  Future<void> open(WidgetTester tester, TravelHistory history,
      {String? focusId, bool fighting = false}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        travelHistoryProvider.overrideWithValue(history),
        storyDataProvider.overrideWith((ref) async => const StoryData({})),
        if (fighting) combatActiveProvider.overrideWith((ref) => true),
      ],
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)),
        home: FullMapScreen(focusId: focusId),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  void tapPlace(WidgetTester tester, String id) {
    tester
        .widget<JourneyWorldMap>(find.byKey(const ValueKey('full_world_map')))
        .onSelect!(landmarkById(id)!);
  }

  testWidgets('the page is the Journey chart at the world level',
      (tester) async {
    await open(tester, withTarget);
    final map = tester
        .widget<JourneyWorldMap>(find.byKey(const ValueKey('full_world_map')));
    expect(map.level, JourneyMapLevel.world);
    // No streets to zoom into from here, and no button for itself.
    expect(map.onZoomIn, isNull);
    expect(map.onFullMap, isNull);
  });

  testWidgets('a place to travel to offers the journey', (tester) async {
    await open(tester, withTarget);
    tapPlace(tester, 'sleeper');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('map_place_sheet')), findsOneWidget);
    final go = tester.widget<FilledButton>(find.byKey(const Key('travel_go')));
    expect(go.onPressed, isNotNull);
  });

  testWidgets('a place that is no way to travel says so', (tester) async {
    await open(tester, withTarget);
    tapPlace(tester, 'crash');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('map_no_road')), findsOneWidget);
    expect(find.byKey(const Key('travel_go')), findsNothing);
  });

  testWidgets('the place the party stands at says so, with nothing to take',
      (tester) async {
    await open(tester, withTarget);
    tapPlace(tester, withTarget.currentId!);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('map_here')), findsOneWidget);
    expect(find.byKey(const Key('travel_go')), findsNothing);
  });

  testWidgets('during a fight the offer stays but cannot be taken',
      (tester) async {
    await open(tester, withTarget, fighting: true);
    tapPlace(tester, 'sleeper');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('map_busy')), findsOneWidget);
    final go = tester.widget<FilledButton>(find.byKey(const Key('travel_go')));
    expect(go.onPressed, isNull);
  });

  testWidgets('opened on a place, its sheet is up at once', (tester) async {
    await open(tester, withTarget, focusId: 'sleeper');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('map_place_sheet')), findsOneWidget);
    expect(find.byKey(const Key('travel_go')), findsOneWidget);
  });

  testWidgets('the toolbar opens the legend, and the journeys turn the chart',
      (tester) async {
    await open(tester, withTarget);
    expect(find.byKey(const Key('map_story')), findsOneWidget);
    await tester.tap(find.byKey(const Key('map_legend')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('map_legend_sheet')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 400));

    // No road walked: the sheet says so.
    await tester.tap(find.byKey(const Key('map_journeys')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('map_journeys_empty')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 400));

    // Three places walked: a tap on a stretch faces the chart to where it ends.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FullMapScreen)));
    final play = container.read(storyPlayProvider.notifier);
    for (final id in const ['965', '1100', '1120']) {
      play.jumpTo(id);
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('map_journeys')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    final rows = find.byWidgetPredicate(
        (w) => w.key.toString().contains('map_journey_') && w is ListTile);
    expect(rows, findsWidgets);
    await tester.tap(rows.first);
    await tester.pump(const Duration(milliseconds: 400));
    final map = tester
        .widget<JourneyWorldMap>(find.byKey(const ValueKey('full_world_map')));
    expect(map.focus, isNotNull);
  });

  testWidgets('the Journey chart offers the full map from its controls',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var opened = 0;
    await tester.pumpWidget(ProviderScope(
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
              onFullMap: () => opened++,
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('journey_full_map')));
    expect(opened, 1);
  });

  testWidgets('closing the map removes the map page, not what is over it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final key = GlobalKey<NavigatorState>();
    late Route<dynamic> mapRoute;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      home: const Scaffold(body: Text('journey')),
    ));
    mapRoute = MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('map')));
    key.currentState!.push(mapRoute);
    await tester.pumpAndSettle();
    // A notice (a route here) lands over the map.
    key.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('walked to X'))));
    await tester.pumpAndSettle();

    closeMapRoute(key.currentState!, mapRoute);
    await tester.pumpAndSettle();
    expect(find.text('walked to X'), findsOneWidget,
        reason: 'the notice stays');
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('map'), findsNothing,
        reason: 'the map is gone: popping the notice lands on the journey');
    expect(find.text('journey'), findsOneWidget);
    // Closing a route that is gone is harmless.
    closeMapRoute(key.currentState!, mapRoute);
  });
}
