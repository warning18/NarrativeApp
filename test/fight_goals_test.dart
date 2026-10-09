// Fight goals and faction doctrine (v1.212): a fight may ask for more than
// the slaughter (hold the line, rout a pack's captain, subdue a fighter),
// and a faction's people fight by their own habits (the Writ, the short
// con). The engines are pure; one widget test plays a hold to its end.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/doctrine.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/enemy_affix.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/aftermath_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 150 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _enabled(String label) {
  final button = find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
  return button.evaluate().isNotEmpty &&
      (button.evaluate().first.widget as ButtonStyleButton).enabled;
}

Future<void> _tapWhenEnabled(WidgetTester tester, String label) async {
  await _pumpUntil(tester, () => _enabled(label));
  expect(_enabled(label), isTrue, reason: '"$label" never became enabled');
  await tester.tap(find.text(label));
}

Map<String, dynamic> _enemy(String id) =>
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map<String, dynamic>;

void main() {
  group('fight goals', () {
    test('only an eligible fight rolls a goal, about one in four', () {
      final random = Random(7);
      final none = rollFightGoal(
          eligible: false,
          enemyCount: 2,
          canYield: true,
          random: random,
          chance: 1.0);
      expect(none, FightGoal.slay);

      var goals = 0;
      const trials = 4000;
      for (var i = 0; i < trials; i++) {
        if (!rollFightGoal(
                eligible: true, enemyCount: 2, canYield: false, random: random)
            .isSlay) {
          goals++;
        }
      }
      expect(goals / trials, closeTo(fightGoalChance, 0.04));
    });

    test('a pack holds or routs; a lone person may be subdued; a beast not',
        () {
      final random = Random(3);
      final pack = {
        for (var i = 0; i < 200; i++)
          rollFightGoal(
                  eligible: true,
                  enemyCount: 3,
                  canYield: false,
                  random: random,
                  chance: 1.0)
              .kind,
      };
      expect(pack, {FightGoalKind.hold, FightGoalKind.rout});
      expect(
          rollFightGoal(
              eligible: true,
              enemyCount: 1,
              canYield: true,
              random: random,
              chance: 1.0),
          const FightGoal(FightGoalKind.subdue));
      expect(
          rollFightGoal(
              eligible: true,
              enemyCount: 1,
              canYield: false,
              random: random,
              chance: 1.0),
          FightGoal.slay);
    });

    test('a hold lasts four turns against a pair, five against more', () {
      expect(holdRoundsFor(2), 4);
      expect(holdRoundsFor(3), 5);
      final goal = FightGoal(FightGoalKind.hold, rounds: holdRoundsFor(2));
      expect(holdComplete(goal, 3), isFalse);
      expect(holdComplete(goal, 4), isTrue);
      expect(holdComplete(FightGoal.slay, 99), isFalse);
    });

    test('the captain is the sturdiest, the first of equals', () {
      expect(captainIndex([30, 50, 50, 20]), 1);
      expect(captainIndex([10]), 0);
    });

    test('a fighter yields at thirty percent of health, never at zero', () {
      expect(yieldsNow(31, 100), isFalse);
      expect(yieldsNow(30, 100), isTrue);
      expect(yieldsNow(1, 100), isTrue);
      expect(yieldsNow(0, 100), isFalse);
    });

    test('goals can be named by a hand-made fight', () {
      expect(fightGoalFromName('rout'), const FightGoal(FightGoalKind.rout));
      expect(
          fightGoalFromName('subdue'), const FightGoal(FightGoalKind.subdue));
      expect(fightGoalFromName('hold:5'),
          const FightGoal(FightGoalKind.hold, rounds: 5));
      expect(fightGoalFromName('hold', enemyCount: 3)!.rounds, 5);
      expect(fightGoalFromName('nonsense'), isNull);
      expect(fightGoalFromName(null), isNull);
    });

    test('the harder asks pay more, the plain slaughter pays as before', () {
      expect(goalRewardMultiplier(FightGoalKind.slay), 1.0);
      expect(goalRewardMultiplier(FightGoalKind.hold), greaterThan(1.0));
      expect(goalRewardMultiplier(FightGoalKind.rout), greaterThan(1.0));
    });

    test('only people can yield', () {
      expect(canYieldFaction('crows'), isTrue);
      expect(canYieldFaction('dominion'), isTrue);
      expect(canYieldFaction('pit'), isFalse);
      expect(canYieldFaction('choir'), isFalse);
      expect(canYieldFaction(''), isFalse);
      expect(canYieldFaction(null), isFalse);
    });
  });

  group('doctrine', () {
    test('the Writ falls on every third round', () {
      expect([for (var r = 1; r <= 7; r++) writSilencesRound(r)],
          [false, false, true, false, false, true, false]);
      expect(writSilencesRound(0), isFalse);
    });

    test('a boss is never under a doctrine; the first faction with one is', () {
      expect(
          doctrineForFight(factions: ['dominion'], isBoss: [true])?.factionId,
          isNull);
      expect(
          doctrineForFight(
              factions: ['', 'crows', 'dominion'],
              isBoss: [false, false, false])?.factionId,
          'crows');
      expect(doctrineForFight(factions: [''], isBoss: [false]), isNull);
    });

    test('a thief lifts a share of its reward, up to a cap', () {
      expect(plunderPerHit(0), 0);
      expect(plunderPerHit(1), 1);
      expect(plunderPerHit(20), 7);
      expect(plunderCap(20), 40);
      expect(plunderStashAfter(35, 7, 40), 40);
      expect(plunderStashAfter(0, 7, 40), 7);
    });

    test('what escaped is missing from the spoils, never below zero', () {
      expect(plunderLoss(goldGain: 100, escapedStashes: [10, 5]), 15);
      expect(plunderLoss(goldGain: 8, escapedStashes: [10, 5]), 8);
      expect(plunderLoss(goldGain: 50, escapedStashes: []), 0);
    });

    test('a doctrine’s taste makes its affix likelier', () {
      int armored(List<List<EnemyAffix>>? tastes, int seed) {
        final random = Random(seed);
        var n = 0;
        for (var i = 0; i < 4000; i++) {
          final rolled = rollEncounterAffixes(
              enemyIds: ['harbor_rat'],
              isElite: false,
              random: random,
              tastes: tastes);
          if (rolled.first.contains(EnemyAffix.armored)) n++;
        }
        return n;
      }

      final plain = armored(null, 11);
      final tasted = armored([
        [EnemyAffix.armored]
      ], 11);
      expect(tasted, greaterThan(plain * 2));
    });

    test('every faction named by an enemy or a doctrine exists', () {
      final factions =
          (jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
              as Map<String, dynamic>);
      final enemies =
          (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
              as Map<String, dynamic>);
      for (final entry in enemies.entries) {
        final faction =
            (entry.value as Map<String, dynamic>)['faction']?.toString() ?? '';
        if (faction.isEmpty) continue;
        expect(factions.containsKey(faction), isTrue,
            reason: '${entry.key}: $faction');
      }
      for (final id in doctrines.keys) {
        expect(factions.containsKey(id), isTrue, reason: id);
      }
    });

    test('a boss or unique has no faction, so no doctrine', () {
      final enemies =
          (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
              as Map<String, dynamic>);
      // Uniques tuned one by one carry no faction in their own right.
      for (final id in ['void_sovereign', 'white_admiral', 'void_archon']) {
        expect((enemies[id] as Map<String, dynamic>)['faction'], '',
            reason: id);
      }
    });
  });

  testWidgets('goals and doctrine are announced; a hold is held',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
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

    // Rats no blow of the party can fell, and that barely scratch.
    final rat = {
      ..._enemy('harbor_rat'),
      'maxHealth': 20000,
      'damage': 1,
      'faction': '',
      'skillMoves': <dynamic>[],
    };
    NavigatorState navigator() =>
        tester.state<NavigatorState>(find.byType(Navigator).first);

    Future<void> pushFight(FightScreen screen) async {
      navigator().push(MaterialPageRoute<bool>(builder: (_) => screen));
      await _settle(tester);
    }

    FightScreen pack(FightGoal goal) => FightScreen(
          enemyId: 'harbor_rat',
          enemy: rat,
          additionalEnemyIds: const ['harbor_rat'],
          additionalEnemies: {'harbor_rat': rat},
          modifiers: EncounterModifiers(
              forcedGoal: goal,
              forcedCondition: BattlefieldCondition.highGround),
        );

    // A hold, a rout and a subdue each say so before the first die.
    await pushFight(pack(const FightGoal(FightGoalKind.hold, rounds: 2)));
    expect(find.byKey(const Key('fight_goal_banner')), findsOneWidget);
    expect(find.textContaining('Hold the line'), findsOneWidget);
    expect(find.textContaining('Survive 2 of their turns'), findsOneWidget);
    navigator().pop();
    await _settle(tester);

    await pushFight(pack(const FightGoal(FightGoalKind.rout)));
    expect(find.textContaining('Rout'), findsWidgets);
    expect(find.textContaining('their captain'), findsOneWidget);
    navigator().pop();
    await _settle(tester);

    await pushFight(FightScreen(
      enemyId: 'slum_thug',
      enemy: {..._enemy('slum_thug'), 'maxHealth': 20000, 'damage': 1},
      modifiers: const EncounterModifiers(
          forcedGoal: FightGoal(FightGoalKind.subdue),
          forcedCondition: BattlefieldCondition.highGround),
    ));
    expect(find.textContaining('Subdue'), findsWidgets);
    expect(find.textContaining('30'), findsWidgets);
    // The thug is a Salt Crow: the short con is announced beside it.
    expect(find.byKey(const Key('fight_doctrine_banner')), findsOneWidget);
    expect(find.textContaining('The Short Con'), findsOneWidget);
    navigator().pop();
    await _settle(tester);

    // A plain fight shows neither banner.
    await pushFight(FightScreen(
      enemyId: 'harbor_rat',
      enemy: rat,
      modifiers: const EncounterModifiers(
          forcedGoal: FightGoal.slay,
          forcedCondition: BattlefieldCondition.highGround),
    ));
    expect(find.byKey(const Key('fight_goal_banner')), findsNothing);
    expect(find.byKey(const Key('fight_doctrine_banner')), findsNothing);
    navigator().pop();
    await _settle(tester);

    // A hold of two turns: nothing can be felled, so the party wins only by
    // standing through the second enemy turn.
    await pushFight(pack(const FightGoal(FightGoalKind.hold, rounds: 2)));
    await tester.ensureVisible(find.text('Enter Battle'));
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    expect(find.textContaining('Hold 1/2'), findsOneWidget);
    expect(container.read(lastFightOutcomeProvider), isNull);

    await _tapWhenEnabled(tester, 'Roll Dice');
    await _tapWhenEnabled(tester, 'Confirm');
    await _pumpUntil(
        tester,
        () =>
            find.textContaining('Hold 2/2').evaluate().isNotEmpty &&
            _enabled('Roll Dice'));
    expect(container.read(lastFightOutcomeProvider), isNull,
        reason: 'one turn survived of two');
    expect(find.textContaining('Hold 2/2'), findsOneWidget);

    await _tapWhenEnabled(tester, 'Roll Dice');
    await _tapWhenEnabled(tester, 'Confirm');
    await _pumpUntil(
        tester, () => container.read(lastFightOutcomeProvider) != null);
    final outcome = container.read(lastFightOutcomeProvider);
    expect(outcome, isNotNull);
    expect(outcome!.won, isTrue);
    expect(outcome.rounds, 2);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
