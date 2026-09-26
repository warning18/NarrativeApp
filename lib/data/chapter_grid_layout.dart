import 'dart:collection';

import '../data/story_repository.dart';
import '../models/story_node.dart';

/// Which chapter a node id belongs to, by its numeric id prefix — mirrors
/// the boundaries used throughout the codebase (e.g. the playthrough
/// simulator's chapter buckets): 0 = prologue, 1 = <2000, 2 = <3000,
/// 3 = <5000, 4 = <6000, 5 = <7000, 6 = everything else. Non-numeric ids (companion
/// recruit bridge nodes like "2015_kelda", flag variants like
/// "6001_seeker") still start with their parent's numeric id, so the
/// leading-digits match handles them the same way.
int chapterOfNode(String nodeId) {
  final match = RegExp(r'^(\d+)').firstMatch(nodeId);
  if (match == null) return 0;
  final n = int.parse(match.group(1)!);
  if (n == 0) return 0;
  if (n < 2000) return 1;
  if (n < 3000) return 2;
  if (n < 5000) return 3;
  if (n < 6000) return 4;
  if (n < 7000) return 5;
  return 6;
}

/// Each chapter's own BFS root(s) for column assignment — the same first
/// main beat(s) `chapter_spine.dart` defines, duplicated narrowly here
/// (just the ids, not the full spine) so this file has no dependency on
/// that one's shape.
const Map<int, Set<String>> _chapterRoots = {
  0: {'0'},
  1: {'100'},
  2: {'2001'},
  3: {'3001'},
  4: {'5003'},
  5: {'6001'},
  6: {'7001'},
};

/// A node's position on its chapter's own grid: [column] is how many hops
/// (via same-chapter edges) it sits from that chapter's opening beat;
/// [row] is its slot within that column, 0-based and always < the grid's
/// max-per-column cap.
class GridSlot {
  const GridSlot(
      {required this.chapter, required this.column, required this.row});

  final int chapter;
  final int column;
  final int row;
}

/// Buckets every node in [story] into a (chapter, column, row) grid slot,
/// capping each column at [maxPerColumn] nodes: column = BFS depth from
/// that chapter's opening beat (following only edges that stay within the
/// same chapter, so one chapter's branching never bleeds into another's
/// column numbering), split into extra columns whenever a depth level
/// would otherwise overflow the cap. A node with no path back to its
/// chapter's root (a back-reference, a disconnected fragment) still gets
/// placed — appended past the deepest column reached so nothing is lost.
Map<String, GridSlot> computeChapterGridSlots(StoryData story,
    {int maxPerColumn = 5}) {
  final byChapter = <int, List<String>>{};
  for (final id in story.nodes.keys) {
    byChapter.putIfAbsent(chapterOfNode(id), () => []).add(id);
  }

  final adjacency = <String, List<String>>{};
  final predecessors = <String, List<String>>{};
  for (final entry in story.nodes.entries) {
    final chapter = chapterOfNode(entry.key);
    for (final choice in entry.value.choices) {
      if (choice.isEnding) continue;
      final nextId = choice.nextId;
      if (story.nodes.containsKey(nextId) && chapterOfNode(nextId) == chapter) {
        adjacency.putIfAbsent(entry.key, () => []).add(nextId);
        predecessors.putIfAbsent(nextId, () => []).add(entry.key);
      }
    }
  }

  final slots = <String, GridSlot>{};
  final chapters = byChapter.keys.toList()..sort();
  for (final chapter in chapters) {
    final nodes = byChapter[chapter]!;
    // An open chapter's places are reached by travel, not by a choice:
    // each is a root of its own (see chapter_loop.dart).
    final roots = [
      ...(_chapterRoots[chapter] ?? const <String>{}).where(nodes.contains),
      for (final id in nodes..sort())
        if (_isTravelPlace(story.nodeFor(id))) id,
    ];
    final effectiveRoots = roots.isNotEmpty ? roots : [nodes.first];

    final depth = <String, int>{};
    final queue = Queue<String>();
    for (final root in effectiveRoots) {
      depth[root] = 0;
      queue.add(root);
    }
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final next in adjacency[current] ?? const <String>[]) {
        if (!depth.containsKey(next)) {
          depth[next] = depth[current]! + 1;
          queue.add(next);
        }
      }
    }
    var maxSeen =
        depth.values.isEmpty ? 0 : depth.values.reduce((a, b) => a > b ? a : b);
    for (final id in nodes) {
      if (!depth.containsKey(id)) {
        maxSeen += 1;
        depth[id] = maxSeen;
      }
    }

    final byDepth = <int, List<String>>{};
    for (final id in nodes) {
      byDepth.putIfAbsent(depth[id]!, () => []).add(id);
    }

    // The row a node already landed on, filled in as each depth level is
    // placed (always earlier than any depth that could reference it, since
    // edges only ever point to a strictly greater depth or across chapters
    // -- both excluded from `predecessors` above).
    final placedRow = <String, int>{};

    var column = 0;
    final depths = byDepth.keys.toList()..sort();
    for (final d in depths) {
      List<String> members;
      if (d == depths.first) {
        // The opening column has no predecessors to sort by; alphabetical
        // keeps it deterministic.
        members = [...byDepth[d]!]..sort();
      } else {
        // A same-depth-level cluster fanning out from (or converging back
        // into) a shared parent reads as a tangle of crossing lines if its
        // members are ordered alphabetically, since that has nothing to do
        // with where their edges actually land. Ordering by the average
        // row of each node's already-placed predecessors (a single-pass
        // barycenter heuristic) keeps a predecessor's fan-out roughly
        // aligned with it instead, which is what actually cuts down on
        // crossings for the diamond-shaped branch/rejoin patterns this
        // story graph is full of.
        double barycenter(String id) {
          final rows = (predecessors[id] ?? const [])
              .map((p) => placedRow[p])
              .whereType<int>()
              .toList();
          if (rows.isEmpty) return double.infinity;
          return rows.reduce((a, b) => a + b) / rows.length;
        }

        members = [...byDepth[d]!]..sort((a, b) {
            final cmp = barycenter(a).compareTo(barycenter(b));
            return cmp != 0 ? cmp : a.compareTo(b);
          });
      }
      for (var i = 0; i < members.length; i += maxPerColumn) {
        final chunk = members.skip(i).take(maxPerColumn).toList();
        for (var row = 0; row < chunk.length; row++) {
          slots[chunk[row]] =
              GridSlot(chapter: chapter, column: column, row: row);
          placedRow[chunk[row]] = row;
        }
        column += 1;
      }
    }
  }
  return slots;
}

/// The pixel geometry derived from a slot map: each chapter gets its own
/// vertical band (tall enough for its own deepest column, so a
/// low-branching chapter doesn't waste space matching a denser one),
/// stacked with a gap between chapters so each one visually reads as its
/// own small map, per the "chapter as its own map" brief.
class ChapterBandLayout {
  const ChapterBandLayout({
    required this.bandStartY,
    required this.maxColumn,
    required this.totalHeight,
  });

  final Map<int, double> bandStartY;
  final int maxColumn;
  final double totalHeight;
}

ChapterBandLayout computeChapterBandLayout(
  Map<String, GridSlot> slots, {
  double rowHeight = 64,
  double chapterGap = 90,
}) {
  final maxRowByChapter = <int, int>{};
  var maxColumn = 0;
  for (final slot in slots.values) {
    if (slot.column > maxColumn) maxColumn = slot.column;
    final current = maxRowByChapter[slot.chapter] ?? 0;
    if (slot.row > current) maxRowByChapter[slot.chapter] = slot.row;
  }

  final chapters = maxRowByChapter.keys.toList()..sort();
  final bandStartY = <int, double>{};
  var y = 0.0;
  for (final chapter in chapters) {
    bandStartY[chapter] = y;
    final rows = (maxRowByChapter[chapter] ?? 0) + 1;
    y += rows * rowHeight + chapterGap;
  }
  return ChapterBandLayout(
      bandStartY: bandStartY, maxColumn: maxColumn, totalHeight: y);
}

bool _isTravelPlace(StoryNode? node) {
  final settlement = node?.settlement;
  return settlement != null && !settlement.isCamp && settlement.chapter != null;
}
