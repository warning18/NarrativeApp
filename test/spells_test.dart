// Unit coverage for lib/combat/spells.dart -- the pure half of the mana and
// spell system: the mana pool formula, spell parsing, scaling and the
// spellbook learning gate. The fight screen's casting flow sits on top of
// these and is exercised by hand; the numbers it shows come from here.

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/combat/status_effect.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

const Map<String, dynamic> _frostBind = {
  'spellID': 'spell_frost_bind',
  'spellName': 'Frost Bind',
  'spellName_fr': 'Entrave de givre',
  'description': 'Ice locks one enemy in place.',
  'description_fr': '',
  'professionID': 'mage',
  'manaCost': 3,
  'effect': 'Damage',
  'target': 'Enemy',
  'amount': 8,
  'damageMultiplier': 1.5,
  'scalingStat': 'intelligence',
  'element': 'Ice',
  'inflictsStatus': 'Stun',
  'statusDuration': 1,
  'statusMagnitude': 0,
  'battleMessage': 'Frost crawls up its limbs.',
  'battleMessage_fr': 'Le givre remonte.',
};

void main() {
  group('maxManaFor', () {
    test('base mana plus half the higher of Intelligence and Wisdom', () {
      expect(maxManaFor(intelligence: 0, wisdom: 0), baseMana);
      expect(maxManaFor(intelligence: 4, wisdom: 1), baseMana + 2);
      expect(maxManaFor(intelligence: 1, wisdom: 5), baseMana + 2);
      expect(maxManaFor(intelligence: 9, wisdom: 9), baseMana + 4);
    });
  });

  group('SpellSpec.fromJson', () {
    final spell = SpellSpec.fromJson('spell_frost_bind', _frostBind);

    test('parses cost, effect, target, scaling, element and status', () {
      expect(spell.id, 'spell_frost_bind');
      expect(spell.professionId, 'mage');
      expect(spell.manaCost, 3);
      expect(spell.effect, SpellEffectKind.damage);
      expect(spell.target, SpellTarget.enemy);
      expect(spell.amount, 8);
      expect(spell.damageMultiplier, 1.5);
      expect(spell.scalingStat, 'intelligence');
      expect(spell.element, 'Ice');
      expect(spell.status, isNotNull);
      expect(spell.status!.type, StatusEffectType.stun);
      expect(spell.status!.remainingTurns, 1);
      expect(spell.needsEnemyPick, isTrue);
      expect(spell.needsAllyPick, isFalse);
      expect(spell.hitsEnemies, isTrue);
    });

    test('no status for an empty inflictsStatus or a zero duration', () {
      final plain =
          SpellSpec.fromJson('a', {..._frostBind, 'inflictsStatus': ''});
      expect(plain.status, isNull);
      final zero =
          SpellSpec.fromJson('b', {..._frostBind, 'statusDuration': 0});
      expect(zero.status, isNull);
    });

    test('unknown effect/target fall back to damage on one enemy', () {
      final odd = SpellSpec.fromJson(
          'c', {..._frostBind, 'effect': 'Nonsense', 'target': 'Moon'});
      expect(odd.effect, SpellEffectKind.damage);
      expect(odd.target, SpellTarget.enemy);
    });

    test('French text is used when present and falls back when empty', () {
      expect(spell.nameFor(AppLanguage.fr), 'Entrave de givre');
      expect(spell.nameFor(AppLanguage.en), 'Frost Bind');
      expect(spell.descriptionFor(AppLanguage.fr), spell.description);
      expect(spell.battleMessageFor(AppLanguage.fr), 'Le givre remonte.');
    });

    test('a negative mana cost reads as free', () {
      final free = SpellSpec.fromJson('d', {..._frostBind, 'manaCost': -2});
      expect(free.manaCost, 0);
    });
  });

  group('spellAmountFor', () {
    final spell = SpellSpec.fromJson('spell_frost_bind', _frostBind);

    test('a damage spell rides the caster\'s own damage like a skill', () {
      // (casterDamage 16 + amount 8 + intelligence 6 ~/ 2) x 1.5
      expect(
          spellAmountFor(spell, intelligence: 6, wisdom: 20, casterDamage: 16),
          41);
      expect(
          spellAmountFor(spell, intelligence: 0, wisdom: 20, casterDamage: 0),
          12);
      final flat = SpellSpec.fromJson('e', {..._frostBind, 'scalingStat': ''});
      expect(
          spellAmountFor(flat, intelligence: 10, wisdom: 10, casterDamage: 10),
          27);
      final wise =
          SpellSpec.fromJson('f', {..._frostBind, 'scalingStat': 'wisdom'});
      expect(spellAmountFor(wise, intelligence: 10, wisdom: 4, casterDamage: 0),
          15);
    });

    test('healing and block grow with level, never with caster damage', () {
      final heal = SpellSpec.fromJson('h', {
        ..._frostBind,
        'effect': 'Heal',
        'target': 'Ally',
        'amount': 20,
        'scalingStat': 'wisdom',
      });
      expect(spellAmountFor(heal, intelligence: 0, wisdom: 4, casterDamage: 99),
          22);
      expect(
          spellAmountFor(heal,
              intelligence: 0, wisdom: 4, level: 11, casterDamage: 99),
          (22 * 2.2).round());
      final block = SpellSpec.fromJson('b', {
        ..._frostBind,
        'effect': 'Block',
        'target': 'Party',
        'amount': 10,
        'scalingStat': ''
      });
      expect(spellAmountFor(block, intelligence: 0, wisdom: 0, level: 6), 16);
    });

    test('status and cleanse spells have no amount', () {
      final hex = SpellSpec.fromJson(
          'x', {..._frostBind, 'effect': 'Status', 'amount': 50});
      expect(
          spellAmountFor(hex, intelligence: 9, wisdom: 9, casterDamage: 9), 0);
    });
  });

  group('spellStatusFor', () {
    test('a Poison grows with level, a Stun does not, no status stays null',
        () {
      final hex = SpellSpec.fromJson('x', {
        ..._frostBind,
        'effect': 'Status',
        'inflictsStatus': 'Poison',
        'statusDuration': 3,
        'statusMagnitude': 6,
      });
      final poison = spellStatusFor(hex, level: 11)!;
      expect(poison.type, StatusEffectType.poison);
      expect(poison.remainingTurns, 3);
      expect(poison.magnitude, (6 * 1.8).round());
      final stun =
          spellStatusFor(SpellSpec.fromJson('s', _frostBind), level: 11)!;
      expect(stun.type, StatusEffectType.stun);
      expect(stun.magnitude, 0);
      final none =
          SpellSpec.fromJson('n', {..._frostBind, 'inflictsStatus': ''});
      expect(spellStatusFor(none, level: 5), isNull);
    });
  });

  group('canLearnSpell', () {
    final spell = SpellSpec.fromJson('spell_frost_bind', _frostBind);

    test('only the spell\'s own profession, and never twice', () {
      expect(
          canLearnSpell(spell, professionId: 'mage', knownSpellIds: const []),
          isTrue);
      expect(
          canLearnSpell(spell,
              professionId: 'warrior', knownSpellIds: const []),
          isFalse);
      expect(
          canLearnSpell(spell,
              professionId: 'mage', knownSpellIds: const ['spell_frost_bind']),
          isFalse);
    });

    test('a spell with no profession is open to everyone', () {
      final open = SpellSpec.fromJson('g', {..._frostBind, 'professionID': ''});
      expect(
          canLearnSpell(open, professionId: 'rogue', knownSpellIds: const []),
          isTrue);
    });
  });

  group('spellbookSpellIdFor', () {
    test('reads a Spellbook item\'s taught spell and nothing else', () {
      expect(
          spellbookSpellIdFor(const {
            'itemType': 'Spellbook',
            'teachesSpellId': 'spell_war_shout',
          }),
          'spell_war_shout');
      expect(spellbookSpellIdFor(const {'itemType': 'Spellbook'}), isNull);
      expect(
          spellbookSpellIdFor(
              const {'itemType': 'Tome', 'teachesSpellId': 'spell_war_shout'}),
          isNull);
      expect(spellbookSpellIdFor(null), isNull);
    });
  });

  group('parseSpells', () {
    test('keys every record by its table key and skips non-records', () {
      final parsed = parseSpells({
        'spell_frost_bind': _frostBind,
        'junk': 3,
      });
      expect(parsed.keys, ['spell_frost_bind']);
      expect(parsed['spell_frost_bind']!.name, 'Frost Bind');
    });
  });
}
