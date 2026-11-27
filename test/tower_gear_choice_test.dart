// The Tower's gear choice (tower_gear_choice.dart, behind
// towerGearChoiceLive): a loot card's gear waits for the player (equip or
// discard), saved by floor and replayed; the bot equips exactly what the
// automatic rule wore, so its climbs are the same with the choice on.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_coins.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_gear_choice.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  final data = towerDataFromAssets();

  setUp(() => towerGearChoiceOverride = true);
  tearDown(() => towerGearChoiceOverride = null);

  TowerRun start(int seed, {int rules = 2}) => towerStart(
      seed: seed,
      raceId: 'human',
      professionId: 'warrior',
      rules: rules,
      data: data);
  TowerRun won(TowerRun run) {
    final hero = towerHeroOf(run, data);
    return towerAfterFight(run, data,
        won: true,
        healthLeft: hero.currentHealth,
        potionsLeft: run.potions,
        maxHealthBefore: hero.maxHealth);
  }

  TowerRun reload(TowerRun run) =>
      TowerRun.fromJson(jsonDecode(jsonEncode(run.toJson())));

  int score(String id) => towerGearScore(id, data);

  /// The weapon slot's strongest and weakest pieces (by towerGearScore).
  final weapons = [
    for (final MapEntry(:key, :value) in data.items.entries)
      if ((value as Map)['equipSlot'] == 'Weapon') key,
  ]..sort((a, b) => score(a).compareTo(score(b)));
  final strong = weapons.last, weak = weapons.first;

  /// [run]'s loot table with card 0 made gear [id].
  TowerRun withGear(TowerRun run, String id) => run.copyWith(offer: [
        TowerReward(TowerRewardKind.gear, id: id),
        ...run.offer.skip(1),
      ]);

  /// [run] played on to its next loot table (Level Ups refused, stores
  /// left, fights won).
  TowerRun nextLoot(TowerRun run) {
    for (var guard = 0; guard < 100; guard++) {
      if (run.status == TowerStatus.climbing) {
        if (run.store != null) run = towerLeaveStore(run);
        run = won(run);
        if (run.table == TowerTableKind.loot) return run;
        continue;
      }
      run = towerPick(run, data, null);
    }
    fail('no loot table');
  }

  /// A loot table of rules [rules] with card 0 a gear card ([id], or as
  /// dealt).
  TowerRun lootTable({int rules = 2, String? id}) {
    final run = won(start(3, rules: rules));
    expect(run.table, TowerTableKind.loot);
    return withGear(run, id ?? weapons[weapons.length ~/ 2]);
  }

  test('a gear card taken waits: the table stays, nothing else moves', () {
    final table = lootTable();
    final pending = towerPick(table, data, 0);
    expect(pending.pendingGear,
        TowerPendingGear(floor: table.floor, itemId: table.offer[0].id));
    expect(pending.status, TowerStatus.choosing);
    expect(pending.table, TowerTableKind.loot);
    expect(pending.floor, table.floor);
    expect(pending.loot[table.floor], table.offer[0]);
    // Not worn while it waits.
    expect(towerHeroOf(pending, data).equippedItemIds,
        isNot(contains(table.offer[0].id)));
    // Every other pick, the reroll and the banish do nothing.
    expect(identical(towerPick(pending, data, 1), pending), isTrue);
    expect(identical(towerPick(pending, data, null), pending), isTrue);
    expect(towerCanReroll(pending.copyWith(coins: 99)), isFalse);
    expect(towerCanBanish(pending.copyWith(coins: 99), 1), isFalse);
  });

  test('a run waiting is saved and reloaded as it was', () {
    final pending = towerPick(lootTable(), data, 0);
    final back = reload(pending);
    expect(back.pendingGear, pending.pendingGear);
    expect(back.toJson(), pending.toJson());
    expect(jsonEncode(towerEquip(back, data).toJson()),
        jsonEncode(towerEquip(pending, data).toJson()));
    final kept = towerEquip(pending, data);
    expect(kept.pendingGear, isNull);
    expect(reload(kept).gearKept, {pending.floor: true});
    expect(
        reload(towerDiscard(pending, data)).gearKept, {pending.floor: false});
  });

  group('a worse piece', () {
    late TowerRun pending;
    setUpAll(() {
      towerGearChoiceOverride = true;
      final first = towerEquip(towerPick(lootTable(id: strong), data, 0), data);
      expect(towerHeroOf(first, data).equippedBySlot['Weapon'], strong);
      pending = towerPick(withGear(nextLoot(first), weak), data, 0);
      expect(pending.pendingGear?.itemId, weak);
      towerGearChoiceOverride = null;
    });

    test('compared: not better, its rows those of the two pieces', () {
      final compare = towerGearCompareOf(pending, data, weak);
      expect(compare.slot, 'Weapon');
      expect(compare.wornId, strong);
      expect(compare.better, isFalse);
      expect([for (final r in compare.rows.take(3)) r.key],
          ['attackDamage', 'damage', 'armor']);
      final w = data.items[weak] as Map, s = data.items[strong] as Map;
      for (final row in compare.rows) {
        expect(row.offered, (w[row.key] as num?) ?? 0, reason: row.key);
        expect(row.worn, (s[row.key] as num?) ?? 0, reason: row.key);
        expect(row.higherIsBetter, !row.key.startsWith('req'));
        if (row.key.endsWith('Resist') || row.key.endsWith('DmgBonus')) {
          expect(row.offered != 0 || row.worn != 0, isTrue);
        }
      }
      expect(compare.scalingStat, w['scalingStat']?.toString() ?? '');
      expect(compare.wornScalingStat, s['scalingStat']?.toString() ?? '');
      // The other way round, better.
      expect(towerGearCompareOf(pending, data, strong).better, isTrue);
    });

    test('equipped: worn, the strong piece off, and so on replay', () {
      final kept = towerEquip(pending, data);
      expect(kept.pendingGear, isNull);
      expect(kept.gearKept[pending.floor], isTrue);
      for (final run in [kept, reload(kept)]) {
        final hero = towerHeroOf(run, data);
        expect(hero.equippedBySlot['Weapon'], weak);
        expect(hero.equippedItemIds, isNot(contains(strong)));
      }
      // On as towerPick goes on after the loot: the next table, or climbing.
      expect(kept.table == TowerTableKind.loot, isFalse);
    });

    test('discarded: never worn, the strong piece kept, and so on replay', () {
      final dropped = towerDiscard(pending, data);
      expect(dropped.gearKept[pending.floor], isFalse);
      for (final run in [dropped, reload(dropped)]) {
        final hero = towerHeroOf(run, data);
        expect(hero.equippedBySlot['Weapon'], strong);
        expect(hero.equippedItemIds, isNot(contains(weak)));
      }
    });

    test('a strong piece discarded is not worn either', () {
      final table = lootTable(id: strong);
      final dropped = towerDiscard(towerPick(table, data, 0), data);
      expect(
          towerHeroOf(dropped, data).equippedItemIds, isNot(contains(strong)));
    });
  });

  test('a gamble that gives gear waits too (rules 4: Gilded, Twin)', () {
    var gilded = 0, twin = 0;
    for (var seed = 1; seed <= 40 && (gilded == 0 || twin == 0); seed++) {
      final table = won(start(seed, rules: 4));
      if (table.table != TowerTableKind.loot || table.offer.length < 3) {
        continue;
      }
      for (final outcome in [
        TowerGambleOutcome.gilded,
        TowerGambleOutcome.twin
      ]) {
        final run = table.copyWith(
            offer: [...table.offer]..[0] =
                const TowerReward(TowerRewardKind.gamble),
            gambleOutcome: outcome);
        final after = towerPick(run, data, 0);
        final got = after.loot[run.floor]!;
        if (got.kind != TowerRewardKind.gear) {
          expect(after.pendingGear, isNull);
          continue;
        }
        expect(after.pendingGear,
            TowerPendingGear(floor: run.floor, itemId: got.id));
        expect(after.lastGamble, outcome);
        final kept = towerEquip(after, data);
        expect(
            towerHeroOf(reload(kept), data).equippedItemIds, contains(got.id));
        outcome == TowerGambleOutcome.gilded ? gilded++ : twin++;
      }
    }
    expect(gilded, greaterThan(0));
    expect(twin, greaterThan(0));
  });

  test('switched off: the gear is worn by the rule and the climb goes on', () {
    towerGearChoiceOverride = false;
    final table = lootTable(id: strong);
    final after = towerPick(table, data, 0);
    expect(after.pendingGear, isNull);
    expect(after.gearKept, isEmpty);
    expect(towerHeroOf(after, data).equippedBySlot['Weapon'], strong);
    expect(after.table == TowerTableKind.loot, isFalse);
  });

  test('the bot equips iff better: its climbs the same with the choice on', () {
    var choices = 0, declined = 0;
    for (final rules in [2, 3, 4]) {
      for (var seed = 1; seed <= 12; seed++) {
        TowerRun play(bool on) {
          towerGearChoiceOverride = on;
          return playTowerRun(
              seed: seed,
              data: data,
              progress: seed.isEven ? towerAllUnlocked : const TowerProgress(),
              events: towerEventsLive,
              rules: rules);
        }

        final off = play(false), on = play(true);
        expect(off.gearKept, isEmpty);
        expect(on.pendingGear, isNull);
        choices += on.gearKept.length;
        declined += on.gearKept.values.where((k) => !k).length;
        for (final key in on.gearKept.keys) {
          expect(on.loot[key]?.kind, TowerRewardKind.gear);
        }
        final json = on.toJson()..remove('gearKept');
        expect(jsonEncode(json), jsonEncode(off.toJson()),
            reason: 'rules $rules seed $seed');
        // The replays agree too.
        expect(towerHeroOf(on, data).equippedBySlot,
            towerHeroOf(off, data).equippedBySlot);
      }
    }
    expect(choices, greaterThan(0));
    expect(declined, greaterThan(0), reason: 'a worse piece was declined');
  });
}
