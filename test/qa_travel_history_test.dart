// QA: the travel-history map's data (travel_history.dart) on real story
// walks. It reads only the story's own record, so every save already holds
// what it needs: an early save, one in chapter 5, one at an ending, an empty
// history and a history with scenes the story no longer has must all build
// without throwing, and what it builds must hold together.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/chapter_loop.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/models/story_node.dart';

void main() {
  final dag =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final story = StoryData({
    for (final e in dag.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });

  /// A walk from the first scene along random choices, up to [steps] scenes
  /// or the end of the story: what a save's history is.
  List<String> walk(int seed, int steps) {
    final random = Random(seed);
    final path = <String>[StoryRepository.startNodeId];
    while (path.length < steps) {
      final node = story.nodeFor(path.last)!;
      final next = [
        for (final c in node.choices)
          if (story.nodeFor(c.nextId) != null) c.nextId,
      ];
      if (next.isEmpty) break;
      path.add(next[random.nextInt(next.length)]);
    }
    return path;
  }

  void check(TravelHistory t, {required String label}) {
    expect({for (final s in t.stops) s.landmarkId}.length, t.stops.length,
        reason: '$label: a place reached twice in stops');
    expect(t.heardOf.intersection(t.visited), isEmpty, reason: label);
    for (final s in t.stops) {
      expect(t.visited, contains(s.landmarkId), reason: label);
      expect(landmarkById(s.landmarkId), isNotNull, reason: label);
    }
    for (final l in t.legs) {
      expect(l.fromId, isNot(l.toId), reason: '$label: a leg to itself');
      expect(landmarkById(l.fromId), isNotNull, reason: label);
      expect(landmarkById(l.toId), isNotNull, reason: label);
    }
    if (t.currentId != null) {
      expect(landmarkById(t.currentId!), isNotNull, reason: label);
    }
    for (final id in [...t.visited, ...t.heardOf]) {
      expect(t.shows(id), isTrue, reason: label);
    }
    for (final e in t.travelTargets.entries) {
      expect(t.visited, contains(e.key), reason: '$label: ${e.key}');
      final place = story.nodeFor(e.value);
      expect(place, isNotNull, reason: '$label: target ${e.value} missing');
      expect(place!.settlement, isNotNull, reason: e.value);
    }
  }

  test('an empty history, and one with scenes the story no longer has', () {
    final empty = travelHistoryOf(history: const [], currentNodeId: '0');
    check(empty, label: 'empty');
    expect(empty.legs, isEmpty);
    // A save written before a scene was renamed or removed.
    final stale = travelHistoryOf(
        history: const ['0', 'gone_scene', '1100', ''],
        currentNodeId: 'also_gone',
        visitedNodeIds: const ['gone_scene', '1100']);
    check(stale, label: 'stale');
    expect(
        travelHistoryOf(history: const [], currentNodeId: '').stops, isEmpty);
  });

  test('walks of every length build, early, in chapter 5 and at an ending', () {
    var longest = 0;
    for (var seed = 0; seed < 40; seed++) {
      for (final steps in [3, 12, 60, 250, 4000]) {
        final path = walk(seed, steps);
        longest = max(longest, path.length);
        final t = travelHistoryOf(
          history: path.sublist(0, path.length - 1),
          currentNodeId: path.last,
          visitedNodeIds: path,
          knownPlaces: knownPlaces(story, chapter: 8, flags: const []),
        );
        check(t, label: 'seed $seed, $steps steps');
      }
    }
    expect(longest, greaterThan(100), reason: 'walks should get far');
  });

  test('the whole story at once: every scene read, every place known', () {
    final all = story.nodes.keys.toList();
    final stopwatch = Stopwatch()..start();
    final t = travelHistoryOf(
      history: all.sublist(0, all.length - 1),
      currentNodeId: all.last,
      visitedNodeIds: all,
      knownPlaces: knownPlaces(story, chapter: 8, flags: const []),
    );
    check(t, label: 'everything');
    expect(stopwatch.elapsedMilliseconds, lessThan(2000),
        reason: 'the provider rebuilds at every scene');
    // Everything reached: nothing left to hear of.
    expect(t.heardOf, isEmpty);
  });

  test('every place the camp can travel to maps to a landmark and a node', () {
    final places = knownPlaces(story, chapter: 8, flags: const []);
    final t = travelHistoryOf(
      history: const [],
      currentNodeId: '0',
      visitedNodeIds: story.nodes.keys,
      knownPlaces: places,
    );
    final unmapped = [
      for (final p in places)
        if (landmarkOfScene(p.id) == null &&
            landmarkOfScene(p.settlement?.arrivalNodeId ?? '') == null)
          p.id,
    ];
    expect(unmapped, isEmpty, reason: 'places off the map: $unmapped');
    check(t, label: 'targets');
  });

  test('the story chart is not one of the looks, and has every landmark', () {
    expect(mapLookShapes, isNot(contains(MapShape.story)));
    expect(mapLookShapes.length, MapShape.values.length - 1);
    final chart = chartOf(MapShape.story);
    for (final l in worldMapLandmarks) {
      expect(chart.places[l.id], isNotNull, reason: l.id);
    }
  });
}
