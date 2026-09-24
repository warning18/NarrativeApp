// Towns and camps in the story: where they are, what counts as arriving,
// and which hub choices stay in the place.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/settlements.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

StoryData _loadStory() {
  for (final path in [
    'assets/Cleaned_Narrative_DAG.json',
    '../assets/Cleaned_Narrative_DAG.json'
  ]) {
    final file = File(path);
    if (file.existsSync()) {
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return StoryData({
        for (final entry in decoded.entries)
          entry.key: StoryNode.fromJson(
              entry.key, entry.value as Map<String, dynamic>),
      });
    }
  }
  throw StateError('Cannot find the story file');
}

Map<String, dynamic> _loadGamedata(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find $name');
}

void main() {
  final story = _loadStory();
  final ports = _loadGamedata('ports.json');

  test('the wharf is a town with its port, and the camp is a camp', () {
    final wharf = story.nodeFor('2015')!.settlement!;
    expect(wharf.isCamp, isFalse);
    expect(ports, contains(wharf.portId));
    expect(story.nodeFor('3001_camp')!.settlement!.isCamp, isTrue);
    expect(story.nodeFor('3005')!.settlement, isNotNull);
  });

  test('every settlement names a real port, if any', () {
    for (final node in story.nodes.values) {
      final portId = node.settlement?.portId;
      if (portId != null) expect(ports, contains(portId), reason: node.id);
    }
  });

  test('a town scene belongs to its town; the road out does not', () {
    expect(settlementNodeAt('2015', story)?.id, '2015');
    expect(settlementNodeAt('2015_kelda', story)?.id, '2015');
    expect(settlementNodeAt('2030', story), isNull);
    expect(settlementNodeAt('3001_camp', story)?.id, '3001_camp');
  });

  test('arriving is coming from elsewhere, not back from a town scene', () {
    expect(isSettlementArrival('2015', '2010'), isTrue);
    expect(isSettlementArrival('2015', '2015_bazaar'), isFalse);
    expect(isSettlementArrival('2015', '2015'), isFalse);
    expect(isSettlementArrival('2015', null), isFalse,
        reason: 'opening the game in town is not an arrival');
  });

  test('the wharf keeps its activities in town and its way onward last', () {
    final wharf = story.nodeFor('2015')!;
    final local =
        wharf.choices.where((c) => isLocalChoice(c, wharf.id)).toList();
    final onward =
        wharf.choices.where((c) => !isLocalChoice(c, wharf.id)).toList();
    expect(local.map((c) => c.nextId),
        containsAll(['2015_bazaar', '2015_apothecary', '2015_ternrow']));
    expect(onward.map((c) => c.nextId), containsAll(['2030', '2040', '2011']));
    expect(onward.every((c) => !c.nextId.startsWith('2015')), isTrue);
  });

  test('a settlement survives a save of the story file', () {
    final wharf = story.nodeFor('2015')!;
    final again = StoryNode.fromJson('2015', wharf.toJson());
    expect(again.settlement?.portId, wharf.settlement?.portId);
    expect(again.settlement?.nameFor(true), 'Le Quai des Contrebandiers');
  });
}
