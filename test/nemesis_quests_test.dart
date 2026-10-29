// The nemesis quests and their champions (v5.2 step 6, PR 5,
// nemesis.dart): a clan made the character's nemesis opens its quest; its
// trail, then its champion (a boss, met by Force, Guile or Mercy, each
// with its edge), come on roads at rest while the quest is under way;
// the quest's turn-in breaks the nemesis. The champions' curve: about
// half won where they come (the simulator with championFights on).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart' show isBossEnemy;
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/data/clan_crisis.dart' show isClanCrisisNode;
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/nemesis.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/models/story_node.dart';

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
      // The trail first, then the champion.
      final objectives = (quest['objectives'] as List).cast<Map>();
      expect(objectives.map((o) => o['type']), ['Flag', 'Kill']);
      expect(objectives.first['targetFlag'], trailFlagOf(clan));
      expect(objectives.last['targetEnemyID'], championIdOf(clan));
      // Narrative's ways in and the clan's own news.
      for (final way in ['wayForce', 'wayGuile', 'wayMercy']) {
        expect(champion[way], isNotEmpty, reason: '$clan $way');
        expect(champion['${way}_fr'], isNotEmpty, reason: '$clan $way');
      }
      expect(data.faction(clan)!.brokenNews, isNotEmpty, reason: clan);
      for (final turnIn in quest['turnInChoices'] as List) {
        expect((turnIn as Map)['politics'], {'breakNemesis': clan});
      }
    }
  });

  test('the trail, then the champion, while its quest is under way', () {
    final politics = PoliticsState.empty.copyWith(nemesis: 'crows');
    List<StoryNode>? roll(int seed,
            {List<String> active = const ['q_nemesis_crows'],
            int chapter = 5,
            List<String> flags = const []}) =>
        maybeChampionRoad(
            politics: politics,
            activeQuestIds: active,
            enemies: enemies,
            chapter: chapter,
            random: Random(seed),
            flags: flags,
            quests: quests);
    final met = [for (var i = 0; i < 400; i++) roll(i)].whereType<List>();
    expect(met.length, inInclusiveRange(100, 180));
    // The trail first: no fight, its flag.
    final trail = met.first.single as StoryNode;
    expect(trail.choices.single.triggerEnemyId, isNull);
    expect(trail.choices.single.flagsToAdd, [trailFlagOf('crows')]);
    expect(trail.description, contains('leads somewhere'));
    expect(trail.descriptionFr, isNot(contains('{')));
    // The trail followed: the champion, by three ways in.
    final node = [
      for (var i = 0; i < 100; i++) roll(i, flags: [trailFlagOf('crows')])
    ].nonNulls.first.single;
    expect(node.choices, hasLength(3));
    for (final (i, way) in championWays.indexed) {
      final choice = node.choices[i];
      expect(choice.triggerEnemyId, 'champion_crows');
      expect(choice.roadEvent, 'nemesis_$way');
      expect(choice.flagsToAdd, [wayFlagOf('crows', way)]);
      expect(
          choice.text,
          (enemies['champion_crows']
              as Map)['way${way[0].toUpperCase()}${way.substring(1)}']);
      // Each way an edge, none too much.
      final edge = EncounterModifiers.fromChoice(choice);
      final eased = edge.healthMultiplier * edge.difficultyMultiplier;
      expect(eased, inInclusiveRange(0.8, 0.95), reason: way);
    }
    // Mercy, won, earns standing (the node's politics apply on the road).
    expect(isClanCrisisNode(node.id), isTrue);
    expect(node.choices.last.politics!.standing, {'crows': mercyStanding});
    expect(node.choices.first.politics, isNull);
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
    // The clan's own words.
    expect(
        change.politics.news.last.text, data.faction('dominion')!.brokenNews);
  });

  // The champions' curve is measured in boss_balance_test.dart, on the boss
  // curve's own run (one walk of 400 runs instead of two).
}
