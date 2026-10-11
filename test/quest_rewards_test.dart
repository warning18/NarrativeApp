// Side quests pay on one scale (v1.223): gold and XP follow the quest's
// difficulty, a turn-in choice pays between a little and about twice the
// base, and the hardest quests pay in gear.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final quests =
      json.decode(File('assets/gamedata/quests.json').readAsStringSync())
          as Map<String, dynamic>;
  final items =
      json.decode(File('assets/gamedata/items.json').readAsStringSync())
          as Map<String, dynamic>;
  // The temptations (chapter 0) pay in relics, by side.
  final side = [
    for (final e in quests.entries)
      if ((e.value as Map)['category'] == 'Side' &&
          ((e.value as Map)['chapter'] as num) >= 1)
        MapEntry(e.key, e.value as Map<String, dynamic>),
  ];

  int number(Object? v) => int.parse('$v');

  test('gold and XP follow the difficulty', () {
    for (final e in side) {
      final d = number(e.value['difficulty']);
      final gold = number(e.value['rewardGold']);
      final xp = number(e.value['rewardXP']);
      expect(gold / d, inInclusiveRange(9, 18),
          reason: '${e.key}: $gold gold at difficulty $d');
      expect(xp / d, inInclusiveRange(11, 22),
          reason: '${e.key}: $xp XP at difficulty $d');
      expect(xp / gold, inInclusiveRange(0.8, 2.0),
          reason: '${e.key}: $xp XP for $gold gold');
    }
  });

  test('a turn-in choice never pays more than 2.5 times the base', () {
    for (final e in side) {
      final base = number(e.value['rewardGold']);
      for (final t in (e.value['turnInChoices'] as List? ?? const [])) {
        expect(number((t as Map)['rewardGold']), lessThanOrEqualTo(base * 2.5),
            reason: '${e.key}: ${t['choiceText']}');
      }
    }
  });

  test('the hardest side quests pay in gear', () {
    for (final e in side) {
      if (number(e.value['difficulty']) < 8) continue;
      final item = e.value['rewardItemID']?.toString() ?? '';
      expect(item, isNotEmpty, reason: e.key);
      expect(items, contains(item), reason: '${e.key} pays $item');
    }
  });
}
