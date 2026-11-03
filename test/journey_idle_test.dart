// The Journey map at rest (v1.209): once nothing on it moves, its clock
// stops and the map holds its frame; the next moment (coming back to the
// tab) starts it again. Its own file, as journey_motion_still_test is:
// two Journeys opened in one process do not start alike.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart'
    show debugJourneyMapsTicking;
import 'package:narrative_data_app/widgets/journey_fx.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

final _fx = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is JourneyFxPainter);

Future<ProviderContainer> _openJourney(WidgetTester tester) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
  usePhone(tester, const Size(400, 860));
  final container = await openGame(tester, overrides: [noCityPlans]);
  final play = container.read(storyPlayProvider.notifier);
  play.jumpTo('2001');
  await settleApp(tester);
  play.jumpTo('2005');
  await settleApp(tester);
  return container;
}

void main() {
  testWidgets('the map holds its frame once nothing on it moves (v1.209)',
      (tester) async {
    final container = await _openJourney(tester);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settleApp(tester);
    // Opened: the unroll, the ways inking in, the stamp. It moves.
    expect(_fx, findsOneWidget);
    expect(debugJourneyMapsTicking.value, greaterThan(0));
    // Past every moment (the stamp fades by 4.2 s, the settling window
    // after the last event is 3.8 s): the clock stops, the layer stays.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(debugJourneyMapsTicking.value, 0);
    expect(_fx, findsOneWidget);
    // Nothing wakes it on its own.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(debugJourneyMapsTicking.value, 0);
    // Coming back to the tab is a moment (the map unrolls): the clock
    // runs again, then rests.
    container.read(homeTabIndexProvider.notifier).state = 1;
    await settleApp(tester);
    expect(debugJourneyMapsTicking.value, 0);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await tester.pump(const Duration(milliseconds: 100));
    expect(debugJourneyMapsTicking.value, greaterThan(0));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(debugJourneyMapsTicking.value, 0);
    expect(tester.takeException(), isNull);
  });
}
