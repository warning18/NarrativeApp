// One-time fight tips: the first fight that shows a goal, a doctrine or a
// situation explains it, once per save, all of them in one pass.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/combat/fight_tips.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/tutorial_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/pump.dart';

Map<String, dynamic> _enemy(String id) =>
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map<String, dynamic>;

void main() {
  group('due tips', () {
    final shown = fightTipIdsFor(
        goal: FightGoalKind.hold,
        doctrineFactionId: 'crows',
        condition: BattlefieldCondition.ambush);

    test('a fight shows its goal, doctrine and situation, in that order', () {
      expect(shown, ['goal_hold', 'doctrine_crows', 'situation_ambush']);
      expect(
          fightTipIdsFor(
              goal: FightGoalKind.slay,
              condition: BattlefieldCondition.highGround),
          ['situation_high_ground']);
      expect(fightTipIdsFor(goal: FightGoalKind.slay), isEmpty);
    });

    test('only the unseen are due; none when tutorials are off', () {
      expect(dueFightTips(shown: shown, seen: const [], enabled: true), shown);
      expect(
          dueFightTips(
              shown: shown, seen: const ['doctrine_crows'], enabled: true),
          ['goal_hold', 'situation_ambush']);
      expect(dueFightTips(shown: shown, seen: shown, enabled: true), isEmpty);
      expect(
          dueFightTips(shown: shown, seen: const [], enabled: false), isEmpty);
    });

    test('every goal, doctrine and situation has a name and a tip, EN and FR',
        () {
      expect(allFightTipIds, hasLength(3 + 7 + 5));
      for (final id in allFightTipIds) {
        for (final key in [fightTipTextKey(id), fightTipNameKey(id)]) {
          for (final lang in [AppLanguage.en, AppLanguage.fr]) {
            final text = trFor(lang, key);
            expect(text, isNot(key), reason: '$key ($lang)');
            expect(text, isNotEmpty, reason: '$key ($lang)');
          }
        }
      }
    });
  });

  group('save', () {
    test('the seen tips survive a save; an old save has seen none', () {
      final session = PlayerSession.fromJson({'raceId': 'human'})
          .copyWith(seenFightTipIds: ['goal_hold', 'situation_ambush']);
      final back =
          PlayerSession.fromJson(jsonDecode(jsonEncode(session.toJson())));
      expect(back.seenFightTipIds, ['goal_hold', 'situation_ambush']);
      expect(
          PlayerSession.fromJson({'raceId': 'human'}).seenFightTipIds, isEmpty);
    });
  });

  testWidgets('the first ambush explains itself, the second does not',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(390, 844));

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        fightRandomProvider.overrideWithValue(() => Random(7)),
        tutorialAutoShowProvider.overrideWithValue(true),
      ],
      child: MaterialApp(
          navigatorKey: navigatorKey, home: const SizedBox.shrink()),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'maxHealth': 900,
          'currentHealth': 900,
        })));

    final rat = {..._enemy('harbor_rat'), 'faction': ''};
    FightScreen pack() => FightScreen(
          enemyId: 'harbor_rat',
          enemy: rat,
          additionalEnemyIds: const ['harbor_rat'],
          additionalEnemies: {'harbor_rat': rat},
          modifiers: const EncounterModifiers(
              forcedGoal: FightGoal(FightGoalKind.hold, rounds: 3),
              forcedCondition: BattlefieldCondition.ambush),
        );
    Future<void> pushFight() async {
      navigatorKey.currentState!
          .push(MaterialPageRoute<bool>(builder: (_) => pack()));
      await settleApp(tester);
    }

    // The first hold under an ambush: both explained, one after the other.
    await pushFight();
    expect(find.byKey(const Key('fight_tip_goal_hold')), findsOneWidget);
    expect(find.textContaining('Survive 3 of their turns'), findsWidgets);
    expect(find.textContaining('1/2'), findsOneWidget);
    expect(find.byKey(const Key('fight_tip_situation_ambush')), findsNothing);
    await tester.tap(find.byKey(const Key('fight_tip_next')));
    await settleApp(tester);
    expect(find.byKey(const Key('fight_tip_goal_hold')), findsNothing);
    expect(find.byKey(const Key('fight_tip_situation_ambush')), findsOneWidget);
    expect(find.textContaining('2/2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('fight_tip_ok')));
    await settleApp(tester);
    expect(find.byKey(const Key('fight_tip_situation_ambush')), findsNothing);
    expect(container.read(playerSessionProvider).seenFightTipIds,
        ['goal_hold', 'situation_ambush']);
    navigatorKey.currentState!.pop();
    await settleApp(tester);

    // The same fight again: nothing left to explain.
    await pushFight();
    expect(find.byKey(const Key('fight_goal_banner')), findsOneWidget);
    expect(find.byKey(const Key('fight_tip_goal_hold')), findsNothing);
    expect(find.byKey(const Key('fight_tip_situation_ambush')), findsNothing);
    navigatorKey.currentState!.pop();
    await settleApp(tester);

    // With tutorials off, a fresh save is told nothing.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
        })));
    await tester.runAsync(
        () => container.read(tutorialProvider.notifier).setEnabled(false));
    await pushFight();
    expect(find.byKey(const Key('fight_goal_banner')), findsOneWidget);
    expect(find.byKey(const Key('fight_tip_goal_hold')), findsNothing);
    expect(tester.takeException(), isNull);
    navigatorKey.currentState!.pop();
    await settleApp(tester);
  });
}
