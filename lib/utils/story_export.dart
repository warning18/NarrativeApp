import 'dart:convert';

import '../data/chapter_grid_layout.dart';
import '../data/story_repository.dart';
import '../models/story_node.dart';

final RegExp _leadingDigits = RegExp(r'^\d+');

int _numericPrefix(String id) =>
    int.tryParse(_leadingDigits.firstMatch(id)?.group(0) ?? '') ?? 0;

/// [story]'s nodes in reading order: by chapter, then by the number their
/// id starts with, then by id.
List<StoryNode> nodesInChapterOrder(StoryData story) =>
    story.nodes.values.toList()
      ..sort((a, b) {
        final byChapter = chapterOfNode(a.id).compareTo(chapterOfNode(b.id));
        if (byChapter != 0) return byChapter;
        final byNumber = _numericPrefix(a.id).compareTo(_numericPrefix(b.id));
        return byNumber != 0 ? byNumber : a.id.compareTo(b.id);
      });

/// The light export of every story node, for reading or review: each
/// node's id, chapter and text (in French when [french] and the node has
/// it), and its choices with where they lead, the enemies they fight and
/// where a lost fight goes.
String storyLightExport(StoryData story, {bool french = false}) {
  final nodes = nodesInChapterOrder(story);
  return const JsonEncoder.withIndent('  ').convert({
    'format': 'story-nodes-light',
    'nodeCount': nodes.length,
    'nodes': [
      for (final node in nodes)
        {
          'id': node.id,
          'chapter': chapterOfNode(node.id),
          'text': node.descriptionFor(french),
          'choices': [
            for (final choice in node.choices)
              {
                'text': french && (choice.textFr?.isNotEmpty ?? false)
                    ? choice.textFr
                    : choice.text,
                'next': choice.nextId,
                if (choice.allTriggerEnemyIds.isNotEmpty)
                  'fight': choice.allTriggerEnemyIds,
                if (choice.loseNextId?.isNotEmpty ?? false)
                  'ifLost': choice.loseNextId,
              },
          ],
        },
    ],
  });
}

/// The full export: [rawNodes] (see [StoryRepository.loadRaw]) with every
/// field of every node in both languages, in the story file's own format,
/// so it can be read back as the story.
String storyFullExport(Map<String, dynamic> rawNodes) =>
    const JsonEncoder.withIndent('  ').convert(rawNodes);
