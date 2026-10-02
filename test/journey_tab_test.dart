// The Journey tab: the story's ways on as steps on a map. Picking one
// says what it holds; Go walks the party there and takes it, as its
// choice under the story would. The chapter's earlier scenes lie below
// the party, and a double-tap reads the scene full screen.
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
import 'package:narrative_data_app/screens/journey_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a step picked on the map takes the story there', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
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
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);

    // In play the Journey tab sits beside the Story tab.
    expect(find.text('Journey'), findsOneWidget);
    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('2001');
    await _settle(tester);
    play.jumpTo('2005');
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);
    expect(container.read(homeTabIndexProvider), journeyTabIndex);
    expect(find.byType(JourneyScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Both ways on from the gate are steps on the map.
    final node = container.read(storyDataProvider).value!.nodeFor('2005')!;
    for (final choice in node.choices) {
      expect(find.text(choice.text), findsOneWidget, reason: choice.text);
    }
    expect(find.text('You are here'.toUpperCase()), findsOneWidget);

    // The scene before, on the road below the party, and what happened
    // there a tap away.
    expect(find.byKey(const ValueKey('journey_past_0')), findsOneWidget);
    expect(find.text('Join the queue at the landward gate'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_past_0')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Way taken: Join the queue at the landward gate'),
        findsOneWidget);
    await tester.tapAt(const Offset(200, 40));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Way taken: Join the queue at the landward gate'),
        findsNothing);

    // Read opens the scene full screen (v1.199: the scene no longer sits
    // over the map); the map button brings the map back.
    await tester.tap(find.byKey(const ValueKey('journey_read')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_reading_exit')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_reading_exit')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);

    // Picking one says what it is; Go takes it.
    final taken = node.choices.first;
    await tester.tap(find.byKey(const ValueKey('journey_step_0')));
    await tester.pump();
    expect(find.text('ROAD'), findsOneWidget);
    expect(find.text(taken.text), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    // The party walks there first.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_traveller')), findsOneWidget);
    expect(container.read(storyPlayProvider).currentNodeId, '2005');
    // Through the gate into the town is a walk between two places.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _settle(tester);
    // The scene reached is read full screen first; Continue brings the
    // map back (v1.200.1).
    expect(find.byKey(const ValueKey('journey_continue')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_continue')));
    await tester.pump(const Duration(milliseconds: 400));
    // The road there may hold a detour first, which the map then shows.
    final after = container.read(storyPlayProvider);
    if (after.isInExcursion) {
      expect(after.resumeNodeId, taken.nextId);
      expect(find.text('Detour'), findsOneWidget);
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
