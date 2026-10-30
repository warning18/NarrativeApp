// Shared by the skill fight tests (v1.245): plays one round of a fight where
// the player's only die face is a given skill, then opens the log. The suite
// keeps one fight per test file, as the other fight tests do.
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
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/pump.dart';

/// The first settle of a test waits for the game data to load; the later
/// ones only let the screen catch up.
final _warmed = Expando<bool>();

Future<void> settle(WidgetTester tester) async {
  final first = _warmed[tester] == null;
  _warmed[tester] = true;
  for (var i = 0; i < (first ? 8 : 3); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: first ? 200 : 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool shows(String text) =>
    find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

Finder inLog(String text) => find.descendant(
    of: find.byType(BottomSheet), matching: find.textContaining(text));

Future<void> tapWhenEnabled(WidgetTester tester, String label) async {
  bool enabled() {
    final button = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    return button.evaluate().isNotEmpty &&
        (button.evaluate().first.widget as ButtonStyleButton).enabled;
  }

  await pumpUntil(tester, enabled);
  expect(enabled(), isTrue, reason: '"$label" never became enabled');
  await tester.tap(find.text(label));
}

Map<String, dynamic> gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Plays one round of a fight where the player's only face is [skillId], then
/// opens the log. [enemies] thugs stand against the party; the first is the
/// one a strike is aimed at.
Future<void> playSkillRound(WidgetTester tester, String skillId,
    {int enemies = 1}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  final dice = gamedata('dice.json');
  SharedPreferences.setMockInitialValues({
    'gamedb_dice': jsonEncode({
      ...dice,
      'skill_test_die': {
        'diceName': 'skill_test_die',
        'numberOfFaces': 1,
        'faces': [
          {
            'faceName': 'Test',
            'type': 'Skill',
            'value': 0,
            'linkedSkillID': skillId,
            'element': 'None',
          },
        ],
      },
    }),
  });
  usePhone(tester, const Size(600, 1600));

  await tester.pumpWidget(ProviderScope(
      overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
      child: const MyApp()));
  await settle(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'mage',
        'ownedDiceIds': ['skill_test_die'],
        'equippedDiceId': 'skill_test_die',
        'maxHealth': 400,
        'currentHealth': 400,
      })));
  // Thugs too sturdy to fall this round.
  final thug = {
    ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
    'maxHealth': 900,
    // Nothing but plain blows: no wind-up, no brace.
    'skillMoves': <dynamic>[],
  };
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.push(MaterialPageRoute<bool>(
      builder: (_) => FightScreen(
            enemyId: 'slum_thug',
            enemy: thug,
            additionalEnemyIds: [for (var i = 1; i < enemies; i++) 'slum_thug'],
            additionalEnemies: {'slum_thug': thug},
            modifiers: const EncounterModifiers(
                forcedCondition: BattlefieldCondition.highGround,
                forcedGoal: FightGoal.slay),
          )));
  await settle(tester);
  await tester.tap(find.text('Enter Battle'));
  await settle(tester);
  await tapWhenEnabled(tester, 'Roll Dice');
  await pumpUntil(tester, () => shows('Confirm'));
  await tapWhenEnabled(tester, 'Confirm');
  await pumpUntil(tester, () => shows('Round 2'));
  await settle(tester);
  await tester.tap(find.byIcon(Icons.unfold_more));
  await settle(tester);
}
