// Full simulated playthroughs (v1.228): every goal, every profession, from
// the first scene to the end with the real fight model. The story must lead
// each of them to a real ending (no dead end, no broken link, no step cap),
// through chapter 8. For the balance review set SIM_RUNS (default 40), SIM_STRATEGY,
// SIM_GOALS, SIM_SEED and SIM_OUT: the runs are then also written to that file as JSON
// (see docs/simulation/).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('every goal and every profession plays through to a real ending', () {
    final runs = int.parse(Platform.environment['SIM_RUNS'] ?? '40');
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
        'expedition_steps',
      ])
        name: _table(name),
    };
    final professions = tables['professions']!.keys.toList()..sort();
    // SIM_STRATEGY names the one goal to play (default: all in turn).
    final only = Platform.environment['SIM_STRATEGY'] == null
        ? null
        : SimStrategy.values.byName(Platform.environment['SIM_STRATEGY']!);
    // SIM_GOALS (comma-separated goal names) plays those goals in turn, the
    // professions rotating after each round of them: the balance reports of
    // docs/simulation/ play random, favorGood, favorEvil and maximizeGold.
    final goals = Platform.environment['SIM_GOALS'] == null
        ? SimStrategy.values
        : [
            for (final name in Platform.environment['SIM_GOALS']!.split(','))
              SimStrategy.values.byName(name),
          ];
    final plan = [
      for (var i = 0; i < runs; i++)
        (
          strategy: only ?? goals[i % goals.length],
          raceId: null as String?,
          professionId:
              professions[(i ~/ goals.length) % professions.length] as String?,
        ),
    ];
    final results = simulatePlaythroughs(story,
        tables: tables,
        gameConfig: _table('game_config'),
        plan: plan,
        seed: seed);

    for (final r in results) {
      final who = '${r.strategy.name} ${r.raceId} ${r.professionId}';
      expect(r.endedHow, 'ending', reason: who);
      expect(r.furthestChapter, 8, reason: who);
    }
    // Every goal and every profession was played.
    expect({for (final r in results) r.strategy}.length,
        only != null ? 1 : (runs >= goals.length ? goals.length : runs));

    final out = Platform.environment['SIM_OUT'];
    if (out != null) {
      File(out).writeAsStringSync(jsonEncode([
        for (final r in results)
          {
            'strategy': r.strategy.name,
            'race': r.raceId,
            'profession': r.professionId,
            'level': r.finalLevel,
            'gold': r.finalGold,
            'alignment': r.finalAlignment,
            'endedHow': r.endedHow,
            'endingText': r.ending,
            'chapter': r.furthestChapter,
            'steps': r.steps,
            'unique': r.uniqueNodes,
            'won': r.fightsWon,
            'lost': r.fightsLost,
            'encounters': r.combatEncounters,
            'casts': r.totalCasts,
            'potions': r.potionsUsed,
            'shops': r.shops,
            'quests': r.quests,
            'flags': r.flags,
            'signs': r.signs,
            'offers': r.offers,
            'skills': r.skillsLearned,
            'byChapter': {
              for (final e in r.byChapter.entries)
                e.key: {
                  'attempts': e.value.attempts,
                  'won': e.value.won,
                  'fights': e.value.fights,
                },
            },
            'enemies': r.enemiesFought,
            'enemiesLost': r.enemiesLost,
            'enemiesByChapter': {
              for (final c in r.enemiesByChapter.entries)
                c.key: {
                  for (final e in c.value.entries)
                    e.key: {'fought': e.value.fought, 'lost': e.value.lost},
                },
            },
            'arrivals': {
              for (final a in r.arrivals.entries)
                '${a.key}': {'level': a.value.level, 'gold': a.value.gold},
            },
            'housesBuilt': r.housesBuilt,
            'questRecords': [
              for (final q in r.questRecords)
                {
                  'id': q.questId,
                  'from': q.acceptedAtStep,
                  'to': q.completedAtStep,
                  'gold': q.gold,
                  'xp': q.xp,
                  'item': q.itemId,
                  'turnIn': q.turnIn,
                },
            ],
            'questsStuck': r.questsStuck,
          },
      ]));
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
