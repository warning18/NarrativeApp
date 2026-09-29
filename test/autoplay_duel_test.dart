// Autoplay's fights (v1.166) play the enemy's intents the way the fight
// screen does: a wind-up swings nothing and lands next turn unless broken,
// a heal mends.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/autoplay_engine.dart';

const _skills = <String, dynamic>{
  'windup': {'id': 'windup', 'intent': 'charge', 'damageMod': 10},
  'mend': {'id': 'mend', 'damageMod': 0, 'healAmount': 30},
};

Map<String, dynamic> _enemy(String skill) => {
      'maxHealth': 100,
      'damage': 20,
      'skillMoves': [
        {'skillID': skill, 'condition': 'Always', 'priority': 1},
      ],
    };

({int playerHealth, int enemyHealth}) _duel(String skill,
        {required int hit, required int turns}) =>
    autoplayDuel(
      diceFaces: [
        {'faceName': 'Jab', 'type': 'Attack', 'value': hit, 'weight': 1.0},
      ],
      assignments: const {},
      skills: _skills,
      playerDamage: 0,
      playerArmor: 0,
      playerHealth: 200,
      playerMaxHealth: 200,
      enemy: _enemy(skill),
      enemyMaxHealth: 100,
      random: Random(1),
      maxTurns: turns,
    );

void main() {
  test('a wind-up swings nothing, then lands the next turn', () {
    expect(_duel('windup', hit: 1, turns: 1).playerHealth, 200);
    expect(_duel('windup', hit: 1, turns: 2).playerHealth, lessThan(200));
  });

  test('a hit hard enough breaks the wind-up and the blow never lands', () {
    // 30 of 100 health in one round: past a quarter.
    expect(_duel('windup', hit: 30, turns: 2).playerHealth, 200);
  });

  test('a heal mends the enemy instead of hitting', () {
    final duel = _duel('mend', hit: 10, turns: 1);
    expect(duel.enemyHealth, 100, reason: '100 - 10 + 30, capped');
    expect(duel.playerHealth, 200);
  });
}
