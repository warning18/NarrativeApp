// QA guard for the one healing rule (v1.866, lib/combat/heal_rules.dart) in
// the playthrough simulator's fight: a cleric's Mending Light goes through
// the ground's rule as it does on the fight screen (before v1.866 the
// simulator's cleric spell skipped it, so a sanctified ground never weakened
// it). Read from SimFightOutcome.healedBy (v1.874): what the hero's spells
// healed, per cast (the two fights' rolls differ once heals do).
//
// Sanctified ground (context_rules.dart) fades heals from round 6. A fight
// stopped at round 5 is the same on both grounds; played on, a cast heals
// less on the sanctified one.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/context_rules.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';

void main() {
  final data = towerDataFromAssets();
  const spell = 'spell_mending_light';

  /// A level 1 cleric (Mending Light from the start), hurt, with no Heal
  /// face on its die (the spell is its only heal), against a foe too sturdy
  /// to fall. Returns what its spells healed and how many casts it made.
  ({int healed, int casts}) fight(int seed, ContextRule? rule,
      {required int maxRounds}) {
    final hero = towerFreshHero('human', 'cleric', const [], data)..potions = 0;
    hero.maxHealth = 3000;
    hero.currentHealth = 1200;
    hero.mana = 60;
    hero.diceFaces = [
      for (final face in hero.diceFaces)
        if (face['type'] != 'Heal') face,
    ];
    final thug = {
      ...(data.enemies['slum_thug'] as Map<String, dynamic>),
      'maxHealth': 90000,
      'damage': 20,
      'skillMoves': <dynamic>[],
    };
    final outcome = simulateSimFight(
      character: hero,
      enemies: [MapEntry('slum_thug', thug)],
      chapter: 1,
      skills: data.skills,
      items: data.items,
      random: Random(seed),
      context: rule,
      maxRounds: maxRounds,
    );
    return (healed: outcome.spellHealed, casts: outcome.spellsCast[spell] ?? 0);
  }

  /// What a cast heals on average over [seeds] fights.
  double perCast(ContextRule? rule, {required int maxRounds, int seeds = 20}) {
    var healed = 0;
    var casts = 0;
    for (var seed = 1; seed <= seeds; seed++) {
      final run = fight(seed, rule, maxRounds: maxRounds);
      healed += run.healed;
      casts += run.casts;
    }
    expect(casts, greaterThan(0), reason: 'the cleric cast no Mending Light');
    return healed / casts;
  }

  test('the cleric heals with Mending Light in the simulator (guard is live)',
      () {
    final run = fight(1, null, maxRounds: 40);
    expect(run.casts, greaterThan(0));
    expect(run.healed, greaterThan(0));
  });

  test('before round 6 a sanctified ground changes nothing', () {
    for (var seed = 1; seed <= 10; seed++) {
      final plain = fight(seed, null, maxRounds: 5);
      final holy = fight(seed, ContextRule.sanctified, maxRounds: 5);
      expect(holy, plain, reason: 'seed $seed: the rule has not risen yet');
    }
  });

  test('after round 6 a cast of Mending Light heals less on sanctified ground',
      () {
    final plain = perCast(null, maxRounds: 40);
    final holy = perCast(ContextRule.sanctified, maxRounds: 40);
    expect(holy, lessThan(plain * 0.95),
        reason: 'a cast heals $holy on sanctified ground and $plain on the '
            'plain Tide: the ground\'s rule must weaken the cleric\'s spell');
  });
}
