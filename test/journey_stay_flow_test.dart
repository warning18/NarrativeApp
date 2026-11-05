// The scene-or-map rule as the user set it (v1.825, after v1.809): a scene
// with nothing to choose, its one way leading to the next scene at the same
// stop, goes on in the view it was taken from (the page or the sheet), with
// no map; a scene with a choice to make keeps its choices on the map as
// before v1.809 (the city chart's banners, the room plan's spots); a way to
// another district of the town is walked on the city chart. A carried trip
// and a hub's one-tap return keep their own views.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/data/choice_shape.dart';
import 'package:narrative_data_app/providers/geography_provider.dart'
    show geographyProvider;
import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/politics_provider.dart'
    show choiceHiddenFor, coastGateWorldProvider;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart'
    show CityChartView;
import 'package:narrative_data_app/widgets/arrival_sheet.dart';
import 'package:narrative_data_app/widgets/choice_card.dart' show ChoiceCard;
import 'support/open_game.dart';
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
      'a hub on the city chart keeps its banners: only the ways acted out '
      'there are cards (reduced motion)', (tester) async {
    final container = await openAt(tester, '2015', motion: false);
    await closeOverlays(tester);

    final story = container.read(storyDataProvider).value!;
    final world = container.read(geographyProvider);
    final hub = story.nodeFor('2015')!;
    final session = container.read(playerSessionProvider);
    final gate = container.read(coastGateWorldProvider);
    final visible = [
      for (final c in hub.choices)
        if (!choiceHiddenFor(c, session, gate)) c,
    ];
    // A move that pays, checks or fights is a banner too (v1.854): only a
    // way acted out where the party stands, or a decision, is a card.
    bool card(ChoiceShape s) =>
        s.here &&
        (s.action == ChoiceAction.decide ||
            (s.move != ChoiceMove.walk && s.move != ChoiceMove.travel));
    final acted = visible
        .where((c) => card(choiceShape(hub, c, story: story, geography: world)))
        .length;
    final button = find.byKey(const ValueKey('journey_open_choices'));
    expect(button, findsOneWidget);
    final badge = tester.widget<Badge>(
        find.descendant(of: button, matching: find.byType(Badge)));
    expect(int.parse((badge.label! as Text).data!), acted,
        reason: 'the cards are the ways acted out here, nothing else');
    final chart = tester
        .widget<CityChartView>(find.byKey(const ValueKey('journey_city_chart')))
        .chart;
    expect(chart.ways.length, greaterThanOrEqualTo(visible.length - acted),
        reason: 'every way not acted out here is a banner on the city chart');
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
