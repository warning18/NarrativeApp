// The nemesis and the alignment hunters for everyone (v5.2 step 6, PR 2:
// nemesis.dart, rival_hunters.dart, alignment_events.dart): who becomes the
// nemesis and when it lets go, its hunt without an oath, its war on your
// patron, breaking it; a neutral character hunted lightly by both sides,
// and Narrative's good orders and evil forces. HUNT_RUNS=n prints the
// hunters a run by alignment, and the nemesis (the PR's table).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/alignment_events.dart';
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/nemesis.dart';
import 'package:narrative_data_app/data/rival_hunters.dart';
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
  final enemies = _table('enemies');
  PoliticsState at(Map<String, num> standings, [PoliticsState? from]) {
    var state = from ?? PoliticsState.empty;
    for (final e in standings.entries) {
      state = setStandingValue(state, e.key, e.value, 'edit', data: data).state;
    }
    return state;
  }

  group('the nemesis', () {
    test('the strongest clan turned Hostile, with power enough', () {
      expect(nemesisCandidate(PoliticsState.empty, data), '');
      final state = at({'mire': -40, 'dominion': -40});
      expect(nemesisCandidate(state, data), 'dominion');
      // Too weak to hunt: the Mire at 20.
      expect(
          nemesisCandidate(
              at({'mire': -40}).copyWith(power: {'mire': 20}), data),
          '');
      // Resented is not enough.
      expect(nemesisCandidate(at({'dominion': -20}), data), '');
    });

    test('it rises at a chapter\'s turn, holds, and lets go at Wary', () {
      var state = updateNemesis(at({'crows': -40}), data, chapter: 3);
      expect(state.nemesis, 'crows');
      expect(state.news.last.eventId, 'nemesis:crows');
      expect(state.news.last.text, contains('nemesis'));
      // Climbing to Resented: still the nemesis.
      state = updateNemesis(at({'crows': -20}, state), data, chapter: 4);
      expect(state.nemesis, 'crows');
      // At Wary, it lets go.
      state = updateNemesis(at({'crows': -5}, state), data, chapter: 5);
      expect(state.nemesis, '');
      expect(state.news.last.eventId, 'nemesis_end:crows');
    });

    test('it hunts without an oath, at the Hunted odds', () {
      final state = updateNemesis(at({'compact': -40}), data, chapter: 3);
      expect(state.swornFactionId, '');
      expect(rivalHunts(state, data), {'compact': rivalHunterChanceHunted});
      expect(rivalHunterChance(state, data), rivalHunterChanceHunted);
      final roads = [
        for (var i = 0; i < 400; i++)
          maybeRivalHunter(
              politics: state,
              data: data,
              enemies: enemies,
              chapter: 3,
              random: Random(i)),
      ].whereType<List<StoryNode>>();
      expect(roads, isNotEmpty);
      for (final road in roads) {
        final id = road.single.choices.single.triggerEnemyId!;
        expect((enemies[id] as Map)['hunterClan'], 'compact');
      }
    });

    test('broken, it loses a tier and can\'t return for two chapters', () {
      var state = updateNemesis(at({'dominion': -40}), data, chapter: 3);
      state = breakNemesis(state, 'dominion', data, chapter: 3);
      expect(state.nemesis, '');
      expect(powerOf(state, 'dominion', data), 60 - risingPower);
      expect(updateNemesis(state, data, chapter: 4).nemesis, '');
      expect(updateNemesis(state, data, chapter: 5).nemesis, 'dominion');
    });

    test('at war, it takes your patron\'s places first', () {
      final geography = Geography.parse(
          geography: _table('geography'), biomes: _table('biomes'));
      // Friendly with the Compact (the patron), the Dominion the nemesis,
      // the two Hostile (step 3), the Compact weak.
      var state = at({'compact': 30, 'dominion': -40}).copyWith(
          power: {'compact': 30},
          helped: ['compact', 'dominion'],
          relationSteps: {relationKey('dominion', 'compact'): 3});
      state = updateNemesis(state, data, chapter: 3);
      expect(state.nemesis, 'dominion');
      final turn = territoryTurn(state,
          data: data, geography: Geography.empty, chapter: 3);
      expect(turn.changes, isEmpty); // No map, nothing to take.
      final war =
          territoryTurn(state, data: data, geography: geography, chapter: 3)
              .changes
              .where((c) => c.cause == 'war')
              .single;
      expect(war.to, 'dominion');
      expect(war.from, 'compact');
    });

    test('the nemesis is saved', () {
      final state = PoliticsState.empty
          .copyWith(nemesis: 'mire', nemesisCooldown: {'crows': 5});
      final back = PoliticsState.fromJson(
          jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>);
      expect(back.nemesis, 'mire');
      expect(back.nemesisCooldown, {'crows': 5});
    });
  });

  group('the alignment hunters', () {
    test('a neutral character is hunted lightly, meeting the curve', () {
      expect(hunterChanceFor(0), closeTo(0.02, 1e-9));
      expect(hunterChanceFor(-10), closeTo(0.04, 1e-9));
      expect(hunterChanceFor(19), closeTo(0.058, 1e-9));
      expect(hunterChanceFor(20), closeTo(hunterBaseChance, 1e-9));
      expect(hunterChanceFor(100), hunterChanceCap);
      // Both sides, by the lean.
      final sides = [
        for (var i = 0; i < 400; i++) neutralHuntedSide(0, Random(i)),
      ];
      expect(
          sides.where((s) => s == 'Good').length, inInclusiveRange(150, 250));
      final leaning = [
        for (var i = 0; i < 400; i++) neutralHuntedSide(15, Random(i)),
      ];
      expect(leaning.where((s) => s == 'Good').length, greaterThan(300));
    });

    test('Narrative\'s six: the good orders and the evil forces', () {
      for (final id in [
        'vigil_candlebearer_ysel',
        'vigil_spearman_halvard',
        'masked_penitent',
      ]) {
        expect((enemies[id] as Map)['hunterAlignment'], 'Evil', reason: id);
        expect(((enemies[id] as Map)['alignment'] as num), greaterThan(19),
            reason: '$id reads Good');
      }
      for (final id in [
        'cultist_acolyte',
        'hollow_court_zealot',
        'void_hound'
      ]) {
        final enemy = enemies[id] as Map<String, dynamic>;
        expect(enemy['hunterAlignment'], 'Good', reason: id);
        expect(enemy['alignment'] as num, inInclusiveRange(-35, -25),
            reason: id);
        expect(enemy['battleCry'], isNotEmpty, reason: id);
        expect(enemy['battleCry_fr'], isNotEmpty, reason: id);
        // Still met on the roads as ever.
        expect(isHunterEnemy(enemy), isFalse, reason: id);
      }
      // The Inquisition soldier stays a clan hunter only.
      expect((enemies['inquisition_soldier'] as Map)['hunterAlignment'] ?? '',
          isEmpty);
      expect(isHunterEnemy(enemies['angel_sentinel'] as Map<String, dynamic>),
          isTrue);
      // Each comes from its own chapter.
      expect(hunterPoolFor(enemies: enemies, side: 'Good', chapter: 2),
          isNot(contains('cultist_acolyte')));
      expect(
          hunterPoolFor(enemies: enemies, side: 'Good', chapter: 5),
          containsAll(
              ['cultist_acolyte', 'void_hound', 'hollow_court_zealot']));
      expect(hunterPoolFor(enemies: enemies, side: 'Evil', chapter: 5),
          containsAll(['vigil_spearman_halvard', 'masked_penitent']));
    });

    test('their ambush lines are Narrative\'s, with the cry', () {
      for (var i = 0; i < 40; i++) {
        final node = buildHunterAmbushNode(
            enemies: {'cultist_acolyte': enemies['cultist_acolyte']},
            side: 'Good',
            chapter: 4,
            random: Random(i))!;
        expect(node.description, contains('kept your hands clean'));
        expect(node.description, contains('The tear is kind'));
        expect(node.descriptionFr, contains('mains propres'));
      }
      final neutral = buildHunterAmbushNode(enemies: {
        'vigil_spearman_halvard': enemies['vigil_spearman_halvard']
      }, side: 'Evil', chapter: 4, random: Random(1), neutral: true)!;
      expect(neutral.description, contains('You have not chosen'));
      expect(neutral.contextNote, contains('not chosen a side'));
      // The angels keep their own words.
      final angel = buildHunterAmbushNode(
          enemies: {'angel_sentinel': enemies['angel_sentinel']},
          side: 'Evil',
          chapter: 4,
          random: Random(1))!;
      expect(angel.description, isNot(contains('{name}')));
      expect(angel.contextNote, contains('Choir'));
    });

    test('a neutral character meets them on the road', () {
      var ambushes = 0;
      for (var i = 0; i < 2000; i++) {
        final event = maybeAlignmentEvent(
            alignmentScore: 0,
            activeQuestIds: const [],
            completedQuestIds: const [],
            enemies: enemies,
            chapter: 4,
            random: Random(i));
        if (event != null && isHunterAmbushChain(event)) ambushes++;
      }
      // About 2%.
      expect(ambushes, inInclusiveRange(20, 70));
    });
  });

  test('in the simulator, the hunters a run', () {
    final runs = int.tryParse(Platform.environment['HUNT_RUNS'] ?? '');
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
    final bands = <String, List<num>>{};
    for (final r in summaries) {
      final a = r.finalAlignment.abs();
      final band = a < 20
          ? 'Neutral (under ±20)'
          : a < 50
              ? 'Leaning (±20 to ±49)'
              : 'Strong (±50 and past)';
      final b = bands.putIfAbsent(band, () => [0, 0, 0, 0, 0, 0, 0]);
      int count(String kind) => r.roads.where((x) => x.kind == kind).length;
      b[0] += 1;
      b[1] += count('hunter');
      b[2] += count('rival_hunter');
      b[3] += count('nemesis_hunter');
      b[4] += count('betrayal');
      b[5] += r.nemeses.isNotEmpty ? 1 : 0;
      b[6] += r.roads.where((x) => x.atRest).length;
    }
    String per(num x, num n) => (x / n).toStringAsFixed(2);
    final lines = [
      '| Final alignment | Runs | Alignment hunters | Clan hunters | Nemesis hunters | Betrayals | All | Runs with a nemesis | Roads at rest |',
      '|---|---|---|---|---|---|---|---|---|',
      for (final e
          in bands.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        '| ${e.key} | ${e.value[0]} | ${per(e.value[1], e.value[0])} | '
            '${per(e.value[2], e.value[0])} | ${per(e.value[3], e.value[0])} | '
            '${per(e.value[4], e.value[0])} | '
            '${per(e.value[1] + e.value[2] + e.value[3] + e.value[4], e.value[0])} | '
            '${e.value[5]} | ${per(e.value[6], e.value[0])} |',
    ];
    final nemeses = <String, int>{};
    for (final r in summaries) {
      for (final n in r.nemeses) {
        nemeses[n] = (nemeses[n] ?? 0) + 1;
      }
    }
    // ignore: avoid_print
    print([...lines, 'nemeses: $nemeses'].join('\n'));
  });
}
