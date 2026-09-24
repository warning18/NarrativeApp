// The main menu: New Game+ appears once a story has been finished, and
// starts the next cycle from that finished run even after a new game.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/finished_story_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/main_menu_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a finished story counts once per run and ending', () async {
    final notifier = FinishedStoryNotifier();
    await Future<void>.delayed(Duration.zero);
    final run = PlayerSession.fromJson(
        {'raceId': 'elf', 'professionId': 'mage', 'gold': 400});
    await notifier.record(run, '7005');
    await notifier.record(run, '7005');
    expect(notifier.state.count, 1);
    expect(notifier.state.any, isTrue);
    // The same run healed on the ending screen: a fresher snapshot, the
    // same story.
    await notifier.record(run.copyWith(gold: 450), '7005');
    expect(notifier.state.count, 1);
    expect(notifier.state.lastRun!.gold, 450);
    // Another ending is another story.
    await notifier.record(run, '7005_dawn');
    expect(notifier.state.count, 2);
  });

  test('a game is in progress once a character exists or the story moved', () {
    final fresh = PlayerSession.fromJson(const {});
    const start =
        StoryPlayState(currentNodeId: '0', history: [], visitedNodeIds: {'0'});
    expect(hasGameInProgress(fresh, start), isFalse);
    expect(
        hasGameInProgress(
            PlayerSession.fromJson({'raceId': 'orc', 'professionId': 'rogue'}),
            start),
        isTrue);
    expect(
        hasGameInProgress(
            fresh,
            const StoryPlayState(
                currentNodeId: '100',
                history: ['0'],
                visitedNodeIds: {'0', '100'})),
        isTrue);
  });

  testWidgets('New Game+ from the menu starts the next cycle of the last run',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    expect(find.byKey(const Key('menu_new_game_plus')), findsNothing);

    await tester
        .runAsync(() => container.read(finishedStoryProvider.notifier).record(
            PlayerSession.fromJson({
              'raceId': 'elf',
              'professionId': 'mage',
              'characterName': 'Ysolde',
              'gold': 400,
              'ownedDiceIds': ['starter_die', 'void_die'],
            }),
            '7005'));
    await _settle(tester);
    expect(find.byKey(const Key('menu_new_game_plus')), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu_new_game_plus')));
    await _settle(tester);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    await _settle(tester);

    final session = container.read(playerSessionProvider);
    expect(session.newGamePlusCycle, 1);
    expect(session.legacyGold, 100);
    expect(session.legacyDiceIds, contains('void_die'));
    expect(container.read(storyPlayProvider).currentNodeId, '0');
  });
}
