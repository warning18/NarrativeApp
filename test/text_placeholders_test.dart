import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/combat/spec_variants.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/description_text.dart';
import 'package:narrative_data_app/data/text_placeholders.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('numbers: whole, fractions, the French comma', () {
    expect(formatPlaceholderNumber(3, AppLanguage.en), '3');
    expect(formatPlaceholderNumber(2.0, AppLanguage.en), '2');
    expect(formatPlaceholderNumber(1.6, AppLanguage.en), '1.6');
    expect(formatPlaceholderNumber(1.6, AppLanguage.fr), '1,6');
    expect(formatPlaceholderNumber(1.875, AppLanguage.en), '1.88');
    expect(formatPlaceholderNumber(-2, AppLanguage.fr), '-2');
  });

  test('an unknown placeholder stays visible, braces and all', () {
    const text = 'Blocks {block}, then {nonsense} and {not a placeholder}.';
    expect(resolvePlaceholders(text, {'block': 2}, AppLanguage.en),
        'Blocks 2, then {nonsense} and {not a placeholder}.');
    expect(unresolvedPlaceholders(text, {'block': 2}), ['{nonsense}']);
  });

  test('spells.json: amount, effect name, multiplier, mana, status', () {
    final spell = SpellSpec.fromJson('spell_test', {
      'spellName': 'Test Bolt',
      'description': 'Your damage plus {damage}, times {multiplier}; '
          'costs {mana}. Stuns {duration} round.',
      'description_fr': 'Vos dégâts plus {damage}, fois {multiplier} ; '
          'coûte {mana}. Étourdit {duration} tour.',
      'manaCost': 2,
      'effect': 'Damage',
      'amount': 1,
      'damageMultiplier': 1.6,
      'inflictsStatus': 'Stun',
      'statusDuration': 1,
    });
    expect(spell.descriptionFor(AppLanguage.en),
        'Your damage plus 1, times 1.6; costs 2. Stuns 1 round.');
    expect(spell.descriptionFor(AppLanguage.fr),
        'Vos dégâts plus 1, fois 1,6 ; coûte 2. Étourdit 1 tour.');
    // A Damage spell has no {heal}: it stays for the content test to find.
    expect(unresolvedPlaceholders('Heals {heal}.', spell.placeholders),
        ['{heal}']);
  });

  test('item_sets.json: each bonus tier fills its own numbers', () {
    final set = ItemSet.fromJson('kit', {
      'setName': 'Kit',
      'itemIds': ['a', 'b'],
      'bonuses': [
        {
          'pieces': 2,
          'armor': 1,
          'dodgeChance': 5,
          'description': '{pieces} pieces: +{armor} armor and +{dodge}% dodge.',
          'descriptionFr':
              '{pieces} pièces : +{armor} armure et +{dodge} % d’esquive.',
        },
      ],
    });
    final tier = set.tiers.single;
    expect(tier.descriptionFor(AppLanguage.en),
        '2 pieces: +1 armor and +5% dodge.');
    expect(tier.descriptionFor(AppLanguage.fr),
        '2 pièces : +1 armure et +5 % d’esquive.');
    // The table as the screens read it: nested tiers resolved too.
    final resolved = withResolvedPlaceholders('item_sets', {
      'kit': {
        'bonuses': [
          {'pieces': 3, 'attackDamage': 2, 'description': '+{attack} attack'},
        ],
      },
    });
    expect(((resolved['kit'] as Map)['bonuses'] as List).single['description'],
        '+2 attack');
  });

  test('skills.json: the record fields, shares as percents', () {
    final records = withResolvedPlaceholders('skills', {
      'cleave': {
        'damageMod': 2,
        'damageMultiplier': 1.25,
        'splashShare': 0.5,
        'statusDuration': 2,
        'description': '+{damage}, x{multiplier}; {splash}% to the others '
            'for {duration} turns.',
        'description_fr': '+{damage}, x{multiplier} ; {splash} % aux autres '
            'pendant {duration} tours.',
      },
    });
    final skill = records['cleave'] as Map<String, dynamic>;
    expect(skill['description'], '+2, x1.25; 50% to the others for 2 turns.');
    expect(skill['description_fr'],
        '+2, x1,25 ; 50 % aux autres pendant 2 tours.');
    // A table without placeholders comes back as it is.
    final plain = {
      'a': {'description': 'No numbers.'}
    };
    expect(identical(withResolvedPlaceholders('skills', plain), plain), isTrue);
  });

  test('spec_variants.json: the numbers come from SpecMods', () {
    final info = SpecVariantInfo.tryParse('reliquary_thieves_relicbreaker', {
      'spec': 'relicbreaker',
      'kind': 'upgrade',
      'subclan': 'reliquary_thieves',
      'text': 'Each critical hit gives {mana} mana (not {baseMana}).',
      'text_fr': 'Chaque coup critique donne {mana} de mana.',
    })!;
    expect(info.textFor(false), 'Each critical hit gives 2 mana (not 1).');
    expect(info.textFor(true), 'Chaque coup critique donne 2 de mana.');
    expect(specVariantPlaceholders('brig_born_berserker')['heal'], 10);
    expect(specVariantPlaceholders('berserker_ii')['rank'], 50);
  });

  test('every placeholder in the four files can be filled', () {
    for (final name in placeholderTextFields.keys) {
      expect(unresolvedPlaceholdersIn(name, _table(name)), isEmpty,
          reason: '$name.json names a number its record does not have '
              '(see docs/proposals/text-placeholders.md)');
    }
  });
}
