// The companions most runs never met (v1.181): Sable's marker can always
// be won back, whatever happened at the card table, and Vess is there for
// anyone who carried the Bundle out of Alster.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/models/story_node.dart';

void main() {
  final raw =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final nodes = {
    for (final entry in raw.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  };
  List<StoryChoice> shown(String nodeId, Set<String> flags) => [
        for (final c in nodes[nodeId]!.choices)
          if (c.showIfFlags.every(flags.contains) &&
              !c.hideIfFlags.any(flags.contains))
            c,
      ];
  bool winsMarker(StoryChoice c) =>
      c.flagsToAdd.contains('sable_marker_won') ||
      (nodes[c.nextId]?.choices ?? const [])
          .any((next) => next.flagsToAdd.contains('sable_marker_won'));

  group("Sable's marker", () {
    test('a lost card game can be played again while she waits', () {
      const waiting = {'hub_2015_sable', 'hub_2015_cards'};
      expect(shown('2015', waiting).where(winsMarker), isNotEmpty);
      expect(shown('2015', {...waiting, 'sable_marker_won'}).where(winsMarker),
          isEmpty);
      // Before meeting her, a lost game is simply lost: no rematch.
      expect(
          shown('2015', {'hub_2015_cards'})
              .where((c) => c.nextId == '2015_cards_won'),
          isEmpty);
    });

    test('a marker won at cards first is handed over, not hunted', () {
      final choices = shown('2015_sable', {'sable_marker_won'});
      expect(choices, hasLength(1));
      expect(choices.single.checkAbility, isNull);
      expect(shown('2015_sable', const {}).where((c) => c.checkAbility != null),
          hasLength(2));
    });

    test('the wharf only remembers her marker once she was met', () {
      final line = nodes['2015']!
          .flagCallbacks
          .singleWhere((cb) => cb.flag == 'sable_marker_won');
      expect(line.andFlags, contains('hub_2015_sable'));
    });
  });

  test('Vess waits for every Bundle bearer at the wharf', () {
    final vess =
        nodes['2015']!.choices.singleWhere((c) => c.nextId == '2015_vess');
    expect(vess.showIfFlags, ['void_banner_bearer']);
    final setters = {
      for (final node in nodes.values)
        for (final choice in node.choices)
          if (choice.flagsToAdd.contains('void_banner_bearer')) node.id,
    };
    expect(setters, isNotEmpty);
  });
}
