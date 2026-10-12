// A route along the world's roads laid on a chart (v1.254): the landmarks and
// stops in order, how far along each stop lies, and the one the party has
// passed.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/chart_worlds.dart';
import 'package:narrative_data_app/data/road_chart.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

void main() {
  for (final entry in {
    'A': chartWorldA,
    'B': chartWorldB,
    'C': chartWorldC,
  }.entries) {
    test('a route lies on chart ${entry.key} from landmark to landmark', () {
      final geography = entry.value;
      final route =
          chartRoadsBetween(geography, 'beggar', 'hold', AppLanguage.en)!;
      final roads = roadRoute('beggar', 'hold')!;
      // Every landmark passed, and every stop between, in order.
      expect(route.points.length, roads.places.length + roads.stops.length);
      expect(route.points.first, geography.of(landmarkById('beggar')!));
      expect(route.points.last, geography.of(landmarkById('hold')!));
      expect(route.stops.map((s) => s.name), roads.stops.map((s) => s.nameEn));
      // The stops come in order along the road, strictly inside it.
      var last = 0.0;
      for (final stop in route.stops) {
        expect(stop.along, greaterThan(last));
        expect(stop.along, lessThan(1));
        last = stop.along;
      }
    });
  }

  test('the stop passed is the last one the party has walked by', () {
    final route =
        chartRoadsBetween(chartWorldB, 'hovel', 'sewers', AppLanguage.fr)!;
    // The road to the sewers passes the Cistern Steps; the French names it.
    expect(route.stops.single.name, 'Les marches de la citerne');
    expect(route.passed(0), isNull);
    expect(route.passed(route.stops.single.along - 0.01), isNull);
    expect(route.passed(route.stops.single.along)!.name,
        'Les marches de la citerne');
    expect(route.passed(1)!.name, 'Les marches de la citerne');
  });

  test(
      'a route frames its bounds, and there is none between a place and itself',
      () {
    final route =
        chartRoadsBetween(chartWorldB, 'beggar', 'camp', AppLanguage.en)!;
    final (low, high) = route.bounds;
    for (final p in route.points) {
      expect(p.dx, inInclusiveRange(low.dx, high.dx));
      expect(p.dy, inInclusiveRange(low.dy, high.dy));
    }
    expect(
        chartRoadsBetween(chartWorldB, 'camp', 'camp', AppLanguage.en), isNull);
  });
}
