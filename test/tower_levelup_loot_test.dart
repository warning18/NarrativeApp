// The Tower's rules 2 (Core's rules PR, docs/simulation/
// tower-levelup-loot.md): Tower XP and the Level Up card table, the stat
// nudges, the loot table, the oath kept as today, the perks re-mapped, and
// TowerRun.rules (a save without it plays out on rules 1). Rules 3 (the
// survival curve, docs/simulation/tower-difficulty-survival.md) at the end:
// rules 2's systems with its own numbers; rules 2 keeps today's.
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_coins.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_gear_choice.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_levelup_loot.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  final data = towerDataFromAssets();

  // These test the automatic gear rule (a loot card's gear worn when it
  // scores at least the worn piece): the gear choice is off here.
  setUp(() => towerGearChoiceOverride = false);
  tearDown(() => towerGearChoiceOverride = null);

  TowerRun start(int seed,
          {String profession = 'warrior',
          int rules = 2,
          int heat = 0,
          List<String> perks = const []}) =>
      towerStart(
          seed: seed,
          raceId: 'human',
          professionId: profession,
          rules: rules,
          heat: heat,
          perks: perks,
          data: data);
  TowerRun won(TowerRun run) =>
      towerAfterFight(run, data, won: true, healthLeft: run.health);

  /// What the player sees a card to be: a skill (a rank-up raises the skill
  /// it names), a die, a spell, an oath, a loot card.
  String gift(TowerReward c) => switch (c.kind) {
        TowerRewardKind.skill || TowerRewardKind.rankUp => 'skill:${c.id}',
        TowerRewardKind.die => 'die:${c.id}',
        TowerRewardKind.spell => 'spell:${c.id}',
        TowerRewardKind.clanOath => 'oath:${c.id}',
        _ => '${c.kind.name}:${c.id}:${c.amount}',
      };

  /// Every table a rules-2 climb of [seed] deals, as the bot plays it.
  List<(TowerTableKind?, List<TowerReward>)> tablesOf(int seed,
      {TowerProgress progress = const TowerProgress(),
      List<String> perks = const [],
      int heat = 0,
      int rules = 2}) {
    final seen = <(TowerTableKind?, List<TowerReward>)>[];
    playTowerRun(
      seed: seed,
      data: data,
      progress: progress,
      perks: perks,
      heat: heat,
      events: towerEventsLive,
      rules: rules,
      choice: (run) {
        seen.add((run.table, run.offer));
        if (run.table == TowerTableKind.loot) {
          return towerBotLootChoice(run, towerHeroOf(run, data), data);
        }
        return towerBotChoice(run, clans: data.clans);
      },
    );
    return seen;
  }

  group('Level Up', () {
    test('a table is three distinct cards: a clan, a skill, a die or spell',
        () {
      var tables = 0, shaped = 0;
      for (var seed = 1; seed <= 12; seed++) {
        for (final (kind, offer)
            in tablesOf(seed, progress: towerAllUnlocked)) {
          if (kind != TowerTableKind.levelUp) continue;
          final cards = [
            for (final c in offer)
              if (c.kind != TowerRewardKind.clanOath) c,
          ];
          tables++;
          expect(cards, hasLength(3), reason: 'seed $seed: $offer');
          expect({for (final c in cards) gift(c)}, hasLength(3),
              reason: 'seed $seed: $offer');
          // The oaths, when due, in front.
          final oaths =
              offer.takeWhile((c) => c.kind == TowerRewardKind.clanOath);
          expect(oaths.length,
              offer.where((c) => c.kind == TowerRewardKind.clanOath).length);
          if (cards[0].clan.isNotEmpty &&
              cards.skip(1).every((c) => c.clan.isEmpty) &&
              (cards[1].kind == TowerRewardKind.skill ||
                  cards[1].kind == TowerRewardKind.rankUp) &&
              (cards[2].kind == TowerRewardKind.die ||
                  cards[2].kind == TowerRewardKind.spell)) {
            shaped++;
          }
        }
      }
      expect(tables, greaterThan(60));
      // A short slot is filled (a skill, a die, a spell): the shape holds
      // on nearly every table.
      expect(shaped / tables, greaterThan(.85), reason: '$shaped of $tables');
    });

    test('Tower XP: 2 a floor, 3 an Elite, 4 a warden or boss; 4 a level', () {
      final floors = towerFloorsFor(3, data.enemies, rules: 2);
      for (final f in floors) {
        expect(
            towerXpFor(f),
            switch (f.kind) {
              TowerFloorKind.warden || TowerFloorKind.boss => 4,
              _ => f.elite || f.elitePack ? 3 : 2,
            });
      }
      expect(towerXpStart, 2);
      expect(towerXpPerLevel, 4);
      expect(towerXpLevelOf(towerXpStart, rules: 2), 1);
      // Floors 1 to 29 with no Elite: today's 17 Level Ups.
      const plain = towerXpStart + 24 * towerXpFight + 5 * towerXpWarden;
      expect(towerXpLevelOf(plain, rules: 2) - 1, 17);
      // The first floor won is the first level.
      var run = won(start(5));
      expect(run.xp,
          {1: towerXpFor(towerFloorsFor(5, data.enemies, rules: 2).first)});
      expect(towerHeroOf(run, data).level,
          towerXpLevelOf(towerXpOf(run), rules: 2));
      expect(towerLevelUpsPending(run),
          towerXpLevelOf(towerXpOf(run), rules: 2) - 1);
      // A rules-2 climb never owes a stat pick.
      expect(towerPendingPicks(run), 0);
      // The loot first, then the Level Up.
      expect(run.table, TowerTableKind.loot);
      run = towerPick(run, data, 0);
      expect(run.table, TowerTableKind.levelUp);
      run = towerPick(run, data, 0);
      expect(towerLevelUpsTaken(run), 1);
      expect(run.status, TowerStatus.climbing);
      expect(run.floor, 2);
    });

    test('a climb to the top gets about today\'s 17 Level Ups', () {
      for (var seed = 1; seed <= 40; seed++) {
        final run = playTowerRun(
            seed: seed,
            data: data,
            progress: towerAllUnlocked,
            events: towerEventsLive,
            rules: 2);
        if (run.status != TowerStatus.won) continue;
        expect(towerLevelUpsTaken(run), inInclusiveRange(17, 20),
            reason: 'seed $seed');
        expect(run.statPicks, isEmpty);
        expect(run.spoils, isEmpty, reason: 'no spoils chest on rules 2');
      }
    });
  });

  group('stat nudges', () {
    test('a skill nudges its stat by the first rule that matches', () {
      String of(Map<String, dynamic> s, [String p = 'rogue']) =>
          towerNudgeStatOf(s, p);
      expect(of({'healAmount': 3, 'damageMultiplier': 1.0}), 'constitution');
      expect(of({'blockAmount': 2, 'element': 'Light'}), 'wisdom');
      expect(of({'cleanse': 'All', 'element': 'Water'}), 'wisdom');
      // A heal that hits harder than ×1.0 is not a support skill.
      expect(of({'healAmount': 3, 'damageMultiplier': 1.4, 'element': 'Fire'}),
          'intelligence');
      expect(of({'inflictsStatus': 'Weaken', 'restrictedProfessionID': 'mage'}),
          'perception');
      expect(of({'restrictedProfessionID': 'warrior', 'element': 'Fire'}),
          'strength');
      expect(of({'restrictedProfessionID': 'cleric'}), 'intelligence');
      for (final e in ['Fire', 'Electricity', 'Void', 'Ice', 'Water']) {
        expect(of({'element': e}), 'intelligence', reason: e);
      }
      expect(of({'element': 'Wind'}), 'dexterity');
      expect(of({'element': 'Earth', 'inflictsStatus': 'Poison'}), 'strength');
      expect(of({'element': 'Light'}), 'wisdom');
      expect(of({'element': 'None', 'inflictsStatus': 'Poison'}), 'dexterity');
      expect(of({'element': 'None', 'inflictsStatus': 'Stun'}), 'strength');
      expect(of({'element': 'None'}, 'mage'), 'intelligence');
      expect(of({'element': 'None'}, 'ranger'), 'dexterity');
      // Every skill of the game maps to a stat.
      const stats = {
        'strength',
        'dexterity',
        'constitution',
        'intelligence',
        'wisdom',
        'perception',
      };
      for (final MapEntry(:key, :value) in data.skills.entries) {
        expect(stats, contains(of(value as Map<String, dynamic>)), reason: key);
      }
    });

    test('+1 a skill or rank-up, at most +4 a stat and +10 a climb', () {
      final hero = towerFreshHero('human', 'mage', const [], data);
      final fire = [
        for (final MapEntry(:key, :value) in data.skills.entries)
          if (towerNudgeStatOf(value as Map<String, dynamic>, 'mage') ==
              'intelligence')
            key,
      ];
      final int0 = hero.intelligence;
      for (final id in fire.take(8)) {
        towerNudgeOn(hero, TowerReward(TowerRewardKind.skill, id: id), data,
            rules: 2);
      }
      expect(hero.intelligence - int0, towerNudgeStatCap);
      // Neither a die, a spell nor an oath nudges.
      final before = {...hero.pickedPoints};
      towerNudgeOn(hero, const TowerReward(TowerRewardKind.die, id: 'x'), data,
          rules: 2);
      towerNudgeOn(
          hero, const TowerReward(TowerRewardKind.clanOath, id: 'mire'), data,
          rules: 2);
      expect(hero.pickedPoints, before);
      // Every skill of the game, twice: the climb's cap.
      for (final id in [...data.skills.keys, ...data.skills.keys]) {
        towerNudgeOn(hero, TowerReward(TowerRewardKind.rankUp, id: id), data,
            rules: 2);
      }
      expect(hero.pickedPoints.values.fold<int>(0, (n, p) => n + p),
          towerNudgeClimbCap);
      for (final p in hero.pickedPoints.values) {
        expect(p, lessThanOrEqualTo(towerNudgeStatCap));
      }
    });

    test('the bot\'s climbs keep the caps, replayed the same', () {
      for (var seed = 1; seed <= 10; seed++) {
        final run = playTowerRun(
            seed: seed, data: data, events: towerEventsLive, rules: 2);
        final hero = towerHeroOf(run, data);
        final total = hero.pickedPoints.values.fold<int>(0, (n, p) => n + p);
        expect(total, lessThanOrEqualTo(towerNudgeClimbCap));
        final again = towerHeroOf(
            TowerRun.fromJson(
                jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>),
            data);
        expect(again.pickedPoints, hero.pickedPoints);
        expect(again.strength, hero.strength);
        expect(again.intelligence, hero.intelligence);
        expect(again.maxHealth, hero.maxHealth);
      }
    });
  });

  group('loot', () {
    test('three distinct cards, a weighted mix, one purse at most', () {
      final items = data.items;
      var twoGear = 0, twoBundles = 0, tables = 0;
      final kinds = <TowerRewardKind, int>{};
      for (var seed = 1; seed <= 40; seed++) {
        final floors = towerFloorsFor(seed, data.enemies, rules: 2);
        for (final floor in floors.take(29)) {
          final cards = towerLootFor(seed: seed, floor: floor, items: items);
          tables++;
          expect(cards, hasLength(towerLootCards), reason: '$seed/$floor');
          expect({for (final c in cards) gift(c)}, hasLength(3),
              reason: '$seed ${floor.floor}: $cards');
          final count = <TowerRewardKind, int>{};
          for (final c in cards) {
            count[c.kind] = (count[c.kind] ?? 0) + 1;
            kinds[c.kind] = (kinds[c.kind] ?? 0) + 1;
            expect(
                c.kind,
                isIn(const [
                  TowerRewardKind.gear,
                  TowerRewardKind.bundle,
                  TowerRewardKind.purse,
                ]));
            if (c.kind == TowerRewardKind.gear) {
              expect((items[c.id] as Map)['isEquippable'], isTrue);
            }
            if (c.kind == TowerRewardKind.purse) {
              expect(c.amount, greaterThan(0));
            }
          }
          expect(count[TowerRewardKind.purse] ?? 0, lessThanOrEqualTo(1));
          if ((count[TowerRewardKind.gear] ?? 0) >= 2) twoGear++;
          if ((count[TowerRewardKind.bundle] ?? 0) >= 2) twoBundles++;
        }
      }
      // A mix: sometimes two pieces of gear, sometimes two bundles, gear the
      // most drawn.
      expect(twoGear, greaterThan(tables ~/ 20));
      expect(twoBundles, greaterThan(tables ~/ 40));
      expect(kinds[TowerRewardKind.gear],
          greaterThan(kinds[TowerRewardKind.purse]!));
    });

    test('the same floor deals the same table; gear owned is never dealt', () {
      final floor = towerFloorsFor(9, data.enemies, rules: 2)[11];
      final a = towerLootFor(seed: 9, floor: floor, items: data.items);
      final b = towerLootFor(seed: 9, floor: floor, items: data.items);
      expect(a, b);
      final owned = [
        for (final c in a)
          if (c.kind == TowerRewardKind.gear) c.id,
      ];
      for (var i = 0; i < 20; i++) {
        final c = towerLootFor(
            seed: 9,
            floor: floor,
            items: data.items,
            ownedItemIds: owned,
            random: Random(i));
        for (final card in c) {
          expect(owned, isNot(contains(card.id)));
        }
      }
    });

    test('the band raises the tier; bundles and purses grow with it', () {
      expect(towerLootTierShift, [0, 1, 2]);
      expect(towerBundleOf(towerBundleId(3, 1)), (potions: 3, antidotes: 1));
      for (var t = 1; t < towerLootPurse.length; t++) {
        expect(towerLootPurse[t], greaterThanOrEqualTo(towerLootPurse[t - 1]));
      }
    });

    test('a loot card taken: gear owned, potions in the bag, coins in hand',
        () {
      final run = won(start(11));
      expect(run.table, TowerTableKind.loot);
      for (var i = 0; i < run.offer.length; i++) {
        final card = run.offer[i];
        final next = towerPick(run, data, i);
        expect(next.loot[run.floor], card);
        switch (card.kind) {
          case TowerRewardKind.gear:
            expect(towerHeroOf(next, data).ownedItemIds, contains(card.id));
          case TowerRewardKind.bundle:
            final b = towerBundleOf(card.id);
            expect(
                next.potions, min(run.potions + b.potions, towerBagCapOf(run)));
            expect(next.antidotes, run.antidotes + b.antidotes);
          case TowerRewardKind.purse:
            expect(next.coins, run.coins + card.amount);
            expect(next.coinsEarned, run.coinsEarned + card.amount);
          default:
            fail('not a loot card: $card');
        }
      }
      // Left: a mark, and the Level Up still comes.
      final left = towerPick(run, data, null);
      expect(left.refused, contains(run.floor));
      expect(left.table, TowerTableKind.levelUp);
    });

    test('Pyre: floors 13 and 23 deal no loot table, their Level Ups still',
        () {
      for (final floor in towerHeatCutBoons) {
        final run = start(4, heat: towerHeatPyre).copyWith(
            floor: floor,
            crest: floor - 1,
            xp: {for (var f = 1; f < floor; f++) f: 2});
        final after = won(run);
        expect(after.table, isNot(TowerTableKind.loot), reason: 'floor $floor');
        expect(after.table, TowerTableKind.levelUp, reason: 'floor $floor');
      }
      // The bot's Pyre climbs: never a loot card on 13 or 23.
      for (var seed = 1; seed <= 6; seed++) {
        final run = playTowerRun(
            seed: seed,
            data: data,
            progress: towerAllUnlocked,
            heat: towerHeatPyre,
            events: towerEventsLive,
            rules: 2);
        for (final floor in towerHeatCutBoons) {
          expect(run.loot[floor], isNull, reason: 'seed $seed floor $floor');
        }
      }
    });
  });

  group('the oath', () {
    // [run] on floor [floor] with [clan]'s gifts taken below it up to the
    // oath's step (three gifts of +2), the Level Ups below it all dealt.
    TowerRun due(TowerRun run, String clan, {int floor = 4}) => run.copyWith(
          floor: floor,
          crest: floor - 1,
          xp: {for (var f = 1; f < floor; f++) f: 2},
          levelUps: {
            1: [
              for (var l = 1;
                  l < towerXpLevelOf(towerXpStart + 2 * (floor - 1), rules: 2);
                  l++)
                null,
            ],
          },
          taken: {
            for (var f = floor - 3; f < floor; f++)
              f: TowerReward(TowerRewardKind.skill, id: 'gift$f', clan: clan),
          },
        );

    test('the flag keeps today\'s oath: alone, or in front of a Level Up', () {
      expect(towerOathInLevelUp, isFalse);
      // Floor 4 won: 2 XP more, no level (10 XP, level 3, both dealt):
      // after the loot, the oath alone.
      var run = won(due(start(4), 'mire'));
      expect(run.table, TowerTableKind.loot);
      run = towerPick(run, data, 0);
      expect(run.table, TowerTableKind.oath);
      expect(
          run.offer, [const TowerReward(TowerRewardKind.clanOath, id: 'mire')]);
      // Refused: a mark, on to the next floor.
      final refused = towerPick(run, data, null);
      expect(refused.refused, contains(4));
      expect(refused.status, TowerStatus.climbing);
      // Sworn: its die, one a run.
      final sworn = towerPick(run, data, 0);
      expect(sworn.clanIds, ['mire']);
      // Floor 5 (a warden, 4 XP): a level; the oath in front of it.
      var five = won(due(start(4), 'mire', floor: 5));
      five = towerPick(five, data, 0);
      expect(five.table, TowerTableKind.levelUp);
      expect(five.offer.first,
          const TowerReward(TowerRewardKind.clanOath, id: 'mire'));
      // Sworn there: the level's card is gone with it.
      final took = towerPick(five, data, 0);
      expect(took.clanIds, ['mire']);
      expect(took.levelUps[5], [null]);
      expect(took.status, TowerStatus.climbing);
    });

    test(
        'rules 3: the oath is its own step, after the loot, before the '
        'Level Ups, and never costs a level', () {
      expect(towerOathOwnStepOf(3), isTrue);
      expect(towerOathOwnStepOf(2), isFalse);
      // Floor 4 won on rules 3 with the oath due and a level earned there
      // (4 XP below, 2 more: the first level costs 5).
      TowerRun at(int seed) => start(seed, rules: 3).copyWith(
            floor: 4,
            crest: 3,
            xp: {1: 2, 2: 2},
            taken: {
              for (var f = 1; f < 4; f++)
                f: TowerReward(TowerRewardKind.skill,
                    id: 'gift$f', clan: 'mire'),
            },
          );
      var checked = 0;
      for (var seed = 1; seed <= 6; seed++) {
        var run = won(at(seed));
        if (towerLevelUpsPending(run) < 1) continue;
        expect(run.table, TowerTableKind.loot, reason: 'seed $seed');
        run = towerPick(run, data, 0);
        // The oath alone, its own step.
        expect(run.table, TowerTableKind.oath, reason: 'seed $seed');
        expect(run.offer,
            [const TowerReward(TowerRewardKind.clanOath, id: 'mire')]);
        for (final swear in [true, false]) {
          final after = towerPick(run, data, swear ? 0 : null);
          if (swear) {
            expect(after.clanIds, ['mire']);
          } else {
            // Not now: a mark, as today.
            expect(after.refused, contains(4));
          }
          // Then the Level Up, whole, with no oath on it.
          expect(after.table, TowerTableKind.levelUp, reason: 'seed $seed');
          expect(after.offer.where((c) => c.kind == TowerRewardKind.clanOath),
              isEmpty);
          expect(after.offer.length, greaterThanOrEqualTo(3));
          final took = towerPick(after, data, 0);
          expect(took.levelUps[4], [after.offer[0]]);
          expect(took.status, TowerStatus.climbing);
        }
        checked++;
      }
      expect(checked, greaterThan(0));
    });

    test('rules 3: no Level Up table carries an oath over whole climbs', () {
      for (var seed = 1; seed <= 40; seed++) {
        for (final (kind, offer)
            in tablesOf(seed, rules: 3, progress: towerAllUnlocked)) {
          if (kind == TowerTableKind.levelUp) {
            expect(
                offer.where((c) => c.kind == TowerRewardKind.clanOath), isEmpty,
                reason: 'seed $seed: $offer');
          }
        }
      }
    });

    test('the late oath from floor 15, as today', () {
      var run = start(8).copyWith(floor: 16, crest: 15, xp: {
        for (var f = 1; f <= 15; f++) f: 2
      }, levelUps: {
        1: [
          for (var l = 1; l < towerXpLevelOf(towerXpStart + 30, rules: 2); l++)
            null
        ],
      });
      run = towerPick(won(run), data, 0);
      final oaths = run.offer.where((c) => c.kind == TowerRewardKind.clanOath);
      expect(oaths, hasLength(1), reason: '${run.table} ${run.offer}');
    });
  });

  group('perks', () {
    test('Fourth card: the first two Level Up tables show a fourth card', () {
      for (var seed = 1; seed <= 4; seed++) {
        final ups = [
          for (final (kind, offer)
              in tablesOf(seed, perks: const [towerPerkFourthCard]))
            if (kind == TowerTableKind.levelUp)
              [
                for (final c in offer)
                  if (c.kind != TowerRewardKind.clanOath) c,
              ],
        ];
        expect(ups.length, greaterThan(2), reason: 'seed $seed');
        expect(ups[0], hasLength(4), reason: 'seed $seed');
        expect(ups[1], hasLength(4), reason: 'seed $seed');
        expect(ups[2], hasLength(3), reason: 'seed $seed');
        for (final table in ups.take(2)) {
          expect({for (final c in table) gift(c)}, hasLength(4));
        }
      }
    });

    test('Keen eye: the first Level Up table\'s skills one rarity up', () {
      int rarity(TowerReward c) => const ['common', 'uncommon', 'rare', 'epic']
          .indexOf('${(data.skills[c.id] as Map)['rarity']}');
      var plain = 0, keen = 0;
      for (var seed = 1; seed <= 30; seed++) {
        TowerRun first(List<String> perks) =>
            towerPick(won(start(seed, perks: perks)), data, 0);
        for (final (perks, add) in [
          (const <String>[], (int r) => plain += r),
          (const [towerPerkKeenEye], (int r) => keen += r),
        ]) {
          final run = first(perks);
          expect(run.table, TowerTableKind.levelUp);
          for (final c in run.offer) {
            if (c.kind == TowerRewardKind.skill && c.clan.isEmpty) {
              add(rarity(c));
            }
          }
        }
      }
      expect(keen, greaterThan(plain));
    });

    test('Free hand: the first reroll free, on a Level Up table too', () {
      var run = won(start(6, perks: const [towerPerkFreeHand]));
      run = towerPick(run, data, 0);
      expect(run.table, TowerTableKind.levelUp);
      expect(towerCanReroll(run), isTrue);
      expect(towerRerollPriceOf(run), 0);
      final rerolled = towerReroll(run, data);
      expect(rerolled.rerolls[run.floor], 1);
      expect(rerolled.coins, run.coins);
      expect(rerolled.table, TowerTableKind.levelUp);
      final cards = [
        for (final c in rerolled.offer)
          if (c.kind != TowerRewardKind.clanOath) c,
      ];
      expect(cards, hasLength(3));
      expect({for (final c in cards) gift(c)}, hasLength(3));
      expect(towerRerollPriceOf(rerolled), towerRerollPrice + towerRerollStep);
    });

    test('a loot table rerolled is three distinct loot cards', () {
      final run = won(start(7, perks: const [towerPerkFreeHand]));
      final rerolled = towerReroll(run, data);
      expect(rerolled.table, TowerTableKind.loot);
      expect(rerolled.offer, hasLength(3));
      expect({for (final c in rerolled.offer) gift(c)}, hasLength(3));
    });

    test('a stall\'s boon on rules 2: a Level Up table with no clan', () {
      final run = start(3);
      final hero = towerHeroOf(run, data);
      final boon = towerStallBoonFor(run, data, 4, hero);
      expect(boon, hasLength(3));
      expect(boon.every((c) => c.clan.isEmpty), isTrue);
      expect({for (final c in boon) gift(c)}, hasLength(3));
    });
  });

  group('TowerRun.rules', () {
    test('a save without it is rules 1, and plays as before', () {
      final old = start(12, rules: 1);
      expect(old.rules, 1);
      final json = old.toJson();
      expect(json.containsKey('rules'), isFalse);
      final back = TowerRun.fromJson(
          jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(back.rules, 1);
      // Rules 1: the spoils chest, the stat pick, the clans' table.
      final after = won(back);
      expect(after.spoils[1], isNotNull);
      expect(after.table, isNull);
      expect(towerPendingPicks(after), greaterThan(0));
      expect(after.offer.every((c) => c.clan.isNotEmpty), isTrue);
      // The same climb, played whole, on rules 1 by default.
      final played =
          playTowerRun(seed: 12, data: data, events: towerEventsLive);
      expect(played.rules, 1);
      expect(played.loot, isEmpty);
      expect(played.xp, isEmpty);
    });

    test('a rules-2 climb saves and loads every field', () {
      final run = playTowerRun(
          seed: 21,
          data: data,
          progress: towerAllUnlocked,
          events: towerEventsLive,
          rules: 2,
          choice: (r) =>
              r.floor == 6 && r.table == TowerTableKind.levelUp ? null : 0);
      final mid = run.copyWith(status: TowerStatus.climbing);
      final back = TowerRun.fromJson(
          jsonDecode(jsonEncode(mid.toJson())) as Map<String, dynamic>);
      expect(back.rules, 2);
      expect(back.xp, mid.xp);
      expect(back.loot, mid.loot);
      expect(back.levelUps, mid.levelUps);
      expect(back.levelUps[6], contains(null), reason: 'refused on floor 6');
      // A table on screen comes back as it was.
      final choosing = won(start(2));
      final again = TowerRun.fromJson(
          jsonDecode(jsonEncode(choosing.toJson())) as Map<String, dynamic>);
      expect(again.table, choosing.table);
      expect(again.offer, choosing.offer);
    });

    test('the app starts new climbs on the live rules', () {
      // Rules 5 is live (tower_providers.dart starts new climbs on
      // towerRulesLive; rules 4's screens serve it, the early floors need
      // none).
      expect(towerRulesLive, 5);
      expect(towerRulesMax, 5);
      expect(start(1, rules: 9).rules, towerRulesMax);
    });

    test('rules 2 lowers the foes; rules 1 keeps them', () {
      final one = towerFloorsFor(5, data.enemies, rules: 1)[7];
      final two = towerFloorsFor(5, data.enemies, rules: 2)[7];
      expect(one.enemyIds, two.enemyIds);
      for (final p in ['warrior', 'mage', 'rogue', 'cleric', 'ranger']) {
        expect(two.extraFor(p) / one.extraFor(p),
            closeTo(towerRulesScaleOf(2, p), 1e-9));
      }
      expect(towerRulesScaleOf(1, 'cleric'), 1.0);
      // Rules 2 has no curve by floor.
      for (final f in [0, 1, 5, 10, 20, 30]) {
        expect(towerRulesScaleOf(2, 'warrior', floor: f),
            towerRulesScaleOf(2, 'warrior'));
      }
    });
  });

  // Rules 3, the survival curve (docs/simulation/tower-difficulty-survival.md):
  // rules 2's systems with slower levels, harder foes and more health an
  // unlock. Rules 2 keeps today's numbers (above).
  group('rules 3', () {
    test('Tower XP: none at the start, 5, 6, 6, 7, 7, 8 ... a level', () {
      expect(towerXpStartOf(2), towerXpStart);
      expect(towerXpStartOf(3), 0);
      for (var l = 1; l <= 20; l++) {
        expect(towerXpCostOf(l, rules: 2), 4);
      }
      expect([for (var l = 1; l <= 8; l++) towerXpCostOf(l, rules: 3)],
          [5, 6, 6, 7, 7, 8, 8, 9]);
      expect(towerXpLevelOf(4, rules: 3), 1);
      expect(towerXpLevelOf(5, rules: 3), 2);
      expect(towerXpLevelOf(10, rules: 3), 2);
      expect(towerXpLevelOf(11, rules: 3), 3);
      expect(towerXpLevelOf(-3, rules: 3), 1);
      // Floors 1 to 29 with no Elite: 9 Level Ups (rules 2: 17).
      const plain = 24 * towerXpFight + 5 * towerXpWarden;
      expect(towerXpLevelOf(towerXpStartOf(3) + plain, rules: 3) - 1, 9);
      expect(towerXpLevelOf(towerXpStartOf(2) + plain, rules: 2) - 1, 17);
    });

    test('the first Level Up after floor 3 (two plain floors pay none)', () {
      // A seed whose floors 1 to 3 are plain fights (2 XP each).
      final seed = [
        for (var s = 1; s <= 40; s++)
          if (towerFloorsFor(s, data.enemies, events: towerEventsLive, rules: 3)
              .take(3)
              .every((f) => towerXpFor(f) == towerXpFight))
            s,
      ].first;
      var run = towerStart(
          seed: seed,
          raceId: 'human',
          professionId: 'warrior',
          events: towerEventsLive,
          rules: 3,
          data: data);
      expect(run.rules, 3);
      for (var floor = 1; floor <= 2; floor++) {
        run = won(run);
        expect(run.table, TowerTableKind.loot, reason: 'floor $floor');
        expect(towerLevelUpsPending(run), 0, reason: 'floor $floor');
        run = towerPick(run, data, 0);
        expect(run.status, TowerStatus.climbing, reason: 'floor $floor');
        expect(run.floor, floor + 1);
      }
      run = towerPick(won(run), data, 0);
      expect(run.table, TowerTableKind.levelUp);
      expect(towerHeroOf(run, data).level, 2);
      // The bot's climbs: never a Level Up on floor 1, never two by floor 3.
      for (var s = 1; s <= 30; s++) {
        final climb = playTowerRun(
            seed: s,
            data: data,
            progress: towerAllUnlocked,
            events: towerEventsLive,
            rules: 3);
        expect(climb.levelUps[1], isNull, reason: 'seed $s');
        final byThree = [
          for (var f = 1; f <= 3; f++) ...?climb.levelUps[f],
        ];
        expect(byThree.length, lessThanOrEqualTo(1), reason: 'seed $s');
      }
    });

    test('a climb to the top gets about 9 Level Ups', () {
      var wins = 0;
      for (var seed = 1; seed <= 60; seed++) {
        final run = playTowerRun(
            seed: seed,
            data: data,
            progress: towerAllUnlocked,
            events: towerEventsLive,
            rules: 3);
        expect(run.rules, 3);
        if (run.status != TowerStatus.won) continue;
        wins++;
        expect(towerLevelUpsTaken(run), inInclusiveRange(8, 11),
            reason: 'seed $seed');
      }
      expect(wins, greaterThan(0));
    });

    test('the nudges: at most +3 a stat and +6 a climb (rules 2: 4 and 10)',
        () {
      expect(towerNudgeStatCapOf(2), 4);
      expect(towerNudgeClimbCapOf(2), 10);
      expect(towerNudgeStatCapOf(3), 3);
      expect(towerNudgeClimbCapOf(3), 6);
      final hero = towerFreshHero('human', 'mage', const [], data);
      final int0 = hero.intelligence;
      final fire = [
        for (final MapEntry(:key, :value) in data.skills.entries)
          if (towerNudgeStatOf(value as Map<String, dynamic>, 'mage') ==
              'intelligence')
            key,
      ];
      for (final id in fire.take(8)) {
        towerNudgeOn(hero, TowerReward(TowerRewardKind.skill, id: id), data,
            rules: 3);
      }
      expect(hero.intelligence - int0, 3);
      for (final id in [...data.skills.keys, ...data.skills.keys]) {
        towerNudgeOn(hero, TowerReward(TowerRewardKind.rankUp, id: id), data,
            rules: 3);
      }
      expect(hero.pickedPoints.values.fold<int>(0, (n, p) => n + p), 6);
      for (final p in hero.pickedPoints.values) {
        expect(p, lessThanOrEqualTo(3));
      }
    });

    test('the band raises the tier 0 / 0 / +1 (rules 2: 0 / +1 / +2)', () {
      expect(towerLootTierShiftOf(2), [0, 1, 2]);
      expect(towerLootTierShiftOf(3), [0, 0, 1]);
      final two = towerFloorsFor(9, data.enemies, rules: 2);
      final three = towerFloorsFor(9, data.enemies, rules: 3);
      for (final i in [4, 14, 24]) {
        final band = towerLootBandOf(i + 1);
        expect(towerLootContextOf(two[i]).tierShift, [0, 1, 2][band]);
        expect(towerLootContextOf(three[i]).tierShift, [0, 0, 1][band]);
      }
    });

    test('10% health back after a floor won (rules 2: 15%); Heat 3 5%', () {
      expect(towerRecoveryShareFor(0, rules: 2), .15);
      expect(towerRecoveryShareFor(0, rules: 3), .10);
      expect(towerRecoveryShareFor(2, rules: 3), .10);
      expect(towerRecoveryShareFor(3, rules: 3), towerHeatRecoveryShare);
      expect(towerRecoveryShareFor(3, rules: 2), towerHeatRecoveryShare);
      expect(towerRecoveryShareFor(1, rules: 1), towerRecoveryShareOf(1));
    });

    test('the foes: the survival curve by floor and the calling pass', () {
      expect(towerSurvivalScale, hasLength(towerTop));
      final one = towerFloorsFor(5, data.enemies, rules: 1);
      final three = towerFloorsFor(5, data.enemies, rules: 3);
      for (final i in [0, 2, 7, 9, 19, 29]) {
        expect(three[i].enemyIds, one[i].enemyIds);
        for (final p in ['warrior', 'mage', 'rogue', 'cleric', 'ranger']) {
          final upper = i + 1 >= towerSurvivalUpperFloor
              ? towerSurvivalProfessionUpperScale[p] ?? 1.0
              : 1.0;
          final scale = towerLootFoeScale *
              (towerSurvivalProfessionScale[p] ?? 1.0) *
              upper *
              towerSurvivalScale[i];
          expect(towerRulesScaleOf(3, p, floor: i + 1), closeTo(scale, 1e-12));
          expect(
              three[i].extraFor(p) / one[i].extraFor(p), closeTo(scale, 1e-9),
              reason: 'floor ${i + 1} $p');
        }
      }
      expect(towerSurvivalScale.first, 3.0);
      expect(towerSurvivalScale.last, 1.75);
      // No floor: the calling pass only.
      expect(towerRulesScaleOf(3, 'rogue'), closeTo(.85 * .93, 1e-12));
    });

    test('an unlock gives 5.33 times the health, by the calling', () {
      for (final p in ['warrior', 'mage', 'rogue', 'cleric', 'ranger']) {
        for (final r in ['human', 'dwarf', 'elf']) {
          expect(towerHealthPerUnlockFor(r, p, rules: 1),
              towerHealthPerUnlockOf(r));
          expect(towerHealthPerUnlockFor(r, p, rules: 2),
              towerHealthPerUnlockOf(r));
          expect(
              towerHealthPerUnlockFor(r, p, rules: 3),
              closeTo(
                  towerHealthPerUnlockOf(r) *
                      5.33 *
                      (towerSurvivalProfessionHealthPerUnlock[p] ?? 1.0),
                  1e-12));
        }
      }
      final bare = towerFreshHero('human', 'mage', const [], data);
      final two = towerFreshHero('human', 'mage', const [], data,
          unlocksOwned: 10, rules: 2);
      final three = towerFreshHero('human', 'mage', const [], data,
          unlocksOwned: 10, rules: 3);
      expect(
          two.maxHealth,
          (bare.maxHealth * (1 + towerHealthPerUnlockOf('human') * 10))
              .round());
      expect(
          three.maxHealth,
          (bare.maxHealth *
                  (1 + towerHealthPerUnlockFor('human', 'mage', rules: 3) * 10))
              .round());
      expect(three.maxHealth, greaterThan(two.maxHealth));
    });
  });
}
