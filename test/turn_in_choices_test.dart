// Quest turn-in choices (v1.162): reading them, what each pays, and the
// data behind the six quests that ask.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/turn_in_choices.dart';

Map<String, dynamic> _load(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find $name');
}

void main() {
  final quests = _load('quests.json');
  final companions = _load('companions.json');

  test('a choice pays its own gold and alignment, or the quest\'s', () {
    const quest = {
      'rewardGold': 50,
      'alignmentChange': 5,
      'turnInChoices': [
        {'choiceText': 'Sell it', 'rewardGold': 150, 'alignmentChange': -10},
        {'choiceText': 'Keep it'},
      ],
    };
    final choices = turnInChoicesOf(quest);
    expect(choices.map((c) => c.text), ['Sell it', 'Keep it']);
    expect(choices[0].goldFor(50), 150);
    expect(choices[0].alignmentFor(5), -10);
    expect(choices[0].profitOver(50), 100);
    expect(choices[1].goldFor(50), 50);
    expect(choices[1].alignmentFor(5), 5);
    expect(choices[1].profitOver(50), 0);
    expect(turnInChoicesOf(const {'rewardGold': 10}), isEmpty);
    expect(turnInChoicesOf(null), isEmpty);
  });

  test('approval reactions and flags are read', () {
    final choice = TurnInChoice.fromJson(const {
      'choiceText': 'Grant him absolution',
      'flag': 'penitent_absolved',
      'approvalMods': {'maren': 2, '*': -1},
    });
    expect(choice.flag, 'penitent_absolved');
    expect(choice.approvalMods, {'maren': 2, '*': -1});
  });

  test('the quests that ask are written in both languages', () {
    final asking = [
      for (final entry in quests.entries)
        if (turnInChoicesOf(entry.value as Map<String, dynamic>).isNotEmpty)
          entry.key,
    ];
    expect(asking, hasLength(6));
    final flags = <String>{};
    for (final id in asking) {
      final raw = (quests[id] as Map)['turnInChoices'] as List;
      expect(raw.length, inInclusiveRange(2, 3), reason: id);
      for (final choice in raw.cast<Map<String, dynamic>>()) {
        for (final field in ['choiceText', 'resultText']) {
          expect(choice[field]?.toString() ?? '', isNotEmpty, reason: id);
          expect(choice['${field}_fr']?.toString() ?? '', isNotEmpty,
              reason: '$id $field');
        }
        final flag = choice['flag']?.toString() ?? '';
        if (flag.isNotEmpty) {
          expect(flags.add(flag), isTrue, reason: 'flag $flag used twice');
        }
        for (final who in ((choice['approvalMods'] as Map?) ?? {}).keys) {
          expect(who == '*' || companions.containsKey(who), isTrue,
              reason: '$id names $who');
        }
      }
      // A choice is a real choice: they don't all pay the same.
      final golds = {for (final c in raw) (c as Map)['rewardGold']};
      final alignments = {for (final c in raw) (c as Map)['alignmentChange']};
      expect(golds.length > 1 || alignments.length > 1, isTrue, reason: id);
    }
  });
}
