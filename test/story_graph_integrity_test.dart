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
      entry.key: StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
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
      final report = checkStoryGraphIntegrity(nodes, startNodeId: StoryRepository.startNodeId);
      expect(
        report.unreachableNodeIds,
        isEmpty,
        reason: 'Orphaned nodes no choice can ever reach: ${report.unreachableNodeIds}',
      );
    });

    test('no node is a dead end', () async {
      final report = checkStoryGraphIntegrity(nodes, startNodeId: StoryRepository.startNodeId);
      expect(
        report.deadEndNodeIds,
        isEmpty,
        reason: 'Nodes with nowhere left to go: ${report.deadEndNodeIds}',
      );
    });

    test('every choice points at a real node or an EXIT/END marker', () async {
      final report = checkStoryGraphIntegrity(nodes, startNodeId: StoryRepository.startNodeId);
      expect(
        report.brokenReferences,
        isEmpty,
        reason: 'Broken next_id links:\n${report.brokenReferences.join('\n')}',
      );
    });

    test('at least one reachable node can actually end the story', () async {
      final report = checkStoryGraphIntegrity(nodes, startNodeId: StoryRepository.startNodeId);
      expect(
        report.reachableEndingCount,
        greaterThan(0),
        reason: 'No path from the start node ever reaches an EXIT/END choice — '
            'every playthrough would loop or hit the simulator\'s step cap.',
      );
    });

    test('overall report is clean', () async {
      final report = checkStoryGraphIntegrity(nodes, startNodeId: StoryRepository.startNodeId);
      expect(report.isClean, isTrue);
    });
  });
}
