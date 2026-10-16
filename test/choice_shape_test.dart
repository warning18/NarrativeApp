// What a story choice does on the map (choice_shape.dart): whether it moves
// the party and what kind of action it is, derived from the story and the
// geography -- the Stone Bridge's toll and the family house's stand are
// acted out where the party is, whatever their aftermath; and the story's shares, which the journey map's
// display rests on.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/choice_shape.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final geography =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  ChoiceShape shape(String nodeId, String startsWith) {
    final node = story.nodeFor(nodeId)!;
    final choice =
        node.choices.firstWhere((c) => c.text.startsWith(startsWith));
    return choiceShape(node, choice, story: story, geography: geography);
  }

  test('the Stone Bridge toll: pay or fight, where the party stands', () {
    expect(shape('260', 'Pay the toll').move, ChoiceMove.stay);
    expect(shape('260', 'Pay the toll').action, ChoiceAction.pay);
    expect(shape('260', 'Pay the toll').here, isTrue);
    // The fight is fought here; its aftermath walks on to the lower town.
    expect(shape('260', 'Refuse and fight').action, ChoiceAction.fight);
    expect(shape('260', 'Refuse and fight').move, ChoiceMove.walk);
    expect(shape('260', 'Refuse and fight').here, isTrue);
  });

  test('the family house: charge him or kneel, where the party stands', () {
    expect(shape('400', 'Charge him').action, ChoiceAction.fight);
    expect(shape('400', 'Charge him').here, isTrue);
    // Kneeling is a decision here, though it ends in the Black Hold.
    expect(shape('400', 'Kneel').action, ChoiceAction.decide);
    expect(shape('400', 'Kneel').here, isTrue);
  });

  test('every choice has a shape; most stay, few travel', () {
    final moves = <ChoiceMove, int>{};
    final actions = <ChoiceAction, int>{};
    var total = 0, here = 0;
    for (final node in story.nodes.values) {
      for (final choice in node.choices) {
        final s = choiceShape(node, choice, story: story, geography: geography);
        moves[s.move] = (moves[s.move] ?? 0) + 1;
        actions[s.action] = (actions[s.action] ?? 0) + 1;
        total++;
        // A choice that stays never reads as going somewhere, and only a
        // way somewhere is not acted out here.
        if (s.move == ChoiceMove.stay) {
          expect(s.action, isNot(ChoiceAction.go), reason: node.id);
        }
        expect(s.here, s.action != ChoiceAction.go, reason: node.id);
        if (s.here) here++;
      }
    }
    final stay = moves[ChoiceMove.stay] ?? 0;
    final travel = moves[ChoiceMove.travel] ?? 0;
    expect(stay / total, greaterThan(0.5));
    expect(travel / total, lessThan(0.15));
    expect(actions[ChoiceAction.fight], greaterThan(100));
    // ignore: avoid_print
    print('choices $total: ${[
      for (final m in ChoiceMove.values) '${m.name} ${moves[m] ?? 0}'
    ].join(', ')}; ${[
      for (final a in ChoiceAction.values) '${a.name} ${actions[a] ?? 0}'
    ].join(', ')}; acted out here $here');
  });

  ChoiceTags tags(String nodeId, String startsWith) {
    final node = story.nodeFor(nodeId)!;
    final choice =
        node.choices.firstWhere((c) => c.text.startsWith(startsWith));
    return choiceTags(node, choice, story: story, geography: geography);
  }

  test('a card\'s tags: the toll\'s price, and where a fight\'s aftermath goes',
      () {
    final toll = tags('260', 'Pay the toll');
    expect(toll.cost, 30);
    expect(toll.group, ChoiceGroup.checksPay);
    expect(toll.destination, isNull);
    final fight = tags('260', 'Refuse and fight');
    expect(fight.cost, 0);
    expect(fight.group, ChoiceGroup.fight);
    expect(fight.destination, shape('260', 'Refuse and fight').to);
  });

  test('Smugglers\' Wharf\'s rings: fight, talk and decide, checks and pay',
      () {
    final hub = story.nodeFor('2015')!;
    final groups = <ChoiceGroup, int>{};
    for (final c in hub.choices) {
      final g = choiceTags(hub, c, story: story, geography: geography).group;
      groups[g] = (groups[g] ?? 0) + 1;
    }
    expect(groups[ChoiceGroup.fight], 4);
    expect(groups[ChoiceGroup.talkDecide], 7);
    expect(groups[ChoiceGroup.checksPay], 3);
    expect(groups[ChoiceGroup.go], 17);
  });
}
