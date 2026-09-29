// French speaks to the player as « vous » (v1.168): the interface, the
// companions' lines and what they say in the story's asides. Lines a
// companion throws at an enemy (a dodge) may still say « tu ».
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/ally_acknowledgments.dart';

final _tu = RegExp(
    r"(?<!\p{L})(?:(?:tu|toi|ton|ta|tes|te)(?!\p{L})|t['’](?=\p{L}))",
    caseSensitive: false,
    unicode: true);

/// Second-person singular commands a companion might give the player
/// (as written: « Reste » opens a command, « je reste » doesn't).
final _tuCommand = RegExp(
    r'(?<!\p{L})(?:Reste au|Essaie|Ne touche|Ouvre|Prends|Laisse|Mets-toi|'
    r"relève-toi|tiens-toi|Sers-t|n'écoute|Demande-lui|fais-le)(?!\p{L})",
    unicode: true);

bool _saysTu(String text) => _tu.hasMatch(text) || _tuCommand.hasMatch(text);

void main() {
  test('companions say « vous » to the player, except to enemies', () {
    final companions =
        jsonDecode(File('assets/gamedata/companions.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final entry in companions.entries) {
      for (final field in (entry.value as Map<String, dynamic>).entries) {
        final key = field.key;
        if (!(key.endsWith('Fr') || key.endsWith('_fr'))) continue;
        if (key == 'dodgeLineFr') continue; // said to the enemy
        expect(_saysTu(field.value.toString()), isFalse,
            reason: '${entry.key}.$key: ${field.value}');
      }
    }
  });

  test("what companions say in the story's asides is in « vous »", () {
    for (final nodeId in acknowledgedNodeIds) {
      for (final line in allyAcknowledgmentVariantsFor(nodeId, french: true)) {
        for (final quote in RegExp(r'«([^»]*)»').allMatches(line)) {
          expect(_saysTu(quote.group(1)!), isFalse,
              reason: '$nodeId: ${quote.group(1)}');
        }
      }
    }
  });

  test('the interface speaks to the player as « vous »', () {
    final source = File('lib/l10n/app_strings.dart').readAsStringSync();
    final french = RegExp(
        r'''AppLanguage\.fr:\s*((?:'(?:[^'\\]|\\.)*'\s*|"(?:[^"\\]|\\.)*"\s*)+)''');
    final literal = RegExp(r'''^'((?:[^'\\]|\\.)*)'|^"((?:[^"\\]|\\.)*)"''');
    var checked = 0;
    for (final match in french.allMatches(source)) {
      var rest = match.group(1)!.trim();
      final text = StringBuffer();
      while (rest.isNotEmpty) {
        final part = literal.firstMatch(rest);
        if (part == null) break;
        text.write(part.group(1) ?? part.group(2));
        rest = rest.substring(part.end).trim();
      }
      checked++;
      expect(_tu.hasMatch(text.toString()), isFalse, reason: '$text');
    }
    expect(checked, greaterThan(500));
  });
}
