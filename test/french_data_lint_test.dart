// A French lint over every game table (v1.209): each French string of
// assets/gamedata/*.json and of the story (assets/Cleaned_Narrative_DAG.json)
// -- every field ending in `_fr` or `Fr`, nested maps and lists included --
// keeps French typography (a no-break space before ; : ! ? and », after «)
// and speaks to the player as « vous », with no gendered form. It grew out
// of the People codex's lint (v1.204, l10n_data_test) and the clan
// tables' (clans_content_test): the same rules over everything, once.
//
// What is addressed to the player: the narrator is first person, so a
// « tu » in a French string is a character speaking to the player unless a
// character quoted in « » says it to another character. The data holds
// none of those today; one that is written goes into [_allowlist] under
// its node id, which only shrinks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _tablesDir = 'assets/gamedata';
const String _dagPath = 'assets/Cleaned_Narrative_DAG.json';

/// Records exempt today, by file (its base name) and record id (the story's
/// node id): a scene where a quoted character says « tu » to another, a
/// line that needs a human voice before it reads in « vous ». Every entry
/// must still trip the lint (else it is removed), and the whole only
/// shrinks (see [_allowlistSize]).
const Map<String, Set<String>> _allowlist = {};

/// How many records [_allowlist] held when it was last trimmed: it never
/// grows past this; lower it when a record is fixed.
const int _allowlistSize = 0;

/// Fields exempt by name: what a companion throws at an enemy (see
/// french_address_test) is not said to the player.
const Set<String> _fieldsNotToThePlayer = {'dodgeLineFr'};

/// Where « Un ami » / « Une amie » is a gendered word for the player: what
/// a keeper or a person says to them.
bool _spokenToThePlayer(String file, String field) =>
    file == 'npcs.json' ||
    (file == 'shops.json' && field.startsWith('keeperLine')) ||
    (file == 'quests.json' && field == 'npcDialogueText_fr');

/// A no-break space before ; : ! ? and », after «.
final RegExp _nbsp = RegExp('[^ ][:;!?»]|«[^ ]');

/// Tutoiement, with accent-aware boundaries (not \b, which stops at every
/// accented letter: « hôtes » holds a « tes » to it).
final RegExp _tu = RegExp(
    r"(?<!\p{L})(?:(?:tu|toi|ton|ta|tes|te)(?!\p{L})|t['’](?=\p{L}))",
    caseSensitive: false,
    unicode: true);

/// Phrases [_tu] trips on that address nobody: « ton » the noun (du ton de
/// quelqu'un, sur un ton d'affaires) and « tu » the participle of se taire
/// (le Vide s'est tu). Blanked before the check.
final List<RegExp> _notAnAddress = [
  RegExp(
      r"(?<!\p{L})(?:un|le|du|ce|au|son|même|quel|bon|mauvais|sur un) ton(?!\p{L})",
      caseSensitive: false,
      unicode: true),
  RegExp(r"(?<!\p{L})s['’](?:est|était|étaient|étant|être) tue?s?(?!\p{L})",
      caseSensitive: false, unicode: true),
];

/// A past participle agreed with the player: « Vous êtes arrivé(e) »,
/// « vous avez été payé », « vous voilà perdu ».
final RegExp _gendered = RegExp(
    r"(?<!\p{L})vous (?:êtes|avez été|voilà|voici) \p{L}+ée?s?(?!\p{L})",
    caseSensitive: false,
    unicode: true);

/// « Un ami », « Une amie »: the player called a friend with a gender.
final RegExp _genderedFriend =
    RegExp(r'(?<!\p{L})(?:Un|Une) (?:ami|amie)(?!\p{L})', unicode: true);

/// Everything wrong with [text] at [field] of [file], in words.
List<String> _faults(String file, String field, String text) {
  final faults = <String>[];
  if (_nbsp.hasMatch(text)) faults.add('no-break space');
  if (!_fieldsNotToThePlayer.contains(field)) {
    var spoken = text;
    for (final phrase in _notAnAddress) {
      spoken = spoken.replaceAll(phrase, ' ');
    }
    if (_tu.hasMatch(spoken)) faults.add('tutoiement');
  }
  if (_gendered.hasMatch(text)) faults.add('gendered form');
  if (_spokenToThePlayer(file, field) && _genderedFriend.hasMatch(text)) {
    faults.add('gendered friend');
  }
  return faults;
}

/// Every French string under [value] with where it is and the field it is
/// written under: a key ending in `_fr` or `Fr` (its own, or the nearest
/// one above a list or a map), through maps and lists.
Iterable<({String path, String field, String text})> _french(
    Object? value, String path,
    {String field = ''}) sync* {
  if (value is String) {
    if (field.isNotEmpty) yield (path: path, field: field, text: value);
  } else if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final french = key.endsWith('_fr') || (key.endsWith('Fr') && key != 'Fr');
      yield* _french(entry.value, '$path.$key', field: french ? key : field);
    }
  } else if (value is List) {
    for (var i = 0; i < value.length; i++) {
      yield* _french(value[i], '$path[$i]', field: field);
    }
  }
}

Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Every data file, by base name: the tables, then the story.
Map<String, Map<String, dynamic>> _allData() {
  final paths = [
    for (final entity in Directory(_tablesDir).listSync())
      if (entity.path.endsWith('.json')) entity.path,
  ]..sort();
  return {
    for (final path in paths) path.split('/').last: _read(path),
    _dagPath.split('/').last: _read(_dagPath),
  };
}

void main() {
  late final Map<String, Map<String, dynamic>> data;
  setUpAll(() => data = _allData());

  test('the rules read as meant', () {
    const nbsp = ' ';
    expect(_faults('x', 'line_fr', 'Où allez-vous$nbsp?'), isEmpty);
    expect(_faults('x', 'line_fr', 'Où allez-vous ?'), ['no-break space']);
    expect(
        _faults('x', 'line_fr', 'Ha$nbsp! Non$nbsp: ici$nbsp; là.'), isEmpty);
    expect(_faults('x', 'line_fr', 'Ha! Non.'), ['no-break space']);
    expect(_faults('x', 'line_fr', '«${nbsp}Entrez.$nbsp»'), isEmpty);
    expect(_faults('x', 'line_fr', '« Entrez. »'), ['no-break space']);
    expect(_faults('x', 'line_fr', 'Nos hôtes vous attendent.'), isEmpty);
    expect(_faults('x', 'line_fr', 'Tu viens$nbsp?'), ['tutoiement']);
    expect(_faults('x', 'line_fr', 'Donne-moi ta main.'), ['tutoiement']);
    expect(_faults('x', 'line_fr', 'Il parle, t’avertit, et se tait.'),
        ['tutoiement']);
    expect(
        _faults('x', 'line_fr', 'Elle me dit, du ton de quelqu’un…'), isEmpty);
    expect(_faults('x', 'line_fr', 'Le Vide s’est tu.'), isEmpty);
    expect(
        _faults('companions.json', 'dodgeLineFr', 'Tu n’as saisi que l’ombre.'),
        isEmpty);
    expect(_faults('x', 'line_fr', 'Vous êtes arrivé trop tard.'),
        ['gendered form']);
    expect(_faults('x', 'line_fr', 'Vous êtes arrivée trop tard.'),
        ['gendered form']);
    expect(_faults('x', 'line_fr', 'vous avez été payé.'), ['gendered form']);
    expect(_faults('x', 'line_fr', 'Et vous voilà tout près.'), isEmpty);
    expect(_faults('shops.json', 'keeperLineKnown_fr', 'Un ami$nbsp! Entrez.'),
        ['gendered friend']);
    expect(
        _faults('items.json', 'description_fr', 'Un ami l’a forgé.'), isEmpty);
  });

  test('the French strings are found through maps and lists', () {
    final found = _french({
      'name': 'Rat',
      'name_fr': 'Rat',
      'phases': [
        {'nameFr': 'Frénésie', 'heal': 1},
      ],
      'lines_fr': ['Un', 'Deux'],
      'nested': {
        'deep_fr': {'en': 'x', 'fr': 'y'},
      },
      'Fr': 'not a French key',
    }, 'r')
        .toList();
    expect(found.map((f) => f.path), [
      'r.name_fr',
      'r.phases[0].nameFr',
      'r.lines_fr[0]',
      'r.lines_fr[1]',
      'r.nested.deep_fr.en',
      'r.nested.deep_fr.fr',
    ]);
    expect(found.map((f) => f.field).toSet(),
        {'name_fr', 'nameFr', 'lines_fr', 'deep_fr'});
  });

  test('every French string keeps French typography and says « vous »', () {
    final failures = <String>[];
    final stillExempt = <String, Set<String>>{};
    var checked = 0;
    for (final file in data.entries) {
      for (final record in file.value.entries) {
        final faults = <String>[];
        for (final s in _french(record.value, record.key)) {
          checked++;
          for (final fault in _faults(file.key, s.field, s.text)) {
            faults.add('${s.path}: $fault: "${s.text}"');
          }
        }
        if (faults.isEmpty) continue;
        if (_allowlist[file.key]?.contains(record.key) ?? false) {
          (stillExempt[file.key] ??= {}).add(record.key);
        } else {
          failures.add('${file.key} ${faults.join('\n  ')}');
        }
      }
    }
    // 4,754 strings as of v1.209.
    expect(checked, greaterThan(4000));
    expect(failures, isEmpty, reason: failures.join('\n'));
    // An exempt record that reads clean now leaves the allowlist.
    for (final file in _allowlist.entries) {
      for (final id in file.value) {
        expect(data[file.key]?.containsKey(id) ?? false, isTrue,
            reason: '${file.key} $id is in the allowlist but not the data');
        expect(stillExempt[file.key]?.contains(id) ?? false, isTrue,
            reason:
                '${file.key} $id reads clean: remove it from the allowlist');
      }
    }
  });

  test('the allowlist only shrinks', () {
    final size = _allowlist.values.fold<int>(0, (n, ids) => n + ids.length);
    expect(size, lessThanOrEqualTo(_allowlistSize),
        reason: 'fix the French rather than exempt it');
  });
}
