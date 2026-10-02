// Road hazards (v1.197): the land a road runs through may throw one of
// its biome's hazards at the party, pushed through at a cost in health
// (never fatal) or waited out at a cost in time; and a champion on that
// road is one of the foes that live there. Fixture biomes over the real
// story's roads.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/journey_rules.dart';
import 'package:narrative_data_app/data/road_events.dart';
import 'package:narrative_data_app/data/road_hazards.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/ally_state.dart';
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

const BiomeHazard _sandstorm = BiomeHazard(
  id: 'sandstorm',
  name: 'Sandstorm',
  nameFr: 'Tempête de sable',
  text: 'The horizon turned brown and came at us.',
  textFr: 'L’horizon vira au brun et fondit sur nous.',
  push: 'Push on through the sand',
  pushFr: 'Avancer dans le sable',
  wait: 'Shelter until it passes',
  waitFr: 'Vous abriter jusqu’à ce qu’elle passe',
);

const BiomeHazard _heat = BiomeHazard(id: 'heat', name: 'Killing heat');

const Biome _desert =
    Biome(id: 'desert', name: 'Desert', hazards: [_sandstorm, _heat]);
const Biome _calm = Biome(id: 'calm', name: 'Calm');

void main() {
  final story = _story();
  // Every road between two places the story takes.
  final roads = [
    for (final node in story.nodes.values)
      for (final choice in node.choices)
        if (!choice.isEnding && isRoadStep(node.id, choice.nextId))
          (from: node.id, to: choice.nextId),
  ];

  group('the mix', () {
    Map<RoadEventKind?, int> tally({double hazardShare = 0}) {
      final seen = <RoadEventKind?, int>{};
      for (final road in roads) {
        for (var at = 0; at < 200; at++) {
          final event = roadEventFor(
            story: story,
            fromNodeId: road.from,
            toNodeId: road.to,
            historyLength: at,
            chapter: 4,
            hazardShare: hazardShare,
          );
          seen[event] = (seen[event] ?? 0) + 1;
        }
      }
      return seen;
    }

    test('a land with hazards has them: about a fifth of the road\'s events',
        () {
      expect(hazardShareFor(_desert), roadHazardShare);
      expect(roadHazardShare, closeTo(0.2, 1e-9));
      final before = tally();
      final after = tally(hazardShare: hazardShareFor(_desert));
      expect(before[RoadEventKind.hazard], isNull);
      final events = after.entries
          .where((e) => e.key != null)
          .fold(0, (a, e) => a + e.value);
      expect(after[RoadEventKind.hazard]! / events, closeTo(0.2, 0.04));
      // As many roads hold something; the champions are the same ones.
      expect(after[null], before[null]);
      expect(after[RoadEventKind.champion], before[RoadEventKind.champion]);
      // The rest comes out of the shrines and the caravan in proportion:
      // 0.3 each becomes 0.2 each.
      final shrines = after[RoadEventKind.shrine]! / events;
      final caravans = after[RoadEventKind.caravan]! / events;
      expect(shrines, closeTo(0.2, 0.04));
      expect(caravans, closeTo(0.2, 0.04));
      expect(after[RoadEventKind.shrine]!,
          lessThan(before[RoadEventKind.shrine]!));
      expect(after[RoadEventKind.caravan]!,
          lessThan(before[RoadEventKind.caravan]!));
    });

    test('a hazard only ever takes a shrine\'s or the caravan\'s place', () {
      for (final road in roads) {
        for (var at = 0; at < 10; at++) {
          RoadEventKind? event(double share) => roadEventFor(
                story: story,
                fromNodeId: road.from,
                toNodeId: road.to,
                historyLength: at,
                chapter: 3,
                hazardShare: share,
              );
          final plain = event(0);
          final rough = event(roadHazardShare);
          if (rough == RoadEventKind.hazard) {
            expect(plain, anyOf(RoadEventKind.shrine, RoadEventKind.caravan));
          } else {
            expect(rough, plain);
          }
        }
      }
    });

    test('no biome, or one without hazards: nothing changes', () {
      expect(hazardShareFor(null), 0);
      expect(hazardShareFor(_calm), 0);
      expect(
          roadHazardFor(_calm,
              fromNodeId: 'a', toNodeId: 'b', historyLength: 1),
          isNull);
    });

    test(
        'a chapter condition keeps scaling, and a full champion share leaves '
        'no room for hazards', () {
      var hazards = 0;
      for (final road in roads.take(60)) {
        for (var at = 0; at < 10; at++) {
          final event = roadEventFor(
            story: story,
            fromNodeId: road.from,
            toNodeId: road.to,
            historyLength: at,
            chapter: 4,
            championShare: 1,
            shrineShare: 0,
            hazardShare: roadHazardShare,
          );
          if (event == RoadEventKind.hazard) hazards++;
        }
      }
      expect(hazards, 0);
    });
  });

  group('the hazard', () {
    test('the same road holds the same hazard at the same point', () {
      final picked = <String>{};
      for (final road in roads.take(40)) {
        for (final at in [3, 17]) {
          BiomeHazard? pick() => roadHazardFor(_desert,
              fromNodeId: road.from, toNodeId: road.to, historyLength: at);
          expect(pick(), same(pick()));
          picked.add(pick()!.id);
        }
      }
      // Both of the land's hazards come up.
      expect(picked, {'sandstorm', 'heat'});
    });

    test('its scene: push on at a cost in health, or wait it out', () {
      final node = roadEventChain(RoadEventKind.hazard,
              chapter: 4, enemyPool: const [], seed: 9, hazard: _sandstorm)
          .single;
      expect(node.description, _sandstorm.text);
      expect(node.descriptionFr, _sandstorm.textFr);
      expect(node.contextNoteFor(false), contains('Sandstorm'));
      expect(node.contextNoteFor(false), contains('${hazardWoundFor(4)}'));
      expect(node.contextNoteFor(true), contains('Tempête de sable'));
      expect(node.contextNoteFor(true), contains(' ;'));
      final push = node.choices[0];
      final wait = node.choices[1];
      expect(push.text, _sandstorm.push);
      expect(push.textFr, _sandstorm.pushFr);
      expect(push.healAmount, -hazardWoundFor(4));
      expect(isHazardPush(push), isTrue);
      expect(isHazardWait(push), isFalse);
      expect(wait.text, _sandstorm.wait);
      expect(wait.healAmount, 0);
      expect(wait.goldMod, 0);
      expect(isHazardWait(wait), isTrue);
      for (final choice in node.choices) {
        expect(choice.text.length, lessThanOrEqualTo(55));
        expect(choice.triggersCombat, isFalse);
      }
      // A hazard written with no choices of its own gets the plain ones.
      final bare = roadEventChain(RoadEventKind.hazard,
              chapter: 2, enemyPool: const [], seed: 1, hazard: _heat)
          .single;
      expect(bare.choices.map((c) => c.text),
          ['Push on through it', 'Wait it out']);
      expect(bare.choices.map((c) => c.textFr),
          ['Forcer le passage', 'Attendre que cela passe']);
      // With no hazard to tell, a shrine stands there instead.
      expect(
          roadEventChain(RoadEventKind.hazard,
                  chapter: 3, enemyPool: const [], seed: 1)
              .single
              .choices
              .first
              .healAmount,
          greaterThan(0));
    });

    test('pushing on costs about 10 + 5 a chapter, and never kills', () {
      expect(hazardWoundFor(1), 15);
      expect(hazardWoundFor(2), 20);
      expect(hazardWoundFor(6), 40);
      expect(healthAfterHazard(100, 30), 70);
      expect(healthAfterHazard(25, 30), 1);
      expect(healthAfterHazard(1, 30), 1);
      expect(healthAfterHazard(0, 30), 0);
      // A companion at full health (the sentinel) loses it from its max;
      // one already down stays down.
      expect(
          companionHealthAfterHazard(
              stored: AllyState.fullHealthSentinel, maxHealth: 120, wound: 30),
          90);
      expect(
          companionHealthAfterHazard(stored: 12, maxHealth: 120, wound: 30), 1);
      expect(
          companionHealthAfterHazard(stored: 0, maxHealth: 120, wound: 30), 0);
    });

    test('a party nobody steers pushes on above half health, else waits', () {
      expect(hazardPushesOn(health: 51, maxHealth: 100), isTrue);
      expect(hazardPushesOn(health: 50, maxHealth: 100), isFalse);
      expect(hazardPushesOn(health: 10, maxHealth: 100), isFalse);
      // Waiting it out is a whole day on the road.
      expect(watchesPerDay, 4);
    });
  });

  group('champions', () {
    final enemies = _json('assets/gamedata/enemies.json');

    test('a champion on a road through a land is one that lives there', () {
      final pool = championPoolFor(enemies, 3);
      expect(pool.length, greaterThanOrEqualTo(3));
      Map<String, dynamic> tagged(List<String> ids) => {
            for (final entry in enemies.entries)
              entry.key: {
                ...(entry.value as Map<String, dynamic>),
                'biomes': ids.contains(entry.key) ? ['desert'] : <String>[],
              },
          };
      final two = pool.take(2).toList();
      expect(championPoolFor(tagged(two), 3, biome: 'desert'), two);
      // Fewer than two live there: the chapter's own pool.
      expect(championPoolFor(tagged(pool.take(1).toList()), 3, biome: 'desert'),
          pool);
      expect(championPoolFor(tagged(two), 3, biome: 'frost'), pool);
      expect(championPoolFor(tagged(two), 3), pool);
      // One that lives there but belongs to no chapter's pool stays out.
      final outsider = enemies.keys.firstWhere((id) => !pool.contains(id));
      expect(
          championPoolFor(tagged([...two, outsider]), 3, biome: 'desert'), two);
      expect(
          enemyLivesIn({
            'biomes': ['desert', 'sea']
          }, 'sea'),
          isTrue);
      expect(enemyLivesIn({'biomes': 'desert'}, 'desert'), isFalse);
      expect(enemyLivesIn(null, 'desert'), isFalse);
    });
  });
}
