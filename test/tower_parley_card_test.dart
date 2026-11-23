// The parley on the floor screen (floor events PR 3, tower_peaceful_cards.dart
// wired in tower_floor_screen.dart): a guardian's card with Core's odds before
// the fight, a choice that comes first (no fight button until it is made), the
// guardian's plate behind it, and a fight chosen or a talk lost leaving the
// ordinary floor.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_backdrop.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'support/pump.dart';

void main() {
  final data = towerDataFromAssets();

  TowerRun run(int seed, int floor, {Map<int, TowerReward> taken = const {}}) =>
      TowerRun(
        seed: seed,
        raceId: 'human',
        professionId: 'warrior',
        floor: floor,
        health: 40,
        events: towerPeacefulEvents,
        taken: taken,
      );

  /// A seed and floor holding a parley.
  (int, int) parleyFloor() {
    for (var seed = 1; seed < 400; seed++) {
      for (var floor = 2; floor < 29; floor++) {
        if (towerEventKindOf(run(seed, floor)) == TowerEventKind.parley) {
          return (seed, floor);
        }
      }
    }
    throw StateError('no parley found');
  }

  /// The picks a run owes are taken, so no Level Up covers the screen.
  TowerRun settled(TowerRun r) {
    for (var g = 0; g < 64 && towerPendingPicks(r) > 0; g++) {
      final taken = towerTakeStatPick(r, data, 0);
      if (identical(taken, r)) break;
      r = taken;
    }
    return r;
  }

  Future<ProviderContainer> open(WidgetTester tester, TowerRun r) async {
    r = settled(r);
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      'tower_run_v1': jsonEncode(r.toJson()),
    });
    usePhone(tester, const Size(400, 1600));
    final container = ProviderContainer(overrides: [
      towerDataProvider.overrideWith((ref) async => data),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: TowerFloorScreen()),
    ));
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    return container;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('the parley card shows Core\'s odds, and the choice comes first',
      (tester) async {
    final (seed, floor) = parleyFloor();
    final view = towerEventOf(run(seed, floor), data)!;
    await open(tester, run(seed, floor));
    expect(find.byKey(const Key('tower_parley')), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('tower_parley_chance'))).data,
        '${(view.chance! * 100).round()}%');
    expect(find.byKey(const Key('tower_fight')), findsNothing,
        reason: 'the fight waits for the choice');
    // The guardian's plate is behind the floor while the parley is on offer.
    final image = tester.widget<Image>(find.byKey(const Key('tower_backdrop')));
    expect((image.image as AssetImage).assetName, towerEventPlate('parley'));
  });

  testWidgets('a fight chosen leaves the ordinary floor and its own picture',
      (tester) async {
    final (seed, floor) = parleyFloor();
    final container = await open(tester, run(seed, floor));
    await tester.tap(find.byKey(const Key('tower_parley_fight')));
    await settle(tester);
    expect(find.byKey(const Key('tower_fight')), findsOneWidget);
    expect(find.byKey(const Key('tower_parley')), findsNothing);
    expect(container.read(towerProvider).value!.run!.parley, false);
    final image = tester.widget<Image>(find.byKey(const Key('tower_backdrop')));
    expect((image.image as AssetImage).assetName,
        isNot(towerEventPlate('parley')));
  });

  testWidgets('sworn to the guardian\'s clan, the talk needs no roll',
      (tester) async {
    final (seed, floor) = parleyFloor();
    final clan = towerParleyClanOf(run(seed, floor))!;
    final sworn = run(seed, floor,
        taken: {0: TowerReward(TowerRewardKind.clanOath, id: clan)});
    final container = await open(tester, sworn);
    expect(find.byKey(const Key('tower_parley_sworn')), findsOneWidget);
    expect(find.byKey(const Key('tower_parley_chance')), findsNothing);
    await tester.tap(find.byKey(const Key('tower_parley_talk')));
    await settle(tester);
    // A pass lands on the next floor.
    expect(container.read(towerProvider).value!.run!.floor, floor + 1);
  });
}
