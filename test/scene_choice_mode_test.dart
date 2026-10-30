// How a scene shows its choices (UX's in-place choices, v1.679,
// scene_choice_mode.dart): the map's rings, the fight stage or a panel;
// where a choice's door leads; and the hero's spoken reply.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/choice_shape.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/scene_choice_mode.dart';
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
  SceneChoiceMode mode(String id, {bool sprite = true}) =>
      sceneChoiceMode(story.nodeFor(id)!,
          story: story, geography: geography, hasSprite: (_) => sprite);

  test('the Stone Bridge: a fight facing the thug, on the stage', () {
    final bridge = story.nodeFor('260')!;
    expect(bridge.facing, 'slum_thug');
    expect(mode('260'), SceneChoiceMode.stage);
    // No standing sprite for them: a panel.
    expect(mode('260', sprite: false), SceneChoiceMode.panel);
    // Without its fight, the toll alone is a panel.
    expect(
        sceneChoiceMode(bridge,
            story: story,
            geography: geography,
            choices: [bridge.choices.first],
            hasSprite: (_) => true),
        SceneChoiceMode.panel);
  });

  test('more than four choices acted out here make a hub', () {
    final hubs = [
      for (final node in story.nodes.values)
        if (mode(node.id) == SceneChoiceMode.hub) node,
    ];
    expect(hubs, isNotEmpty);
    for (final node in hubs) {
      final here = node.choices
          .where((c) =>
              choiceShape(node, c, story: story, geography: geography).here)
          .length;
      expect(here, greaterThan(panelChoiceLimit), reason: node.id);
    }
    // Every scene has a mode, and the panel is the most common.
    final counts = <SceneChoiceMode, int>{};
    for (final node in story.nodes.values) {
      if (node.choices.isEmpty) continue;
      final m = mode(node.id, sprite: false);
      counts[m] = (counts[m] ?? 0) + 1;
    }
    expect(counts[SceneChoiceMode.panel],
        greaterThan(counts[SceneChoiceMode.hub] ?? 0));
  });

  test("a door: where the choice's aftermath takes the party, by name", () {
    final bridge = story.nodeFor('260')!;
    final pay =
        doorOf(bridge, bridge.choices[0], story: story, geography: geography);
    expect(pay.move, ChoiceMove.stay);
    expect(pay.place, isNull);
    expect(doorName(pay), '');
    final fight =
        doorOf(bridge, bridge.choices[1], story: story, geography: geography);
    expect(fight.move, ChoiceMove.walk);
    expect(fight.place, isNotNull);
    expect(doorName(fight), fight.place!.name);
    expect(doorName(fight, french: true), isNotEmpty);
  });

  test("the hero's reply: its own line, else the choice's text", () {
    final plain = StoryChoice.fromJson({
      'text': 'Refuse and fight',
      'text_fr': 'Refuser et se battre',
      'next_id': 'x'
    });
    expect(plain.replyFor(false), 'Refuse and fight');
    expect(plain.replyFor(true), 'Refuser et se battre');
    final spoken = StoryChoice.fromJson({
      'text': 'Refuse and fight',
      'reply': 'Not one coin.',
      'reply_fr': 'Pas une pièce.',
      'next_id': 'x',
    });
    expect(spoken.replyFor(false), 'Not one coin.');
    expect(spoken.replyFor(true), 'Pas une pièce.');
    expect(spoken.toJson()['reply'], 'Not one coin.');
    expect(plain.toJson().containsKey('reply'), isFalse);
  });
}
