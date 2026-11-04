// A scene's one way is picked by the game (Go ready), but a tap on its mark
// only confirms the pick; it never sets the party on the road (v1.825).
// Before, the first tap on the map after "Back to the map" took the step at
// once, and a way to another place rolled its road and its detour: the
// wreck's "Walk on" (1101_scarred) to the Sleeper's Face.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/open_game.dart';
import 'support/pump.dart';

void main() {
  testWidgets(
      'a tap on the mark of a way the game picked does not take it; Go does',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(400, 860));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = await openGame(tester);
    container.read(storyPlayProvider.notifier).jumpTo('1101_scarred');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    for (var i = 0; i < 3; i++) {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }
    // "Back to the map" at the end of the page: the map, nothing taken.
    final back = find.byKey(const ValueKey('journey_continue'));
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back);
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(container.read(storyPlayProvider).currentNodeId, '1101_scarred');
    // Its one way is picked already, Go ready.
    final mark = find.byKey(const ValueKey('journey_step_0'));
    expect(mark, findsOneWidget);
    expect(find.byKey(const ValueKey('journey_go')), findsOneWidget);
    // A tap on the map's mark: still here, no road, no detour.
    for (var i = 0; i < 2; i++) {
      await tester.tap(mark, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      await settleApp(tester);
      expect(container.read(storyPlayProvider).currentNodeId, '1101_scarred',
          reason: 'tap ${i + 1} on the mark');
      expect(container.read(storyPlayProvider).isInExcursion, isFalse);
    }
    expect(tester.takeException(), isNull);
  });
}
