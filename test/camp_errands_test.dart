// Camp errands (companion loyalty errands): a `campErrand` node is offered
// at every chapter camp after the camp's own choices, under its own flags,
// never counted in a camp's choices; its `returnToCamp` choice goes to the
// camp of the chapter the party is in, else its own next_id.
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/camp_errands.dart';
import 'package:narrative_data_app/data/chapter_loop.dart';
import 'package:narrative_data_app/data/scene_flow.dart';
import 'package:narrative_data_app/data/story_graph_integrity.dart';
import 'package:narrative_data_app/models/story_node.dart';

const _back =
    StoryChoice(text: 'Back to camp', nextId: 'camp3', returnToCamp: true);

Map<String, StoryNode> _nodes() {
  StoryNode camp(String id, int chapter, String next) => StoryNode(
        id: id,
        description: 'The camp.',
        settlement: Settlement(kind: 'camp', name: id, chapter: chapter),
        choices: [StoryChoice(text: 'On', nextId: next)],
      );
  return {
    '0': const StoryNode(
        id: '0',
        description: 'start',
        choices: [StoryChoice(text: 'Go', nextId: 'camp3')]),
    'camp3': camp('camp3', 3, 'camp4'),
    'camp4': camp('camp4', 4, 'end'),
    'end': const StoryNode(
        id: 'end',
        description: 'the end',
        choices: [StoryChoice(text: 'End', nextId: 'EXIT')]),
    'errand_mira': const StoryNode(
      id: 'errand_mira',
      description: 'Mira asks a favour.\nShe says it plainly.',
      descriptionFr: 'Mira demande un service.\nElle le dit sans détour.',
      campErrand: true,
      showIfFlags: ['mira_joined'],
      hideIfFlags: ['mira_errand_done'],
      choices: [
        StoryChoice(text: 'Help her', nextId: 'errand_mira_end'),
      ],
    ),
    'errand_mira_end': const StoryNode(
      id: 'errand_mira_end',
      description: 'It is done.',
      choices: [_back],
    ),
    'errand_tom': const StoryNode(
      id: 'errand_tom',
      description: 'Tom has a thing.',
      campErrand: true,
      campErrandText: "Tom's errand",
      campErrandTextFr: 'La course de Tom',
      choices: [
        StoryChoice(text: 'Home', nextId: '', returnToCamp: true),
      ],
    ),
  };
}

const _loops = [
  ChapterLoop(
      id: 'c3',
      chapter: 3,
      label: '',
      title: '',
      campNodeId: 'camp3',
      activityGoal: 0),
  ChapterLoop(
      id: 'c4',
      chapter: 4,
      label: '',
      title: '',
      campNodeId: 'camp4',
      activityGoal: 0),
];

void main() {
  final nodes = _nodes();

  test('the fields round-trip through JSON and stay out of it when unset', () {
    final errand = nodes['errand_mira']!;
    final json = errand.toJson();
    expect(json['campErrand'], isTrue);
    expect(json['showIfFlags'], ['mira_joined']);
    expect(json['hideIfFlags'], ['mira_errand_done']);
    final back = StoryNode.fromJson(errand.id, json);
    expect(back.campErrand, isTrue);
    expect(back.showIfFlags, ['mira_joined']);
    expect(back.hideIfFlags, ['mira_errand_done']);
    final tom = StoryNode.fromJson('errand_tom', nodes['errand_tom']!.toJson());
    expect(tom.campErrandText, "Tom's errand");
    expect(tom.campErrandTextFr, 'La course de Tom');
    expect(StoryChoice.fromJson(_back.toJson()).returnToCamp, isTrue);
    final plain = nodes['end']!.toJson();
    for (final key in [
      'campErrand',
      'showIfFlags',
      'hideIfFlags',
      'campErrandText',
      'campErrandText_fr'
    ]) {
      expect(plain.containsKey(key), isFalse, reason: key);
    }
    expect(
        const StoryChoice(text: 'Go', nextId: '1')
            .toJson()
            .containsKey('returnToCamp'),
        isFalse);
  });

  test('an errand is listed only while its flags let it show', () {
    List<String> ids(Set<String> flags) =>
        [for (final c in campErrandsFor(nodes.values, flags)) c.nextId];
    expect(ids({}), ['errand_tom']);
    expect(ids({'mira_joined'}), ['errand_mira', 'errand_tom']);
    expect(ids({'mira_joined', 'mira_errand_done'}), ['errand_tom']);
    // The same visibility as any choice's.
    final mira = campErrandChoice(nodes['errand_mira']!);
    expect(mira.isHiddenFor(const []), isTrue);
    expect(mira.isHiddenFor(const ['mira_joined']), isFalse);
  });

  test('the label: campErrandText, else the scene\'s first line', () {
    final tom = campErrandChoice(nodes['errand_tom']!);
    expect(tom.textFor(false), "Tom's errand");
    expect(tom.textFor(true), 'La course de Tom');
    final mira = campErrandChoice(nodes['errand_mira']!);
    expect(mira.textFor(false), 'Mira asks a favour.');
    expect(mira.textFor(true), 'Mira demande un service.');
  });

  test('errands sit in no camp\'s choices, so no hub limit counts them', () {
    for (final node in nodes.values) {
      for (final choice in node.choices) {
        expect(nodes[choice.nextId]?.campErrand ?? false, isFalse,
            reason: '${node.id} lists an errand');
      }
    }
    expect(campErrandChoices(nodes.values), hasLength(2));
    expect(nodes['camp3']!.choices, hasLength(1));
  });

  test('returnToCamp goes to the camp of the chapter the party is in', () {
    String target(StoryChoice choice, List<String> history) =>
        storyChoiceTarget(choice,
            campNodeId: currentCampNodeId(
                currentNodeId: 'errand_mira_end',
                history: history,
                loops: _loops));
    // Left from the chapter 4 camp: back there, not to the editor's camp3.
    expect(target(_back, ['0', 'camp3', 'camp4', 'errand_mira']), 'camp4');
    expect(target(_back, ['0', 'camp3', 'errand_mira']), 'camp3');
    // A save that sits inside the errand resolves from its history alone.
    expect(target(_back, ['camp4', 'errand_mira']), 'camp4');
  });

  test('with no camp current, returnToCamp falls back to its next_id', () {
    expect(storyChoiceTarget(_back, campNodeId: null), 'camp3');
    expect(storyChoiceTarget(_back, campNodeId: ''), 'camp3');
    // A plain choice keeps its next_id whatever the camp.
    const plain = StoryChoice(text: 'Go', nextId: 'end');
    expect(storyChoiceTarget(plain, campNodeId: 'camp4'), 'end');
  });

  test('a way back to camp is a stop, never read straight through', () {
    expect(isPlainGoOn(_back), isFalse);
    expect(isPlainGoOn(const StoryChoice(text: 'On', nextId: 'camp3')), isTrue);
  });

  test('the graph check reaches errands from camps, and camps from home', () {
    final report = checkStoryGraphIntegrity(nodes, startNodeId: '0');
    expect(report.unreachableNodeIds, isEmpty);
    // Tom's way home has no next_id: still a way on.
    expect(report.deadEndNodeIds, isEmpty);
    expect(report.brokenReferences, isEmpty);
    expect(report.isClean, isTrue);
  });

  test('without camps, an errand is an orphan the graph check reports', () {
    final noCamps = {
      for (final e in nodes.entries)
        if (e.value.settlement == null) e.key: e.value,
    };
    noCamps['0'] = const StoryNode(
        id: '0',
        description: 'start',
        choices: [StoryChoice(text: 'Go', nextId: 'end')]);
    final report = checkStoryGraphIntegrity(noCamps, startNodeId: '0');
    expect(report.unreachableNodeIds, contains('errand_mira'));
  });
}
