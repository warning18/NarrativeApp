// QA guard (the user's hand test, "whenever I click on the map it triggers a
// detour"; Core's diagnosis): the Lark's wreck, scene 1101_scarred, has one
// way, "Walk on" to the Sleeper's Face. The game picks it (Go is ready). The
// user opens the page, presses "Back to the map" (journey_reading_exit; it
// only closes the page) and taps the way's mark once. That tap is not a
// confirming second tap: the party stays put, the rations, the clock and the
// road's dice untouched; only Go (a second tap, or a card of the page) takes
// the step. On v1.825 the tap took it at once: a ration, a part of the day, a
// road roll and, on the way, a detour.
//
// The page, the one tap and Go are walked through; what is held after each:
// the scene, the history, the excursion flag, the detours' pacing, the day
// and the watch, and the provisions are as before, and no walk is on screen
// (the traveller, the world camera, the crossing's skip button). Go then does
// set the party walking. Its own file: the walk Go starts leaves the game
// crossing, so nothing else can run after it (see also
// qa_journey_map_click_detour_test for taps inside a place).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'support/open_game.dart';
import 'support/pump.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

/// Whether the party is on the walk: the traveller on the map, the camera
/// over the land, or the crossing's skip button.
bool _walking() =>
    _key('journey_traveller').evaluate().isNotEmpty ||
    _key('journey_walk_camera').evaluate().isNotEmpty ||
    _key('journey_road_skip').evaluate().isNotEmpty;

void main() {
  testWidgets('"Back to the map" and one tap on the picked way take no step',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(412, 892));
    final container = await openGame(tester, overrides: [storedCityPlans]);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settleApp(tester);

    /// What the road would touch: the scene, the history, the pacing, the
    /// clock and the pack.
    String snap() {
      final s = container.read(playerSessionProvider);
      final p = container.read(storyPlayProvider);
      return 'node ${p.currentNodeId}, history ${p.history.length}, '
          'excursion ${p.isInExcursion}, pacing ${s.detourPacing.toJson()}, '
          'day ${s.day} watch ${s.watch}, provisions ${s.provisions}';
    }

    // The scene, after another one (the Journey draws its first scene of a
    // test before the towns' data is read).
    final play = container.read(storyPlayProvider.notifier);
    for (final id in ['100', '1101_scarred']) {
      play.jumpTo(id);
      await settleApp(tester);
      await tester.pump(const Duration(seconds: 6));
      for (var i = 0; i < 3; i++) {
        Navigator.of(tester.element(find.byType(JourneyScreen)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
    }
    final before = snap();
    expect(before, startsWith('node 1101_scarred'));
    expect(_key('journey_go'), findsOneWidget,
        reason: 'the way is picked by the game: Go is ready');
    expect(_key('journey_step_0'), findsOneWidget);

    // The page, then "Back to the map".
    await tester.tap(_key('journey_read'));
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(_key('journey_reading_exit'), findsOneWidget);
    await tester.tap(_key('journey_reading_exit'));
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(snap(), before, reason: '"Back to the map" only closes the page');
    expect(_walking(), isFalse);

    // One tap on the way's mark: the way the game picked is confirmed by Go.
    await tester.tap(_key('journey_step_0'));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(_walking(), isFalse,
        reason: 'one tap on the picked way took the step: the party set out');
    expect(snap(), before,
        reason: 'one tap on the picked way changed the road');

    // Go takes it: the party sets out.
    expect(_key('journey_go'), findsOneWidget);
    await tester.tap(_key('journey_go'));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    final now = container.read(storyPlayProvider);
    expect(
        _walking() || now.currentNodeId != '1101_scarred' || now.isInExcursion,
        isTrue,
        reason: 'Go takes the step');
  });
}
