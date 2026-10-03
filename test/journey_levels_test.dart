// The Journey on one interface (v1.199): the scene read full screen from
// the Read button, the map looked at from the place, its land or the
// world, the calques over the world, and the story so far in a line under
// the map that opens its page.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journal_screen.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the Journey reads, looks out at the world and keeps the story',
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
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _settle(tester);
    final after = container.read(storyPlayProvider);
    expect(after.isInExcursion || after.currentNodeId != '2005', isTrue);
    expect(find.byKey(const ValueKey('journey_continue')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_continue')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_continue')), findsNothing);
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);
    play.jumpTo('2005');
    await _settle(tester);

    // The story so far opens from the journal button by the stats: where
    // the party stands, now, the threads (v1.201: no strip under the map).
    expect(find.byKey(const ValueKey('journey_sofar')), findsNothing);
    expect(find.byKey(const Key('journey_level_place')), findsNothing);
    await tester.tap(find.byTooltip('The story so far'));
    await _settle(tester);
    expect(find.byType(JournalScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('sofar_page')), findsOneWidget);
    expect(find.byKey(const ValueKey('sofar_where')), findsOneWidget);
    expect(find.byKey(const ValueKey('sofar_now')), findsOneWidget);
    expect(find.text('The Landward Gate'), findsWidgets);
    await tester.pageBack();
    await _settle(tester);

    // The − button on the streets looks out at the land under the fog
    // (v1.201: the levels are zoomed between); the steps wait behind.
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(JourneyWorldMap), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);
    expect(find.byKey(const ValueKey('journey_level_hint')), findsOneWidget);
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
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(JourneyWorldMap), findsOneWidget);

    // The calques: the clans' influence over the lands, with its legend;
    // the choice is kept.
    await tester.tap(find.byKey(const Key('journey_layers')));
    await _settle(tester);
    expect(find.byKey(const Key('calque_clans')), findsOneWidget);
    await tester.tap(find.byKey(const Key('calque_clans')));
    await _settle(tester);
    expect(container.read(chartCalqueProvider), ChartCalque.clans);
    await tester.tapAt(const Offset(200, 40));
    await _settle(tester);
    expect(find.byKey(const ValueKey('journey_clan_legend')), findsOneWidget);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getString(chartCalquePrefsKey), 'clans');

    // The world as a sphere: turned with a drag, closer with +, a tap
    // picks a place on it; the choice is kept.
    await tester.tap(find.byKey(const Key('journey_layers')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('journey_globe')));
    await _settle(tester);
    await tester.tapAt(const Offset(200, 40));
    await _settle(tester);
    expect(container.read(chartGlobeProvider), isTrue);
    expect(prefs.getBool(chartGlobePrefsKey), isTrue);
    final globe = find.byKey(const ValueKey('journey_globe_canvas'));
    expect(globe, findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_zoom_in')));
    await tester.pump();
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
    await _settle(tester);
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
