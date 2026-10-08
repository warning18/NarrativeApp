// The chart's climate (v1.204, see climate.dart): the sea is at nought,
// the ranges stand high, the deserts are dry and the fens wet, the frost
// is cold and the heights colder; and the weather over it is the same for
// the same place and time, moves with the wind, and falls as snow where it
// is cold.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';

void main() {
  final chart = chartOf(MapShape.archipelago);
  final climate = ChartClimate.of(chart);
  Offset at(String landmark) =>
      chart.of(worldMapLandmarks.firstWhere((l) => l.id == landmark));

  test('the same chart gives the same climate, kept once', () {
    expect(identical(ChartClimate.of(chart), climate), isTrue);
    expect(
        ChartClimate.of(chartOf(MapShape.continental)), isNot(same(climate)));
  });

  test('the sea lies at nought and the land above it', () {
    final sea = climate.sample(const Offset(2, 2));
    expect(sea.sea, isTrue);
    expect(sea.elevation, 0);
    expect(sea.humidity, 1);
    final alster = climate.sample(at('beggar'));
    expect(alster.sea, isFalse);
    expect(alster.elevation, greaterThan(0));
    expect(alster.biome, 'temperate');
  });

  test('the ranges stand high over a low land', () {
    for (final range in chart.ranges) {
      final crest = range.line[1];
      if (!climate.isLand(crest)) continue;
      expect(climate.elevationAt(crest), greaterThan(0.5),
          reason: range.nameEn);
    }
    var sum = 0.0, n = 0;
    for (var y = 1.0; y < worldMapHeight; y += 3) {
      for (var x = 1.0; x < worldMapWidth; x += 3) {
        final p = Offset(x, y);
        if (!climate.isLand(p)) continue;
        sum += climate.elevationAt(p);
        n++;
      }
    }
    expect(n, greaterThan(100));
    expect(sum / n, lessThan(0.35));
  });

  test('the desert is dry, the fen is wet', () {
    final wells = climate.sample(at('wells'));
    final kindly = climate.sample(at('kindly'));
    expect(wells.biome, 'desert');
    expect(kindly.biome, 'fen');
    expect(wells.humidity, lessThan(0.35));
    expect(kindly.humidity, greaterThan(0.6));
    expect(kindly.humidity, greaterThan(wells.humidity + 0.3));
  });

  test('the frost is cold, the Alster vale mild, and height cools', () {
    final rimewell = climate.sample(at('rimewell'));
    final alster = climate.sample(at('beggar'));
    expect(rimewell.biome, 'frost');
    expect(rimewell.temperature, lessThan(4));
    expect(alster.temperature, greaterThan(rimewell.temperature + 8));
    final range = chart.ranges.first;
    final crest = range.line[1];
    final foot = Offset(crest.dx, crest.dy + 20);
    if (climate.isLand(foot)) {
      expect(
          climate.temperatureAt(crest), lessThan(climate.temperatureAt(foot)));
    }
  });

  test('the season turns over ninety days and a day is its own', () {
    final p = at('beggar');
    final spring = climate.temperatureAt(p, day: 22);
    final autumn = climate.temperatureAt(p, day: 67);
    expect(spring, greaterThan(autumn + 5));
    expect(climate.temperatureAt(p, day: 3),
        isNot(closeTo(climate.temperatureAt(p, day: 4), 0.001)));
  });

  test('weather is the same for the same place and time, and moves', () {
    final p = at('beggar');
    final a = climate.weather(p, 12.25);
    final b = climate.weather(p, 12.25);
    expect(a.kind, b.kind);
    expect(a.cloud, b.cloud);
    expect(a.windSpeed, greaterThan(0));
    // Over a day the sky over one place changes.
    var changed = false;
    for (var t = 12.0; t < 16; t += 0.1) {
      if ((climate.cloudAt(p, t) - a.cloud).abs() > 0.2) {
        changed = true;
        break;
      }
    }
    expect(changed, isTrue);
  });

  test('clouds gather over the sea more than over the desert', () {
    var seaCover = 0.0, desertCover = 0.0;
    const n = 240;
    for (var t = 0; t < n; t++) {
      seaCover += climate.cloudAt(at('storm'), t * 0.375);
      desertCover += climate.cloudAt(at('wells'), t * 0.375);
    }
    expect(seaCover / n, greaterThan(desertCover / n + 0.05));
  });

  test('what falls on the frost is snow, on the vale rain', () {
    final count = <String, Map<WeatherKind, int>>{};
    for (final (name, p) in [
      ('rimewell', at('rimewell')),
      ('beggar', at('beggar')),
    ]) {
      for (var t = 0.0; t < 90; t += 0.25) {
        final kind = climate.weather(p, t).kind;
        final tally = count[name] ??= {};
        tally[kind] = (tally[kind] ?? 0) + 1;
      }
    }
    // The frost snows far more than it rains (a mild day may bring sleet);
    // the vale never sees snow.
    expect(count['rimewell']![WeatherKind.snow] ?? 0,
        greaterThan((count['rimewell']![WeatherKind.rain] ?? 0) * 3));
    expect(count['beggar']![WeatherKind.rain] ?? 0, greaterThan(0));
    expect(count['beggar']!.containsKey(WeatherKind.snow), isFalse);
  });

  test('dust blows over the desert, never rain enough to drown it', () {
    final kinds = <WeatherKind>{};
    for (var t = 0.0; t < 90; t += 0.25) {
      kinds.add(climate.weather(at('wells'), t).kind);
    }
    expect(kinds, contains(WeatherKind.dust));
    expect(kinds, isNot(contains(WeatherKind.ash)));
  });

  test('the wind has a point of the compass', () {
    for (final (angle, from) in [
      (0.0, 'W'),
      (3.14159, 'E'),
      (-1.5708, 'S'),
      (1.5708, 'N'),
    ]) {
      final sample = WeatherSample(
          kind: WeatherKind.clear,
          cloud: 0,
          fall: 0,
          windAngle: angle,
          windSpeed: 1,
          climate: climate.sample(const Offset(2, 2)));
      expect(sample.windFrom, from, reason: 'blowing to $angle');
    }
  });

  test('contours follow the heights and close round the ranges', () {
    final lines = climate.contours(0.5);
    expect(lines, isNotEmpty);
    var onLand = 0;
    for (final line in lines) {
      expect(line.length, greaterThanOrEqualTo(3));
      for (final p in line) {
        // A contour that runs off a cliff into the sea ends at nought.
        if (!climate.isLand(p)) continue;
        onLand++;
        expect(climate.elevationAt(p), closeTo(0.5, 0.25));
      }
    }
    expect(onLand, greaterThan(20));
    expect(climate.contours(0.5, humidity: true), isNotEmpty);
  });

  test('the clock runs a day in forty seconds from the story day', () {
    final t = ChartClimate.timeOf(7);
    expect(t, greaterThanOrEqualTo(7));
    expect(t, lessThan(8 + 1e6));
  });

  test('noise is smooth and bounded', () {
    for (var i = 0; i < 50; i++) {
      final v = fbm(Offset(i * 3.7, i * 1.3), 20, 3, 5);
      expect(v, inInclusiveRange(0, 1));
    }
    final a = valueNoise(const Offset(10, 10), 8, 1);
    final b = valueNoise(const Offset(10.1, 10), 8, 1);
    expect((a - b).abs(), lessThan(0.05));
  });
}
