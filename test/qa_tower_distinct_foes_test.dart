// QA guard for the duplicate-foe blocker (found by the real-fight reruns of
// main 1.911): a Tower floor with the same foe twice (seed 2, floor 6: two
// Harbour Rats) must start its fight when the player taps "Fight". Before the
// fix `towerFightFor` collected the foes in a map by id, saw 1 record for 2
// foes and returned "not fought": the button did nothing and the climb ended.
//
// A saved run of seed 2 is put on floor 6 and played through the real
// launcher and FightScreen; the fight screen must open.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

void main() {
  testWidgets('a Tower floor with the same foe twice starts its fight',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final data = towerDataFromAssets();
    const seed = 2;
    const floorNo = 6;
    final foes = towerFloorsFor(seed, data.enemies)[floorNo - 1].enemyIds;
    // The premise: this floor repeats a foe (if the generator changes, pick
    // another seed and floor from the batch).
    expect(foes.toSet().length, lessThan(foes.length),
        reason: 'seed $seed floor $floorNo no longer repeats a foe: $foes');

    final run = towerStart(
            seed: seed, raceId: 'human', professionId: 'warrior', data: data)
        .copyWith(floor: floorNo);
    SharedPreferences.setMockInitialValues({
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });
    final enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(enemies.keys, containsAll(foes.toSet()));

    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 860);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    Future<void> settle([int n = 6]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> tapKey(String key) async {
      final f = find.byKey(Key(key));
      for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
        final vertical = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
        if (vertical.evaluate().isEmpty) break;
        await tester.drag(vertical.first, const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(f, findsWidgets, reason: 'no "$key" on the screen');
      await tester.ensureVisible(f.first);
      await tester.tap(f.first);
      await settle();
    }

    await settle(10);
    await tester.ensureVisible(find.byKey(const Key('menu_tower')));
    await tapKey('menu_tower');
    await tapKey('tower_continue');
    await settle(10);
    await tapKey('tower_fight');
    await settle(20);
    expect(find.byType(FightScreen), findsOneWidget,
        reason: 'Fight on floor $floorNo ($foes) did nothing: the launcher '
            'gave up on a floor with a repeated foe');
    // Both foes are in the fight, the repeat too (Core, v1.915).
    final screen = tester.widget<FightScreen>(find.byType(FightScreen));
    expect([screen.enemyId, ...screen.additionalEnemyIds], foes);
    expect(screen.additionalEnemies.keys, containsAll(foes.skip(1).toSet()));
  });
}
