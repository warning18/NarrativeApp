// The Tower's loot table on rules 2 (v2.10.26): it keeps "Not now", and its
// answer shows a spoils summary closed by Continue.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_styled_card.dart';
import 'support/pump.dart';

void main() {
  final data = towerDataFromAssets();
  final start = towerStart(
      seed: 5, raceId: 'human', professionId: 'warrior', data: data, rules: 2);

  Future<void> open(WidgetTester tester, TowerRun run) async {
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
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a loot table: Not now stays, and a pick waits for Confirm',
      (tester) async {
    await open(
        tester,
        start.copyWith(
            status: TowerStatus.choosing,
            table: TowerTableKind.loot,
            floor: 6,
            offer: const [
              TowerReward(TowerRewardKind.gear, id: 'armor_leather'),
              TowerReward(TowerRewardKind.bundle, id: 'p2a1'),
              TowerReward(TowerRewardKind.purse, amount: 2),
            ]));
    expect(find.byType(TowerStyledCard), findsNWidgets(3));
    expect(find.byKey(const Key('tower_refuse')), findsOneWidget);
    expect(find.byKey(const Key('level_up_ribbon')), findsNothing);
    await tester.tap(find.byKey(const Key('tower_card_2')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('tower_take')));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The pick waits for Confirm: the sheet shows, nothing is taken yet.
    expect(find.byKey(const Key('tower_pick_confirm')), findsOneWidget);
    var saved = (await TowerSave.open()).loadRun()!;
    expect(saved.loot.containsKey(6), isFalse);
    expect(saved.status, TowerStatus.choosing);
    // Change goes back to the three cards.
    await tester.tap(find.byKey(const Key('tower_change')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('tower_pick_confirm')), findsNothing);
    expect(find.byKey(const Key('tower_card_2')), findsOneWidget);
    // Pick again and Confirm: now it counts.
    await tester.tap(find.byKey(const Key('tower_card_2')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('tower_take')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('tower_confirm')));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    saved = (await TowerSave.open()).loadRun()!;
    expect(saved.loot[6]?.kind, TowerRewardKind.purse);
  });
}
