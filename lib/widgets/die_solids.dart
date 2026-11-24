// The solids of the dice that are not cubes, as real geometry (v1.903): the
// corners and the facets of a d4, d8, d10, d12 and d20, each on a unit
// sphere, so a die can turn in 3D and every facet can carry its own face.
// Pure data and maths, no widgets (see die_poly3d.dart for the drawing).
import 'dart:math' as math;

import 'poly_die.dart' show DieShape;

typedef Vec3 = List<double>;

Vec3 vsub(Vec3 a, Vec3 b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
Vec3 vcross(Vec3 a, Vec3 b) => [
      a[1] * b[2] - a[2] * b[1],
      a[2] * b[0] - a[0] * b[2],
      a[0] * b[1] - a[1] * b[0],
    ];
double vdot(Vec3 a, Vec3 b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
Vec3 vnorm(Vec3 a) {
  final l = math.sqrt(vdot(a, a));
  return [a[0] / l, a[1] / l, a[2] / l];
}

/// A convex solid: its corners and its facets (each a cycle of corner
/// indices).
class DieSolid {
  const DieSolid(this.verts, this.faces);

  final List<Vec3> verts;
  final List<List<int>> faces;

  /// The centre of facet [i].
  Vec3 centre(int i) {
    final f = faces[i];
    final c = [0.0, 0.0, 0.0];
    for (final v in f) {
      for (var a = 0; a < 3; a++) {
        c[a] += verts[v][a] / f.length;
      }
    }
    return c;
  }
}

DieSolid _unit(List<Vec3> v, List<List<int>> f) {
  var r = 0.0;
  for (final p in v) {
    r = math.max(r, math.sqrt(vdot(p, p)));
  }
  return DieSolid([
    for (final p in v) [p[0] / r, p[1] / r, p[2] / r]
  ], f);
}

DieSolid _tetra() => _unit([
      [1, 1, 1],
      [1, -1, -1],
      [-1, 1, -1],
      [-1, -1, 1],
    ], [
      [0, 1, 2],
      [0, 3, 1],
      [0, 2, 3],
      [1, 3, 2],
    ]);

DieSolid _octa() {
  final f = <List<int>>[];
  for (final x in [0, 1]) {
    for (final y in [2, 3]) {
      for (final z in [4, 5]) {
        f.add([x, y, z]);
      }
    }
  }
  return _unit([
    [1, 0, 0],
    [-1, 0, 0],
    [0, 1, 0],
    [0, -1, 0],
    [0, 0, 1],
    [0, 0, -1],
  ], f);
}

DieSolid _icosa() {
  final p = (1 + math.sqrt(5)) / 2;
  final v = <Vec3>[];
  for (final a in [-1.0, 1.0]) {
    for (final b in [-p, p]) {
      v
        ..add([0, a, b])
        ..add([a, b, 0])
        ..add([b, 0, a]);
    }
  }
  double d(int i, int j) {
    final s = vsub(v[i], v[j]);
    return vdot(s, s);
  }

  var edge = double.infinity;
  for (var i = 1; i < v.length; i++) {
    edge = math.min(edge, d(0, i));
  }
  final f = <List<int>>[];
  for (var i = 0; i < v.length; i++) {
    for (var j = i + 1; j < v.length; j++) {
      for (var k = j + 1; k < v.length; k++) {
        if ((d(i, j) - edge).abs() < 1e-6 &&
            (d(j, k) - edge).abs() < 1e-6 &&
            (d(i, k) - edge).abs() < 1e-6) {
          f.add([i, j, k]);
        }
      }
    }
  }
  return _unit(v, f);
}

/// The dual: one facet for each corner of [s], through the centres of the
/// facets that meet there (the d12 from the d20).
DieSolid _dual(DieSolid s) {
  final verts = [
    for (var i = 0; i < s.faces.length; i++) vnorm(s.centre(i)),
  ];
  final faces = <List<int>>[];
  for (var c = 0; c < s.verts.length; c++) {
    final axis = vnorm(s.verts[c]);
    final around = [
      for (var i = 0; i < s.faces.length; i++)
        if (s.faces[i].contains(c)) i
    ];
    final a = vnorm(vsub(verts[around.first],
        [for (final x in axis) x * vdot(verts[around.first], axis)]));
    final b = vcross(axis, a);
    around.sort((p, q) => math
        .atan2(vdot(verts[p], b), vdot(verts[p], a))
        .compareTo(math.atan2(vdot(verts[q], b), vdot(verts[q], a))));
    faces.add(around);
  }
  return _unit(verts, faces);
}

/// The pentagonal trapezohedron: ten kites round two apexes.
DieSolid _trapezohedron() {
  const a = 0.22;
  Vec3 ring(int k) =>
      [math.cos(k * math.pi / 5), math.sin(k * math.pi / 5), k.isEven ? a : -a];
  // The apex height that makes each kite flat: the axis meets the plane
  // through three of the ring's corners.
  final p0 = ring(0);
  final n = vcross(vsub(ring(1), p0), vsub(ring(2), p0));
  final h = p0[2] + (n[0] * p0[0] + n[1] * p0[1]) / n[2];
  final v = <Vec3>[
    [0, 0, h],
    [0, 0, -h],
    for (var k = 0; k < 10; k++) ring(k),
  ];
  final f = <List<int>>[];
  for (var i = 0; i < 5; i++) {
    f.add([0, 2 + 2 * i, 2 + (2 * i + 1) % 10, 2 + (2 * i + 2) % 10]);
    f.add(
        [1, 2 + (2 * i + 3) % 10, 2 + (2 * i + 2) % 10, 2 + (2 * i + 1) % 10]);
  }
  return _unit(v, f);
}

final Map<DieShape, DieSolid> _cache = {};

/// The solid of [shape]; null for the coin and the cube (flat and cube
/// drawings own those).
DieSolid? dieSolidOf(DieShape shape) => switch (shape) {
      DieShape.d4 => _cache.putIfAbsent(shape, _tetra),
      DieShape.d8 => _cache.putIfAbsent(shape, _octa),
      DieShape.d10 => _cache.putIfAbsent(shape, _trapezohedron),
      DieShape.d12 =>
        _cache.putIfAbsent(shape, () => _dual(dieSolidOf(DieShape.d20)!)),
      DieShape.d20 => _cache.putIfAbsent(shape, _icosa),
      _ => null,
    };
