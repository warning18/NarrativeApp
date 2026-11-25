// QA guard (v2.10.0, Tower coins and perks). Written from the changelog's
// numbers, not Core's constants: what a floor pays, what a reroll and a
// banish cost and how often, the stall's prices (half for a sworn clan), the
// one perk slot and the marks shop's prices, and that the coins are never
// marks: they are earned in a climb, spent in it, lost at its end, and no
// coin ever changes the marks banked. The last test is the real app: a floor
// won through the screens pays its coins into the saved run.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_coins.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';

import 'support/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = towerDataFromAssets();

  TowerRun start(int seed, {String clan = '', List<String> perks = const []}) =>
      towerStart(
          seed: seed,
          raceId: 'human',
          professionId: 'warrior',
          clanId: clan,
          perks: perks,
          events: towerEventsLive,
          data: data);

  /// [run] on [floor] at full health, the floor fought and won: its table.
  TowerRun table(TowerRun run, int floor) {
    final on = run.copyWith(
        floor: floor,
        status: TowerStatus.climbing,
        offer: const [],
        health: towerHeroOf(run.copyWith(floor: floor), data).maxHealth);
    return towerAfterFight(on, data, won: true, healthLeft: on.health);
  }

  test(
      'a floor pays 1, 2 or 3 by band, an Elite as much again, a warden '
      '3 / 6 / 9, a boss 5 / 10, the top nothing', () {
    for (var seed = 1; seed <= 60; seed++) {
      final floors =
          towerFloorsFor(seed, data.enemies, events: towerEventsLive, heat: 0);
      for (final f in floors) {
        if (f.floor == towerTop) {
          expect(towerCoinsFor(f), 0, reason: 'the top pays coins');
          continue;
        }
        final band = f.floor <= 10 ? 1 : (f.floor <= 20 ? 2 : 3);
        final base = switch (f.floor) {
          5 || 15 || 25 => 3,
          10 || 20 => 5,
          _ => 1,
        };
        final elite = f.elite || f.elitePack ? 1 : 0;
        expect(towerCoinsFor(f), band * (base + elite),
            reason: 'seed $seed floor ${f.floor}');
      }
    }
    // The shape of the table, read straight off the changelog.
    final plain = towerFloorsFor(1, data.enemies, events: towerEventsLive);
    expect(towerCoinsFor(plain[4]), anyOf(3, 6)); // floor 5, a warden
    expect(towerCoinsFor(plain[9]), anyOf(5, 10)); // floor 10, a boss
    expect(towerCoinsFor(plain[19]), anyOf(10, 20)); // floor 20, a boss
    expect(towerCoinsFor(plain[14]), anyOf(6, 12)); // floor 15, a warden
    expect(towerCoinsFor(plain[24]), anyOf(9, 18)); // floor 25, a warden
  });

  test(
      'a reroll costs 3, then 5, 7, 9 on the same table, 3 on a new one; '
      'a banish 4, one a table, five a run; no marks change', () {
    var run = start(3);
    final paid = <int>[];
    var tables = 0;
    var banished = 0;
    for (final floor in [5, 10, 13, 15, 20, 23]) {
      run = table(run, floor).copyWith(coins: 100);
      expect(run.status, TowerStatus.choosing, reason: 'floor $floor');
      tables++;
      final marks = run.marks;
      // Rerolls: 3, 5, 7, 9.
      for (final price in [3, 5, 7, 9]) {
        final before = run.coins;
        run = towerReroll(run, data);
        paid.add(before - run.coins);
        expect(before - run.coins, price, reason: 'floor $floor reroll');
      }
      // A banish: 4, once a table, five in all.
      final index = [
        for (var i = 0; i < run.offer.length; i++)
          if (const {
            TowerRewardKind.skill,
            TowerRewardKind.die,
            TowerRewardKind.spell
          }.contains(run.offer[i].kind))
            i
      ];
      final before = run.coins;
      if (index.isNotEmpty && banished < 5) {
        final id = run.offer[index.first].id;
        run = towerBanish(run, index.first);
        expect(before - run.coins, 4, reason: 'floor $floor banish');
        expect(run.banishedIds, contains(id));
        banished++;
        // One a table.
        expect(towerCanBanish(run, 0), isFalse, reason: 'a second banish');
      } else if (index.isNotEmpty) {
        expect(towerCanBanish(run, index.first), isFalse,
            reason: 'a sixth banish on floor $floor');
      }
      expect(run.marks, marks, reason: 'a coin spent moved the marks');
    }
    expect(tables, 6);
    expect(banished, 5);
    expect(paid, [
      for (var i = 0; i < 6; i++) ...[3, 5, 7, 9]
    ]);
  });

  test('the stall: the salve 4, the bundle 5, a boon 15; 2, 3, 8 sworn', () {
    TowerRun landingOf(TowerRun run, int floor) =>
        towerPick(table(run, floor), data, null).copyWith(coins: 30);
    TowerRun? plain, sworn;
    for (var seed = 1; seed < 600 && sworn == null; seed++) {
      for (final floor in [5, 10, 15, 20, 25]) {
        final run = landingOf(start(seed), floor);
        if (towerStoreKindOf(run) != TowerEventKind.merchant) continue;
        final clan = towerStoreClanOf(run)!;
        final swornRun = landingOf(start(seed, clan: clan), floor);
        if (towerStoreClanOf(swornRun) != clan) continue;
        plain = run;
        sworn = swornRun;
        break;
      }
    }
    expect(sworn, isNotNull, reason: 'no merchant of a clan one can swear to');
    final full = towerEventOf(plain!, data)!;
    expect([for (final s in full.stock!) s.price], [4, 5]);
    expect(full.boon!.price, 15);
    expect(full.discount, isFalse);
    final half = towerEventOf(sworn!, data)!;
    expect(half.discount, isTrue);
    expect([for (final s in half.stock!) s.price], [2, 3]);
    expect(half.boon!.price, 8);
    // The wallet drops by what the stall shows, and no marks move.
    final hurt = sworn.copyWith(health: 1);
    final bought = towerBuy(towerBuy(hurt, data, 'salve'), data, 'potions');
    expect(bought.coins, 30 - 2 - 3);
    expect(bought.marks, hurt.marks);
    expect(towerBuy(bought, data, towerStallBoonId).coins, 30 - 2 - 3 - 8);
    // Full price without the clan.
    final paid = towerBuy(plain.copyWith(health: 1), data, 'salve');
    expect(paid.coins, 30 - 4);
  });

  test('one perk slot, eight perks at 40 to 70 marks, sold after the tree', () {
    expect(towerPerkSlots, 1);
    expect(towerPerks, hasLength(8));
    for (final p in towerPerks) {
      expect(p.cost, inInclusiveRange(40, 70), reason: p.id);
    }
    expect(
        [for (final p in towerPerks) p.cost], [40, 40, 45, 50, 50, 55, 55, 70]);
    final partway =
        TowerProgress(marks: 1000, unlocked: {towerUnlocks.first.id});
    for (final p in towerPerks) {
      expect(partway.canBuyPerk(p.id), isFalse,
          reason: '${p.id} sold before the tree is full');
    }
    var progress = TowerProgress(
        marks: 1000, unlocked: {for (final u in towerUnlocks) u.id});
    for (final p in towerPerks) {
      final before = progress.marks;
      progress = progress.buyPerk(p.id);
      expect(before - progress.marks, p.cost, reason: p.id);
      expect(progress.wornPerks.length, lessThanOrEqualTo(1),
          reason: 'two perks worn after buying ${p.id}');
    }
    expect(progress.perks, hasLength(8));
    // A new run wears one, whatever is asked.
    expect(
        start(1, perks: ['purse', 'keen_eye', 'free_hand']).perks, ['purse']);
    // Worn through a save: still one.
    final back = TowerProgress.fromJson(
        jsonDecode(jsonEncode(progress.toJson())) as Map<String, dynamic>);
    expect(back.wornPerks.length, lessThanOrEqualTo(1));
  });

  test('coins are earned in a climb and lost at its end; no coin is marks', () {
    final coinsOf = <TowerRun>[];
    for (final heat in [0, 3]) {
      for (var seed = 1; seed <= 150; seed++) {
        coinsOf.add(playTowerRun(
            seed: seed,
            data: data,
            progress: towerAllUnlocked,
            events: towerEventsLive,
            heat: heat));
      }
    }
    for (final run in coinsOf) {
      // The most the floors cleared can pay: a shortcut can make any floor
      // an Elite, so each pays its table's Elite figure.
      var ceiling = 0;
      for (var f = 1; f <= run.floorsCleared && f < towerTop; f++) {
        final band = f <= 10 ? 1 : (f <= 20 ? 2 : 3);
        final base = const {5, 15, 25}.contains(f)
            ? 3
            : const {10, 20}.contains(f)
                ? 5
                : 1;
        ceiling += band * (base + 1);
      }
      expect(run.coins, greaterThanOrEqualTo(0), reason: 'seed ${run.seed}');
      expect(run.coinsEarned, inInclusiveRange(0, ceiling),
          reason: 'seed ${run.seed}: more coins than its floors pay');
      expect(run.coins, lessThanOrEqualTo(run.coinsEarned),
          reason: 'seed ${run.seed}: coins from nowhere');
      // The marks are the floors', the Heat's and the stores', never the coins'.
      expect(run.marksEarned,
          towerMarksOf(run.heightCleared, run.refused.length, heat: run.heat),
          reason: 'seed ${run.seed}');
      // The end: marks banked, no coin kept, the next run starts at none.
      final after = towerAllUnlocked.afterRun(run);
      // Banked: the run's marks and the first win's bonus, nothing of coins.
      expect(
          after.marks,
          towerAllUnlocked.marks +
              run.marks +
              towerFirstWinBonusOf(run, towerAllUnlocked.heatWon),
          reason: 'seed ${run.seed}');
      expect(jsonEncode(after.toJson()), isNot(contains('coin')));
      final next = towerStart(
          seed: run.seed + 1,
          raceId: 'human',
          professionId: 'warrior',
          events: towerEventsLive,
          data: data);
      expect(next.coins, 0);
    }
    // About 50 a climb with every unlock, 80 in a won one (the changelog).
    final mean = coinsOf.map((r) => r.coinsEarned).reduce((a, b) => a + b) /
        coinsOf.length;
    final wins = coinsOf.where((r) => r.status == TowerStatus.won).toList();
    final wonMean =
        wins.map((r) => r.coinsEarned).reduce((a, b) => a + b) / wins.length;
    expect(mean, inInclusiveRange(25, 70), reason: 'a climb earns $mean coins');
    expect(wonMean, inInclusiveRange(55, 120),
        reason: 'a won climb earns $wonMean coins');
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('a floor won on the real screens pays its coins into the save',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final foes =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    final run = start(5);
    final floor1 = towerFloorsFor(5, data.enemies, events: towerEventsLive)[0];
    SharedPreferences.setMockInitialValues({
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
      'combat_dice_speed': 'quad',
      'gamedb_enemies': jsonEncode({
        for (final e in foes.entries)
          e.key: {...(e.value as Map<String, dynamic>), 'maxHealth': 1},
      }),
    });
    usePhone(tester, const Size(412, 860));
    await tester.pumpWidget(ProviderScope(overrides: [
      fightRandomProvider.overrideWithValue(() => Random(7)),
    ], child: const MyApp()));

    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> tapKey(String key) async {
      final f = find.byKey(Key(key));
      for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
        final lists = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
        if (lists.evaluate().isEmpty) break;
        await tester.drag(lists.first, const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(f, findsWidgets, reason: 'no "$key" on the screen');
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await settle();
    }

    Future<Map<String, dynamic>> saved() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return jsonDecode(prefs.getString(towerRunPrefsKey)!)
          as Map<String, dynamic>;
    }

    await settle(10);
    await tapKey('menu_tower');
    await tapKey('tower_continue');
    await settle(10);
    expect((await saved()).containsKey('coins'), isFalse);
    await tapKey('tower_fight');
    final enter = find.text('Enter Battle');
    for (var i = 0; i < 20 && enter.evaluate().isEmpty; i++) {
      await settle(2);
    }
    await tester.ensureVisible(enter);
    await tester.pump();
    await tester.tap(enter);
    await settle(10);
    final back = find.text('Victory! Return');
    for (var i = 0; i < 300 && back.evaluate().isEmpty; i++) {
      final confirm = find.text('Confirm');
      final roll = find.textContaining('Roll Dice');
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm.first);
      } else if (roll.evaluate().isNotEmpty) {
        await tester.tap(roll.first);
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
    }
    expect(back, findsOneWidget, reason: 'floor 1 was not won');
    for (var i = 0; i < 60; i++) {
      final b = find.ancestor(
          of: back,
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      if ((tester.widget(b.first) as ButtonStyleButton).enabled) break;
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.tap(back.first);
    await settle(20);
    final json = await saved();
    final paid = towerCoinsFor(floor1);
    expect(json['coins'], paid, reason: 'floor 1 was won on the screens');
    expect(json['coinsEarned'], paid);
    expect(paid, anyOf(1, 2), reason: 'an ordinary floor 1 pays 1, an Elite 2');
    // Killed and opened again: the coins are still in the run.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(ProviderScope(
        key: UniqueKey(),
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp()));
    await settle(10);
    expect((await saved())['coins'], paid);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
