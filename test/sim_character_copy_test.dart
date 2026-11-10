// SimCharacter.copy (v1.880): every field the class declares is copied,
// and the copy's collections are its own. The Tower builds its hero from a
// copy (towerHeroOf), so a field left out would drift a climb quietly.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';

const _statements = {'return', 'break', 'continue'};

/// The fields SimCharacter declares, read from its source.
Set<String> _declaredFields(String source) {
  final start = source.indexOf('class SimCharacter {');
  final end = source.indexOf('\n}\n', start);
  final body = source.substring(start, end);
  final fields = <String>{};
  // A field at the class's indent: "  int level = 1;", "  final Set<String>
  // ownedItemIds = {};", "  late ...;", and a type that spans lines whose
  // name ends it alone ("      dieTrial;").
  final oneLine =
      RegExp(r'^  (?=\S)(?:final |late )?[\w<>?, ()]+ (_?\w+)(?: = .*)?;$');
  final lastLine = RegExp(r'^      (_?\w+);$');
  for (final line in body.split('\n')) {
    final m = oneLine.firstMatch(line) ?? lastLine.firstMatch(line);
    // (A method's bare "return;" or "break;" is no field.)
    if (m != null && !_statements.contains(m.group(1))) fields.add(m.group(1)!);
  }
  return fields;
}

void main() {
  final source = File('lib/data/sim_combat.dart').readAsStringSync();

  test('copy() names every field the class declares', () {
    final fields = _declaredFields(source);
    // The class's own fields, so the scan itself is checked.
    expect(
        fields,
        containsAll([
          'raceId',
          'level',
          'ownedDice',
          'dieTrial',
          '_dieFailedAt',
          'pickedPoints',
          'alignmentLabel'
        ]));
    expect(fields.length, greaterThan(40));
    final copy = source.substring(source.indexOf('SimCharacter copy() =>'),
        source.indexOf('\n}\n', source.indexOf('SimCharacter copy() =>')));
    final missing = [
      for (final f in fields)
        if (!RegExp('(^|[^\\w])${RegExp.escape(f)}[: ]').hasMatch(copy) &&
            !copy.contains('..$f'))
          f,
    ];
    expect(missing, isEmpty, reason: 'fields copy() leaves out: $missing');
  });

  test('a copy is the same hero, with collections of its own', () {
    final data = towerDataFromAssets();
    final run = playTowerRun(seed: 11, data: data, progress: towerAllUnlocked);
    final hero = towerHeroOf(run, data);
    final copy = hero.copy();
    String sheet(dynamic c) => [
          c.level,
          c.maxHealth,
          c.currentHealth,
          c.strength,
          c.dexterity,
          c.constitution,
          c.intelligence,
          c.wisdom,
          c.luck,
          c.perception,
          c.charisma,
          c.baseDamage,
          c.baseArmor,
          c.potions,
          c.mana,
          c.diceId,
          c.diceSkillAssignments,
          c.unlockedSkillIds,
          c.equippedBySlot,
          c.ownedDice.keys.toList(),
          [for (final s in c.knownSpells) s.id],
          c.trainingTaken,
          c.pickedPoints,
        ].join('|');
    expect(sheet(copy), sheet(hero));
    // Its own collections: changing the copy leaves the hero as it was.
    copy.unlockedSkillIds.add('zz');
    copy.equippedBySlot['zz'] = 'zz';
    copy.ownedDice['zz'] = const [];
    copy.trainingTaken['zz'] = 1;
    copy.pickedPoints['zz'] = 1;
    final spells = hero.knownSpells.length;
    copy.knownSpells.clear();
    expect(sheet(towerHeroOf(run, data)), sheet(hero));
    expect(hero.unlockedSkillIds, isNot(contains('zz')));
    expect(hero.knownSpells, hasLength(spells));
  });
}
