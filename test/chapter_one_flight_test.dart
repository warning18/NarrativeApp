// Chapter 1 is the flight from the burning city (v1.181): no shops, no
// detours, no hunters; the docks give one piece of salvaged gear, and the
// heirloom quest ends once the Bundle is out of Alster.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/alignment_events.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final raw = _json('assets/Cleaned_Narrative_DAG.json');
  final nodes = {
    for (final entry in raw.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  };
  bool inChapterOne(String id) {
    final head = int.tryParse(id.split('_').first);
    return head != null && head < 2000;
  }

  test('no scene of chapter 1 opens a shop', () {
    for (final node in nodes.values.where((n) => inChapterOne(n.id))) {
      for (final choice in node.choices) {
        expect(choice.unlockShopId ?? '', isEmpty,
            reason: '${node.id}: ${choice.text}');
      }
    }
    final shops = _json('assets/gamedata/shops.json');
    expect(
        SubNodeEngine.filterShopPool(
            shops: shops, unlockedShopIds: const [], chapter: 1),
        isEmpty);
  });

  test('the docks give one piece of salvaged gear', () {
    final grabs = nodes['891']!.choices.where((c) => c.grantsItem).toList();
    expect(grabs, hasLength(2));
    for (final grab in grabs) {
      expect(grab.hideIfFlags, grab.flagsToAdd,
          reason: 'taking one hides the other');
      expect(grab.nextId, '891');
    }
    final items = _json('assets/gamedata/items.json');
    for (final grab
        in nodes.values.expand((n) => n.choices).where((c) => c.grantsItem)) {
      expect(items, contains(grab.grantItemId), reason: grab.text);
    }
  });

  test('a granted item survives a round trip and counts as an effect', () {
    final choice = StoryChoice.fromJson(const {
      'text': 'Snatch a blade',
      'next_id': '891',
      'grantItemId': 'sword_t1',
    });
    expect(choice.grantsItem, isTrue);
    expect(choice.hasEffects, isTrue);
    expect(StoryChoice.fromJson(choice.toJson()).grantItemId, 'sword_t1');
    expect(StoryChoice.fromJson(const {'text': 'x', 'next_id': 'y'}).grantsItem,
        isFalse);
  });

  test('no hunter or temptation finds the party in chapter 1', () {
    final enemies = _json('assets/gamedata/enemies.json');
    for (var seed = 0; seed < 200; seed++) {
      for (final score in [-60, 0, 60]) {
        expect(
            maybeAlignmentEvent(
              alignmentScore: score,
              activeQuestIds: const [],
              completedQuestIds: const [],
              enemies: enemies,
              chapter: 1,
              random: Random(seed),
            ),
            isNull);
      }
    }
  });

  test('the heirloom quest and Vess wait until the party is out of Alster', () {
    final quests = _json('assets/gamedata/quests.json');
    for (final id in ['q_retrieve_banner', 'q_ch1_vess_in_the_dark']) {
      final objective = ((quests[id] as Map)['objectives'] as List).single
          as Map<String, dynamic>;
      expect(objective['type'], 'Flag', reason: id);
      expect(objective['targetFlag'], 'void_banner_bearer', reason: id);
    }
    // void_banner_bearer is set as chapter 1 ends, and only then.
    final setters = [
      for (final node in nodes.values)
        for (final choice in node.choices)
          if (choice.flagsToAdd.contains('void_banner_bearer')) node.id,
    ];
    expect(setters.toSet(), {'1000', '1001', '1002'});
  });
}
