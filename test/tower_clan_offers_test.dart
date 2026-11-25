// The clans' offers in the Tower (docs/simulation/tower-clan-offers.md, the
// user's calls): on the oath's floors up to three clans each offer a skill
// gift; a gift taken gives its clan +2, its allies +1 and takes 1 from its
// rivals, standing 0 to 6 replayed from the cards taken; at 6 the clan's
// oath is dealt, a card of its own, on the next floor won that is not a
// boon's; one oath a run; fights move nothing; an old save loads and plays.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_clans.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  final data = towerDataFromAssets();
  TowerRun start(int seed, {List<String>? pool, String profession = 'rogue'}) =>
      towerStart(
          seed: seed,
          raceId: 'human',
          professionId: profession,
          clanPool: pool ?? towerStartClanPool,
          data: data);
  TowerRun won(TowerRun run) =>
      towerAfterFight(run, data, won: true, healthLeft: run.health);
  TowerReward gift(String clan, [String id = 'x']) =>
      TowerReward(TowerRewardKind.skill, id: id, clan: clan);

  group('standing', () {
    test('the ripple follows relations.json: +2, allies +1, rivals -1', () {
      expect(towerClanRipple('dominion', data.clans), {
        'dominion': 2,
        'vigil': -1,
        'mire': -1,
        'crows': 1,
        'penitents': -1
      });
      expect(towerClanRipple('vigil', data.clans), {
        'vigil': 2,
        'dominion': -1,
        'compact': 1,
        'crows': -1,
        'penitents': 1
      });
      expect(towerClanRipple('compact', data.clans),
          {'compact': 2, 'vigil': 1, 'mire': 1, 'penitents': -1});
      // No relations read: the clan alone.
      expect(towerClanRipple('mire', const TowerClanTables()), {'mire': 2});
    });

    test('summed card by card, clamped to 0..6 after each', () {
      final s = towerStandingFrom([
        gift('mire'), // mire 2, dominion 0 (clamped), penitents 0
        gift('dominion'), // dominion 2, mire 1, crows 1
        gift('mire'), // mire 3, dominion 1, compact 1
        const TowerReward(TowerRewardKind.skill, id: 'y'), // no clan
        const TowerReward(TowerRewardKind.clanOath, id: 'vigil'),
        gift('mire'), gift('mire'), gift('mire'), gift('mire'),
      ], data.clans);
      expect(s['mire'], towerOathStep, reason: 'clamped at the top');
      expect(s['dominion'], 0, reason: 'clamped at 0');
      expect(s['compact'], towerOathStep, reason: 'an ally of the Mire');
      expect(s['crows'], 1);
      expect(s['vigil'], 0, reason: 'an oath card moves nothing');
    });

    test('rebuilt from TowerRun.taken in floor order, over the pool', () {
      final run = start(3).copyWith(floor: 9, taken: {
        6: gift('penitents'),
        2: gift('mire'),
        4: gift('mire'),
      });
      // Floor order: mire, mire, penitents (rivals of each other).
      expect(towerStandingOf(run, data),
          {'dominion': 0, 'mire': 3, 'penitents': 2});
      // The save holds the clan, not the standing.
      final again = TowerRun.fromJson(
          jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
      expect(again.taken[2], gift('mire'));
      expect(towerStandingOf(again, data), towerStandingOf(run, data));
      expect(run.toJson().toString(), isNot(contains('standing')));
    });

    test('the depth of a gift follows standing: 0-1, 2-3, 4-5, 6', () {
      expect([for (var s = 0; s <= 6; s++) towerGiftDepthFor(s)],
          [0, 0, 1, 1, 2, 2, 3]);
    });

    test('a fight moves no standing', () {
      var run = won(start(5));
      final before = towerStandingOf(run, data);
      run = towerPick(run, data, null);
      expect(towerStandingOf(run, data), before);
      run = won(run);
      expect(towerStandingOf(run, data), before);
    });
  });

  group('offers', () {
    test('the first floor won deals up to three clans, each a gift', () {
      for (var seed = 1; seed <= 20; seed++) {
        final first = won(start(seed));
        expect(first.offer, isNotEmpty, reason: 'seed $seed');
        expect(first.offer.length, lessThanOrEqualTo(towerSuitorsPerOffer));
        final clans = [for (final r in first.offer) r.clan];
        expect(clans.toSet(), hasLength(clans.length), reason: 'one a clan');
        for (final r in first.offer) {
          expect(towerStartClanPool, contains(r.clan));
          expect(r.kind, anyOf(TowerRewardKind.skill, TowerRewardKind.rankUp));
          expect(data.skills[r.id], isNotNull);
        }
        // No oath yet: no clan stands at 6.
        expect(first.offer.where((r) => r.kind == TowerRewardKind.clanOath),
            isEmpty);
      }
    });

    test('a sponsored branch gives its first skill at standing 0', () {
      // The rogue's Venom branch is the Mire's (factions.json sponsors).
      final run = won(start(1, pool: const ['mire']));
      final card = run.offer.single;
      expect(card.clan, 'mire');
      final tree = data.clans.skillTrees['rogue_venom'] as Map;
      final first = (tree['skillIds'] as List).first.toString();
      // Its first skill, or a rank-up when it would sit on no face.
      if (card.kind == TowerRewardKind.skill) expect(card.id, first);
    });

    test('a clan with no branch for the hero gives a pool skill', () {
      // The Compact sponsors no rogue branch, nor the human heritage.
      final run = won(start(2, pool: const ['compact']));
      expect(run.offer.single.clan, 'compact');
      expect(data.skills[run.offer.single.id], isNotNull);
    });

    test('a gift taken moves standing, a mark refused moves none', () {
      final run = won(start(7));
      final card = run.offer.first;
      final taken = towerPick(run, data, 0);
      final ripple = towerClanRipple(card.clan, data.clans);
      final standing = towerStandingOf(taken, data);
      for (final clan in towerStartClanPool) {
        expect(standing[clan], (ripple[clan] ?? 0).clamp(0, towerOathStep));
      }
      expect(taken.taken[1]?.clan, card.clan);
      final refused = towerPick(run, data, null);
      expect(refused.refused, {1});
      expect(
          towerStandingOf(refused, data).values.every((s) => s == 0), isTrue);
      expect(refused.marksEarned, run.marksEarned + towerMarksPerRefusal);
    });

    test('boon floors deal the boon only, never a clan or an oath', () {
      final run = start(11).copyWith(
          floor: 5, taken: {1: gift('mire'), 2: gift('mire'), 3: gift('mire')});
      expect(towerOathDue(run, data), ['mire']);
      final boon = won(run);
      expect(boon.offer, isNotEmpty);
      expect(boon.offer.every((r) => r.clan.isEmpty), isTrue);
      expect(
          boon.offer.where((r) => r.kind == TowerRewardKind.clanOath), isEmpty);
      // The next floor won, not a boon's, deals the oath.
      final next = won(towerPick(boon, data, null));
      expect(next.offer.first,
          const TowerReward(TowerRewardKind.clanOath, id: 'mire'));
    });
  });

  group('the oath', () {
    TowerRun at(int standingGifts, {int floor = 7}) => start(13).copyWith(
        floor: floor,
        taken: {for (var f = 1; f <= standingGifts; f++) f: gift('mire')});

    test('dealt at 6 only, first, beside the gifts or alone', () {
      expect(towerOathDue(at(2), data), isEmpty, reason: 'standing 4');
      for (final floor in [6, 7, 8, 9, 11, 12]) {
        final run = won(at(3, floor: floor));
        expect(run.offer.first.kind, TowerRewardKind.clanOath,
            reason: 'floor $floor');
        expect(run.offer.first.id, 'mire');
        expect(run.offer.where((r) => r.kind == TowerRewardKind.clanOath),
            hasLength(1));
        expect(run.offer.length, lessThanOrEqualTo(towerSuitorsPerOffer + 1));
      }
      final five = won(at(2, floor: 7));
      expect(
          five.offer.where((r) => r.kind == TowerRewardKind.clanOath), isEmpty);
    });

    test('declined, it comes back on the next floor', () {
      var run = won(at(3, floor: 6));
      run = towerPick(run, data, null);
      run = won(run);
      expect(run.offer.first,
          const TowerReward(TowerRewardKind.clanOath, id: 'mire'));
    });

    test('sworn: its die, and no other oath this run', () {
      var run = won(at(3, floor: 6));
      run = towerPick(run, data, 0);
      expect(run.clanIds, ['mire']);
      if (towerClanDieOf('mire', data.dice) case final die?) {
        expect(towerHeroOf(run, data).ownedDice.keys, contains(die));
      }
      expect(run.oathsLeft, isEmpty);
      // Another clan brought to 6: no oath is dealt.
      run = run.copyWith(taken: {
        ...run.taken,
        for (var f = 20; f < 24; f++) f: gift('dominion'),
      });
      expect(towerStandingOf(run, data)['dominion'], towerOathStep);
      expect(towerOathDue(run, data), isEmpty);
      for (var f = 0; f < 6 && run.status == TowerStatus.climbing; f++) {
        run = won(run);
        expect(run.offer.where((r) => r.kind == TowerRewardKind.clanOath),
            isEmpty);
        run = towerPick(run, data, null);
      }
    });
  });

  group('the floor-15 oath (#1153)', () {
    Iterable<TowerReward> oathsOf(TowerRun run) =>
        run.offer.where((r) => r.kind == TowerRewardKind.clanOath);
    // Mire at 4, the others at 0: no oath due by standing.
    TowerRun unsworn(int floor, {int seed = 17, List<String>? pool}) =>
        start(seed, pool: pool)
            .copyWith(floor: floor, taken: {1: gift('mire'), 2: gift('mire')});

    test('below floor 15, standing under 6: no oath', () {
      for (var seed = 1; seed <= 20; seed++) {
        final run = unsworn(14, seed: seed);
        expect(towerOathDue(run, data), isEmpty);
        expect(oathsOf(won(run)), isEmpty, reason: 'seed $seed');
      }
    });

    test('from floor 15: the highest-standing clan, first, every floor', () {
      // Floor 15 is a boon floor: the boon only.
      expect(towerBoonFloors, contains(towerPityOathFloor));
      final boon = won(unsworn(15));
      expect(oathsOf(boon), isEmpty);
      expect(boon.offer.every((r) => r.clan.isEmpty), isTrue);
      for (var floor = towerPityOathFloor; floor < towerTop; floor++) {
        if (towerBoonFloors.contains(floor)) continue;
        for (var seed = 1; seed <= 5; seed++) {
          final run = won(unsworn(floor, seed: seed));
          expect(run.offer.first,
              const TowerReward(TowerRewardKind.clanOath, id: 'mire'),
              reason: 'floor $floor seed $seed');
          expect(oathsOf(run), hasLength(1));
        }
      }
      // Declined, it comes back on the next floor won.
      var run = towerPick(won(unsworn(16)), data, null);
      run = won(run);
      expect(run.offer.first,
          const TowerReward(TowerRewardKind.clanOath, id: 'mire'));
    });

    test('a sworn run is offered none', () {
      var run = won(unsworn(16));
      run = towerPick(run, data, 0);
      expect(run.clanIds, ['mire']);
      for (var f = 0; f < 6 && run.status == TowerStatus.climbing; f++) {
        run = won(run);
        expect(oathsOf(run), isEmpty);
        run = towerPick(run, data, null);
      }
    });

    test('a tie goes to the first clan of the run, stably', () {
      expect(towerPityOathClan(const [], const {}), isNull);
      expect(towerPityOathClan(['a', 'b', 'c'], const {}), 'a');
      expect(towerPityOathClan(['a', 'b', 'c'], {'b': 3, 'c': 3}), 'b');
      expect(towerPityOathClan(['c', 'b', 'a'], {'b': 3, 'c': 3}), 'c');
      // All at 0: the first of the run's pool (kept in towerClans' order,
      // whatever order it was given in), on every seed.
      for (final pool in [
        towerStartClanPool,
        towerStartClanPool.reversed.toList(),
      ]) {
        for (var seed = 1; seed <= 5; seed++) {
          final run = won(start(seed, pool: pool).copyWith(floor: 16));
          expect(
              run.offer.first,
              TowerReward(TowerRewardKind.clanOath,
                  id: towerStartClanPool.first),
              reason: 'seed $seed');
        }
      }
    });
  });

  group('old saves', () {
    test('a run halfway up, saved before: standing 0, it climbs on', () {
      final run = TowerRun.fromJson({
        'seed': 21,
        'race': 'elf',
        'profession': 'mage',
        'pool': ['dominion', 'mire', 'penitents'],
        'floor': 6,
        'health': 40,
        'status': 'climbing',
        'picks': [0, 0, 0, 0],
        'taken': {
          '1': {'kind': 'clanOath', 'id': 'mire'},
          '2': {'kind': 'skill', 'id': 'fireball'},
          '5': {'kind': 'die', 'id': 'flame_die'},
        },
      });
      expect(towerStandingOf(run, data).values.every((s) => s == 0), isTrue);
      expect(run.clanIds, ['mire'], reason: 'its oath stays sworn');
      expect(run.taken[2]?.clan, '');
      final played = playTowerRun(
          seed: 21, data: data, raceId: 'elf', professionId: 'mage');
      expect(played.isOver, isTrue);
      // It plays on from where it stands.
      var next = won(run);
      expect(next.status, TowerStatus.choosing);
      expect(
          next.offer.where((r) => r.kind == TowerRewardKind.clanOath), isEmpty,
          reason: 'one oath a run: it has one');
      next = towerPick(next, data, next.offer.isEmpty ? null : 0);
      expect(next.floor, 7);
    });

    test('an oath card on the table when saved stays and can be sworn', () {
      final run = TowerRun.fromJson({
        'seed': 22,
        'race': 'human',
        'profession': 'warrior',
        'floor': 1,
        'health': 40,
        'status': 'choosing',
        'picks': [],
        'offer': [
          {'kind': 'clanOath', 'id': 'penitents'},
        ],
      });
      expect(run.offer.single.kind, TowerRewardKind.clanOath);
      final sworn = towerPick(run, data, 0);
      expect(sworn.clanIds, ['penitents']);
    });

    test('a clan card saves its clan, a card with none saves none', () {
      expect(gift('crows', 'a').toJson(),
          {'kind': 'skill', 'id': 'a', 'clan': 'crows'});
      expect(const TowerReward(TowerRewardKind.skill, id: 'a').toJson(),
          {'kind': 'skill', 'id': 'a'});
      expect(TowerReward.fromJson(gift('crows', 'a').toJson()),
          gift('crows', 'a'));
    });
  });

  group('the bot', () {
    test('swears an oath on the table, else the clan it stands best with', () {
      final base = start(31).copyWith(
          status: TowerStatus.choosing,
          taken: {1: gift('mire'), 2: gift('dominion'), 3: gift('mire')});
      final pick = base.copyWith(offer: [
        gift('dominion', 'a'),
        gift('mire', 'b'),
        const TowerReward(TowerRewardKind.spell, id: 'c'),
      ]);
      expect(towerBotChoice(pick, clans: data.clans), 1);
      final oath = base.copyWith(offer: [
        gift('mire', 'b'),
        const TowerReward(TowerRewardKind.clanOath, id: 'mire'),
      ]);
      expect(towerBotChoice(oath, clans: data.clans), 1);
    });

    test('plays runs to their end, with no unlocks and with all', () {
      var gifts = 0, sworn = 0;
      for (var seed = 1; seed <= 12; seed++) {
        for (final progress in [const TowerProgress(), towerAllUnlocked]) {
          final run = playTowerRun(
              seed: seed,
              data: data,
              progress: progress,
              events: towerEventsLive);
          expect(run.isOver, isTrue, reason: 'seed $seed');
          expect(run.offer, isEmpty);
          expect(run.clanIds.length, lessThanOrEqualTo(1),
              reason: 'seed $seed: one oath a run');
          gifts += run.taken.values.where((r) => r.clan.isNotEmpty).length;
          if (run.clanIds.isNotEmpty) {
            sworn++;
            // Sworn only once its clan stood at the oath's step, or from
            // the floor-15 oath on, its highest-standing clan's.
            final f = run.taken.entries
                .firstWhere((e) => e.value.kind == TowerRewardKind.clanOath)
                .key;
            final before = towerStandingFrom([
              for (final k in run.taken.keys.toList()..sort())
                if (k < f) run.taken[k]!,
            ], data.clans);
            final pool = {for (final c in run.clanPool) c: before[c] ?? 0};
            if (f >= towerPityOathFloor &&
                !pool.values.any((v) => v >= towerOathStep)) {
              expect(run.clanIds.single, towerPityOathClan(run.clanPool, pool),
                  reason: 'seed $seed');
            } else {
              expect(before[run.clanIds.single], towerOathStep,
                  reason: 'seed $seed');
            }
          }
        }
      }
      expect(gifts, greaterThan(0));
      expect(sworn, greaterThan(0));
    });
  });
}
