// Keeps spells.json, the spellbooks in items.json, the professions'
// starting spells/dice and the Mana faces in dice.json consistent with each
// other -- a spell nobody can learn, a spellbook teaching a spell that
// doesn't exist, or a starting die whose Technique faces sit at the wrong
// indexes would each only show up as a fizzle in play.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';

Map<String, dynamic> _loadGamedata(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $name under ${Directory.current.path}');
}

void main() {
  final spellsDb = _loadGamedata('spells.json');
  final spells = parseSpells(spellsDb);
  final professions = _loadGamedata('professions.json');
  final items = _loadGamedata('items.json');
  final shops = _loadGamedata('shops.json');
  final dice = _loadGamedata('dice.json');

  group('spells.json', () {
    test('every spell is well-formed and belongs to a real profession', () {
      expect(spells, isNotEmpty);
      for (final entry in spellsDb.entries) {
        final raw = entry.value as Map<String, dynamic>;
        final spell = spells[entry.key]!;
        expect(raw['spellID'], entry.key);
        expect(spell.name, isNotEmpty);
        expect(spell.nameFr, isNotEmpty, reason: '${entry.key} has no FR name');
        expect(spell.description, isNotEmpty);
        expect(spell.descriptionFr, isNotEmpty);
        expect(spell.manaCost, greaterThanOrEqualTo(1));
        expect(professions, contains(spell.professionId),
            reason: '${entry.key} names unknown profession');
        expect(spellEffectOptions, contains(raw['effect']));
        expect(spellTargetOptions, contains(raw['target']));
        expect(spellScalingOptions, contains(raw['scalingStat']));
        expect(elementOptions, contains(raw['element']));
        if (spell.effect == SpellEffectKind.status) {
          expect(spell.status, isNotNull,
              reason: '${entry.key} is a Status spell with no status');
          expect(spell.hitsEnemies, isTrue);
        }
        if (spell.effect == SpellEffectKind.damage) {
          expect(spell.damageMultiplier, greaterThan(0));
        }
        if (spell.effect == SpellEffectKind.heal ||
            spell.effect == SpellEffectKind.block) {
          expect(spell.amount, greaterThan(0));
        }
        if (spell.effect == SpellEffectKind.heal ||
            spell.effect == SpellEffectKind.block ||
            spell.effect == SpellEffectKind.cleanse) {
          expect(spell.hitsEnemies, isFalse,
              reason: '${entry.key} helps but targets enemies');
        }
      }
    });

    test('every spell is obtainable: a starting spell or a stocked spellbook',
        () {
      final starting = <String>{
        for (final p in professions.values)
          ...((p as Map<String, dynamic>)['startingSpellIds'] as List? ??
                  const [])
              .map((e) => e.toString()),
      };
      final stocked = <String>{
        for (final s in shops.values)
          ...((s as Map<String, dynamic>)['initialStock'] as List? ?? const [])
              .map((e) => e.toString()),
      };
      final taughtByStockedBooks = <String>{
        for (final entry in items.entries)
          if (stocked.contains(entry.key))
            if (spellbookSpellIdFor(entry.value as Map<String, dynamic>) !=
                null)
              spellbookSpellIdFor(entry.value as Map<String, dynamic>)!,
      };
      for (final id in spells.keys) {
        expect(
            starting.contains(id) || taughtByStockedBooks.contains(id), isTrue,
            reason: '$id is neither a starting spell nor sold in any shop');
      }
    });
  });

  group('spellbooks', () {
    test('every Spellbook item teaches a real spell, and only one book each',
        () {
      final taught = <String>[];
      for (final entry in items.entries) {
        final item = entry.value as Map<String, dynamic>;
        final spellId = spellbookSpellIdFor(item);
        if (item['itemType'] == 'Spellbook') {
          expect(spellId, isNotNull, reason: '${entry.key} teaches nothing');
          expect(spells, contains(spellId),
              reason: '${entry.key} teaches unknown $spellId');
          expect(item['isEquippable'], isNot(true));
          expect((item['cost'] as num).toInt(), greaterThan(0));
          taught.add(spellId!);
        } else {
          expect(spellId, isNull);
        }
      }
      expect(taught.toSet().length, taught.length,
          reason: 'two spellbooks teach the same spell');
    });

    test('a starting spell is never also sold as a spellbook', () {
      final starting = <String>{
        for (final p in professions.values)
          ...((p as Map<String, dynamic>)['startingSpellIds'] as List? ??
                  const [])
              .map((e) => e.toString()),
      };
      for (final item in items.values) {
        final spellId = spellbookSpellIdFor(item as Map<String, dynamic>);
        if (spellId != null) expect(starting, isNot(contains(spellId)));
      }
    });
  });

  group('professions', () {
    test('starting spells exist and belong to that profession', () {
      for (final entry in professions.entries) {
        final profession = entry.value as Map<String, dynamic>;
        for (final raw in profession['startingSpellIds'] as List? ?? const []) {
          final spell = spells[raw.toString()];
          expect(spell, isNotNull,
              reason: '${entry.key} starts with unknown spell $raw');
          expect(spell!.professionId, entry.key);
        }
      }
    });

    test(
        'a starting die exists and keeps the Technique faces at the starter '
        'die\'s indexes 4 and 5', () {
      final starter =
          (dice['starter_die'] as Map<String, dynamic>)['faces'] as List;
      expect((starter[4] as Map)['type'], 'Skill');
      expect((starter[5] as Map)['type'], 'Skill');
      for (final entry in professions.entries) {
        final id = (entry.value as Map<String, dynamic>)['startingDiceId']
                ?.toString() ??
            '';
        if (id.isEmpty) continue;
        expect(dice, contains(id),
            reason: '${entry.key} starts with unknown die $id');
        final faces = (dice[id] as Map<String, dynamic>)['faces'] as List;
        expect(faces.length, greaterThanOrEqualTo(6));
        expect((faces[4] as Map)['type'], 'Skill');
        expect((faces[4] as Map)['linkedSkillID'], '');
        expect((faces[5] as Map)['type'], 'Skill');
        expect((faces[5] as Map)['linkedSkillID'], '');
      }
    });

    test('a Mage and a Cleric start with a die that has Mana faces', () {
      for (final id in ['mage', 'cleric']) {
        final dieId =
            (professions[id] as Map<String, dynamic>)['startingDiceId'];
        final faces = (dice[dieId] as Map<String, dynamic>)['faces'] as List;
        expect(faces.any((f) => (f as Map)['type'] == 'Mana'), isTrue);
      }
    });
  });

  group('dice.json Mana faces', () {
    test(
        'every face type is a known option and every Mana face restores '
        'at least 1', () {
      var manaDice = 0;
      for (final entry in dice.entries) {
        final faces = (entry.value as Map<String, dynamic>)['faces'] as List;
        var hasMana = false;
        for (final raw in faces) {
          final face = raw as Map;
          expect(faceTypeOptions, contains(face['type']),
              reason: '${entry.key} has a ${face['type']} face');
          if (face['type'] == 'Mana') {
            hasMana = true;
            expect((face['value'] as num).toInt(), greaterThanOrEqualTo(1));
          }
        }
        if (hasMana) manaDice++;
      }
      expect(manaDice, greaterThanOrEqualTo(4));
    });

    test('the sage die is sold somewhere', () {
      final stocked = <String>{
        for (final s in shops.values)
          ...((s as Map<String, dynamic>)['diceStock'] as List? ?? const [])
              .map((e) => e.toString()),
      };
      expect(stocked, contains('sage_die'));
      expect(stocked, contains('apprentice_die'));
      for (final id in stocked) {
        expect(dice, contains(id), reason: 'a shop stocks unknown die $id');
      }
    });
  });
}
