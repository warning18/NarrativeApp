// The open chapters (3 to 6, then the Ending): each stands at the camp,
// finds its places through expeditions, counts what the party has done in
// them, and opens its main quest once enough of it is done.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/chapter_loop.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _loadJson(String relative) {
  for (final path in [relative, '../$relative']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find $relative');
}

void main() {
  final dag = _loadJson('assets/Cleaned_Narrative_DAG.json');
  final story = StoryData({
    for (final entry in dag.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  });
  final zones = _loadJson('assets/gamedata/zones.json');
  final loops = chapterLoopsFrom(_loadJson('assets/gamedata/chapters.json'));
  ChapterLoop loop(int chapter) =>
      loops.firstWhere((l) => l.chapter == chapter);

  test('five loops, in order, each at a camp with a main quest', () {
    // Eight things done in a chapter before its main quest; the Ending has
    // no goal.
    expect(loops.where((l) => l.chapter < 7).map((l) => l.activityGoal),
        everyElement(8));
    expect(loops.map((l) => l.chapter), [3, 4, 5, 6, 7]);
    for (final l in loops) {
      final camp = story.nodeFor(l.campNodeId);
      expect(camp, isNotNull, reason: l.id);
      expect(camp!.settlement?.isCamp, isTrue, reason: l.id);
      expect(camp.settlement!.chapter, l.chapter, reason: l.id);
      expect(camp.choices.where((c) => c.mainQuest), isNotEmpty,
          reason: '${l.id}: its main quest');
      expect(l.mainQuestTitle, isNotEmpty, reason: l.id);
      for (final id in l.mainQuestNeedsPlaceIds) {
        expect(story.nodeFor(id)?.settlement?.chapter, l.chapter,
            reason: '${l.id} needs $id');
      }
    }
    expect(loop(7).activityGoal, 0);
  });

  test('the camp the story comes back to is the last one it stood at', () {
    expect(
        currentCampNodeId(
            currentNodeId: '3005', history: const ['3001'], loops: loops),
        isNull);
    expect(
        currentCampNodeId(
            currentNodeId: '3005',
            history: const ['3001', '3001_camp', '3100'],
            loops: loops),
        '3001_camp');
    expect(
        currentCampNodeId(
            currentNodeId: '4999_camp',
            history: const ['3001_camp', '3005'],
            loops: loops),
        '4999_camp');
    expect(
        currentLoop(
                currentNodeId: '5100',
                history: const ['3001_camp', '4999_camp'],
                loops: loops)
            ?.chapter,
        4);
  });

  test('a scene\'s chapter: its place\'s, else its spine\'s', () {
    expect(storyChapterOf('3100', story), 3);
    expect(storyChapterOf('7100', story), 6);
    expect(storyChapterOf('7400', story), 7);
    expect(storyChapterOf('5003', story), 4);
    expect(
        reachedChapter(
            currentNodeId: '3005',
            history: const ['3001_camp'],
            loops: loops,
            story: story),
        3);
  });

  test('places are known once found, and only from their chapter', () {
    Set<String> known(int chapter, List<String> flags) => {
          for (final p in knownPlaces(story, chapter: chapter, flags: flags))
            p.id,
        };
    expect(known(3, const []), isEmpty);
    expect(known(3, [placeFoundFlag('3005')]), {'3005'});
    // A later chapter's place is never known early, found or not.
    expect(known(3, [placeFoundFlag('5010')]), isEmpty);
    expect(known(4, [placeFoundFlag('3005'), placeFoundFlag('5010')]),
        {'3005', '5010'});
    // The Hollow Shore is where the sixth chapter lands: known from the
    // start of it.
    expect(known(6, const []), contains('7002'));
  });

  test('every place is found by an expedition of its chapter', () {
    final found = <String, int>{};
    for (final entry in zones.entries) {
      final zone = entry.value as Map<String, dynamic>;
      for (final id in zoneDiscoveries(zone)) {
        found[id] = (zone['chapter'] as num?)?.toInt() ?? 1;
      }
    }
    for (final place in loopPlaces(story)) {
      if (!place.settlement!.mustDiscover) continue;
      expect(found[place.id], place.settlement!.chapter, reason: place.id);
    }
  });

  test('an expedition finds its first place halfway, the rest at the end', () {
    final ossuary = zones['z_ossuary_galleries'] as Map<String, dynamic>;
    expect(zoneDiscoveriesAt(ossuary, atEnd: false), ['5100']);
    expect(zoneDiscoveriesAt(ossuary, atEnd: true), ['5100', '5010']);
    expect(zoneDiscoveriesAt(const {}, atEnd: true), isEmpty);
  });

  test('a place counts its own activities', () {
    final village = story.nodeFor('3100')!;
    expect(placeActivityMarkers(village), contains('hub_3100_kiln'));
    final progress =
        placeProgress(village, const ['hub_3100_kiln', 'hub_3005_oath']);
    expect(progress.done, 1);
    expect(progress.total, placeActivityMarkers(village).length);
  });

  test('the main quest opens with the goal met and its place visited', () {
    final ch3 = loop(3);
    int count(List<String> flags, List<String> zonesDone) =>
        chapterActivityCount(
          story: story,
          chapter: 3,
          flags: flags,
          completedZoneIds: zonesDone,
          zones: zones,
        );
    // What was done in another chapter's places and expeditions never
    // counts toward this one.
    expect(count(const ['hub_5010_ghouls'], const ['z_ossuary_galleries']), 0);
    final flags = [
      placeFoundFlag('3005'),
      'hub_3005_oath',
      'hub_3005_wisp',
      'hub_3005_acolyte',
      'hub_3005_relic',
      'hub_3100_kiln',
      'hub_3100_bread',
    ];
    final done = count(flags, const ['z_cinder_row', 'z_scaffold_yards']);
    expect(done, 8);
    expect(ch3.activityGoal, 8);
    expect(ch3.questGoal, 2);
    bool open(Iterable<String> visited, {int quests = 2}) => mainQuestOpen(
        loop: ch3,
        story: story,
        activityCount: done,
        questCount: quests,
        flags: flags,
        visitedNodeIds: visited);
    expect(open(const []), isFalse);
    expect(missingMainQuestPlaces(ch3, story, flags, visitedNodeIds: const []),
        ['3005']);
    expect(open(const ['3005']), isTrue);
    // The Quarter will not show a stranger the way to the Spire before the
    // party has done something for it.
    expect(open(const ['3005'], quests: 1), isFalse);
    expect(
        mainQuestOpen(
            loop: ch3,
            story: story,
            activityCount: 7,
            questCount: 2,
            flags: flags,
            visitedNodeIds: const ['3005']),
        isFalse);
  });

  group('quests before the main quest', () {
    final quests = _loadJson('assets/gamedata/quests.json');

    test('only the chapter\'s own completed quests count', () {
      int count(List<String> done) => chapterQuestCount(
          chapter: 3, quests: quests, completedQuestIds: done);
      expect(count(const []), 0);
      expect(count(const ['q_ch3_ashen_oath', 'q_ch3_void_relic']), 2);
      expect(count(const ['q_ch3_ashen_oath', 'q_ch3_ashen_oath']), 1);
      expect(count(const ['q_ch2_dockside_debts', 'q_ch4_ossuary_bounty']), 0);
      expect(count(const ['q_unknown']), 0);
    });

    test('each chapter offers enough quests before its main quest', () {
      // The quests a party can finish before the main quest (the rest open
      // with it, or end at its boss).
      const before = {
        3: [
          'q_ch3_ashen_oath',
          'q_ch3_void_relic',
          'q_ch3_inquisition_ledger',
          'q_ch3_reckoning_wall',
        ],
        4: ['q_ch4_ossuary_bounty'],
        5: ['q_ch5_penitents_confession'],
        6: ['q_ch6_faces_of_the_fallen'],
      };
      expect(loops.map((l) => l.questGoal), [2, 1, 1, 1, 0]);
      for (final l in loops.where((l) => l.questGoal > 0)) {
        final ids = before[l.chapter]!;
        expect(ids.length, greaterThanOrEqualTo(l.questGoal), reason: l.id);
        for (final id in ids) {
          expect((quests[id] as Map)['chapter'], l.chapter, reason: id);
          // Offered by a scene of the chapter, not by its main quest.
          final offers = [
            for (final nodeId in dag.keys)
              for (final c in story.nodeFor(nodeId)!.choices)
                if (c.unlockQuestId == id) (nodeId, c),
          ];
          expect(offers, isNotEmpty, reason: id);
          for (final (nodeId, c) in offers) {
            expect(c.mainQuest, isFalse, reason: '$nodeId offers $id');
            expect(storyChapterOf(nodeId, story), l.chapter,
                reason: '$nodeId offers $id');
          }
        }
      }
    });
  });

  group('companions to meet', () {
    final quests = _loadJson('assets/gamedata/quests.json');
    List<String> leads(
      String placeId, {
      List<String> flags = const [],
      int alignment = 0,
      List<String> met = const [],
    }) =>
        placeCompanionLeads(story.nodeFor(placeId)!, story, quests,
            flags: flags,
            alignmentScore: alignment,
            charisma: 0,
            unavailableAllyIds: met);

    test('a town says who can still join, a village nobody', () {
      // Grosh asks for gold, which comes: he is on offer. Maren waits for
      // Lysa to have lived.
      expect(leads('3005'), ['grosh']);
      expect(leads('3005', flags: const ['lysa_survived']),
          containsAll(['maren', 'grosh']));
      expect(leads('3100'), isEmpty);
    });

    test('once met, or once the scene is done, no more word', () {
      expect(leads('3005', met: const ['grosh']), isEmpty);
      expect(leads('3005', flags: const ['hub_3005_grosh']), isEmpty);
    });

    test('a companion the party\'s alignment rules out is not hinted', () {
      expect(leads('5010'), isEmpty);
      expect(leads('5010', alignment: 25), ['tobin']);
      expect(leads('6010'), isEmpty);
      expect(leads('6010', alignment: -25), ['malrik']);
    });
  });

  test('a first trip to the Quarter goes through its gate', () {
    final quarter = story.nodeFor('6010')!;
    expect(arrivalNodeFor(quarter, const []), '6010_gate');
    expect(arrivalNodeFor(quarter, const ['6010_gate']), '6010');
    expect(arrivalNodeFor(story.nodeFor('3005')!, const []), '3005');
  });
}
