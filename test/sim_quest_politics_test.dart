// The simulator's quest turn-in politics (v1.463): a quest settled with a
// turn-in choice moves the clans as the app's quest_turn_in.dart does, once
// under questTurnInPoliticsKey and logged `quest:<id>`, so a main clan it
// raises by questPowerStanding or more gains questPower and is spared this
// chapter's neglect.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/politics_events.dart'
    show questTurnInPoliticsKey;
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/sim_growth.dart';
import 'package:narrative_data_app/data/sim_quests.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/turn_in_choices.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final clans = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );

  test('a turn-in choice\'s politics come with the payout and apply once', () {
    final log = SimQuestLog({
      'candles': {
        'questName': 'Candles',
        'requiredAlignment': 'Neutral',
        'rewardGold': 10,
        'rewardXP': 0,
        'alignmentChange': 0,
        'objectives': <Map<String, dynamic>>[],
        'turnInChoices': [
          {
            'choiceText': 'For the Vigil',
            'alignmentChange': 5,
            'politics': {
              'standing': {'vigil': 10, 'dominion': -5},
            },
          },
          {'choiceText': 'Keep quiet', 'alignmentChange': -5},
        ],
      },
    });
    log.accept('candles',
        step: 0, flags: const {}, gold: 0, alignmentLabel: 'Neutral');
    final pay = log.complete('candles',
        step: 1, bias: SimTurnInBias.good, random: Random(1));
    expect(pay.turnIn, 'For the Vigil');
    expect(pay.politics?.standing, {'vigil': 10, 'dominion': -5});
    expect(pay.politicsKey, questTurnInPoliticsKey('candles', 0));

    final growth = SimGrowth(
      mode: SimProgression.offers,
      tables: SimGrowthTables(clans: clans),
      character: SimCharacter.create(
        raceId: 'human',
        race: _table('races')['human'] as Map<String, dynamic>,
        professionId: 'warrior',
        profession: _table('professions')['warrior'] as Map<String, dynamic>,
        gameConfig: _table('game_config'),
        dice: _table('dice'),
        spells: parseSpells(_table('spells')),
      ),
    );
    final vigil0 = powerOf(growth.politics, 'vigil', clans);
    final standing0 = growth.politics.standingOf('vigil', clans);
    for (var i = 0; i < 2; i++) {
      growth.applyStoryPolitics(pay.politics!,
          flags: const [],
          chapter: 5,
          key: pay.politicsKey,
          cause: 'quest:candles');
    }
    expect(growth.politics.standingOf('vigil', clans), standing0 + 10,
        reason: 'applied once');
    expect(powerOf(growth.politics, 'vigil', clans), vigil0 + questPower);
    expect(growth.politics.helped, contains('vigil'),
        reason: 'no neglect this chapter');
    expect(growth.politics.helped, isNot(contains('dominion')));

    // A choice without politics brings none.
    final quiet = SimQuestLog(log.quests)
      ..accept('candles',
          step: 0, flags: const {}, gold: 0, alignmentLabel: 'Neutral');
    final pay2 = quiet.complete('candles',
        step: 1, bias: SimTurnInBias.evil, random: Random(1));
    expect(pay2.turnIn, 'Keep quiet');
    expect(pay2.politics, isNull);
  });

  test('a simulated playthrough applies the turn-ins\' politics', () {
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
    final quests = tables['quests']!;
    final runs = simulatePlaythroughs(story,
        tables: tables,
        gameConfig: _table('game_config'),
        plan: [
          for (final s in [SimStrategy.completionist, SimStrategy.favorGood])
            (strategy: s, raceId: null, professionId: null),
        ],
        seed: 7000);
    var seen = 0;
    for (final run in runs) {
      for (final record in run.questRecords) {
        if (record.completedAtStep == null || record.turnIn.isEmpty) continue;
        final choices =
            turnInChoicesOf(quests[record.questId] as Map<String, dynamic>);
        final i = choices.indexWhere((c) => c.text == record.turnIn);
        if (i < 0 || !choices[i].hasPolitics) continue;
        seen++;
        expect(run.politics.applied(questTurnInPoliticsKey(record.questId, i)),
            isTrue,
            reason: '${record.questId} settled "${record.turnIn}"');
        if (choices[i].politics!.standing.isNotEmpty) {
          expect(
              run.politics.standingLog
                  .any((e) => e.cause == 'quest:${record.questId}'),
              isTrue,
              reason: '${record.questId} logged under the quest');
        }
      }
    }
    expect(seen, greaterThan(0), reason: 'a quest with politics handed in');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
