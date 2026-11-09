// What the simulated hero healed (v1.873, for QA's heal-rule guards):
// SimFightOutcome.healedBy, by source, as the heal rule (heal_rules.dart)
// worked it out, a lost fight's too.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/context_rules.dart';
import 'package:narrative_data_app/combat/heal_rules.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/sim_combat.dart';

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final races = _gamedata('races.json');
  final professions = _gamedata('professions.json');
  final gameConfig = _gamedata('game_config.json');
  final dice = _gamedata('dice.json');
  final skills = _gamedata('skills.json');
  final items = _gamedata('items.json');
  final enemies = _gamedata('enemies.json');
  final spells = parseSpells(_gamedata('spells.json'));

  /// A cleric low enough to cast its heal, against a sturdy foe.
  SimFightOutcome fight({ContextRule? context, int seed = 3}) {
    final cleric = SimCharacter.create(
      raceId: 'human',
      race: races['human'] as Map<String, dynamic>,
      professionId: 'cleric',
      profession: professions['cleric'] as Map<String, dynamic>,
      gameConfig: gameConfig,
      dice: dice,
      spells: spells,
    )..potions = 1;
    cleric.currentHealth = (cleric.maxHealth * 0.3).round();
    return simulateSimFight(
      character: cleric,
      enemies: [
        MapEntry('slum_thug', {
          ...enemies['slum_thug'] as Map<String, dynamic>,
          'maxHealth': 400,
          'damage': 3,
        }),
      ],
      chapter: 1,
      skills: skills,
      items: items,
      random: Random(seed),
      context: context,
    );
  }

  test('the outcome says what the hero healed, by source', () {
    final outcome = fight();
    expect(outcome.spellHealed, greaterThan(0),
        reason: 'the cleric under half health casts Mending Light');
    expect(
        outcome.healed, outcome.healedBy.values.fold<int>(0, (a, b) => a + b));
    expect(outcome.healed, greaterThanOrEqualTo(outcome.spellHealed));
    expect(outcome.healedBy.keys, everyElement(isA<HealSource>()));
  });

  test('the same fight on a ground with a heal rule reports its heals too', () {
    final plain = fight();
    final holy = fight(context: ContextRule.sanctified);
    expect(holy.spellHealed, greaterThan(0));
    expect(plain.spellHealed, greaterThan(0));
  });

  test('a fight with no heal reports none', () {
    expect(
        const SimFightOutcome(
                won: true,
                rounds: 1,
                spellsCast: {},
                manaGained: 0,
                potionsUsed: 0)
            .healed,
        0);
  });
}
