// A scene's callback cap and its revisit text (v1.813): `callback_cap` on a
// node keeps at most that many earned callbacks, the highest `priority`
// first (ties by the file's order), shown in the file's order; a node's
// `revisit_description` (and `_fr`) is what it says once the party has
// been there before. Both go through the screen text, its pages, the
// read-aloud, the recording script and the story file's round-trip, and
// the story file's own values are checked for their types.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/narration_clips.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart'
    show composeNarration, composeNarrationParts;
import 'player_session_provider_test.dart' show baseSession;

StoryNode _capped({int? cap}) => StoryNode.fromJson('hub', {
      'description': 'The hall.',
      if (cap != null) 'callback_cap': cap,
      'flag_callbacks': [
        {'flag': 'a', 'en': 'Line A.', 'fr': 'Ligne A.'},
        {'flag': 'b', 'en': 'Line B.', 'fr': 'Ligne B.', 'priority': 5},
        {'flag': 'c', 'en': 'Line C.', 'fr': 'Ligne C.', 'priority': 1},
        {'flag': 'd', 'en': 'Line D.', 'fr': 'Ligne D.', 'priority': 5},
        {'flag': 'e', 'en': 'Line E.', 'fr': 'Ligne E.'},
      ],
      'choices': [],
    });

StoryNode _revisited() => StoryNode.fromJson('wells', {
      'description': 'First sight of the wells.[PAGE]The water, at last.',
      'description_fr': 'Les puits, pour la première fois.',
      'revisit_description': 'The wells again.[PAGE]Still water.',
      'revisit_description_fr': 'Encore les puits.',
      'flag_callbacks': [
        {'flag': 'a', 'en': 'Line A.'},
      ],
      'choices': [],
    });

Map<String, dynamic> _dag() {
  for (final path in [
    StoryRepository.assetPath,
    '../${StoryRepository.assetPath}'
  ]) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('no story file');
}

void main() {
  const all = ['a', 'b', 'c', 'd', 'e'];

  group('the callback cap', () {
    test('keeps the highest priority, ties by file order, shown in file order',
        () {
      final node = _capped(cap: 2);
      expect(node.firedCallbacks(all).map((c) => c.flag), ['b', 'd']);
      expect(node.callbacksFor(all, false), ['Line B.', 'Line D.']);
      expect(node.callbacksFor(all, true), ['Ligne B.', 'Ligne D.']);
      // Three: b and d (5), then c (1) over a and e (0); shown in file order.
      expect(_capped(cap: 3).firedCallbacks(all).map((c) => c.flag),
          ['b', 'c', 'd']);
      // Ties at 0 go by the file's order: a before e.
      expect(_capped(cap: 4).firedCallbacks(all).map((c) => c.flag),
          ['a', 'b', 'c', 'd']);
      // Only what the flags earned counts toward the cap.
      expect(
          _capped(cap: 2)
              .firedCallbacks(const ['a', 'c', 'e']).map((c) => c.flag),
          ['a', 'c']);
    });

    test('with no cap, or a cap above what fired, nothing changes', () {
      expect(_capped().callbackCap, isNull);
      expect(_capped().firedCallbacks(all).map((c) => c.flag), all);
      expect(_capped(cap: 9).firedCallbacks(all).map((c) => c.flag), all);
    });

    test('the screen and the read-aloud show the capped lines', () {
      final session = baseSession().copyWith(flags: all);
      final node = _capped(cap: 2);
      final text = composeNarration(node, session, french: false);
      expect(text, contains('Line B.'));
      expect(text, contains('Line D.'));
      for (final gone in ['Line A.', 'Line C.', 'Line E.']) {
        expect(text, isNot(contains(gone)));
      }
      final spoken = readAloudParagraphs(node, session, french: true);
      expect(spoken, containsAll(['Ligne B.', 'Ligne D.']));
      expect(spoken, isNot(contains('Ligne A.')));
    });

    test('the recording script keeps every callback, uncapped', () {
      final script = nodeNarrationScript(_capped(cap: 1),
          french: false, personalize: (t) => t);
      expect(script,
          containsAll(['Line A.', 'Line B.', 'Line C.', 'Line D.', 'Line E.']));
    });
  });

  group('the revisit text', () {
    test('the first visit reads the description, a revisit its own text', () {
      final node = _revisited();
      expect(node.descriptionFor(false), startsWith('First sight'));
      expect(node.descriptionFor(false, revisit: true),
          startsWith('The wells again.'));
      expect(node.descriptionFor(true), 'Les puits, pour la première fois.');
      expect(node.descriptionFor(true, revisit: true), 'Encore les puits.');
      // No French revisit: the English one; no revisit text: the description.
      final english = StoryNode.fromJson('x', {
        'description': 'Once.',
        'description_fr': 'Une fois.',
        'revisit_description': 'Again.',
        'choices': [],
      });
      expect(english.descriptionFor(true, revisit: true), 'Again.');
      final plain =
          StoryNode.fromJson('y', {'description': 'Once.', 'choices': []});
      expect(plain.descriptionFor(false, revisit: true), 'Once.');
    });

    test('a scene is a revisit when it is in the scenes left before it', () {
      StoryPlayState at(String id, List<String> history) => StoryPlayState(
          currentNodeId: id,
          history: history,
          visitedNodeIds: {id, ...history});
      expect(isRevisit(at('1200', ['1150_vica'])), isFalse);
      expect(isRevisit(at('1200', ['1150_vica', '1200'])), isTrue);
      expect(isRevisit(at('1200', ['1200', '1210', '1150'])), isTrue);
    });

    test('the screen text, its pages and the read-aloud use it; the rest stays',
        () {
      final session = baseSession().copyWith(flags: const ['a']);
      final node = _revisited();
      final story = StoryData({node.id: node});
      final first = composeNarrationParts(node, session, story, french: false);
      final again = composeNarrationParts(node, session, story,
          french: false, revisit: true);
      expect(first.pages.first, contains('First sight'));
      expect(again.pages, hasLength(2));
      expect(again.pages.first, contains('The wells again.'));
      expect(again.text, isNot(contains('First sight')));
      // The callbacks are the same on both visits.
      expect(first.text, contains('Line A.'));
      expect(again.text, contains('Line A.'));
      expect(composeNarration(node, session, french: true, revisit: true),
          startsWith('Encore les puits.'));
      final spoken =
          readAloudParagraphs(node, session, french: false, revisit: true);
      expect(spoken.join(' '), contains('The wells again.'));
      expect(spoken.join(' '), isNot(contains('First sight')));
      expect(readAloudParagraphs(node, session, french: false).join(' '),
          contains('First sight'));
    });

    test('the recording script keeps the first visit\'s text, then the revisit',
        () {
      final script = nodeNarrationScript(_revisited(),
          french: false, personalize: (t) => t);
      final joined = script.join(' ');
      expect(joined, contains('First sight'));
      expect(joined, contains('The wells again.'));
      expect(
          joined.indexOf('First sight'), lessThan(joined.indexOf('The wells')));
      expect(
          nodeNarrationScript(_revisited(),
                  french: false, personalize: (t) => t, variations: false)
              .join(' '),
          isNot(contains('The wells again.')));
    });
  });

  test('both round-trip through the story file, and are left out when unset',
      () {
    final capped = StoryNode.fromJson('hub', _capped(cap: 2).toJson());
    expect(capped.callbackCap, 2);
    expect(capped.flagCallbacks.map((c) => c.priority), [0, 5, 1, 5, 0]);
    final again = StoryNode.fromJson('wells', _revisited().toJson());
    expect(again.revisitDescription, 'The wells again.[PAGE]Still water.');
    expect(again.revisitDescriptionFr, 'Encore les puits.');
    final json = _capped().toJson();
    expect(json.containsKey('callback_cap'), isFalse);
    expect(json.containsKey('revisit_description'), isFalse);
    expect((json['flag_callbacks'] as List).first.containsKey('priority'),
        isFalse);
  });

  test('the story file: every cap, priority and revisit text has its type', () {
    final bad = <String>[];
    for (final MapEntry(key: id, :value) in _dag().entries) {
      final node = value as Map<String, dynamic>;
      final cap = node['callback_cap'];
      if (cap != null && (cap is! int || cap < 1)) {
        bad.add('$id: callback_cap $cap is not a whole number of 1 or more');
      }
      if (cap != null && node['flag_callbacks'] is! List) {
        bad.add('$id: callback_cap with no flag_callbacks');
      }
      for (final entry in (node['flag_callbacks'] as List?) ?? const []) {
        final priority = entry is Map ? entry['priority'] : null;
        if (priority != null && priority is! int) {
          bad.add('$id: priority $priority is not a whole number');
        }
      }
      for (final key in ['revisit_description', 'revisit_description_fr']) {
        final text = node[key];
        if (text != null && (text is! String || text.trim().isEmpty)) {
          bad.add('$id: $key is not a text');
        }
      }
      if (node['revisit_description_fr'] != null &&
          node['revisit_description'] == null) {
        bad.add('$id: revisit_description_fr with no revisit_description');
      }
    }
    expect(bad, isEmpty);
  });
}
