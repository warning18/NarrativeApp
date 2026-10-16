// The nemesis quests and their champions (v5.2 step 6, PR 5,
// nemesis.dart): a clan made the character's nemesis opens its quest; its
// champion, a boss, comes on a road at rest while the quest is under way;
// the quest's turn-in breaks the nemesis. The champions' curve: about
// half won where they come (the simulator with championFights on).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart' show isBossEnemy;
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/nemesis.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _clans = ['dominion', 'vigil', 'compact', 'mire', 'crows', 'penitents'];

void main() {
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  final enemies = _table('enemies');
  final quests = _table('quests');

  test('each clan has a champion (a boss) and a quest to beat it', () {
    for (final clan in _clans) {
      final champion = enemies[championIdOf(clan)] as Map<String, dynamic>?;
      expect(champion, isNotNull, reason: clan);
      expect(isBossEnemy(championIdOf(clan), champion!), isTrue, reason: clan);
      expect(champion['championClan'], clan);
      // Never an ordinary rival hunter.
      expect(champion['hunterClan'], isNull);
      expect(champion['hunterOnly'], isTrue);
      final quest = quests[nemesisQuestIdOf(clan)] as Map<String, dynamic>?;
      expect(quest, isNotNull, reason: clan);
      expect(quest!['detourEligible'], isFalse);
      final objective = (quest['objectives'] as List).single as Map;
      expect(objective['type'], 'Kill');
      expect(objective['targetEnemyID'], championIdOf(clan));
      for (final turnIn in quest['turnInChoices'] as List) {
        expect((turnIn as Map)['politics'], {'breakNemesis': clan});
      }
    }
  });

  test('the champion comes on the road while its quest is under way', () {
    final politics = PoliticsState.empty.copyWith(nemesis: 'crows');
    List<StoryNode>? roll(int seed,
            {List<String> active = const ['q_nemesis_crows'],
            int chapter = 5}) =>
        maybeChampionRoad(
            politics: politics,
            activeQuestIds: active,
            enemies: enemies,
            chapter: chapter,
            random: Random(seed));
    final met = [for (var i = 0; i < 400; i++) roll(i)].whereType<List>();
    expect(met.length, inInclusiveRange(100, 180));
    final node = met.first.single as StoryNode;
    expect(node.choices.single.triggerEnemyId, 'champion_crows');
    expect(node.choices.single.text, startsWith('Face '));
    // No quest, too early, or no nemesis: never.
    expect([for (var i = 0; i < 100; i++) roll(i, active: const [])].nonNulls,
        isEmpty);
    expect(
        [for (var i = 0; i < 100; i++) roll(i, chapter: 3)].nonNulls, isEmpty);
  });

  test('the quest\'s turn-in breaks the nemesis', () {
    final state = PoliticsState.empty.copyWith(nemesis: 'dominion');
    final turnIn =
        ((quests['q_nemesis_dominion'] as Map)['turnInChoices'] as List).first
            as Map<String, dynamic>;
    final change = applyStoryPolitics(
        StoryPolitics.tryParse(turnIn['politics'])!,
        cause: 'quest:q_nemesis_dominion',
        politics: state,
        flags: const [],
        world: CoastWorld(data: data, chapter: 5));
    expect(change.politics.nemesis, '');
    expect(powerOf(change.politics, 'dominion', data), 60 - risingPower);
    expect(
        change.politics.nemesisCooldown['dominion'], 5 + nemesisBreakChapters);
    expect(change.politics.news.last.eventId, 'nemesis_broken:dominion');
  });

  test('the champions\' curve: about half won where they come', () {
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
    final runs =
        int.tryParse(Platform.environment['CHAMPION_RUNS'] ?? '') ?? 200;
    final professions = tables['professions']!.keys.toList()..sort();
    final summaries = simulatePlaythroughs(story,
        tables: tables,
        gameConfig: _table('game_config'),
        plan: [
          for (var i = 0; i < runs; i++)
            (
              strategy: SimStrategy.values[i % 4],
              raceId: null,
              professionId: professions[(i ~/ 4) % professions.length],
            ),
        ],
        seed: 7,
        championFights: true);
    final fought = <String, int>{};
    final lost = <String, int>{};
    for (final r in summaries) {
      for (final byChapter in r.enemiesByChapter.values) {
        for (final e in byChapter.entries) {
          if (!e.key.startsWith('champion_')) continue;
          fought[e.key] = (fought[e.key] ?? 0) + e.value.fought;
          lost[e.key] = (lost[e.key] ?? 0) + e.value.lost;
        }
      }
    }
    final all = fought.values.fold(0, (a, b) => a + b);
    final allLost = lost.values.fold(0, (a, b) => a + b);
    final rate = all == 0 ? 0.0 : (all - allLost) / all;
    // ignore: avoid_print
    print('champions: ${(100 * rate).toStringAsFixed(1)}% of $all '
        '(${[
      for (final e in fought.entries)
        '${e.key} ${e.value - (lost[e.key] ?? 0)}/${e.value}'
    ].join(', ')})');
    expect(all, greaterThanOrEqualTo(40), reason: 'too few met');
    expect(rate, closeTo(0.5, 0.12));
  });
}
