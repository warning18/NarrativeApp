// The Journey on one interface (v1.199): the scene read full screen from
// the Read button, the map looked at from the place, its land or the
// world, the calques over the world, and the story so far in a line under
// the map that opens its page.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/chart_globe.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journal_screen.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

void main() {
  testWidgets('the Journey reads, looks out at the world and keeps the story',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester, overrides: [storedCityPlans]);
    final play = container.read(storyPlayProvider.notifier);
    // Alster's High Quay (scene 960) first: its way out takes the party
    // from the city to another place.
    play.jumpTo('250');
    await settleApp(tester);
    play.jumpTo('960');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);

    // No scene over the map: Read opens it full screen, the map button
    // brings the map back.
    const chart = ValueKey('journey_city_chart');
    await tester.pump(const Duration(seconds: 6));
    expect(find.byKey(const ValueKey('journey_scene_fold')), findsNothing);
    expect(find.byKey(chart), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_read')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_reading_exit')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_reading_exit')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(chart), findsOneWidget);

    // A choice made opens the scene reached full screen, with Continue
    // under it to come back to the map. (The city's way here is a row of
    // its list; the walk camera of the generated plan, v1.219, is gone with
    // it, the chart's camera is city_camera_test's.)
    expect(find.byKey(const ValueKey('journey_continue')), findsNothing);
    final out = find.byKey(const ValueKey('place_row_out:lark_wreck'));
    await tester.tap(find.byKey(const ValueKey('journey_tab_district')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('places_handle')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(out);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.byKey(const ValueKey('journey_go')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    // The party walks to the way's building, then out by the road: a tap
    // skips each.
    final cityWalk = find.byKey(const ValueKey('journey_city_walk_skip'));
    final skip = find.byKey(const ValueKey('journey_road_skip'));
    for (var i = 0;
        i < 120 &&
            find.byKey(const ValueKey('journey_continue')).evaluate().isEmpty;
        i++) {
      if (cityWalk.evaluate().isNotEmpty) {
        await tester.tap(cityWalk);
      } else if (skip.evaluate().isNotEmpty) {
        await tester.tap(skip);
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    await settleApp(tester);
    final after = container.read(storyPlayProvider);
    expect(after.isInExcursion || after.currentNodeId != '960', isTrue);
    expect(find.byKey(const ValueKey('journey_continue')), findsOneWidget);
    expect(find.byKey(chart), findsNothing);
    // Continue brings the map back (a scene that goes on has its own).
    for (var i = 0;
        i < 4 &&
            find
                .byKey(const ValueKey('journey_continue'))
                .evaluate()
                .isNotEmpty;
        i++) {
      await tester.tap(find.byKey(const ValueKey('journey_continue')));
      await tester.pump(const Duration(milliseconds: 600));
    }
    // The map is back with its tabs, or, when the road held a written
    // detour (v1.439), its scene, whose ways are cards.
    expect(
        find.byKey(const Key('journey_level_tabs')).evaluate().length +
            find.byKey(const Key('journey_detour_scene')).evaluate().length,
        1);
    play.jumpTo('2001');
    await settleApp(tester);
    play.jumpTo('2005');
    await settleApp(tester);

    // The story so far opens from the journal button by the stats: where
    // the party stands, now, the threads (v1.201: no strip under the map).
    expect(find.byKey(const ValueKey('journey_sofar')), findsNothing);
    expect(find.byKey(const Key('journey_level_place')), findsNothing);
    await tester.tap(find.byTooltip('The story so far'));
    await settleApp(tester);
    expect(find.byType(JournalScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('sofar_page')), findsOneWidget);
    expect(find.byKey(const ValueKey('sofar_where')), findsOneWidget);
    expect(find.byKey(const ValueKey('sofar_now')), findsOneWidget);
    expect(find.text('The Landward Gate'), findsWidgets);
    await tester.pageBack();
    await settleApp(tester);

    // The − button on a district looks out at the whole town first
    // (v1.350), with its three level tabs; the world comes next.
    expect(find.byKey(const Key('journey_level_tabs')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('journey_town_zoom_in')), findsOneWidget);
    expect(find.byType(JourneyWorldMap), findsNothing);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    // The + under it comes back to the district; the Town tab goes out.
    await tester.tap(find.byKey(const Key('journey_town_zoom_in')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('journey_town_zoom_in')), findsNothing);
    await tester.tap(find.byKey(const Key('journey_tab_town')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('journey_town_zoom_in')), findsOneWidget);

    // The − button on the whole town looks out at the land under the fog
    // (v1.201: the levels are zoomed between); the steps wait behind.
    // (A scene inside a building steps out into its streets first.)
    for (var i = 0;
        i < 2 && find.byType(JourneyWorldMap).evaluate().isEmpty;
        i++) {
      await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(find.byType(JourneyWorldMap), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsNothing);
    expect(find.byKey(const ValueKey('journey_level_hint')), findsOneWidget);
    // No jump (v1.201.1): the sphere opens close, where the streets were,
    // and glides out to the zoom that fills its box, turned to the party.
    final map = find.byType(JourneyWorldMap);
    GlobeView globeNow() => journeyGlobeOf(tester.element(map))!;
    final box = tester.getSize(map);
    final k =
        (box.shortestSide * 0.9 / (2 * GlobeView.baseRadius)).clamp(0.0, 3.6);
    final fill = JourneyWorldMapZoom.fillFor(box, 2 * GlobeView.baseRadius * k);
    expect(fill, greaterThan(1));
    await tester.pump(const Duration(milliseconds: 20));
    final early = globeNow().zoom;
    expect(early, greaterThan(fill + 1));
    await tester.pump(const Duration(milliseconds: 150));
    final later = globeNow().zoom;
    expect(later, lessThan(early));
    await tester.pump(const Duration(milliseconds: 400));
    expect(globeNow().zoom, closeTo(fill, 0.01));
    // The ball covers its box, corners included, and is turned to the
    // party: its place is at the middle of the map.
    final pxRadius = globeNow().radius * k;
    expect(pxRadius * 2,
        greaterThanOrEqualTo(Offset(box.width, box.height).distance - 0.5));
    final story = chartOf(MapShape.story);
    final party = tester.widget<JourneyWorldMap>(map).here!;
    final at = globeNow().clamp(story.of(party));
    expect((at - globeNow().centre).distance, lessThan(1));
    // − shows the whole ball; no pole buttons, no sphere switch.
    await tester.tap(find.byKey(const Key('journey_zoom_out')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(globeNow().zoom, closeTo(1, 0.01));
    expect(find.byKey(const Key('journey_pole_north')), findsNothing);
    expect(find.byKey(const Key('journey_pole_south')), findsNothing);
    await tester.tap(find.byKey(const Key('journey_recentre')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(globeNow().zoom, closeTo(fill, 0.01));
    // Zoomed in as far as the chart goes, on the party's place, the
    // streets come back; − looks out again.
    for (var i = 0;
        i < 8 && find.byKey(const Key('journey_zoom_in')).evaluate().isNotEmpty;
        i++) {
      await tester.tap(find.byKey(const Key('journey_zoom_in')));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(JourneyWorldMap), findsOneWidget);

    // The tabs from the land: the District tab goes straight to the
    // streets, the World tab back out to the whole sphere.
    await tester.tap(find.byKey(const Key('journey_tab_district')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(JourneyWorldMap), findsNothing);
    expect(find.byKey(const Key('journey_town_zoom_in')), findsNothing);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_tab_world')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(JourneyWorldMap), findsOneWidget);

    // The calques: the clans' influence over the lands, with its legend;
    // the choice is kept.
    await tester.tap(find.byKey(const Key('journey_layers')));
    await settleApp(tester);
    expect(find.byKey(const Key('calque_clans')), findsOneWidget);
    await tester.tap(find.byKey(const Key('calque_clans')));
    await settleApp(tester);
    expect(container.read(chartCalqueProvider), ChartCalque.clans);
    // The sheet closed (it can fill the screen, so a tap above it
    // would land on it).
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settleApp(tester);
    expect(find.byKey(const ValueKey('journey_clan_legend')), findsOneWidget);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getString(chartCalquePrefsKey), 'clans');

    // The Layers sheet no longer offers a flat chart.
    await tester.tap(find.byKey(const Key('journey_layers')));
    await settleApp(tester);
    expect(find.byKey(const Key('journey_globe')), findsNothing);
    expect(find.byKey(const Key('journey_weather')), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settleApp(tester);
    // The sphere: turned with a drag, and + comes back to the party
    // wherever the ball was turned.
    final globe = find.byKey(const ValueKey('journey_globe_canvas'));
    expect(globe, findsOneWidget);
    expect(find.byKey(const ValueKey('journey_world_canvas')), findsNothing);
    await tester.drag(globe, const Offset(-120, 40));
    await tester.pump();
    expect((globeNow().clamp(story.of(party)) - globeNow().centre).distance,
        greaterThan(10));
    await tester.tap(find.byKey(const Key('journey_zoom_in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(globeNow().zoom, closeTo(JourneyWorldMapZoom.district, 0.01));
    expect((globeNow().clamp(story.of(party)) - globeNow().centre).distance,
        lessThan(1));
    // A tap on the party's own place is the streets again (v1.201).
    // The ball closes in on it first (the dive), then hands over.
    await tester.tap(globe);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(globeNow().zoom, greaterThan(JourneyWorldMapZoom.max));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 400));
    expect(globe, findsNothing);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(globe, findsOneWidget);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}
