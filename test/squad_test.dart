// Enemy squads and reaction moves (v1.215): pure rules and data.
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
import 'package:narrative_data_app/combat/enemy_response.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/combat/squad.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
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

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('squad roles', () {
    test('a lone enemy never has a role', () {
      for (var seed = 0; seed < 50; seed++) {
        final roles = rollSquadRoles(
            packSize: 1, eligible: [true], random: Random(seed), chance: 1);
        expect(roles, [null]);
      }
    });

    test('a pack keeps at least one plain enemy, one healer, one guard', () {
      for (var seed = 0; seed < 200; seed++) {
        final roles = rollSquadRoles(
            packSize: 3,
            eligible: [true, true, true],
            random: Random(seed),
            chance: 1);
        expect(roles.where((r) => r == null).length, greaterThanOrEqualTo(1));
        expect(roles.where((r) => r == SquadRole.healer).length, lessThan(2));
        expect(roles.where((r) => r == SquadRole.guard).length, lessThan(2));
      }
    });

    test('ineligible enemies (bosses) never get a role', () {
      for (var seed = 0; seed < 100; seed++) {
        final roles = rollSquadRoles(
            packSize: 3,
            eligible: [false, true, false],
            random: Random(seed),
            chance: 1);
        expect(roles[0], isNull);
        expect(roles[2], isNull);
      }
    });

    test('about half of the packs have a squad', () {
      var squads = 0;
      const runs = 2000;
      final random = Random(7);
      for (var i = 0; i < runs; i++) {
        final roles =
            rollSquadRoles(packSize: 2, eligible: [true, true], random: random);
        if (roles.any((r) => r != null)) squads++;
      }
      expect(squads / runs, closeTo(squadChance, 0.05));
    });

    test('a healer mends the most wounded friend, never itself or the dead',
        () {
      expect(
          squadHealTarget(
              health: [10, 4, 0, 9], maxHealth: [10, 10, 10, 10], self: 3),
          1);
      expect(squadHealTarget(health: [5, 10], maxHealth: [10, 10], self: 0),
          isNull);
      expect(squadHealTarget(health: [10, 10], maxHealth: [10, 10], self: 0),
          isNull);
      expect(squadHealAmount(100), 12);
      expect(squadHealAmount(3), 1);
    });
  });

  group('enemy responses', () {
    test('a heavy blow provokes a counter', () {
      expect(provokesCounter(19, 100), isFalse);
      expect(provokesCounter(20, 100), isTrue);
    });

    test('a round of Defend from everyone makes a press-enemy press', () {
      expect(provokesPress(defenders: 2, acting: 2), isTrue);
      expect(provokesPress(defenders: 1, acting: 2), isFalse);
      expect(provokesPress(defenders: 0, acting: 0), isFalse);
    });

    test('provoked beats pressing, neither is 1.0', () {
      expect(responseDamageMultiplier(provoked: false, pressing: false), 1.0);
      expect(responseDamageMultiplier(provoked: false, pressing: true),
          pressDamageMultiplier);
      expect(responseDamageMultiplier(provoked: true, pressing: true),
          counterDamageMultiplier);
    });

    test('enemies.json names only known reactions', () {
      final enemies =
          jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
              as Map<String, dynamic>;
      var withReaction = 0;
      for (final entry in enemies.entries) {
        final raw = (entry.value as Map)['reaction']?.toString() ?? '';
        if (raw.isEmpty) continue;
        withReaction++;
        expect(enemyResponseFromName(raw), isNot(EnemyResponse.none),
            reason: '${entry.key}: unknown reaction "$raw"');
      }
      expect(withReaction, greaterThan(5));
    });
  });

  testWidgets('a squad\'s healer is marked and mends its wounded friend',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final dice = _gamedata('dice.json');
    SharedPreferences.setMockInitialValues({
      'gamedb_dice': jsonEncode({
        ...dice,
        'strike_test_die': {
          'diceName': 'strike_test_die',
          'numberOfFaces': 1,
          'faces': [
            {'type': 'Attack', 'value': 30, 'element': 'None'},
          ],
        },
      }),
    });
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
          'ownedDiceIds': ['strike_test_die'],
          'equippedDiceId': 'strike_test_die',
          'maxHealth': 900,
          'currentHealth': 900,
        })));

    final rat = {
      ..._gamedata('enemies.json')['harbor_rat'] as Map<String, dynamic>,
      'maxHealth': 20000,
      'damage': 1,
      'faction': '',
      'reaction': '',
      'skillMoves': <dynamic>[],
    };
    NavigatorState navigator() =>
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator().push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'harbor_rat',
              enemy: rat,
              additionalEnemyIds: const ['harbor_rat'],
              additionalEnemies: {'harbor_rat': rat},
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.highGround,
                  forcedGoal: FightGoal.slay,
                  forcedSquad: [null, SquadRole.healer]),
            )));
    await _settle(tester);
    await tester.ensureVisible(find.text('Enter Battle'));
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    expect(find.text('Healer'), findsOneWidget);

    // The first rat takes the blow; the healer mends it before they strike.
    await _tapWhenEnabled(tester, 'Roll Dice');
    await _tapWhenEnabled(tester, 'Confirm');
    await _pumpUntil(
        tester,
        () =>
            find.textContaining('Round 2').evaluate().isNotEmpty &&
            _enabled('Roll Dice'));
    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    expect(
        find.descendant(
            of: find.byType(BottomSheet),
            matching: find.textContaining('mends')),
        findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
