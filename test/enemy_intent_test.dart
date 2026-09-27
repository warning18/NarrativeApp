// Enemy intents, weaknesses and the momentum drain (v1.162): the pure
// rules, resolveEnemyMove's reading of them, and the data that uses them.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _load(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find $name');
}

EnemyMoveResult _useOnly(String skillId, Map<String, dynamic> skills,
    {int damage = 10, AppLanguage language = AppLanguage.en}) {
  return resolveEnemyMove(
    enemy: {
      'enemyName': 'Test Foe',
      'damage': damage,
      'skillMoves': [
        {'skillID': skillId, 'condition': 'Always', 'priority': 1},
      ],
    },
    skills: skills,
    enemyCurrentHealth: 50,
    enemyMaxHealth: 100,
    random: Random(1),
    language: language,
  );
}

void main() {
  final skills = _load('skills.json');
  final enemies = _load('enemies.json');

  group('enemyIntentOf', () {
    test('reads the intent field', () {
      expect(enemyIntentOf({'intent': 'guard'}), EnemyIntent.guard);
      expect(enemyIntentOf({'intent': 'charge'}), EnemyIntent.charge);
      expect(enemyIntentOf({'intent': 'rally'}), EnemyIntent.rally);
      expect(enemyIntentOf({'intent': 'heal'}), EnemyIntent.heal);
    });

    test('a skill that only heals is a heal; a strike is an attack', () {
      expect(
          enemyIntentOf({'damageMod': 0, 'healAmount': 20}), EnemyIntent.heal);
      expect(enemyIntentOf({'damageMod': 5, 'healAmount': 10}),
          EnemyIntent.attack);
      expect(enemyIntentOf({'damageMod': 5}), EnemyIntent.attack);
    });
  });

  group('resolveEnemyMove with intents', () {
    test('Second Wind mends the enemy instead of hitting (the heal bug)', () {
      final move = _useOnly('second_wind', skills);
      expect(move.intent, EnemyIntent.heal);
      expect(move.damage, 0);
      expect(move.healAmount, 20);
      expect(categoryFor(move), MoveCategory.healSelf);
      // Enemy-voiced, not "You catch your breath."
      expect(move.message, isNot(startsWith('You')));
    });

    test('Shadow Step still strikes, and carries its self-heal', () {
      final move = _useOnly('shadow_step', skills);
      expect(move.intent, EnemyIntent.attack);
      expect(move.damage, greaterThan(0));
      expect(move.healAmount, 10);
    });

    test('a guard raises block worth the enemy damage and does not hit', () {
      final move = _useOnly('brace', skills, damage: 14);
      expect(move.intent, EnemyIntent.guard);
      expect(move.damage, 0);
      expect(move.guardAmount, 14);
      expect(categoryFor(move), MoveCategory.guard);
    });

    test('a wind-up carries the doubled blow and its landing line', () {
      final move = _useOnly('heavy_windup', skills, damage: 10);
      expect(move.intent, EnemyIntent.charge);
      expect(move.damage, (10 + 4) * 2);
      expect(move.releaseMessage, isNotEmpty);
      expect(categoryFor(move), MoveCategory.charge);
      final fr = _useOnly('heavy_windup', skills,
          damage: 10, language: AppLanguage.fr);
      expect(fr.releaseMessage, isNot(move.releaseMessage));
    });

    test('a rally carries its bonus and does not hit', () {
      final move = _useOnly('pack_howl', skills);
      expect(move.intent, EnemyIntent.rally);
      expect(move.damage, 0);
      expect(move.rallyPercent, 25);
      expect(categoryFor(move), MoveCategory.rally);
    });

    test('a borrowed player skill speaks as the enemy in both languages', () {
      for (final lang in AppLanguage.values) {
        final move = _useOnly('heavy_attack', skills, language: lang);
        expect(move.message, isNot(contains('You ')), reason: '$lang');
        expect(move.message, isNot(contains('Vous ')), reason: '$lang');
      }
    });
  });

  group('weaknesses and resistances', () {
    final ghoul = enemies['catacomb_ghoul'] as Map<String, dynamic>;

    test('a weakness lands ×1.5, a resistance ×½, anything else as is', () {
      expect(damageAfterElement(20, ghoul, 'Light'), 30);
      expect(damageAfterElement(20, ghoul, 'Ice'), 10);
      expect(damageAfterElement(20, ghoul, 'Earth'), 20);
      expect(damageAfterElement(20, ghoul, 'None'), 20);
      expect(damageAfterElement(1, ghoul, 'Ice'), 1,
          reason: 'a hit that did something still does at least 1');
      expect(damageAfterElement(0, ghoul, 'Light'), 0);
    });

    test('every enemy lists real elements, never both weak and resistant', () {
      for (final entry in enemies.entries) {
        final enemy = entry.value as Map<String, dynamic>;
        final weak = enemyWeaknesses(enemy);
        final resist = enemyResistances(enemy);
        for (final element in [...weak, ...resist]) {
          expect(elementOptions, contains(element), reason: entry.key);
          expect(element, isNot('None'), reason: entry.key);
        }
        expect(weak.toSet().intersection(resist.toSet()), isEmpty,
            reason: entry.key);
      }
    });

    test('elements have names in both languages', () {
      for (final element in elementOptions.where((e) => e != 'None')) {
        expect(elementLabel(element, AppLanguage.en), isNotEmpty);
        expect(elementLabel(element, AppLanguage.fr), isNotEmpty);
      }
      expect(elementLabel('Fire', AppLanguage.fr), 'Feu');
    });
  });

  group('guard, charge and momentum rules', () {
    test('a guard soaks what it can and wears down', () {
      expect(damageThroughGuard(10, 6), (damage: 4, guard: 0));
      expect(damageThroughGuard(4, 6), (damage: 0, guard: 2));
      expect(damageThroughGuard(10, 0), (damage: 10, guard: 0));
    });

    test('a wind-up breaks on a quarter of its health, a stun or a weakness',
        () {
      expect(chargeBroken(damageThisRound: 24, maxHealth: 100), isFalse);
      expect(chargeBroken(damageThisRound: 25, maxHealth: 100), isTrue);
      expect(chargeBroken(damageThisRound: 0, maxHealth: 100, stunned: true),
          isTrue);
      expect(
          chargeBroken(damageThisRound: 1, maxHealth: 100, hitWeakness: true),
          isTrue);
    });

    test('an enemy heal scales with its health, never below the written one',
        () {
      expect(scaledEnemyHeal(20, maxHealth: 300, baseMaxHealth: 150), 40);
      expect(scaledEnemyHeal(20, maxHealth: 150, baseMaxHealth: 150), 20);
      expect(scaledEnemyHeal(20, maxHealth: 100, baseMaxHealth: 150), 20);
      expect(scaledEnemyHeal(0, maxHealth: 300, baseMaxHealth: 150), 0);
    });

    test('a hit taken costs one point of momentum instead of all of it', () {
      expect(momentumAfterHit(3), 2);
      expect(momentumAfterHit(1), 0);
      expect(momentumAfterHit(0), 0);
    });
  });

  group('the data', () {
    test('every enemy move names a real skill', () {
      for (final entry in enemies.entries) {
        final moves = ((entry.value as Map)['skillMoves'] as List?) ?? [];
        for (final move in moves.cast<Map<String, dynamic>>()) {
          expect(skills, contains(move['skillID']), reason: entry.key);
        }
      }
    });

    test('guard, charge and rally skills are enemy-only', () {
      for (final entry in skills.entries) {
        final skill = entry.value as Map<String, dynamic>;
        final intent = skill['intent']?.toString() ?? '';
        if (intent == 'guard' || intent == 'charge' || intent == 'rally') {
          expect(skill['enemyOnly'], isTrue, reason: entry.key);
        }
      }
    });

    test('the three tested late bosses keep their kits unchanged', () {
      // boss_balance_test pins their win rates on these exact moves.
      Set<String> kit(String id) =>
          (((enemies[id] as Map)['skillMoves'] as List?) ?? [])
              .map((m) => (m as Map)['skillID'].toString())
              .toSet();
      expect(kit('inquisition_high_warden'), {'fireball', 'void_blast'});
      expect(kit('hollow_court_zealot'), {'void_blast'});
      expect(kit('void_manifestation'),
          {'void_blast', 'shadow_step', 'disorienting_pulse'});
    });
  });
}
