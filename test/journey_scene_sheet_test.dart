// A hub's errand (here one of the wharf's) holds its own choices under its
// words (v1.465). It holds a way acted out there, so since v1.553 (the
// scene lock, scene_lock.dart) it opens as its page, not as a sheet over
// the map: its way is a card, the map waits. At phone width and in French.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/choice_card.dart' show ChoiceCard;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('an errand opens as a sheet that holds its own choices',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
        })));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);
    await tester.tap(find.text('Journey'));
    await _settle(tester);

    // The wharf, a hub: its errands are in the scene view, under a chip for
    // each kind.
    play.jumpTo('2015');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    // What arriving opens over the game (the new place's card) is closed.
    for (var i = 0; i < 3; i++) {
      Navigator.of(tester.element(find.byType(JourneyScreen)))
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byKey(const ValueKey('journey_choice_card_0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('choice_chip_talkDecide')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final first = find.byType(ChoiceCard).first;
    await tester.tap(first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(first);
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _settle(tester);
    final here = container.read(storyPlayProvider).currentNodeId;
    expect(here, '2015_dockside');

    // The errand holds a way acted out there (its fight back to the
    // wharf): since v1.553 (scene_lock.dart) it opens as its page, locked,
    // with that way as a card under its words, not as a sheet over the map.
    final sheet = find.byKey(const Key('journey_arrival_sheet'));
    expect(sheet, findsNothing);
    final page = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>)
            .value
            .startsWith('journey_reading_2015_dockside'));
    expect(page, findsOneWidget);
    expect(find.byKey(const ValueKey('journey_choice_card_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_choose_first')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // French, and the narrowest phone: the page still fits its card.
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    tester.view.physicalSize = const Size(320, 568);
    await _settle(tester);
    expect(page, findsOneWidget);
    expect(find.byKey(const ValueKey('journey_choice_card_0')), findsOneWidget);
    expect(find.text('Choisissez d\'abord'), findsOneWidget);
    // The way back to the map waits until the errand's way is taken.
    final back = find.byKey(const ValueKey('journey_continue'));
    expect(tester.widget<ButtonStyleButton>(back).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
