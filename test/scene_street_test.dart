// The street a scene plays in (v1.589, city_districts.dart sceneStreetOf):
// Narrative's `scene` block (`kind: street` and a building of the town's
// plan) wins; the geography `doorstep` lists stay the fallback until every
// chapter is tagged. The toll on the Stone Bridge (260), the quay drill
// (890_trainer) and the Wharf's gate (2010) are tagged; the family house's
// street (300) comes from its doorstep list.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
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
  final geo =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final plans = cityPlanRecordsFrom(_table('city_plans'));
  CityPlanRecord planOf(String nodeId) =>
      plans[geo.locationOfNode(story.nodeFor(nodeId))!.id]!;

  test('a tagged scene plays before the plan building it names', () {
    for (final id in ['260', '890_trainer', '2010']) {
      final node = story.nodeFor(id)!;
      expect(node.sceneInStreet, isTrue, reason: id);
      final record = planOf(id);
      final street = sceneStreetOf(geo, record, node)!;
      final building = record.building(node.sceneBuilding!)!;
      expect(street.id, building.id, reason: id);
      expect(street.parent, building.district, reason: id);
      expect(street.kind, building.kind, reason: id);
      expect(street.level, GeoLevel.building, reason: id);
      expect(scenePlaysInStreet(geo, node), isTrue, reason: id);
      // On the plan: the party at that building's door.
      final doorstep = sceneDoorstep(geo, record, node)!;
      expect(doorstep.buildingId, building.id, reason: id);
      expect(doorstep.districtId, building.district, reason: id);
      expect(doorstep.at, record.doorstepOf(building.id), reason: id);
    }
    // The toll booth on the Stone Bridge, by its plan name.
    expect(sceneStreetOf(geo, planOf('260'), story.nodeFor('260'))!.name,
        planOf('260').nameOf('alster_b032', french: false));
  });

  test('an untagged doorstep scene keeps its geography building', () {
    final node = story.nodeFor('300')!;
    expect(node.sceneInStreet, isFalse);
    final street = sceneStreetOf(geo, planOf('300'), node)!;
    expect(street.id, 'alster_family_house');
    expect(sceneDoorstep(geo, planOf('300'), node)!.buildingId,
        planOf('300').anchors['300']);
    // A scene in the street of neither plays nowhere's street.
    expect(sceneStreetOf(geo, planOf('270'), story.nodeFor('270')), isNull);
    expect(scenePlaysInStreet(geo, story.nodeFor('270')), isFalse);
  });

  test('a tag naming a building the plan lacks falls back', () {
    final node = StoryNode.fromJson('300', {
      ...(raw['300'] as Map<String, dynamic>),
      'scene': {'kind': 'street', 'building': 'nowhere_b999'},
    });
    expect(sceneStreetOf(geo, planOf('300'), node)!.id, 'alster_family_house');
    final untold = StoryNode.fromJson('270', {
      ...(raw['270'] as Map<String, dynamic>),
      'scene': {'kind': 'street', 'building': 'nowhere_b999'},
    });
    expect(sceneStreetOf(geo, planOf('270'), untold), isNull);
    // Without the town's plan, only the doorstep lists are read.
    expect(sceneStreetOf(geo, null, story.nodeFor('260')), isNull);
  });
}
