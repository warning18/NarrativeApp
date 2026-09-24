// The main menu: New Game+ appears once a story has been finished, and
// starts the next cycle from that finished run even after a new game;
// a save already on an ending counts; loading over a game asks first.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/finished_story_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/save_game_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Pumps until [found] shows or about five seconds of real time pass: the
/// story file loads off the fake test clock and can take a while.
Future<void> _pumpUntilFound(WidgetTester tester, Finder found) async {
  for (var i = 0; i < 30 && found.evaluate().isEmpty; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // An asset load cached by an earlier test belongs to that test's fake
    // clock and would never finish in this one.
    rootBundle.clear();
  });

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

  test('a story finished before 1.134 counts only when none is recorded',
      () async {
    final notifier = FinishedStoryNotifier();
    final older = PlayerSession.fromJson(
        {'raceId': 'orc', 'professionId': 'rogue', 'gold': 90});
    final recorded = PlayerSession.fromJson(
        {'raceId': 'elf', 'professionId': 'mage', 'gold': 400});
    await notifier.backfill(older, '7005');
    expect(notifier.state.count, 1);
    expect(notifier.state.lastRun!.raceId, 'orc');

    SharedPreferences.setMockInitialValues({});
    final another = FinishedStoryNotifier();
    await another.record(recorded, '7005');
    await another.backfill(older, '7005');
    expect(another.state.count, 1);
    expect(another.state.lastRun!.raceId, 'elf', reason: 'never replaced');
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

  group('from saves made before 1.134', () {
    // The saves are on the device before the app starts, as they would be
    // after an update.
    Future<ProviderContainer> openMenu(
      WidgetTester tester,
      Map<String, Object> stored,
    ) async {
      SharedPreferences.setMockInitialValues(stored);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await _settle(tester);
      return ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)));
    }

    String session(String name, {int cycle = 0}) => json.encode({
          'raceId': 'dwarf',
          'professionId': 'warrior',
          'characterName': name,
          'newGamePlusCycle': cycle,
          'enemyKillCounts': <String, dynamic>{},
        });

    String slot(String name, String nodeId, {int cycle = 0}) => json.encode({
          'session': json.decode(session(name, cycle: cycle)),
          'currentNodeId': nodeId,
          'history': ['0', '100'],
          'savedAt': '2026-09-20T18:00:00.000',
        });

    testWidgets('a game already on an ending offers New Game+', (tester) async {
      final container = await openMenu(tester, {
        'player_session': session('Ysolde'),
        'autosave_story_node': '7005',
        'autosave_story_history': json.encode(['0', '100']),
      });
      await _pumpUntilFound(
          tester, find.byKey(const Key('menu_new_game_plus')));
      expect(find.byKey(const Key('menu_new_game_plus')), findsOneWidget);
      expect(container.read(finishedStoryProvider).lastRun!.characterName,
          'Ysolde');
    });

    testWidgets('a save slot on an ending offers New Game+ from that run',
        (tester) async {
      final container = await openMenu(tester, {
        'player_session': session('Maren'),
        'autosave_story_node': '960',
        'saved_game_slot_1': slot('Maren', '960'),
        'saved_game_slot_2': slot('Brann', '7005', cycle: 1),
      });
      await _pumpUntilFound(
          tester, find.byKey(const Key('menu_new_game_plus')));
      expect(find.byKey(const Key('menu_new_game_plus')), findsOneWidget);
      expect(find.text('Cycle 2'), findsOneWidget);
      expect(container.read(finishedStoryProvider).lastRun!.characterName,
          'Brann');
    });

    testWidgets('nothing on an ending: no New Game+', (tester) async {
      await openMenu(tester, {
        'player_session': session('Maren'),
        'autosave_story_node': '960',
        'saved_game_slot_1': slot('Maren', '960'),
      });
      await _settle(tester);
      expect(find.byKey(const Key('menu_continue')), findsOneWidget);
      expect(find.byKey(const Key('menu_new_game_plus')), findsNothing);
    });

    testWidgets('loading over a game in progress asks first', (tester) async {
      final container = await openMenu(tester, {
        'player_session': session('Ysolde'),
        'autosave_story_node': '100',
        'saved_game_slot_1': slot('Brann', '960'),
      });

      Future<void> pickSlot() async {
        await tester.tap(find.byKey(const Key('menu_load')));
        await _settle(tester);
        await tester.tap(find.textContaining('Brann'));
        await _settle(tester);
        expect(find.text('Load this save?'), findsOneWidget);
      }

      // Cancel: nothing changes, the sheet stays open.
      await pickSlot();
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(container.read(playerSessionProvider).characterName, 'Ysolde');
      expect(container.read(storyPlayProvider).currentNodeId, '100');

      // Load: the save replaces the game and play opens.
      await tester.tap(find.textContaining('Brann'));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('load_confirm_button')));
      await _settle(tester);
      expect(container.read(playerSessionProvider).characterName, 'Brann');
      expect(container.read(storyPlayProvider).currentNodeId, '960');
      expect(find.byType(NavigationBar, skipOffstage: false), findsOneWidget);
      // Let the "game loaded" notice run out.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('loading with no game in progress does not ask',
        (tester) async {
      final container = await openMenu(tester, {
        'saved_game_slot_1': slot('Brann', '960'),
      });
      expect(find.byKey(const Key('menu_continue')), findsNothing);
      await tester.tap(find.byKey(const Key('menu_load')));
      await _settle(tester);
      await tester.tap(find.textContaining('Brann'));
      await _settle(tester);
      expect(find.text('Load this save?'), findsNothing);
      expect(container.read(playerSessionProvider).characterName, 'Brann');
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
