// The arrival sheet holds the scene's own choices too (v1.465): a hub's
// errand (here one of the wharf's) rises as a sheet over the map
// with its words, and the ways of that scene are cards under them; the map
// beneath keeps no card. At phone width and in French.
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
import 'support/pump.dart';

void main() {
  testWidgets(
      "an errand in the hub's own place keeps the scene page, its choices on it",
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(360, 740));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settleApp(tester);
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
    await settleApp(tester);
    final play = container.read(storyPlayProvider.notifier);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);

    // The wharf, a hub: its errands are in the scene view, under a chip for
    // each kind.
    play.jumpTo('2015');
    await settleApp(tester);
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
    await settleApp(tester);
    final here = container.read(storyPlayProvider).currentNodeId;
    expect(here, '2015_dockside');

    // The errand is on the wharf, where the hub is: the same stop, so the
    // scene keeps the party (the scene-or-map rule). It opens in the view
    // the card was taken from, the scene page, not in a sheet over the map,
    // with its own choice as a card under its words.
    final sheet = find.byKey(const Key('journey_arrival_sheet'));
    expect(sheet, findsNothing);
    expect(find.byKey(const ValueKey('journey_scene_text')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_choice_card_0')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // French, and the narrowest phone: the sheet still fits.
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    tester.view.physicalSize = const Size(320, 568);
    await settleApp(tester);
    expect(sheet, findsNothing);
    expect(find.byKey(const ValueKey('journey_choice_card_0')), findsOneWidget);

    // Its one card is the way on (a one-card page, v1.692): no Continue
    // back to the map, and the top bar's map is closed too.
    Navigator.of(tester.element(find.byType(JourneyScreen)))
        .popUntil(isGameRoute);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('journey_continue')), findsNothing);
    expect(container.read(journeyMapClosedProvider), isTrue);
    expect(tester.takeException(), isNull);
  });
}
