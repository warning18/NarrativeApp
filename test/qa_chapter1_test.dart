// QA: what the chapter 1 review (docs/qa/chapter1-review.md) found that a
// plain read of the data can hold. Chapter 1 is the graph's nodes from "0" to
// "1002" in file order.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final graph = _json('assets/Cleaned_Narrative_DAG.json');
  final keys = graph.keys.toList();
  final chapter1 = keys.sublist(0, keys.indexOf('1002') + 1);

  Iterable<String> texts(Map<String, dynamic> node) sync* {
    for (final k in ['description', 'description_fr', 'prompt', 'prompt_fr']) {
      if (node[k] is String) yield node[k] as String;
    }
    for (final c in node['choices'] as List) {
      for (final k in [
        'text',
        'text_fr',
        'lockedText',
        'lockedText_fr',
        'failNote',
        'failNote_fr',
      ]) {
        if ((c as Map)[k] is String) yield c[k] as String;
      }
    }
    for (final v in ((node['persona_variants'] ?? {}) as Map).values) {
      yield* (v as Map).values.whereType<String>();
    }
    for (final cb in (node['flag_callbacks'] ?? []) as List) {
      yield* (cb as Map).values.whereType<String>();
    }
  }

  test('the dog is Vica, and she is met at 1150_vica: no earlier scene has one',
      () {
    final dog = RegExp(r'\b(dog|hound|pup|puppy|chien|chienne|chiot)s?\b',
        caseSensitive: false);
    final seen = <String>[];
    for (final id in chapter1) {
      if (id == '1150_vica') continue;
      for (final t in texts(graph[id] as Map<String, dynamic>)) {
        if (dog.hasMatch(t)) seen.add(id);
      }
    }
    expect(seen, isEmpty, reason: 'a dog before Vica is met: $seen');
    expect(
        texts(graph['1150_vica'] as Map<String, dynamic>)
            .any((t) => t.contains('Vica')),
        isTrue);
  });

  test(
      'every scene a companion joins on is in the graph, and Vica joins at '
      'the White Wells', () {
    final companions = _json('assets/gamedata/companions.json');
    for (final c in companions.values) {
      for (final id in ((c as Map)['joinNodeIds'] ?? []) as List) {
        expect(graph.containsKey(id), isTrue,
            reason: '${c['companionID']} joins on $id, which is not a scene');
      }
    }
    final vica = companions['vica'] as Map;
    expect(vica['joinNodeIds'], containsAll(['1150_vica', '1200']));
    expect(chapter1, containsAll(['1150_vica', '1200']));
  });

  test(
      'a payment in chapter 1 that the story asks (pays) is shut to a purse '
      'too small, and its gold shown in the text', () {
    for (final id in chapter1) {
      for (final c in (graph[id] as Map)['choices'] as List) {
        if ((c as Map)['pays'] == true) {
          expect((c['goldMod'] as num) < 0, isTrue, reason: id);
          final price = -(c['goldMod'] as num).toInt();
          if (id == '1150_vica') {
            expect(c['text'], contains('$price gold'));
            expect(c['text_fr'], contains('$price pièces d’or'));
          }
        }
      }
    }
  });
}
