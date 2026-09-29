import 'dart:ui' show Offset, Rect;

/// The land under the Journey map: a gentle height field, the same on
/// every visit, drawn as contour lines, a few peaks and their shade.
///
/// Heights are read in map points. The map moves the land with the party
/// (see JourneyScreen), so a point keeps its height as the party walks on.

/// The height of the land at ([x], [y]), from 0 (low) to 1 (high): two
/// layers of smooth noise, a broad one for the hills and a finer one for
/// their shoulders.
double reliefHeight(double x, double y, {int seed = 7}) {
  final broad = _valueNoise(x / 190, y / 190, seed);
  final fine = _valueNoise(x / 74, y / 74, seed + 31);
  return (broad * 0.74 + fine * 0.26).clamp(0.0, 1.0);
}

/// The contour levels drawn, low to high. Every other one from the
/// second is an index line, drawn a little stronger.
const List<double> reliefLevels = [0.42, 0.52, 0.62, 0.72];

/// The contour line at [level] across [area]: the segments where the
/// height crosses it, found on a grid of [cell] points (marching squares,
/// each crossing placed by linear interpolation along the cell's edge).
List<(Offset, Offset)> reliefContour({
  required Rect area,
  required double level,
  required double Function(double x, double y) height,
  double cell = 14,
}) {
  final columns = (area.width / cell).ceil() + 1;
  final rows = (area.height / cell).ceil() + 1;
  // Heights at the grid's corners, read once.
  final h = List.generate(
    rows,
    (r) => List.generate(
      columns,
      (c) => height(area.left + c * cell, area.top + r * cell),
    ),
  );
  final segments = <(Offset, Offset)>[];
  Offset point(int r, int c) =>
      Offset(area.left + c * cell, area.top + r * cell);
  Offset cross(int r0, int c0, int r1, int c1) {
    final a = h[r0][c0], b = h[r1][c1];
    final t = (a == b) ? 0.5 : ((level - a) / (b - a)).clamp(0.0, 1.0);
    final p = point(r0, c0), q = point(r1, c1);
    return Offset(p.dx + (q.dx - p.dx) * t, p.dy + (q.dy - p.dy) * t);
  }

  for (var r = 0; r < rows - 1; r++) {
    for (var c = 0; c < columns - 1; c++) {
      // Corners: 0 top-left, 1 top-right, 2 bottom-right, 3 bottom-left.
      final index = (h[r][c] > level ? 8 : 0) |
          (h[r][c + 1] > level ? 4 : 0) |
          (h[r + 1][c + 1] > level ? 2 : 0) |
          (h[r + 1][c] > level ? 1 : 0);
      if (index == 0 || index == 15) continue;
      final top = cross(r, c, r, c + 1);
      final right = cross(r, c + 1, r + 1, c + 1);
      final bottom = cross(r + 1, c, r + 1, c + 1);
      final left = cross(r, c, r + 1, c);
      switch (index) {
        case 1 || 14:
          segments.add((left, bottom));
        case 2 || 13:
          segments.add((bottom, right));
        case 3 || 12:
          segments.add((left, right));
        case 4 || 11:
          segments.add((top, right));
        case 5:
          segments.add((left, top));
          segments.add((bottom, right));
        case 6 || 9:
          segments.add((top, bottom));
        case 7 || 8:
          segments.add((left, top));
        case 10:
          segments.add((top, right));
          segments.add((left, bottom));
      }
    }
  }
  return segments;
}

/// The hilltops in [area]: points of a [spacing]-point grid higher than
/// [above] and than every neighbour around them.
List<Offset> reliefPeaks({
  required Rect area,
  required double Function(double x, double y) height,
  double spacing = 30,
  double above = 0.7,
}) {
  final peaks = <Offset>[];
  final x0 = (area.left / spacing).floor(), x1 = (area.right / spacing).ceil();
  final y0 = (area.top / spacing).floor(), y1 = (area.bottom / spacing).ceil();
  for (var gy = y0; gy <= y1; gy++) {
    for (var gx = x0; gx <= x1; gx++) {
      final here = height(gx * spacing, gy * spacing);
      if (here <= above) continue;
      var highest = true;
      for (var dy = -1; dy <= 1 && highest; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          if (height((gx + dx) * spacing, (gy + dy) * spacing) >= here) {
            highest = false;
            break;
          }
        }
      }
      if (highest) peaks.add(Offset(gx * spacing, gy * spacing));
    }
  }
  return peaks;
}

double _valueNoise(double x, double y, int seed) {
  final xi = x.floor(), yi = y.floor();
  final xf = x - xi, yf = y - yi;
  final u = xf * xf * (3 - 2 * xf);
  final v = yf * yf * (3 - 2 * yf);
  final top = _lerp(_hash(xi, yi, seed), _hash(xi + 1, yi, seed), u);
  final bottom = _lerp(_hash(xi, yi + 1, seed), _hash(xi + 1, yi + 1, seed), u);
  return _lerp(top, bottom, v);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// A value from 0 to 1 for the lattice point ([x], [y]), the same on every
/// device (kept within 31 bits so no platform's integers overflow
/// differently).
double _hash(int x, int y, int seed) {
  var h = (x * 73856093) ^ (y * 19349663) ^ (seed * 83492791);
  h &= 0x7fffffff;
  h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff;
  h ^= h >> 16;
  return (h & 0xffffff) / 0xffffff;
}
