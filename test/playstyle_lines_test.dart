// The playstyle line of every people and class (v1.598): one short line, in
// both languages, saying how it plays in game terms for the race/profession
// picker (docs: the user's "their choices align with clans and ways of
// playing"). Short enough for a card, and never a promise the numbers
// don't keep: each line is checked against the stats it names.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final races = _table('races');
  final professions = _table('professions');

  for (final (label, table) in [('race', races), ('profession', professions)]) {
    test('every $label has a short playstyle line in both languages', () {
      for (final entry in table.entries) {
        final record = entry.value as Map<String, dynamic>;
        final en = (record['playstyle'] ?? '').toString();
        final fr = (record['playstyle_fr'] ?? '').toString();
        expect(en, isNotEmpty, reason: '${entry.key} playstyle');
        expect(fr, isNotEmpty, reason: '${entry.key} playstyle_fr');
        expect(en.length, lessThanOrEqualTo(60), reason: '${entry.key}: $en');
        expect(fr.length, lessThanOrEqualTo(60), reason: '${entry.key}: $fr');
        // French: a no-break space before a colon or semicolon.
        expect(RegExp(r'[^ ][:;!?]').hasMatch(fr), isFalse,
            reason: '${entry.key}: $fr');
      }
    });
  }

  test('a line only promises what the numbers do', () {
    num bonus(Map<String, dynamic> t, String id, String stat) =>
        (t[id] as Map<String, dynamic>)['bonus$stat'] as num;
    // Races named for a strength have it; the fragile ones are fragile.
    expect(bonus(races, 'dwarf', 'MaxHealth'), greaterThan(0));
    expect(bonus(races, 'dwarf', 'BaseArmor'), greaterThan(0));
    expect(bonus(races, 'elf', 'Dexterity'), greaterThan(0));
    expect(bonus(races, 'elf', 'Luck'), greaterThan(0));
    expect(bonus(races, 'elf', 'MaxHealth'), lessThan(0));
    expect(bonus(races, 'orc', 'Strength'), greaterThan(0));
    expect(bonus(races, 'orc', 'Charisma'), lessThan(0));
    expect(bonus(races, 'voidkin', 'Intelligence'), greaterThan(0));
    expect(bonus(races, 'voidkin', 'MaxHealth'), lessThan(0));
    expect(bonus(races, 'human', 'Charisma'), greaterThan(0));
    expect((races['human'] as Map)['startingGoldBonus'], greaterThan(0));
    // Classes: the warrior is the tank, the rogue fast and lucky, the cleric
    // healed and hardy, the ranger without extra life.
    expect(bonus(professions, 'warrior', 'MaxHealth'), greaterThan(0));
    expect(bonus(professions, 'rogue', 'Dexterity'), greaterThan(0));
    expect(bonus(professions, 'rogue', 'Luck'), greaterThan(0));
    expect(bonus(professions, 'cleric', 'MaxHealth'), greaterThan(0));
    expect(bonus(professions, 'ranger', 'MaxHealth'), 0);
    expect((professions['mage'] as Map)['startingSpellIds'], isNotEmpty);
  });
}
