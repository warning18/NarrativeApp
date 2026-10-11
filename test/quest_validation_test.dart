// The quest chapter validator checks main-quest chains only, and the real
// quest data passes it (side quests are open and unordered).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/gamedata/quest_validation.dart';

Map<String, dynamic> _quest(String category, int chapter, [String next = '']) =>
    {'category': category, 'chapter': chapter, 'nextQuestID': next};

void main() {
  test('the shipped quests have one start and one end per main chain', () {
    final quests =
        json.decode(File('assets/gamedata/quests.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(validateQuestChapters(quests), isEmpty);
  });

  test('side quests are not part of the chain', () {
    final issues = validateQuestChapters({
      'a': _quest('Main', 2, 'b'),
      'b': _quest('Main', 2),
      's1': _quest('Side', 2),
      's2': _quest('Side', 2),
    });
    expect(issues, isEmpty);
  });

  test('a chain that runs on into the next chapter ends there', () {
    final issues = validateQuestChapters({
      'a': _quest('Main', 4, 'b'),
      'b': _quest('Main', 5),
    });
    expect(issues, isEmpty);
  });

  test('two unlinked main quests in a chapter are reported', () {
    final issues = validateQuestChapters({
      'a': _quest('Main', 3),
      'b': _quest('Main', 3),
    });
    expect(issues, hasLength(2));
    expect(issues.first, contains('2 start quests'));
  });
}
