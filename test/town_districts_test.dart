// The towns of the story have their districts too (v1.349): the Ashen
// Quarter, the Drowned Cloister and the White Anchorage, like the cities,
// and every scene in them stands in one of their districts, so the
// journey shows the district level there as it does in Saltmouth.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

void main() {
  final raw =
      jsonDecode(File('assets/gamedata/geography.json').readAsStringSync())
          as Map<String, dynamic>;
  final dag = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in dag.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });

  test(
      'every city and town with scenes has districts, and its scenes '
      'stand in them', () {
    final locations = {
      for (final MapEntry(:key, :value) in raw.entries)
        if ((value as Map)['level'] == 'location' &&
            const {'city', 'town'}.contains(value['kind']))
          key,
    };
    expect(locations,
        containsAll(['ashen_quarter', 'drowned_cloister', 'white_anchorage']));
    final districts = {
      for (final MapEntry(:key, :value) in raw.entries)
        if ((value as Map)['level'] == 'district') key: value['parent'],
    };
    for (final city in locations) {
      expect(districts.values, contains(city), reason: city);
    }
    // No scene stands on a city or town itself: each is in a district.
    for (final MapEntry(:key, :value) in dag.entries) {
      final location = (value as Map)['location'];
      expect(locations, isNot(contains(location)), reason: key);
    }
  });

  test('the new districts read as the cities\' do', () {
    for (final id in [
      'ashen_quarter_gate',
      'ashen_quarter_ash_market',
      'ashen_quarter_wall_of_names',
      'ashen_quarter_cinder_row',
      'ashen_quarter_spire_stair',
      'drowned_cloister_stair',
      'drowned_cloister_nave',
      'drowned_cloister_ossuary',
      'white_anchorage_quay',
      'white_anchorage_hulls',
      'white_anchorage_chapel',
    ]) {
      final d = raw[id] as Map<String, dynamic>;
      expect(d['level'], 'district', reason: id);
      for (final key in ['name', 'name_fr', 'blurb', 'blurb_fr']) {
        expect((d[key] as String).isNotEmpty, isTrue, reason: '$id.$key');
      }
      expect(geoGlyphs, contains(d['glyph']), reason: id);
    }
  });

  test('every district reads as the cities\' do, under a place on file', () {
    final villages = <String>{};
    for (final MapEntry(key: id, value: entry) in raw.entries) {
      final d = entry as Map<String, dynamic>;
      if (d['level'] != 'district') continue;
      for (final key in ['name', 'name_fr', 'blurb', 'blurb_fr']) {
        expect((d[key] as String).isNotEmpty, isTrue, reason: '$id.$key');
      }
      expect(geoGlyphs, contains(d['glyph']), reason: id);
      final parent = raw[d['parent']] as Map<String, dynamic>?;
      expect(parent?['level'], 'location', reason: id);
      if (parent?['kind'] != 'city' && parent?['kind'] != 'town') {
        villages.add(d['parent'] as String);
      }
    }
    // The villages, halts and camps have theirs too (v1.426).
    expect(
        villages,
        containsAll([
          'rimewell',
          'greyhithe',
          'wracks_end',
          'cove_camp',
          'kindly_hill',
          'highhearth',
          'emberwick',
          'akagiri',
          'white_wells',
        ]));
  });

  test('the Ashen Quarter\'s opening scene stands at its gate', () {
    final geo = Geography.parse(geography: raw);
    expect(
        districtOfNode(geo, story.nodeFor('3005'))?.id, 'ashen_quarter_gate');
    expect(districtsOfCity(geo, 'ashen_quarter'), hasLength(5));
    expect(geo.locationOfNode(story.nodeFor('3005_wall'))?.id, 'ashen_quarter');
  });
}
