// A chapter 8 in chapters.json just works (v1.196): nothing reads the
// story's last chapter as 7. On fixtures: the loops and the chapter the
// party has reached, the ids' chapters, the threat's grace, and the
// offers a chapter brings.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/chapter_grid_layout.dart';
import 'package:narrative_data_app/data/chapter_loop.dart';
import 'package:narrative_data_app/data/journey_rules.dart';
import 'package:narrative_data_app/data/offers.dart' show OfferSource;
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/sim_growth.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Chapter 7, the Lantern Throne, at camp 7400; chapter 8, Beyond the
/// Tear, at camp 7800, in chapters.json's shape.
const Map<String, dynamic> _chapters = {
  'ch6': {
    'chapterID': 'ch6',
    'chapter': 6,
    'label': 'Chapter 6',
    'title': 'The Hollow Shore',
    'campNodeId': '7001',
    'activityGoal': 8,
  },
  'ch7': {
    'chapterID': 'ch7',
    'chapter': 7,
    'label': 'Chapter 7',
    'title': 'The Lantern Throne',
    'campNodeId': '7400',
    'activityGoal': 0,
  },
  'ending': {
    'chapterID': 'ending',
    'chapter': 8,
    'label': 'Chapter 8',
    'title': 'Beyond the Tear',
    'campNodeId': '7800',
    'activityGoal': 0,
  },
};

StoryNode _camp(String id, int chapter) => StoryNode.fromJson(id, {
      'description': 'A camp.',
      'settlement': {'kind': 'camp', 'name': 'Camp', 'chapter': chapter},
      'choices': [
        {'text': 'On', 'next_id': '${int.parse(id) + 10}', 'mainQuest': true},
      ],
    });

void main() {
  final loops = chapterLoopsFrom(_chapters);
  final story = StoryData({
    '7001': _camp('7001', 6),
    '7400': _camp('7400', 7),
    '7800': _camp('7800', 8),
  });

  test('the loops run to chapter 8, in order', () {
    expect(loops.map((l) => l.chapter), [6, 7, 8]);
    expect(loops.last.title, 'Beyond the Tear');
  });

  test('the chapter reached follows the camps to the eighth', () {
    int reached(String node, List<String> history) => reachedChapter(
        currentNodeId: node, history: history, loops: loops, story: story);
    expect(reached('7400', const ['7001']), 7);
    expect(reached('7510_vigil', const ['7001', '7400', '7500']), 7);
    expect(reached('7800', const ['7400']), 8);
    expect(reached('7810', const ['7400', '7800']), 8);
    // The Hollow Shore's scenes, met again in the last chapter, are read
    // in it too.
    expect(reached('7002_approach', const ['7400', '7800', '7810']), 8);
  });

  test('ids past 7400 read as chapters 7 and 8', () {
    expect(chapterOfNode('7001'), 6);
    expect(chapterOfNode('7002_confront'), 6);
    expect(chapterOfNode('7300'), 6);
    expect(chapterOfNode('7400'), 7);
    expect(chapterOfNode('7520_vane'), 7);
    expect(chapterOfNode('7800'), 8);
    expect(chapterOfNode('7810'), 8);
    expect(chapterOfNode('7810'), lastNodeIdChapter);
    expect(storyChapterOf('7800', story), 8);
    expect(storyChapterOf('7590_vigil'), 7);
  });

  test('a scene off the spine takes the chapter of the beat leading to it', () {
    // 7300 (chapter 6's beat) leads to two scenes with no number, then a
    // place; 5005 (chapter 4's) reaches the second as well.
    StoryNode scene(String id, List<String> next) => StoryNode.fromJson(id, {
          'description': id,
          'choices': [
            for (final n in next) {'text': 'On', 'next_id': n},
          ],
        });
    final led = StoryData({
      '5005': scene('5005', ['side_shared']),
      '7300': scene('7300', ['side_road']),
      'side_road': scene('side_road', ['side_shared', '7400']),
      'side_shared': scene('side_shared', ['7400']),
      '7400': _camp('7400', 7),
      'side_after_camp': scene('side_after_camp', const []),
    });
    expect(storyChapterOf('side_road', led), 6);
    expect(storyChapterOf('side_shared', led), 4, reason: 'the earliest');
    expect(spineLedChapters(led), isNot(contains('7400')),
        reason: 'a place keeps its own');
    expect(storyChapterOf('side_after_camp', led), 1,
        reason: 'no beat leads there: its id says');
    expect(storyChapterOf('side_road'), 1, reason: 'no story, no road');
  });

  test('a chapter past the threat\'s table is as short as the last', () {
    expect(threatGraceDaysFor(8), threatGraceDaysFor(7));
    expect(threatGraceDaysFor(12), threatGraceDaysFor(7));
    expect(threatGraceDaysFor(4), greaterThan(threatGraceDaysFor(8)));
  });

  test('the eighth chapter brings its offer like any other', () {
    final growth = SimGrowth(
      mode: SimProgression.offers,
      tables: const SimGrowthTables(),
      character: SimCharacter.create(
        raceId: 'human',
        race: _gamedata('races.json')['human'] as Map<String, dynamic>,
        professionId: 'warrior',
        profession:
            _gamedata('professions.json')['warrior'] as Map<String, dynamic>,
        gameConfig: _gamedata('game_config.json'),
        dice: _gamedata('dice.json'),
        spells: parseSpells(_gamedata('spells.json')),
      ),
    );
    growth.chapterReached(7);
    growth.chapterReached(8);
    expect(
        growth.pending
            .where((t) => t.source == OfferSource.chapter)
            .map((t) => t.detail),
        ['7', '8']);
  });
}
