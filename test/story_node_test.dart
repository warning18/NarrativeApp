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

  group('hideIfFlags', () {
    test('hides the choice once any listed flag is held', () {
      const choice = StoryChoice(
        text: 'Visit the Arcane Bazaar',
        nextId: '2015_bazaar',
        hideIfFlags: ['hub_2015_bazaar'],
      );
      expect(choice.isHiddenFor(const []), isFalse);
      expect(choice.isHiddenFor(const ['other']), isFalse);
      expect(choice.isHiddenFor(const ['other', 'hub_2015_bazaar']), isTrue);
      final restored = StoryChoice.fromJson(choice.toJson());
      expect(restored.hideIfFlags, ['hub_2015_bazaar']);
      const plain = StoryChoice(text: 'Go', nextId: 'n1');
      expect(plain.toJson().containsKey('hideIfFlags'), isFalse);
    });
  });

  group('launchZoneId', () {
    test('round-trips through JSON and is omitted when unset', () {
      const choice = StoryChoice(
        text: 'Take the Drowned Stair down to the Court',
        nextId: '5003',
        launchZoneId: 'z_drowned_stair',
      );
      final restored = StoryChoice.fromJson(choice.toJson());
      expect(restored.launchZoneId, 'z_drowned_stair');
      expect(restored.launchesZone, isTrue);
      const plain = StoryChoice(text: 'Go', nextId: '1');
      expect(plain.launchesZone, isFalse);
      expect(plain.toJson().containsKey('launchZoneId'), isFalse);
      expect(
          const StoryChoice(text: 'Go', nextId: '1', launchZoneId: '')
              .launchesZone,
          isFalse);
    });
  });

  group('StoryNode.alignmentEpilogues', () {
    test('parses, picks by alignment and language, and round-trips', () {
      final node = StoryNode.fromJson('7005', {
        'description': 'The end.',
        'choices': const [],
        'alignment_epilogues': {
          'Good': {
            'en': 'You stopped for people.',
            'fr': 'Vous vous arrêtiez.'
          },
          'Evil': {'en': 'The gallows went up fast.'},
          'Broken': {'fr': 'no english'},
        },
      });
      expect(node.alignmentEpilogues.keys, ['Good', 'Evil']);
      expect(node.epilogueFor('Good', false), 'You stopped for people.');
      expect(node.epilogueFor('Good', true), 'Vous vous arrêtiez.');
      expect(node.epilogueFor('Evil', true), 'The gallows went up fast.');
      expect(node.epilogueFor('Neutral', false), isNull);
      final json = node.toJson();
      final epilogues = json['alignment_epilogues'] as Map;
      expect((epilogues['Good'] as Map)['fr'], 'Vous vous arrêtiez.');
      expect((epilogues['Evil'] as Map).containsKey('fr'), isFalse);
      expect(StoryNode.fromJson('x', {'description': 'y'}).toJson(),
          isNot(contains('alignment_epilogues')));
    });
  });
}
