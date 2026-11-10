// Old Tower saves, brought up to date once as they load (v1.867, round 3
// item D): the three shapes before it, each as its version saved it.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  final data = towerDataFromAssets();

  /// A run's save, as [json] says, round-tripped once more after loading.
  TowerRun load(Map<String, dynamic> json) {
    final run = TowerRun.fromJson(json);
    final again = TowerRun.fromJson(
        jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
    expect(jsonEncode(again.toJson()), jsonEncode(run.toJson()),
        reason: 'a loaded save saves as it loads');
    return run;
  }

  test('before v1.855: the clan sworn at the start is its oath on floor 0', () {
    final run = load({
      'seed': 9,
      'race': 'human',
      'profession': 'warrior',
      'clan': 'mire',
      'floor': 3,
      'health': 30,
      'status': 'climbing',
      'picks': [0, 0],
    });
    expect(run.clanIds, ['mire']);
    expect(run.mainClanId, 'mire');
    expect(run.taken[0]?.kind, TowerRewardKind.clanOath);
    expect(run.toJson().containsKey('clan'), isFalse);
    // Sworn, it holds the clan's die, as an oath taken on the way up does.
    if (towerClanDieOf('mire', data.dice) case final die?) {
      expect(towerHeroOf(run, data).ownedDice.keys, contains(die));
    }
  });

  test('before v1.857: each pick the levels earned is the calling\'s', () {
    final run = load({
      'seed': 9,
      'race': 'elf',
      'profession': 'mage',
      'floor': 6,
      'health': 30,
      'status': 'climbing',
    });
    final earned = towerLevelAfter(5) - 1;
    expect(run.statPicks, List.filled(earned, 0));
    expect(towerPendingPicks(run), 0);
  });

  test('before v1.860: the old cards become what the Tower gives now', () {
    final run = load({
      'seed': 9,
      'race': 'human',
      'profession': 'warrior',
      'floor': 5,
      'health': 30,
      'status': 'choosing',
      'picks': [0, 0, 0],
      'taken': {
        '1': {'kind': 'item', 'id': 'sword_t4'},
        '2': {'kind': 'heal', 'amount': 35},
        '3': {'kind': 'clanGift', 'id': 'flame_die'},
        '4': {'kind': 'clanGift', 'amount': 1},
      },
      'offer': [
        {'kind': 'heal', 'amount': 50},
        {'kind': 'item', 'id': 'sword_t4'},
        {'kind': 'skill', 'id': 'second_wind'},
      ],
    });
    // An item card: its gear among that floor's spoils, worn when better.
    expect(run.spoils[1], ['sword_t4']);
    expect(towerHeroOf(run, data).ownedItemIds, contains('sword_t4'));
    // A heal card, and a gift's stat point: nothing (the health is saved).
    expect(run.taken.containsKey(2), isFalse);
    expect(run.taken.containsKey(4), isFalse);
    // A clan's die: a die card.
    expect(
        run.taken[3], const TowerReward(TowerRewardKind.die, id: 'flame_die'));
    // The waiting offer keeps the cards still dealt.
    expect(run.offer.map((r) => r.kind), [TowerRewardKind.skill]);
    expect(run.health, 30);
  });

  test('a save of now loads as it is', () {
    final run = playTowerRun(seed: 5, data: data);
    final again = TowerRun.fromJson(
        jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
    expect(jsonEncode(again.toJson()), jsonEncode(run.toJson()));
  });
}
