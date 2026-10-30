// QA: the one place the simulator tests get their world from. The tables are
// the ones the playthrough simulator reads (playthrough_simulator_screen.dart,
// `_simContextOf`), companions included: since v1.601 every hero has Vica,
// and a test that leaves a table out measures a game nobody plays. A file
// that leaves one out on purpose says so in qa_sim_tables_test.dart's terms
// (`// sim-tables-ok: <table>: <why>` on the line of its call).
//
// When the simulator starts reading a new table, add it to [simTableNames]
// and every simulator test has it; the numbers move once, here.
import 'dart:convert';
import 'dart:io';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

/// Every table the simulator reads from its `tables` map.
const simTableNames = [
  'biomes',
  'companions',
  'detour_scenes',
  'dice',
  'enemies',
  'expedition_steps',
  'factions',
  'geography',
  'houses',
  'item_sets',
  'items',
  'land_events',
  'land_routes',
  'npcs',
  'politics_events',
  'ports',
  'professions',
  'quests',
  'races',
  'relations',
  'shops',
  'signs',
  'skill_merges',
  'skill_trees',
  'skills',
  'spec_variants',
  'specialisations',
  'spells',
  'subclans',
  'titles',
  'training_paths',
  'zones',
];

Map<String, dynamic> simTable(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, Map<String, dynamic>>? _tables;

/// The simulator's tables, read once per test file. Every simulator test plays
/// in this whole world (the bosses were re-sized for it in v1.613 and v1.614,
/// docs/proposals/bosses-full-world.md); a test that must leave a table out
/// builds its own map and says why (`// sim-tables-ok: <table>: <why>`).
Map<String, Map<String, dynamic>> simTables() =>
    _tables ??= {for (final name in simTableNames) name: simTable(name)};

/// game_config.json, the simulator's other input.
Map<String, dynamic> simGameConfig() => simTable('game_config');

/// The story graph as the simulator walks it.
StoryData simStory() {
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  return StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
}
