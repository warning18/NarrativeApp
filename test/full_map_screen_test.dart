// The full-screen map (v1.279): the Journey's own chart on a page, a tap on
// a place opening its sheet (where the party stands, the offer to travel,
// or why it cannot), opened on a place asked for, and the Journey's chart
// offering the page from its controls.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/map_charts.dart' show ChartPalette;
import 'package:narrative_data_app/data/heard_of.dart';
import 'package:narrative_data_app/data/map_charts.dart' show MapShape;
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/providers/combat_active_provider.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
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
      {String? focusId,
      bool fighting = false,
      Map<String, HeardOfPlace> heard = const {}}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        travelHistoryProvider.overrideWithValue(history),
        heardOfPlacesProvider.overrideWithValue(heard),
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

  testWidgets(
      'a place heard of with a road offers to set out, by its expedition',
      (tester) async {
    final id = travels.heardOf.first;
    await open(tester, travels, heard: {
      id: HeardOfPlace(
          landmarkId: id,
          action: HeardOfAction.setOut,
          expeditionId: 'z_nowhere',
          expeditionPortId: 'port_x'),
    });
    tapPlace(tester, id);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('map_set_out')), findsOneWidget);
    expect(find.byKey(const Key('map_set_out_expedition')), findsOneWidget);
    expect(find.byKey(const Key('heard_setout_warning')), findsOneWidget);
    expect(find.byKey(const Key('travel_go')), findsNothing);
    final out =
        tester.widget<FilledButton>(find.byKey(const Key('map_set_out')));
    expect(out.onPressed, isNotNull);
  });

  testWidgets('a place heard of with no way yet says why, and can be the goal',
      (tester) async {
    final id = travels.heardOf.first;
    await open(tester, travels, heard: {
      id: HeardOfPlace(
          landmarkId: id,
          action: HeardOfAction.markGoal,
          reason: HeardOfReason.laterChapter,
          chapter: 4),
    });
    tapPlace(tester, id);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('heard_reason_laterChapter')), findsOneWidget);
    expect(find.textContaining('chapter 4'), findsOneWidget);
    expect(find.byKey(const Key('map_set_out')), findsNothing);
    await tester.tap(find.byKey(const Key('map_goal_button')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 400));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FullMapScreen)));
    expect(
        container.read(playerSessionProvider).flags, contains(mapGoalFlag(id)));
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

  testWidgets('the chapters reached are chips, one picks that chapter out',
      (tester) async {
    await open(tester, withTarget);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FullMapScreen)));
    final play = container.read(storyPlayProvider.notifier);
    for (final id in const ['965', '1100', '1120', '2001', '2005']) {
      play.jumpTo(id);
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('world_map_chip_0')), findsOneWidget);
    final chip = find.byKey(const Key('world_map_chip_2'));
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await tester.pump(const Duration(milliseconds: 300));
    final map = tester
        .widget<JourneyWorldMap>(find.byKey(const ValueKey('full_world_map')));
    expect(map.chapterFilter, 2);
    expect(map.focus?.chapter, 2);
    await tester.tap(find.byKey(const Key('world_map_chip_0')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        tester
            .widget<JourneyWorldMap>(
                find.byKey(const ValueKey('full_world_map')))
            .chapterFilter,
        0);
  });

  testWidgets('the layers sheet holds the map look and the shape of its world',
      (tester) async {
    await open(tester, withTarget);
    await tester.tap(find.byKey(const Key('journey_layers')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FullMapScreen)));
    await tester.tap(find.byKey(const Key('world_map_look_parchment')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(mapLookProvider), MapLook.parchment);
    await tester.tap(find.byKey(const Key('world_map_shape_delta')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(mapShapeProvider), MapShape.delta);
  });

  testWidgets('"Replay all" in the journeys sheet walks the road again',
      (tester) async {
    await open(tester, withTarget);
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
    await tester.tap(find.byKey(const Key('map_replay')));
    await tester.pump(const Duration(milliseconds: 400));
    final map = tester
        .widget<JourneyWorldMap>(find.byKey(const ValueKey('full_world_map')));
    expect(map.replayToken, 1);
    expect(map.replayLegs, isNotNull);
    // Let the walk run out.
    await tester.pump(const Duration(seconds: 12));
    expect(tester.takeException(), isNull);
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
