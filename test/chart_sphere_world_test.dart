// The story world on the whole sphere (board 11, chart_story.dart from
// tool/fmg_chart/story_world.py): 360 by 180 degrees, the story's three lands
// moved in longitude with their latitudes kept, ten lands with a polar land
// at each pole, twelve archipelagos, land and sea in every 30 degrees of
// longitude; the globe turns to either pole; the ice cap is the coldest.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/chart_globe.dart';
import 'package:narrative_data_app/data/chart_story.dart';
import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';

void main() {
  final chart = chartOf(MapShape.story);
  double deg(double r) => r * 180 / math.pi;
  (double, double) lonLat(Offset p) {
    final (lon, lat) =
        GlobeView.lonLatOf(p, lonSpan: chart.lonSpan, latSpan: chart.latSpan);
    return (deg(lon), deg(lat));
  }

  bool onLand(Offset p) => chart.lands.any((land) => pointInPolygon(p, land));

  test('the story world covers the whole sphere', () {
    expect(chart.wholeSphere, isTrue);
    expect(deg(chart.lonSpan), closeTo(360, 1e-6));
    expect(deg(chart.latSpan), closeTo(180, 1e-6));
    // The other charts stay on their band.
    expect(chartOf(MapShape.archipelago).wholeSphere, isFalse);
  });

  test('the story lands moved in longitude, their latitudes kept', () {
    void at(String place, (double, double) lon, double lat) {
      final (x, y) = lonLat(chart.places[place]!);
      expect(x, inInclusiveRange(lon.$1, lon.$2), reason: '$place lon');
      expect(y, closeTo(lat, 2.5), reason: '$place lat');
    }

    // The Ashen Continent west, the Old Continent east, the Lantern Isles
    // between (board 11), each place at the latitude it had.
    at('camp', (-122, -4), 35);
    at('reliquary', (-122, -4), 56);
    at('highhearth', (-122, -4), 57);
    at('candlehold', (-34, 8), 9);
    at('sleeper', (12, 134), -18);
    at('crash', (12, 134), -24);
    at('alster', (12, 134), -36);
  });

  test('ten lands, a polar land over each pole, twelve archipelagos', () {
    expect(storyEmptyLands.keys,
        containsAll(['polar_north', 'polar_south', 'east', 'west']));
    expect(3 + storyEmptyLands.length, 10);
    expect(storyArchipelagoLands, hasLength(12));
    for (final MapEntry(:key, :value) in storyArchipelagoLands.entries) {
      expect(value, isNotEmpty, reason: key);
    }
    for (var lon = -175.0; lon < 180; lon += 10) {
      for (final lat in [88.0, -88.0]) {
        final p = GlobeView.chartOf(lon * math.pi / 180, lat * math.pi / 180,
            lonSpan: chart.lonSpan, latSpan: chart.latSpan);
        expect(onLand(p), isTrue, reason: '$lon, $lat');
      }
    }
  });

  test('every new land, archipelago, island and ocean has its names', () {
    expect(storyLandNames.keys.toSet(), storyEmptyLands.keys.toSet());
    expect(
        storyArchipelagoNames.keys.toSet(), storyArchipelagoLands.keys.toSet());
    final islands = {for (final ix in storyArchipelagoLands.values) ...ix};
    expect(storyIslandNames.keys.toSet(), islands);
    for (final n in [
      ...storyLandNames.values,
      ...storyArchipelagoNames.values,
      ...storyIslandNames.values,
    ]) {
      expect(n.en, isNotEmpty);
      expect(n.fr, isNotEmpty);
    }
    final seas = chart.labels.where((l) => l.sea).toList();
    expect(seas.map((l) => l.en), contains('the Silent Sea'));
    expect(seas, hasLength(7));
    for (final l in seas) {
      expect(onLand(Offset(l.x, l.y)), isFalse, reason: l.en);
    }
  });

  test('every 30 degrees of longitude holds land and sea; about a third land',
      () {
    var land = 0.0, all = 0.0;
    for (var band = 0; band < 12; band++) {
      var bandLand = 0, bandSea = 0;
      for (var lon = -180.0 + band * 30 + 1;
          lon < -180 + (band + 1) * 30;
          lon += 2) {
        for (var lat = -80.0; lat <= 80; lat += 2) {
          final p = GlobeView.chartOf(lon * math.pi / 180, lat * math.pi / 180,
              lonSpan: chart.lonSpan, latSpan: chart.latSpan);
          final w = math.cos(lat * math.pi / 180);
          all += w;
          if (onLand(p)) {
            bandLand++;
            land += w;
          } else {
            bandSea++;
          }
        }
      }
      expect(bandLand, greaterThan(0), reason: 'band $band');
      expect(bandSea, greaterThan(0), reason: 'band $band');
    }
    expect(land / all, inInclusiveRange(0.25, 0.5));
  });

  test('the globe turns right over either pole, and round past the seam', () {
    final view = chart.globeAt(chart.places['camp']!, 1, const Offset(128, 88));
    expect(view.wholeSphere, isTrue);
    expect(view.toPole(north: true).lat0, closeTo(math.pi / 2, 1e-9));
    expect(view.toPole(north: false).lat0, closeTo(-math.pi / 2, 1e-9));
    expect(view.turned(0, 5).lat0, closeTo(math.pi / 2, 1e-9));
    // A band chart's view still stops short of the poles.
    final band = chartOf(MapShape.archipelago)
        .globeAt(const Offset(128, 88), 1, const Offset(128, 88));
    expect(band.toPole(north: true).lat0, lessThan(1.5));
    // Past the seam a longitude comes round to the chart's other edge.
    final p = GlobeView.chartOf(math.pi + 0.1, 0,
        lonSpan: chart.lonSpan, latSpan: chart.latSpan);
    expect(p.dx, lessThan(worldMapWidth * 0.1));
    expect(view.chartAt(view.centre), isNotNull);
  });

  test('the climate: the ice caps the coldest, the story places as before', () {
    final climate = ChartClimate.of(chart);
    double t(Offset p) => climate.sample(p).temperature;
    final northPole = GlobeView.chartOf(0, 85 * math.pi / 180,
        lonSpan: chart.lonSpan, latSpan: chart.latSpan);
    final southPole = GlobeView.chartOf(0, -85 * math.pi / 180,
        lonSpan: chart.lonSpan, latSpan: chart.latSpan);
    expect(t(northPole), lessThan(-5));
    expect(t(southPole), lessThan(-5));
    expect(t(chart.places['reliquary']!), lessThan(t(chart.places['camp']!)));
    expect(t(chart.places['wharf']!), greaterThan(20));
    expect(
        t(chart.places['sleeper']!), greaterThan(t(chart.places['alster']!)));
  });
}
