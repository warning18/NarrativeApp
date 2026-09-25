// The world map's three geographies: every place the story reaches has a
// spot on each, inside the chart, on land or at sea as the story has it.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';

bool _inside(Offset p, List<Offset> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i], b = polygon[j];
    if ((a.dy > p.dy) != (b.dy > p.dy) &&
        p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
      inside = !inside;
    }
  }
  return inside;
}

void main() {
  for (final shape in MapShape.values) {
    group(shape.name, () {
      final chart = chartOf(shape);

      test('places every landmark inside the chart', () {
        for (final l in worldMapLandmarks) {
          expect(chart.places.containsKey(l.id), isTrue, reason: l.id);
          final p = chart.of(l);
          expect(p.dx, inInclusiveRange(4, worldMapWidth - 4), reason: l.id);
          expect(p.dy, inInclusiveRange(4, worldMapHeight - 4), reason: l.id);
        }
      });

      test('puts the places at sea on the water and the rest ashore', () {
        for (final l in worldMapLandmarks) {
          final ashore = chart.lands.any((land) => _inside(chart.of(l), land));
          expect(ashore, !l.atSea, reason: l.id);
        }
      });

      test('keeps the places apart', () {
        for (final a in worldMapLandmarks) {
          for (final b in worldMapLandmarks) {
            if (a.id.compareTo(b.id) >= 0) continue;
            expect((chart.of(a) - chart.of(b)).distance, greaterThan(9),
                reason: '${a.id} and ${b.id}');
          }
        }
      });
    });
  }
}
