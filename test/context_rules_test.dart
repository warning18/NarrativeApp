// The context rules (v5.2 step 4, context_rules.dart): which rule a fight
// plays by its place and foe, what each does, and (CONTEXT_RUNS=40) what
// each does to every profession's fights in the simulator when every fight
// plays it, against the Tide (docs/simulation/context-rules.md).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/context_rules.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';
import 'support/sim_world.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('one rule a fight: the foe, the city, a holy place, the stage', () {
    // A boss's fight: the Tide's own boss step is its enrage.
    expect(contextRuleFor(stage: FightStage.reeds, bossFight: true),
        ContextRule.tide);
    expect(contextRuleFor(stage: FightStage.reeds, city: true),
        ContextRule.townGuards);
    expect(contextRuleFor(stage: FightStage.dunes, holy: true),
        ContextRule.sanctified);
    expect(contextRuleFor(stage: FightStage.reeds), ContextRule.marshMist);
    expect(contextRuleFor(stage: FightStage.saltFlats), ContextRule.desertHeat);
    expect(contextRuleFor(stage: FightStage.hall), ContextRule.risingWater);
    expect(contextRuleFor(stage: FightStage.fields), ContextRule.tide);
  });

  test('what each does', () {
    expect(risingLevel(5), 0);
    expect(risingLevel(6), 1);
    expect(risingLevel(9), 4);
    // The mist: 1% of max health a level, never finishing.
    expect(ContextRule.marshMist.tick(200, 5), 0);
    expect(ContextRule.marshMist.tick(200, 8), 6);
    expect(afterTick(3, 10), 1);
    // The heat cuts healing once risen.
    expect(ContextRule.desertHeat.heal(100, 5), 100);
    expect(ContextRule.desertHeat.heal(100, 6), 80);
    // The water: from the Tide's round, the party +10% a level (and its
    // heals), the enemies +5%, up to three levels.
    expect(ContextRule.risingWater.blow(100, 7, byParty: true), 100);
    expect(ContextRule.risingWater.blow(100, 8, byParty: false), 116);
    expect(waterLevel(20), waterMaxLevel);
    expect(ContextRule.risingWater.heal(100, 9), 120);
    // Sanctified: Light harder, heals fading.
    expect(ContextRule.sanctified.blow(100, 7, byParty: true, element: 'Light'),
        120);
    expect(ContextRule.sanctified.blow(100, 7, byParty: true), 100);
    expect(ContextRule.sanctified.heal(100, 8), 70);
    // The Tide rises under every rule (from round 8).
    expect(ContextRule.marshMist.blow(100, 9, byParty: true), 140);
    expect(ContextRule.tide.blow(100, 9, byParty: false), 120);
    expect(
        partyAheadOnHealth(
            partyHealth: 60, partyMax: 100, enemyHealth: 50, enemyMax: 100),
        isTrue);
    // The watch.
    expect(ContextRule.townGuards.guardsCome(5), isFalse);
    expect(ContextRule.townGuards.guardsCome(6), isTrue);
  });

  test('in the simulator, each rule in every fight', () {
    final runs = int.tryParse(Platform.environment['CONTEXT_RUNS'] ?? '');
    if (runs == null) return;
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final tables = simTables();
    final rules = (Platform.environment['CONTEXT_ONLY'] ?? '')
        .split(',')
        .where((r) => r.isNotEmpty)
        .map((r) => ContextRule.values.byName(r))
        .toList();
    final lines = <String>[];
    for (final profession in [
      'cleric',
      'mage',
      'ranger',
      'rogue',
      'warrior',
    ]) {
      final cells = <String>[];
      for (final rule in rules.isEmpty
          ? [
              ContextRule.tide,
              ContextRule.marshMist,
              ContextRule.desertHeat,
              ContextRule.risingWater,
              ContextRule.sanctified,
            ]
          : rules) {
        final summaries = simulatePlaythroughs(story,
            tables: tables,
            gameConfig: _table('game_config'),
            plan: [
              for (var i = 0; i < runs; i++)
                (
                  strategy: SimStrategy.random,
                  raceId: null,
                  professionId: profession,
                ),
            ],
            seed: 11,
            context: rule);
        var won = 0, fights = 0, rounds = 0;
        for (final r in summaries) {
          won += r.fightsWon;
          fights += r.fightsWon + r.fightsLost;
          rounds += r.roundsFought;
        }
        cells.add('${rule.name} ${(100 * won / fights).toStringAsFixed(1)}% / '
            '${(rounds / fights).toStringAsFixed(1)}');
      }
      lines.add('| $profession | ${cells.join(' | ')} |');
    }
    // ignore: avoid_print
    print(lines.join('\n'));
  });

  test('a deck rises like the sea; the streets keep the watch by the city', () {
    expect(contextRuleFor(stage: FightStage.deck), ContextRule.risingWater);
    expect(contextRuleFor(stage: FightStage.streets), ContextRule.tide);
    expect(contextRuleFor(stage: FightStage.streets, city: true),
        ContextRule.townGuards);
  });
}
