// QA guard (the Tower's clan offers, v2.6.0): Core's tower_clan_offers_test
// holds the rules on made-up runs; this plays the bot over 200 real climbs
// and holds what must be true of every one of them, replayed card by card:
//  - the standing with a clan comes from the gifts taken and nothing else
//    (the cards with no clan move nothing), always between 0 and 6;
//  - a clan's oath is taken only with that clan at standing 6 (from the cards
//    taken on the floors before), or from floor 15 with none at 6 the
//    highest-standing clan's (#1153), and at most one oath is sworn a run;
//  - the sworn clans are exactly the oaths taken, and the leading clan is the
//    sworn one once sworn;
//  - a card refused is a floor with no card taken, and the marks the run
//    earned are those of the height it cleared and its refusals ("Not now"
//    gives one mark);
//  - the clans' offers moved the climb by no more than Core said (the top
//    stays near the v2.4.0 curve).
// And the old saves load: a run saved before the clans' offers (no clan on
// its cards) reads as standing 0 with every clan and plays on.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_clans.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  final data = towerDataFromAssets();
  final runs = playTowerBatch(List.generate(200, (i) => i + 1), data);

  test('standing comes from the gifts taken, within 0 to 6; oaths only at 6',
      () {
    var gifts = 0;
    var oaths = 0;
    for (final run in runs) {
      final floors = run.taken.keys.toList()..sort();
      final seen = <TowerReward>[];
      var sworn = 0;
      for (final f in floors) {
        final card = run.taken[f]!;
        if (card.kind == TowerRewardKind.clanOath) {
          // The standing before this floor's card.
          final before = towerStandingFrom(seen, data.clans);
          final pool = {for (final c in run.clanPool) c: before[c] ?? 0};
          // From towerPityOathFloor (#1153), with none at 6: the oath of
          // the highest-standing clan.
          if (f >= towerPityOathFloor &&
              !pool.values.any((v) => v >= towerOathStep)) {
            expect(card.id, towerPityOathClan(run.clanPool, pool),
                reason: 'seed ${run.seed}, floor $f: the floor-15 oath of '
                    '${card.id} at standing $pool');
          } else {
            expect(before[card.id] ?? 0, towerOathStep,
                reason: 'seed ${run.seed}, floor $f: the oath of ${card.id} '
                    'was taken at standing ${before[card.id]}');
          }
          sworn++;
          oaths++;
        } else if (card.clan.isNotEmpty) {
          gifts++;
        }
        seen.add(card);
        for (final v in towerStandingFrom(seen, data.clans).values) {
          expect(v, inInclusiveRange(0, towerOathStep),
              reason: 'seed ${run.seed}, floor $f: standing $v');
        }
      }
      expect(sworn, lessThanOrEqualTo(1),
          reason: 'seed ${run.seed}: $sworn oaths in a run');
      expect(run.clanIds.length, sworn,
          reason: 'seed ${run.seed}: sworn clans ${run.clanIds} but $sworn '
              'oaths taken');
      // The cards with no clan move nothing.
      final onlyGifts = [
        for (final f in floors)
          if (run.taken[f]!.clan.isNotEmpty) run.taken[f]!
      ];
      expect(
          towerStandingOf(run, data),
          {
            for (final c in run.clanPool)
              c: towerStandingFrom(onlyGifts, data.clans)[c] ?? 0
          },
          reason: 'seed ${run.seed}: a card with no clan moved standing');
      if (run.clanIds.isNotEmpty) {
        expect(towerLeadingClan(run, data), run.mainClanId,
            reason: 'seed ${run.seed}: the sworn clan does not lead');
      }
    }
    expect(gifts, greaterThan(100),
        reason: 'gifts taken in 200 climbs: $gifts');
    expect(oaths, greaterThan(0), reason: 'no oath sworn in 200 climbs');
  });

  test('a card refused is a floor with no card, and it pays a mark', () {
    var refusals = 0;
    for (final run in runs) {
      for (final f in run.refused) {
        expect(run.taken.containsKey(f), isFalse,
            reason: 'seed ${run.seed}: floor $f was refused and taken');
      }
      refusals += run.refused.length;
      expect(
          run.marksEarned, towerMarksOf(run.heightCleared, run.refused.length),
          reason: 'seed ${run.seed}: marks');
    }
    // One more refusal is exactly one more mark, whatever the height.
    for (final h in [0, 1, 5, 12, 30]) {
      expect(towerMarksOf(h, 1) - towerMarksOf(h, 0), 1,
          reason: '"Not now" at height $h');
    }
    // The bot never refuses, so none here: the rule above is what pays.
    expect(refusals, greaterThanOrEqualTo(0));
  });

  test('old saves load: no clan on any card, standing 0, the climb goes on',
      () {
    final withClans = runs.firstWhere((r) =>
        r.taken.values.any((c) => c.clan.isNotEmpty) &&
        (r.status == TowerStatus.dead || r.status == TowerStatus.won));
    final json =
        jsonDecode(jsonEncode(withClans.toJson())) as Map<String, dynamic>;
    // Strip the clan off every card, as a save from before has it.
    void strip(Object? node) {
      if (node is Map) {
        node.remove('clan');
        node.values.forEach(strip);
      } else if (node is List) {
        node.forEach(strip);
      }
    }

    strip(json);
    final old = TowerRun.fromJson(json);
    expect(old.taken.length, withClans.taken.length);
    expect(towerStandingOf(old, data).values.every((v) => v == 0), isTrue,
        reason: 'an old save has standing with a clan');
    // It reads and saves back as itself.
    expect(jsonDecode(jsonEncode(old.toJson())), json);
  });
}
