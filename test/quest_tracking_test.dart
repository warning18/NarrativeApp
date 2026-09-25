// The followed quest and its goal: which quest shows above the story, what
// it waits on, how it moves on and is turned in, and which quests,
// creatures and people a play-mode list may show.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/quest_tracking.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/tab_badges_provider.dart';

import 'player_session_provider_test.dart' show baseSession, notifierWith;

const _bounty = <String, dynamic>{
  'questName': 'The Ossuary Bounty',
  'objectives': [
    {
      'description': 'Clear three catacomb ghouls',
      'type': 'Kill',
      'targetEnemyID': 'catacomb_ghoul',
      'requiredAmount': 3,
    },
  ],
};

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _closeDialogs(WidgetTester tester) async {
  final button = find.descendant(
      of: find.byType(AlertDialog), matching: find.byType(FilledButton));
  while (button.evaluate().isNotEmpty) {
    await tester.tap(button.first, warnIfMissed: false);
    await _settle(tester);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the followed quest', () {
    test('is the tracked quest while active, else the latest taken on', () {
      expect(followedQuestIdOf(baseSession()), isNull);
      final two = baseSession().copyWith(activeQuestIds: const ['a', 'b']);
      expect(followedQuestIdOf(two), 'b');
      expect(followedQuestIdOf(two.copyWith(trackedQuestId: 'a')), 'a');
      // A tracked quest that is no longer active gives way.
      expect(followedQuestIdOf(two.copyWith(trackedQuestId: 'done')), 'b');
    });

    test('accepting follows it when nothing is followed, not otherwise',
        () async {
      final notifier = await notifierWith(baseSession());
      await notifier.acceptQuest('a');
      expect(notifier.state.trackedQuestId, 'a');
      await notifier.acceptQuest('b');
      expect(notifier.state.trackedQuestId, 'a');
      await notifier.trackQuest('b');
      expect(notifier.state.trackedQuestId, 'b');
      // Only a quest in progress can be followed.
      await notifier.trackQuest('never_taken');
      expect(notifier.state.trackedQuestId, 'b');
      // Turned in, it is no longer followed; the other one stands in.
      await notifier.completeQuest('b');
      expect(notifier.state.trackedQuestId, '');
      expect(followedQuestIdOf(notifier.state), 'a');
    });

    test('a story choice that starts a quest follows it', () async {
      final notifier = await notifierWith(baseSession());
      await notifier.applyChoiceEffects(questIDToProgress: 'q_first_blood');
      expect(notifier.state.trackedQuestId, 'q_first_blood');
    });

    test('survives a save', () {
      final s = baseSession().copyWith(trackedQuestId: 'q_first_blood');
      expect(
          PlayerSession.fromJson(s.toJson()).trackedQuestId, 'q_first_blood');
    });
  });

  group('the goal', () {
    test('is the next objective with its progress, then ready', () {
      var s = baseSession().copyWith(
          activeQuestIds: const ['bounty'],
          enemyKillCounts: const {'catacomb_ghoul': 1});
      var goal = questGoalFor('bounty', _bounty, s);
      expect(goal.ready, isFalse);
      expect(goal.label, 'Clear three catacomb ghouls (1/3)');
      s = s.copyWith(enemyKillCounts: const {'catacomb_ghoul': 3});
      goal = questGoalFor('bounty', _bounty, s);
      expect(goal.ready, isTrue);
    });

    test('a goal reached is announced once, not on a loaded save', () {
      const before = QuestReadiness(active: {'a', 'b'}, ready: {'b'});
      const after =
          QuestReadiness(active: {'a', 'b', 'c'}, ready: {'a', 'b', 'c'});
      // 'a' was in progress and is now ready; 'c' only just appeared.
      expect(QuestReadiness.newlyReady(before, after), ['a']);
      // Nothing is known before the quests table loads.
      expect(
          QuestReadiness.newlyReady(const QuestReadiness(loaded: false), after),
          isEmpty);
    });
  });

  group('discovery', () {
    test('quests: offered, in progress or done', () {
      final s = baseSession().copyWith(
        activeQuestIds: const ['a'],
        completedQuestIds: const ['b'],
        unlockedQuestIds: const ['c'],
      );
      expect(['a', 'b', 'c', 'd'].where((id) => questDiscovered(id, s)),
          ['a', 'b', 'c']);
    });

    test('creatures: beaten once', () {
      final s = baseSession().copyWith(
          enemyKillCounts: const {'harbor_rat': 1},
          unlockedEnemyIds: const ['slum_thug']);
      expect(enemyDiscovered('harbor_rat', s), isTrue);
      expect(enemyDiscovered('slum_thug', s), isTrue);
      expect(enemyDiscovered('void_sovereign', s), isFalse);
    });

    test('people: from their chapter and flag, or once spoken to', () {
      const harker = {'chapter': 2, 'requiredFlag': ''};
      const lysa = {'chapter': 3, 'requiredFlag': 'lysa_survived'};
      final s = baseSession();
      expect(npcDiscovered('old_harker', harker, s, 1), isFalse);
      expect(npcDiscovered('old_harker', harker, s, 2), isTrue);
      expect(npcDiscovered('lysa', lysa, s, 3), isFalse);
      expect(
          npcDiscovered(
              'lysa', lysa, s.copyWith(flags: const ['lysa_survived']), 3),
          isTrue);
      expect(
          npcDiscovered('old_harker', harker,
              s.copyWith(talkedToNpcIds: const ['old_harker']), 1),
          isTrue);
    });

    test('the list order: followed, ready, in progress, offered, done', () {
      final quests = {
        'ready': _bounty,
        'going': _bounty,
        'offered': _bounty,
        'done': _bounty,
        'followed': _bounty,
      };
      final s = baseSession().copyWith(
        activeQuestIds: const ['going', 'ready', 'followed'],
        completedQuestIds: const ['done'],
        unlockedQuestIds: const ['offered'],
        trackedQuestId: 'followed',
        enemyKillCounts: const {'catacomb_ghoul': 0},
      );
      // Make 'ready' ready: only it gets its own objective list here.
      final withReady = {
        ...quests,
        'ready': const <String, dynamic>{'objectives': []},
      };
      expect(questDisplayOrder(withReady.keys, withReady, s),
          ['followed', 'ready', 'going', 'offered', 'done']);
    });
  });

  testWidgets(
      'the story shows the followed goal; turning it in from there pays out',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'characterName': 'Maren',
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 10,
          'activeQuestIds': ['q_ch2_dockside_debts', 'q_ch4_ossuary_bounty'],
          'trackedQuestId': 'q_ch4_ossuary_bounty',
          'enemyKillCounts': {'catacomb_ghoul': 1},
        })));
    container.read(storyPlayProvider.notifier).jumpTo('5001');
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester);
    await _closeDialogs(tester);

    final tracker = find.byKey(const Key('quest_tracker'));
    expect(tracker, findsOneWidget);
    expect(find.text('The Ossuary Bounty'), findsOneWidget);
    expect(find.textContaining('(1/3)'), findsOneWidget);

    // Two more ghouls: the goal is reached and can be turned in here.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(container
            .read(playerSessionProvider)
            .copyWith(enemyKillCounts: const {'catacomb_ghoul': 3})));
    await _settle(tester);
    expect(find.text('Goal reached: turn it in'), findsOneWidget);
    // It is announced once, then the notice goes by itself.
    expect(find.textContaining('Goal reached: The Ossuary Bounty'),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('quest_tracker_turn_in')));
    await _settle(tester);
    final s = container.read(playerSessionProvider);
    expect(s.completedQuestIds, contains('q_ch4_ossuary_bounty'));
    expect(s.gold, 10 + 90);
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    // The other quest in progress now stands in.
    expect(find.text('Dockside Debts'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
