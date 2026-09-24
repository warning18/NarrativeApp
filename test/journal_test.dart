// The story journal: a scene's opening line without its chapter heading,
// and the story so far read off the graph -- each scene with the choice
// whose way on reached the next one.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journal.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

StoryData _story() {
  for (final path in [
    'assets/Cleaned_Narrative_DAG.json',
    '../assets/Cleaned_Narrative_DAG.json'
  ]) {
    final file = File(path);
    if (file.existsSync()) {
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return StoryData({
        for (final e in decoded.entries)
          e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
      });
    }
  }
  throw StateError('Cannot find the story graph');
}

void main() {
  group('openingLine', () {
    test('drops the chapter heading and keeps the first sentence', () {
      expect(
          openingLine('[CHAPTER 3: THE SPIRE] Landfall came. The Eel stopped.'),
          'Landfall came.');
    });

    test('cuts a long sentence at a word', () {
      final line = openingLine('${'word ' * 80}end.', maxLength: 40);
      expect(line.length, lessThanOrEqualTo(41));
      expect(line.endsWith('…'), isTrue);
    });
  });

  test('the story so far names the choice that left each scene', () {
    final story = _story();
    final start = story.nodeFor(StoryRepository.startNodeId)!;
    final next = firstSceneAfterCreation(story);
    final entries = storySoFar(story, [start.id], next, french: false);
    expect(entries.map((e) => e.nodeId), [start.id, next]);
    final taken = start.choices.firstWhere((c) => c.nextId == next);
    expect(entries.first.choiceText, taken.text);
    expect(entries.last.choiceText, isNull);
    expect(entries.last.opening, isNotEmpty);
  });

  test('a French reader gets the French lines', () {
    final story = _story();
    final entries = storySoFar(story, const [], '2015', french: true);
    expect(entries.single.opening, startsWith('Même'));
  });
}
