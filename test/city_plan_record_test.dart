// The city plan (board 15, city_plan_record.dart, city_districts.dart):
// Saltmouth's stored plan covers its districts (and every other city's
// plan on file its own), every scene's way stands on
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
  // Narrative's seats for the towns it gave districts to (v1.426): by the
  // place a scene stands in now, the district it stands in on the plan.
  final seats = <String, Map<String, String>>{
    for (final MapEntry(key: from, value: districts)
        in _json('tool/city_plans/district_seats.json').entries)
      from: {
        for (final MapEntry(key: d, value: list) in (districts as Map).entries)
          for (final s in list as List) s as String: d as String,
      },
  };
  String? seatOf(StoryNode node) => seats[node.location]?[node.id];
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

  // Every city on file: the same checks as Saltmouth's above.
  for (final MapEntry(key: city, value: plan) in plans.entries) {
    group('$city\'s plan', () {
      final own = districtsOfCity(geo, city);

      test('covers its districts: shape, label and entry inside', () {
        expect(own, isNotEmpty);
        expect(plan.districts.keys.toSet(), {for (final d in own) d.id});
        for (final d in plan.districts.values) {
          expect(d.shape.length, greaterThanOrEqualTo(3), reason: d.id);
          expect(plan.districtAt(d.label), d.id, reason: '${d.id} label');
          expect(pointInPolygonOffsets(d.entry, d.shape), isTrue,
              reason: '${d.id} entry');
        }
        expect(plan.squares.map((s) => s.kind), contains('market'));
      });

      test('buildings stand in their district, with unique ids', () {
        final ids = <String>{};
        final byDistrict = <String, int>{};
        for (final b in plan.buildings) {
          expect(ids.add(b.id), isTrue, reason: b.id);
          expect(b.shape.length, greaterThanOrEqualTo(3), reason: b.id);
          expect(plan.districtAt(b.centre), b.district, reason: b.id);
          byDistrict[b.district] = (byDistrict[b.district] ?? 0) + 1;
        }
        for (final d in own) {
          expect(byDistrict[d.id], greaterThanOrEqualTo(6), reason: d.id);
        }
      });

      test('every scene has its way on a building of its district', () {
        var scenes = 0;
        for (final node in story.nodes.values) {
          final district = districtOfNode(geo, node);
          // Where Narrative seats it, until the story's location says so.
          final seat = seatOf(node);
          final at = seat ?? district?.id;
          if (at == null || geo.locationOf(at)?.id != city) continue;
          scenes++;
          expect(plan.anchors[node.id], isNotNull, reason: node.id);
          expect(plan.building(plan.anchors[node.id]!)!.district, at,
              reason: node.id);
          if (district != null) {
            expect(
                plan.buildingOfWay(node.id, district.id)!.district, district.id,
                reason: node.id);
          }
        }
        expect(scenes, greaterThan(0));
      });

      test('a building with no name written reads as empty, not missing', () {
        for (final b in plan.buildings) {
          if (plan.names.containsKey(b.id)) continue;
          expect(plan.nameOf(b.id, french: false), '');
          expect(plan.nameOf(b.id, french: true), '');
        }
      });
    });
  }

  test('Narrative\'s town districts are on file and on the plans', () {
    final proposed = _json('docs/proposals/town-districts.json');
    var count = 0;
    for (final MapEntry(key: place, value: list) in proposed.entries) {
      for (final raw in list as List) {
        final d = raw as Map<String, dynamic>;
        final id = d['id'] as String;
        final here = geo.place(id);
        expect(here?.level, GeoLevel.district, reason: id);
        // Under the place the proposal names (the Reliquary Quarter's new
        // neighbours are the Black Reliquary's districts).
        final parent = geo.place(place)!.level == GeoLevel.district
            ? geo.place(place)!.parent
            : place;
        expect(here!.parent, parent, reason: id);
        expect(here.name, d['name'], reason: id);
        expect(here.controller, d['controller'], reason: id);
        final plan = plans[parent]!;
        expect(plan.districts, contains(id), reason: id);
        // Every scene listed in it stands on one of its buildings.
        for (final scene in (d['scenes'] as List).cast<String>()) {
          expect(story.nodeFor(scene), isNotNull, reason: scene);
          final b = plan.building(plan.anchors[scene] ?? '');
          expect(b?.district, id, reason: scene);
          count++;
        }
      }
    }
    expect(count, greaterThan(150));
  });

  test('Candlehold\'s rest stands where 7510_seen does, at its gates', () {
    final candlehold = plans['candlehold']!;
    expect(candlehold.anchors['7510_seen'], 'candlehold_b003');
    expect(candlehold.anchors['7515_rest'], 'candlehold_b003');
    expect(
        candlehold.building('candlehold_b003')!.district, 'candlehold_gates');
    expect(candlehold.districts.keys, hasLength(3));
  });

  test('the villages are small and open, shaped to their place', () {
    final towns = [
      for (final c in ['saltmouth', 'alster', 'ashen_quarter', 'candlehold'])
        plans[c]!,
    ];
    final fewest =
        towns.map((t) => t.buildings.length).reduce((a, b) => a < b ? a : b);
    for (final village in [
      'rimewell',
      'greyhithe',
      'wracks_end',
      'cove_camp',
      'kindly_hill',
      'highhearth',
      'emberwick',
      'akagiri',
      'white_wells',
    ]) {
      final plan = plans[village]!;
      expect(plan.buildings.length, lessThan(fewest), reason: village);
      expect(plan.districts.length, inInclusiveRange(2, 4), reason: village);
      expect(plan.rivers, isEmpty, reason: village);
      expect(plan.squares.map((s) => s.kind), isNot(contains('arena')),
          reason: village);
      expect(plan.squares.map((s) => s.kind), isNot(contains('plaza')),
          reason: village);
    }
    // The coast's on the sea; the halt on the frost road is inland, open.
    for (final c in ['greyhithe', 'wracks_end', 'cove_camp']) {
      expect(plans[c]!.sea, isNotEmpty, reason: c);
    }
    expect(plans['rimewell']!.sea, isEmpty);
    expect(plans['rimewell']!.wallRuns, isEmpty);
    expect(plans['greyhithe']!.wallRuns, isEmpty);
    // The camp's palisade and the giants' wall.
    expect(plans['cove_camp']!.wallRuns, isNotEmpty);
    expect(plans['highhearth']!.wallRuns, isNotEmpty);
  });

  test('the towns are shaped to their place', () {
    // Alster: a river city with a quay, inland.
    final alster = plans['alster']!;
    expect(alster.rivers, isNotEmpty);
    expect(alster.sea, isEmpty);
    expect(alster.squares.map((s) => s.kind), contains('quay'));
    // The Ashen Quarter: walled, burned, no water.
    final ashen = plans['ashen_quarter']!;
    expect(ashen.wallRuns, isNotEmpty);
    expect(ashen.rivers, isEmpty);
    expect(ashen.sea, isEmpty);
    // The Drowned Cloister: the fen's water, a river and channels, no wall.
    final cloister = plans['drowned_cloister']!;
    expect(cloister.sea, isNotEmpty);
    expect(cloister.rivers, isNotEmpty);
    expect(cloister.canals.length, greaterThanOrEqualTo(3));
    expect(cloister.wallRuns, isEmpty);
    // White Anchorage: an open shore town, its hulls beached outside it.
    final anchorage = plans['white_anchorage']!;
    expect(anchorage.sea, isNotEmpty);
    expect(anchorage.wallRuns, isEmpty);
    expect(
        anchorage.buildings
            .where((b) => b.district == 'white_anchorage_hulls')
            .every((b) => b.kind == 'shed'),
        isTrue);
    // Candlehold: walled above the sea, no river.
    final candlehold = plans['candlehold']!;
    expect(candlehold.sea, isNotEmpty);
    expect(candlehold.wallRuns, isNotEmpty);
    expect(candlehold.rivers, isEmpty);
  });

  test('Narrative\'s seating: each way on a named building of its district',
      () {
    final seated = {
      '2015_bazaar': 'saltmouth_lantern_alleys',
      '2015_cards': 'saltmouth_card_row',
      '2015_kelda': 'saltmouth_landward_gate',
      '2015_survivor': 'saltmouth_tern_row',
      '2015_hound': 'saltmouth_yard',
      '2015_smuggler': 'saltmouth_wharf',
    };
    for (final MapEntry(key: scene, value: district) in seated.entries) {
      final b = salt.buildingOfWay(scene, district)!;
      expect(b.id, salt.anchors[scene], reason: scene);
      expect(salt.nameOf(b.id, french: false), isNotEmpty, reason: scene);
      expect(salt.nameOf(b.id, french: true), isNotEmpty, reason: scene);
    }
    expect(salt.nameOf(salt.anchors['2015_bazaar']!, french: false),
        'The Arcane Bazaar');
    // A way's follow-up stands at its building.
    expect(salt.anchors['2015_sable_caught'], salt.anchors['2015_sable']);
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

  test('the generator lays a village out: three roads, small, loose', () {
    Map<String, dynamic> lay({required bool village}) =>
        jsonDecode(jsonEncode(generateCityPlan(CityPlanSpec(
          cityId: 'test',
          seed: 11,
          districts: const [
            DistrictSeed('a', P(450, 420)),
            DistrictSeed('b', P(600, 540)),
          ],
          scenesByDistrict: const {
            'a': ['s1'],
            'b': ['s2'],
          },
          shoreY: null,
          riverX: null,
          walled: false,
          arena: false,
          wallRadius: 220,
          lotSpacing: 42,
          village: village,
        )))) as Map<String, dynamic>;
    final town = CityPlanRecord.fromJson('test', lay(village: false));
    final village = CityPlanRecord.fromJson('test', lay(village: true));
    expect(village.avenues, hasLength(3));
    expect(town.avenues, hasLength(5));
    expect(village.squares.map((s) => s.kind), ['market']);
    double mean(CityPlanRecord r) {
      var sum = 0.0;
      for (final b in r.buildings) {
        sum += (b.shape.first - b.centre).distance;
      }
      return sum / r.buildings.length;
    }

    expect(mean(village), lessThan(mean(town)));
    expect(village.building(village.anchors['s2']!)!.district, 'b');
  });

  test('the generator lays a town out with no sea, river or wall', () {
    final record = CityPlanRecord.fromJson(
        'test',
        jsonDecode(jsonEncode(generateCityPlan(const CityPlanSpec(
          cityId: 'test',
          seed: 9,
          districts: [
            DistrictSeed('a', P(400, 400)),
            DistrictSeed('b', P(650, 500)),
          ],
          scenesByDistrict: {
            'a': ['s1'],
            'b': ['s2', 's2_fight'],
          },
          followUps: {'s2_fight': 's2'},
          shoreY: null,
          riverX: null,
          walled: false,
          arena: false,
        )))) as Map<String, dynamic>);
    expect(record.sea, isEmpty);
    expect(record.rivers, isEmpty);
    expect(record.islands, isEmpty);
    expect(record.canals, isEmpty);
    expect(record.wallRuns, isEmpty);
    expect(record.gates, isEmpty);
    expect(record.towers, isEmpty);
    expect(record.squares.map((s) => s.kind), isNot(contains('arena')));
    expect(record.building(record.anchors['s1']!)!.district, 'a');
    expect(record.anchors['s2_fight'], record.anchors['s2']);
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
