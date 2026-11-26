// The Tower's tables on rules 2 (v2.10.26): the Level Up wears the ribbon, a
// fan in the card styles, a radar beside the held card's words and no skip;
// the loot keeps "Not now", and its answer shows a spoils summary closed by
// Continue.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
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

  testWidgets('a Level Up table of rules 2: ribbon, styled fan, radar, no skip',
      (tester) async {
    await open(
        tester,
        start.copyWith(
            status: TowerStatus.choosing,
            table: TowerTableKind.levelUp,
            floor: 6,
            offer: const [
              TowerReward(TowerRewardKind.skill,
                  id: 'shadow_step', clan: 'dominion'),
              TowerReward(TowerRewardKind.skill, id: 'fireball'),
              TowerReward(TowerRewardKind.spell, id: 'spell_ember_wave'),
            ]));
    expect(find.byKey(const Key('level_up_ribbon')), findsOneWidget);
    expect(find.byType(TowerStyledCard), findsNWidgets(3));
    expect(find.byKey(const Key('tower_levelup_radar')), findsOneWidget);
    // Nothing in hand: Take is off, and a Level Up cannot be skipped.
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('tower_take')))
            .onPressed,
        isNull);
    expect(find.byKey(const Key('tower_refuse')), findsNothing);
    await tester.tap(find.byKey(const Key('tower_card_1')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('tower_take')))
            .onPressed,
        isNotNull);
    expect(find.text('+1 INT'), findsOneWidget);
  });
}
