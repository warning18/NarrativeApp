// A room scene with choices to make keeps them as spots on its plan (v1.823,
// as before v1.809): the Blind Beggar's casino (110) is a room plan with a
// mark for each way, and its page has a way back to it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/politics_provider.dart'
    show choiceHiddenFor, coastGateWorldProvider;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/open_game.dart';
import 'support/pump.dart';

void main() {
  /// The game open on the Journey at scene [nodeId].
  Future<ProviderContainer> openAt(WidgetTester tester, String nodeId,
      {bool motion = true}) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(400, 860));
    if (!motion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }
    final container = await openGame(tester);
    container.read(storyPlayProvider.notifier).jumpTo(nodeId);
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    return container;
  }

  Future<void> closeOverlays(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets(
      'a room with choices to make keeps its spots: the casino\'s tables are '
      'marks on the room plan, not cards (reduced motion)', (tester) async {
    final container = await openAt(tester, '110', motion: false);
    await closeOverlays(tester);
    final back = find.byKey(const ValueKey('journey_continue'));
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back);
      await tester.pump(const Duration(milliseconds: 600));
    }
    final story = container.read(storyDataProvider).value!;
    final session = container.read(playerSessionProvider);
    final gate = container.read(coastGateWorldProvider);
    final shown = story
        .nodeFor('110')!
        .choices
        .where((c) => !choiceHiddenFor(c, session, gate))
        .length;
    expect(shown, greaterThan(1));
    final spots = [
      for (var i = 0; i < shown; i++)
        if (find.byKey(ValueKey('journey_step_$i')).evaluate().isNotEmpty) i,
    ];
    expect(spots.length, shown,
        reason:
            'every way of the room is a spot on its plan, as before v1.809');
    expect(find.byKey(const ValueKey('journey_continue')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
