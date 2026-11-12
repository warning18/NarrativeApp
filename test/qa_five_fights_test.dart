// QA: the five deadliest story fights of the difficulty review, played on the
// REAL fight screen by a basic player (the walkthrough drivers' dice play:
// roll, confirm, no rerolls, no thought), with Core's "typical" heroes.
//
// Inert unless QA_FIVE=<folder> is set (it writes `five-fights.json`, one row
// a run, and `_trace.txt`). Other variables:
//   QA_FIVE_BUILDS   the builds file (default docs/simulation/typical-player-builds.json)
//   QA_FIVE_N        runs a fight (default 12)
//   QA_FIVE_IDS      comma list of encounter ids (default all five)
//   QA_FIVE_PROF     a profession id to play (default: the file's mostCommonProfession)
//
// Each run loads the build's PlayerSession (PlayerSession.fromJson of its
// `save`), opens FightScreen on the fight's foes in the build's chapter
// (EncounterModifiers(chapter, isTest)), with Random(1000 * id + run) for the
// dice, so a run can be played again alone. The place, the zone and the
// scene's own modifiers are NOT set: the foes and the hero only.
//
// The figure is a LOWER bound on a fight (a basic player), not a typical one.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'qa_smoke_harness.dart';

void main() {
  final out = Platform.environment['QA_FIVE'];
  if (out == null) {
    test('the five-fights check runs only with QA_FIVE', () {});
    return;
  }
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  testWidgets('five fights, a basic player, a typical hero', (tester) async {
    final builds = jsonDecode(File(Platform.environment['QA_FIVE_BUILDS'] ??
            'docs/simulation/typical-player-builds.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final runs = int.tryParse(Platform.environment['QA_FIVE_N'] ?? '') ?? 12;
    final ids = (Platform.environment['QA_FIVE_IDS'] ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();
    final trace = <String>[];
    final rows = <Map<String, dynamic>>[];
    void note(String s) {
      trace.add(s);
      // ignore: avoid_print
      print('FIVE $s');
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'tutorial_enabled': false,
      'combat_dice_speed': 'quad',
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = smokeSizes.first;

    Future<void> settle([int n = 6]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await settle(10);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settle(10);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await settle(6);
    await tester.runAsync(() =>
        container.read(gameDbProvider(enemiesSchema).notifier).whenLoaded());
    final enemies = container.read(localizedDbProvider(enemiesSchema)).value ??
        const <String, dynamic>{};

    bool has(String key) => find.byKey(Key(key)).evaluate().isNotEmpty;

    for (final id in (ids.isEmpty ? builds.keys.toList() : ids)) {
      final fight = builds[id] as Map<String, dynamic>;
      final prof = Platform.environment['QA_FIVE_PROF'] ??
          fight['mostCommonProfession'] as String;
      final build = (fight['byProfession'] as Map<String, dynamic>)[prof]
          as Map<String, dynamic>;
      final foes = [for (final e in build['enemies'] as List) '$e'];
      for (var run = 0; run < runs; run++) {
        await tester.runAsync(() => container
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson(
                Map<String, dynamic>.from(build['save'] as Map))));
        var rounds = 0;
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        nav.push<bool>(MaterialPageRoute(
          builder: (_) => FightScreen(
            enemyId: foes.first,
            enemy: enemies[foes.first] as Map<String, dynamic>,
            additionalEnemyIds: foes.skip(1).toList(),
            additionalEnemies: {
              for (final f in foes.skip(1))
                f: enemies[f] as Map<String, dynamic>,
            },
            modifiers: EncounterModifiers(
                chapter: build['chapter'] as int, isTest: true),
            random: Random(1000 * (int.tryParse(id) ?? 0) + run),
            onRound: (n) => rounds = n,
          ),
        ));
        await settle(10);
        var outcome = 'timeout';
        for (var i = 0; i < 600 && outcome == 'timeout'; i++) {
          if (find.text('Victory! Return').evaluate().isNotEmpty) {
            outcome = 'won';
            break;
          }
          if (find.text('Face what comes').evaluate().isNotEmpty) {
            outcome = 'lost';
            break;
          }
          final enter = find.text('Enter Battle');
          final confirm = find.text('Confirm');
          final roll = find.textContaining('Roll Dice');
          if (enter.evaluate().isNotEmpty) {
            await tester.ensureVisible(enter);
            await tester.pump();
            await tester.tap(enter);
          } else if (confirm.evaluate().isNotEmpty) {
            await tester.tap(confirm.first);
          } else if (roll.evaluate().isNotEmpty) {
            await tester.tap(roll.first);
          }
          await tester.pump(const Duration(milliseconds: 400));
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
        }
        rows.add({
          'fight': id,
          'run': run,
          'profession': prof,
          'foes': foes,
          'outcome': outcome,
          'rounds': rounds,
        });
        note('$id run $run ($prof): $outcome in $rounds rounds');
        // Leave the fight: chest, offers, the question of mercy, Return.
        for (var i = 0;
            i < 120 && find.byType(FightScreen).evaluate().isNotEmpty;
            i++) {
          if (has('mercy_finish')) {
            await tester.tap(find.byKey(const Key('mercy_finish')));
          } else if (find.text('Take all').evaluate().isNotEmpty) {
            await tester.tap(find.text('Take all'));
          } else if (find
                  .text('What the spoils change')
                  .evaluate()
                  .isNotEmpty &&
              find.text('Take').evaluate().isNotEmpty) {
            await tester.tap(find.text('Take').last);
          } else if (find.text('Victory! Return').evaluate().isNotEmpty) {
            final b = find.ancestor(
                of: find.text('Victory! Return'),
                matching:
                    find.byWidgetPredicate((w) => w is ButtonStyleButton));
            if ((tester.widget(b.first) as ButtonStyleButton).enabled) {
              await tester.tap(find.text('Victory! Return'));
            }
          } else if (find.text('Face what comes').evaluate().isNotEmpty) {
            await tester.tap(find.text('Face what comes'));
          }
          await tester.pump(const Duration(milliseconds: 300));
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
        }
        if (find.byType(FightScreen).evaluate().isNotEmpty) {
          note('$id run $run: the fight did not close; popping it');
          nav.pop();
          await settle(4);
        }
        await settle(4);
      }
    }
    Directory(out).createSync(recursive: true);
    File('$out/five-fights.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rows));
    File('$out/_trace.txt').writeAsStringSync('${trace.join('\n')}\n');
  }, timeout: const Timeout(Duration(minutes: 120)));
}
