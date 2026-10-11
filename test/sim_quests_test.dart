// The simulator's quest log (v1.230): quests are taken when the character
// qualifies, counted from the kills, flags and items, and handed in with the
// turn-in choice the player's lean picks.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/sim_quests.dart';

Map<String, dynamic> _quests() => {
      'bounty': {
        'questName': 'Bounty',
        'requiredAlignment': 'Neutral',
        'requiredFlags': <String>[],
        'requiredGold': 0,
        'rewardGold': 50,
        'rewardXP': 60,
        'alignmentChange': 0,
        'nextQuestID': 'after',
        'rewardItemID': 'trinket',
        'objectives': [
          {
            'type': 'Kill',
            'targetEnemyID': 'rat',
            'requiredAmount': 2,
            'countFromAccept': true,
          },
        ],
      },
      'after': {
        'questName': 'After',
        'requiredAlignment': 'Neutral',
        'requiredFlags': <String>[],
        'requiredGold': 0,
        'rewardGold': 5,
        'rewardXP': 5,
        'alignmentChange': 0,
        'objectives': [
          {'type': 'Flag', 'targetFlag': 'met_her', 'requiredAmount': 1},
        ],
      },
      'dark': {
        'questName': 'Dark',
        'requiredAlignment': 'Evil',
        'requiredFlags': <String>[],
        'requiredGold': 0,
        'rewardGold': 10,
        'rewardXP': 10,
        'alignmentChange': 0,
        'objectives': <Map<String, dynamic>>[],
      },
      'choosy': {
        'questName': 'Choosy',
        'requiredAlignment': 'Neutral',
        'requiredFlags': <String>[],
        'requiredGold': 0,
        'rewardGold': 100,
        'rewardXP': 0,
        'alignmentChange': 0,
        'objectives': <Map<String, dynamic>>[],
        'turnInChoices': [
          {'choiceText': 'Keep it', 'rewardGold': 150, 'alignmentChange': -5},
          {
            'choiceText': 'Give it back',
            'rewardGold': 20,
            'alignmentChange': 5
          },
        ],
      },
    };

bool _take(SimQuestLog log, String id,
        {Set<String> flags = const {},
        String alignment = 'Neutral',
        Map<String, int>? before}) =>
    log.accept(id,
        step: 1,
        flags: flags,
        gold: 0,
        alignmentLabel: alignment,
        killsBefore: before);

void main() {
  test('a quest asks the character\'s alignment, once', () {
    final log = SimQuestLog(_quests());
    expect(_take(log, 'dark'), isFalse);
    expect(_take(log, 'dark', alignment: 'Evil'), isTrue);
    expect(_take(log, 'dark', alignment: 'Evil'), isFalse, reason: 'taken');
    expect(_take(log, 'nothing'), isFalse);
  });

  test('a bounty counts only the kills after it is taken', () {
    final log = SimQuestLog(_quests())..recordKills(['rat', 'rat']);
    _take(log, 'bounty');
    expect(log.ready({}), isEmpty);
    log.recordKills(['rat']);
    expect(log.ready({}), isEmpty);
    log.recordKills(['rat']);
    expect(log.ready({}), ['bounty']);
  });

  test('a fight that offers the quest counts its own kills', () {
    final log = SimQuestLog(_quests());
    log.recordKills(['rat', 'rat']);
    _take(log, 'bounty', before: const {'rat': 0});
    expect(log.ready({}), ['bounty']);
  });

  test('handing in pays, adds the item and leaves the quest done', () {
    final log = SimQuestLog(_quests());
    _take(log, 'bounty');
    log.recordKills(['rat', 'rat']);
    final pay = log.complete('bounty',
        step: 9, bias: SimTurnInBias.any, random: Random(1));
    expect((pay.gold, pay.xp, pay.itemId, pay.nextQuestId),
        (50, 60, 'trinket', 'after'));
    expect(log.active, isEmpty);
    expect(log.completed, {'bounty'});
    expect(log.inventory, contains('trinket'));
    expect(log.records['bounty']!.completedAtStep, 9);
    // The follow-up waits on its flag.
    _take(log, 'after');
    expect(log.ready({}), isEmpty);
    expect(log.ready({'met_her'}), ['after']);
    expect(log.unmet({})['after'], isNotEmpty);
  });

  test('the turn-in choice follows the player\'s lean', () {
    SimQuestPayout settle(SimTurnInBias bias) {
      final log = SimQuestLog(_quests());
      _take(log, 'choosy');
      return log.complete('choosy', step: 1, bias: bias, random: Random(1));
    }

    expect(settle(SimTurnInBias.gold).turnIn, 'Keep it');
    expect(settle(SimTurnInBias.evil).turnIn, 'Keep it');
    expect(settle(SimTurnInBias.good).turnIn, 'Give it back');
    expect(settle(SimTurnInBias.good).gold, 20);
    expect(settle(SimTurnInBias.good).alignment, 5);
  });

  test('a thorough player is steered to what a quest still wants', () {
    final log = SimQuestLog(_quests());
    _take(log, 'bounty');
    _take(log, 'after');
    final want = log.wanted({});
    expect(want.foes, {'rat'});
    expect(want.flags, {'met_her'});
    expect(log.wanted({'met_her'}).flags, isEmpty);
  });
}
