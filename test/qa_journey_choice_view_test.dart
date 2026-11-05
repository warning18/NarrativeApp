// QA guard (the user's feedback on v1.809, #789): a choice that leaves the
// party where it stands turned into a card in every scene, so rooms and the
// city chart lost the spots and banners the player chooses from. What the
// player sees, held here against the story's own scenes (v1.808 is the
// reference: these checks all pass on it):
//   * a room scene with several choices draws every choice as a spot of its
//     room plan (scene 100's three, scene 110's two), not cards behind a
//     "choices here" button;
//   * a scene with one plain choice at its stop continues at a tap: Go is
//     ready, no map to choose on, no trip (scene 100_dice; v1.808 kept it as
//     a spot, v1.825's design is Go with the choice a card, both pass);
//   * on the city chart a scene's choices hang as banners/pins (scene
//     1150_vica's three, the wharf hub's ways);
//   * a choice to another stop walks the party there, visibly: the
//     traveller on the map (the way out the back from 106), and the Alster
//     street (250) offers its districts on the chart (the Stone Bridge).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/politics_provider.dart'
    show choiceHiddenFor, coastGateWorldProvider;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';
import 'support/open_game.dart';
import 'support/pump.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

/// The choices of scene [id] the player sees (the flags hide the others).
int _visibleChoices(ProviderContainer c, String id) {
  final node = c.read(storyDataProvider).value!.nodeFor(id)!;
  final session = c.read(playerSessionProvider);
  final gate = c.read(coastGateWorldProvider);
  return node.choices.where((x) => !choiceHiddenFor(x, session, gate)).length;
}

/// The numbers of the Journey spots (journey_step_N) on the map now.
List<int> _spots(WidgetTester tester) => [
      for (var i = 0; i < 12; i++)
        if (_key('journey_step_$i').evaluate().isNotEmpty) i,
    ];

/// Opens the Journey on scene [id] with nothing over the map: the new
/// place's card and the chapter's notice closed.
Future<void> _arrive(
    WidgetTester tester, ProviderContainer container, String id) async {
  container.read(storyPlayProvider.notifier).jumpTo(id);
  await settleApp(tester);
  await tester.pump(const Duration(seconds: 6));
  for (var i = 0; i < 3; i++) {
    Navigator.of(tester.element(find.byType(JourneyScreen)))
        .popUntil(isGameRoute);
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<ProviderContainer> _open(WidgetTester tester,
    {Map<String, dynamic>? session}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
  usePhone(tester, const Size(412, 892));
  final container = await openGame(tester,
      overrides: [storedCityPlans],
      session: session ??
          const {
            'raceId': 'human',
            'professionId': 'warrior',
          });
  container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
  await settleApp(tester);
  // The first scene of a test draws the map before the town's data is read
  // (the ground, not the room); one scene first, as the real game has.
  await _arrive(tester, container, '100');
  return container;
}

Future<void> _roomSpots(
    WidgetTester tester, ProviderContainer container) async {
  for (final (id, count) in [('100', 3), ('110', 2)]) {
    await _arrive(tester, container, id);
    expect(_visibleChoices(container, id), count, reason: 'scene $id');
    expect(_key('journey_room'), findsOneWidget, reason: 'scene $id');
    expect(_spots(tester), [for (var i = 0; i < count; i++) i],
        reason: 'scene $id: every choice is a spot of the room plan');
    expect(_key('journey_open_choices'), findsNothing,
        reason: 'scene $id: no "choices here" list behind a button');
  }
}

Future<void> _singleChoice(
    WidgetTester tester, ProviderContainer container) async {
  await _arrive(tester, container, '100_dice');
  expect(_visibleChoices(container, '100_dice'), 1);
  expect(_key('journey_room'), findsOneWidget);
  expect(_key('journey_go'), findsOneWidget,
      reason: 'the way is picked already: Go is ready, no map to choose on');

  await tester.tap(_key('journey_go'));
  await tester.pump();
  for (var i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  await settleApp(tester);
  expect(container.read(storyPlayProvider).currentNodeId, '100');
  // Staying in the room is no trip: the party is not walked anywhere.
  expect(_key('journey_traveller'), findsNothing);
}

Future<void> _chartBanners(
    WidgetTester tester, ProviderContainer container) async {
  // White Wells' scene with three ways (all at the Wells).
  await _arrive(tester, container, '1150_vica');
  expect(_key('journey_city_chart'), findsOneWidget);
  var chart = tester.widget<CityChartView>(find.byType(CityChartView));
  expect(chart.banners.length + chart.numbers.length,
      _visibleChoices(container, '1150_vica'),
      reason: 'each of its choices has a banner or a pin on the chart');

  // The wharf hub: its ways to other districts are on the chart.
  await _arrive(tester, container, '2015');
  chart = tester.widget<CityChartView>(find.byType(CityChartView));
  final node = container.read(storyDataProvider).value!.nodeFor('2015')!;
  expect(chart.banners.length + chart.numbers.length, greaterThanOrEqualTo(2),
      reason: 'the hub has ways on its chart');
  expect(_visibleChoices(container, '2015'), greaterThan(2));
  expect(node.choices.length, greaterThan(2));
}

Future<void> _walkInView(
    WidgetTester tester, ProviderContainer container) async {
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .applyChoiceEffects(flagsToAdd: ['casino_tables'], goldIsProfit: false));
  // Out the back, into the streets: a spot of the room, then the walk.
  await _arrive(tester, container, '106');
  expect(_key('journey_room'), findsOneWidget);
  final out = _spots(tester).last;
  await tester.tap(_key('journey_step_$out'));
  await tester.pump();
  await tester.tap(_key('journey_go'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(_key('journey_traveller'), findsOneWidget,
      reason: 'the party is seen walking to the streets');
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  await settleApp(tester);
  expect(container.read(storyPlayProvider).currentNodeId, '250');

  // On the Alster street the other districts are on the chart (the scene
  // is read first: Continue, when the way came with a page).
  if (_key('journey_continue').evaluate().isNotEmpty) {
    await tester.tap(_key('journey_continue'));
    await settleApp(tester);
  }
  await tester.pump(const Duration(seconds: 6));
  for (var i = 0; i < 3; i++) {
    Navigator.of(tester.element(find.byType(JourneyScreen)))
        .popUntil(isGameRoute);
    await tester.pump(const Duration(seconds: 1));
  }
  expect(_key('journey_city_chart'), findsOneWidget);
  expect(_key('journey_city_walk_alster_stone_bridge'), findsOneWidget,
      reason: 'the Stone Bridge, the way the story goes on');
}

void main() {
  // One test, one game: a second test in this file opens the Journey before
  // the towns' data is read and draws the ground, not the room.
  testWidgets('the Journey keeps its spots, banners and walks (v1.809)',
      (tester) async {
    final container = await _open(tester);
    final scenarios = {
      'a room scene with several choices draws each as a spot': _roomSpots,
      'one plain choice at its stop continues at a tap': _singleChoice,
      "on the city chart a scene's choices hang as banners": _chartBanners,
      'a way to another stop walks the party there, in view': _walkInView,
    };
    final failed = <String>[];
    for (final entry in scenarios.entries) {
      try {
        await entry.value(tester, container);
      } on TestFailure catch (e) {
        failed.add('${entry.key}: ${e.message}');
      }
    }
    expect(tester.takeException(), isNull);
    expect(failed, isEmpty, reason: failed.join('\n\n'));
  });
}
