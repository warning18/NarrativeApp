// A story choice's politics gate (v1.196) where a choice's visibility is
// decided: hidden when it fails, or shut with its locked text; a scene
// read straight through skips a hidden way on; on fixtures.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/data/scene_flow.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/politics_provider.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart'
    show isStoryChoiceLocked;

final ClanData _data = ClanData.fromTables(
  factions: {
    'vigil': {'kind': 'clan', 'name': 'The Grey Vigil'},
    'mire': {'kind': 'clan', 'name': 'The Mire Courts'},
  },
  subclans: {
    'stitchers': {'clan': 'vigil', 'name': 'The Stitchers'},
  },
);

StoryChoice _choice(String text,
        {Map<String, dynamic>? gate, String? locked, String next = '2'}) =>
    StoryChoice.fromJson({
      'text': text,
      'next_id': next,
      if (gate != null) 'politicsIf': gate,
      if (locked != null) 'lockedText': locked,
    });

PlayerSession _session({PoliticsState politics = PoliticsState.empty}) =>
    PlayerSession.fromJson(const {}).copyWith(politics: politics);

void main() {
  final world = CoastWorld(data: _data, chapter: 5);
  final house = setSubclanMark(
          PoliticsState.empty, 'stitchers', SubclanMark.friend, 'edit',
          data: _data)
      .state;
  final step1 = _choice('A night on the wall', gate: {
    'rungAtLeast': {'vigil': 1}
  });
  final step3 = _choice('Walk before us',
      gate: {
        'claim': 'any',
      },
      locked: 'Only a claimant can lead them.');

  test('a gate that fails hides a choice, or shuts it with its text', () {
    final none = _session();
    expect(choiceHiddenFor(step1, none, world), isTrue);
    expect(choiceHiddenFor(step3, none, world), isFalse);
    expect(choiceGateFor(step3, none, world), ChoiceGate.locked);
    final friend = _session(politics: house);
    expect(choiceHiddenFor(step1, friend, world), isFalse);
    expect(choiceGateFor(step1, friend, world), ChoiceGate.open);
    // The flags still hide as before.
    final done = StoryChoice.fromJson({
      'text': 'Done',
      'next_id': '2',
      'hideIfFlags': ['x'],
    });
    expect(
        choiceHiddenFor(
            done,
            PlayerSession.fromJson(const {}).copyWith(flags: const ['x']),
            world),
        isTrue);
  });

  test('the story shuts a locked one, with its world', () {
    final story = StoryData({
      '1': StoryNode.fromJson('1', {
        'description': 'The wall.',
        'choices': [step3.toJson()],
      }),
      '2': StoryNode.fromJson('2', {
        'description': 'After.',
        'choices': [
          {'text': 'On', 'next_id': '3'}
        ],
      }),
    });
    final none = _session();
    expect(isStoryChoiceLocked(step3, story, none, world: world), isTrue);
    // Without a world (a caller that reads no politics) only the old
    // locks hold.
    expect(isStoryChoiceLocked(step3, story, none), isFalse);
    final claimant =
        _session(politics: PoliticsState.empty.copyWith(claim: 'mire'));
    expect(isStoryChoiceLocked(step3, story, claimant, world: world), isFalse);
  });

  test('a scene read through skips a way on its gate hides', () {
    final node = StoryNode.fromJson('10', {
      'description': 'A road.',
      'choices': [
        {
          'text': 'The Vigil’s way',
          'next_id': '11',
          'politicsIf': {
            'rungAtLeast': {'vigil': 1}
          },
        },
        {'text': 'Walk on', 'next_id': '12'},
      ],
    });
    final none = _session();
    // Two ways by the flags alone: a stop.
    expect(passThroughChoiceOf(node, const []), isNull);
    // The gate hides the first: the second is the lone way on.
    final way = passThroughChoiceOf(node, const [],
        hidden: (c) => choiceHiddenFor(c, none, world));
    expect(way?.nextId, '12');
    final friend = _session(politics: house);
    expect(
        passThroughChoiceOf(node, const [],
            hidden: (c) => choiceHiddenFor(c, friend, world)),
        isNull);
  });
}
