// The district as places, not choices (way_places.dart, the user's call):
// each way has one place (here, a building of the plan, a way out), the
// list holds one entry per place with its count, `here` first, the main
// story next, the ways out after, a shut place last; a choice's own `place`
// wins; a stand-in building is never a place. The party's arrival in a
// district is a new value each time it changes district.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/way_places.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/city_provider.dart';

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
  List<WayPlaceEntry> placesOf(String nodeId) {
    final node = story.nodeFor(nodeId)!;
    final city = geography.locationOfNode(node)!.id;
    return districtPlaces(node,
        story: story, geography: geography, record: plans[city]!, stops: stops);
  }

  group('the place of a way', () {
    test('the High Quay: every way is done where the party stands', () {
      final list = placesOf('891');
      expect(list, hasLength(1));
      expect(list.single.place.isHere, isTrue);
      expect(list.single.ways, [0, 1, 2, 3, 4]);
      // The mate at the gangway goes on with the main story.
      expect(list.single.main, isTrue);
    });

    test('Smugglers\' Quay: here first, then the named buildings', () {
      final list = placesOf('2015');
      expect(list.first.place.isHere, isTrue);
      final buildings =
          list.where((e) => e.place.kind == WayPlaceKind.building).toList();
      expect(buildings, isNotEmpty);
      final record = plans['saltmouth']!;
      final names = [
        for (final e in buildings)
          wayPlaceName(e.place,
              record: record,
              geography: geography,
              french: false,
              fallback: '?'),
      ];
      expect(names, contains('The Arcane Bazaar'));
      expect(names.where((n) => n == '?'), isEmpty);
      // Every way is in one entry, once.
      final ways = [for (final e in list) ...e.ways]..sort();
      expect(ways,
          [for (var i = 0; i < story.nodeFor('2015')!.choices.length; i++) i]);
      // Several ways at one building make one entry with their count.
      expect(buildings.any((e) => e.ways.length > 1), isTrue);
    });

    test('a choice\'s own place wins; a stand-in building is never one', () {
      final node = story.nodeFor('891')!;
      final record = plans['alster']!;
      final building = record.buildings.first.id;
      final placed = StoryChoice.fromJson({
        ...node.choices.first.toJson(),
        'place': building,
      });
      expect(
          placeOfWay(node, placed,
              story: story, geography: geography, record: record, stops: stops),
          WayPlace.building(building));
      final here = StoryChoice.fromJson({
        ...node.choices.first.toJson(),
        'place': herePlaceWord,
      });
      expect(
          placeOfWay(node, here,
                  story: story,
                  geography: geography,
                  record: record,
                  stops: stops)
              .isHere,
          isTrue);
      expect(placed.toJson()['place'], building);
      // A scene with no anchor of its own (the camp's) never lands on a
      // building picked for it.
      final camp = story.nodeFor('3001_camp')!;
      final city = geography.locationOfNode(camp)?.id;
      if (city != null && plans.containsKey(city)) {
        for (final c in camp.choices) {
          final p = placeOfWay(camp, c,
              story: story,
              geography: geography,
              record: plans[city]!,
              stops: stops);
          if (p.kind == WayPlaceKind.building) {
            expect(plans[city]!.anchors[c.nextId], p.buildingId);
          }
        }
      }
    });
  });

  test('the list\'s order: here, the main story, near to far, ways out, shut',
      () {
    const a = WayPlace.building('a'),
        b = WayPlace.building('b'),
        c = WayPlace.building('c'),
        out = WayPlace.wayOut('road');
    final list = groupWaysByPlace(
      {
        0: c,
        1: a,
        2: const WayPlace.here(),
        3: out,
        4: b,
        5: a,
        6: c,
      },
      main: {4},
      carries: {1, 3, 4},
      locked: {0, 6},
      distance: (p) => switch (p.buildingId) { 'a' => 2.0, _ => 1.0 },
    );
    expect([for (final e in list) e.place.id],
        ['here', 'building:b', 'building:a', 'out:road', 'building:c']);
    final atA = list[2];
    expect(atA.ways, [1, 5]);
    expect(atA.openCount, 2);
    expect(atA.carries, isTrue);
    expect(list[1].main, isTrue);
    expect(list.last.locked, isTrue);
    expect(list.last.openCount, 0);
    expect(list.first.carries, isFalse);
  });

  test('an arrival each time the party changes district', () {
    final district = StateProvider<String?>((ref) => 'gate');
    final container = ProviderContainer(overrides: [
      partyDistrictProvider.overrideWith((ref) => ref.watch(district)),
    ]);
    addTearDown(container.dispose);
    final seen = <DistrictArrival?>[];
    container.listen(districtArrivalProvider, (_, next) => seen.add(next),
        fireImmediately: true);
    void walk(String? to) {
      container.read(district.notifier).state = to;
      container.read(districtArrivalProvider);
    }

    walk('wharf');
    walk('wharf');
    walk(null);
    walk('gate');
    expect(seen, [
      (districtId: 'gate', count: 1),
      (districtId: 'wharf', count: 2),
      (districtId: 'gate', count: 3),
    ]);
  });
}
