// The rivals' hunters (v5.2 step 3b, rival_hunters.dart): sworn to a clan,
// each rival you stand Hostile with (4%) or that hunts you (8%) may send a
// fighter onto the roads, up to 15%; every clan has a line fighter and a
// captain; the Vigil's, the Compact's and the Mire's are hunters only, with
// Narrative's battle cries. RIVALS_RUNS=100 prints how often they come in
// the simulator.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/alignment_events.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/rival_hunters.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final enemies = _table('enemies');
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

  test('every clan has a line fighter and a captain', () {
    for (final clan in data.clans) {
      final mine = {
        for (final MapEntry(:key, :value) in enemies.entries)
          if ((value as Map)['hunterClan'] == clan.id) key: value,
      };
      final tiers = mine.values.map((v) => v['hunterTier']).toSet();
      expect(tiers, containsAll([1, 2]), reason: clan.id);
      for (final MapEntry(:key, :value) in mine.entries) {
        final enemy = value as Map<String, dynamic>;
        expect(enemy['faction'], clan.id, reason: key);
        if (enemy['hunterOnly'] == true) {
          // Narrative's: a battle cry in both languages, never an ordinary
          // draw.
          expect(enemy['battleCry'], isNotEmpty, reason: key);
          expect(enemy['battleCry_fr'], isNotEmpty, reason: key);
          expect(isHunterEnemy(enemy), isTrue, reason: key);
        }
      }
    }
    final pool = SubNodeEngine.filterEnemyPool(
        enemies: enemies, unlockedEnemyIds: const [], chapter: 8);
    expect(pool, isNot(contains('vigil_spearman_halvard')));
  });

  test('sworn, each Hostile rival 4%, each hunting one 8%, up to 15%', () {
    // Not sworn: nobody.
    expect(rivalHunts(at({'dominion': 40, 'vigil': -40}), data), isEmpty);
    final sworn = at({'dominion': 70});
    final rivals = rivalsOf('dominion', sworn, data);
    expect(rivals, isNotEmpty);
    expect(rivalHunts(sworn, data), isEmpty);
    // One Hostile rival.
    var state =
        setStandingValue(sworn, rivals.first, -40, 'edit', data: data).state;
    expect(rivalHunts(state, data), {rivals.first: rivalHunterChanceHostile});
    // Hunted.
    state =
        setStandingValue(sworn, rivals.first, -80, 'edit', data: data).state;
    expect(rivalHunterChance(state, data), rivalHunterChanceHunted);
    // Every rival hunting: the cap.
    for (final rival in rivals) {
      state = setStandingValue(state, rival, -80, 'edit', data: data).state;
    }
    expect(rivalHunterChance(state, data),
        min(hunterChanceCap, rivals.length * rivalHunterChanceHunted));
  });

  test('the ambush: a fighter of a hunting rival, tiered by chapter', () {
    expect(rivalHunterPool(enemies: enemies, clanId: 'vigil', chapter: 2),
        ['vigil_spearman_halvard']);
    expect(rivalHunterPool(enemies: enemies, clanId: 'vigil', chapter: 4),
        containsAll(['vigil_spearman_halvard', 'vigil_candlebearer_ysel']));
    var state = at({'dominion': 70});
    state = setStandingValue(state, 'vigil', -80, 'edit', data: data).state;
    final random = Random(1);
    List<StoryNode>? chain;
    for (var i = 0; i < 200 && chain == null; i++) {
      chain = maybeRivalHunter(
          politics: state,
          data: data,
          enemies: enemies,
          chapter: 4,
          random: random);
    }
    expect(chain, isNotNull);
    final choice = chain!.single.choices.single;
    expect(choice.isHunterAmbush, isTrue);
    expect(isHunterAmbushChain(chain), isTrue);
    final enemy = enemies[choice.triggerEnemyId] as Map;
    expect(enemy['hunterClan'], isNot('dominion'));
    expect(chain.single.description, contains(enemy['enemyName']));
    // Off, or within the cooldown: nothing.
    expect(
        maybeRivalHunter(
            politics: state,
            data: data,
            enemies: enemies,
            chapter: 4,
            random: Random(1),
            enabled: false),
        isNull);
    expect(
        maybeRivalHunter(
            politics: state,
            data: data,
            enemies: enemies,
            chapter: 4,
            random: Random(1),
            cooledDown: false),
        isNull);
  });

  test('in the simulator, how often they come', () {
    final runs = int.tryParse(Platform.environment['RIVALS_RUNS'] ?? '');
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
        'expedition_steps', 'training_paths',
      ])
        name: _table(name),
    };
    final summaries = simulatePlaythroughs(story,
        tables: tables,
        gameConfig: _table('game_config'),
        plan: [
          for (var i = 0; i < runs; i++)
            (
              strategy: SimStrategy.values[i % 4],
              raceId: null,
              professionId: null
            ),
        ],
        seed: 17);
    var rivals = 0, hunters = 0, withRivals = 0;
    for (final r in summaries) {
      final n = r.roads.where((x) => x.kind == 'rival_hunter').length;
      rivals += n;
      if (n > 0) withRivals++;
      hunters += r.roads.where((x) => x.kind == 'hunter').length;
    }
    // ignore: avoid_print
    print('rival hunters: ${(rivals / runs).toStringAsFixed(2)} a run, '
        'in $withRivals of $runs runs; alignment hunters: '
        '${(hunters / runs).toStringAsFixed(2)} a run');
  });
}
