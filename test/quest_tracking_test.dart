// The followed quest and its goal: which quest shows above the story, what
// it waits on, how it moves on and is turned in, and which quests,
// creatures and people a play-mode list may show.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/quest_tracking.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

import 'player_session_provider_test.dart' show baseSession, notifierWith;
import 'support/pump.dart';

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
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
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

  group('quests the party need not act on (Wave 6)', () {
    const quests = <String, dynamic>{
      'bounty': _bounty,
      'main': {'questName': 'The chapter', 'category': 'Main'},
      'locked_main': {
        'questName': 'Later chapter',
        'category': 'Main',
        'requiredFlags': ['camp_founded'],
      },
      'side': {'questName': 'An errand', 'category': 'Side'},
    };
    test('a main quest offered is taken on, a side quest waits', () {
      final offered = baseSession()
          .copyWith(unlockedQuestIds: const ['main', 'locked_main', 'side']);
      expect(mainQuestsToTake(quests, offered), ['main']);
      expect(
          mainQuestsToTake(
              quests, offered.copyWith(flags: const ['camp_founded'])),
          ['main', 'locked_main']);
      expect(
          mainQuestsToTake(
              quests, offered.copyWith(activeQuestIds: const ['main'])),
          isEmpty);
    });
    test('a quest whose objectives are met completes', () {
      final active =
          baseSession().copyWith(activeQuestIds: const ['bounty', 'side']);
      // A quest with no objectives is done at once; the bounty waits on
      // its ghouls.
      expect(questsReadyToComplete(quests, active), ['side']);
      expect(
          questsReadyToComplete(quests,
              active.copyWith(enemyKillCounts: const {'catacomb_ghoul': 3})),
          ['bounty', 'side']);
    });
  });

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

  // A quest taken sets its `<id>_accepted` flag, which opens a district
  // locked until it is taken: the Spire Stair on the Ashen Oath (v1.639).
  group('the accepted flag', () {
    Map<String, dynamic> table(String name) =>
        jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
            as Map<String, dynamic>;
    final geo =
        Geography.parse(geography: table('geography'), biomes: table('biomes'));
    const oath = 'q_ch3_ashen_oath';
    const stair = 'ashen_quarter_spire_stair';
    bool barred(PlayerSession s) =>
        districtLocked(geo, stair, s.flags, s.completedQuestIds);

    test('taking the Ashen Oath opens the Spire Stair', () async {
      final notifier = await notifierWith(baseSession());
      expect(barred(notifier.state), isTrue);
      await notifier.acceptQuest(oath);
      expect(notifier.state.flags, contains(questAcceptedFlag(oath)));
      expect(barred(notifier.state), isFalse);
    });

    test('a quest taken in a scene is marked taken too', () async {
      final notifier = await notifierWith(baseSession());
      await notifier.applyChoiceEffects(questIDToProgress: oath);
      expect(barred(notifier.state), isFalse);
    });

    test('a save with the oath taken before the flag opens the Stair', () {
      final json = baseSession(activeQuestIds: [oath]).toJson();
      expect(json['flags'] as List, isNot(contains(questAcceptedFlag(oath))));
      expect(barred(PlayerSession.fromJson(json)), isFalse);
      expect(barred(PlayerSession.fromJson(baseSession().toJson())), isTrue);
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
      'the story shows the followed goal; reached, it completes and pays out',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(420, 1400));

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
    container.read(storyPlayProvider.notifier).jumpTo('5003');
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester);
    await _closeDialogs(tester);

    // On the Journey the quest is a small button (v1.213): its sheet
    // names the quest and shows the progress.
    final tracker = find.byKey(const Key('quest_tracker'));
    expect(tracker, findsOneWidget);
    expect(find.byKey(const Key('quest_tracker_ready')), findsNothing);
    await tester.tap(tracker);
    await _settle(tester);
    expect(find.text('The Ossuary Bounty'), findsOneWidget);
    expect(find.textContaining('(1/2)'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);

    // One more ghoul: the goal is reached and the quest completes on its
    // own (Wave 6), with no turn-in to tap.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(container
            .read(playerSessionProvider)
            .copyWith(enemyKillCounts: const {'catacomb_ghoul': 2})));
    await _settle(tester);
    expect(find.text('Turn in'), findsNothing);
    // The bounty asks how it's settled (v1.163): take the sapper's coins.
    expect(find.text('How do you settle it?'), findsOneWidget);
    expect(container.read(playerSessionProvider).completedQuestIds,
        isNot(contains('q_ch4_ossuary_bounty')));
    await tester.tap(find.byKey(const Key('turn_in_choice_0')));
    await _settle(tester);
    final s = container.read(playerSessionProvider);
    expect(s.completedQuestIds, contains('q_ch4_ossuary_bounty'));
    expect(s.gold, 10 + 90);
    expect(find.textContaining('Two coins, as promised'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    // The other quest in progress now stands in.
    expect(followedQuestIdOf(container.read(playerSessionProvider)),
        'q_ch2_dockside_debts');
    await tester.pump(const Duration(seconds: 5));
  });
}
