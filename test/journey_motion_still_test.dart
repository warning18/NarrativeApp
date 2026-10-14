// With the system's reduced motion, the Journey map is still: no effects,
// every way drawn at once, no stamp. (Its own file: see journey_motion_test.)
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
import 'package:narrative_data_app/widgets/journey_fx.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _fx = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is JourneyFxPainter);

Future<ProviderContainer> _openJourney(WidgetTester tester) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
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
  await tester.runAsync(() =>
      container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
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
    await _settle(tester);
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
