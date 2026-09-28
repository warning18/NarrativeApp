// The Journey tab: the story's ways on as steps on a map. Picking one
// says what it holds; Go takes it, as its choice under the story would.
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
    play.jumpTo('2005');
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);
    expect(container.read(homeTabIndexProvider), journeyTabIndex);
    expect(find.byType(JourneyScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Both ways on from the ship are steps on the map.
    final node = container.read(storyDataProvider).value!.nodeFor('2005')!;
    for (final choice in node.choices) {
      expect(find.text(choice.text), findsOneWidget, reason: choice.text);
    }
    expect(find.text('You are here'.toUpperCase()), findsOneWidget);

    // Picking one says what it is; Go takes it.
    final taken = node.choices.first;
    await tester.tap(find.byKey(const ValueKey('journey_step_0')));
    await tester.pump();
    expect(find.text('ROAD'), findsOneWidget);
    expect(find.text(taken.text), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    await _settle(tester);
    // The road there may hold a detour first, which the map then shows.
    final after = container.read(storyPlayProvider);
    if (after.isInExcursion) {
      expect(after.resumeNodeId, taken.nextId);
      expect(find.text('Detour'), findsOneWidget);
      for (final choice in after.activeExcursionNode!.choices) {
        if (choice.isHiddenFor(container.read(playerSessionProvider).flags)) {
          continue;
        }
        expect(find.text(choice.text), findsWidgets, reason: choice.text);
      }
    } else {
      expect(after.currentNodeId, taken.nextId);
    }
    expect(container.read(homeTabIndexProvider), journeyTabIndex);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
