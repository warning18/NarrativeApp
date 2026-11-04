// The scene-or-map rule, finished (v1.809, docs/proposals/scene-vs-map-flow.md
// and scene-flow-status-and-strip.md): a choice that leads to the next scene
// at the same stop keeps the party in the scene, in the view it was taken
// from (the page or the sheet). A way to another stop is still a mark on the
// map, a carried trip and a hub's one-tap return keep their own views.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/choice_flow_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/politics_provider.dart'
    show choiceHiddenFor, coastGateWorldProvider;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/arrival_sheet.dart';
import 'package:narrative_data_app/widgets/choice_card.dart' show ChoiceCard;
import 'support/pump.dart';

void main() {
  group('the view after a choice', () {
    test('a same-place step keeps the page or the sheet it was taken from', () {
      for (final main in [true, false]) {
        expect(
            arrivalViewOf(const FlowStay(),
                mainStory: main, inExcursion: false, current: ArrivalView.page),
            ArrivalView.page,
            reason: 'main $main');
        expect(
            arrivalViewOf(const FlowStay(),
                mainStory: main,
                inExcursion: false,
                current: ArrivalView.sheet),
            ArrivalView.sheet,
            reason: 'main $main');
      }
    });

    test('taken from the map, a same-place step opens as before', () {
      expect(
          arrivalViewOf(const FlowStay(), mainStory: true, inExcursion: false),
          ArrivalView.page);
      expect(
          arrivalViewOf(const FlowStay(), mainStory: false, inExcursion: false),
          ArrivalView.sheet);
    });

    test('a move, a carried trip and a hub return ignore the view they left',
        () {
      for (final current in [ArrivalView.page, ArrivalView.sheet, null]) {
        // A way to another stop: the main story's page, else the sheet.
        expect(
            arrivalViewOf(const FlowMap('saltmouth_bazaar'),
                mainStory: false, inExcursion: false, current: current),
            ArrivalView.sheet,
            reason: '$current');
        expect(
            arrivalViewOf(const FlowMap('saltmouth_bazaar'),
                mainStory: true, inExcursion: false, current: current),
            ArrivalView.page,
            reason: '$current');
        // Carried (a fight, a roll, a decision with its aftermath elsewhere).
        expect(
            arrivalViewOf(const FlowTripThenArrive('alster_black_hold'),
                mainStory: false, inExcursion: false, current: current),
            ArrivalView.sheet,
            reason: '$current');
        // The one-tap return to a hub: no view, the hub's map and notice.
        expect(
            arrivalViewOf(const FlowReturnToHub('saltmouth_wharf', '2015'),
                mainStory: false, inExcursion: false, current: current),
            ArrivalView.none,
            reason: '$current');
      }
    });
  });

  testWidgets(
      'a run of scenes on the wharf stays on the scene page; its ways to '
      'other districts stay marks on the map (reduced motion)', (tester) async {
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

    play.jumpTo('2015');
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 3));
    for (var i = 0; i < 3; i++) {
      Navigator.of(tester.element(find.byType(JourneyScreen)))
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }

    // The hub's ways to other districts are marks on the map; its errands
    // on the wharf itself are behind the "choices here" button.
    final stops = container.read(storyStopsProvider)!;
    final story = container.read(storyDataProvider).value!;
    final hub = story.nodeFor('2015')!;
    final moves = hub.choices.where((c) => stops.flowOf(hub, c) is FlowMap);
    expect(moves, isNotEmpty);
    final button = find.byKey(const ValueKey('journey_open_choices'));
    expect(button, findsOneWidget);
    final badge = tester.widget<Badge>(
        find.descendant(of: button, matching: find.byType(Badge)));
    final here = int.parse((badge.label! as Text).data!);
    final session = container.read(playerSessionProvider);
    final gate = container.read(coastGateWorldProvider);
    final visible = [
      for (final c in hub.choices)
        if (!choiceHiddenFor(c, session, gate)) c,
    ];
    expect(here, greaterThan(0));
    expect(here, lessThan(visible.length),
        reason: 'the ways to other districts are not cards: marks on the map');
    expect(here, visible.where((c) => stops.flowOf(hub, c) is! FlowMap).length,
        reason: 'every way that stays (or is acted out here) is a card');

    // Open the scene, take an errand on the wharf: the page stays.
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 500));
    await takeCard(tester, 'Buy a quiet route');
    expect(container.read(storyPlayProvider).currentNodeId, '2015_route_sold');
    expect(find.byKey(const ValueKey('journey_scene_text')), findsOneWidget);
    expect(find.byKey(const Key('journey_arrival_sheet')), findsNothing);
    expect(find.byKey(const Key('journey_level_tabs')), findsNothing,
        reason: 'no map between two scenes in one place');

    // Back to the hub, still on the wharf: the page again, no map between.
    await takeCard(tester, 'Say nothing');
    expect(container.read(storyPlayProvider).currentNodeId, '2015');
    expect(find.byKey(const ValueKey('journey_scene_text')), findsOneWidget);
    expect(find.byKey(const Key('journey_arrival_sheet')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

/// Takes the card whose text starts with [text]: it is on the page, or in
/// the list one of a hub's chips opens (each list is tried in turn). A tap
/// picks the card, a second takes it.
Future<void> takeCard(WidgetTester tester, String text) async {
  Finder card() => find.ancestor(
      of: find.textContaining(text, findRichText: true),
      matching: find.byType(ChoiceCard));
  if (card().evaluate().isEmpty) {
    final chips = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('choice_chip_'));
    for (final chip in chips.evaluate().map((e) => e.widget.key!).toList()) {
      await tester.tap(find.byKey(chip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      try {
        await tester.scrollUntilVisible(card(), 120,
            scrollable: find.byType(Scrollable).last, maxScrolls: 40);
        break;
      } on StateError {
        await tester.tap(find.byKey(const ValueKey('choice_sheet_close')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      }
    }
  }
  expect(card(), findsOneWidget, reason: text);
  await tester.tap(card());
  await tester.pump(const Duration(milliseconds: 300));
  final go = find.byKey(const ValueKey('journey_go'));
  await tester.tap(go.evaluate().isNotEmpty ? go : card());
  await tester.pump();
  await settleApp(tester);
  for (var i = 0; i < 3; i++) {
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .popUntil(isGameRoute);
    await tester.pump(const Duration(seconds: 1));
  }
}
