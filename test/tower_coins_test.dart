// Core: the Tower's coins and perks (v2.10.0, docs/simulation/tower-coins.md):
// the coins each floor pays, each spend (reroll, banish, the stall's salve,
// bundle and boon), the coins lost with the run, the perks bought and worn
// (two at most) and what each does, the first-win bonuses, the trims, and
// the save, old saves too.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_clans.dart';
import 'package:narrative_data_app/data/tower/tower_coins.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = towerDataFromAssets();
  const v = towerPeacefulEvents;

  TowerRun start(int seed,
          {List<String> perks = const [], String friend = '', int heat = 0}) =>
      towerStart(
          seed: seed,
          raceId: 'human',
          professionId: 'warrior',
          events: v,
          perks: perks,
          friend: friend,
          heat: heat,
          data: data);

  /// [seed]'s run climbing [floor], at full health.
  TowerRun at(int seed, int floor,
      {List<String> perks = const [], int heat = 0}) {
    final run = start(seed, perks: perks, heat: heat).copyWith(floor: floor);
    return run.copyWith(health: towerHeroOf(run, data).maxHealth);
  }

  TowerRun win(TowerRun run) =>
      towerAfterFight(run, data, won: true, healthLeft: run.health);

  /// A floor of [kind] on [floor], for the coin table.
  TowerFloor floorOf(int floor, TowerFloorKind kind, {bool elite = false}) =>
      TowerFloor(
          floor: floor,
          kind: kind,
          chapter: 1,
          extra: 1,
          enemyIds: const [],
          elite: elite);

  group('earning', () {
    test('the fixed table: per band, the Elite\'s bonus, none at the top', () {
      const f = TowerFloorKind.fight;
      expect([
        for (final n in [1, 9, 11, 19, 21, 29]) towerCoinsFor(floorOf(n, f))
      ], [
        1,
        1,
        2,
        2,
        3,
        3
      ]);
      expect([
        for (final n in [3, 13, 23]) towerCoinsFor(floorOf(n, f, elite: true))
      ], [
        2,
        4,
        6
      ]);
      expect([
        for (final n in [5, 15, 25])
          towerCoinsFor(floorOf(n, TowerFloorKind.warden))
      ], [
        3,
        6,
        9
      ]);
      expect([
        for (final n in [10, 20, 30])
          towerCoinsFor(floorOf(n, TowerFloorKind.boss))
      ], [
        5,
        10,
        0
      ]);
    });

    test('a floor won pays its coins; met again, or the top, none', () {
      final boss = win(at(3, 10));
      expect(boss.coins, 5);
      expect(boss.coinsEarned, 5);
      final ordinary = win(at(3, 12));
      expect(ordinary.coins, towerCoinsFor(towerFloorOf(at(3, 12), data)));
      // A floor met again (below the crest) pays nothing.
      final again = win(at(3, 12).copyWith(crest: 14));
      expect(again.coins, 0);
      // The top: the climb ends, its coins with it.
      final top = win(at(3, towerTop).copyWith(coins: 7));
      expect(top.status, TowerStatus.won);
      expect(top.coins, 7);
      // Heat multiplies marks, never coins.
      expect(win(at(3, 10, heat: 2)).coins, 5);
    });

    test('a climb earns coins along the way, in hand less spent', () {
      for (var seed = 1; seed <= 6; seed++) {
        final run = playTowerRun(seed: seed, data: data, events: v);
        expect(run.coinsEarned, greaterThan(0), reason: 'seed $seed');
        expect(run.coins, lessThanOrEqualTo(run.coinsEarned));
        expect(run.coins, greaterThanOrEqualTo(0));
      }
    });
  });

  group('spending', () {
    /// [seed]'s floor-5 boon table, with [coins] in hand.
    TowerRun boonTable(int seed,
            {int coins = 30, List<String> perks = const []}) =>
        win(at(seed, 5, perks: perks)).copyWith(coins: coins);

    test('reroll: 3, then 5, 7 on the same table; a new draw; never short', () {
      final table = boonTable(3);
      expect(towerCanReroll(table), isTrue);
      expect(towerRerollPriceOf(table), 3);
      final once = towerReroll(table, data);
      expect(once.coins, 27);
      expect(once.rerolls, {5: 1});
      expect(once.offer.length, table.offer.length);
      expect(once.offer, isNot(table.offer));
      expect(towerRerollPriceOf(once), 5);
      final twice = towerReroll(once, data);
      expect(twice.coins, 22);
      expect(towerRerollPriceOf(twice), 7);
      // The same draw every time (its own stream).
      expect(towerReroll(table, data).offer, once.offer);
      // Short of coins: nothing.
      final poor = table.copyWith(coins: 2);
      expect(identical(towerReroll(poor, data), poor), isTrue);
      // A new table's price starts again at 3.
      expect(towerRerollPriceOf(twice.copyWith(floor: 6)), 3);
      // Climbing: no table.
      final climbing = at(3, 6).copyWith(coins: 30);
      expect(identical(towerReroll(climbing, data), climbing), isTrue);
    });

    test('reroll keeps the oaths; an oath alone is not rerolled', () {
      const oath = TowerReward(TowerRewardKind.clanOath, id: 'mire');
      final alone = boonTable(3).copyWith(offer: [oath]);
      expect(towerCanReroll(alone), isFalse);
      // A clans' table with an oath beside its gifts: the oath stays first.
      final gifts = win(at(3, 1)).copyWith(coins: 30);
      expect(gifts.offer.every((c) => c.clan.isNotEmpty), isTrue);
      final withOath = gifts.copyWith(offer: [oath, ...gifts.offer]);
      final rerolled = towerReroll(withOath, data);
      expect(rerolled.offer.first, oath);
      expect(rerolled.offer.where((c) => c.kind == TowerRewardKind.clanOath),
          [oath]);
      expect(rerolled.offer.skip(1).every((c) => c.clan.isNotEmpty), isTrue);
    });

    test('banish: 4, one a table, five a run, never an oath or a rank-up', () {
      final table = boonTable(3);
      final id = table.offer.first.id;
      final banished = towerBanish(table, 0);
      expect(banished.coins, 26);
      expect(banished.offer.length, table.offer.length - 1);
      expect(banished.banished, {5: id});
      expect(banished.banishedIds, {id});
      // One a table.
      expect(towerCanBanish(banished, 0), isFalse);
      // Never offered again: the offer's taken ids hold it.
      expect(towerHeroView(banished, towerHeroOf(banished, data)).takenIds,
          contains(id));
      // Five a run.
      final five =
          table.copyWith(banished: {1: 'a', 2: 'b', 3: 'c', 4: 'd', 6: 'e'});
      expect(towerCanBanish(five, 0), isFalse);
      // Short of coins, an oath, a rank-up: nothing.
      expect(towerCanBanish(table.copyWith(coins: 3), 0), isFalse);
      final odd = table.copyWith(offer: [
        const TowerReward(TowerRewardKind.clanOath, id: 'mire'),
        TowerReward(TowerRewardKind.rankUp, id: table.offer.first.id),
      ]);
      expect(towerCanBanish(odd, 0), isFalse);
      expect(towerCanBanish(odd, 1), isFalse);
      expect(identical(towerBanish(odd, 0), odd), isTrue);
    });

    test('the stall in coins: the salve 4, the bundle 5, the boon 15', () {
      final landing = towerPick(win(at(3, 10)), data, null).copyWith(coins: 30);
      expect(towerStoreKindOf(landing), TowerEventKind.merchant);
      final view = towerEventOf(landing, data)!;
      expect(view.wallet, 30);
      expect([for (final s in view.stock!) s.price], [4, 5]);
      expect(view.boon!.price, towerBoonPrice);
      expect(view.boon!.affordable, isTrue);
      final hurt = landing.copyWith(health: 1);
      final salve = towerBuy(hurt, data, 'salve');
      expect(salve.coins, 26);
      expect(salve.marks, hurt.marks);
      final boon = towerBuy(salve, data, towerStallBoonId);
      expect(boon.coins, 26 - towerBoonPrice);
      expect(boon.stallOffer.length, 3);
      // A boon floor's three: a skill (or its rank-up), a die, a spell.
      expect(
          boon.stallOffer.map((c) => c.kind),
          everyElement(isIn(const {
            TowerRewardKind.skill,
            TowerRewardKind.rankUp,
            TowerRewardKind.die,
            TowerRewardKind.spell
          })));
      expect(boon.bought[10], ['salve', towerStallBoonId]);
      // Once a stall.
      expect(identical(towerBuy(boon, data, towerStallBoonId), boon), isTrue);
      // Taken: the card is the hero's, replayed from the save.
      final card = boon.stallOffer[1];
      final taken = towerTakeStallBoon(boon, 1);
      expect(taken.stallOffer, isEmpty);
      expect(taken.stallBoons, {10: card});
      final loaded = TowerRun.fromJson(jsonDecode(jsonEncode(taken.toJson())));
      final hero = towerHeroOf(loaded, data);
      switch (card.kind) {
        case TowerRewardKind.die:
          expect(hero.ownedDice.keys, contains(card.id));
        case TowerRewardKind.spell:
          expect([for (final s in hero.knownSpells) s.id], contains(card.id));
        default:
          expect(
              hero.unlockedSkillIds.contains(card.id) ||
                  hero.skillTiers.isNotEmpty,
              isTrue);
      }
      // Never offered again.
      expect(towerHeroView(taken, hero).takenIds, contains(card.id));
      // Left with the boon not chosen: its first card is given.
      final left = towerLeaveStore(boon);
      expect(left.stallBoons, {10: boon.stallOffer.first});
      expect(left.store, isNull);
      // Short of coins: no boon.
      final poor = landing.copyWith(coins: towerBoonPrice - 1);
      expect(identical(towerBuy(poor, data, towerStallBoonId), poor), isTrue);
    });

    test('the coins end with the climb: never banked, never marks', () {
      final run = towerAbandon(win(at(3, 10)).copyWith(coins: 40));
      final after = const TowerProgress().afterRun(run);
      expect(after.marks, run.marks);
      expect(after.toJson().keys, isNot(contains('coins')));
      expect(run.coins, 40, reason: 'left for the end tally, then lost');
    });
  });

  group('perks', () {
    final full = TowerProgress(
        marks: 1000, unlocked: {for (final u in towerUnlocks) u.id});

    test('bought with marks once the tree is full, one worn', () {
      expect(towerPerks.map((p) => p.id), [
        'purse',
        'deep_pockets',
        'early_word',
        'old_friend',
        'second_wind',
        'keen_eye',
        'free_hand',
        'fourth_card'
      ]);
      expect([for (final p in towerPerks) p.cost],
          [40, 40, 45, 50, 50, 55, 55, 70]);
      expect(towerPerks.fold<int>(0, (n, p) => n + p.cost), 405);
      expect(towerPerkSlots, 1);
      // The tree not full: not for sale.
      final partway = full.copyWith(unlocked: {'flame_die'});
      expect(partway.treeFull, isFalse);
      expect(partway.canBuyPerk('purse'), isFalse);
      expect(identical(partway.buyPerk('purse'), partway), isTrue);
      // Bought: its marks off, worn while a slot is free.
      final one = full.buyPerk('purse');
      expect(one.marks, 960);
      expect(one.perks, {'purse'});
      expect(one.worn, ['purse']);
      expect(identical(one.buyPerk('purse'), one), isTrue);
      // The slot taken: a perk bought later is owned, not worn.
      final three = one.buyPerk('keen_eye').buyPerk('fourth_card');
      expect(three.perks, {'purse', 'keen_eye', 'fourth_card'});
      expect(three.worn, ['purse']);
      expect(three.wornPerks, ['purse']);
      // One at most, owned ones only.
      expect(three.wear(['fourth_card', 'purse', 'keen_eye']).worn,
          ['fourth_card']);
      expect(three.wear(['free_hand', 'purse']).worn, ['purse']);
      expect(three.wear(['free_hand']).worn, isEmpty);
      // Toggled: in place of the one worn, or off.
      expect(three.toggleWorn('fourth_card').worn, ['fourth_card']);
      expect(three.toggleWorn('purse').worn, isEmpty);
      expect(
          three.toggleWorn('purse').toggleWorn('keen_eye').worn, ['keen_eye']);
      expect(three.toggleWorn('free_hand').worn, ['purse']);
      // Short of marks, an unknown id: nothing.
      expect(full.copyWith(marks: 39).canBuyPerk('purse'), isFalse);
      expect(full.copyWith(marks: 40).canBuyPerk('purse'), isTrue);
      expect(full.canBuyPerk('whetstone'), isFalse);
      // A run wears one at most: the first known.
      expect(
          start(1, perks: ['purse', 'keen_eye', 'free_hand']).perks, ['purse']);
      expect(start(1, perks: ['nope', 'keen_eye']).perks, ['keen_eye']);
      expect(start(1, perks: ['purse', 'nope']).perks, ['purse']);
    });

    test('Purse: coins in hand at the start', () {
      expect(start(1).coins, 0);
      expect(start(1, perks: [towerPerkPurse]).coins, towerPurseCoins);
      expect(start(1, perks: [towerPerkPurse]).coinsEarned, 0);
    });

    test('Deep pockets: one potion more in the bag', () {
      final plain = start(1);
      final deep = start(1, perks: [towerPerkDeepPockets]);
      expect(towerBagCapOf(plain), 5);
      expect(towerBagCapOf(deep), 6);
      final landing =
          towerPick(win(at(3, 10, perks: [towerPerkDeepPockets])), data, null)
              .copyWith(coins: 20, potions: 5);
      expect(towerBuy(landing, data, 'potions').potions, 6);
    });

    test('Early word: the late oath three floors sooner', () {
      // A floor-12 table of a climb with no oath due: none, then the late
      // oath with the perk.
      for (var seed = 1; seed <= 10; seed++) {
        final plain = at(seed, 12);
        final early = at(seed, 12, perks: [towerPerkEarlyWord]);
        final hero = towerHeroOf(plain, data);
        bool hasOath(TowerRun run) => towerRunOfferFor(run, data, 12, hero)
            .any((c) => c.kind == TowerRewardKind.clanOath);
        expect(hasOath(plain), isFalse, reason: 'seed $seed');
        expect(hasOath(early), isTrue, reason: 'seed $seed');
      }
    });

    test('Old friend: one clan of the pool starts one gift up', () {
      final run = start(1, perks: [towerPerkOldFriend], friend: 'mire');
      expect(run.friend, 'mire');
      final standing = towerStandingOf(run, data);
      final ripple = towerClanRipple('mire', data.clans);
      for (final clan in run.clanPool) {
        expect(standing[clan], (ripple[clan] ?? 0).clamp(0, towerOathStep),
            reason: clan);
      }
      expect(standing['mire'], towerGiftStanding);
      // Not in the pool: the one the seed points to. Not worn: none.
      final drawn = start(4, perks: [towerPerkOldFriend], friend: 'vigil');
      expect(drawn.clanPool, contains(drawn.friend));
      expect(start(1, friend: 'mire').friend, '');
      // Saved.
      expect(TowerRun.fromJson(jsonDecode(jsonEncode(run.toJson()))).friend,
          'mire');
    });

    test('Second wind: health back after a warden or a boss', () {
      for (final floor in [5, 10]) {
        final plain = at(3, floor);
        final wind = at(3, floor, perks: [towerPerkSecondWind]);
        final hurt = plain.health ~/ 3;
        final a = towerAfterFight(plain.copyWith(health: hurt), data,
            won: true, healthLeft: hurt);
        final b = towerAfterFight(wind.copyWith(health: hurt), data,
            won: true, healthLeft: hurt);
        final max = towerHeroOf(a, data).maxHealth;
        expect(b.health - a.health, (max * towerSecondWindShare).round(),
            reason: 'floor $floor');
      }
      // An ordinary floor: nothing more.
      final plain = at(3, 7), wind = at(3, 7, perks: [towerPerkSecondWind]);
      final hurt = plain.health ~/ 3;
      expect(
          towerAfterFight(wind.copyWith(health: hurt), data,
                  won: true, healthLeft: hurt)
              .health,
          towerAfterFight(plain.copyWith(health: hurt), data,
                  won: true, healthLeft: hurt)
              .health);
    });

    test('Keen eye: the first boon\'s skill a rarity up, no other table', () {
      int step(TowerReward card) {
        final rarity = (data.skills[card.id] as Map?)?['rarity'];
        return towerSkillRarities.indexWhere((r) => r.contains(rarity));
      }

      var plainSum = 0, keenSum = 0;
      for (var seed = 1; seed <= 30; seed++) {
        final plain = win(at(seed, 5));
        final keen = win(at(seed, 5, perks: [towerPerkKeenEye]));
        final a = plain.offer.where((c) => c.kind == TowerRewardKind.skill);
        final b = keen.offer.where((c) => c.kind == TowerRewardKind.skill);
        if (a.isEmpty || b.isEmpty) continue;
        expect(step(b.first), greaterThanOrEqualTo(step(a.first)),
            reason: 'seed $seed');
        plainSum += step(a.first);
        keenSum += step(b.first);
        // The second boon table: as without.
        expect(win(at(seed, 10, perks: [towerPerkKeenEye])).offer,
            win(at(seed, 10)).offer);
      }
      expect(keenSum, greaterThan(plainSum));
    });

    test('Free hand: the climb\'s first reroll costs nothing', () {
      final table =
          win(at(3, 5, perks: [towerPerkFreeHand])).copyWith(coins: 0);
      expect(towerRerollPriceOf(table), 0);
      final free = towerReroll(table, data);
      expect(free.rerolls, {5: 1});
      expect(free.coins, 0);
      expect(towerRerollPriceOf(free), towerRerollPrice + towerRerollStep);
      expect(towerRerollPriceOf(free.copyWith(floor: 10)), towerRerollPrice);
    });

    test('Fourth card: the first two boon tables show a fourth card', () {
      for (var seed = 1; seed <= 10; seed++) {
        for (final floor in [5, 10, 15]) {
          final plain = win(at(seed, floor));
          final four = win(at(seed, floor, perks: [towerPerkFourthCard]));
          expect(four.offer.take(plain.offer.length), plain.offer,
              reason: 'seed $seed f$floor');
          expect(four.offer.length, plain.offer.length + (floor < 15 ? 1 : 0),
              reason: 'seed $seed f$floor');
        }
      }
    });
  });

  group('bonuses and looks', () {
    TowerRun won(int heat) => TowerRun(
        seed: 1,
        raceId: 'human',
        professionId: 'warrior',
        health: 1,
        status: TowerStatus.won,
        heat: heat);

    test('first win +30, first win at each Heat +20, once each', () {
      const fresh = TowerProgress();
      final first = fresh.afterRun(won(0));
      expect(first.marks, won(0).marks + towerFirstWinMarks);
      final second = first.afterRun(won(0));
      expect(second.marks - first.marks, won(0).marks);
      final heat1 = second.afterRun(won(1));
      expect(heat1.marks - second.marks, won(1).marks + towerFirstHeatWinMarks);
      expect(heat1.afterRun(won(1)).marks - heat1.marks, won(1).marks);
      // A climb lost: no bonus.
      const dead = TowerRun(
          seed: 1,
          raceId: 'human',
          professionId: 'warrior',
          health: 0,
          status: TowerStatus.dead,
          floor: 30);
      expect(fresh.firstWinBonusOf(dead), 0);
      // A save from before with a win: the plain climb's bonus is not
      // paid again.
      final old = TowerProgress.fromJson({'marks': 0, 'wins': 2});
      expect(old.firstWinBonusOf(won(0)), 0);
      expect(old.firstWinBonusOf(won(1)), towerFirstHeatWinMarks);
    });

    test('trims: 10 marks once the tree is full; Ash\'s earned', () {
      expect(towerTrims.map((t) => t.id),
          ['moth', 'stitch', 'brass', 'bone', 'lamp']);
      final full = TowerProgress(
          marks: 25, unlocked: {for (final u in towerUnlocks) u.id});
      expect(const TowerProgress(marks: 25).canBuyTrim('moth'), isFalse);
      final moth = full.buyTrim('moth');
      expect(moth.marks, 15);
      expect(moth.trims, {'moth'});
      expect(moth.trim, 'moth');
      expect(identical(moth.buyTrim('moth'), moth), isTrue);
      expect(moth.canBuyTrim('ash'), isFalse);
      expect(moth.showTrim(null).trim, isNull);
      expect(identical(moth.showTrim('lamp'), moth), isTrue);
      final ash = moth.copyWith(heatWon: towerHeatMax);
      expect(ash.trimsOwned, {'moth', 'ash'});
      expect(ash.showTrim('ash').trim, 'ash');
      expect(towerShopMarksTotal, 455);
      expect(full.marksToBuyAll, 455);
      expect(const TowerProgress().marksToBuyAll, 665);
      expect(full.nextPerk!.id, 'purse');
    });
  });

  group('the save', () {
    test('a run\'s coins and perks round-trip; an old run has none', () {
      final run =
          win(at(3, 5, perks: [towerPerkOldFriend, towerPerkPurse])).copyWith(
        coins: 12,
        coinsEarned: 30,
        rerolls: {5: 2},
        banished: {3: 'x'},
        stallBoons: {10: const TowerReward(TowerRewardKind.spell, id: 'y')},
        stallOffer: const [TowerReward(TowerRewardKind.die, id: 'z')],
      );
      final json = jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>;
      final loaded = TowerRun.fromJson(json);
      expect(loaded.coins, 12);
      expect(loaded.coinsEarned, 30);
      expect(loaded.rerolls, {5: 2});
      expect(loaded.banished, {3: 'x'});
      expect(loaded.perks, run.perks);
      expect(loaded.friend, run.friend);
      expect(loaded.stallBoons, run.stallBoons);
      expect(loaded.stallOffer, run.stallOffer);
      expect(jsonEncode(loaded.toJson()), jsonEncode(json));
      // A run saved before coins: none of it.
      final old = Map<String, dynamic>.of(json)
        ..removeWhere((k, _) => const {
              'coins',
              'coinsEarned',
              'rerolls',
              'banished',
              'perks',
              'friend',
              'stallBoons',
              'stallOffer'
            }.contains(k));
      final before = TowerRun.fromJson(old);
      expect(before.coins, 0);
      expect(before.perks, isEmpty);
      expect(before.friend, '');
      expect(before.banished, isEmpty);
      expect(before.stallBoons, isEmpty);
      // A plain run writes none of the new keys.
      expect(start(1).toJson().keys,
          isNot(anyOf(contains('coins'), contains('perks'))));
    });

    test('the record\'s perks and trims round-trip; an old record has none',
        () {
      final progress = TowerProgress(
              marks: 500, unlocked: {for (final u in towerUnlocks) u.id})
          .buyPerk('purse')
          .buyPerk('fourth_card')
          .buyTrim('bone');
      final loaded =
          TowerProgress.fromJson(jsonDecode(jsonEncode(progress.toJson())));
      expect(loaded.perks, {'purse', 'fourth_card'});
      expect(loaded.worn, ['purse']);
      expect(loaded.trims, {'bone'});
      expect(loaded.trim, 'bone');
      expect(loaded.marks, progress.marks);
      // A save from the two-slot build wearing two: the first only.
      final two = TowerProgress.fromJson({
        'marks': 0,
        'unlocked': [for (final u in towerUnlocks) u.id],
        'perks': ['keen_eye', 'second_wind'],
        'worn': ['keen_eye', 'second_wind'],
      });
      expect(two.perks, {'keen_eye', 'second_wind'});
      expect(two.worn, ['keen_eye']);
      expect(two.wornPerks, ['keen_eye']);
      expect(two.toJson()['worn'], ['keen_eye']);
      expect(two.toggleWorn('second_wind').worn, ['second_wind']);
      final old = TowerProgress.fromJson({'marks': 12, 'wins': 0});
      expect(old.perks, isEmpty);
      expect(old.worn, isEmpty);
      expect(old.trims, isEmpty);
      expect(old.trim, isNull);
      expect(const TowerProgress().toJson().keys,
          isNot(anyOf(contains('perks'), contains('worn'), contains('trims'))));
    });
  });
}
