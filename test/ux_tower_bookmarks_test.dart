// The Tower's bookmarks (v2.10.31): three tabs at the top right of the floor,
// each opening a read-only view (stats, gear, dice) over it; the nudges read
// the rules' caps, never a typed 4 or 10.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_levelup_loot.dart'
    show towerNudgeClimbCap;
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'support/pump.dart';

void main() {
  final data = towerDataFromAssets();
  final start = towerStart(
      seed: 5, raceId: 'human', professionId: 'warrior', data: data, rules: 2);
  final run = start.copyWith(floor: 7, taken: {
    1: const TowerReward(TowerRewardKind.gear, id: 'sword_001'),
    5: const TowerReward(TowerRewardKind.die, id: 'flame_die'),
  }, levelUps: {
    2: const [TowerReward(TowerRewardKind.skill, id: 'fireball')],
  });

  testWidgets('the bookmarks open the stats, the gear and the dice',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'app_language': 'en',
      'tower_run_v1': jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });
    usePhone(tester, const Size(412, 900));
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TowerFloorScreen())));
    Future<void> settle([int n = 10]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle(30);
    for (final b in ['stats', 'gear', 'dice']) {
      expect(find.byKey(Key('tower_bookmark_$b')), findsOneWidget);
    }
    expect(find.byKey(const Key('tower_bookmark_panel_stats')), findsNothing);

    // Stats: HP and level, the radar, the nudges against the climb's cap.
    await tester.tap(find.byKey(const Key('tower_bookmark_stats')));
    await settle();
    expect(find.byKey(const Key('tower_bookmark_panel_stats')), findsOneWidget);
    expect(find.text('Level Up nudges: +1 of +$towerNudgeClimbCap this climb'),
        findsOneWidget);

    // Gear: the weapon worn, and a tile for every slot.
    await tester.tap(find.byKey(const Key('tower_bookmark_gear')));
    await settle();
    expect(find.byKey(const Key('tower_bookmark_panel_gear')), findsOneWidget);
    expect(find.byKey(const Key('tower_bookmark_panel_stats')), findsNothing);
    for (final s in ['Head', 'Weapon', 'Banner', 'Top', 'Bottom', 'Foot']) {
      expect(find.byKey(Key('tower_gear_$s')), findsOneWidget);
    }
    expect(find.text('Iron Sword'), findsWidgets);

    // Dice: the die in play and the one won; a tap turns to the other.
    await tester.tap(find.byKey(const Key('tower_bookmark_dice')));
    await settle();
    expect(find.byKey(const Key('tower_bookmark_panel_dice')), findsOneWidget);
    expect(find.byKey(const Key('tower_die_starter_die')), findsOneWidget);
    expect(find.byKey(const Key('tower_die_flame_die')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tower_die_flame_die')));
    await settle(4);
    expect(find.byKey(const Key('tower_die_face_0')), findsOneWidget);

    // Closing: the floor is back.
    await tester.tap(find.byKey(const Key('tower_bookmark_close')));
    await settle();
    expect(find.byKey(const Key('tower_bookmark_panel_dice')), findsNothing);
  });
}
