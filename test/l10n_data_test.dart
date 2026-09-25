import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/dice_names_fr.dart';
import 'package:narrative_data_app/l10n/skill_names_fr.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';

Map<String, dynamic> _load(String file) =>
    jsonDecode(File('assets/gamedata/$file').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('the French skill names match skills.json', () {
    final skills = _load('skills.json');
    expect(skillNamesFr.keys.toSet(), skills.keys.toSet());
    for (final entry in skills.entries) {
      expect(skillNamesFr[entry.key], (entry.value as Map)['name_fr'],
          reason: entry.key);
    }
  });

  test('the French dice names match dice.json', () {
    final dice = _load('dice.json');
    expect(diceNamesFr.keys.toSet(), dice.keys.toSet());
    for (final entry in dice.entries) {
      expect(diceNamesFr[entry.key], (entry.value as Map)['diceName_fr'],
          reason: entry.key);
    }
  });

  test('every named record has a French name', () {
    const nameFields = {
      'items.json': 'itemName_fr',
      'dice.json': 'diceName_fr',
      'enemies.json': 'enemyName_fr',
      'shops.json': 'shopName_fr',
      'skills.json': 'name_fr',
      'spells.json': 'spellName_fr',
      'quests.json': 'questName_fr',
      'zones.json': 'zoneName_fr',
      'races.json': 'raceName_fr',
      'professions.json': 'professionName_fr',
      'houses.json': 'houseName_fr',
      'skill_trees.json': 'branchName_fr',
      'achievements.json': 'achievementName_fr',
    };
    for (final file in nameFields.entries) {
      for (final record in _load(file.key).entries) {
        final french = (record.value as Map)[file.value]?.toString() ?? '';
        expect(french.trim(), isNotEmpty,
            reason: '${file.key} ${record.key} has no ${file.value}');
      }
    }
  });

  test('titled companions and people have a French name', () {
    // A bare given name ("Kelda", "Malrik Sarn") reads the same in French;
    // a title ("Sister Maren", "Old Harker") has to be translated.
    const titles = ['Sister', 'Brother', 'Old', 'Captain', 'Father', 'Mother'];
    for (final file in {
      'companions.json': 'companionName',
      'npcs.json': 'npcName',
    }.entries) {
      for (final record in _load(file.key).entries) {
        final map = record.value as Map;
        final english = map[file.value]?.toString() ?? '';
        if (!titles.any((t) => english.startsWith('$t '))) continue;
        expect(map['${file.value}_fr']?.toString() ?? '', isNotEmpty,
            reason: '${file.key} ${record.key}');
      }
    }
  });

  test('names read in the chosen language', () {
    expect(dieDisplayName('iron_die'), 'Iron Die');
    expect(dieDisplayName('iron_die', language: AppLanguage.fr),
        diceNamesFr['iron_die']);
    expect(
        dieDisplayName('unknown_die', language: AppLanguage.fr), 'Unknown Die');
    expect(skillDisplayName('fireball', language: AppLanguage.fr),
        skillNamesFr['fireball']);
  });

  test('the French overlay lays filled French text over the English', () {
    final records = {
      'rat': {
        'enemyName': 'Rat',
        'enemyName_fr': 'Rat d’égout',
        'description': 'Small.',
        'description_fr': '',
        'phases': [
          {'name': 'Frenzy', 'nameFr': 'Frénésie', 'healPercent': 10},
        ],
        'maxHealth': 20,
      },
    };
    final french = frenchOverlay(records)['rat'] as Map<String, dynamic>;
    expect(french['enemyName'], 'Rat d’égout');
    expect(french['description'], 'Small.', reason: 'empty French is skipped');
    expect((french['phases'] as List).single['name'], 'Frénésie');
    expect(french['maxHealth'], 20);
    expect(records['rat']!['enemyName'], 'Rat', reason: 'originals untouched');
  });
}
