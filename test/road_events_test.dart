// What waits on the road (v1.176): road events known before the party
// sets out (a champion, a shrine, the Wayfarer's Caravan), fewer and
// shorter detours, and three travellers met again and again who remember
// what the party did.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/loot_box.dart';
import 'package:narrative_data_app/data/journey_rules.dart';
import 'package:narrative_data_app/data/recurring_encounters.dart';
import 'package:narrative_data_app/data/road_events.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

StoryData _story() {
  final raw = _json('assets/Cleaned_Narrative_DAG.json');
  return StoryData({
    for (final entry in raw.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  });
}

void main() {
  final story = _story();

  group('road events', () {
    // Every road between two places the story takes from chapter 2 on.
    final roads = [
      for (final node in story.nodes.values)
        for (final choice in node.choices)
          if (!choice.isEnding && isRoadStep(node.id, choice.nextId))
            (from: node.id, to: choice.nextId),
    ];

    test('the same road holds the same thing at the same point', () {
      expect(stableHash('abc'), stableHash('abc'));
      expect(stableHash('abc'), isNot(stableHash('abd')));
      for (final road in roads.take(20)) {
        for (final at in [3, 40]) {
          RoadEventKind? event() => roadEventFor(
                story: story,
                fromNodeId: road.from,
                toNodeId: road.to,
                historyLength: at,
                chapter: 4,
              );
          expect(event(), event());
        }
      }
    });

    test('about a third of the roads hold one, of every kind', () {
      final seen = <RoadEventKind, int>{};
      var tries = 0;
      for (final road in roads) {
        for (var at = 0; at < 20; at++) {
          tries++;
          final event = roadEventFor(
            story: story,
            fromNodeId: road.from,
            toNodeId: road.to,
            historyLength: at,
            chapter: 3,
          );
          if (event != null) seen[event] = (seen[event] ?? 0) + 1;
        }
      }
      final share = seen.values.fold(0, (a, b) => a + b) / tries;
      expect(share, inInclusiveRange(0.1, roadEventChance + 0.05));
      expect(seen.keys.toSet(), RoadEventKind.values.toSet());
    });

    test('none in chapter 1, within a place, or into an ending', () {
      for (final road in roads.take(40)) {
        expect(
            roadEventFor(
              story: story,
              fromNodeId: road.from,
              toNodeId: road.to,
              historyLength: 7,
              chapter: 1,
            ),
            isNull);
      }
      expect(
          roadEventFor(
              story: story,
              fromNodeId: '5003',
              toNodeId: '5004',
              historyLength: 7,
              chapter: 4),
          isNull);
    });

    test('a champion is an Elite fight with a better chest, or a hard sneak',
        () {
      final chain = roadEventChain(RoadEventKind.champion,
          chapter: 3, enemyPool: const ['harbor_rat'], seed: 11);
      final node = chain.single;
      expect(node.description, isNotEmpty);
      expect(node.descriptionFr, isNotEmpty);
      final fight = node.choices.first;
      expect(fight.triggerEnemyId, 'harbor_rat');
      final modifiers = EncounterModifiers.fromChoice(fight);
      expect(modifiers.forceElite, isTrue);
      expect(modifiers.chestTierFloor, ChestTier.silver);
      final sneak = node.choices[1];
      expect(sneak.avoidFightOnSuccess, isTrue);
      expect(sneak.checkDC, greaterThan(SubNodeEngine.detourCheckDc(3)));
      // With no foe to draw, a shrine stands there instead.
      expect(
          roadEventChain(RoadEventKind.champion,
                  chapter: 3, enemyPool: const [], seed: 11)
              .single
              .choices
              .first
              .healAmount,
          greaterThan(0));
    });

    test('a shrine heals, more for an offering; the caravan sells', () {
      final shrine = roadEventChain(RoadEventKind.shrine,
              chapter: 4, enemyPool: const [], seed: 3)
          .single;
      expect(shrine.choices[0].healAmount, shrineHealFor(4));
      expect(shrine.choices[1].goldMod, -shrineOfferingFor(4));
      expect(shrine.choices[1].healAmount, greaterThan(shrineHealFor(4)));
      final caravan = roadEventChain(RoadEventKind.caravan,
              chapter: 4, enemyPool: const [], seed: 3)
          .single;
      expect(caravan.choices.first.unlockShopId, caravanShopId);
      final shops = _json('assets/gamedata/shops.json');
      final shop = shops[caravanShopId] as Map<String, dynamic>;
      expect(shop['detourEligible'], isFalse);
      expect(shop['shopName_fr'], isNotEmpty);
      final items = _json('assets/gamedata/items.json');
      for (final id in shop['initialStock'] as List) {
        expect(items, contains(id));
      }
      for (final kind in RoadEventKind.values) {
        for (final choice in roadEventChain(kind,
                chapter: 5, enemyPool: const ['harbor_rat'], seed: 5)
            .single
            .choices) {
          expect(choice.textFr, isNotEmpty);
          expect(choice.text.length, lessThanOrEqualTo(55));
        }
      }
    });
  });

  group('detours', () {
    test('fewer, and shorter', () {
      expect(SubNodeEngine.detourChance, 0.35);
      final random = Random(4);
      var chains = 0;
      for (var i = 0; i < 200; i++) {
        final chain = SubNodeEngine.maybeGenerate(
          random: random,
          chapter: 3,
          shops: const {},
          enemies: const {},
          quests: const {},
          unlockedShopIds: const [],
          unlockedEnemyIds: const [],
          unlockedQuestIds: const [],
          completedQuestIds: const [],
          triggerChance: 1,
        );
        if (chain == null) continue;
        chains++;
        expect(chain.length, inInclusiveRange(1, 2));
      }
      expect(chains, 200);
    });
  });

  group('familiar faces', () {
    test('each traveller is met first from their chapter on', () {
      expect(recurringBeatsOpen(flags: const {}, chapter: 1), isEmpty);
      expect(recurringBeatsOpen(flags: const {}, chapter: 2),
          containsAll([(who: 'wren', stage: 1), (who: 'oswin', stage: 1)]));
      expect(recurringBeatsOpen(flags: const {}, chapter: 3),
          contains((who: 'mira', stage: 1)));
    });

    test('a beat follows the one before it, a chapter or more on', () {
      final met = {'met_wren_1', 'wren_helped'};
      expect(recurringBeatsOpen(flags: met, chapter: 2),
          isNot(contains((who: 'wren', stage: 2))));
      expect(recurringBeatsOpen(flags: met, chapter: 3),
          contains((who: 'wren', stage: 2)));
      expect(recurringBeatsOpen(flags: met, chapter: 3),
          isNot(contains((who: 'wren', stage: 1))));
      // A cold shoulder ends Wren's story at her second beat.
      expect(
          recurringBeatsOpen(
              flags: {'met_wren_1', 'met_wren_2', 'wren_left'}, chapter: 6),
          isNot(contains((who: 'wren', stage: 3))));
    });

    test('they remember what the party did', () {
      String textFor(Set<String> flags) =>
          recurringBeatScene('wren', 2, flags: flags, chapter: 3).description;
      final helped = textFor({'wren_helped'});
      final sold = textFor({'wren_sold'});
      final left = textFor({'wren_left'});
      expect({helped, sold, left}, hasLength(3));
      final cheated = recurringBeatScene('mira', 2,
          flags: {'mira_cheated'}, chapter: 4, enemyId: 'harbor_rat');
      expect(cheated.choices.first.triggerEnemyId, 'harbor_rat');
      final split = recurringBeatScene('mira', 2,
          flags: {'mira_split'}, chapter: 4, enemyId: 'harbor_rat');
      expect(split.choices.every((c) => !c.triggersCombat), isTrue);
    });

    test('every beat is written in both languages and marks the meeting', () {
      final everyone = {
        for (final who in ['wren', 'oswin', 'mira'])
          for (var stage = 1; stage <= 3; stage++) markerFor(who, stage),
      };
      for (final who in ['wren', 'oswin', 'mira']) {
        for (var stage = 1; stage <= 3; stage++) {
          for (final flags in <Set<String>>[
            {},
            {'wren_helped', 'oswin_paid', 'mira_split'},
            {'wren_sold', 'oswin_refused', 'mira_cheated'},
            {'wren_left', 'oswin_dug', 'mira_yielded'},
          ]) {
            final scene = recurringBeatScene(who, stage,
                flags: flags.difference(everyone),
                chapter: 5,
                enemyId: 'harbor_rat');
            expect(scene.description, isNotEmpty);
            expect(scene.descriptionFr, isNotEmpty);
            expect(scene.choices, isNotEmpty);
            for (final choice in scene.choices) {
              expect(choice.textFr, isNotEmpty, reason: choice.text);
              expect(choice.text.length, lessThanOrEqualTo(55),
                  reason: choice.text);
              expect(choice.flagsToAdd, contains(markerFor(who, stage)),
                  reason: choice.text);
            }
          }
        }
      }
    });

    test('met now and then, never when nobody is left to meet', () {
      final met = maybeRecurringEncounter(
        flags: const {},
        chapter: 3,
        random: Random(1),
        enemyPool: const ['harbor_rat'],
        chance: 1,
      );
      expect(met, hasLength(1));
      expect(
          maybeRecurringEncounter(
            flags: const {},
            chapter: 3,
            random: Random(1),
            enemyPool: const [],
            chance: 0,
          ),
          isNull);
      final done = {
        for (final who in ['wren', 'oswin', 'mira'])
          for (var stage = 1; stage <= 3; stage++) markerFor(who, stage),
      };
      expect(
          maybeRecurringEncounter(
            flags: done,
            chapter: 6,
            random: Random(1),
            enemyPool: const [],
            chance: 1,
          ),
          isNull);
    });
  });
}
