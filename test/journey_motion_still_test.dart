// With the system's reduced motion, the Journey map is still: no effects,
// every way drawn at once, no stamp. (Its own file: see journey_motion_test.)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
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
  testWidgets('with reduced motion the map is still, and still works',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = await _openJourney(tester);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settleApp(tester);
    expect(_fx, findsNothing);
    // Every way is there at once, fully drawn: nothing waits to ink in.
    final step =
        find.byKey(const ValueKey('journey_step_0'), skipOffstage: false);
    expect(step, findsOneWidget);
    final opacity = tester.widget<Opacity>(
        find.ancestor(of: step, matching: find.byType(Opacity)).first);
    expect(opacity.opacity, 1);
    expect(find.byKey(const ValueKey('journey_stamp')), findsNothing);
    expect(container.read(storyPlayProvider).currentNodeId, '2005');
    expect(tester.takeException(), isNull);
  });
}
