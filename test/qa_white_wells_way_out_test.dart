// The White Wells' way south (v1.851, QA's hand test of 1.846): scene
// 1200's "Go south…" ways lead to a departure scene still told at the
// Wells (1000, 1001, 1002), whose one way is the road to Saltmouth. Each
// is a way out of the village (`place: out`), never a thing done where the
// party stands; and the chart opens on the Pool, the hub's district, with
// the way south a banner on it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/data/choice_shape.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/way_places.dart';
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
  final plans = cityPlanRecordsFrom(_table('city_plans'));
  final stops = StoryStops.of(
    story: story,
    geography: geography,
    cityPlans: plans,
    ports: _table('ports'),
  );
  final wells = story.nodeFor('1200')!;
  final south = [
    for (final c in wells.choices)
      if (c.textFor(false).startsWith('Go south')) c,
  ];

  test('1200: every "Go south" way is a way out to Saltmouth, not here', () {
    expect(south, hasLength(3));
    for (final c in south) {
      expect(c.place, outPlaceWord, reason: c.nextId);
      expect(wayOutEndOf(c, story), '2001', reason: c.nextId);
      final shape = choiceShape(wells, c, story: story, geography: geography);
      expect(shape.here, isFalse, reason: c.nextId);
      expect(shape.move, ChoiceMove.travel, reason: c.nextId);
      expect(geography.locationOf(shape.to?.id)?.id,
          geography.locationOfNode(story.nodeFor('2001'))?.id);
      final place = placeOfWay(wells, c,
          story: story,
          geography: geography,
          record: plans['white_wells']!,
          stops: stops);
      expect(place.kind, WayPlaceKind.wayOut, reason: c.nextId);
    }
    // In the district's list the way south is its own place, after `here`.
    final list = districtPlaces(wells,
        story: story,
        geography: geography,
        record: plans['white_wells']!,
        stops: stops);
    final out = list.where((e) => e.place.kind == WayPlaceKind.wayOut);
    expect(out, isNotEmpty, reason: '$list');
    expect(out.expand((e) => e.ways),
        containsAll([for (final c in south) wells.choices.indexOf(c)]));
  });

  test('1200 stands at the Pool: the chart opens on the district', () {
    // partyDistrictProvider falls back on the scene's stop when the scene
    // is told at the village itself, so the chart opens on the Pool with
    // its ways on it, not on the whole town with none.
    expect(wells.location, 'white_wells');
    expect(stops.stopOf('1200'), 'white_wells_pool');
    expect(geography.place('white_wells_pool')?.level, GeoLevel.district);
    expect(geography.locationOf('white_wells_pool')?.id, 'white_wells');
  });

  test('a way with no `place: out` keeps its own next scene', () {
    final sleep = wells.choices.firstWhere((c) => c.nextId == '1200');
    expect(wayOutEndOf(sleep, story), '1200');
  });
}
