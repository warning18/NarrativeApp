// Unit coverage for StoryChoice.allTriggerEnemyIds -- the one place that
// resolves "which enemy/enemies" a choice triggers combat against, now that
// a choice can carry either the original singular triggerEnemyId or a
// plural triggerEnemyIds pack, but never both meaningfully at once.

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/models/story_node.dart';

void main() {
  group('StoryChoice.allTriggerEnemyIds', () {
    test('falls back to wrapping the singular triggerEnemyId', () {
      const choice = StoryChoice(
        text: 'Fight',
        nextId: 'n1',
        triggerEnemyId: 'harbor_rat',
      );
      expect(choice.allTriggerEnemyIds, ['harbor_rat']);
      expect(choice.triggersCombat, isTrue);
    });

    test('prefers the plural triggerEnemyIds when set', () {
      const choice = StoryChoice(
        text: 'Fight',
        nextId: 'n1',
        triggerEnemyIds: ['harbor_rat', 'dock_overseer'],
      );
      expect(choice.allTriggerEnemyIds, ['harbor_rat', 'dock_overseer']);
      expect(choice.triggersCombat, isTrue);
    });

    test('prefers triggerEnemyIds even if triggerEnemyId is also set', () {
      const choice = StoryChoice(
        text: 'Fight',
        nextId: 'n1',
        triggerEnemyId: 'harbor_rat',
        triggerEnemyIds: ['dock_overseer', 'street_bandit'],
      );
      expect(choice.allTriggerEnemyIds, ['dock_overseer', 'street_bandit']);
    });

    test('is empty, and triggersCombat is false, with neither field set', () {
      const choice = StoryChoice(text: 'Move on', nextId: 'n1');
      expect(choice.allTriggerEnemyIds, isEmpty);
      expect(choice.triggersCombat, isFalse);
    });

    test(
        'an empty triggerEnemyId string falls through to empty, not a '
        'single blank entry', () {
      const choice =
          StoryChoice(text: 'Move on', nextId: 'n1', triggerEnemyId: '');
      expect(choice.allTriggerEnemyIds, isEmpty);
      expect(choice.triggersCombat, isFalse);
    });
  });

  group('hunt and hunter fields', () {
    test('round-trip through JSON and default to empty', () {
      const choice = StoryChoice(
        text: 'Hunt it down',
        nextId: '',
        triggerEnemyId: 'harbor_rat',
        huntName: 'Old Scar',
        huntAffixes: ['frenzied', 'armored'],
        chestFloor: 'gold',
      );
      final restored = StoryChoice.fromJson(choice.toJson());
      expect(restored.huntName, 'Old Scar');
      expect(restored.huntAffixes, ['frenzied', 'armored']);
      expect(restored.chestFloor, 'gold');
      expect(restored.isHunterAmbush, isFalse);

      const plain = StoryChoice(text: 'Go', nextId: 'n1');
      expect(plain.toJson().containsKey('huntName'), isFalse);
      expect(plain.toJson().containsKey('isHunterAmbush'), isFalse);
      final ambush = StoryChoice.fromJson({
        'text': 'Fight',
        'next_id': '',
        'triggerEnemyId': 'demon_imp',
        'isHunterAmbush': true,
      });
      expect(ambush.isHunterAmbush, isTrue);
    });
  });
}
