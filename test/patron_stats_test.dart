// The patron's passive stats (v5.2 step 5, patron_stats.dart): who the
// patron is, what a level gives at each standing, and (PATRON_RUNS=200) the
// simulator's win rate by the patron a run ended with, with the passives
// on and off.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/patron_stats.dart';
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
  PoliticsState at(Map<String, num> standings) {
    var state = PoliticsState.empty;
    for (final e in standings.entries) {
      state = setStandingValue(state, e.key, e.value, 'edit', data: data).state;
    }
    return state;
  }

  test('every main clan has two stats', () {
    for (final clan in data.clans) {
      expect(patronStatsOf[clan.id], hasLength(2), reason: clan.id);
    }
  });

  test('the patron: the sworn clan, else the best at Friendly', () {
    expect(statPatron(at({'mire': 10}), data), '');
    expect(statPatron(at({'mire': 15, 'crows': 20}), data), 'crows');
    expect(statPatron(at({'dominion': 70}), data), 'dominion');
  });

  test('what a level gives', () {
    expect(patronLevelGains(at({'mire': 15}), data).stats, {'dexterity': 1});
    expect(patronLevelGains(at({'mire': 30}), data).stats,
        {'dexterity': 1, 'luck': 1});
    final sworn = patronLevelGains(at({'vigil': 70}), data);
    expect(sworn.stats, {'constitution': 1, 'perception': 1});
    expect(sworn.maxHealth, swornPatronHealth);
    expect(patronLevelGains(PoliticsState.empty, data).stats, isEmpty);
    // The Open Hand: +1 to the strongest.
    expect(
        patronLevelGains(PoliticsState.empty, data,
                stats: {'strength': 4, 'wisdom': 9}, openHand: true)
            .stats,
        {'wisdom': 1});
  });

  test('in the simulator, by patron', () {
    final runs = int.tryParse(Platform.environment['PATRON_RUNS'] ?? '');
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
        'expedition_steps', 'specialisations', 'spec_variants',
      ])
        name: _table(name),
    };
    Map<String, ({int runs, int won, int fights, int level})> byPatron(
        bool on) {
      final summaries = simulatePlaythroughs(story,
          tables: tables,
          gameConfig: _table('game_config'),
          plan: [
            for (var i = 0; i < runs; i++)
              (
                strategy: SimStrategy.values[i % 4],
                raceId: null,
                professionId: null,
              ),
          ],
          seed: 13,
          clashOff: on ? const {} : const {'passives'});
      final out = <String, ({int runs, int won, int fights, int level})>{};
      for (final r in summaries) {
        for (final key in [r.patron.isEmpty ? '(none)' : r.patron, 'all']) {
          final o = out[key] ?? (runs: 0, won: 0, fights: 0, level: 0);
          out[key] = (
            runs: o.runs + 1,
            won: o.won + r.fightsWon,
            fights: o.fights + r.fightsWon + r.fightsLost,
            level: o.level + r.finalLevel,
          );
        }
      }
      return out;
    }

    final off = byPatron(false);
    final on = byPatron(true);
    String pct(({int runs, int won, int fights, int level})? x) => x == null
        ? '-'
        : '${(100 * x.won / x.fights).toStringAsFixed(1)}% (${x.runs})';
    final lines = [
      for (final key in {...off.keys, ...on.keys}.toList()..sort())
        '| $key | ${pct(off[key])} | ${pct(on[key])} |',
    ];
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}
