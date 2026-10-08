// The chart's climate (v1.204): how high, how wet and how warm each point
// of the world is, worked out once from the chart itself (its coasts, its
// ranges, its rivers and lakes, its lands' biomes, its latitude), and the
// weather that moves over it: clouds carried on the wind, rain and snow
// where the air is wet enough and cold enough, dust over the dry lands,
// ash over the burnt ones. Everything is a function of place and time
// alone, so every screen sees the same sky.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect;

import 'chart_globe.dart';
import 'chart_relief.dart';
import 'map_charts.dart';
import 'world_map.dart';

/// What the climate is at one point of the chart.
class ClimateSample {
  const ClimateSample({
    required this.elevation,
    required this.humidity,
    required this.temperature,
    required this.sea,
    required this.biome,
  });

  /// 0 at the sea, 1 on the highest peak.
  final double elevation;

  /// 0 bone dry, 1 sodden.
  final double humidity;

  /// Degrees, on the day asked for.
  final double temperature;

  /// Open water.
  final bool sea;

  /// The biome of the land here ('' at sea).
  final String biome;

  /// Height in metres, as a chart would write it.
  int get metres => (elevation * 2400).round();
}

/// The sky at one point of the chart at one moment.
enum WeatherKind { clear, cloud, fog, rain, snow, dust, ash }

class WeatherSample {
  const WeatherSample({
    required this.kind,
    required this.cloud,
    required this.fall,
    required this.windAngle,
    required this.windSpeed,
    required this.climate,
  });

  final WeatherKind kind;

  /// Cloud cover, 0 to 1.
  final double cloud;

  /// How hard it rains, snows, or blows dust: 0 to 1.
  final double fall;

  /// Where the wind blows to (radians, 0 east, y down) and how hard
  /// (chart units a day).
  final double windAngle;
  final double windSpeed;
  final ClimateSample climate;

  /// The point of the compass the wind comes from: N, NE, E…
  String get windFrom {
    // The wind blows to windAngle and comes from the opposite point. On
    // the chart 0 is east and the angle turns clockwise on screen (y goes
    // down), so a quarter turn is south.
    const points = ['E', 'SE', 'S', 'SW', 'W', 'NW', 'N', 'NE'];
    final from = windAngle + math.pi;
    final i = ((from / (math.pi / 4)).round() % 8 + 8) % 8;
    return points[i];
  }
}

/// The climate of one chart, kept once worked out.
class ChartClimate {
  ChartClimate._(this.geography)
      : _relief = ChartRelief.of(geography),
        _elev = Float32List(cols * rows),
        _hum = Float32List(cols * rows),
        _warm = Float32List(cols * rows),
        _coast = Float32List(cols * rows),
        _land = Uint8List(cols * rows),
        _zone = Int16List(cols * rows) {
    _lay();
  }

  static final Map<ChartGeography, ChartClimate> _cache = {};

  static ChartClimate of(ChartGeography geography) =>
      _cache[geography] ??= ChartClimate._(geography);

  final ChartGeography geography;
  final ChartRelief _relief;

  /// The grid: one cell every [cell] chart units.
  static const double cell = 2;
  static const int cols = worldMapWidth ~/ 2;
  static const int rows = worldMapHeight ~/ 2;

  final Float32List _elev;
  final Float32List _hum;

  /// The temperature of the land in the chart's own mild season.
  final Float32List _warm;

  /// Distance to the coast in chart units: positive on land, negative at
  /// sea.
  final Float32List _coast;
  final Uint8List _land;
  final Int16List _zone;

  /// How many real seconds the sky takes to live one of the story's days:
  /// the clouds cross a land in a minute or two.
  static const double secondsADay = 40;
  static final Stopwatch _clock = Stopwatch()..start();

  /// The sky's time on the story's [day]: that day, plus the time that
  /// has passed since the app opened, so the clouds move while the map
  /// is watched.
  static double timeOf(int day) =>
      day + _clock.elapsedMilliseconds / 1000 / secondsADay;

  // ---------------------------------------------------------------- lay

  static String _biomeOfZone(ChartGeography g, int zone) =>
      zone < 0 ? '' : g.zones[zone].biome;

  void _lay() {
    final g = geography;
    // Land, and which zone.
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final p = Offset((i + 0.5) * cell, (j + 0.5) * cell);
        final k = j * cols + i;
        var zone = -1;
        for (var z = 0; z < g.zones.length; z++) {
          if (pointInPolygon(p, g.zones[z].polygon)) {
            zone = z;
            break;
          }
        }
        final onLand = zone >= 0
            ? _biomeOfZone(g, zone) != 'sea'
            : g.lands.any((land) => pointInPolygon(p, land));
        _land[k] = onLand ? 1 : 0;
        _zone[k] = zone;
      }
    }
    _distances();
    _heights();
    _moisture();
    _warmth();
  }

  /// A chamfer distance transform: each cell's distance to the other
  /// kind of ground, in chart units.
  void _distances() {
    const far = 1e6;
    final toSea = Float32List(cols * rows);
    final toLand = Float32List(cols * rows);
    for (var k = 0; k < cols * rows; k++) {
      toSea[k] = _land[k] == 1 ? far : 0;
      toLand[k] = _land[k] == 1 ? 0 : far;
    }
    for (final d in [toSea, toLand]) {
      // Forward pass.
      for (var j = 0; j < rows; j++) {
        for (var i = 0; i < cols; i++) {
          final k = j * cols + i;
          var v = d[k];
          if (i > 0) v = math.min(v, d[k - 1] + 1);
          if (j > 0) {
            v = math.min(v, d[k - cols] + 1);
            if (i > 0) v = math.min(v, d[k - cols - 1] + 1.414);
            if (i < cols - 1) v = math.min(v, d[k - cols + 1] + 1.414);
          }
          d[k] = v;
        }
      }
      // Backward pass.
      for (var j = rows - 1; j >= 0; j--) {
        for (var i = cols - 1; i >= 0; i--) {
          final k = j * cols + i;
          var v = d[k];
          if (i < cols - 1) v = math.min(v, d[k + 1] + 1);
          if (j < rows - 1) {
            v = math.min(v, d[k + cols] + 1);
            if (i < cols - 1) v = math.min(v, d[k + cols + 1] + 1.414);
            if (i > 0) v = math.min(v, d[k + cols - 1] + 1.414);
          }
          d[k] = v;
        }
      }
    }
    for (var k = 0; k < cols * rows; k++) {
      _coast[k] = (_land[k] == 1 ? toSea[k] : -toLand[k]) * cell;
    }
  }

  /// Adds a rounded bump of [height] round [at], [sigma] wide, to the
  /// cells it reaches.
  void _bump(Float32List field, Offset at, double height, double sigma,
      {bool landOnly = true}) {
    final reach = sigma * 2.6;
    final i0 = math.max(0, ((at.dx - reach) / cell).floor());
    final i1 = math.min(cols - 1, ((at.dx + reach) / cell).ceil());
    final j0 = math.max(0, ((at.dy - reach) / cell).floor());
    final j1 = math.min(rows - 1, ((at.dy + reach) / cell).ceil());
    for (var j = j0; j <= j1; j++) {
      for (var i = i0; i <= i1; i++) {
        final k = j * cols + i;
        if (landOnly && _land[k] == 0) continue;
        final p = Offset((i + 0.5) * cell, (j + 0.5) * cell);
        final d2 = (p - at).distanceSquared / (sigma * sigma);
        field[k] += height * math.exp(-d2);
      }
    }
  }

  /// Adds a ridge along [line].
  void _ridge(
      Float32List field, List<Offset> line, double height, double sigma) {
    for (var s = 0; s + 1 < line.length; s++) {
      final a = line[s], b = line[s + 1];
      final len = (b - a).distance;
      final steps = math.max(1, (len / (sigma * 0.5)).ceil());
      for (var t = 0; t <= steps; t++) {
        // Bumps along the segment overlap into a ridge; each is scaled so
        // the ridge's crest stays near [height].
        _bump(field, a + (b - a) * (t / steps), height * 0.28, sigma);
      }
    }
  }

  void _heights() {
    final g = geography;
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final k = j * cols + i;
        if (_land[k] == 0) {
          _elev[k] = 0;
          continue;
        }
        final p = Offset((i + 0.5) * cell, (j + 0.5) * cell);
        // The land rises from the coast inland, with a gentle roll.
        final inland = 1 - math.exp(-_coast[k] / 26);
        var h = 0.05 + 0.2 * inland + 0.07 * (fbm(p, 24, 3, 11) - 0.5);
        switch (_biomeOfZone(g, _zone[k])) {
          case 'fen':
            h *= 0.5;
          case 'desert':
            h = 0.05 + 0.12 * inland + 0.04 * (fbm(p, 16, 2, 5) - 0.5);
          case 'sea_cliffs':
            h += 0.12 * math.exp(-_coast[k] / 10);
          case 'volcanic':
            h += 0.18;
          case 'tear':
            h += 0.1;
          case 'frost':
            h += 0.08;
        }
        _elev[k] = h;
      }
    }
    for (final range in g.ranges) {
      final height = 0.35 + range.size * 0.09 + (range.snow ? 0.12 : 0);
      _ridge(_elev, range.line, height, 2.0 + range.size * 1.3);
    }
    for (final mark in _relief.terrain) {
      switch (mark.kind) {
        case TerrainKind.peak:
          _bump(_elev, mark.at, 0.16 * mark.size, 2.4 * mark.size);
        case TerrainKind.hill:
          _bump(_elev, mark.at, 0.07 * mark.size, 2.2 * mark.size);
        case TerrainKind.cone:
          _bump(_elev, mark.at, 0.2 * mark.size, 2.6 * mark.size);
        case TerrainKind.cliff:
          _bump(_elev, mark.at, 0.08, 3);
        default:
          break;
      }
    }
    for (var k = 0; k < cols * rows; k++) {
      _elev[k] = _elev[k].clamp(0.0, 1.0);
    }
  }

  static double _biomeMoisture(String biome) => switch (biome) {
        'temperate' => 0.62,
        'fen' => 0.92,
        'desert' => 0.1,
        'arid_coast' => 0.3,
        'ashlands' => 0.3,
        'volcanic' => 0.22,
        'sea_cliffs' => 0.58,
        'frost' => 0.46,
        'tear' => 0.18,
        'sea' => 1,
        _ => 0.5,
      };

  /// Distance from [p] to the nearest point of [line].
  static double _toLine(Offset p, List<Offset> line) {
    var best = double.infinity;
    for (var s = 0; s + 1 < line.length; s++) {
      final a = line[s], b = line[s + 1];
      final ab = b - a;
      final l2 = ab.distanceSquared;
      final t = l2 == 0
          ? 0.0
          : (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / l2).clamp(0.0, 1.0);
      final d = (p - (a + ab * t)).distance;
      if (d < best) best = d;
    }
    return best;
  }

  void _moisture() {
    final g = geography;
    final lakes = [
      for (final m in _relief.terrain)
        if (m.kind == TerrainKind.lake || m.kind == TerrainKind.pool) m.at,
    ];
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final k = j * cols + i;
        if (_land[k] == 0) {
          _hum[k] = 1;
          continue;
        }
        final p = Offset((i + 0.5) * cell, (j + 0.5) * cell);
        final base = _biomeMoisture(_biomeOfZone(g, _zone[k]));
        final seaNear = math.exp(-_coast[k] / 40);
        var water = 0.0;
        for (final river in g.rivers) {
          final d = _toLine(p, river);
          water = math.max(water, 0.28 * math.exp(-(d * d) / 64));
        }
        for (final lake in lakes) {
          final d = (p - lake).distance;
          water = math.max(water, 0.22 * math.exp(-(d * d) / 36));
        }
        // The rain shadow: a height to the west (the prevailing wind's
        // side) that stands above this ground keeps the rain off it.
        var upwind = 0.0;
        for (var dx = 2; dx <= 24; dx += 2) {
          final ii = i - dx ~/ 2;
          if (ii < 0) break;
          upwind = math.max(upwind, _elev[j * cols + ii]);
        }
        final shadow = ((upwind - _elev[k] - 0.12) * 1.1).clamp(0.0, 0.4);
        // The windward slopes catch the rain.
        var lift = 0.0;
        for (var dx = 2; dx <= 8; dx += 2) {
          final ii = i + dx ~/ 2;
          if (ii >= cols) break;
          lift = math.max(lift, _elev[j * cols + ii] - _elev[k]);
        }
        final h = 0.55 * base +
            0.3 * seaNear +
            water +
            0.12 * (1 - _elev[k]) +
            0.3 * lift.clamp(0.0, 0.5) -
            shadow +
            0.05 * (fbm(p, 30, 2, 23) - 0.5);
        _hum[k] = (h * (base < 0.2 ? 0.75 : 1)).clamp(0.0, 1.0);
      }
    }
  }

  static double _biomeWarmth(String biome) => switch (biome) {
        'frost' => -12,
        'desert' => 9,
        'arid_coast' => 5,
        'ashlands' => 3,
        'volcanic' => 6,
        'fen' => -1,
        'sea_cliffs' => -2,
        'tear' => -5,
        _ => 0,
      };

  void _warmth() {
    final g = geography;
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final k = j * cols + i;
        final p = Offset((i + 0.5) * cell, (j + 0.5) * cell);
        final (_, lat) = GlobeView.lonLatOf(p);
        final latNorm = (lat.abs() / (GlobeView.latSpan / 2)).clamp(0.0, 1.0);
        var t = 24 - 26 * latNorm * latNorm;
        if (_land[k] == 1) {
          t += _biomeWarmth(_biomeOfZone(g, _zone[k]));
          t -= 20 * _elev[k];
          // Inland the days are warmer than on the coast.
          t += 1.5 * (1 - math.exp(-_coast[k] / 30));
        } else {
          t = t * 0.85 + 1;
        }
        _warm[k] = t;
      }
    }
  }

  // ------------------------------------------------------------- sample

  double _at(Float32List field, Offset p) {
    final x = (p.dx / cell - 0.5).clamp(0.0, cols - 1.0);
    final y = (p.dy / cell - 0.5).clamp(0.0, rows - 1.0);
    final i = x.floor(), j = y.floor();
    final i1 = math.min(i + 1, cols - 1), j1 = math.min(j + 1, rows - 1);
    final fx = x - i, fy = y - j;
    final a = field[j * cols + i], b = field[j * cols + i1];
    final c = field[j1 * cols + i], d = field[j1 * cols + i1];
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy;
  }

  bool isLand(Offset p) {
    final i = (p.dx / cell).floor().clamp(0, cols - 1);
    final j = (p.dy / cell).floor().clamp(0, rows - 1);
    return _land[j * cols + i] == 1;
  }

  String biomeAt(Offset p) {
    final i = (p.dx / cell).floor().clamp(0, cols - 1);
    final j = (p.dy / cell).floor().clamp(0, rows - 1);
    return _biomeOfZone(geography, _zone[j * cols + i]);
  }

  double elevationAt(Offset p) => isLand(p) ? _at(_elev, p) : 0;
  double humidityAt(Offset p) => _at(_hum, p);

  /// Distance to the coast in chart units: positive on land, negative at
  /// sea.
  double coastAt(Offset p) => _at(_coast, p);

  /// The season's swing on [day]: the story's year turns in ninety days,
  /// and each day is a little warmer or colder than the last.
  static double seasonOf(double day) =>
      5 * math.sin(2 * math.pi * day / 90) + 2 * (_hash(day.floor()) - 0.5);

  double temperatureAt(Offset p, {double day = 1}) =>
      _at(_warm, p) + seasonOf(day);

  ClimateSample sample(Offset p, {int day = 1}) => ClimateSample(
        elevation: elevationAt(p),
        humidity: humidityAt(p),
        temperature: temperatureAt(p, day: day.toDouble()),
        sea: !isLand(p),
        biome: isLand(p) ? biomeAt(p) : '',
      );

  // ------------------------------------------------------------ weather

  /// Where the wind blows at [p] at time [t] (days): westerlies in the
  /// temperate bands, easterlies about the equator, with the day's turn.
  (double, double) windAt(Offset p, double t) {
    final (_, lat) = GlobeView.lonLatOf(p);
    final band = _tanh((lat.abs() - 0.36) / 0.14);
    final dx = band * 62 + 18 * math.cos(0.31 * t);
    final dy = 24 * 0.23 * math.cos(0.23 * t + lat * 3) +
        10 * 0.71 * math.cos(0.71 * t);
    return (math.atan2(dy, dx), math.sqrt(dx * dx + dy * dy));
  }

  /// How far the air at [p] has been carried by time [t].
  Offset _drift(Offset p, double t) {
    final (_, lat) = GlobeView.lonLatOf(p);
    final band = _tanh((lat.abs() - 0.36) / 0.14);
    return Offset(band * 62 * t + 18 / 0.31 * math.sin(0.31 * t),
        24 * math.sin(0.23 * t + lat * 3) + 10 * math.sin(0.71 * t));
  }

  /// How wet the air is over [p] for the clouds' sake: the sea counts
  /// as a wet land, no more, or the sky over it would never clear.
  double _wetAt(Offset p) => isLand(p) ? humidityAt(p) : 0.6;

  /// Cloud cover at [p] at time [t], 0 to 1: banks of cloud carried on
  /// the wind, gathering where the air is wet, rare over the dry lands.
  double cloudAt(Offset p, double t) {
    final q = p - _drift(p, t);
    final n = fbm(q, 30, 3, 101, z: t * 0.3);
    final lo = 0.66 - 0.22 * _wetAt(p);
    return _smooth(lo, lo + 0.2, n);
  }

  WeatherSample weather(Offset p, double t) {
    final climate = sample(p, day: t.floor());
    final cloud = cloudAt(p, t);
    final gust = fbm(p - _drift(p, t) * 1.6, 34, 2, 303, z: t * 0.2);
    final wet = _wetAt(p);
    // Only the heavy cloud over wet enough air lets anything fall.
    final fall = _smooth(0.5, 0.95, cloud) * _smooth(0.15, 0.55, wet);
    final (angle, speed) = windAt(p, t);
    WeatherKind kind;
    if (!climate.sea && climate.humidity < 0.3 && gust > 0.6 && cloud < 0.5) {
      kind = climate.biome == 'ashlands' || climate.biome == 'volcanic'
          ? WeatherKind.ash
          : WeatherKind.dust;
    } else if (fall > 0.15) {
      kind = climate.temperature < 0.5 ? WeatherKind.snow : WeatherKind.rain;
    } else if (!climate.sea &&
        climate.humidity > 0.66 &&
        climate.temperature < 14 &&
        cloud < 0.45 &&
        gust > 0.58) {
      kind = WeatherKind.fog;
    } else if (cloud > 0.45) {
      kind = WeatherKind.cloud;
    } else {
      kind = WeatherKind.clear;
    }
    return WeatherSample(
      kind: kind,
      cloud: cloud,
      fall: kind == WeatherKind.dust || kind == WeatherKind.ash
          ? ((gust - 0.6) * 2.5).clamp(0.2, 1.0)
          : fall,
      windAngle: angle,
      windSpeed: speed,
      climate: climate,
    );
  }

  // ----------------------------------------------------------- contours

  /// The lines of equal [value] of the elevation (or, with [humidity],
  /// of the moisture), as chart polylines: marching squares over the
  /// grid, the segments of each cell joined into runs.
  List<List<Offset>> contours(double level, {bool humidity = false}) =>
      _contours['$humidity:$level'] ??= _contoursOf(level, humidity);

  final Map<String, List<List<Offset>>> _contours = {};

  List<List<Offset>> _contoursOf(double level, bool humidity) {
    final field = humidity ? _hum : _elev;
    final segments = <(Offset, Offset)>[];
    Offset corner(int i, int j) => Offset((i + 0.5) * cell, (j + 0.5) * cell);
    double at(int i, int j) => _land[j * cols + i] == 0 && !humidity
        ? 0.0
        : field[j * cols + i].toDouble();
    Offset lerp(Offset a, Offset b, double va, double vb) =>
        a + (b - a) * ((level - va) / (vb - va)).clamp(0.0, 1.0);
    for (var j = 0; j + 1 < rows; j++) {
      for (var i = 0; i + 1 < cols; i++) {
        final v00 = at(i, j), v10 = at(i + 1, j);
        final v01 = at(i, j + 1), v11 = at(i + 1, j + 1);
        final p00 = corner(i, j), p10 = corner(i + 1, j);
        final p01 = corner(i, j + 1), p11 = corner(i + 1, j + 1);
        final code = (v00 >= level ? 1 : 0) |
            (v10 >= level ? 2 : 0) |
            (v11 >= level ? 4 : 0) |
            (v01 >= level ? 8 : 0);
        if (code == 0 || code == 15) continue;
        final top = lerp(p00, p10, v00, v10);
        final right = lerp(p10, p11, v10, v11);
        final bottom = lerp(p01, p11, v01, v11);
        final left = lerp(p00, p01, v00, v01);
        switch (code) {
          case 1 || 14:
            segments.add((left, top));
          case 2 || 13:
            segments.add((top, right));
          case 3 || 12:
            segments.add((left, right));
          case 4 || 11:
            segments.add((right, bottom));
          case 5:
            segments.add((left, top));
            segments.add((right, bottom));
          case 6 || 9:
            segments.add((top, bottom));
          case 7 || 8:
            segments.add((left, bottom));
          case 10:
            segments.add((top, right));
            segments.add((left, bottom));
        }
      }
    }
    return _join(segments);
  }

  /// Joins [segments] end to end into runs.
  static List<List<Offset>> _join(List<(Offset, Offset)> segments) {
    int keyOf(Offset p) => (p.dx * 10).round() * 100000 + (p.dy * 10).round();
    final byStart = <int, List<int>>{};
    for (var s = 0; s < segments.length; s++) {
      (byStart[keyOf(segments[s].$1)] ??= []).add(s);
      (byStart[keyOf(segments[s].$2)] ??= []).add(s);
    }
    final used = List<bool>.filled(segments.length, false);
    final runs = <List<Offset>>[];
    for (var s = 0; s < segments.length; s++) {
      if (used[s]) continue;
      used[s] = true;
      final run = [segments[s].$1, segments[s].$2];
      // Grow at the tail, then at the head.
      for (final atTail in [true, false]) {
        while (true) {
          final end = atTail ? run.last : run.first;
          final next = byStart[keyOf(end)]?.where((n) => !used[n]).firstOrNull;
          if (next == null) break;
          used[next] = true;
          final (a, b) = segments[next];
          final other = keyOf(a) == keyOf(end) ? b : a;
          if (atTail) {
            run.add(other);
          } else {
            run.insert(0, other);
          }
        }
      }
      if (run.length >= 3) runs.add(run);
    }
    return runs;
  }

  /// The whole chart.
  static Rect get bounds =>
      const Rect.fromLTWH(0, 0, worldMapWidth * 1.0, worldMapHeight * 1.0);
}

// ------------------------------------------------------------------ noise

double _hash(int n) {
  var x = (n * 374761393) & 0x7fffffff;
  x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
  return ((x ^ (x >> 16)) & 0xffff) / 0xffff;
}

double _hash3(int x, int y, int z, int seed) =>
    _hash(x * 73856093 ^ y * 19349663 ^ z * 83492791 ^ seed * 2654435761);

double _fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);

/// Value noise at [p] (chart units) on a lattice [scale] wide, 0 to 1;
/// [z] moves through a third dimension (time).
double valueNoise(Offset p, double scale, int seed, {double z = 0}) {
  final x = p.dx / scale, y = p.dy / scale;
  final x0 = x.floor(), y0 = y.floor(), z0 = z.floor();
  final fx = _fade(x - x0), fy = _fade(y - y0), fz = _fade(z - z0);
  double corner(int dx, int dy, int dz) =>
      _hash3(x0 + dx, y0 + dy, z0 + dz, seed);
  double lerp(double a, double b, double t) => a + (b - a) * t;
  final c00 = lerp(corner(0, 0, 0), corner(1, 0, 0), fx);
  final c10 = lerp(corner(0, 1, 0), corner(1, 1, 0), fx);
  final c01 = lerp(corner(0, 0, 1), corner(1, 0, 1), fx);
  final c11 = lerp(corner(0, 1, 1), corner(1, 1, 1), fx);
  return lerp(lerp(c00, c10, fy), lerp(c01, c11, fy), fz);
}

/// Layered value noise, 0 to 1.
double fbm(Offset p, double scale, int octaves, int seed, {double z = 0}) {
  var sum = 0.0, amp = 1.0, total = 0.0;
  var s = scale;
  for (var o = 0; o < octaves; o++) {
    sum += amp * valueNoise(p, s, seed + o * 17, z: z);
    total += amp;
    amp *= 0.5;
    s *= 0.5;
  }
  return sum / total;
}

double _smooth(double lo, double hi, double x) {
  final t = ((x - lo) / (hi - lo)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _tanh(double x) {
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}
