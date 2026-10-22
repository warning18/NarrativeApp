// Exploring every branch (v1.229): a batch of runs that always takes the way
// on taken least so far, whatever the goal, covers far more of the story than
// the same number of random runs, and every one still ends in a real ending.
// SIM_RUNS (default 60), SIM_SEED and SIM_OUT (a JSON file for the report in
// docs/simulation/) tune it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_graph_integrity.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('exploring runs cover more of the story than random ones', () {
    final runs = int.parse(Platform.environment['SIM_RUNS'] ?? '60');
    final seed = int.parse(Platform.environment['SIM_SEED'] ?? '7');
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
        name: _table(name),
    };
    final professions = tables['professions']!.keys.toList()..sort();
    List<({SimStrategy strategy, String? raceId, String? professionId})> plan(
            SimStrategy strategy) =>
        [
          for (var i = 0; i < runs; i++)
            (
              strategy: strategy,
              raceId: null,
              professionId: professions[i % professions.length],
            ),
        ];

    ({List<SimRunSummary> results, SimCoverage coverage}) play(
        SimStrategy strategy,
        {bool alternate = false}) {
      final coverage = SimCoverage(alternateChecks: alternate);
      final results = simulatePlaythroughs(story,
          tables: tables,
          gameConfig: _table('game_config'),
          plan: plan(strategy),
          seed: seed,
          coverage: coverage);
      return (results: results, coverage: coverage);
    }

    final explore = play(SimStrategy.explore);
    final both = play(SimStrategy.explore, alternate: true);
    final random = play(SimStrategy.random);
    int nodes(List<SimRunSummary> rs) =>
        {for (final r in rs) ...r.visitedNodes}.length;
    int choices(List<SimRunSummary> rs) =>
        {for (final r in rs) ...r.choicesTaken}.length;

    for (final r in [...explore.results, ...both.results]) {
      expect(r.endedHow, 'ending', reason: '${r.raceId} ${r.professionId}');
    }
    expect(choices(explore.results), greaterThan(choices(random.results)));
    expect(nodes(explore.results), greaterThanOrEqualTo(nodes(random.results)));
    // Walking both sides of every check reaches the failure scenes too.
    expect(nodes(both.results), greaterThan(nodes(random.results)));

    final out = Platform.environment['SIM_OUT'];
    if (out == null) return;
    final report = checkStoryGraphIntegrity(story.nodes,
        startNodeId: StoryRepository.startNodeId);
    Map<String, dynamic> curve(List<SimRunSummary> rs) {
      final seenNodes = <String>{}, seenChoices = <String>{};
      final seenQuests = <String>{}, seenShops = <String>{};
      final seenEnemies = <String>{};
      final points = <Map<String, int>>[];
      final fresh = <Map<String, int>>[];
      for (var i = 0; i < rs.length; i++) {
        fresh.add({
          'newNodes': rs[i].visitedNodes.difference(seenNodes).length,
          'newChoices':
              rs[i].choicesTaken.toSet().difference(seenChoices).length,
          'newQuests': rs[i].questIds.difference(seenQuests).length,
        });
        seenNodes.addAll(rs[i].visitedNodes);
        seenChoices.addAll(rs[i].choicesTaken);
        seenQuests.addAll(rs[i].questIds);
        seenShops.addAll(rs[i].shopIds);
        seenEnemies.addAll(rs[i].enemiesFought.keys);
        if ((i + 1) % 10 == 0 || i == rs.length - 1) {
          points.add({
            'runs': i + 1,
            'nodes': seenNodes.length,
            'choices': seenChoices.length,
            'quests': seenQuests.length,
            'shops': seenShops.length,
            'enemies': seenEnemies.length,
          });
        }
      }
      return {
        'curve': points,
        'nodes': seenNodes.toList()..sort(),
        'choices': seenChoices.toList()..sort(),
        'quests': seenQuests.toList()..sort(),
        'shops': seenShops.toList()..sort(),
        'enemies': seenEnemies.toList()..sort(),
        'flags': {for (final r in rs) ...r.flagIds}.toList()..sort(),
        'endings': {for (final r in rs) r.ending}.toList()..sort(),
        'perRun': [
          for (var i = 0; i < rs.length; i++)
            {
              ...fresh[i],
              'profession': rs[i].professionId,
              'race': rs[i].raceId,
              'level': rs[i].finalLevel,
              'gold': rs[i].finalGold,
              'alignment': rs[i].finalAlignment,
              'nodes': rs[i].visitedNodes.length,
              'choicesTaken': rs[i].choicesTaken.length,
              'won': rs[i].fightsWon,
              'lost': rs[i].fightsLost,
              'quests': rs[i].questIds.length,
              'endedHow': rs[i].endedHow,
              'checks': rs[i].checksRolled,
              'checksFailed': rs[i].checksFailed,
            },
        ],
      };
    }

    File(out).writeAsStringSync(jsonEncode({
      'runs': runs,
      'seed': seed,
      'explore': curve(explore.results),
      'exploreBothSides': curve(both.results),
      'random': curve(random.results),
      'universe': {
        'nodes': story.nodes.keys.toList()..sort(),
        'unreachable': report.unreachableNodeIds,
        'choices': [
          for (final n in story.nodes.values)
            for (final c in n.choices) simChoiceKey(n.id, c),
        ]..sort(),
        'quests': tables['quests']!.keys.toList()..sort(),
        'shops': tables['shops']!.keys.toList()..sort(),
        'enemies': tables['enemies']!.keys.toList()..sort(),
      },
    }));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
