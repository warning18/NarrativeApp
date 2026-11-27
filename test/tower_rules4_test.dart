// The Tower's rules 4 (lib/data/tower/tower_rules4.dart, docs/simulation/
// tower-round2-proposals.md): the gamble card, the perks redesigned, the
// stat-pick card and the foes 3% more from floor 11, for climbs begun on
// rules 4 only. Rules 1 to 3 climbs deal, give and fight as before.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_coins.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart'
    show towerLeaveStore;
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_levelup_loot.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_rules4.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_session.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_fight_launcher.dart';

void main() {
  final data = towerDataFromAssets();

  TowerRun start(
          {int seed = 7,
          int rules = 4,
          List<String> perks = const [],
          String professionId = 'warrior'}) =>
      towerStart(
          seed: seed,
          raceId: 'human',
          professionId: professionId,
          perks: perks,
          events: towerEventsLive,
          rules: rules,
          data: data);

  /// [run]'s fight won with its health as it stands.
  TowerRun win(TowerRun run) {
    final hero = towerHeroOf(run, data);
    return towerAfterFight(run, data,
        won: true,
        healthLeft: hero.currentHealth,
        potionsLeft: run.potions,
        maxHealthBefore: hero.maxHealth);
  }

  /// [run] played on (fights won, a face-up card taken: the first that is
  /// neither a gamble nor a stat pick) to its first table of [kind]; null
  /// if the climb has none by floor 15.
  TowerRun? toTable(TowerRun run, TowerTableKind kind) {
    for (var guard = 0; guard < 200 && !run.isOver; guard++) {
      if (run.floor > 15) return null;
      if (run.status == TowerStatus.climbing) {
        if (run.store != null) run = towerLeaveStore(run);
        run = win(run);
        continue;
      }
      if (run.table == kind) return run;
      final i = run.offer.indexWhere((c) =>
          c.kind != TowerRewardKind.gamble &&
          c.kind != TowerRewardKind.statPick);
      run = towerPick(run, data, i < 0 ? null : i);
    }
    return null;
  }

  /// The first table of [kind] of a climb from seed [from] on, all its
  /// cards face up (no gamble, no stat pick).
  TowerRun faceUpTable(TowerTableKind kind, {int from = 11}) {
    for (var seed = from;; seed++) {
      final run = toTable(start(seed: seed), kind);
      if (run != null &&
          run.offer.length >= 3 &&
          run.offer.every((c) =>
              c.kind != TowerRewardKind.gamble &&
              c.kind != TowerRewardKind.statPick)) {
        return run;
      }
    }
  }

  /// [run] at its table with card [at] made the gamble, [outcome] under it.
  TowerRun gambled(TowerRun run, TowerGambleOutcome outcome, {int at = 0}) =>
      run.copyWith(
          offer: [...run.offer]..[at] =
              const TowerReward(TowerRewardKind.gamble),
          gambleOutcome: outcome);

  group('the gamble card', () {
    final cards = [
      const TowerReward(TowerRewardKind.skill, id: 'a', clan: 'crows'),
      const TowerReward(TowerRewardKind.skill, id: 'b'),
      const TowerReward(TowerRewardKind.die, id: 'c'),
    ];
    final withOath = [
      const TowerReward(TowerRewardKind.clanOath, id: 'crows'),
      ...cards,
    ];

    test('dealt on 15% of loot and Level Up tables, one, never an oath', () {
      for (final table in [TowerTableKind.loot, TowerTableKind.levelUp]) {
        var dealt = 0;
        const n = 4000;
        final outcomes = <TowerGambleOutcome, int>{};
        for (var seed = 1; seed <= n; seed++) {
          final run = start(seed: seed).copyWith(floor: 1 + seed % 29);
          final deal = towerDealRoundTwo(run, withOath, table);
          final gambles = [
            for (var i = 0; i < deal.offer.length; i++)
              if (deal.offer[i].kind == TowerRewardKind.gamble) i,
          ];
          expect(gambles.length, lessThanOrEqualTo(1));
          expect(gambles.isEmpty, deal.outcome == null);
          expect(deal.offer.first.kind, TowerRewardKind.clanOath,
              reason: 'an oath is never turned face down');
          if (gambles.isNotEmpty) {
            dealt++;
            expect(deal.offer[gambles.first].id, isEmpty,
                reason: 'the card never names its outcome');
            outcomes[deal.outcome!] = (outcomes[deal.outcome!] ?? 0) + 1;
          }
        }
        expect(dealt / n, closeTo(.15, .02), reason: table.name);
        final weights = table == TowerTableKind.loot
            ? towerGambleLootWeights
            : towerGambleLevelUpWeights;
        expect(outcomes.keys.toSet(), weights.keys.toSet(),
            reason: '${table.name}: every outcome of its own list');
        for (final MapEntry(:key, :value) in weights.entries) {
          expect(outcomes[key]! / dealt, closeTo(value / 100, .05),
              reason: '${table.name} ${key.name}');
        }
      }
    });

    test('an oath alone is never gambled', () {
      for (var seed = 1; seed <= 500; seed++) {
        final deal = towerDealRoundTwo(
            start(seed: seed),
            const [TowerReward(TowerRewardKind.clanOath, id: 'crows')],
            TowerTableKind.loot);
        expect(deal.outcome, isNull);
      }
    });

    test('a reload deals the same card and the same outcome', () {
      for (var seed = 1; seed <= 300; seed++) {
        final run = toTable(start(seed: seed), TowerTableKind.loot);
        if (run == null || run.gambleOutcome == null) continue;
        final back = TowerRun.fromJson(
            jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
        expect(back.gambleOutcome, run.gambleOutcome);
        expect(back.offer, run.offer);
        expect(jsonEncode(back.toJson()), jsonEncode(run.toJson()));
        // Dealt again from the same run, the same table.
        final again = towerDealTable(run.copyWith(clearTable: true), data,
            towerHeroOf(run, data), TowerTableKind.loot);
        expect(again.offer, run.offer);
        expect(again.gambleOutcome, run.gambleOutcome);
        // The card on the table never names the outcome.
        expect(jsonEncode([for (final c in run.offer) c.toJson()]),
            isNot(contains(run.gambleOutcome!.name)));
        return;
      }
      fail('no loot gamble dealt in 300 seeds');
    });

    test('the hint: nothing under PER 3, good or bad from 3, the kind from 5',
        () {
      final table = toTable(start(), TowerTableKind.loot)!;
      final hero = towerHeroOf(table, data);
      for (final outcome in towerGambleLootWeights.keys) {
        final run = gambled(table, outcome);
        for (final (per, hint) in [
          (0, TowerGambleHint.none),
          (2, TowerGambleHint.none),
          (
            3,
            towerGambleIsGood(outcome)
                ? TowerGambleHint.good
                : TowerGambleHint.bad
          ),
          (
            4,
            towerGambleIsGood(outcome)
                ? TowerGambleHint.good
                : TowerGambleHint.bad
          ),
          (5, TowerGambleHint.kind),
          (8, TowerGambleHint.kind),
        ]) {
          final h = hero.copy()..perception = per;
          expect(towerGambleHintOf(run, h), hint, reason: '$outcome PER $per');
          expect(towerGambleOutcomeShown(run, h),
              hint == TowerGambleHint.kind ? outcome : null);
        }
      }
      // No gamble on the table: no hint.
      expect(
          towerGambleHintOf(
              table.copyWith(clearGamble: true), hero.copy()..perception = 9),
          TowerGambleHint.none);
    });

    group('a loot table\'s outcomes', () {
      late TowerRun table;
      late int max;
      setUpAll(() {
        table = faceUpTable(TowerTableKind.loot);
        max = towerHeroOf(table, data).maxHealth;
      });

      TowerRun take(TowerGambleOutcome o, {int potions = 2}) =>
          towerPick(gambled(table.copyWith(potions: potions), o), data, 0);

      test('Gilded: a piece of gear one chest tier up', () {
        final after = take(TowerGambleOutcome.gilded);
        expect(after.loot[table.floor]!.kind,
            anyOf(TowerRewardKind.gear, TowerRewardKind.bundle));
        expect(after.lastGamble, TowerGambleOutcome.gilded);
        expect(after.gambleOutcome, isNull);
      });

      test('Twin: both other cards', () {
        final others = table.offer.skip(1).toList();
        final after = take(TowerGambleOutcome.twin);
        expect(after.loot[table.floor], others[0]);
        expect(after.gambles[table.floor], [others[1]]);
        var coins = table.coins, potions = 2;
        for (final c in others.take(2)) {
          if (c.kind == TowerRewardKind.purse) coins += c.amount;
          if (c.kind == TowerRewardKind.bundle) {
            potions += towerBundleOf(c.id).potions;
          }
        }
        expect(after.coins, coins);
        expect(after.potions, potions.clamp(0, towerBagCapOf(table)));
        for (final c in others.take(2)) {
          if (c.kind == TowerRewardKind.gear) {
            expect(towerHeroOf(after, data).ownedItemIds, contains(c.id));
          }
        }
      });

      test('Hoard: 4 coins on floors 1 to 10', () {
        final after = take(TowerGambleOutcome.hoard);
        expect(after.coins, table.coins + 4);
        expect(after.loot[table.floor],
            const TowerReward(TowerRewardKind.gamble, id: 'hoard'));
      });

      test('Dud: nothing', () {
        final after = take(TowerGambleOutcome.dud);
        expect(after.coins, table.coins);
        expect(after.potions, 2);
        expect(after.health, table.health);
      });

      test('Wound: 20% of max health', () {
        final after = take(TowerGambleOutcome.wound);
        expect(after.health, (table.health - (max * .2).round()).clamp(1, max));
      });

      test('Spill: a potion of the bag, else 10% of max health', () {
        expect(take(TowerGambleOutcome.spill).potions, 1);
        final dry = take(TowerGambleOutcome.spill, potions: 0);
        expect(dry.potions, 0);
        expect(dry.health, (table.health - (max * .1).round()).clamp(1, max));
      });
    });

    group('a Level Up table\'s outcomes', () {
      late TowerRun table;
      setUpAll(() {
        table = faceUpTable(TowerTableKind.levelUp);
      });

      TowerRun take(TowerGambleOutcome o) =>
          towerPick(gambled(table, o, at: 0), data, 0);

      List<TowerReward?> level(TowerRun run) =>
          run.levelUps[table.floor] ?? const [];

      test('Bright: a skill card, with its nudge', () {
        final after = take(TowerGambleOutcome.bright);
        final got = level(after).last;
        expect(got, isNotNull);
        expect(got!.kind, anyOf(TowerRewardKind.skill, TowerRewardKind.rankUp));
        expect(after.lastGamble, TowerGambleOutcome.bright);
      });

      test('Twin: both other cards', () {
        final others = table.offer.skip(1).toList();
        final after = take(TowerGambleOutcome.twin);
        expect(level(after).last, others[0]);
        expect(after.gambles[table.floor], [others[1]]);
        final hero = towerHeroOf(after, data);
        for (final c in others.take(2)) {
          if (c.kind == TowerRewardKind.skill) {
            expect(hero.unlockedSkillIds, contains(c.id));
          }
        }
      });

      test('Dud and Wound: the level spent', () {
        expect(level(take(TowerGambleOutcome.dud)).last, isNull);
        final wound = take(TowerGambleOutcome.wound);
        expect(level(wound).last, isNull);
        final max = towerHeroOf(table, data).maxHealth;
        expect(wound.health, (table.health - (max * .2).round()).clamp(1, max));
      });

      test('Hex: the next floor\'s foes 15% stronger, in the app\'s fight too',
          () {
        var after = take(TowerGambleOutcome.hex);
        expect(after.gambles[table.floor], [towerHexMark]);
        // On to the next floor's fight.
        for (var g = 0; after.status == TowerStatus.choosing && g < 10; g++) {
          after = towerPick(after, data, null);
        }
        if (after.store != null) after = towerLeaveStore(after);
        expect(after.floor, table.floor + 1);
        expect(towerHexedOf(after), isTrue);
        final plain = after.copyWith(gambles: const {});
        final hexed = towerFloorOf(after, data);
        final base = towerFloorOf(plain, data);
        expect(
            hexed.extraFor(after.professionId),
            closeTo(
                base.extraFor(after.professionId) * towerHexFoeScale, 1e-9));
        // The app's fight screen reads it (tower_fight_launcher.dart).
        final records = {
          for (final id in hexed.enemyIds)
            id: (data.enemies[id] as Map).cast<String, dynamic>(),
        };
        expect(
            towerFightScreen(after, hexed, records)
                .modifiers
                .difficultyMultiplier,
            closeTo(
                base.modifiersFor(after.professionId).difficultyMultiplier *
                    towerHexFoeScale,
                1e-9));
        // The bot's floor is the same builder's.
        final floors = towerFloorsFor(after.seed, data.enemies,
            events: after.events, heat: after.heat, rules: after.rules);
        expect(
            towerHexFloor(after, floors[after.floor - 1])
                .extraFor(after.professionId),
            hexed.extraFor(after.professionId));
        // Only the next floor.
        expect(towerHexedOf(after.copyWith(floor: after.floor + 1)), isFalse);
        // A rules-3 climb is never hexed, whatever it holds.
        expect(towerHexedOf(TowerRun.fromJson({...after.toJson(), 'rules': 3})),
            isFalse);
      });
    });

    test('the pick is final; a reroll deals face up; never banished', () {
      final table = faceUpTable(TowerTableKind.loot);
      final run = gambled(table, TowerGambleOutcome.gilded).copyWith(coins: 20);
      expect(towerCanBanish(run, 0), isFalse);
      final rerolled = towerReroll(run, data);
      expect(
          rerolled.offer.any((c) => c.kind == TowerRewardKind.gamble), isFalse);
      expect(rerolled.gambleOutcome, isNull);
    });
  });

  group('the stat-pick card', () {
    const cards = [
      TowerReward(TowerRewardKind.skill, id: 'a', clan: 'crows'),
      TowerReward(TowerRewardKind.skill, id: 'b'),
      TowerReward(TowerRewardKind.die, id: 'c'),
    ];

    test('Level Up tables only, on 15%, in place of the die or the spell', () {
      var dealt = 0;
      const n = 4000;
      for (var seed = 1; seed <= n; seed++) {
        final run = start(seed: seed).copyWith(floor: 1 + seed % 29);
        final loot = towerDealRoundTwo(run, cards, TowerTableKind.loot);
        expect(
            loot.offer.any((c) => c.kind == TowerRewardKind.statPick), isFalse);
        final level = towerDealRoundTwo(run, cards, TowerTableKind.levelUp);
        final at =
            level.offer.indexWhere((c) => c.kind == TowerRewardKind.statPick);
        if (at < 0) continue;
        dealt++;
        expect(
            level.offer[0].clan == 'crows' ||
                level.offer[0].kind == TowerRewardKind.gamble,
            isTrue,
            reason: 'the clan\'s card stays');
        // The die (the last card), or the skill when the die is the gamble.
        expect(at, level.offer[2].kind == TowerRewardKind.gamble ? 1 : 2);
      }
      expect(dealt / n, closeTo(.15, .02));
    });

    test('+1 to the chosen stat, outside the nudge caps; saved', () {
      final table = faceUpTable(TowerTableKind.levelUp);
      final run = table.copyWith(
          offer: [...table.offer]..[table.offer.length - 1] =
              const TowerReward(TowerRewardKind.statPick));
      final i = run.offer.length - 1;
      final before = towerHeroOf(run, data);
      // A stat the hero has not: refused.
      expect(identical(towerPick(run, data, i, stat: 'mana'), run), isTrue);
      final after = towerPick(run, data, i, stat: 'dexterity');
      expect(after.levelUps[run.floor]!.last,
          const TowerReward(TowerRewardKind.statPick, id: 'dexterity'));
      final hero = towerHeroOf(after, data);
      expect(hero.dexterity, before.dexterity + 1);
      expect(hero.pickedPoints, before.pickedPoints,
          reason: 'not counted in the nudges');
      // With every nudge cap reached it still gives its point.
      final capped = before.copy()
        ..pickedPoints['dexterity'] = towerNudgeStatCapOf(4)
        ..pickedPoints['strength'] = towerNudgeClimbCapOf(4);
      final dex = capped.dexterity;
      towerApplyReward(capped,
          const TowerReward(TowerRewardKind.statPick, id: 'dexterity'), data);
      expect(capped.dexterity, dex + 1);
      expect(
          towerNudgeOn(capped,
              const TowerReward(TowerRewardKind.statPick, id: 'luck'), data,
              rules: 4),
          isNull);
      // Saved and replayed.
      final back = TowerRun.fromJson(
          jsonDecode(jsonEncode(after.toJson())) as Map<String, dynamic>);
      expect(towerHeroOf(back, data).dexterity, hero.dexterity);
      // No stat given: the hero's damage stat.
      final plain = towerPick(run, data, i);
      expect(plain.levelUps[run.floor]!.last!.id, before.preferredStat);
    });
  });

  group('the perks on rules 4 (rules 3 keeps today\'s)', () {
    test('Purse: 15 coins and the pedlar', () {
      expect(start(perks: [towerPerkPurse]).coins, 15);
      expect(start(perks: [towerPerkPurse], rules: 3).coins, towerPurseCoins);
      final run = start(perks: [towerPerkPurse]);
      expect(towerCanBuyPotion(run), isTrue);
      final bought = towerBuyPotion(run);
      expect(bought.coins, 15 - towerPedlarPrice);
      expect(bought.potions, run.potions + 1);
      // The bag's cap, the coins, a landing, the perk, the rules.
      expect(towerCanBuyPotion(run.copyWith(potions: towerBagCapOf(run))),
          isFalse);
      expect(towerCanBuyPotion(run.copyWith(coins: towerPedlarPrice - 1)),
          isFalse);
      expect(towerCanBuyPotion(run.copyWith(status: TowerStatus.choosing)),
          isFalse);
      expect(towerCanBuyPotion(run.copyWith(fightBegun: true)), isFalse);
      expect(towerCanBuyPotion(start().copyWith(coins: 20)), isFalse);
      final r3 = start(perks: [towerPerkPurse], rules: 3).copyWith(coins: 20);
      expect(towerCanBuyPotion(r3), isFalse);
      expect(identical(towerBuyPotion(r3), r3), isTrue);
    });

    test('Deep pockets: the flask holds 2, in the app\'s fight too', () {
      final flask = towerFlaskOf(start());
      final r4 = start(perks: [towerPerkDeepPockets]);
      final r3 = start(perks: [towerPerkDeepPockets], rules: 3);
      expect(towerHeroOf(r4, data).potions, flask + 1);
      expect(towerSessionOf(r4, data).potionCount, flask + 1);
      expect(towerHeroOf(r3, data).potions, flask);
      expect(towerBagCapOf(r4), towerBagCap + 1);
      expect(towerBagCapOf(r3), towerBagCap + 1);
    });

    test('Early word: 2 flask potions on warden and boss floors', () {
      final flask = towerFlaskOf(start());
      final r4 = start(perks: [towerPerkEarlyWord]);
      final r3 = start(perks: [towerPerkEarlyWord], rules: 3);
      expect(towerFlaskOf(r4.copyWith(floor: 4)), flask);
      expect(towerFlaskOf(r4.copyWith(floor: 5)), flask + 2);
      expect(towerFlaskOf(r4.copyWith(floor: 10)), flask + 2);
      expect(towerFlaskOf(r3.copyWith(floor: 5)), flask);
      expect(
          towerSessionOf(r4.copyWith(floor: 5), data).potionCount, flask + 2);
    });

    test('Old friend: a piece of gear at the start', () {
      var given = 0;
      for (var seed = 1; seed <= 20; seed++) {
        final r4 = start(seed: seed, perks: [towerPerkOldFriend]);
        final r3 = start(seed: seed, perks: [towerPerkOldFriend], rules: 3);
        expect(r3.startGear, isNull);
        expect(r4.friend, r3.friend);
        if (r4.startGear case final gear?) {
          given++;
          expect(gear.kind, TowerRewardKind.gear);
          expect(towerHeroOf(r4, data).ownedItemIds, contains(gear.id));
          final back = TowerRun.fromJson(
              jsonDecode(jsonEncode(r4.toJson())) as Map<String, dynamic>);
          expect(back.startGear, gear);
          // The same seed, the same piece.
          expect(
              start(seed: seed, perks: [towerPerkOldFriend]).startGear, gear);
        }
      }
      expect(given, greaterThan(15));
      expect(start(seed: 3).startGear, isNull);
    });

    test('Second wind: +8% after every floor, +15% on wardens and bosses', () {
      final r4 = start(perks: [towerPerkSecondWind]);
      final r3 = start(perks: [towerPerkSecondWind], rules: 3);
      expect(towerSecondWindShareOf(r4.copyWith(floor: 3)), .08);
      expect(towerSecondWindShareOf(r4.copyWith(floor: 5)), .15);
      expect(towerSecondWindShareOf(r3.copyWith(floor: 3)), 0);
      expect(towerSecondWindShareOf(r3.copyWith(floor: 5)), .15);
    });

    test('Keen eye: loot one chest tier up on floors 1 to 10', () {
      final r4 = start(perks: [towerPerkKeenEye]);
      final r3 = start(perks: [towerPerkKeenEye], rules: 3);
      expect(towerLootTierBonusOf(r4.copyWith(floor: 10)), 1);
      expect(towerLootTierBonusOf(r4.copyWith(floor: 11)), 0);
      expect(towerLootTierBonusOf(r3.copyWith(floor: 3)), 0);
      expect(towerLootTierBonusOf(start().copyWith(floor: 3)), 0);
    });

    test('Free hand: the first reroll of each table free on floors 1 to 10',
        () {
      final r4 = start(perks: [towerPerkFreeHand])
          .copyWith(rerolls: {1: 1}, floor: 3, status: TowerStatus.choosing);
      final r3 = start(perks: [towerPerkFreeHand], rules: 3)
          .copyWith(rerolls: {1: 1}, floor: 3, status: TowerStatus.choosing);
      expect(towerRerollPriceOf(r4), 0);
      expect(towerRerollPriceOf(r4.copyWith(rerolls: {1: 1, 3: 1})),
          towerRerollPrice + towerRerollStep);
      expect(towerRerollPriceOf(r4.copyWith(floor: 11)), towerRerollPrice);
      expect(towerRerollPriceOf(r3), towerRerollPrice);
      // The climb's first, free as before on both.
      expect(towerRerollPriceOf(r3.copyWith(rerolls: const {})), 0);
    });

    test('Fourth card: a 4th loot card on floors 1 to 20', () {
      final r4 = start(perks: [towerPerkFourthCard]);
      expect(towerLootCardsOf(r4.copyWith(floor: 20)), 4);
      expect(towerLootCardsOf(r4.copyWith(floor: 21)), 3);
      expect(
          towerLootCardsOf(
              start(perks: [towerPerkFourthCard], rules: 3).copyWith(floor: 2)),
          3);
      final table = toTable(r4, TowerTableKind.loot)!;
      expect(table.offer.length, 4);
    });

    test('the perks\' lines: `_r4` on rules 4', () {
      expect(towerPerkLineKey('purse', rules: 4), 'tower_perk_purse_line_r4');
      expect(towerPerkLineKey('purse', rules: 3), 'tower_perk_purse_line');
      expect(
          towerPerkLineKey('keen_eye', rules: 1), 'tower_perk_keen_eye_line');
      for (final p in towerPerks) {
        expect(p.lineKeyFor(3), p.lineKey);
        expect(p.lineKeyFor(4), '${p.lineKey}_r4');
      }
    });
  });

  group('rules', () {
    test('the foes 3% more from floor 11 on rules 4 only', () {
      for (final p in towerProfessionScale.keys) {
        for (var f = 1; f <= towerTop; f++) {
          final r3 = towerRulesScaleOf(3, p, floor: f);
          expect(towerRulesScaleOf(4, p, floor: f),
              closeTo(f >= 11 ? r3 * 1.03 : r3, 1e-12),
              reason: '$p floor $f');
        }
      }
    });

    test('a new climb starts on rules 4 (live with UX\'s screens)', () {
      expect(towerRulesLive, 4);
      expect(start().rules, 4);
      expect(start(rules: 9).rules, towerRulesMax);
    });

    test('a rules-4 climb saves and loads at every step', () {
      for (final seed in [3, 8]) {
        playTowerRun(
            seed: seed,
            data: data,
            progress: towerAllUnlocked,
            events: towerEventsLive,
            perks: const [towerPerkPurse],
            rules: 4,
            choice: (run) {
              final json = jsonEncode(run.toJson());
              final back =
                  TowerRun.fromJson(jsonDecode(json) as Map<String, dynamic>);
              expect(jsonEncode(back.toJson()), json);
              return towerBotRoundTwoChoice(run, towerHeroOf(run, data), data);
            });
      }
    });

    test('rules-3 climbs deal and save none of rules 4', () {
      for (final perk in [null, ...towerPerks.map((p) => p.id)]) {
        for (final seed in [1, 2, 5]) {
          final run = playTowerRun(
              seed: seed,
              data: data,
              progress: towerAllUnlocked,
              events: towerEventsLive,
              perks: [if (perk != null) perk],
              rules: 3);
          final json = jsonEncode(run.toJson());
          for (final key in [
            'gamble',
            'statPick',
            'gambles',
            'startGear',
            'lastGamble',
          ]) {
            expect(json, isNot(contains('"$key"')), reason: '$perk $seed');
          }
        }
      }
    });

    test('the bot on rules 4 meets the cards', () {
      var gambles = 0, statPicks = 0;
      for (var seed = 1; seed <= 40; seed++) {
        playTowerRun(
            seed: seed,
            data: data,
            progress: towerAllUnlocked,
            events: towerEventsLive,
            rules: 4,
            choice: (run) {
              if (run.offer.any((c) => c.kind == TowerRewardKind.gamble)) {
                gambles++;
              }
              if (run.offer.any((c) => c.kind == TowerRewardKind.statPick)) {
                statPicks++;
                expect(run.table, TowerTableKind.levelUp);
              }
              return towerBotRoundTwoChoice(run, towerHeroOf(run, data), data);
            });
      }
      expect(gambles, greaterThan(40));
      expect(statPicks, greaterThan(10));
    });
  });
}
