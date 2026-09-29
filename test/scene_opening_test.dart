// What opens a scene before its own text (v1.168): a check's outcome in
// words when the check has no scene of its own, and everything the scene
// opens with read aloud first.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/ability_check.dart';
import 'package:narrative_data_app/data/check_outcomes.dart';
import 'package:narrative_data_app/data/narration_clips.dart';
import 'package:narrative_data_app/models/story_node.dart';

import 'player_session_provider_test.dart' show baseSession;

void main() {
  test('every ability has words for passing and failing, in both languages',
      () {
    for (final ability in abilityScoreKeys) {
      for (final success in [true, false]) {
        for (final french in [false, true]) {
          expect(
              checkOutcomeLineFor(ability,
                  success: success, french: french, seed: 3),
              isNotEmpty,
              reason: '$ability $success $french');
        }
      }
    }
    for (final lines in checkOutcomeLinesForTest) {
      expect(lines.fr.length, lines.en.length, reason: lines.ability);
    }
    expect(
        checkOutcomeLineFor('juggling', success: true, french: false, seed: 0),
        isNull);
  });

  test('the road always tells its checks; the story only a bare failure', () {
    bool tells(
            {required bool success,
            bool onTheRoad = false,
            bool hasFailScene = false,
            bool isSneak = false}) =>
        checkOutcomeNeedsTelling(
            success: success,
            onTheRoad: onTheRoad,
            hasFailScene: hasFailScene,
            isSneak: isSneak);
    expect(tells(success: true, onTheRoad: true), isTrue);
    expect(tells(success: false, onTheRoad: true), isTrue);
    expect(tells(success: true, onTheRoad: true, isSneak: true), isTrue);
    expect(tells(success: false, onTheRoad: true, isSneak: true), isFalse,
        reason: 'the fight it starts has its own aftermath');
    expect(tells(success: true), isFalse, reason: 'the next scene tells it');
    expect(tells(success: false, hasFailScene: true), isFalse);
    expect(tells(success: false), isTrue);
  });

  test('every story check has a scene for each outcome', () {
    final raw =
        jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final entry in raw.entries) {
      for (final choice in (entry.value as Map)['choices'] as List) {
        final c = choice as Map<String, dynamic>;
        if (c['checkAbility'] == null) continue;
        expect((c['failNextId'] as String?) ?? '', isNotEmpty,
            reason: '${entry.key}: ${c['text']}');
      }
    }
  });

  test('read aloud, the scene opens with what opens it on screen', () {
    final node = StoryNode.fromJson('x', const {
      'description': 'The scene itself.',
      'description_fr': 'La scène elle-même.',
      'choices': [],
    });
    final paragraphs = readAloudParagraphs(node, baseSession(),
        french: false,
        opening: const ['The dust settled.', 'Kelda: Good call.']);
    expect(paragraphs,
        ['The dust settled.', 'Kelda: Good call.', 'The scene itself.']);
    expect(readAloudParagraphs(node, baseSession(), french: false),
        ['The scene itself.']);
  });
}
