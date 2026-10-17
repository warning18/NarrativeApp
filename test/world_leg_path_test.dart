// The move between two Journey places on the real world chart (wave 14):
// the polyline along the world's roads and sea lanes in the story chart's
// coordinates, the stops passed, the leg's kind, and a straight line by the
// lie of the land when no road joins the two.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/chart_relief.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_leg_path.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/travel_history_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final chart = chartOf(MapShape.story);

  test('one road: from A\'s spot to B\'s, as the full map draws it', () {
    final path = worldLegPath(chart, 'beggar', 'alley');
    expect(path.routed, isTrue);
    expect(path.kind, WorldLegKind.road);
    expect(path.points.first, chart.places['beggar']);
    expect(path.points.last, chart.places['alley']);
    expect(path.segments.single.roadId, 'beggar_alley');
    // The full map's road for a leg walked beggar -> alley.
    expect(
        path.points,
        windingRoad(chart.places['beggar']!, chart.places['alley']!,
            seed: chartSeed('beggar-alley'), bends: 3, amp: 0.16));
    expect(path.stops.single.name, 'Tallow Steps');
    expect(path.stops.single.along, inExclusiveRange(0, 1));
    final french =
        worldLegPath(chart, 'beggar', 'alley', language: AppLanguage.fr);
    expect(french.stops.single.name, 'Les marches du Suif');
  });

  test('a sea lane is a sea leg; a road then a lane is a crossing', () {
    final sail = worldLegPath(chart, 'docks', 'crash');
    expect(sail.kind, WorldLegKind.sea);
    expect(sail.segments.single.kind, WorldLegKind.sea);
    expect(sail.stops.map((s) => s.name),
        ['The Harbour Chain', 'The Painted Sails']);

    final far = worldLegPath(chart, 'docks', 'sleeper');
    expect(far.kind, WorldLegKind.crossing);
    expect([for (final s in far.segments) s.roadId],
        ['docks_crash', 'crash_sleeper']);
    expect([for (final s in far.segments) s.kind],
        [WorldLegKind.sea, WorldLegKind.road]);
    // The roads join end to end, through the landmark between.
    expect(far.points[far.segments.first.end], chart.places['crash']);
    expect(far.segments.last.start, far.segments.first.end);
    expect(far.points.last, chart.places['sleeper']);
  });

  test('every road, both ways, lies end to end with its stops in order', () {
    for (final road in worldRoads) {
      for (final (a, b) in [(road.a, road.b), (road.b, road.a)]) {
        final path = worldLegPath(chart, a, b);
        expect(path.routed, isTrue, reason: road.id);
        expect(path.points.first, chart.places[a], reason: road.id);
        expect(path.points.last, chart.places[b], reason: road.id);
        expect(path.kind,
            road.kind == RoadKind.sea ? WorldLegKind.sea : WorldLegKind.road,
            reason: road.id);
        expect(path.stops.map((s) => s.name),
            [for (final s in road.stopsFrom(a)) s.nameEn],
            reason: road.id);
        var last = 0.0;
        for (final s in path.stops) {
          expect(s.along, greaterThan(last), reason: road.id);
          last = s.along;
        }
        expect(path.at(0), path.points.first);
        expect(path.at(1), path.points.last);
      }
    }
  });

  test('a long way follows the roads, landmark after landmark', () {
    final route = roadRoute('beggar', 'camp')!;
    final path = worldLegPath(chart, 'beggar', 'camp');
    expect([for (final s in path.segments) s.roadId],
        [for (final l in route.legs) l.road.id]);
    expect(path.kind, WorldLegKind.crossing);
    for (final s in path.segments) {
      expect(path.points[s.start], chart.places[s.from]);
      expect(path.points[s.end], chart.places[s.to]);
    }
  });

  test('no road: a straight line, its kind by the lie of the land', () {
    const land = [
      Offset(0, 0),
      Offset(100, 0),
      Offset(100, 100),
      Offset(0, 100)
    ];
    final toy = ChartGeography(
      places: const {
        'here': Offset(10, 10),
        'there': Offset(90, 90),
        'isle': Offset(200, 10),
        'storm': Offset(150, 150),
      },
      lands: const [
        land,
        [Offset(190, 0), Offset(210, 0), Offset(210, 20), Offset(190, 20)]
      ],
      rivers: const [],
      labels: const [],
    );
    final walk = worldLegPath(toy, 'here', 'there');
    expect(walk.routed, isFalse);
    expect(walk.points, const [Offset(10, 10), Offset(90, 90)]);
    expect(walk.kind, WorldLegKind.road);
    expect(walk.stops, isEmpty);
    expect(walk.segments.single.roadId, '');
    expect(worldLegPath(toy, 'here', 'isle').kind, WorldLegKind.crossing);
    // 'storm' is a landmark at sea (the crossing), here with no road.
    expect(worldLegPath(toy, 'here', 'storm').routed, isFalse);
    expect(landmarkById('storm')!.atSea, isTrue);
    expect(worldLegPath(toy, 'here', 'storm').kind, WorldLegKind.sea);
    // A place no chart knows stands at the chart's middle.
    final lost = worldLegPath(chart, 'beggar', 'nowhere');
    expect(lost.routed, isFalse);
    expect(
        lost.points.last, const Offset(worldMapWidth / 2, worldMapHeight / 2));
    // No move: one point.
    expect(worldLegPath(chart, 'wharf', 'wharf').points, hasLength(1));
  });

  test('by scenes: the landmarks the Journey moves between', () {
    final from = landmarkOfScene('100')!, to = landmarkOfScene('2010')!;
    final path = worldLegPathForScenes(chart, '100', '2010')!;
    expect(path.fromId, from.id);
    expect(path.toId, to.id);
    expect(path.points.first, chart.places[from.id]);
    expect(path.points.last, chart.places[to.id]);
    expect(path.kind, WorldLegKind.crossing);
    expect(worldLegPathForScenes(chart, '100', '105'), isNull);
  });

  test('the provider lays it on the story chart', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final path =
        container.read(worldLegPathProvider((from: 'docks', to: 'crash')));
    expect(
        path.points.first, container.read(storyChartProvider).places['docks']);
    expect(path.kind, WorldLegKind.sea);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
}
