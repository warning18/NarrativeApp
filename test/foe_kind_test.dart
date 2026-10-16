// What a foe is (foe_kind.dart): every enemy has a kind, an Evil foe is the
// void, the dead or a demon, beasts tire, the dead crumble, and only people
// and beasts break under morale. KINDS_RUNS=100 prints each profession's
// fights with the foe rules off and on.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/foe_kind.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final enemies = _table('enemies');
  Map<String, dynamic> enemy(String id) => enemies[id] as Map<String, dynamic>;

  test('every enemy has a kind', () {
    const kinds = {
      'person', 'beast', 'undead', 'construct', 'void', 'demon', 'angel', //
      'giant',
    };
    for (final MapEntry(:key, :value) in enemies.entries) {
      expect(kinds, contains((value as Map)['kind']), reason: key);
    }
  });

  test('an Evil foe is the void, the dead or a demon, not merely Light-weak',
      () {
    expect(isEvilFoe(enemy('void_stalker')), isTrue);
    expect(isEvilFoe(enemy('bone_warden')), isTrue);
    expect(isEvilFoe(enemy('demon_imp')), isTrue);
    // Weak to Light, but living people (Narrative's foe-kinds review).
    expect(isEvilFoe(enemy('kelda_turned')), isFalse);
    expect(isEvilFoe(enemy('cultist_acolyte')), isFalse);
    expect(isEvilFoe(enemy('slum_thug')), isFalse);
  });

  test('beasts tire, the dead crumble, people and beasts break', () {
    final rat = enemy('harbor_rat');
    expect(foeBlow(100, rat, 5), 100);
    expect(foeBlow(100, rat, 6), 95);
    expect(foeBlow(100, rat, 30), 50);
    expect(foeBlow(100, enemy('slum_thug'), 9), 100);
    expect(crumble(enemy('bone_warden'), 200, 5), 0);
    expect(crumble(enemy('bone_warden'), 200, 6), 6);
    expect(crumble(rat, 200, 9), 0);
    expect(canWaver(rat), isTrue);
    expect(canWaver(enemy('slum_thug')), isTrue);
    expect(canWaver(enemy('bone_warden')), isFalse);
    expect(canWaver(enemy('iron_golem')), isFalse);
  });

  test('in the simulator, the foe rules off and on', () {
    final runs = int.tryParse(Platform.environment['KINDS_RUNS'] ?? '');
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
    String measure(String profession, Set<String> off) {
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
          clashOff: off);
      var won = 0, fights = 0, rounds = 0;
      for (final r in summaries) {
        won += r.fightsWon;
        fights += r.fightsWon + r.fightsLost;
        rounds += r.roundsFought;
      }
      return '${(100 * won / fights).toStringAsFixed(1)}% / '
          '${(rounds / fights).toStringAsFixed(1)}';
    }

    final lines = [
      for (final p in ['cleric', 'mage', 'ranger', 'rogue', 'warrior'])
        '| $p | ${measure(p, const {'kinds'})} | ${measure(p, const {})} |',
    ];
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}
