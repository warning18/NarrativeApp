// Structural audit of the shipped story graph, run automatically on every
// change instead of relying on someone remembering to re-run the manual
// "20 playthroughs plus an exhaustive BFS" sweep this project's commit
// history describes doing by hand after content passes.
//
// This walks assets/Cleaned_Narrative_DAG.json exactly as
// story_graph_integrity.dart does at runtime: every choice followed
// regardless of whether a real player could currently satisfy its
// requirements, so it catches orphaned nodes, dead ends, and broken
// next_id links a gated playthrough sample could easily miss.

import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_graph_integrity.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

Future<Map<String, StoryNode>> _loadStoryNodes() async {
  final raw = await rootBundle.loadString(StoryRepository.assetPath);
  final decoded = json.decode(raw) as Map<String, dynamic>;
  return {
    for (final entry in decoded.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('story graph integrity', () {
    late Map<String, StoryNode> nodes;

    setUpAll(() async {
      nodes = await _loadStoryNodes();
    });

    test('every node is reachable from the start node', () async {
      final report = checkStoryGraphIntegrity(nodes,
          startNodeId: StoryRepository.startNodeId);
      expect(
        report.unreachableNodeIds,
        isEmpty,
        reason:
            'Orphaned nodes no choice can ever reach: ${report.unreachableNodeIds}',
      );
    });

    test('no node is a dead end', () async {
      final report = checkStoryGraphIntegrity(nodes,
          startNodeId: StoryRepository.startNodeId);
      expect(
        report.deadEndNodeIds,
        isEmpty,
        reason: 'Nodes with nowhere left to go: ${report.deadEndNodeIds}',
      );
    });

    test('every choice points at a real node or an EXIT/END marker', () async {
      final report = checkStoryGraphIntegrity(nodes,
          startNodeId: StoryRepository.startNodeId);
      expect(
        report.brokenReferences,
        isEmpty,
        reason: 'Broken next_id links:\n${report.brokenReferences.join('\n')}',
      );
    });

    test('at least one reachable node can actually end the story', () async {
      final report = checkStoryGraphIntegrity(nodes,
          startNodeId: StoryRepository.startNodeId);
      expect(
        report.reachableEndingCount,
        greaterThan(0),
        reason: 'No path from the start node ever reaches an EXIT/END choice — '
            'every playthrough would loop or hit the simulator\'s step cap.',
      );
    });

    test('overall report is clean', () async {
      final report = checkStoryGraphIntegrity(nodes,
          startNodeId: StoryRepository.startNodeId);
      expect(report.isClean, isTrue);
    });
  });

  group('loseNextId traversal (synthetic graph)', () {
    test('a node reachable only via a lost fight is not flagged orphaned', () {
      final nodes = {
        '0': const StoryNode(
          id: '0',
          description: 'start',
          choices: [
            StoryChoice(
              text: 'Fight',
              nextId: 'won',
              triggerEnemyId: 'harbor_rat',
              loseNextId: 'lost',
            ),
          ],
        ),
        'won': const StoryNode(
          id: 'won',
          description: 'they fall',
          choices: [StoryChoice(text: 'End', nextId: 'EXIT')],
        ),
        'lost': const StoryNode(
          id: 'lost',
          description: 'you are taken',
          choices: [StoryChoice(text: 'End', nextId: 'EXIT')],
        ),
      };
      final report = checkStoryGraphIntegrity(nodes, startNodeId: '0');
      expect(report.unreachableNodeIds, isEmpty);
      expect(report.brokenReferences, isEmpty);
    });

    test('a loseNextId pointing nowhere is reported as a broken reference', () {
      final nodes = {
        '0': const StoryNode(
          id: '0',
          description: 'start',
          choices: [
            StoryChoice(
              text: 'Fight',
              nextId: 'won',
              triggerEnemyId: 'harbor_rat',
              loseNextId: 'does_not_exist',
            ),
          ],
        ),
        'won': const StoryNode(
          id: 'won',
          description: 'they fall',
          choices: [StoryChoice(text: 'End', nextId: 'EXIT')],
        ),
      };
      final report = checkStoryGraphIntegrity(nodes, startNodeId: '0');
      expect(report.brokenReferences.map((b) => b.targetId),
          contains('does_not_exist'));
      expect(report.brokenReferences.single.choiceText, contains('loseNextId'));
    });

    test('loseNextId round-trips through JSON and stays out of it when empty',
        () {
      const choice = StoryChoice(
          text: 'Fight', nextId: '1', triggerEnemyId: 'x', loseNextId: 'lost');
      expect(choice.hasLossBranch, isTrue);
      final restored = StoryChoice.fromJson(choice.toJson());
      expect(restored.loseNextId, 'lost');
      const plain = StoryChoice(text: 'Go', nextId: '1');
      expect(plain.hasLossBranch, isFalse);
      expect(plain.toJson().containsKey('loseNextId'), isFalse);
    });
  });

  group('failNextId traversal (synthetic graph)', () {
    test('a node reachable only via a check failure is not flagged orphaned',
        () {
      final nodes = {
        '0': const StoryNode(
          id: '0',
          description: 'start',
          choices: [
            StoryChoice(
              text: 'Try the lock',
              nextId: 'success',
              checkAbility: 'dexterity',
              checkDC: 12,
              failNextId: 'failure',
            ),
          ],
        ),
        'success': const StoryNode(
          id: 'success',
          description: 'it opens',
          choices: [StoryChoice(text: 'End', nextId: 'EXIT')],
        ),
        'failure': const StoryNode(
          id: 'failure',
          description: 'it jams',
          choices: [StoryChoice(text: 'End', nextId: 'EXIT')],
        ),
      };
      final report = checkStoryGraphIntegrity(nodes, startNodeId: '0');
      expect(report.unreachableNodeIds, isEmpty);
      expect(report.brokenReferences, isEmpty);
    });

    test('a failNextId pointing nowhere is reported as a broken reference', () {
      final nodes = {
        '0': const StoryNode(
          id: '0',
          description: 'start',
          choices: [
            StoryChoice(
              text: 'Try the lock',
              nextId: 'success',
              checkAbility: 'dexterity',
              checkDC: 12,
              failNextId: 'does_not_exist',
            ),
          ],
        ),
        'success': const StoryNode(
          id: 'success',
          description: 'it opens',
          choices: [StoryChoice(text: 'End', nextId: 'EXIT')],
        ),
      };
      final report = checkStoryGraphIntegrity(nodes, startNodeId: '0');
      expect(report.brokenReferences, hasLength(1));
      expect(report.brokenReferences.single.targetId, 'does_not_exist');
    });

    test('a failNextId of EXIT is not treated as a broken reference', () {
      final nodes = {
        '0': const StoryNode(
          id: '0',
          description: 'start',
          choices: [
            StoryChoice(
              text: 'Try the lock',
              nextId: 'success',
              checkAbility: 'dexterity',
              checkDC: 12,
              failNextId: 'EXIT',
            ),
          ],
        ),
        'success': const StoryNode(
          id: 'success',
          description: 'it opens',
          choices: [StoryChoice(text: 'End', nextId: 'EXIT')],
        ),
      };
      final report = checkStoryGraphIntegrity(nodes, startNodeId: '0');
      expect(report.brokenReferences, isEmpty);
    });
  });

  group('flag-gated reachability (regression)', () {
    // checkStoryGraphIntegrity deliberately ignores reqFlags/reqGold/
    // reqAlignment gating (see its doc comment) -- it only proves a node is
    // reachable at all, not that some real path actually satisfies the
    // flags gating it. That gap once let Vess's first scene go permanently
    // unreachable in a real content pass: it requires "void_marked", which
    // only failing the luck check at the tear ever sets, and the graph
    // routed that failure straight past the scene. Since v1.196 the tear
    // hangs over the wreck in the Waste (1100) and Vess waits at the White
    // Wells (1210). This walks every path from the start node tracking
    // whether the mark has been set along the way (only that flag: the
    // full flag sets of the casino's chains make the walk explode), so a
    // future edit that breaks this link again fails loudly instead of
    // silently stranding the content.
    late Map<String, StoryNode> nodes;

    setUpAll(() async {
      nodes = await _loadStoryNodes();
    });

    test('Vess at the Wells is reachable on a path that set void_marked', () {
      const target = '1210';
      const mark = 'void_marked';
      expect(nodes[target]!.reqFlags, [mark]);
      final seenStates = <String>{};
      final queue = Queue<MapEntry<String, bool>>()
        ..add(const MapEntry(StoryRepository.startNodeId, false));
      var reachedWithMark = false;

      while (queue.isNotEmpty) {
        final entry = queue.removeFirst();
        final nodeId = entry.key;
        final marked = entry.value;
        if (!seenStates.add('$nodeId|$marked')) continue;

        if (nodeId == target && marked) {
          reachedWithMark = true;
          break;
        }

        final node = nodes[nodeId];
        if (node == null) continue;
        for (final choice in node.choices) {
          // A choice hidden until the mark is held waits for it.
          if (choice.showIfFlags.contains(mark) && !marked) continue;
          final next = choice.nextId;
          if (next != 'EXIT' && next != 'END' && nodes.containsKey(next)) {
            queue.add(
                MapEntry(next, marked || choice.flagsToAdd.contains(mark)));
          }
          final fail = choice.failNextId;
          if (fail != null &&
              fail.isNotEmpty &&
              fail != 'EXIT' &&
              fail != 'END' &&
              nodes.containsKey(fail)) {
            // A failed check never applies this choice's own flagsToAdd.
            queue.add(MapEntry(fail, marked));
          }
        }
      }

      expect(reachedWithMark, isTrue,
          reason: '$target requires $mark, but no path from the start node '
              'ever reaches it with that flag set -- the Vess questline is '
              'stranded.');
    });
  });
}
