// The story node editor (v1.166): a node opened and saved with no edits
// keeps every field of every choice, the ones with no control in the
// editor included (hunts, showIfFlags, main-quest and travel markers, the
// sneak round a fight, approval reactions).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/story_node_editor_screen.dart';

void main() {
  test('every choice in the story survives the editor untouched', () {
    final dag =
        jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
            as Map<String, dynamic>;
    var checked = 0;
    for (final entry in dag.entries) {
      final node =
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>);
      for (final choice in node.choices) {
        final saved = debugEditorRoundTrip(choice);
        expect(saved.toJson(), choice.toJson(),
            reason: '${entry.key}: "${choice.text}"');
        checked++;
      }
    }
    expect(checked, greaterThan(300));
  });

  test('fields the editor has no control for come back as they were', () {
    final choice = StoryChoice.fromJson(const {
      'text': 'Slip past',
      'nextId': 'x',
      'huntName': 'the One-Eyed',
      'huntAffixes': ['venomous'],
      'chestFloor': 'gold',
      'isHunterAmbush': true,
      'showIfFlags': ['seen'],
      'mainQuest': true,
      'travelPlaceId': 'p1',
      'avoidFightOnSuccess': true,
      'forcedCondition': 'ambush',
      'approvalMods': {'*': -4},
    });
    expect(debugEditorRoundTrip(choice).toJson(), choice.toJson());
  });
}
