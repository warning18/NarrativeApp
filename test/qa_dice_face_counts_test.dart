// QA guard (the user's rule of 12 November): every die a player, an ally or an
// enemy can roll has exactly 4, 6, 8, 10 or 12 faces: no odd counts, nothing
// above 12.
//
// Three places make dice, and each is read here as the game reads it:
//  - dice.json: the `faces` list of every die, and its declared
//    `numberOfFaces`, which must agree with it;
//  - the Tower's own table (TowerData.dice, `towerDiceTable`: the Tower's
//    faces of its dice unlocks replace dice.json's);
//  - the dice built in code: the tally die the Skillwright recuts from two d8s
//    (`tallyDieId`, 12 plain faces) comes from dice.json, the clans' Resonance
//    changes faces, not their number (clan_dice.dart): both are read through
//    the first two.
//
// While a die breaks the rule the test FAILS and says which ids, with what
// counts, so the report and the guard are one file.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';

const _allowed = {4, 6, 8, 10, 12};

void main() {
  final dice = jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
      as Map<String, dynamic>;

  String describe(Map<String, int> bad) =>
      bad.entries.map((e) => '${e.key} (${e.value} faces)').join(', ');

  test('every die of dice.json has 4, 6, 8, 10 or 12 faces, as it declares',
      () {
    final bad = <String, int>{};
    final disagree = <String>[];
    for (final e in dice.entries) {
      final die = e.value as Map<String, dynamic>;
      final faces = (die['faces'] as List).length;
      final declared = (die['numberOfFaces'] as num?)?.toInt();
      if (!_allowed.contains(faces)) bad[e.key] = faces;
      if (declared != null && declared != faces) {
        disagree.add('${e.key}: declares $declared, has $faces');
      }
    }
    expect(bad, isEmpty,
        reason: 'dice.json: ${bad.length} of ${dice.length} dice outside '
            '{4, 6, 8, 10, 12}: ${describe(bad)}');
    expect(disagree, isEmpty,
        reason: 'numberOfFaces and the faces list disagree: $disagree');
  });

  test('every die the Tower rolls has 4, 6, 8, 10 or 12 faces', () {
    final tower = towerDataFromAssets().dice;
    final bad = <String, int>{};
    final changed = <String>[];
    for (final e in tower.entries) {
      final faces = ((e.value as Map)['faces'] as List).length;
      if (!_allowed.contains(faces)) bad[e.key] = faces;
      final base = (dice[e.key] as Map<String, dynamic>)['faces'] as List;
      if (faces != base.length) {
        changed
            .add('${e.key}: ${base.length} in dice.json, $faces in the Tower');
      }
    }
    expect(bad, isEmpty,
        reason: 'the Tower rolls ${bad.length} dice outside {4, 6, 8, 10, 12}: '
            '${describe(bad)}');
    // The Tower's own faces keep the die's size (towerDieFaces says so).
    expect(changed, isEmpty,
        reason: 'the Tower resized dice: ${changed.join('; ')}');
  });
}
