import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/chapter_grid_layout.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/utils/story_export.dart';

void main() {
  final raw =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final story = StoryData({
    for (final entry in raw.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  });

  test('the light export lists every node in chapter order', () {
    final export = jsonDecode(storyLightExport(story)) as Map<String, dynamic>;
    final nodes = (export['nodes'] as List).cast<Map<String, dynamic>>();
    expect(export['nodeCount'], story.nodes.length);
    expect(nodes.map((n) => n['id']).toSet(), story.nodes.keys.toSet());
    final chapters = [for (final n in nodes) n['chapter'] as int];
    expect(chapters, [...chapters]..sort());
    for (final n in nodes) {
      expect(n['chapter'], chapterOfNode(n['id'] as String));
    }

    // A story fight carries its enemies and where a loss goes.
    final hovel = nodes.firstWhere((n) => n['id'] == '400');
    final unfurl = (hovel['choices'] as List).first as Map<String, dynamic>;
    expect(unfurl['next'], '450');
    expect(
        unfurl['fight'], ['white_soldier', 'white_soldier', 'white_soldier']);
    expect(unfurl['ifLost'], '400_lost');
    expect(hovel['text'], story.nodeFor('400')!.description);
  });

  test('the light export reads in French when asked', () {
    final export = jsonDecode(storyLightExport(story, french: true))
        as Map<String, dynamic>;
    final hovel = (export['nodes'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((n) => n['id'] == '400');
    expect(hovel['text'], story.nodeFor('400')!.descriptionFr);
    expect(((hovel['choices'] as List).first as Map)['text'],
        'Déployer le Balluchon');
  });

  test('the full export is the story file itself', () {
    expect(jsonDecode(storyFullExport(raw)), raw);
  });
}
