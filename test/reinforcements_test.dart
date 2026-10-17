// Reinforcements (v5.2 step 6, PR 3, context_rules.dart): in a place a
// clan holds, from round 8 its people join the fight, on your side when
// you stand Friend or better with it, against you when it hunts you or is
// your nemesis; never in a boss's fight. REINFORCE_RUNS=n prints each
// profession's fights won and rounds with none, allies and foes in every
// fight (the PR's table).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/context_rules.dart';
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  final geography =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  PoliticsState at(Map<String, num> standings) {
    var state = PoliticsState.empty;
    for (final e in standings.entries) {
      state = setStandingValue(state, e.key, e.value, 'edit', data: data).state;
    }
    return state;
  }

  test('they come from round 8, never in a boss\'s fight', () {
    expect(allyStrike(200, reinforceStartRound - 1), 0);
    expect(allyStrike(200, reinforceStartRound), 10);
    expect(allyStrike(200, 12, bossFight: true), 0);
    expect(foeStrike(120, reinforceStartRound), 6);
    expect(foeStrike(120, 7), 0);
    expect(foeStrike(120, 9, bossFight: true), 0);
  });

  test('who comes: the holder\'s people, by your standing with it', () {
    // Candlehold is the Dominion's.
    expect(reinforcementAt('candlehold', geography, PoliticsState.empty, data),
        Reinforcement.none);
    expect(reinforcementAt('candlehold', geography, at({'dominion': 40}), data),
        Reinforcement.allies);
    expect(
        reinforcementAt('candlehold', geography, at({'dominion': -80}), data),
        Reinforcement.foes);
    expect(
        reinforcementAt('candlehold', geography,
            PoliticsState.empty.copyWith(nemesis: 'dominion'), data),
        Reinforcement.foes);
    // Nobody holds the Drowned Cloister's nave.
    expect(
        reinforcementAt(
            'drowned_cloister_nave', geography, at({'dominion': 40}), data),
        Reinforcement.none);
  });

  test('in the simulator, each profession with none, allies and foes', () {
    final runs = int.tryParse(Platform.environment['REINFORCE_RUNS'] ?? '');
    if (runs == null) return;
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
        'expedition_steps', 'training_paths', 'specialisations',
        'spec_variants',
      ])
        name: _table(name),
    };
    final lines = <String>[
      '| Profession | None | Allies | Foes |',
      '|---|---|---|---|',
    ];
    for (final profession in ['cleric', 'mage', 'ranger', 'rogue', 'warrior']) {
      final cells = <String>[];
      for (final r in Reinforcement.values) {
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
            reinforcement: r);
        var won = 0, fights = 0, rounds = 0;
        for (final s in summaries) {
          won += s.fightsWon;
          fights += s.fightsWon + s.fightsLost;
          rounds += s.roundsFought;
        }
        cells.add('${(100 * won / fights).toStringAsFixed(1)}% / '
            '${(rounds / fights).toStringAsFixed(1)}');
      }
      lines.add('| $profession | ${cells.join(' | ')} |');
    }
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}
