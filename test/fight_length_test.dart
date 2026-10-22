// The fight-length rules (fight_length.dart): healing fatigue, the execute
// line, morale, the pack's leader and the Tide; and, in the simulator,
// fights that end sooner with them than without (docs/simulation/
// fight-length.md has the full batch).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/fight_length.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

void main() {
  test('each heal heals 5% less than the one before, never under 30%', () {
    expect(fatiguedHeal(100, 0), 100);
    expect(fatiguedHeal(100, 1), 95);
    expect(fatiguedHeal(100, 4), 80);
    expect(fatiguedHeal(100, 30), 30);
    expect(fatiguedHeal(1, 30), 1);
    expect(fatiguedHeal(0, 3), 0);
  });

  test('a foe under a tenth of its health falls when struck', () {
    expect(executes(health: 9, maxHealth: 100), isTrue);
    expect(executes(health: 10, maxHealth: 100), isFalse);
    expect(executes(health: 0, maxHealth: 100), isFalse);
  });

  test('a foe under a quarter of its health wavers', () {
    expect(wavers(health: 24, maxHealth: 100), isTrue);
    expect(wavers(health: 25, maxHealth: 100), isFalse);
  });

  test('the pack\'s leader is its biggest that is not a boss', () {
    expect(packLeaderIndex([30, 80, 50], [true, true, true]), 1);
    expect(packLeaderIndex([30, 80, 50], [true, false, true]), 2);
    expect(packLeaderIndex([80], [true]), isNull);
    expect(packLeaderIndex([30, 80], [false, false]), isNull);
  });

  test('the Tide rises from round 8: the party by 20%, the enemies by 10%', () {
    expect(tideLevel(7), 0);
    expect(tideDamage(100, 7, byParty: true), 100);
    expect(tideLevel(8), 1);
    expect(tideDamage(100, 8, byParty: true), 120);
    expect(tideDamage(100, 8, byParty: false), 110);
    expect(tideDamage(100, 10, byParty: true), 160);
    expect(tideDamage(100, 10, byParty: false), 130);
  });

  test('in the simulator, fights end sooner with the rules than without', () {
    Map<String, dynamic> table(String name) =>
        jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
            as Map<String, dynamic>;
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final tables = {
      for (final name in [
        'enemies', 'dice', 'skills', 'items', 'shops', 'races', //
        'professions', 'spells', 'item_sets', 'zones', 'skill_trees',
        'factions', 'signs', 'subclans', 'relations', 'titles', 'geography',
        'biomes', 'quests', 'npcs', 'land_routes', 'land_events', 'houses',
        'expedition_steps', 'training_paths', 'politics_events',
      ])
        name: table(name),
    };
    final professions = tables['professions']!.keys.toList()..sort();
    final runs =
        int.tryParse(Platform.environment['FIGHT_LENGTH_RUNS'] ?? '') ??
            professions.length * 2;
    ({
      double rounds,
      double win,
      Map<String, double> byProfession,
      Map<String, double> winBy
    }) measure(Set<String> off) {
      final summaries = simulatePlaythroughs(story,
          tables: tables,
          gameConfig: table('game_config'),
          plan: [
            for (var i = 0; i < runs; i++)
              (
                strategy: SimStrategy.random,
                raceId: null,
                professionId: professions[i % professions.length],
              ),
          ],
          seed: 11,
          clashOff: off);
      var rounds = 0, won = 0, fights = 0;
      final roundsBy = <String, int>{},
          fightsBy = <String, int>{},
          wonBy = <String, int>{};
      for (final r in summaries) {
        rounds += r.roundsFought;
        won += r.fightsWon;
        fights += r.fightsWon + r.fightsLost;
        roundsBy[r.professionId] =
            (roundsBy[r.professionId] ?? 0) + r.roundsFought;
        fightsBy[r.professionId] =
            (fightsBy[r.professionId] ?? 0) + r.fightsWon + r.fightsLost;
        wonBy[r.professionId] = (wonBy[r.professionId] ?? 0) + r.fightsWon;
      }
      return (
        rounds: rounds / fights,
        win: won / fights,
        byProfession: {
          for (final p in roundsBy.keys) p: roundsBy[p]! / fightsBy[p]!,
        },
        winBy: {
          for (final p in wonBy.keys) p: 100 * wonBy[p]! / fightsBy[p]!,
        },
      );
    }

    final without =
        measure(const {'fatigue', 'execute', 'morale', 'packBreak', 'tide'});
    final withRules = measure(const {});
    // ignore: avoid_print
    print('fight length: without ${without.rounds.toStringAsFixed(1)} rounds, '
        '${(100 * without.win).toStringAsFixed(1)}% won '
        '${without.byProfession.map((k, v) => MapEntry(k, v.toStringAsFixed(1)))}'
        ' | with ${withRules.rounds.toStringAsFixed(1)} rounds, '
        '${(100 * withRules.win).toStringAsFixed(1)}% won '
        '${withRules.byProfession.map((k, v) => MapEntry(k, v.toStringAsFixed(1)))}'
        ' | win by profession: without '
        '${without.winBy.map((k, v) => MapEntry(k, v.toStringAsFixed(1)))}'
        ', with ${withRules.winBy.map((k, v) => MapEntry(k, v.toStringAsFixed(1)))}');
    expect(withRules.rounds, lessThan(without.rounds));
    // The cleric's endless fights are the ones it ends.
    expect(withRules.byProfession['cleric']!,
        lessThan(without.byProfession['cleric']!));
  });
}
