// How the party came to stand where it does (v1.245): a lost fight or a
// failed roll carries it along a branch it did not pick, a jump along none;
// the author's note on the branch is what the Journey map says of it. And the
// story keeps the map's promise: every branch that sets the party down
// somewhere other than where its chosen step leads says why.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/party_trail.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/models/story_node.dart';

StoryNode _node(String id, List<StoryChoice> choices) =>
    StoryNode(id: id, description: id, choices: choices);

StoryData _story() => StoryData({
      for (final n in [
        _node('gate', [
          const StoryChoice(
            text: 'Fight Vane',
            nextId: 'street',
            triggerEnemyId: 'vane',
            loseNextId: 'cells',
            loseNote: 'You are put in prison',
            loseNoteFr: 'On vous jette en prison',
          ),
          const StoryChoice(
            text: 'Talk',
            nextId: 'yard',
            checkAbility: 'charisma',
            checkDC: 12,
            failNextId: 'street',
            failNote: 'The talk goes wrong',
          ),
          const StoryChoice(text: 'Leave', nextId: 'road'),
        ]),
        _node('street', []),
        _node('cells', []),
        _node('yard', []),
        _node('road', []),
      ])
        n.id: n,
    });

void main() {
  group('why the party is where it is', () {
    final story = _story();

    test('a way the player took is no forced move', () {
      expect(partyMoveCause(story, 'gate', 'street'), isNull);
      expect(partyMoveCause(story, 'gate', 'yard'), isNull);
      expect(partyMoveCause(story, 'gate', 'road'), isNull);
    });

    test('a lost fight and a failed roll carry the party along their branch',
        () {
      expect(partyMoveCause(story, 'gate', 'cells'), PartyMoveCause.lost);
      // The failed talk lands on a scene another way also leads to: that is
      // the way taken, and nothing is forced (a pick wins over a fail).
      expect(partyMoveCause(story, 'gate', 'street'), isNull);
    });

    test('a scene no choice leads to is a jump', () {
      expect(partyMoveCause(story, 'street', 'cells'), PartyMoveCause.carried);
      expect(partyMoveCause(story, null, 'cells'), PartyMoveCause.carried);
      expect(partyMoveCause(story, 'nowhere', 'cells'), PartyMoveCause.carried);
    });

    test('the author\'s note is told in the language read', () {
      expect(partyMoveNote(story, 'gate', 'cells', french: false),
          'You are put in prison');
      expect(partyMoveNote(story, 'gate', 'cells', french: true),
          'On vous jette en prison');
      // No French written: the English one reads.
      expect(partyMoveNote(story, 'gate', 'street', french: true), isNull);
      expect(partyMoveNote(story, 'street', 'cells', french: false), isNull);
      expect(partyMoveNote(story, null, 'cells', french: false), isNull);
    });
  });

  test('the notes survive the save file', () {
    const choice = StoryChoice(
      text: 'Fight',
      nextId: 'a',
      loseNextId: 'b',
      loseNote: 'Lost',
      loseNoteFr: 'Perdu',
      failNextId: 'c',
      failNote: 'Failed',
      failNoteFr: 'Raté',
    );
    final back = StoryChoice.fromJson(
        jsonDecode(jsonEncode(choice.toJson())) as Map<String, dynamic>);
    expect(back.loseNote, 'Lost');
    expect(back.loseNoteFr, 'Perdu');
    expect(back.failNote, 'Failed');
    expect(back.failNoteFr, 'Raté');
    expect(back.loseNoteFor(true), 'Perdu');
    expect(back.failNoteFor(false), 'Failed');
    // Nothing written: nothing in the file.
    final plain = const StoryChoice(text: 'Go', nextId: 'a').toJson();
    expect(plain.keys, isNot(contains('loseNote')));
    expect(plain.keys, isNot(contains('failNote')));
  });

  group('the real story', () {
    final raw =
        jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
            as Map<String, dynamic>;
    final nodes = {
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    };

    test('every scene stands at a place on the world chart', () {
      final lost = [
        for (final id in nodes.keys)
          if (landmarkOfScene(id) == null) id,
      ];
      expect(lost, isEmpty, reason: 'scenes with no landmark: $lost');
    });

    test('a branch that sets the party down elsewhere says why', () {
      // The party walks the chosen step to its place before the fight or the
      // roll, so only a branch ending at another place than that (another
      // district or building, another city) is a move the player never saw
      // coming. On the world's own places.
      final world = Geography.parse(
        geography: jsonDecode(
                File('assets/gamedata/geography.json').readAsStringSync())
            as Map<String, dynamic>,
        biomes:
            jsonDecode(File('assets/gamedata/biomes.json').readAsStringSync())
                as Map<String, dynamic>,
      );
      final story = StoryData(nodes);
      String? placeOf(String id) => world.placeOfNode(story.nodeFor(id))?.id;
      final silent = <String>[];
      for (final node in nodes.values) {
        for (final choice in node.choices) {
          final walkedTo = placeOf(choice.nextId);
          for (final (branch, note, noteFr) in [
            (choice.loseNextId, choice.loseNote, choice.loseNoteFr),
            (choice.failNextId, choice.failNote, choice.failNoteFr),
          ]) {
            if (branch == null || branch.isEmpty) continue;
            if (placeOf(branch) == walkedTo) continue;
            if ((note ?? '').isEmpty || (noteFr ?? '').isEmpty) {
              silent.add('${node.id} > $branch');
            }
          }
        }
      }
      expect(silent, isEmpty,
          reason: 'forced moves with no note in both languages: $silent');
    });
  });
}
