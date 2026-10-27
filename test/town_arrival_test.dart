// Arriving in a town with districts never leaves its whole plan fogged (the
// White Wells, v1.573): a scene played in the town itself, in no district,
// finds the first open district; scenes played in districts find theirs as
// before.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final geo =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final cities = {
    for (final p in geo.places.values)
      if (p.level == GeoLevel.district) p.parent,
  };

  // A scene played in the town itself, in none of its districts.
  String townScene(String city) => [
        for (final id in raw.keys)
          if (geo.locationOfNode(story.nodeFor(id))?.id == city &&
              districtOfNode(geo, story.nodeFor(id)) == null)
            id,
      ].first;

  Set<String> found(String city,
          {List<String> flags = const [], String? scene}) =>
      foundDistricts(geo, story,
          cityId: city,
          visitedNodeIds: const [],
          currentNodeId: scene ?? townScene(city),
          flags: flags);

  test('a town scene with districts opens on one found district', () {
    var checked = 0;
    for (final city in cities) {
      final hasTownScene = raw.keys.any((id) =>
          geo.locationOfNode(story.nodeFor(id))?.id == city &&
          districtOfNode(geo, story.nodeFor(id)) == null);
      if (!hasTownScene) continue;
      checked++;
      final open = [
        for (final d in districtsOfCity(geo, city))
          if (!districtLocked(geo, d.id, const [], const [])) d.id,
      ];
      expect(open, isNotEmpty, reason: city);
      expect(found(city), {open.first}, reason: city);
    }
    expect(checked, greaterThan(0));
  });

  test('the White Wells: the pool is found, the caravan ring is not', () {
    expect(found('white_wells'), {'white_wells_pool'});
  });

  test('a district walked into joins the arrival one, which stays found', () {
    expect(
        found('white_wells',
            flags: [districtFoundFlag('white_wells_caravan_ring')]),
        {'white_wells_pool', 'white_wells_caravan_ring'});
  });

  test('a scene in a district finds that district only, as before', () {
    final inDistrict = [
      for (final id in raw.keys)
        if (districtOfNode(geo, story.nodeFor(id))?.id == 'saltmouth_wharf') id,
    ].first;
    expect(found('saltmouth', scene: inDistrict), {'saltmouth_wharf'});
  });
}
