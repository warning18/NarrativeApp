// A city laid out as a city (v1.203): the same each time from its seed,
// its districts each with a spot on the plan, inside the frame, and the
// streets joined so a walk finds its way between any two of them.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/city_plan.dart';

void main() {
  const alster = [
    CityDistrict('alster_lower_town', 'slum'),
    CityDistrict('alster_stone_bridge', 'bridge'),
    CityDistrict('alster_black_hold', 'keep'),
    CityDistrict('alster_undercroft', 'cellar'),
    CityDistrict('alster_high_quay', 'quay'),
  ];
  const saltmouth = [
    CityDistrict('saltmouth_landward_gate', 'gate'),
    CityDistrict('saltmouth_tern_row', 'market'),
    CityDistrict('saltmouth_wharf', 'wharf'),
    CityDistrict('saltmouth_yard', 'yard'),
  ];

  test('the plan is the same from the same seed, and kept', () {
    final a = CityPlan.of(
        seed: 7, size: CitySize.city, water: 'river', districts: alster);
    final b = CityPlan.of(
        seed: 7, size: CitySize.city, water: 'river', districts: alster);
    expect(identical(a, b), isTrue);
    final c = CityPlan.of(
        seed: 8, size: CitySize.city, water: 'river', districts: alster);
    expect(
        c.buildings.length == a.buildings.length &&
            c.streets.first.points.first == a.streets.first.points.first,
        isFalse);
  });

  test('a river city: wall, gates, bridges, a quay on the bank, districts', () {
    final plan = CityPlan.of(
        seed: 7,
        size: CitySize.city,
        water: 'river',
        districts: alster,
        exitBearings: const [-1.2, 1.9]);
    expect(plan.walled, isTrue);
    expect(plan.gates.length, greaterThanOrEqualTo(3));
    expect(plan.towers, isNotEmpty);
    expect(plan.river, isNotEmpty);
    expect(plan.bridges, isNotEmpty);
    expect(plan.quays, isNotEmpty);
    expect(plan.buildings.length, greaterThan(150));
    for (final d in alster) {
      expect(plan.anchors.containsKey(d.id), isTrue, reason: d.id);
      expect(plan.frame.contains(plan.anchorOf(d.id)), isTrue, reason: d.id);
    }
    expect(plan.landmarks.map((l) => l.kind),
        containsAll([CityLandmarkKind.keep, CityLandmarkKind.church]));
    // The square is the place itself.
    expect(plan.anchorOf(''), plan.centre);
  });

  test('a shore city keeps its gates off the sea and its wharf on it', () {
    final plan = CityPlan.of(
        seed: 11, size: CitySize.city, water: 'shore', districts: saltmouth);
    expect(plan.shoreline, isNotEmpty);
    for (final g in plan.gates) {
      expect(g.dx, greaterThan(plan.shoreline.first.dx + 20));
    }
    final wharf =
        plan.landmarks.firstWhere((l) => l.districtId == 'saltmouth_wharf');
    expect(wharf.kind, CityLandmarkKind.wharf);
    expect(plan.quays.length, greaterThanOrEqualTo(4));
    final gate = plan.landmarks
        .firstWhere((l) => l.districtId == 'saltmouth_landward_gate');
    expect(plan.gates.any((g) => (g - gate.at).distance < 1), isTrue);
  });

  test('every district is reached through the streets', () {
    final plan = CityPlan.of(
        seed: 7, size: CitySize.city, water: 'river', districts: alster);
    for (final d in alster) {
      final way = plan.route(plan.centre, plan.anchorOf(d.id));
      expect(way.first, plan.centre);
      expect(way.last, plan.anchorOf(d.id));
      expect(way.length, greaterThan(2), reason: d.id);
      // No leg of the way is longer than a street's stretch.
      for (var i = 0; i + 1 < way.length; i++) {
        expect((way[i + 1] - way[i]).distance, lessThan(140), reason: d.id);
      }
    }
  });

  test('a village has no wall, a chapel and a mill', () {
    final plan = CityPlan.of(
        seed: 3, size: CitySize.village, water: '', districts: const []);
    expect(plan.walled, isFalse);
    expect(plan.landmarks.map((l) => l.kind),
        containsAll([CityLandmarkKind.church, CityLandmarkKind.mill]));
    expect(plan.buildings.where((b) => b.kind == CityBuildingKind.house),
        isNotEmpty);
    expect(plan.frame.contains(const Offset(500, 500)), isTrue);
  });
}
