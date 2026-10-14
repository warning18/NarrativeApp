// The city plan (board 15, city_plan_record.dart, city_districts.dart):
// Saltmouth's stored plan covers its districts, every scene's way stands on
// a building of its own district (and finds one when a scene is re-tagged),
// the hub's ways split by district, the fog lifts where the party has been,
// and walking between districts is free.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/data/city_plan_generator.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final geo = Geography.parse(
      geography: _json('assets/gamedata/geography.json'),
      biomes: _json('assets/gamedata/biomes.json'));
  final raw = _json(StoryRepository.assetPath);
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final plans = cityPlanRecordsFrom(_json(cityPlansAssetPath));
  final salt = plans['saltmouth']!;
  final districts = districtsOfCity(geo, 'saltmouth');

  test('Saltmouth has six districts, the two new ones among them', () {
    expect(districts.map((d) => d.id), [
      'saltmouth_landward_gate',
      'saltmouth_tern_row',
      'saltmouth_wharf',
      'saltmouth_yard',
      'saltmouth_lantern_alleys',
      'saltmouth_card_row',
    ]);
    for (final d in districts) {
      expect(geoGlyphs, contains(d.glyph), reason: d.id);
    }
  });

  test('every district has its shape, its label and its entry inside it', () {
    expect(salt.districts.keys.toSet(), {for (final d in districts) d.id});
    for (final d in salt.districts.values) {
      expect(d.shape.length, greaterThanOrEqualTo(3), reason: d.id);
      expect(salt.districtAt(d.label), d.id, reason: '${d.id} label');
      expect(pointInPolygonOffsets(d.entry, d.shape), isTrue,
          reason: '${d.id} entry');
    }
    expect(salt.gates, isNotEmpty);
    expect(salt.rivers, isNotEmpty);
    expect(salt.islands, isNotEmpty);
    expect(salt.squares.map((s) => s.kind), containsAll(['market', 'arena']));
    expect(salt.bridges, isNotEmpty);
  });

  test('buildings stand in their district, with unique ids', () {
    final ids = <String>{};
    final byDistrict = <String, int>{};
    for (final b in salt.buildings) {
      expect(ids.add(b.id), isTrue, reason: b.id);
      expect(salt.districtAt(b.centre), b.district, reason: b.id);
      byDistrict[b.district] = (byDistrict[b.district] ?? 0) + 1;
    }
    for (final d in districts) {
      expect(byDistrict[d.id], greaterThanOrEqualTo(6), reason: d.id);
    }
  });

  test('every scene in Saltmouth has its way on a building of its district',
      () {
    var scenes = 0;
    for (final node in story.nodes.values) {
      final district = districtOfNode(geo, node);
      if (district == null || geo.locationOf(district.id)?.id != 'saltmouth') {
        continue;
      }
      scenes++;
      expect(salt.anchors[node.id], isNotNull, reason: node.id);
      expect(salt.buildingOfWay(node.id, district.id)!.district, district.id,
          reason: node.id);
    }
    expect(scenes, greaterThan(50));
    // Re-tagged into another district, a scene's way finds a building
    // there, the same one every time.
    final moved = salt.buildingOfWay('2016', 'saltmouth_card_row')!;
    expect(moved.district, 'saltmouth_card_row');
    expect(salt.buildingOfWay('2016', 'saltmouth_card_row')!.id, moved.id);
  });

  test('a walk between two districts follows the streets', () {
    final from = salt.anchorOf('saltmouth_landward_gate');
    final to = salt.anchorOf('saltmouth_wharf');
    final path = salt.route(from, to);
    expect(path.first, from);
    expect(path.last, to);
    expect(path.length, greaterThan(2));
    expect(salt.anchorOf(''), isNot(Offset.zero));
  });

  test('the generator lays the same city out from the same seed', () {
    CityPlanSpec spec() => const CityPlanSpec(
          cityId: 'test',
          seed: 5,
          districts: [
            DistrictSeed('a', P(400, 300)),
            DistrictSeed('b', P(650, 450)),
            DistrictSeed('c', P(150, 700), outside: true),
          ],
          scenesByDistrict: {
            'a': ['s1', 's2'],
            'b': ['s3'],
          },
        );
    final one = jsonEncode(generateCityPlan(spec()));
    expect(jsonEncode(generateCityPlan(spec())), one);
    final record = CityPlanRecord.fromJson(
        'test', jsonDecode(one) as Map<String, dynamic>);
    expect(record.districts.keys, containsAll(['a', 'b', 'c']));
    expect(record.building(record.anchors['s3']!)!.district, 'b');
  });

  test('the hub\'s ways split by the district they lead into', () {
    final hub = story.nodeFor('2015')!;
    final all = <int>[];
    for (final d in districts) {
      all.addAll(waysInDistrict(geo, story, hub, d.id));
    }
    expect(all..sort(), [for (var i = 0; i < hub.choices.length; i++) i]);
    expect(waysInDistrict(geo, story, hub, 'saltmouth_wharf'), isNotEmpty);
  });

  test('the fog lifts where a scene was played or the party walked in', () {
    Set<String> found(List<String> flags) => foundDistricts(geo, story,
        cityId: 'saltmouth',
        visitedNodeIds: const ['2015'],
        currentNodeId: '2015',
        flags: flags);
    expect(found(const []), {'saltmouth_wharf'});
    expect(found([districtFoundFlag('saltmouth_card_row')]),
        {'saltmouth_wharf', 'saltmouth_card_row'});
  });

  testWidgets('walking to another district is free and finds it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storyDataProvider.overrideWith((ref) async => story),
      ],
      child: Consumer(builder: (context, r, _) {
        ref = r;
        r.watch(partyDistrictProvider);
        return const SizedBox.shrink();
      }),
    ));
    await tester.runAsync(() async {
      ref.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      ref.read(storyPlayProvider.notifier).jumpTo('2015');
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    expect(ref.read(currentCityProvider), 'saltmouth');
    expect(ref.read(partyDistrictProvider), 'saltmouth_wharf');
    final gold = ref.read(playerSessionProvider).gold;
    await tester
        .runAsync(() => walkToDistrict(ref, 'saltmouth_lantern_alleys'));
    await tester.pump();
    expect(ref.read(partyDistrictProvider), 'saltmouth_lantern_alleys');
    expect(ref.read(foundDistrictsProvider),
        containsAll(['saltmouth_wharf', 'saltmouth_lantern_alleys']));
    expect(ref.read(playerSessionProvider).gold, gold);
    expect(
        ref.read(partyDistrictWaysProvider),
        waysInDistrict(
            geo, story, story.nodeFor('2015')!, 'saltmouth_lantern_alleys'));
    // Another city's district: no walk.
    await tester.runAsync(() => walkToDistrict(ref, 'alster_lower_town'));
    expect(ref.read(partyDistrictProvider), 'saltmouth_lantern_alleys');
  });
}
