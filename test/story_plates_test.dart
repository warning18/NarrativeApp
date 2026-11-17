// The story plates (lib/data/story_plates.dart): a choice's clan and weight,
// read from its effects, and a quest's clan. Display only.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/story_plates.dart';
import 'package:narrative_data_app/models/story_node.dart';

void main() {
  final dag =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final clans =
      (jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
              as Map<String, dynamic>)
          .keys
          .toSet();
  final subclanClans = {
    for (final MapEntry(:key, :value)
        in (jsonDecode(File('assets/gamedata/subclans.json').readAsStringSync())
                as Map<String, dynamic>)
            .entries)
      key: (value as Map)['clan']?.toString() ?? '',
  };
  final choices = [
    for (final node in dag.values)
      if (node is Map && node['choices'] is List)
        for (final raw in node['choices'] as List)
          StoryChoice.fromJson(Map<String, dynamic>.from(raw as Map)),
  ];

  test('every clan a choice shows is a clan; hidden choices show none', () {
    var withClan = 0;
    for (final choice in choices) {
      final clan =
          choiceClanOf(choice, subclanClans: subclanClans, clans: clans);
      if (clan.isEmpty) continue;
      withClan++;
      expect(clans, contains(clan), reason: choice.text);
      expect(choice.politics?.hidden ?? false, isFalse, reason: choice.text);
    }
    // About a quarter of the story's choices touch a clan (v1.978: 1156
    // choices).
    expect(withClan, inInclusiveRange(200, 400));
  });

  test('the weights spread across the story', () {
    final counts = {for (final w in ChoiceWeight.values) w: 0};
    for (final choice in choices) {
      counts[choiceWeightOf(choice)] = counts[choiceWeightOf(choice)]! + 1;
    }
    expect(
        counts[ChoiceWeight.plain], greaterThan(counts[ChoiceWeight.major]!));
    expect(counts[ChoiceWeight.weighty], greaterThan(0));
    expect(counts[ChoiceWeight.major], greaterThan(0));
  });

  test('the rules of the clan and the weight', () {
    StoryChoice choice(Map<String, dynamic> extra) =>
        StoryChoice.fromJson({'text': 't', 'next_id': 'n', ...extra});
    expect(choiceWeightOf(choice({})), ChoiceWeight.plain);
    expect(
        choiceWeightOf(choice({
          'flagsToAdd': ['x']
        })),
        ChoiceWeight.plain);
    expect(choiceWeightOf(choice({'alignmentMod': -1})), ChoiceWeight.weighty);
    expect(
        choiceWeightOf(choice({
          'approvalMods': {'vica': 2}
        })),
        ChoiceWeight.weighty);
    expect(
        choiceWeightOf(choice({
          'approvalMods': {'vica': -5}
        })),
        ChoiceWeight.major);
    expect(choiceWeightOf(choice({'grantsBannerPieceId': 'heirloom_shroud'})),
        ChoiceWeight.major);
    final standing = choice({
      'politics': {
        'standing': {'crows': 1, 'vigil': -2},
      },
    });
    expect(choiceWeightOf(standing), ChoiceWeight.weighty);
    expect(choiceClanOf(standing), 'vigil');
    final claim = choice({
      'politics': {
        'claim': 'mire',
        'standing': {'crows': 3}
      },
    });
    expect(choiceClanOf(claim), 'mire');
    expect(choiceWeightOf(claim), ChoiceWeight.major);
    final hidden = choice({
      'politics': {
        'standing': {'crows': 3},
        'hidden': true,
      },
    });
    expect(choiceClanOf(hidden), '');
    expect(choiceWeightOf(hidden), ChoiceWeight.plain);
    expect(choiceClanOf(choice({'about': 'crows'}), clans: clans), 'crows');
    expect(choiceClanOf(choice({'about': 'renn'}), clans: clans), '');
  });

  test('a quest wears its clan, else its faction, else none', () {
    expect(questClanOf({'clan': 'mire', 'faction': 'crows'}), 'mire');
    expect(questClanOf({'faction': 'crows'}), 'crows');
    expect(questClanOf({}), '');
    final quests =
        jsonDecode(File('assets/gamedata/quests.json').readAsStringSync())
            as Map;
    for (final quest in quests.values.cast<Map<String, dynamic>>()) {
      final clan = questClanOf(quest);
      if (clan.isNotEmpty) expect(clans, contains(clan), reason: '$quest');
    }
  });
}
