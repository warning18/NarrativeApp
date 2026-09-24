// The in-game tabs mark what waits on them: points to spend on
// Character, a house the purse covers on Camp (once the camp is open), a
// quest ready to turn in on Other.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/tab_badges_provider.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

PlayerSession _session([Map<String, dynamic> fields = const {}]) =>
    PlayerSession.fromJson({
      'raceId': 'human',
      'professionId': 'warrior',
      'enemyKillCounts': <String, dynamic>{},
      ...fields,
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('points to spend: stat or skill points', () {
    expect(hasPointsToSpend(_session()), isFalse);
    expect(hasPointsToSpend(_session({'statPoints': 1})), isTrue);
    expect(hasPointsToSpend(_session({'skillPoints': 2})), isTrue);
  });

  test('a house counts when it is unbuilt, unlocked and affordable', () {
    const houses = <String, dynamic>{
      'hall': {'buildCost': 150},
      'forge': {
        'buildCost': 350,
        'requiredFlags': ['yards_cleared'],
      },
      'shrine': {'buildCost': 4000},
    };
    expect(affordableHouseIds(_session({'gold': 100}), houses), isEmpty);
    expect(affordableHouseIds(_session({'gold': 400}), houses), ['hall']);
    expect(
        affordableHouseIds(
            _session({
              'gold': 400,
              'flags': ['yards_cleared'],
            }),
            houses),
        ['hall', 'forge']);
    expect(
        affordableHouseIds(
            _session({
              'gold': 400,
              'flags': ['yards_cleared'],
              'builtHouseIds': ['hall'],
            }),
            houses),
        ['forge']);
  });

  test('a quest is ready once every objective is met', () {
    const quests = <String, dynamic>{
      'q_kill': {
        'objectives': [
          {'type': 'Kill', 'targetEnemyID': 'slum_thug', 'requiredAmount': 1},
        ],
      },
      'q_flag': {
        'objectives': [
          {'type': 'Flag', 'targetFlag': 'took_bundle'},
        ],
      },
    };
    final session = _session({
      'activeQuestIds': ['q_kill', 'q_flag'],
      'enemyKillCounts': {'slum_thug': 1},
    });
    expect(questsReadyToTurnIn(session, quests), ['q_kill']);
    // Not taken, not counted.
    expect(
        questsReadyToTurnIn(
            _session({
              'enemyKillCounts': {'slum_thug': 1},
            }),
            quests),
        isEmpty);
  });

  testWidgets('the tab bar shows the dots and the Quests section the count',
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
    await tester.runAsync(() =>
        container.read(playerSessionProvider.notifier).loadSession(_session({
              'characterName': 'Maren',
              'gold': 400,
              'statPoints': 2,
              'activeQuestIds': ['q_first_blood'],
              'enemyKillCounts': {'slum_thug': 1},
            })));
    container.read(storyPlayProvider.notifier).jumpTo('960');
    await _settle(tester);

    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester);
    expect(find.byTooltip('Character · points to spend'), findsOneWidget);
    expect(find.byTooltip('Other · a quest to turn in'), findsOneWidget);
    // The camp isn't open before chapter 3, however full the purse.
    expect(find.byTooltip('Camp'), findsOneWidget);

    await tester.tap(find.byTooltip('Other · a quest to turn in'));
    await _settle(tester);
    expect(find.text('1 to turn in'), findsOneWidget);

    // In chapter 3 the camp is open and 400 gold builds its first house.
    container.read(storyPlayProvider.notifier).jumpTo('3005');
    await _settle(tester);
    expect(find.byTooltip('Camp · a house you can build'), findsOneWidget);

    // Points spent, quest turned in: the dots go.
    await tester.runAsync(() =>
        container.read(playerSessionProvider.notifier).loadSession(_session({
              'gold': 400,
              'completedQuestIds': ['q_first_blood'],
              'builtHouseIds': ['keldas_hall', 'barracks_annex'],
              'enemyKillCounts': {'slum_thug': 1},
            })));
    await _settle(tester);
    expect(find.byTooltip('Character'), findsOneWidget);
    expect(find.byTooltip('Camp'), findsOneWidget);
    expect(find.byTooltip('Other'), findsOneWidget);
  });
}
