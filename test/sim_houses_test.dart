// The simulator builds the camp's works (playthrough_simulator_screen.dart's
// buildHouses, v1.291): as soon as the building screen calls a house
// buildable, cheapest first, from a purse of its own so the walk's shopping
// and fights are left as they were. Seeded, small, and the measure the
// materials economy is tuned against (docs/simulation/).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

void main() {
  test('the walk builds the harbour at the camp\'s founding, and more after',
      () {
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
    final runs = simulatePlaythroughs(story,
        tables: tables,
        gameConfig: table('game_config'),
        plan: [
          for (var i = 0; i < 24; i++)
            (
              strategy: SimStrategy.values[i % 4],
              raceId: null,
              professionId: professions[i % professions.length],
            ),
        ],
        seed: 7);
    final reachedCamp = runs.where((r) => (r.furthestChapter ?? 0) >= 3);
    expect(reachedCamp, isNotEmpty);
    // The founding hands over the harbour's materials: it goes up at once.
    final harbourInThree =
        reachedCamp.where((r) => r.housesBuilt['harbor'] == 3).length;
    expect(harbourInThree / reachedCamp.length, greaterThan(0.9));
    // Never a house before its tier's chapter, never a companion's.
    for (final r in runs) {
      expect(r.housesBuilt.containsKey('keldas_hall'), isFalse);
      final loft = r.housesBuilt['banner_loft'];
      if (loft != null) expect(loft, greaterThanOrEqualTo(5));
    }
    // What the materials economy is measured by (printed for the report).
    final ids = {for (final r in runs) ...r.housesBuilt.keys}.toList()..sort();
    for (final id in ids) {
      final chapters = [
        for (final r in runs)
          if (r.housesBuilt[id] != null) r.housesBuilt[id]!,
      ]..sort();
      // ignore: avoid_print
      print('$id: ${chapters.length}/${runs.length} runs, '
          'median chapter ${chapters[chapters.length ~/ 2]}');
    }
  });
}
