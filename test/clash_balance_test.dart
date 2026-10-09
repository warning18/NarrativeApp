// The clash rules (v1.212-v1.215: goals, squads, answers, parries and
// reactions) must not move the simulator's fight win rates far from the
// plain rules': they add choices, not a different difficulty. Both runs
// share a seed, so the numbers are stable until the data changes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('the clash rules keep every chapter\'s win rate near the plain rules\'',
      () {
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final tables = {
      for (final name in [
        'enemies',
        'dice',
        'skills',
        'items',
        'shops',
        'races',
        'professions',
        'spells',
        'item_sets',
        'zones',
        'skill_trees',
        'factions',
        'signs',
        'subclans',
        'relations',
        'titles',
        'geography',
        'biomes',
      ])
        name: _gamedata('$name.json'),
    };
    Map<String, double> rates({required bool clash}) {
      final result = simulateFightsByChapter(
        story,
        tables: tables,
        gameConfig: _gamedata('game_config.json'),
        runs: 150,
        seed: 11,
        clash: clash,
      );
      return {
        for (final e in result.chapters.entries)
          if (e.value.attempts >= 200) e.key: e.value.won / e.value.attempts,
      };
    }

    final plain = rates(clash: false);
    final clash = rates(clash: true);
    expect(plain, isNotEmpty);
    for (final chapter in plain.keys) {
      final other = clash[chapter];
      expect(other, isNotNull, reason: '$chapter has no clash fights');
      expect((other! - plain[chapter]!).abs(), lessThan(0.10),
          reason: '$chapter: plain ${plain[chapter]!.toStringAsFixed(2)}, '
              'clash ${other.toStringAsFixed(2)}');
    }
  });
}
