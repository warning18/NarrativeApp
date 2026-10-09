// Fewer presses of "Continue" (v1.176): a scene whose only way on just
// moves the story on is read on the way to the next one, and a line an
// earlier choice earned says which choice it was (an echo).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/echoes.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/journey_rules.dart';
import 'package:narrative_data_app/data/scene_flow.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart'
    show composeNarration, composeNarrationParts;

StoryData _story() {
  final raw =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  return StoryData({
    for (final entry in raw.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  });
}

StoryNode _node(String id, List<Map<String, dynamic>> choices,
        [Map<String, dynamic> extra = const {}]) =>
    StoryNode.fromJson(
        id, {'description': 'Scene $id.', 'choices': choices, ...extra});

void main() {
  group('a plain way on', () {
    test('moves on and may leave a mark, nothing more', () {
      StoryChoice c(Map<String, dynamic> json) =>
          StoryChoice.fromJson({'text': 'Go', 'next_id': 'b', ...json});
      expect(isPlainGoOn(c({})), isTrue);
      expect(
          isPlainGoOn(c({
            'flagsToAdd': ['seen']
          })),
          isTrue);
      for (final mechanic in <Map<String, dynamic>>[
        {'goldMod': 5},
        {'healAmount': -5},
        {'alignmentMod': 1},
        {'triggerEnemyId': 'harbor_rat'},
        {'checkAbility': 'wisdom'},
        {'unlockShopId': 's'},
        {'mainQuest': true},
        {'travelPlaceId': '3100'},
        {'shipBattleId': 'raider_skiff'},
        {'next_id': 'END'},
      ]) {
        expect(isPlainGoOn(c(mechanic)), isFalse, reason: '$mechanic');
      }
    });

    test('a place, a timed scene or a real choice is a stop', () {
      final plain = _node('a', [
        {
          'text': 'On',
          'next_id': 'b',
          'flagsToAdd': ['x']
        }
      ]);
      expect(passThroughChoiceOf(plain, const [])?.nextId, 'b');
      expect(
          passThroughChoiceOf(
              _node('a', [
                {'text': 'On', 'next_id': 'b'}
              ], {
                'settlement': {'kind': 'town', 'name': 'Alster'}
              }),
              const []),
          isNull);
      expect(
          passThroughChoiceOf(
              _node('a', [
                {'text': 'On', 'next_id': 'b'}
              ], {
                'time_limit': 10
              }),
              const []),
          isNull);
      expect(
          passThroughChoiceOf(
              _node('a', [
                {'text': 'Left', 'next_id': 'b'},
                {'text': 'Right', 'next_id': 'c'},
              ]),
              const []),
          isNull);
    });

    test('a choice hidden from the party does not count as a way on', () {
      final node = _node('a', [
        {'text': 'On', 'next_id': 'b'},
        {
          'text': 'Later',
          'next_id': 'c',
          'showIfFlags': ['met']
        },
      ]);
      expect(passThroughChoiceOf(node, const [])?.nextId, 'b');
      expect(passThroughChoiceOf(node, const ['met']), isNull);
    });

    test('a way on that takes the road to another place is a stop', () {
      // The wharf's way to the berths is a step on the road: a ration, a
      // watch and what the road holds, never a page turned.
      final story = _story();
      final paid = story.nodeFor('2040_paid')!;
      expect(paid.choices.single.nextId, '2900');
      expect(isPlainGoOn(paid.choices.single), isTrue);
      expect(passThroughChoiceOf(paid, const []), isNull);
      for (final node in story.nodes.values) {
        final way = passThroughChoiceOf(node, const []);
        if (way == null) continue;
        expect(isRoadStep(node.id, way.nextId), isFalse, reason: node.id);
      }
    });

    test(
        'with the world known, a way to another district of the same city '
        'reads through; one that leaves the city is a stop (v1.209)', () {
      // Saltmouth's landward gate (2005, the Upper City landmark) and its
      // wharf (2015_kelda, the wharf landmark): two landmarks, one city.
      final gate = _node('2005', [
        {'text': 'Down to the wharf', 'next_id': '2015_kelda'}
      ], {
        'location': 'gate'
      });
      expect(isPlainGoOn(gate.choices.single), isTrue);
      // By landmark alone, a change of landmark is the road: a stop.
      expect(isRoadStep('2005', '2015_kelda'), isTrue);
      expect(passThroughChoiceOf(gate, const []), isNull);
      // With the world's places, the wharf is a district of the same
      // city: a walk through its streets, read through.
      final story = StoryData({
        gate.id: gate,
        '2015_kelda': _node('2015_kelda', const [], {'location': 'wharf'}),
      });
      final oneCity = Geography.parse(geography: {
        'old': {'level': 'continent', 'parent': '', 'name': 'Old'},
        'coast': {'level': 'country', 'parent': 'old', 'name': 'Coast'},
        'head': {
          'level': 'zone',
          'parent': 'coast',
          'biome': 'arid_coast',
          'name': 'Headland'
        },
        'saltmouth': {
          'level': 'location',
          'parent': 'head',
          'kind': 'city',
          'name': 'Saltmouth'
        },
        'gate': {'level': 'district', 'parent': 'saltmouth', 'name': 'Gate'},
        'wharf': {'level': 'district', 'parent': 'saltmouth', 'name': 'Wharf'},
      }, biomes: const {});
      expect(
          passThroughChoiceOf(gate, const [],
              travels: (a, b) => oneCity.travelsBetween(story, a, b))?.nextId,
          '2015_kelda');
      // Two locations: the road, a stop.
      final twoTowns = Geography.parse(geography: {
        'old': {'level': 'continent', 'parent': '', 'name': 'Old'},
        'coast': {'level': 'country', 'parent': 'old', 'name': 'Coast'},
        'head': {
          'level': 'zone',
          'parent': 'coast',
          'biome': 'arid_coast',
          'name': 'Headland'
        },
        'gate': {
          'level': 'location',
          'parent': 'head',
          'kind': 'town',
          'name': 'Gate'
        },
        'wharf': {
          'level': 'location',
          'parent': 'head',
          'kind': 'village',
          'name': 'Wharf'
        },
      }, biomes: const {});
      expect(
          passThroughChoiceOf(gate, const [],
              travels: (a, b) => twoTowns.travelsBetween(story, a, b)),
          isNull);
      // No world at all: back to the landmarks.
      expect(
          passThroughChoiceOf(gate, const [],
              travels: (a, b) => Geography.empty.travelsBetween(story, a, b)),
          isNull);
    });

    test('the story has scenes to read straight through, none a stop', () {
      final story = _story();
      final through = [
        for (final node in story.nodes.values)
          if (passThroughChoiceOf(node, const []) != null) node,
      ];
      expect(through.length, greaterThan(40));
      for (final node in through) {
        expect(node.settlement, isNull, reason: node.id);
        expect(isStoryEnding(node), isFalse, reason: node.id);
        expect(story.nodeFor(passThroughChoiceOf(node, const [])!.nextId),
            isNotNull,
            reason: node.id);
      }
    });
  });

  group('echoes', () {
    final story = _story();
    PlayerSession session(List<String> flags) =>
        PlayerSession.fromJson({'flags': flags});

    test(
        'a flag set on the way through a plain scene is credited to the '
        'choice the player pressed', () {
      // 5003's "Confront them" leads into 5004, read straight through,
      // whose own way on sets court_fled.
      final cause = echoCause(story, 'court_fled');
      expect(cause, isNotNull);
      expect(cause!.text, 'Confront them');
      // A flag set by a real choice keeps that choice.
      expect(echoCause(story, 'toll_refused')!.text, 'Refuse and fight');
      expect(echoCause(story, 'no_such_flag'), isNull);
    });

    test('a scene sets its earned lines apart, with their choice', () {
      final altar = story.nodeFor('5004_altar')!;
      final whole =
          composeNarration(altar, session(['court_fled']), french: false);
      final parts = composeNarrationParts(altar, session(['court_fled']), story,
          french: false);
      expect(parts.echoes, hasLength(1));
      final echo = parts.echoes.single;
      expect(echo.nodeId, '5004_altar');
      expect(echo.flag, 'court_fled');
      expect(echo.cause, 'Confront them');
      expect(whole, contains(echo.line));
      expect(parts.text, isNot(contains(echo.line)));
      // In French too.
      final fr = composeNarrationParts(altar, session(['court_fled']), story,
          french: true);
      expect(fr.echoes.single.cause, 'Les affronter');
      // Without the flag there is nothing to echo.
      expect(
          composeNarrationParts(altar, session(const []), story, french: false)
              .echoes,
          isEmpty);
    });

    test('a scene read through keeps its echoes apart, and reads whole', () {
      // 5004 (the Court's flight) is read on the way to the altar; its
      // memory of the floorboard is an echo of the sixteenth year.
      final flight = story.nodeFor('5004')!;
      expect(passThroughChoiceOf(flight, const []), isNotNull);
      final parts = composeNarrationParts(
          flight, session(['origin_board_good']), story,
          french: false);
      expect(parts.echoes.single.flag, 'origin_board_good');
      final prelude = ScenePrelude(
          nodeId: flight.id, body: parts.text, echoes: parts.echoes);
      expect(prelude.body, isNot(contains(parts.echoes.single.line)));
      expect(prelude.text, contains(parts.echoes.single.line));
      expect(prelude.text, startsWith(parts.text));
    });

    test('the journal finds a saved echo again', () {
      final key = echoKey('5004_altar', 'court_fled');
      expect(splitEchoKey(key), ('5004_altar', 'court_fled'));
      final echo = echoForKey(story, key, french: false);
      expect(echo, isNotNull);
      expect(echo!.cause, 'Confront them');
      expect(echo.line, isNotEmpty);
      expect(echoForKey(story, echoKey('5004_altar', 'nothing'), french: false),
          isNull);
    });
  });
}
