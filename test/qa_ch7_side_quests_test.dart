// QA: the chapter 7 quest goal (1) and the three Candlehold side quests that
// meet it. A save parked at the cove camp (7400) must find the three
// visitors, finish one and turn it in, and then the sail opens; a save that
// already did the chapter's main quest is not locked out; and the 7500 gate
// lines remember each turn-in's flag.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/chapter_loop.dart';
import 'package:narrative_data_app/data/quest_tracking.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final dag = _json('assets/Cleaned_Narrative_DAG.json');
  final story = StoryData({
    for (final e in dag.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final quests = _json('assets/gamedata/quests.json');
  final loop = chapterLoopsFrom(_json('assets/gamedata/chapters.json'))
      .firstWhere((l) => l.chapter == 7);

  const visits = {
    'q_ch7_reed_gate_grievance': ('reed', 'hub_7400_reed_later'),
    'q_ch7_heralds_errand': ('herald', 'hub_7400_herald_later'),
    'q_ch7_chain_masters_boy': ('chain', 'hub_7400_chain_later'),
  };

  // The party stands at 7400 with the claim flag the sail needs.
  bool open(Set<String> flags, List<String> done) => mainQuestOpen(
        loop: loop,
        story: story,
        activityCount: 0,
        questCount: chapterQuestCount(
            chapter: 7, quests: quests, completedQuestIds: done),
        flags: flags,
        visitedNodeIds: const [],
      );

  List<String> hub(Set<String> flags) => [
        for (final c in story.nodeFor('7400')!.choices)
          if (!c.isHiddenFor(flags)) c.nextId,
      ];

  // A save with objective tracking (a save from before it grandfathers every
  // active quest, which then counts as met).
  PlayerSession save(Set<String> flags, String active) =>
      PlayerSession.fromJson({
        'flags': flags.toList(),
        'activeQuestIds': [active],
        'enemyKillCounts': <String, int>{},
      });

  test('the cove camp asks for one quest, and the sail waits on it', () {
    expect(loop.questGoal, 1);
    expect(open({'banner_five'}, const []), isFalse);
  });

  for (final entry in visits.entries) {
    final id = entry.key;
    final (stem, laterFlag) = entry.value;
    test('$id: offered, followed up, finished, turned in, sail opens', () {
      final flags = <String>{'banner_five'};
      // A save with none of the three met: the opener is offered.
      expect(hub(flags), contains('7400_$stem'));
      expect(hub(flags), isNot(contains('7400_${stem}_later')));
      final first = story.nodeFor('7400_$stem')!.choices.single;
      expect(first.nextId, '7400');
      expect(first.unlockQuestId, id);
      flags.addAll(first.flagsToAdd);
      // Back at the hub: the opener is gone, the follow-up is there.
      expect(hub(flags), isNot(contains('7400_$stem')));
      expect(hub(flags), contains('7400_${stem}_later'));
      expect(questGoalFor(id, quests[id], save(flags, id)).ready, isFalse,
          reason: 'not finished before the follow-up');
      final later = story.nodeFor('7400_${stem}_later')!.choices.single;
      expect(later.flagsToAdd, contains(laterFlag));
      flags.addAll(later.flagsToAdd);
      expect(hub(flags), isNot(contains('7400_${stem}_later')));
      expect(questGoalFor(id, quests[id], save(flags, id)).ready, isTrue);
      // The sail is still shut until the quest is turned in...
      expect(open(flags, const []), isFalse);
      // ...and opens once it is.
      expect(open(flags, [id]), isTrue);
    });
  }

  test('a quest of another chapter does not open the sail', () {
    expect(open({'banner_five'}, ['q_ch6_faces_of_the_fallen']), isFalse);
  });

  test('a save that took the Lantern Throne already is not shut out', () {
    // q_ch7_lantern_throne is a chapter 7 quest: turned in, it meets the goal.
    expect(open({'banner_five'}, ['q_ch7_lantern_throne']), isTrue);
  });

  test('the hub holds at most 7 choices, and the sail is the last', () {
    final choices = story.nodeFor('7400')!.choices;
    expect(choices.length, lessThanOrEqualTo(7));
    expect(choices.last.mainQuest, isTrue);
  });

  test('each turn-in flag has a gate line at Candlehold, in both languages',
      () {
    final lines = {
      for (final c in story.nodeFor('7500')!.flagCallbacks) c.flag: c,
    };
    for (final id in visits.keys) {
      final turnIns = quests[id]['turnInChoices'] as List;
      expect(turnIns.length, 2, reason: id);
      for (final t in turnIns) {
        final flag = (t as Map)['flag'] as String;
        expect(lines, contains(flag), reason: '$id: $flag has no gate line');
        expect(lines[flag]!.line.en.trim(), isNotEmpty);
        expect((lines[flag]!.line.fr ?? '').trim(), isNotEmpty);
      }
    }
  });
}
