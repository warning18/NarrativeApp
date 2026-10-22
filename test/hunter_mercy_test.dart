// Mercy for a rival's hunter (v1.387, hunter_mercy.dart): the betrayal's
// odds by alignment, the Perception read, the session's flags (a spared
// hunter gone or a betrayal on its way, counted down road by road), the
// back-stab ambush, and (MERCY_RUNS=200) how often the simulator's walk
// spares, finishes and is betrayed.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/hunter_mercy.dart';
import 'package:narrative_data_app/data/rival_hunters.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final enemies = _table('enemies');
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );

  test('every rival hunter has an alignment', () {
    for (final MapEntry(:key, :value) in enemies.entries) {
      final enemy = value as Map<String, dynamic>;
      if ((enemy['hunterClan']?.toString() ?? '').isEmpty) continue;
      expect(enemy['alignment'], isA<int>(), reason: key);
    }
  });

  test('the further apart, the likelier the back-stab', () {
    expect(betrayalChance(10, 10), closeTo(0.10, 1e-9));
    expect(betrayalChance(30, -10), closeTo(0.26, 1e-9));
    expect(betrayalChance(-50, 50), closeTo(0.50, 1e-9));
    expect(betrayalChance(-100, 100), betrayalMax);
  });

  test('Perception reads the side, and how close it is', () {
    expect(readHunter(30, 25), (side: 'good', close: true));
    expect(readHunter(-25, 40), (side: 'evil', close: false));
    expect(readHunter(0, 0).side, 'neutral');
  });

  test('the flags: a betrayal on its way, a betrayer, one gone', () {
    final flags = [betrayalFlag('mire_returned_sedge', 3), 'other'];
    expect(pendingBetrayals(flags), {'mire_returned_sedge': 3});
    expect(sparable('x', [betrayerFlag('x')]), isFalse);
    expect(sparable('x', const []), isTrue);
    for (var i = 0; i < 50; i++) {
      final roads = betrayalRoads(Random(i));
      expect(roads, inInclusiveRange(betrayalMinRoads, betrayalMaxRoads));
    }
  });

  test('the back-stab: the same hunter, striking first', () {
    final node =
        betrayalAmbushNode('vigil_spearman_halvard', enemies, Random(1));
    final choice = node.choices.single;
    expect(choice.triggerEnemyId, 'vigil_spearman_halvard');
    expect(choice.forcedCondition, 'ambush');
    expect(choice.isHunterAmbush, isTrue);
    expect(node.description, contains('Halvard'));
  });

  test('a hunter spared or betraying comes no more as an ordinary one', () {
    expect(
        rivalHunterPool(
            enemies: enemies,
            clanId: 'vigil',
            chapter: 4,
            gone: {'vigil_spearman_halvard'}),
        ['vigil_candlebearer_ysel']);
  });

  test('in the session: spared, the standing and the betrayal\'s countdown',
      () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await notifier.loadSession(baseSession().copyWith(alignmentScore: 0));
    final before = notifier.state.politics.standingOf('vigil', data);
    // Far apart: find a seed that betrays.
    var seed = 0;
    while (Random(seed).nextDouble() >= betrayalChance(-100, 0)) {
      seed++;
    }
    final betrays = await notifier.settleHunter('vigil_spearman_halvard',
        hunterClan: 'vigil',
        alignment: -100,
        spared: true,
        data: data,
        random: Random(seed));
    expect(betrays, isTrue);
    expect(notifier.state.politics.standingOf('vigil', data),
        before + spareStanding);
    final roads = pendingBetrayals(notifier.state.flags).values.single;
    String? due;
    for (var i = 0; i < roads; i++) {
      due = await notifier.tickBetrayals();
    }
    expect(due, 'vigil_spearman_halvard');
    expect(notifier.state.flags, contains(betrayerFlag(due!)));
    expect(pendingBetrayals(notifier.state.flags), isEmpty);
    // Finished: the standing falls.
    final mire = notifier.state.politics.standingOf('mire', data);
    await notifier.settleHunter('mire_returned_sedge',
        hunterClan: 'mire',
        alignment: 0,
        spared: false,
        data: data,
        random: Random(1));
    expect(notifier.state.politics.standingOf('mire', data),
        mire + finishStanding);
  });

  test('in the simulator, how often', () {
    final runs = int.tryParse(Platform.environment['MERCY_RUNS'] ?? '');
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
        'expedition_steps', 'training_paths', 'politics_events',
        'specialisations',
        'spec_variants',
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
    var spared = 0, finished = 0, betrayed = 0, withHunters = 0;
    for (final r in summaries) {
      spared += r.mercy.spared;
      finished += r.mercy.finished;
      betrayed += r.mercy.betrayed;
      if (r.mercy.spared + r.mercy.finished > 0) withHunters++;
    }
    final met = spared + finished;
    // ignore: avoid_print
    print('rival hunters beaten: $met in $withHunters of $runs runs; '
        'spared $spared (${(100 * spared / max(1, met)).toStringAsFixed(0)}%), '
        'finished $finished; betrayed $betrayed '
        '(${(100 * betrayed / max(1, spared)).toStringAsFixed(0)}% of the spared)');
  });
}
