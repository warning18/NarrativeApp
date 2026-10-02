// The chart's relief (v1.199): coasts, roads and terrain drawn from fixed
// seeds, the same on every opening, and the worlds' zones, features and
// roads consistent with their lands.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/chart_relief.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';

void main() {
  group('fractalLine', () {
    const square = [Offset(0, 0), Offset(40, 0), Offset(40, 40), Offset(0, 40)];

    test('is the same for the same seed, and differs by seed', () {
      final a = fractalLine(square, seed: 3);
      final b = fractalLine(square, seed: 3);
      final c = fractalLine(square, seed: 4);
      expect(a, b);
      expect(a, isNot(c));
    });

    test('keeps every corner and adds a point per edge per level', () {
      final pts = fractalLine(square, depth: 2, seed: 1);
      expect(pts.length, 16);
      for (final corner in square) {
        expect(pts, contains(corner));
      }
    });

    test('an open line keeps both ends', () {
      final pts = fractalLine(const [Offset(0, 0), Offset(50, 10)],
          depth: 3, seed: 9, closed: false);
      expect(pts.first, const Offset(0, 0));
      expect(pts.last, const Offset(50, 10));
      expect(pts.length, 9);
    });
  });

  test('windingRoad keeps its ends and bends between them', () {
    final road = windingRoad(const Offset(10, 10), const Offset(90, 30),
        seed: 5, bends: 3);
    expect(road.length, 5);
    expect(road.first, const Offset(10, 10));
    expect(road.last, const Offset(90, 30));
    expect(
        windingRoad(const Offset(10, 10), const Offset(90, 30), seed: 5), road);
  });

  test('chartSeed is stable', () {
    expect(chartSeed('alster'), chartSeed('alster'));
    expect(chartSeed('alster'), isNot(chartSeed('saltmouth')));
  });

  for (final shape in MapShape.values) {
    group('${shape.name} relief', () {
      final chart = chartOf(shape);
      final relief = ChartRelief.of(chart);

      test('is built once and kept', () {
        expect(identical(ChartRelief.of(chart), relief), isTrue);
        expect(relief.coasts.length, chart.lands.length);
        expect(relief.zones.length, chart.zones.length);
        expect(relief.rivers.length, chart.rivers.length);
      });

      test('names every zone in both languages, inside the chart', () {
        for (final zone in chart.zones) {
          expect(zone.nameEn, isNotEmpty);
          expect(zone.nameFr, isNotEmpty);
          expect(chartBiomeColours.containsKey(zone.biome), isTrue,
              reason: zone.biome);
          expect(zone.labelAt.dx, inInclusiveRange(0, worldMapWidth));
          expect(zone.labelAt.dy, inInclusiveRange(0, worldMapHeight));
        }
      });

      test('lays terrain only on the lands, clear of the places', () {
        for (final mark in relief.terrain) {
          expect(mark.zone, inInclusiveRange(0, chart.zones.length - 1));
          expect(pointInPolygon(mark.at, relief.zones[mark.zone]), isTrue);
          for (final place in chart.places.values) {
            expect((place - mark.at).distance, greaterThan(1.5));
          }
        }
      });

      test('the places the story stands at lie in a zone', () {
        // Every landmark but a street of a town (which its town's zone
        // may miss) lies in a named land, so its land clears when read.
        var inZone = 0;
        for (final l in worldMapLandmarks) {
          if (chart.zoneAt(chart.of(l)) != null) inZone++;
        }
        expect(inZone, greaterThan(worldMapLandmarks.length * 3 ~/ 4));
      });
    });
  }

  group('the Ring', () {
    final chart = chartOf(MapShape.archipelago);

    test('is the default and carries the ranges, features and roads', () {
      expect(chart.ranges, isNotEmpty);
      expect(chart.features, isNotEmpty);
      expect(chart.tradeRoads, isNotEmpty);
      for (final range in chart.ranges) {
        expect(range.nameFr, isNotEmpty, reason: range.nameEn);
      }
    });

    test('seats every clan with a colour of its own, on land', () {
      final seats =
          chart.features.where((f) => f.kind == ChartFeatureKind.seat).toList();
      expect(
          seats.map((f) => f.clan).toSet(),
          containsAll([
            'dominion', 'compact', 'mire', 'crows', 'vigil', 'penitents', //
            'giants', 'oni', 'kindly', 'tidekin',
          ]));
      for (final f in chart.features) {
        expect(f.nameFr, isNotEmpty, reason: f.nameEn);
        final ashore =
            ChartRelief.of(chart).coasts.any((c) => pointInPolygon(f.at, c)) ||
                chart.lands.any((l) => pointInPolygon(f.at, l));
        expect(ashore, !f.atSea, reason: f.nameEn);
      }
    });

    test('gives each zone its clans', () {
      final influence = {
        for (final zone in chart.zones) zone.nameEn: zone.influence,
      };
      expect(influence['The Frost Reach']!.first.$1, 'dominion');
      expect(influence['The Grey Fen']!.first.$1, 'mire');
      expect(influence['The Hollow Cape']!.first.$1, 'vigil');
      expect(influence['The Waste'], isEmpty);
    });
  });
}
