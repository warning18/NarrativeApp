// QA: how far the Tower bot's headless fight (simulateSimFight: no affixes,
// no clan-die resonance, no specialisations) is from the real fight screen.
// Round 3, idea 7 (docs/proposals/qa-ideas-round-3.md). Only with
// QA_REAL_SAMPLE=<out.json>; without it the file holds one empty test.
//
// For a sample of floors the bot died on, the hero as it stood there (full
// health) fights the floor twice over: on the headless fight, many times, and
// on the real FightScreen (the Tower's own session, the floor's foes with
// their affixes), a few times, played the naive way (Roll Dice, then Confirm).
// What it writes is the two win rates per floor. It never edits lib/.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_session.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'skill_fight_harness.dart' show settle;
import 'support/pump.dart';

void main() {
  final out = Platform.environment['QA_REAL_SAMPLE'];
  if (out == null || out.isEmpty) {
    test('the real-fight sample runs only with QA_REAL_SAMPLE', () {});
    return;
  }
  final floorsWanted =
      int.tryParse(Platform.environment['QA_SAMPLE_FLOORS'] ?? '') ?? 10;
  final realTries =
      int.tryParse(Platform.environment['QA_SAMPLE_REAL'] ?? '') ?? 3;
  final simTries =
      int.tryParse(Platform.environment['QA_SAMPLE_SIM'] ?? '') ?? 60;
  final data = towerDataFromAssets();

  // The dead runs of seeds 1..: one for each of the floors wanted, taken
  // from those the bot dies on, spread over them.
  final dead = <TowerRun>[];
  for (var seed = 1; seed <= 400 && dead.length < 200; seed++) {
    final run = playTowerRun(seed: seed, data: data);
    if (run.status == TowerStatus.dead) dead.add(run);
  }
  dead.sort((a, b) => a.floor.compareTo(b.floor));
  final onlySeed = int.tryParse(Platform.environment['QA_SAMPLE_SEED'] ?? '');
  final sample = onlySeed != null
      ? [dead.firstWhere((r) => r.seed == onlySeed)]
      : <TowerRun>[
          for (var i = 0; i < floorsWanted; i++)
            dead[(i * (dead.length - 1) / (floorsWanted - 1)).round()],
        ];

  testWidgets('the real-fight sample', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final rows = <Map<String, Object?>>[];
    for (final run in sample) {
      final floor = towerFloorOf(run, data);
      // The headless fight, as the bot plays it.
      var simWins = 0;
      var simLeft = 0.0;
      for (var t = 0; t < simTries; t++) {
        final hero = towerHeroOf(run, data)..currentHealth = 0;
        hero.currentHealth = hero.maxHealth;
        final outcome = simulateSimFight(
          character: hero,
          enemies: [
            for (final id in floor.enemyIds)
              MapEntry(id, data.enemies[id] as Map<String, dynamic>),
          ],
          chapter: floor.chapter,
          zoneMultiplier: floor.extraFor(run.professionId) *
              (floor.elite ? towerSimEliteMultiplier : 1.0),
          skills: data.skills,
          items: data.items,
          random: Random(1000 + t),
        );
        if (outcome.won) {
          simWins++;
          simLeft += hero.currentHealth / hero.maxHealth;
        }
      }
      // The real fight.
      var realWins = 0;
      var realLeft = 0.0;
      var realPlayed = 0;
      for (var t = 0; t < realTries; t++) {
        final result = await _realFight(tester, run, floor, data, 7 + t);
        if (result == null) continue;
        realPlayed++;
        if (result.won) {
          realWins++;
          realLeft += result.healthLeft;
        }
      }
      rows.add({
        'seed': run.seed,
        'floor': run.floor,
        'profession': run.professionId,
        'foes': floor.enemyIds,
        'affixes': [for (final a in floor.affixes) a.name],
        'elite': floor.elite,
        'simWinRate': simWins / simTries,
        'simHealthLeft': simWins == 0 ? 0 : simLeft / simWins,
        'realPlayed': realPlayed,
        'realWins': realWins,
        'realHealthLeft': realWins == 0 ? 0 : realLeft / realWins,
      });
      debugPrint('SAMPLE ${rows.last}');
    }
    File(out)
      ..createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rows));
  }, timeout: const Timeout(Duration(minutes: 40)));
}

class _Result {
  _Result(this.won, this.healthLeft);
  final bool won;
  final double healthLeft;
}

/// One floor played on the real fight screen: the hero as it stood on [run]'s
/// floor with full health, the floor's foes, the naive way (Roll Dice, then
/// Confirm, until the fight ends). Null when the fight did not end in time.
Future<_Result?> _realFight(WidgetTester tester, TowerRun run, TowerFloor floor,
    TowerData data, int seed) async {
  SharedPreferences.setMockInitialValues({
    'combat_dice_speed': 'quad',
    'tutorial_enabled': false,
  });
  usePhone(tester, const Size(412, 860));
  final session = towerSessionOf(run, data)
      .copyWith(currentHealth: towerHeroOf(run, data).maxHealth);
  await tester.pumpWidget(ProviderScope(
      key: UniqueKey(), // a new scope, or the last fight's state is kept
      overrides: [
        fightRandomProvider.overrideWithValue(() => Random(seed)),
      ],
      child: const MyApp()));
  await settle(tester);
  // The app loads its own session as it starts: the hero is given after.
  await tester.runAsync(() =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
          .read(playerSessionProvider.notifier)
          .loadSession(session));
  await settle(tester);
  final records = <String, Map<String, dynamic>>{
    for (final id in floor.enemyIds)
      id: data.enemies[id] as Map<String, dynamic>,
  };
  final before =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
          .read(playerSessionProvider);
  debugPrint('SESSION floor ${floor.floor}: session lvl ${session.level} '
      'hp ${session.maxHealth}, app has lvl ${before.level} hp '
      '${before.maxHealth} ${before.professionId}');
  bool? won;
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<bool>(
          builder: (_) => FightScreen(
                enemyId: floor.enemyIds.first,
                enemy: records[floor.enemyIds.first]!,
                additionalEnemyIds: floor.enemyIds.skip(1).toList(),
                additionalEnemies: {
                  for (final id in floor.enemyIds.skip(1)) id: records[id]!,
                },
                modifiers: floor.modifiersFor(run.professionId),
              )))
      .then((v) => won = v)
      .ignore();
  await settle(tester);
  final enter = find.text('Enter Battle');
  if (enter.evaluate().isNotEmpty) {
    await tester.ensureVisible(enter);
    await tester.pump();
    await tester.tap(enter);
    await settle(tester);
  }
  for (var i = 0; i < 400 && won == null; i++) {
    // A boss beaten opens the clans' offer over the fight: "Victory!" (the
    // screen waits for a tap; the fight is won).
    if (find.textContaining('Victory!').evaluate().isNotEmpty) {
      final left =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
              .read(playerSessionProvider);
      return _Result(true, left.currentHealth / left.maxHealth);
    }
    // The hero down: the fight is lost (the screen waits for a tap).
    if (find.text('Nobody can act this round.').evaluate().isNotEmpty) {
      return _Result(false, 0);
    }
    final roll = find.textContaining('Roll Dice');
    final confirm = find.text('Confirm');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm.first);
    } else if (roll.evaluate().isNotEmpty) {
      await tester.tap(roll.first);
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
  if (won == null) {
    debugPrint('STUCK floor ${floor.floor}: ${[
      for (final e in find.byType(Text).evaluate())
        if ((e.widget as Text).data case final String t when t.isNotEmpty) t
    ].take(60).join(' | ')} || buttons: ${[
      for (final e in find.byType(ButtonStyleButton).evaluate())
        '${find.descendant(of: find.byWidget(e.widget), matching: find.byType(Text)).evaluate().map((t) => (t.widget as Text).data).join('/')}:${(e.widget as ButtonStyleButton).enabled}'
    ]}');
    return null;
  }
  final left =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
          .read(playerSessionProvider);
  return _Result(won!, left.currentHealth / left.maxHealth);
}
