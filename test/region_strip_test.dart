// The world as two strips for the side-view camera (region_strip.dart):
// every place with a scene and every road stop has an x, the same on every
// launch; places follow the roads, districts the story.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/region_strip.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/world_leg_path.dart';
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final geo =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final chart = chartOf(MapShape.story);
  RegionStrips build() =>
      RegionStrips.build(geo: geo, chart: chart, story: story);
  final strips = build();

  if (Platform.environment['STRIP_DUMP'] != null) {
    test('dump', () {
      for (final z in strips.zones) {
        // ignore: avoid_print
        print('${z.strip.name} ${z.zoneId} ${z.kit} '
            '${z.start.toStringAsFixed(1)}..${z.end.toStringAsFixed(1)}');
        for (final e in z.places.entries) {
          if (geo.place(e.key)!.level == GeoLevel.building) continue;
          // ignore: avoid_print
          print('   ${geo.place(e.key)!.level.name} ${e.key} '
              '${e.value.toStringAsFixed(1)}');
        }
      }
    });
  }

  test('every scene that happens somewhere has an x on its strip', () {
    final missing = [
      for (final id in story.nodes.keys)
        if (geo.placeOfNode(story.nodeFor(id)) != null &&
            strips.positionOfNode(id) == null)
          '$id (${geo.placeOfNode(story.nodeFor(id))!.id})',
    ];
    expect(missing, isEmpty,
        reason: 'a place with a scene and no x: add its zone to '
            'stripZoneOrder (region_strip.dart)');
    // And a scene the story doesn't have has none.
    expect(strips.positionOfNode('no_such_scene'), isNull);
  });

  test('every zone with a place is in the order, every biome has a kit', () {
    for (final zone in geo.places.values) {
      if (zone.level != GeoLevel.zone) continue;
      expect(stripZoneOrder, contains(zone.id), reason: zone.id);
      expect(stripKitOfBiome, contains(zone.biome), reason: zone.id);
    }
  });

  test('every stop of a road between two places has an x between them', () {
    for (final road in worldRoads) {
      final a = geo.placeOfLandmark(road.a), b = geo.placeOfLandmark(road.b);
      if (a == null || b == null) continue;
      final pa = strips.positionOfPlace(a.id)!;
      final pb = strips.positionOfPlace(b.id)!;
      for (final stop in road.stops) {
        final at = strips.positionOfStop(stop.id);
        expect(at, isNotNull, reason: '${road.id}: ${stop.id}');
        if (pa.strip == pb.strip) {
          final lo = pa.x < pb.x ? pa.x : pb.x, hi = pa.x < pb.x ? pb.x : pa.x;
          expect(at!.x, inExclusiveRange(lo, hi), reason: stop.id);
        } else {
          expect(at!.strip, StripKind.sea, reason: stop.id);
        }
      }
    }
  });

  test('the same x on every launch', () {
    final again = build();
    for (final z in strips.zones) {
      final other = again.stripOf(z.zoneId)!;
      expect(other.start, z.start);
      expect(other.end, z.end);
      expect(other.places, z.places);
    }
  });

  test('the land strip runs desert, ruins, fen, frost (UX-2\'s panorama)', () {
    final land = [
      for (final z in strips.zones)
        if (z.strip == StripKind.land) z,
    ];
    int first(String kit) => land.indexWhere((z) => z.kit == kit);
    expect(first('desert'), lessThan(first('ruins')));
    expect(first('ruins'), lessThan(first('fen')));
    expect(first('fen'), lessThan(first('frost')));
    // End to end, no gap and no overlap; the sea is a strip of its own.
    for (var i = 1; i < land.length; i++) {
      expect(land[i].start, closeTo(land[i - 1].end, 1e-9),
          reason: land[i].zoneId);
    }
    expect(strips.stripOf('open_water')!.strip, StripKind.sea);
    expect(strips.positionOfPlace('the_crossing')!.strip, StripKind.sea);
  });

  test('places in a zone are their road distance apart, in story order', () {
    final crash = strips.positionOfPlace('lark_wreck')!.x;
    final sleeper = strips.positionOfPlace('sleepers_face')!.x;
    final wells = strips.positionOfPlace('white_wells')!.x;
    expect(crash, lessThan(sleeper));
    expect(sleeper, lessThan(wells));
    expect(sleeper - crash,
        closeTo(worldLegPath(chart, 'crash', 'sleeper').length, 1e-9));
    expect(wells - sleeper,
        closeTo(worldLegPath(chart, 'sleeper', 'wells').length, 1e-9));
    // Across a zone's border, the road distance too.
    final saltmouth = strips.positionOfPlace('saltmouth')!.x;
    expect(saltmouth - wells,
        closeTo(worldLegPath(chart, 'wells', 'saltmouth').length, 1e-9));
  });

  test('a town\'s districts around it in story order; a building at its own',
      () {
    final town = strips.positionOfPlace('saltmouth')!.x;
    final districts = [
      for (final p in geo.childrenOf('saltmouth'))
        if (p.level == GeoLevel.district) p.id,
    ];
    expect(districts.length, greaterThan(1));
    int firstScene(String district) =>
        story.nodes.keys.toList().indexWhere((id) =>
            geo
                .ancestorAt(
                    geo.placeOfNode(story.nodeFor(id))?.id, GeoLevel.district)
                ?.id ==
            district);
    final byStory = [...districts]
      ..sort((a, b) => firstScene(a).compareTo(firstScene(b)));
    final byX = [...districts]..sort((a, b) =>
        strips.positionOfPlace(a)!.x.compareTo(strips.positionOfPlace(b)!.x));
    expect(byX, byStory);
    for (final d in districts) {
      expect((strips.positionOfPlace(d)!.x - town).abs(),
          lessThanOrEqualTo(stripDistrictSpread + 1e-9));
    }
    // Every place stays inside its own zone's stretch (its kit).
    for (final z in strips.zones) {
      for (final e in z.places.entries) {
        expect(e.value, inInclusiveRange(z.start, z.end), reason: e.key);
      }
    }
    for (final p in geo.places.values) {
      if (p.level != GeoLevel.building) continue;
      final district = geo.ancestorAt(p.parent, GeoLevel.district);
      if (district == null) continue;
      expect(strips.positionOfPlace(p.id)!.x,
          strips.positionOfPlace(district.id)!.x,
          reason: p.id);
    }
  });

  test('a move\'s path: start, the road\'s stops, end', () {
    final path = strips.pathOn('lark_wreck', 'white_wells');
    final cairn = strips.positionOfStop('dune_cairn')!.x;
    final wadi = strips.positionOfStop('dry_wadi')!.x;
    expect(path, [
      strips.positionOfPlace('lark_wreck')!.x,
      cairn,
      wadi,
      strips.positionOfPlace('white_wells')!.x,
    ]);
    // The other way round, the same x backwards.
    expect(strips.pathOn('white_wells', 'lark_wreck'), path.reversed.toList());
    // Within one town: no road, from district to district.
    expect(strips.pathOn('saltmouth', 'saltmouth').length, 2);
    // From the land to the sea: no path on one strip.
    expect(strips.pathOn('saltmouth', 'the_crossing'), isEmpty);
  });
}
