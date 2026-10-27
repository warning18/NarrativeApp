// Narrative's scene tags for chapters 1 to 3 (v1.584, presentation-contract.md):
// only the scenes the default rule gets wrong carry a `scene.view`. The three
// approach scenes the user named (the toll at 260, the quay drill at 890_trainer
// and the Wharf's approach at 2010) open as the street; the Black Hold's cells
// scene (800), the chapter 3 ceremony (4999_standard, 4999_drawn) and the
// fall (3010_rope_fail) open as the page; the rest of the first three
// chapters follow the rule.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/scene_presentation.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final geography =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final cityPlans = cityPlanRecordsFrom(_table('city_plans'));
  final present = ScenePresentation.of(
    story: story,
    geography: geography,
    stops: StoryStops.of(
      story: story,
      geography: geography,
      cityPlans: cityPlans,
      ports: _table('ports'),
    ),
  );

  test('the approach scenes open as the street, with their building', () {
    for (final (id, building) in [
      ('260', 'alster_b032'),
      ('890_trainer', 'alster_b175'),
      ('2010', 'saltmouth_b163'),
    ]) {
      expect(present.viewOf(id), SceneView.street, reason: id);
      final scene = story.nodeFor(id)!.scene;
      expect(scene['kind'], 'street', reason: id);
      expect(scene['building'], building, reason: id);
    }
  });

  test(
      'the cells, the ceremony, the fall and the chart-keeper\'s thread open as the page',
      () {
    for (final id in [
      '800',
      '4999_standard',
      '4999_drawn',
      '3010_rope_fail',
      '6010_thread',
    ]) {
      expect(present.viewOf(id), SceneView.page, reason: id);
      expect(story.nodeFor(id)!.sceneView, 'page', reason: id);
    }
  });

  test('the Black Hold\'s rooms and the Beggar\'s floor follow the rule', () {
    for (final id in [
      '106',
      '115',
      '816',
      '820',
      '822',
      '822_lie_failed',
      '823'
    ]) {
      expect(present.viewOf(id), SceneView.room, reason: id);
      expect(story.nodeFor(id)!.sceneView, isNull, reason: id);
    }
  });

  test('every tagged building is in the town\'s plan', () {
    for (final node in story.nodes.values) {
      final building = node.scene['building']?.toString();
      if (building == null) continue;
      final town = building.split('_').first;
      final plan = _table('city_plans')[town] as Map<String, dynamic>;
      final ids = {
        for (final b in plan['buildings'] as List)
          (b as Map<String, dynamic>)['id'],
      };
      expect(ids, contains(building), reason: node.id);
    }
  });
}
