// QA: french_data_lint_test reads only keys ending in `_fr` or `Fr`. The
// story graph also keeps French in bare `fr` keys (flag callbacks, persona
// variants, ...). This holds those strings to the same typography and
// address rules.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A no-break space before ; : ! ? and », after «.
final RegExp _nbsp = RegExp('[^ ][:;!?»]|«[^ ]');

/// Tutoiement, with accent-aware boundaries.
final RegExp _tu = RegExp(
    r"(?<!\p{L})(?:(?:tu|toi|ton|ta|tes|te)(?!\p{L})|t['’](?=\p{L}))",
    caseSensitive: false,
    unicode: true);

/// « ton » the noun and « s'est tu » the participle address nobody.
final List<RegExp> _notAnAddress = [
  RegExp(
      r"(?<!\p{L})(?:un|le|du|ce|au|son|même|quel|bon|mauvais|sur un) ton(?!\p{L})",
      caseSensitive: false,
      unicode: true),
  RegExp(r"(?<!\p{L})s['’](?:est|était|étaient|étant|être) tue?s?(?!\p{L})",
      caseSensitive: false, unicode: true),
];

/// A past participle agreed with the player: « vous êtes arrivé(e) ».
final RegExp _gendered = RegExp(
    r"(?<!\p{L})vous (?:êtes|avez été|voilà|voici) \p{L}+ée?s?(?!\p{L})",
    caseSensitive: false,
    unicode: true);

/// Straight apostrophe between letters: the story uses ’ throughout.
final RegExp _straight = RegExp(r"\p{L}'\p{L}", unicode: true);

Iterable<({String path, String text})> _bareFr(Object? v, String path) sync* {
  if (v is Map) {
    for (final e in v.entries) {
      final key = e.key.toString();
      if (key == 'fr' && e.value is String) {
        yield (path: '$path.fr', text: e.value as String);
      } else {
        yield* _bareFr(e.value, '$path.$key');
      }
    }
  } else if (v is List) {
    for (var i = 0; i < v.length; i++) {
      yield* _bareFr(v[i], '$path[$i]');
    }
  }
}

void main() {
  final story =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final strings = _bareFr(story, '').toList();

  test('the story has bare "fr" strings to check', () {
    // 925 as of v1.255.
    expect(strings.length, greaterThan(500));
  });

  test('bare "fr" strings keep French typography and say « vous »', () {
    final failures = <String>[];
    for (final s in strings) {
      final faults = <String>[];
      if (_nbsp.hasMatch(s.text)) faults.add('no-break space');
      if (_straight.hasMatch(s.text)) faults.add('straight apostrophe');
      var spoken = s.text;
      for (final phrase in _notAnAddress) {
        spoken = spoken.replaceAll(phrase, ' ');
      }
      if (_tu.hasMatch(spoken)) faults.add('tutoiement');
      if (_gendered.hasMatch(s.text)) faults.add('gendered form');
      if (faults.isNotEmpty) {
        failures.add('${s.path}: ${faults.join(', ')}: "${s.text}"');
      }
    }
    expect(failures, isEmpty, reason: failures.take(20).join('\n'));
  });
}
