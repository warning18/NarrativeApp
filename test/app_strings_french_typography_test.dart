// Narrative: guard on the French typography of lib/l10n/app_strings.dart.
// The string table is private, so this reads the source as text. French sets
// a no-break space before : ; ! ? % and inside « », and uses ’ for the
// apostrophe. `python3 tool/fix_fr_typography.py --write` brings the file back
// to this rule; this test keeps it there when a session adds a string.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every French string in app_strings.dart keeps French typography', () {
    final src = File('lib/l10n/app_strings.dart').readAsStringSync();
    final start = src.indexOf('const Map<String, Map<AppLanguage, String>>');
    final end = src.indexOf('\n};', start);
    final body = src.substring(start, end);
    final head = RegExp(r"^  '([a-zA-Z0-9_]+)': \{", multiLine: true);
    final heads = head.allMatches(body).toList();

    // a plain space before : ; ! ? %  (the escape   is not a plain space)
    final plainSpace = RegExp(r'[^\s\\] [:;!?%]');
    final guillemet = RegExp('«[ ]|[ ]»');
    final straight = RegExp(r"\\'|(?<=[A-Za-zÀ-ÿ])'(?=[A-Za-zÀ-ÿ])");

    final faults = <String>[];
    for (var i = 0; i < heads.length; i++) {
      final from = heads[i].end;
      final to = i + 1 < heads.length ? heads[i + 1].start : body.length;
      // comments between keys are not strings
      final chunk = body
          .substring(from, to)
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      final frAt = chunk.indexOf('AppLanguage.fr:');
      if (frAt < 0) continue;
      final enAt = chunk.indexOf('AppLanguage.en:');
      final fr = enAt > frAt
          ? chunk.substring(frAt + 15, enAt)
          : chunk.substring(frAt + 15);
      final key = heads[i].group(1)!;
      if (plainSpace.hasMatch(fr))
        faults.add('$key: plain space before : ; ! ? %');
      if (guillemet.hasMatch(fr)) faults.add('$key: plain space inside « »');
      if (straight.hasMatch(fr)) faults.add('$key: straight apostrophe');
    }
    expect(faults, isEmpty,
        reason: 'run: python3 tool/fix_fr_typography.py --write '
            '(then dart format lib/l10n/app_strings.dart)');
  });
}
