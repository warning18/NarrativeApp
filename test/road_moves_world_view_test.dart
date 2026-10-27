// A move along a world road is walked on the World view (v1.548): the Dune
// Sea road from the Sleeper's Face by the Dry Wadi to the White Wells is a leg
// between two places, never drawn on a district's plan. The District and Town
// views are for places: arriving at one shows its own view again.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The level tab lit under the map.
String? _lit(WidgetTester tester) {
  for (final t in ['district', 'town', 'world']) {
    final f = find.descendant(
        of: find.byKey(Key('journey_tab_$t')),
        matching: find.byType(Container));
    if (f.evaluate().isEmpty) continue;
    final c = tester.widget<Container>(f.first);
    final d = c.decoration as BoxDecoration?;
    if (d?.color != null) return t;
  }
  return null;
}

void main() {
  test('a leg between two places is a world road leg', () {
    expect(isWorldRoadLeg('sleeper', 'wells'), isTrue);
    expect(isWorldRoadLeg('wells', 'wells'), isFalse, reason: 'one place');
    expect(isWorldRoadLeg('sleeper', null), isFalse);
    expect(isWorldRoadLeg(null, 'wells'), isFalse);
  });

  testWidgets('the Dune Sea road is walked on the World view', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // The world walk at a fifth of its pace.
    final pace = worldMoveTimeScale;
    addTearDown(() => worldMoveTimeScale = pace);
    worldMoveTimeScale = 0.2;
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
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await _settle(tester);
    Future<void> clearCards() async {
      for (var i = 0; i < 3; i++) {
        Navigator.of(tester.element(find.byType(JourneyScreen)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    // At the Sleeper's Face, a place: its own view.
    play.jumpTo('1130');
    await _settle(tester);
    play.jumpTo('1140');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    expect(_lit(tester), 'district');
    expect(find.byType(JourneyWorldMap), findsNothing);

    // "Go the long way round": the road to the White Wells by the Dry Wadi.
    final way = find.byKey(const ValueKey('journey_step_2'));
    expect(way, findsOneWidget);
    await tester.tap(way);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Go the long way round'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    var onWorld = false;
    for (var i = 0; i < 60 && !onWorld; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('journey_flight')), findsNothing,
          reason: 'no road drawn over the district');
      onWorld = find.byType(JourneyWorldMap).evaluate().isNotEmpty;
    }
    expect(onWorld, isTrue, reason: 'the road is walked on the world chart');
    expect(_lit(tester), 'world');
    expect(container.read(storyPlayProvider).currentNodeId, '1140');
    final map =
        tester.widget<JourneyWorldMap>(find.byType(JourneyWorldMap).first);
    expect(map.move, isNotNull);
    expect(map.move!.stops.map((s) => s.name), contains('The Dry Wadi'));

    // A tap on the walk lands the party at once (v1.551): the road's
    // crossing comes at once, not after the walk's seconds.
    final skip = find.byKey(const ValueKey('journey_road_skip'));
    expect(skip, findsOneWidget);
    await tester.tap(skip);
    // The walk skipped, the road's crossing is played (its own screen,
    // crossed here at once), and the party is at the White Wells.
    final crossing = find.byType(LandCrossingScreen);
    for (var i = 0; i < 5 && crossing.evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(crossing, findsOneWidget);
    Navigator.of(tester.element(crossing)).pop(true);
    await _settle(tester);

    // Arrived at the White Wells, a place: its own view again.
    expect(container.read(storyPlayProvider).currentNodeId, '1200');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    final back = find.byKey(const ValueKey('journey_continue'));
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back);
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(_lit(tester), 'district');
    expect(find.byType(JourneyWorldMap), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
