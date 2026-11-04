// A step taken inside one place (v1.810, the look of the scene-or-map rule):
// the scene it opens carries a small gold line with the choice just taken and
// a line under it saying the party is still here; a move says neither. At 320
// px, in French.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/aftermath_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'journey_stay_flow_test.dart' show takeCard;
import 'support/pump.dart';

void main() {
  test('only a step that stayed in the place says what was taken', () {
    const choice = StoryChoice(text: 'Buy a quiet route', nextId: 'x');
    TakenStep? after(ChoiceFlow flow,
            {bool excursion = false, bool changed = true}) =>
        takenStepAfter(
            choice: choice,
            flow: flow,
            inExcursion: excursion,
            sceneChanged: changed,
            placeId: 'saltmouth_wharf');
    expect(after(const FlowStay())?.placeId, 'saltmouth_wharf');
    expect(after(const FlowStay())?.choice, same(choice));
    // A way to another stop, a carried trip and a hub's return: nothing.
    expect(after(const FlowMap('saltmouth_bazaar')), isNull);
    expect(after(const FlowTripThenArrive('alster_black_hold')), isNull);
    expect(after(const FlowReturnToHub('saltmouth_wharf', '2015')), isNull);
    // On a detour, or a step that left the scene as it was (a shop, a fight
    // fled): nothing.
    expect(after(const FlowStay(), excursion: true), isNull);
    expect(after(const FlowStay(), changed: false), isNull);
    // The step that opens the making of the character (a new game's first
    // page) is no step taken inside a place.
    expect(
        takenStepAfter(
            choice: const StoryChoice(
                text: 'Choose who you are\u2026',
                nextId: 'x',
                opensCharacterCreation: true),
            flow: const FlowStay(),
            inExcursion: false,
            sceneChanged: true,
            placeId: 'alster_lower_town'),
        isNull);
  });

  testWidgets('a same-place card says what was taken and that nothing moved',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(360, 740));
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settleApp(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior', 'gold': 400})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    // The narrowest phone from here on.
    tester.view.physicalSize = const Size(320, 568);
    await settleApp(tester);
    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('2015');
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 3));
    Future<void> clearCards() async {
      for (var i = 0; i < 3; i++) {
        Navigator.of(tester.element(find.byType(JourneyScreen)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    await clearCards();
    final taken = find.byKey(const ValueKey('journey_taken_line'));
    final still = find.byKey(const ValueKey('journey_still_line'));
    // Nothing was taken yet: the hub's page has neither line.
    expect(taken, findsNothing);
    expect(still, findsNothing);

    // An errand on the wharf: the page stays, with what was taken and where
    // the party still is.
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 500));
    await takeCard(tester, 'Buy a quiet route');
    expect(container.read(storyPlayProvider).currentNodeId, '2015_route_sold');
    expect(taken, findsOneWidget);
    expect(tester.widget<Text>(taken).data, startsWith('› Buy a quiet'));
    expect(still, findsOneWidget);
    expect(tester.widget<Text>(still).data, startsWith('Still at '));
    // The stage and the cards have finished their fade.
    final cards = find.byKey(const ValueKey('journey_choice_cards'));
    final fade =
        find.ancestor(of: cards, matching: find.byType(FadeTransition));
    for (final f in fade.evaluate()) {
      expect((f.widget as FadeTransition).opacity.value, 1.0);
    }

    // Back to the hub, still on the wharf: the lines name what was taken now.
    await takeCard(tester, 'Say nothing');
    expect(container.read(storyPlayProvider).currentNodeId, '2015');
    expect(tester.widget<Text>(taken).data, startsWith('› Say nothing'));

    // French, on the narrowest phone: the line reads "Toujours ici : <place>".
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await settleApp(tester);
    expect(tester.widget<Text>(still).data, startsWith('Toujours ici\u00a0: '));
    expect(tester.takeException(), isNull);
  });
}
