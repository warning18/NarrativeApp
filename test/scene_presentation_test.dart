// Which view a scene opens in (scene_presentation.dart, presentation-
// contract.md §4 and §7): the family house's chain as the user walked it
// (the street before the house, then the page for the cannonball and
// Lysa), the page turns opening in the view of the page they turn to and
// never read through, hubs on their map, rooms, the sheet for side scenes,
// and Narrative's `scene` block winning over the rule.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/scene_flow.dart';
import 'package:narrative_data_app/data/scene_presentation.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _rawStory() =>
    jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;

ScenePresentation _of(Map<String, dynamic> raw, Geography geography) {
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final stops = StoryStops.of(
    story: story,
    geography: geography,
    cityPlans: cityPlanRecordsFrom(_table('city_plans')),
    ports: _table('ports'),
  );
  return ScenePresentation.of(story: story, geography: geography, stops: stops);
}

void main() {
  final geography =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final present = _of(_rawStory(), geography);

  test('the family house: the street, then the page', () {
    // The Weaver's Alley is a main scene in the Lower Town: the page.
    expect(present.viewOf('270'), SceneView.page);
    // At the house's doorstep, walked to: the street with its choices.
    expect(present.viewOf('300'), SceneView.street);
    // The calm first page, the cannonball and Lysa: a beat, the page.
    expect(present.viewOf('400_hold'), SceneView.page);
    expect(present.viewOf('400'), SceneView.page);
    // After the fight, at the same door: the scene goes on, on the page.
    expect(present.viewOf('450'), SceneView.page);
    expect(present.viewOf('400_lost'), SceneView.page);
  });

  test('a page turn opens as the page it turns to, and is never read through',
      () {
    final story = StoryData({
      for (final e in _rawStory().entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    for (final (turn, page) in [
      ('100_dice', '100'),
      ('400_hold', '400'),
      ('960_lift', '960'),
    ]) {
      final node = story.nodeFor(turn)!;
      expect(node.pageTurn, isTrue, reason: turn);
      expect(node.choices.single.nextId, page, reason: turn);
      expect(present.viewOf(turn), present.viewOf(page), reason: turn);
      expect(passThroughChoiceOf(node, const []), isNull, reason: turn);
    }
  });

  test('hubs open their map, rooms their plan, side scenes a sheet', () {
    expect(present.viewOf('2015'), SceneView.map);
    expect(present.viewOf('891'), SceneView.map);
    expect(present.viewOf('3001_camp'), SceneView.map);
    expect(present.weightOf('2015'), SceneWeight.ambient);
    // Inside the Blind Beggar and the Black Hold: the room.
    expect(present.viewOf('106'), SceneView.room);
    expect(present.viewOf('816'), SceneView.room);
    // An errand at a doorstep of Saltmouth: the street.
    expect(present.viewOf('2015_informant_trap'), SceneView.street);
    expect(present.weightOf('2015_informant_trap'), SceneWeight.side);
    // The story's ends.
    expect(present.viewOf('7005'), SceneView.ending);
  });

  test('every scene has a view; most errands are sheets', () {
    final counts = <SceneView, int>{};
    for (final id in _rawStory().keys) {
      counts.update(present.viewOf(id), (n) => n + 1, ifAbsent: () => 1);
    }
    expect(counts.values.fold(0, (a, b) => a + b), _rawStory().length);
    expect(counts[SceneView.sheet]!, greaterThan(counts[SceneView.page]!));
    expect(counts[SceneView.street], isNotNull);
  });

  // 270 and 106 are scenes the story file does not tag (Narrative's own tags
  // are in scene_tags_test.dart), so the rule's view shows against it.
  test('the scene block wins, and a save keeps it', () {
    final raw = _rawStory();
    (raw['270'] as Map<String, dynamic>)['scene'] = {
      'view': 'street',
      'weight': 'side',
      'kind': 'street',
    };
    (raw['106'] as Map<String, dynamic>)['scene'] = {'view': 'page'};
    final tagged = _of(raw, geography);
    expect(present.viewOf('270'), SceneView.page);
    expect(tagged.viewOf('270'), SceneView.street);
    expect(tagged.weightOf('270'), SceneWeight.side);
    expect(present.viewOf('106'), SceneView.room);
    expect(tagged.viewOf('106'), SceneView.page);
    final node = StoryNode.fromJson('270', raw['270'] as Map<String, dynamic>);
    expect(node.sceneView, 'street');
    expect(node.toJson()['scene'], {
      'view': 'street',
      'weight': 'side',
      'kind': 'street',
    });
    // An unknown view word falls back to the rule.
    (raw['300'] as Map<String, dynamic>)['scene'] = {'view': 'balcony'};
    expect(_of(raw, geography).viewOf('300'), SceneView.street);
  });
}
