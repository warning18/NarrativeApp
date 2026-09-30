// Playing v1.176's quicker story: a plain scene is read on the way to the
// next one (no Continue to press), a line an earlier choice earned says
// which choice it was, a road between two places eats a ration and says
// so, and the Journey map picks a lone way on for the player.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/aftermath_provider.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/road_random_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A road where nothing waits: every roll comes up empty.
class _QuietRoad implements Random {
  @override
  double nextDouble() => 0.999;
  @override
  int nextInt(int max) => max - 1;
  @override
  bool nextBool() => false;
}

void main() {
  testWidgets('plain scenes read through, echoes, rations and a lone step',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [roadRandomProvider.overrideWithValue(_QuietRoad.new)],
      child: const MyApp(),
    ));
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
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          // The sixteenth year's memory: the floorboard.
          'flags': ['origin_board_good'],
        })));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);
    PlayerSession session() => container.read(playerSessionProvider);

    // 1. "Confront them": the circle flees (a scene with one plain way on,
    // setting court_fled) and the story opens straight onto the altar,
    // with the flight read above it.
    play.jumpTo('5003');
    await _settle(tester);
    await tester.tap(find.text('Confront them'));
    await _settle(tester);
    expect(container.read(storyPlayProvider).currentNodeId, '5004_altar');
    expect(session().flags, contains('court_fled'));
    final preludes = container.read(pendingPreludeProvider);
    expect(preludes.single.nodeId, '5004');
    expect(find.text('⁂'), findsOneWidget);
    // The altar's line about the flight says what earned it, and is
    // remembered for the journal.
    expect(find.byKey(const ValueKey('echo_5004_altar|court_fled')),
        findsOneWidget);
    expect(find.text('Because you chose “Confront them”'), findsOneWidget);
    // So does the flight's own memory of the floorboard, read on the way.
    expect(find.byKey(const ValueKey('echo_5004|origin_board_good')),
        findsOneWidget);
    expect(preludes.single.body, isNot(contains('I had waited up')));
    await _settle(tester);
    expect(session().seenEchoKeys,
        containsAll(['5004_altar|court_fled', '5004|origin_board_good']));
    expect(tester.takeException(), isNull);

    // 2. The road from 2001 to the wharf eats the last ration, and is a
    // watch of the day.
    play.jumpTo('2001');
    await _settle(tester);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(session().copyWith(provisions: 1, watch: 0)));
    await _settle(tester);
    await tester.tap(find.text('Head toward the wharf'));
    await _settle(tester);
    expect(session().provisions, 0);
    expect(session().watch, 1);
    expect(container.read(pendingRoadNoteProvider),
        contains('That was the last ration'));
    expect(find.textContaining('That was the last ration'), findsWidgets);

    // 3. On the Journey map a scene's lone way on is picked already: one
    // tap on Go.
    play.jumpTo('5006_cornered');
    await _settle(tester);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await _settle(tester);
    expect(find.byType(JourneyScreen), findsOneWidget);
    final go =
        tester.widget<FilledButton>(find.byKey(const ValueKey('journey_go')));
    expect(go.onPressed, isNotNull);
    expect(find.text('Fight your way out'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
