// Unit coverage for quest_objectives.dart's pure objective-evaluation
// logic -- the gate behind the Quests tab's Complete button. Deliberately
// tested independent of PlayerSessionNotifier/SharedPreferences since
// these are pure functions of (quest record, session).

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/quest_objectives.dart';

import 'player_session_provider_test.dart' show baseSession;

void main() {
  group('Kill objectives', () {
    final killQuest = <String, dynamic>{
      'objectives': [
        {
          'description': 'Defeat the slum thug',
          'type': 'Kill',
          'targetEnemyID': 'slum_thug',
          'requiredAmount': 1,
        },
      ],
    };

    test('not met before the target enemy has been killed', () {
      final session = baseSession();
      expect(allObjectivesMet('q_first_blood', killQuest, session), isFalse);
      final status =
          objectiveStatusesFor('q_first_blood', killQuest, session).single;
      expect(status.met, isFalse);
      expect(status.current, 0);
      expect(status.required, 1);
    });

    test('met once the kill count reaches requiredAmount', () {
      final session = baseSession().copyWith(enemyKillCounts: {'slum_thug': 1});
      expect(allObjectivesMet('q_first_blood', killQuest, session), isTrue);
    });

    test('a kill against a different enemy does not satisfy it', () {
      final session =
          baseSession().copyWith(enemyKillCounts: {'rat_matriarch': 5});
      expect(allObjectivesMet('q_first_blood', killQuest, session), isFalse);
    });

    test('requiredAmount > 1 needs that many kills', () {
      final quest = <String, dynamic>{
        'objectives': [
          {
            'description': 'Clear the nest',
            'type': 'Kill',
            'targetEnemyID': 'harbor_rat',
            'requiredAmount': 3,
          },
        ],
      };
      final twoKills = baseSession().copyWith(enemyKillCounts: {
        'harbor_rat': 2,
      });
      expect(allObjectivesMet('q_nest', quest, twoKills), isFalse);
      final threeKills = baseSession().copyWith(enemyKillCounts: {
        'harbor_rat': 3,
      });
      expect(allObjectivesMet('q_nest', quest, threeKills), isTrue);
    });
  });

  group('Fetch objectives', () {
    final fetchQuest = <String, dynamic>{
      'objectives': [
        {
          'description': 'Bring back the relic',
          'type': 'Fetch',
          'targetItemID': 'void_relic',
          'requiredAmount': 1,
        },
      ],
    };

    test('not met without the item in inventory', () {
      final session = baseSession();
      expect(allObjectivesMet('q_relic', fetchQuest, session), isFalse);
    });

    test('met once the item is in inventory', () {
      final session = baseSession().copyWith(inventoryItemIds: ['void_relic']);
      expect(allObjectivesMet('q_relic', fetchQuest, session), isTrue);
    });
  });

  group('objectives with no target data', () {
    test('a Kill objective with no targetEnemyID is always met', () {
      final quest = <String, dynamic>{
        'objectives': [
          {'description': 'Something vague', 'type': 'Kill'},
        ],
      };
      expect(allObjectivesMet('q_vague', quest, baseSession()), isTrue);
    });

    test('a Talk objective (no enforcement convention yet) is always met', () {
      final quest = <String, dynamic>{
        'objectives': [
          {'description': 'Talk to them', 'type': 'Talk'},
        ],
      };
      expect(allObjectivesMet('q_talk', quest, baseSession()), isTrue);
    });

    test('a quest with no objectives at all is always met', () {
      expect(allObjectivesMet('q_none', const {}, baseSession()), isTrue);
    });
  });

  group('multi-objective quests (sub-quest checklist)', () {
    test('every objective must be met, not just one', () {
      final quest = <String, dynamic>{
        'objectives': [
          {
            'description': 'Defeat the guard',
            'type': 'Kill',
            'targetEnemyID': 'inquisition_soldier',
            'requiredAmount': 1,
          },
          {
            'description': 'Recover the banner piece',
            'type': 'Fetch',
            'targetItemID': 'banner_piece_1',
            'requiredAmount': 1,
          },
        ],
      };
      final onlyKillDone =
          baseSession().copyWith(enemyKillCounts: {'inquisition_soldier': 1});
      expect(allObjectivesMet('q_multi', quest, onlyKillDone), isFalse);

      final bothDone = baseSession().copyWith(
        enemyKillCounts: {'inquisition_soldier': 1},
        inventoryItemIds: ['banner_piece_1'],
      );
      expect(allObjectivesMet('q_multi', quest, bothDone), isTrue);

      final statuses = objectiveStatusesFor('q_multi', quest, bothDone);
      expect(statuses, hasLength(2));
      expect(statuses.every((s) => s.met), isTrue);
    });
  });

  group('grandfathered quests', () {
    test('a grandfathered quest is met regardless of actual progress', () {
      final quest = <String, dynamic>{
        'objectives': [
          {
            'description': 'Defeat the slum thug',
            'type': 'Kill',
            'targetEnemyID': 'slum_thug',
            'requiredAmount': 1,
          },
        ],
      };
      final session =
          baseSession().copyWith(grandfatheredQuestIds: ['q_legacy']);
      expect(allObjectivesMet('q_legacy', quest, session), isTrue);
      final status = objectiveStatusesFor('q_legacy', quest, session).single;
      expect(status.met, isTrue);
      expect(status.current, status.required);
    });

    test('a different, non-grandfathered quest is still gated normally', () {
      final quest = <String, dynamic>{
        'objectives': [
          {
            'description': 'Defeat the slum thug',
            'type': 'Kill',
            'targetEnemyID': 'slum_thug',
            'requiredAmount': 1,
          },
        ],
      };
      final session =
          baseSession().copyWith(grandfatheredQuestIds: ['q_legacy']);
      expect(allObjectivesMet('q_other', quest, session), isFalse);
    });
  });
}
