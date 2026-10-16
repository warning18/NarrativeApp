// Narrative's in-place data (docs/proposals/inplace-choices.md): who a
// scene faces, the question it ends on, and a hub choice's grouping key,
// all optional, read and written back as they came.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/models/story_node.dart';

void main() {
  test('the in-place fields are read and written back', () {
    final json = <String, dynamic>{
      'description': 'A chapel.',
      'facing': 'brother_clement',
      'prompt': 'What do you do?',
      'prompt_fr': 'Que faites-vous ?',
      'aboutLabels': {
        'the_chair': {'en': 'The chair', 'fr': 'La chaise'},
      },
      'choices': [
        {'text': 'Ask about the chair', 'next_id': '2', 'about': 'the_chair'},
        {'text': 'Leave', 'next_id': '3'},
      ],
    };
    final node = StoryNode.fromJson('1', json);
    expect(node.facing, 'brother_clement');
    expect(node.promptFor(false), 'What do you do?');
    expect(node.promptFor(true), 'Que faites-vous ?');
    expect(node.aboutLabels['the_chair'], (en: 'The chair', fr: 'La chaise'));
    expect(node.choices.first.about, 'the_chair');
    expect(node.choices.last.about, '');
    final back = node.toJson();
    expect(back['facing'], 'brother_clement');
    expect(back['prompt_fr'], 'Que faites-vous ?');
    expect(back['aboutLabels'], json['aboutLabels']);
    expect((back['choices'] as List).first['about'], 'the_chair');
    expect((back['choices'] as List).last.containsKey('about'), isFalse);
    // Absent, they stay absent.
    final plain = StoryNode.fromJson('2', {'description': 'x', 'choices': []});
    expect(plain.facing, '');
    expect(plain.toJson().containsKey('prompt'), isFalse);
  });
}
