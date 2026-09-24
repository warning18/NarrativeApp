// The fixes from the 1.131 review: one copy of an item is worn by one
// character, a bought tome is read, a death keeps the character, endings
// reach the ending screen, a hub's way onward is read off the graph, and
// game data can be awaited before a choice acts on it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/settlements.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Future<PlayerSessionNotifier> _notifierWith(Map<String, dynamic> json) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(PlayerSession.fromJson(json));
  return notifier;
}

StoryData _loadStory() {
  for (final path in [
    'assets/Cleaned_Narrative_DAG.json',
    '../assets/Cleaned_Narrative_DAG.json'
  ]) {
    final file = File(path);
    if (file.existsSync()) {
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return StoryData({
        for (final entry in decoded.entries)
          entry.key: StoryNode.fromJson(
              entry.key, entry.value as Map<String, dynamic>),
      });
    }
  }
  throw StateError('Cannot find the story file');
}

const _items = <String, dynamic>{
  'lance': {
    'itemName': 'Lance',
    'itemType': 'Weapon',
    'isEquippable': true,
    'equipSlot': 'Weapon',
    'attackDamage': 10,
  },
  'tome_of_mastery': {'itemName': 'Tome of Mastery', 'itemType': 'Tome'},
  'tome_of_insight': {'itemName': 'Tome of Insight', 'itemType': 'Tome'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('one copy, one wearer', () {
    test('a single copy worn by the player cannot also go on an ally',
        () async {
      final notifier = await _notifierWith({
        'inventoryItemIds': ['lance'],
        'recruitedAllies': [
          {'companionId': 'kelda', 'currentHealth': 50},
        ],
      });
      await notifier.equipItem('lance', slot: 'Weapon', items: _items);
      expect(notifier.state.equippedItemIds, ['lance']);
      expect(notifier.state.freeCopiesOf('lance', wearerId: 'kelda'), 0);

      await notifier.equipAllyItem('kelda', 'lance',
          slot: 'Weapon', items: _items);
      expect(notifier.state.recruitedAllies.single.equippedItemIds, isEmpty);
      expect(notifier.state.wearersOf('lance'), [playerWearerId]);
    });

    test('a second copy can be worn by an ally', () async {
      final notifier = await _notifierWith({
        'inventoryItemIds': ['lance', 'lance'],
        'equippedItemIds': ['lance'],
        'recruitedAllies': [
          {'companionId': 'kelda', 'currentHealth': 50},
        ],
      });
      await notifier.equipAllyItem('kelda', 'lance',
          slot: 'Weapon', items: _items);
      expect(notifier.state.recruitedAllies.single.equippedItemIds, ['lance']);
      expect(notifier.state.wearersOf('lance'), [playerWearerId, 'kelda']);
    });

    test('a death empties what the companions wore with the pack', () async {
      final notifier = await _notifierWith({
        'inventoryItemIds': ['lance'],
        'recruitedAllies': [
          {
            'companionId': 'kelda',
            'currentHealth': 50,
            'equippedItemIds': ['lance'],
          },
        ],
      });
      await notifier.applyPermadeath(race: const {}, profession: const {});
      expect(notifier.state.inventoryItemIds, isEmpty);
      expect(notifier.state.recruitedAllies.single.equippedItemIds, isEmpty);
    });
  });

  group('tomes', () {
    test('a bought tome is read on the spot, not carried', () async {
      final notifier = await _notifierWith({'gold': 500});
      await notifier.buyItem('last_lantern', 'tome_of_mastery', 200, 1,
          item: _items['tome_of_mastery'] as Map<String, dynamic>);
      expect(notifier.state.gold, 300);
      expect(notifier.state.skillPoints, 1);
      expect(notifier.state.inventoryItemIds, isEmpty);
    });

    test('a tome already in the pack can be read', () async {
      final notifier = await _notifierWith({
        'inventoryItemIds': ['tome_of_insight'],
      });
      await notifier.readTome(
          'tome_of_insight', _items['tome_of_insight'] as Map<String, dynamic>);
      expect(notifier.state.statPoints, 1);
      expect(notifier.state.inventoryItemIds, isEmpty);
      // A second read does nothing: the copy is gone.
      await notifier.readTome(
          'tome_of_insight', _items['tome_of_insight'] as Map<String, dynamic>);
      expect(notifier.state.statPoints, 1);
    });
  });

  group('story', () {
    final story = _loadStory();

    test('the four endings are story endings; a hub is not', () {
      for (final id in ['7005', '7005_seeker', '7005_dawn', '7005_crown']) {
        expect(isStoryEnding(story.nodeFor(id)!), isTrue, reason: id);
      }
      expect(isStoryEnding(story.nodeFor('2015')!), isFalse);
    });

    test('after a death the story resumes past character creation', () {
      final resume = firstSceneAfterCreation(story);
      expect(resume, isNot(StoryRepository.startNodeId));
      final startChoices = story.nodeFor(StoryRepository.startNodeId)!.choices;
      expect(
          startChoices
              .where((c) => c.opensCharacterCreation)
              .map((c) => c.nextId),
          contains(resume));
    });

    test('the Reliquary Quarter\'s thread is its way onward', () {
      final quarter = story.nodeFor('6010')!;
      final onward = quarter.choices
          .where((c) => !isLocalChoice(c, quarter.id, story))
          .map((c) => c.nextId)
          .toList();
      expect(onward, ['6010_thread']);
      final wharf = story.nodeFor('2015')!;
      expect(
          wharf.choices
              .where((c) => !isLocalChoice(c, wharf.id, story))
              .map((c) => c.nextId),
          containsAll(['2030', '2040', '2011']));
    });
  });

  test('game data can be awaited before anything has watched it', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final zones =
        await container.read(gameDbProvider(zonesSchema).notifier).whenLoaded();
    expect(zones, contains('z_beyond_the_tear'));
  });
}
