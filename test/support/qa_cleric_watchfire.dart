// Shared by qa_cleric_watchfire_test.dart (the story's fight) and
// qa_cleric_watchfire_tower_test.dart (the Tower's detached session; the
// suite keeps one fight per test file).
//
// QA guard for the user's report: "For the cleric when using Mending Light
// the watchfire countdown doesn't accumulate."
//
// The cleric's Watchfire (profession_cores.dart): what heals past full feeds
// a fire, shown on the hero's Watchfire icon, that burns the enemy as the
// round turns. The hero is at full health, so every point Mending Light
// heals is past full: after n casts the icon must show their sum (below the
// cap of half the max health). The same fight is played on the story's own
// session and on the Tower's detached one (TowerFightSession.wrap).

import 'dart:convert';
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

import '../skill_fight_harness.dart' show gamedata, settle;
import 'pump.dart';

/// The number on the hero's Watchfire icon (0 if the icon is not drawn).
int? _fire() {
  final icon = find.byWidgetPredicate(
      (w) => w.key is Key && '${w.key}'.contains('fight_effect_watchfire_'));
  if (icon.evaluate().isEmpty) return null;
  final texts = find.descendant(of: icon.first, matching: find.byType(Text));
  for (final e in texts.evaluate()) {
    final n = int.tryParse((e.widget as Text).data ?? '');
    if (n != null) return n;
  }
  return 0;
}

/// The HP the log says the hero recovered, line by line (the casts).
List<int> _recovered() {
  final out = <int>[];
  for (final e in find
      .descendant(of: find.byType(BottomSheet), matching: find.byType(Text))
      .evaluate()) {
    final m =
        RegExp(r'recovers? (\d+) HP').firstMatch((e.widget as Text).data ?? '');
    if (m != null) out.add(int.parse(m.group(1)!));
  }
  return out;
}

Future<void> playClericCasts(WidgetTester tester,
    {required bool detached}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({
    'combat_dice_speed': 'quad',
    'gamedb_dice': jsonEncode({
      ...gamedata('dice.json'),
      'heal_die': {
        'diceName': 'heal_die',
        'numberOfFaces': 1,
        'faces': [
          {'faceName': 'Mend', 'type': 'Heal', 'value': 6, 'element': 'None'},
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
  final session = PlayerSession.fromJson({
    'raceId': 'human',
    'professionId': 'cleric',
    'ownedDiceIds': ['heal_die'],
    'equippedDiceId': 'heal_die',
    'maxHealth': 400,
    'currentHealth': 400,
    'wisdom': 6,
    'mana': 10,
    'knownSpellIds': ['spell_mending_light'],
  });
  await tester.runAsync(() =>
      container.read(playerSessionProvider.notifier).loadSession(session));
  final thug = {
    ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
    'maxHealth': 900,
    'skillMoves': <dynamic>[],
  };
  final fight = FightScreen(
    enemyId: 'slum_thug',
    enemy: thug,
    modifiers: const EncounterModifiers(
        forcedCondition: BattlefieldCondition.highGround,
        forcedGoal: FightGoal.slay),
  );
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<bool>(
          // The Tower's fight runs under a detached session of the hero
          // (TowerFightSession.wrap does just this).
          builder: (_) => detached
              ? ProviderScope(overrides: [
                  playerSessionProvider.overrideWith(
                      (ref) => PlayerSessionNotifier.detached(session)),
                ], child: fight)
              : fight));
  await settle(tester);
  await tester.tap(find.text('Enter Battle'));
  await settle(tester);
  expect(_fire() ?? 0, 0, reason: 'the Watchfire icon starts at 0');

  var before = 0;
  for (var cast = 1; cast <= 2; cast++) {
    await tester.tap(find.text('Mending Light'));
    await settle(tester);
    final now = _fire() ?? 0;
    expect(now, greaterThan(before),
        reason: 'the hero is at full health: cast $cast of Mending Light '
            'heals past full and must build the Watchfire, whose icon '
            'shows $now after it, $before before');
    before = now;
  }
  // The icon shows all that was healed past full (400 max health: far
  // under the cap of half of it).
  await tester.tap(find.byIcon(Icons.unfold_more));
  await settle(tester);
  final healed = _recovered().fold<int>(0, (a, b) => a + b);
  expect(healed, greaterThan(0));
  expect(before, healed, reason: 'two casts healed $healed past full');
  await tester.pump(const Duration(seconds: 3));
}
