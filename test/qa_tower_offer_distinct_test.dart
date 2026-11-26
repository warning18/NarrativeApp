// QA guard (user bug, v2.10.14): the clans' offer after a floor showed the
// SAME gift on all three cards (Arcane Focus, a rank-up, the die full). Each
// clan's gift was a different skill, but a skill with no free face on the die
// turns into a rank-up of the best skill on it, and every card then raised
// that one skill. A table of cards must show different cards.
//
// Over many climbs of the bot (every offer it is ever dealt), and, at every
// decision point of those climbs, over the other tables the same hero could be
// dealt (the clans' offer, a boon, the stall's boon, a reroll), no table holds
// two cards that are the same gift: the same skill, die or spell (a rank-up
// and the skill it raises count as one), nor the same clan's oath twice.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_coins.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  final data = towerDataFromAssets();

  /// What the player sees a card to be: a skill (a rank-up raises the skill
  /// it names), a die, a spell, a clan's oath.
  String gift(TowerReward c) => switch (c.kind) {
        TowerRewardKind.skill || TowerRewardKind.rankUp => 'skill:${c.id}',
        TowerRewardKind.die => 'die:${c.id}',
        TowerRewardKind.spell => 'spell:${c.id}',
        TowerRewardKind.clanOath => 'oath:${c.id}',
        // Rules 2's loot cards (Core's rules PR): never on these tables.
        TowerRewardKind.gear ||
        TowerRewardKind.bundle ||
        TowerRewardKind.purse =>
          '${c.kind.name}:${c.id}:${c.amount}',
      };

  final problems = <String>[];
  var tables = 0;
  var clanTables = 0;
  var threeCardTables = 0;

  void check(String where, List<TowerReward> cards) {
    if (cards.length < 2) return;
    tables++;
    if (cards.length >= 3) threeCardTables++;
    final seen = <String>{};
    for (final c in cards) {
      if (!seen.add(gift(c))) {
        problems.add('$where: ${[
          for (final x in cards)
            '${x.kind.name}:${x.id}'
                '${x.clan.isEmpty ? '' : '@${x.clan}'}'
        ].join(', ')}');
        return;
      }
    }
  }

  void climb(int seed, TowerProgress progress, int heat) {
    var decision = 0;
    playTowerRun(
        seed: seed,
        data: data,
        progress: progress,
        events: towerEventsLive,
        heat: heat,
        choice: (run) {
          decision++;
          final tag = 'seed $seed heat $heat floor ${run.floor}';
          // The offer the bot is dealt.
          check('$tag, the offer', run.offer);
          // The other tables this hero could be dealt on this floor: forced
          // clans' offers (several draws), a boon, the stall's boon.
          final hero = towerHeroOf(run, data);
          if (run.clanPool.isNotEmpty) {
            for (var i = 0; i < 4; i++) {
              final cards = towerRunOfferFor(run, data, run.floor, hero,
                  clansDue: true,
                  random: Random(seed * 100 + decision * 7 + i));
              if (cards.any((c) => c.clan.isNotEmpty)) clanTables++;
              check('$tag, a clans\' offer (draw $i)', cards);
            }
          }
          for (var i = 0; i < 3; i++) {
            check(
                '$tag, a boon (draw $i)',
                towerRunOfferFor(run, data, run.floor, hero,
                    boon: true,
                    random: Random(seed * 100 + decision * 11 + i)));
          }
          check('$tag, the stall\'s boon',
              towerStallBoonFor(run, data, run.floor, hero));
          return towerBotChoice(run, clans: data.clans);
        });
  }

  test('no table of the Tower holds the same gift twice', () {
    for (var seed = 1; seed <= 120; seed++) {
      climb(seed, towerAllUnlocked, 0);
    }
    for (var seed = 1; seed <= 60; seed++) {
      climb(seed, const TowerProgress(), 0);
      climb(seed, towerAllUnlocked, 3);
    }
    // The sweep reached what it is meant to: many tables, clans' offers and
    // three-card ones among them.
    expect(tables, greaterThan(1000));
    expect(clanTables, greaterThan(200), reason: 'too few clans\' offers');
    expect(threeCardTables, greaterThan(400));
    expect(problems, isEmpty,
        reason: '${problems.length} tables with a repeated gift, e.g.\n'
            '${problems.take(8).join('\n')}');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
