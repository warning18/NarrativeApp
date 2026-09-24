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
    // flags gating it. That gap let node "151_vess" (Vess's questline) go
    // permanently unreachable in a real content pass: it requires
    // "void_marked", which only "281_scarred" (reached by *failing* the
    // luck check at node "280") ever sets, but the old graph routed that
    // failure straight past the market stall that leads to 151_vess. This
    // walks every path from the start node tracking which flags are set
    // along the way, so a future edit that breaks this link again fails
    // loudly instead of silently stranding the content.
    late Map<String, StoryNode> nodes;

    setUpAll(() async {
      nodes = await _loadStoryNodes();
    });

    test('151_vess is reachable on some path that has set void_marked', () {
      final seenStates = <String>{};
      final queue = Queue<MapEntry<String, Set<String>>>()
        ..add(const MapEntry(StoryRepository.startNodeId, {}));
      var reachedWithMark = false;

      while (queue.isNotEmpty) {
        final entry = queue.removeFirst();
        final nodeId = entry.key;
        final flags = entry.value;
        final stateKey = '$nodeId|${(flags.toList()..sort()).join(',')}';
        if (!seenStates.add(stateKey)) continue;

        if (nodeId == '151_vess' && flags.contains('void_marked')) {
          reachedWithMark = true;
          break;
        }

        final node = nodes[nodeId];
        if (node == null) continue;
        for (final choice in node.choices) {
          final next = choice.nextId;
          if (next != 'EXIT' && next != 'END' && nodes.containsKey(next)) {
            queue.add(MapEntry(next, {...flags, ...choice.flagsToAdd}));
          }
          final fail = choice.failNextId;
          if (fail != null &&
              fail.isNotEmpty &&
              fail != 'EXIT' &&
              fail != 'END' &&
              nodes.containsKey(fail)) {
            // A failed check never applies this choice's own flagsToAdd.
            queue.add(MapEntry(fail, flags));
          }
        }
      }

      expect(reachedWithMark, isTrue,
          reason: '151_vess requires void_marked, but no path from the '
              'start node ever reaches it with that flag set -- the Vess '
              'questline is stranded.');
    });
  });
}
