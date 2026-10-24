// The clash rules (v1.212-v1.215: goals, squads, answers, parries and
// reactions) make the simulator's fights kinder than the plain rules': goals
// (rout, subdue, hold), pack break, morale and parry end multi-foe fights
// before every foe is down. The user chose (wave 17 item 3, option c) to keep
// that as the game's design, so this test guards the gap against drifting
// further, not toward zero. Both runs share their seeds, so the numbers are
// stable until the data changes.
//
// It runs on the real walk (the same tables as boss_balance_test,
// politics_events and training_paths included) and pools seeds 7, 11 and 23
// at 100 runs each: which chapter peaks is seed noise, while a rule that
// makes every fight kinder shows in the mean gap. Measured on v1.535: worst
// chapter 0.230 (chapter 2), mean over chapters 2-8 0.151, chapter 1 0.032.
// Limits are those plus 0.03 of seed room. See
// docs/simulation/clash-balance-real-walk.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

const _seeds = [7, 11, 23];
const _runsPerSeed = 100;

void main() {
  test('the clash rules\' gap over the plain rules does not drift', () {
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
        name: _gamedata('$name.json'),
    };
    final gameConfig = _gamedata('game_config.json');
    Map<String, double> rates({required bool clash}) {
      final attempts = <String, int>{};
      final won = <String, int>{};
      for (final seed in _seeds) {
        final result = simulateFightsByChapter(
          story,
          tables: tables,
          gameConfig: gameConfig,
          runs: _runsPerSeed,
          seed: seed,
          clash: clash,
        );
        for (final e in result.chapters.entries) {
          attempts[e.key] = (attempts[e.key] ?? 0) + e.value.attempts;
          won[e.key] = (won[e.key] ?? 0) + e.value.won;
        }
      }
      return {
        for (final e in attempts.entries)
          if (e.value >= 200) e.key: won[e.key]! / e.value,
      };
    }

    final plain = rates(clash: false);
    final clash = rates(clash: true);
    expect(plain, isNotEmpty);
    final midGaps = <double>[];
    final report = StringBuffer();
    for (final chapter in plain.keys) {
      final other = clash[chapter];
      expect(other, isNotNull, reason: '$chapter has no clash fights');
      final gap = other! - plain[chapter]!;
      report.write('$chapter ${gap.toStringAsFixed(3)}; ');
      final number = int.tryParse(chapter.split(' ').last);
      if (number != null && number >= 2 && number <= 8) midGaps.add(gap);
      // Chapter 1 keeps its own 0.25 (since v1.429); chapters 2-8 get 0.26,
      // the worst pooled chapter on v1.535 (0.230) plus seed room.
      expect(gap.abs(), lessThan(chapter == 'Chapter 1' ? 0.25 : 0.26),
          reason: '$chapter: plain ${plain[chapter]!.toStringAsFixed(3)}, '
              'clash ${other.toStringAsFixed(3)}');
    }
    // A rule that makes every fight a little kinder crosses no single
    // chapter's limit, so the mean gap over chapters 2-8 has its own.
    expect(midGaps, hasLength(7), reason: '$report');
    final mean = midGaps.reduce((a, b) => a + b) / midGaps.length;
    // 0.19: the v1.535 mean (0.151) plus seed room.
    expect(mean.abs(), lessThan(0.19),
        reason: 'mean gap, chapters 2-8: ${mean.toStringAsFixed(3)} ($report)');
    // The clash rules stay a net plus for the player.
    expect(mean, greaterThan(0),
        reason: 'mean gap, chapters 2-8: ${mean.toStringAsFixed(3)} ($report)');
    printOnFailure('$report mean 2-8 ${mean.toStringAsFixed(3)}');
  });
}
