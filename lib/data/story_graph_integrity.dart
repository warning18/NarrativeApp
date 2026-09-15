import 'dart:collection';

import '../models/story_node.dart';

/// One choice whose `next_id` doesn't resolve to a real node and isn't an
/// EXIT/END marker — a broken link a player could actually hit mid-story.
class BrokenReference {
  const BrokenReference({
    required this.fromNodeId,
    required this.choiceText,
    required this.targetId,
  });

  final String fromNodeId;
  final String choiceText;
  final String targetId;

  @override
  String toString() =>
      '$fromNodeId -> "$choiceText" -> "$targetId" (no such node)';
}

/// Result of a structural audit of the story graph: every choice followed
/// exactly as authored, ignoring reqGold/reqAlignment/reqFlags gating — the
/// same "assume every choice is available" sweep this project has run by
/// hand after content changes to catch dead-ends and orphaned nodes.
class StoryGraphReport {
  const StoryGraphReport({
    required this.unreachableNodeIds,
    required this.deadEndNodeIds,
    required this.brokenReferences,
    required this.reachableEndingCount,
  });

  /// Nodes no path from the start node ever reaches.
  final List<String> unreachableNodeIds;

  /// Reachable nodes with no way to move the story forward: no choices at
  /// all, or every choice is either broken or points nowhere.
  final List<String> deadEndNodeIds;

  /// Choices pointing at an id that isn't a node and isn't EXIT/END.
  final List<BrokenReference> brokenReferences;

  /// How many distinct reachable nodes offer a choice that actually ends
  /// the story (`next_id` of EXIT/END). Zero means no playthrough can ever
  /// conclude — every run would loop or hit the simulator's step cap.
  final int reachableEndingCount;

  bool get isClean =>
      unreachableNodeIds.isEmpty &&
      deadEndNodeIds.isEmpty &&
      brokenReferences.isEmpty &&
      reachableEndingCount > 0;
}

/// Walks every choice reachable from [startNodeId], regardless of whether a
/// real player could currently satisfy its requirements, to find:
///  - nodes nothing can ever reach (orphaned content),
///  - nodes with nowhere left to go (dead ends), and
///  - choices whose `next_id` doesn't resolve to a real node (broken links).
///
/// This is the exhaustive, gating-blind BFS this project's commit history
/// describes running manually before/after content passes — codified so it
/// runs on every change instead of only when someone remembers to do it.
StoryGraphReport checkStoryGraphIntegrity(
  Map<String, StoryNode> nodes, {
  String startNodeId = '0',
}) {
  final visited = <String>{};
  final queue = Queue<String>();
  if (nodes.containsKey(startNodeId)) queue.add(startNodeId);
  final brokenReferences = <BrokenReference>[];
  final deadEndNodeIds = <String>[];
  var reachableEndingCount = 0;

  while (queue.isNotEmpty) {
    final id = queue.removeFirst();
    if (!visited.add(id)) continue;
    final node = nodes[id]!;

    var hasEnding = false;
    var hasForwardPath = false;
    for (final choice in node.choices) {
      if (choice.isEnding) {
        hasEnding = true;
        hasForwardPath = true;
        continue;
      }
      // Empty next_id is only meaningful on procedurally generated excursion
      // nodes (see SubNodeEngine), never on the authored static graph; treat
      // it as "not this check's concern" rather than a broken link.
      if (choice.nextId.isEmpty) {
        hasForwardPath = true;
        continue;
      }
      if (!nodes.containsKey(choice.nextId)) {
        brokenReferences.add(BrokenReference(
          fromNodeId: id,
          choiceText: choice.text,
          targetId: choice.nextId,
        ));
        continue;
      }
      hasForwardPath = true;
      if (!visited.contains(choice.nextId)) queue.add(choice.nextId);
    }

    if (hasEnding) reachableEndingCount++;
    if (!hasForwardPath) deadEndNodeIds.add(id);
  }

  final unreachableNodeIds = [
    for (final id in nodes.keys)
      if (!visited.contains(id)) id,
  ]..sort();

  return StoryGraphReport(
    unreachableNodeIds: unreachableNodeIds,
    deadEndNodeIds: deadEndNodeIds..sort(),
    brokenReferences: brokenReferences,
    reachableEndingCount: reachableEndingCount,
  );
}
