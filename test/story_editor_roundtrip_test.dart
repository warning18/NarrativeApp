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

  test('a choice\'s politics and a scene\'s on entry come back as they were',
      () {
    const politics = {
      'standing': {'vigil': 5, 'dominion': -5},
      'marks': {'inquisition': 'foe'},
      'relations': [
        {'a': 'mire', 'b': 'penitents', 'steps': 1},
      ],
      'offerFrom': 'penitents',
      'intrigue': {'id': 'hooded_lantern', 'outcome': 1},
      'remembrance': 3,
      'event': 'lantern_bearer_dies',
      'hidden': true,
      'aLaterKey': [1, 2],
    };
    final choice = StoryChoice.fromJson(
        const {'text': 'Raise it', 'next_id': 'x', 'politics': politics});
    final saved = debugEditorRoundTrip(choice);
    expect(saved.toJson(), choice.toJson());
    expect(saved.toJson()['politics'], politics);

    final node = StoryNode.fromJson('n', const {
      'description': 'd',
      'noDetour': true,
      'politicsOnEnter': {'remembrance': 2},
      'choices': [],
    });
    final text = politicsEditorText(node.politicsOnEnter);
    expect(politicsFromEditorText(text, null)!.toJson(), {'remembrance': 2});
    // Not JSON: kept as it was; emptied: none.
    expect(politicsFromEditorText('{oops', node.politicsOnEnter),
        same(node.politicsOnEnter));
    expect(politicsFromEditorText('  ', node.politicsOnEnter), isNull);
    expect(politicsEditorText(null), isEmpty);
  });

  test('a choice\'s politics gate and last-battle mark come back (v1.196)', () {
    const gate = {
      'claim': 'any',
      'rungAtLeast': {'vigil': 2},
      'flags': ['clan_vigil_step_2'],
    };
    final choice = StoryChoice.fromJson(const {
      'text': 'Lead the Host',
      'next_id': 'x',
      'triggerEnemyId': 'tear_herald',
      'politicsIf': gate,
      'hostFight': true,
    });
    final saved = debugEditorRoundTrip(choice);
    expect(saved.toJson(), choice.toJson());
    expect(saved.politicsIf, gate);
    expect(saved.hostFight, isTrue);
    // The gate's JSON field: kept when it is no object, none when empty.
    final text = politicsIfEditorText(choice.politicsIf);
    expect(politicsIfFromEditorText(text, const {}), gate);
    expect(politicsIfFromEditorText('{oops', choice.politicsIf),
        same(choice.politicsIf));
    expect(politicsIfFromEditorText(' ', choice.politicsIf), isEmpty);
    expect(politicsIfEditorText(const {}), isEmpty);
  });
}
