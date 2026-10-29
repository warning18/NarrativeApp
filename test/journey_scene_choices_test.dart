// The scene view holds the scene's own choices (v1.465): after "Fight the
// fire with the crew" the party arrives at the wreck, a main-story scene read
// full screen, and "Lash yourself to the mast" and the other ways of holding
// on are cards under its words, not cards under the map. The map keeps only
// the ways that carry the party.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the wreck arrival: its choices are in the scene view',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // No walks to wait for.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 50,
        })));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);
    await tester.tap(find.text('Journey'));
    await _settle(tester);

    // The high quay: the choices are in the scene view, the map has no card.
    play.jumpTo('960');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey('journey_choice_card_0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 500));
    final fire = find.byKey(const ValueKey('journey_choice_card_0'));
    expect(
        find.descendant(
            of: fire, matching: find.textContaining('Fight the fire')),
        findsOneWidget);

    // Taking it (a second tap) brings the party to the wreck.
    await tester.tap(fire);
    await tester.pump();
    await tester.tap(fire);
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _settle(tester);
    expect(container.read(storyPlayProvider).currentNodeId, '965');

    // The wreck is read full screen, with its own choices under its words.
    // A card led there and its ways are acted out there: it holds the party
    // on its page, the way back to the map greyed, the cards are the way on
    // (v1.553, scene_lock.dart).
    expect(find.byKey(const ValueKey('journey_choose_first')), findsOneWidget);
    expect(
        tester
            .widget<ButtonStyleButton>(
                find.byKey(const ValueKey('journey_continue')))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<IconButton>(
                find.byKey(const ValueKey('journey_reading_exit')))
            .onPressed,
        isNull);
    final mast = find.byKey(const ValueKey('journey_choice_card_0'));
    expect(
        find.descendant(
            of: mast, matching: find.textContaining('Lash yourself')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('journey_choice_card_1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
