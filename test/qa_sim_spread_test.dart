// QA: the five professions win about as often as each other in the simulator.
// The L3 on v1.489 found the warrior winning 73% of its encounters and the
// mage and rogue 60% and 62% (v1.429 aimed at about 70% each); Core's v1.497
// brought them within a few points. This keeps them there: the same 400 runs
// as boss_balance_test (seed 7, four goals, the professions in turn), the
// encounters each profession wins within three tries, and
//   - no profession more than 8 points from the others (max - min): Core's
//     v1.497 and v1.499 put all five within about 5 at seed 7, and 8 stays
//     quiet at the 0.1 to 1 point noise Core measured;
//   - none under 60% (a profession that falls out of the game).
// (The band was 10 at v1.497, with the cleric lowest; v1.499 lifted it.)
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

/// Points between the best and the worst profession that the guard allows.
const double maxSpread = 8;

/// The lowest encounter win a profession may have.
const double floorWin = 60;

void main() {
  test('the professions win within 8 points of each other', () {
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
        'expedition_steps', 'training_paths',
      ])
        name: table(name),
    };
    final professions = tables['professions']!.keys.toList()..sort();
    const goals = [
      SimStrategy.random,
      SimStrategy.favorGood,
      SimStrategy.favorEvil,
      SimStrategy.maximizeGold,
    ];
    final runs = simulatePlaythroughs(story,
        tables: tables,
        gameConfig: table('game_config'),
        plan: [
          for (var i = 0; i < 400; i++)
            (
              strategy: goals[i % goals.length],
              raceId: null,
              professionId:
                  professions[(i ~/ goals.length) % professions.length],
            ),
        ],
        seed: 7);

    final fought = <String, int>{};
    final lost = <String, int>{};
    for (final run in runs) {
      for (final chapter in run.enemiesByChapter.values) {
        for (final enemy in chapter.values) {
          fought[run.professionId] =
              (fought[run.professionId] ?? 0) + enemy.fought;
          lost[run.professionId] = (lost[run.professionId] ?? 0) + enemy.lost;
        }
      }
    }
    final win = {
      for (final p in professions)
        p: 100 * (1 - (lost[p] ?? 0) / (fought[p] ?? 1)),
    };
    final summary = [
      for (final e in win.entries) '${e.key} ${e.value.toStringAsFixed(1)}%',
    ].join(', ');
    debugPrint('encounter win by profession: $summary');
    final spread = win.values.reduce((a, b) => a > b ? a : b) -
        win.values.reduce((a, b) => a < b ? a : b);
    expect(spread, lessThanOrEqualTo(maxSpread),
        reason: 'the professions are $spread points apart ($summary); '
            'Core tunes this (the profession paths in training_paths.json, '
            'bonusMaxHealth in professions.json)');
    for (final e in win.entries) {
      expect(e.value, greaterThanOrEqualTo(floorWin),
          reason: '${e.key} wins ${e.value.toStringAsFixed(1)}% ($summary)');
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
