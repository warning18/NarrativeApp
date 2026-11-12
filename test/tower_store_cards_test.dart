// The Tower's stores on the floor screen (floor events PR 4, UX): the
// merchant's stall in the shop room after a boss and the bargain's card on a
// landing. Core's view feeds them as it is (stock, prices, wallet), Buy and
// Leave and the bargain's choice go to Core's functions, and the fight waits
// until the store is left or the bargain chosen. Only in a climb of events
// version 2 (nothing for players yet).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_event_card.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'support/pump.dart';

void main() {
  final data = towerDataFromAssets();
  const v = towerPeacefulEvents;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  TowerRun landing(int seed, int floor) {
    final start = towerStart(
            seed: seed,
            raceId: 'human',
            professionId: 'warrior',
            events: v,
            data: data)
        .copyWith(floor: floor);
    final run = start.copyWith(health: towerHeroOf(start, data).maxHealth);
    final won = towerAfterFight(run, data, won: true, healthLeft: run.health);
    return towerPick(won, data, null);
  }

  /// A landing whose store is a [kind] (the shop room after floor 10 for a
  /// merchant, a scan of seeds for a bargain).
  TowerRun storeOf(TowerEventKind kind) {
    for (var seed = 1; seed < 400; seed++) {
      for (final floor in kind == TowerEventKind.merchant
          ? const [10]
          : [for (var f = 2; f < 29; f++) f]) {
        if (floor % 5 == 0 && kind == TowerEventKind.bargain) continue;
        final run = landing(seed, floor);
        if (towerStoreKindOf(run) == kind) return run;
      }
    }
    throw StateError('no $kind store found');
  }

  Widget host(Widget child) => ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  testWidgets('the stall shows Core\'s stock, prices and wallet',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final run = storeOf(TowerEventKind.merchant);
    final view = towerEventOf(run, data)!;
    expect(view.kind, TowerEventKind.merchant);
    expect(view.storeOpen, isTrue);
    final bought = <String>[];
    var left = 0;
    await tester.pumpWidget(host(
        TowerEventCard(view, onBuy: bought.add, onLeaveStore: () => left++)));
    await tester.pump();
    expect(find.byKey(const Key('tower_merchant')), findsOneWidget);
    expect(find.text('Marks to spend: ${view.wallet}'), findsOneWidget);
    for (final item in view.stock!) {
      expect(find.byKey(Key('tower_stall_${item.id}')), findsOneWidget);
      final buy = find.byKey(Key('tower_stall_buy_${item.id}'));
      final button = tester.widget<FilledButton>(buy);
      expect(button.onPressed == null, !item.affordable, reason: item.id);
      if (item.affordable) {
        await tester.tap(buy);
        expect(bought.last, item.id);
      }
    }
    await tester.tap(find.byKey(const Key('tower_merchant_leave')));
    expect(left, 1);
  });

  testWidgets('a store that is shut draws no stall', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final run = storeOf(TowerEventKind.merchant);
    final shut = towerLeaveStore(run);
    final view = towerEventOf(shut, data);
    await tester.pumpWidget(
        host(view == null ? const SizedBox() : TowerEventCard(view)));
    await tester.pump();
    expect(find.byKey(const Key('tower_merchant')), findsNothing);
  });

  Future<ProviderContainer> open(WidgetTester tester, TowerRun run) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      'tower_run_v1': jsonEncode(run.toJson()),
    });
    usePhone(tester, const Size(400, 1800));
    final container = ProviderContainer(overrides: [
      towerDataProvider.overrideWith((ref) async => data),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: TowerFloorScreen()),
    ));
    await settle(tester);
    return container;
  }

  testWidgets('the shop room: Buy spends marks, the fight waits for Leave',
      (tester) async {
    final run = storeOf(TowerEventKind.merchant);
    final marks = run.marks;
    final container = await open(tester, run);
    expect(find.byKey(const Key('tower_merchant')), findsOneWidget);
    expect(find.byKey(const Key('tower_fight')), findsNothing);
    final buy = find.byKey(const Key('tower_stall_buy_salve'));
    expect(tester.widget<FilledButton>(buy).onPressed, isNotNull);
    await tester.ensureVisible(buy);
    await tester.tap(buy);
    await settle(tester);
    final after = container.read(towerProvider).value!.run!;
    expect(after.marks, lessThan(marks));
    expect(after.bought[after.store], contains('salve'));
    // Bought once; the stall is still open and the fight still waits.
    expect(find.byKey(const Key('tower_merchant')), findsOneWidget);
    expect(find.byKey(const Key('tower_fight')), findsNothing);
    final leave = find.byKey(const Key('tower_merchant_leave'));
    await tester.ensureVisible(leave);
    await tester.tap(leave);
    await settle(tester);
    expect(find.byKey(const Key('tower_merchant')), findsNothing);
    expect(find.byKey(const Key('tower_fight')), findsOneWidget);
  });

  testWidgets('the bargain: the fight waits for the choice, taken or refused',
      (tester) async {
    for (final take in [true, false]) {
      final run = storeOf(TowerEventKind.bargain);
      final container = await open(tester, run);
      expect(find.byKey(const Key('tower_bargain')), findsOneWidget);
      expect(find.byKey(const Key('tower_fight')), findsNothing);
      final choice = find
          .byKey(Key(take ? 'tower_bargain_accept' : 'tower_bargain_refuse'));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await settle(tester);
      expect(find.byKey(const Key('tower_bargain')), findsNothing);
      expect(find.byKey(const Key('tower_fight')), findsOneWidget);
      final after = container.read(towerProvider).value!.run!;
      expect(after.bargains[after.store] ?? 0, take ? greaterThan(0) : 0);
    }
  });
}
