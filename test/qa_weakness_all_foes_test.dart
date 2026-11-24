// QA guard (weaknesses from the start, v1.994 to v1.996): for every distinct
// set of weaknesses and resistances in enemies.json (one foe each), a party
// that has never met the foe sees its weakness marks on the nameplate and none
// of its resistances; once it has beaten the foe's kind it sees both. The two
// rules of Core, drawn by UX, checked over all the data rather than one rat.
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
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/pump.dart';

void main() {
  testWidgets('weaknesses show from the start, resistances are learned',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final all =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    // A few foes that between them carry every element as a weakness and as
    // a resistance (a greedy cover of the data), so the pass stays short.
    final foes = <String, Set<String>>{};
    all.forEach((id, v) {
      if (v is! Map || v['enemyName'] == null) return;
      foes[id] = {
        for (final e in (v['weakTo'] as List?) ?? const []) 'weak $e',
        for (final e in (v['resists'] as List?) ?? const []) 'resist $e',
      };
    });
    final todo = {for (final s in foes.values) ...s};
    final picked = <String>[];
    while (todo.isNotEmpty) {
      final best = foes.entries.reduce((a, b) =>
          a.value.intersection(todo).length >= b.value.intersection(todo).length
              ? a
              : b);
      if (best.value.intersection(todo).isEmpty) break;
      picked.add(best.key);
      todo.removeAll(best.value);
    }
    expect(picked.length, greaterThan(3));
    // And one with neither, which shows no mark at all.
    picked.add(foes.entries.firstWhere((e) => e.value.isEmpty).key);

    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(390, 844));
    await tester.pumpWidget(ProviderScope(
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp()));
    await settleApp(tester);
    final c =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(
        () => c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
    Future<void> session(Map<String, int> kills) => tester.runAsync(() => c
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'enemyKillCounts': kills,
        })));

    int marks(String kind) => find
        .byWidgetPredicate(
            (w) => w.key.toString().contains('fight_mark_${kind}_'))
        .evaluate()
        .length;
    final problems = <String>[];
    for (final id in picked) {
      final data = Map<String, dynamic>.from(all[id] as Map);
      final weak = ((data['weakTo'] as List?) ?? const []).length;
      final resist = ((data['resists'] as List?) ?? const []).length;
      for (final met in [false, true]) {
        await session(met ? {id: 1} : <String, int>{});
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .push(MaterialPageRoute<bool>(
                builder: (_) => FightScreen(
                      enemyId: id,
                      enemy: {...data, 'skillMoves': const <dynamic>[]},
                      modifiers: const EncounterModifiers(
                          forcedCondition: BattlefieldCondition.ambush,
                          forcedGoal: FightGoal.slay),
                    )));
        await settleApp(tester);
        await tester.tapAt(const Offset(4, 300));
        await settleApp(tester);
        final enter = find.text('Enter Battle');
        if (enter.evaluate().isNotEmpty) {
          await tester.ensureVisible(enter);
          await tester.pump();
          await tester.tap(enter);
          await settleApp(tester);
        }
        final w = marks('weak');
        final r = marks('resist');
        if (w != weak) {
          problems.add('$id (met $met): $w weak marks, data has $weak');
        }
        final wantResist = met ? resist : 0;
        if (r != wantResist) {
          problems.add('$id (met $met): $r resist marks, expected $wantResist');
        }
        tester.takeException();
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await settleApp(tester);
      }
    }
    expect(problems, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
