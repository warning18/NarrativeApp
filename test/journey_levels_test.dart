// The Journey on one interface (v1.199): the scene read full screen from
// the Read button, the map looked at from the place, its land or the
// world, the calques over the world, and the story so far in a line under
// the map that opens its page.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // The flat chart first: the sphere is the default now (v1.350), and the
    // test turns it on from the Layers sheet further down.
    SharedPreferences.setMockInitialValues({chartGlobePrefsKey: false});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester, overrides: [noCityPlans]);
    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('2001');
    await settleApp(tester);
    play.jumpTo('2005');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);

    // No scene over the map: Read opens it full screen, the map button
    // brings the map back.
    expect(find.byKey(const ValueKey('journey_scene_fold')), findsNothing);
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_read')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_reading_exit')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_reading_exit')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);

    // A choice made opens the scene reached full screen, with Continue
    // under it to come back to the map.
    expect(find.byKey(const ValueKey('journey_continue')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_step_0')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    // The city's camera (v1.219): the map zooms in on the party as it
    // strolls, and is back to its size when the walk is done.
    expect(find.byKey(const ValueKey('journey_walk_camera')), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final camera = find.byKey(const ValueKey('journey_walk_camera'));
    expect(camera, findsOneWidget);
    expect(tester.widget<Transform>(camera).transform.storage[0],
        greaterThan(1.2));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await settleApp(tester);
    final after = container.read(storyPlayProvider);
    expect(after.isInExcursion || after.currentNodeId != '2005', isTrue);
    expect(find.byKey(const ValueKey('journey_continue')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_continue')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_continue')), findsNothing);
    // The map is back with its steps, or, when the road held a written
    // detour (v1.439), its scene, whose ways are cards.
    expect(
        find.byKey(const ValueKey('journey_step_0')).evaluate().length +
            find.byKey(const Key('journey_detour_scene')).evaluate().length,
        1);
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
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);
    // The + under it comes back to the district; the Town tab goes out.
    await tester.tap(find.byKey(const Key('journey_town_zoom_in')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('journey_town_zoom_in')), findsNothing);
    await tester.tap(find.byKey(const Key('journey_tab_town')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('journey_town_zoom_in')), findsOneWidget);

    // The − button on the whole town looks out at the land under the fog
    // (v1.201: the levels are zoomed between); the steps wait behind.
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byType(JourneyWorldMap), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);
    expect(find.byKey(const ValueKey('journey_level_hint')), findsOneWidget);
    // No jump (v1.201.1): the chart opens close, where the streets were,
    // and glides out to the land's zoom.
    double chartScale() => tester
        .widget<InteractiveViewer>(
            find.byKey(const ValueKey('journey_world_viewer')))
        .transformationController!
        .value
        .getMaxScaleOnAxis();
    // The saved look loads a frame after the chart opens: the glide starts
    // from there.
    await tester.pump(const Duration(milliseconds: 20));
    final early = chartScale();
    expect(early, greaterThan(JourneyWorldMapZoom.land + 1));
    await tester.pump(const Duration(milliseconds: 150));
    final later = chartScale();
    expect(later, lessThan(early));
    await tester.pump(const Duration(milliseconds: 400));
    expect(chartScale(), closeTo(JourneyWorldMapZoom.land, 0.01));
    await tester.tap(find.byKey(const Key('journey_zoom_out')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('journey_recentre')));
    await tester.pump();
    // Zoomed in as far as the chart goes, on the party's place, the
    // streets come back; − looks out again.
    for (var i = 0;
        i < 8 && find.byKey(const Key('journey_zoom_in')).evaluate().isNotEmpty;
        i++) {
      await tester.tap(find.byKey(const Key('journey_zoom_in')));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(JourneyWorldMap), findsOneWidget);

    // The tabs from the land: the District tab goes straight to the
    // streets, the World tab back out to the whole sphere.
    await tester.tap(find.byKey(const Key('journey_tab_district')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(JourneyWorldMap), findsNothing);
    expect(find.byKey(const Key('journey_town_zoom_in')), findsNothing);
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);
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

    // The world as a sphere: turned with a drag, closer with +, a tap
    // picks a place on it; the choice is kept.
    await tester.tap(find.byKey(const Key('journey_layers')));
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('journey_globe')));
    await settleApp(tester);
    // The sheet closed (it can fill the screen, so a tap above it
    // would land on it).
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settleApp(tester);
    expect(container.read(chartGlobeProvider), isTrue);
    expect(prefs.getBool(chartGlobePrefsKey), isTrue);
    final globe = find.byKey(const ValueKey('journey_globe_canvas'));
    expect(globe, findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_zoom_in')));
    await tester.pump();
    // The sphere wears the whole story world: two pole buttons turn it right
    // over either pole.
    expect(find.byKey(const Key('journey_pole_north')), findsOneWidget);
    expect(find.byKey(const Key('journey_pole_south')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_pole_north')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.byKey(const Key('journey_pole_south')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.drag(globe, const Offset(-60, 20));
    await tester.pump();
    await tester.tap(find.byKey(const Key('journey_recentre')));
    await tester.pump();
    // A tap on the party's own place, on the sphere as on the chart, is
    // the streets again (v1.201).
    await tester.tap(globe);
    await tester.pump(const Duration(milliseconds: 400));
    expect(globe, findsNothing);
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(globe, findsOneWidget);
    await tester.runAsync(
        () => container.read(chartGlobeProvider.notifier).choose(false));
    await settleApp(tester);
    expect(globe, findsNothing);
    expect(find.byType(JourneyWorldMap), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_recentre')));
    await tester.pump();
    await tester.tapAt(tester.getRect(find.byType(JourneyWorldMap)).center);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('journey_world_canvas')), findsNothing);
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}
