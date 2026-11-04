// The story node editor (v1.166): a node opened and saved with no edits
// keeps every field of every choice, the ones with no control in the
// editor included (hunts, showIfFlags, main-quest and travel markers, the
// sneak round a fight, approval reactions). A scene saved unedited keeps
// every field too (v1.820): before, its camp errand, the errand's kind, its
// show/hide flags and its camp line in both languages were lost on every
// save, turning the companions' loyalty errands into plain scenes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/story_node_editor_screen.dart';

/// The story as the app reads it, and what a save writes.
class _CapturingRepository extends StoryRepository {
  _CapturingRepository(this.story);

  final StoryData story;
  Map<String, dynamic>? saved;

  @override
  Future<StoryData> load() async => story;

  @override
  Future<void> saveNodes(Map<String, dynamic> rawNodes) async =>
      saved = rawNodes;
}

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
      'forcedAnomaly': 'sandstorm',
      'forcedStage': 'dunes',
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

  // --- Scenes (v1.820) ---

  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });

  // Scenes that together hold every field the file uses: the first with the
  // most fields not yet held, until none is left (19 of 479 today).
  Set<String> fieldsOf(Map<String, dynamic> n) => {
        ...n.keys,
        for (final c in (n['choices'] as List?) ?? const [])
          if (c is Map) ...c.keys.map((k) => 'choice:$k'),
      };
  final cover = <String>[];
  final left = {
    for (final n in raw.values) ...fieldsOf(n as Map<String, dynamic>)
  };
  while (left.isNotEmpty) {
    String? best;
    var gain = 0;
    for (final e in raw.entries) {
      final g =
          fieldsOf(e.value as Map<String, dynamic>).intersection(left).length;
      if (g > gain) (best, gain) = (e.key, g);
    }
    cover.add(best!);
    left.removeAll(fieldsOf(raw[best] as Map<String, dynamic>));
  }

  test('every scene keeps every field it was read with when written back', () {
    for (final e in raw.entries) {
      final written = story.nodeFor(e.key)!.toJson();
      // A key left out only for holding its default (0, false, empty)
      // loses nothing.
      bool isDefault(Object? v) =>
          v == null ||
          v == 0 ||
          v == false ||
          v == '' ||
          (v is List && v.isEmpty) ||
          (v is Map && v.isEmpty);
      final lost = [
        for (final MapEntry(:key, :value)
            in (e.value as Map<String, dynamic>).entries)
          if (key != 'possibleChoices' &&
              !written.containsKey(key) &&
              !isDefault(value))
            key,
      ];
      expect(lost, isEmpty, reason: e.key);
      expect(jsonEncode(StoryNode.fromJson(e.key, written).toJson()),
          jsonEncode(written),
          reason: e.key);
    }
  });

  testWidgets('a scene saved unedited in the editor is kept as it was',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _CapturingRepository(story);
    final changed = <String>[];
    expect(cover, contains('loyal_kelda'));
    for (final node in [for (final id in cover) story.nodeFor(id)!]) {
      repo.saved = null;
      await tester.pumpWidget(ProviderScope(
        overrides: [storyRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => StoryNodeEditorScreen(node: node))),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      final written = repo.saved?[node.id];
      expect(written, isNotNull, reason: '${node.id}: nothing saved');
      if (jsonEncode(written) != jsonEncode(node.toJson())) {
        changed.add(node.id);
      }
    }
    expect(changed, isEmpty,
        reason: 'scenes the editor changes when saved as they open');
  });

  test('the six fields the editor used to drop are on the loyalty errands', () {
    // Guards the case above: the errands still carry what it checks.
    final errand = story.nodeFor('loyal_kelda')!;
    expect(errand.campErrand, isTrue);
    expect(errand.showIfFlags, isNotEmpty);
    expect(errand.hideIfFlags, isNotEmpty);
    expect(errand.campErrandText, isNotEmpty);
    expect(errand.campErrandTextFr, isNotEmpty);
  });
}
