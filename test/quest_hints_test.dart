// "Work on offer" (v1.166): a story choice that leads to a side job the
// player hasn't taken shows it, so the market's scenes aren't walked past.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/quest_hints.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

void main() {
  final raw =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });

  StoryChoice choiceTo(String from, String to) =>
      story.nodeFor(from)!.choices.firstWhere((c) => c.nextId == to);

  test('the market points at its three side jobs', () {
    for (final (scene, quest) in [
      ('2015_informant', 'q_ch2_informants_tip'),
      ('2015_ternrow', 'q_ch2_terns_toll'),
      ('2010_liora', 'q_ch2_lioras_watch'),
    ]) {
      final choice = choiceTo('2015', scene);
      expect(
          questOfferedAhead(
              choice: choice, story: story, takenQuestIds: const {}),
          isTrue,
          reason: scene);
      // Taken on (or done): nothing left to point at.
      expect(
          questOfferedAhead(
              choice: choice, story: story, takenQuestIds: {quest}),
          isFalse,
          reason: scene);
    }
  });

  test('the main quest is no side job', () {
    final quests =
        jsonDecode(File('assets/gamedata/quests.json').readAsStringSync())
            as Map<String, dynamic>;
    final main = mainQuestIdsOf(quests);
    expect(main, contains('q_retrieve_banner'));
    expect(main, isNot(contains('q_ch2_terns_toll')));
    // Both ways over the river hand out the Heirloom of Alster.
    for (final choice in story.nodeFor('250')!.choices) {
      expect(
          questOfferedAhead(
              choice: choice, story: story, takenQuestIds: const {}),
          isTrue);
      expect(
          questOfferedAhead(
              choice: choice,
              story: story,
              takenQuestIds: const {},
              mainQuestIds: main),
          isFalse,
          reason: choice.text);
    }
  });

  test('a way back to a hub is not tagged for the jobs it holds', () {
    final back = choiceTo('2015_ternrow_talked', '2015');
    expect(
        questOfferedAhead(choice: back, story: story, takenQuestIds: const {}),
        isFalse);
  });
}
