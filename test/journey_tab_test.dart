// The Journey tab: the story's ways on as steps on a map. Picking one
// says what it holds; Go walks the party there and takes it, as its
// choice under the story would. The chapter's earlier scenes lie below
// the party, and a double-tap reads the scene full screen.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

void main() {
  testWidgets('a step picked on the map takes the story there', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester, overrides: [storedCityPlans]);

    // In play the Journey tab sits beside the Story tab.
    expect(find.text('Journey'), findsOneWidget);
    final play = container.read(storyPlayProvider.notifier);
    // The party stands on Alster's High Quay (scene 960): a city draws its
    // ways from its stored chart (N11), and the way out to the Wreck of the
    // Lark is a row of the places' list.
    play.jumpTo('250');
    await settleApp(tester);
    play.jumpTo('960');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    expect(container.read(homeTabIndexProvider), journeyTabIndex);
    expect(find.byType(JourneyScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Past the map inking in and the new place's card.
    await tester.pump(const Duration(seconds: 6));
    for (var i = 0; i < 3; i++) {
      Navigator.of(tester.element(find.byType(JourneyScreen)))
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }

    // The way out that carries the party is a row on the map's list; the
    // others, acted out where the party stands, are cards in the scene view
    // (a button under the map opens it).
    final node = container.read(storyDataProvider).value!.nodeFor('960')!;
    await tester.tap(find.byKey(const ValueKey('journey_tab_district')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('places_handle')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    final out = find.byKey(const ValueKey('place_row_out:lark_wreck'));
    expect(out, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_continue')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_continue')));
    await tester.pump(const Duration(milliseconds: 400));

    // Read opens the scene full screen (v1.199: the scene no longer sits
    // over the map); the map button brings the map back.
    await tester.tap(find.byKey(const ValueKey('journey_read')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_reading_exit')), findsOneWidget);
    expect(out, findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_reading_exit')));
    await tester.pump(const Duration(milliseconds: 400));
    // The map is back with its list folded: the handle raises it.
    if (out.evaluate().isEmpty) {
      await tester.tap(find.byKey(const Key('places_handle')));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    expect(out, findsOneWidget);

    // Picking one says what it is; Go takes it.
    await tester.tap(out);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ROAD'), findsOneWidget);
    final taken =
        node.choices.firstWhere((c) => find.text(c.text).evaluate().isNotEmpty);
    await tester.ensureVisible(find.byKey(const ValueKey('journey_go')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    // The party walks there first.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(storyPlayProvider).currentNodeId, '960');
    // The party walks to the way's building first (a tap skips it), then
    // out by the world's road, a long walk across the land (a tap skips it
    // too; the road's own test is journey_transit_test).
    final cityWalk = find.byKey(const ValueKey('journey_city_walk_skip'));
    final skip = find.byKey(const ValueKey('journey_road_skip'));
    expect(cityWalk, findsOneWidget, reason: 'the party walks there first');
    for (var i = 0;
        i < 120 &&
            find.byKey(const ValueKey('journey_continue')).evaluate().isEmpty;
        i++) {
      if (cityWalk.evaluate().isNotEmpty) {
        await tester.tap(cityWalk);
      } else if (skip.evaluate().isNotEmpty) {
        await tester.tap(skip);
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    await settleApp(tester);
    // The scene reached is read full screen first; Continue brings the
    // map back (v1.200.1).
    expect(find.byKey(const ValueKey('journey_continue')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_continue')));
    await tester.pump(const Duration(milliseconds: 400));
    // The road there may hold a detour first, which the map then shows.
    final after = container.read(storyPlayProvider);
    if (after.isInExcursion) {
      expect(after.resumeNodeId, taken.nextId);
      // A written scene plays over its own band (v1.437); today's chain
      // keeps the map, with "Detour" on it.
      expect(
          find.text('Detour').evaluate().length +
              find.byKey(const Key('journey_detour_scene')).evaluate().length,
          1);
      for (final choice in after.activeExcursionNode!.choices) {
        if (choice.isHiddenFor(container.read(playerSessionProvider).flags)) {
          continue;
        }
        // A payment the purse can't make shows locked, its text followed
        // by why (v1.189).
        expect(find.textContaining(choice.text), findsWidgets,
            reason: choice.text);
      }
    } else {
      expect(after.currentNodeId, taken.nextId);
    }
    expect(container.read(homeTabIndexProvider), journeyTabIndex);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
