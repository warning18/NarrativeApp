// QA: the story text's bold markup (docs/proposals/story-markup.md) cannot
// reach a release with a slip in it. `**the key fact**` shows as bold; an
// unclosed `**` shows as typed. So, in the quests (quests.json, English and
// French) and the story (the DAG):
//   - every `**` closes, inside its own paragraph (a blank line ends one),
//     around something (no empty run, no space just inside the signs);
//   - a `**` never sits in a choice text, a button, a name or a locked line
//     (only in the text a scene or a quest tells: a quest's dialogue, an
//     objective's description, a turn-in's result, a scene's description).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What is wrong with the `**` in [text] ('' when nothing is).
String markupSlip(String text) {
  if (!text.contains('**')) return '';
  for (final paragraph in text.split(RegExp(r'\n\s*\n'))) {
    final parts = paragraph.split('**');
    final signs = parts.length - 1;
    if (signs == 0) continue;
    if (signs.isOdd) return 'an unclosed ** in "${_clip(paragraph)}"';
    // The runs are the odd parts.
    for (var i = 1; i < parts.length; i += 2) {
      final run = parts[i];
      if (run.trim().isEmpty) {
        return 'an empty bold run in "${_clip(paragraph)}"';
      }
      if (run != run.trim()) {
        return 'a space inside the ** in "${_clip(paragraph)}"';
      }
    }
  }
  return '';
}

String _clip(String s) => s.length > 70 ? '${s.substring(0, 70)}...' : s;

typedef _Hit = ({String path, String text});

/// Every string of [node] with its path (list items as `[]`).
Iterable<_Hit> _strings(Object? node, List<String> path) sync* {
  if (node is String) {
    yield (path: path.join('.'), text: node);
  } else if (node is Map) {
    for (final e in node.entries) {
      yield* _strings(e.value, [...path, '${e.key}']);
    }
  } else if (node is List) {
    for (final item in node) {
      yield* _strings(item, [...path, '[]']);
    }
  }
}

/// The paths where the story's markup is allowed (the rest takes none).
bool _quest(String path) =>
    path == 'npcDialogueText' ||
    path == 'npcDialogueText_fr' ||
    path == 'objectives.[].description' ||
    path == 'objectives.[].description_fr' ||
    path == 'turnInChoices.[].resultText' ||
    path == 'turnInChoices.[].resultText_fr';

/// In the story, a choice's own text and its French take none.
bool _storyChoiceText(String path) =>
    path == 'choices.[].text' || path == 'choices.[].text_fr';

void main() {
  test('the scan itself sees a slip and lets good markup pass', () {
    expect(markupSlip('Pay **forty crowns** by dusk.'), '');
    expect(markupSlip('No markup, one * star and **two** done.'), '');
    expect(markupSlip('**One** here.\n\nAnd **another** there.'), '');
    expect(markupSlip('Pay **forty crowns by dusk.'), contains('unclosed'));
    expect(markupSlip('**A bold run\n\nthat crosses** a paragraph.'),
        contains('unclosed'));
    expect(markupSlip('An **** empty one.'), contains('empty'));
    expect(markupSlip('A ** spaced** run.'), contains('space'));
    expect(markupSlip('A **spaced ** run.'), contains('space'));
  });

  test('quests.json: every ** closes, and only in the text a quest tells', () {
    final quests =
        jsonDecode(File('assets/gamedata/quests.json').readAsStringSync())
            as Map<String, dynamic>;
    final found = <String>[];
    for (final quest in quests.entries) {
      for (final hit in _strings(quest.value, const [])) {
        if (!hit.text.contains('**')) continue;
        final where = '${quest.key}: ${hit.path}';
        if (!_quest(hit.path)) {
          found.add('$where takes no markup (a name, a button or a choice)');
          continue;
        }
        final slip = markupSlip(hit.text);
        if (slip.isNotEmpty) found.add('$where: $slip');
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('the story: every ** closes, and none sits in a choice text', () {
    final story =
        jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
            as Map<String, dynamic>;
    final found = <String>[];
    for (final node in story.entries) {
      for (final hit in _strings(node.value, const [])) {
        if (!hit.text.contains('**')) continue;
        final where = 'node ${node.key}: ${hit.path}';
        if (_storyChoiceText(hit.path)) {
          found.add('$where is a choice text and takes no markup');
          continue;
        }
        final slip = markupSlip(hit.text);
        if (slip.isNotEmpty) found.add('$where: $slip');
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
