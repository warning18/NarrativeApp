// QA: guards on lib/l10n/app_strings.dart that hold across sessions' edits.
// Reads the source file as text (the string table is private).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

class _Entry {
  _Entry(this.key, this.en, this.fr);
  final String key;
  final String? en;
  final String? fr;
}

final _placeholder = RegExp(r'\{[a-zA-Z_0-9]+\}');

List<_Entry> _entries() {
  final src = File('lib/l10n/app_strings.dart').readAsStringSync();
  final start = src.indexOf('const Map<String, Map<AppLanguage, String>>');
  final end = src.indexOf('\n};', start);
  final body = src.substring(start, end);
  final head = RegExp(r"^  '([a-zA-Z0-9_]+)': \{", multiLine: true);
  final heads = head.allMatches(body).toList();
  final out = <_Entry>[];
  for (var i = 0; i < heads.length; i++) {
    final from = heads[i].end;
    final to = i + 1 < heads.length ? heads[i + 1].start : body.length;
    final chunk = body.substring(from, to);
    final enAt = chunk.indexOf('AppLanguage.en:');
    final frAt = chunk.indexOf('AppLanguage.fr:');
    String? en, fr;
    if (enAt >= 0 && frAt >= 0) {
      if (enAt < frAt) {
        en = chunk.substring(enAt, frAt);
        fr = chunk.substring(frAt);
      } else {
        fr = chunk.substring(frAt, enAt);
        en = chunk.substring(enAt);
      }
    } else if (enAt >= 0) {
      en = chunk.substring(enAt);
    } else if (frAt >= 0) {
      fr = chunk.substring(frAt);
    }
    out.add(_Entry(heads[i].group(1)!, en, fr));
  }
  return out;
}

Set<String> _holes(String? s) => s == null
    ? <String>{}
    : _placeholder.allMatches(s).map((m) => m[0]!).toSet();

void main() {
  final entries = _entries();

  test('the string table was parsed', () {
    expect(entries.length, greaterThan(500));
  });

  test('every string key has an English and a French text', () {
    final missing = [
      for (final e in entries)
        if (e.en == null || e.fr == null) e.key,
    ];
    expect(missing, isEmpty, reason: 'keys missing a language: $missing');
  });

  test('English and French keep the same {placeholders}', () {
    final bad = [
      for (final e in entries)
        if (e.en != null &&
            e.fr != null &&
            (_holes(e.en).length != _holes(e.fr).length ||
                !_holes(e.en).containsAll(_holes(e.fr))))
          '${e.key}: en ${_holes(e.en)} vs fr ${_holes(e.fr)}',
    ];
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('every key used with tr()/trFor() exists in the table', () {
    final keys = {for (final e in entries) e.key};
    final use = RegExp(r"\btr(?:For)?\(\s*[A-Za-z_.]+\s*,\s*'([a-zA-Z0-9_]+)'");
    final unknown = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final m in use.allMatches(f.readAsStringSync())) {
        if (!keys.contains(m[1])) unknown.add('${m[1]} (${f.path})');
      }
    }
    expect(unknown, isEmpty, reason: 'keys used but not defined: $unknown');
  });
}
