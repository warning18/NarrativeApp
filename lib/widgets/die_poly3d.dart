// The d4, d8, d10, d12 and d20 as real solids in perspective (v1.903): each
// facet is a flat polygon placed by a 4x4 matrix (the way the d6's cube is
// built in die_3d.dart: the turn, the facet's place, the perspective), the
// far ones culled, the near ones lit by the same lamp. A facet that stands
// within about 65 degrees of the viewer and is big enough carries its own
// face's glyph (a skill's icon, or a type icon over its value); the others
// show the face's colour only, so what is on them still reads as a kind.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'die_3d.dart'
    show DieCubeFace, dieRestTipX, dieRestTurnY, dieUnrolledMark;
import 'die_skins.dart';
import 'die_solids.dart';
import 'poly_die.dart' show DieShape;

const double _perspective = 0.0016;
const double _tumbleTurns = 2.5;

/// How big a die of each shape is drawn against the square it is given: the
/// solids are fuller than a cube and a d20's facets are small, so the bigger
/// sizes are drawn bigger (they overflow the square, which does not clip).
double dieSolidScale(DieShape shape) => switch (shape) {
      DieShape.d4 => 1.2,
      DieShape.d8 => 1.25,
      DieShape.d10 => 1.3,
      DieShape.d12 => 1.4,
      DieShape.d20 => 1.5,
      _ => 1.0,
    };

/// The least side, in logical pixels, a facet's glyph box may have to be
/// drawn (a plaque smaller than this does not read).
const double dieGlyphMinSide = 12;

/// The widest angle from the viewer at which a facet still carries its glyph.
final double dieGlyphCosLimit = math.cos(65 * math.pi / 180);

class PolyDie3D extends StatelessWidget {
  const PolyDie3D({
    super.key,
    required this.shape,
    required this.faces,
    required this.skin,
    required this.size,
    required this.t,
    this.showGlyphs = true,
    this.unrolled = false,
    this.landed = false,
  });

  final DieShape shape;

  /// One entry per facet, the landed face first.
  final List<DieCubeFace> faces;
  final DieSkin skin;

  /// The square the die is drawn for; the solid is [dieSolidScale] of it.
  final double size;

  /// The roll's progress, 0 to 1 (1 at rest).
  final double t;
  final bool showGlyphs;

  /// Not rolled yet: the front facet shows a "?" and the others no glyph.
  final bool unrolled;

  /// At rest on the face it rolled: that facet (the first) is ringed and lit,
  /// the others a little dimmer, so the result reads at a glance.
  final bool landed;

  @override
  Widget build(BuildContext context) {
    final solid = dieSolidOf(shape)!;
    final radius = size * dieSolidScale(shape) / 2;
    final e = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final spin = (1 - e) * _tumbleTurns * 2 * math.pi;
    final model = Matrix4.identity()
      ..rotateX(spin * 0.9)
      ..rotateY(spin * 1.3)
      ..rotateZ(spin * 0.35)
      ..rotateX(dieRestTipX)
      ..rotateY(dieRestTurnY)
      ..multiply(_rest(solid));
    final m = model.storage;
    Vec3 rot(Vec3 p) => [
          m[0] * p[0] + m[4] * p[1] + m[8] * p[2],
          m[1] * p[0] + m[5] * p[1] + m[9] * p[2],
          m[2] * p[0] + m[6] * p[1] + m[10] * p[2],
        ];
    const eye = -1 / _perspective;
    final placed = <(double, Widget)>[];
    for (var i = 0; i < solid.faces.length; i++) {
      final c = solid.centre(i);
      final n = _outward(solid, i, c);
      final nr = rot(n);
      final cr = rot([c[0] * radius, c[1] * radius, c[2] * radius]);
      // Facing the viewer: the normal points against the way to the eye.
      if (vdot(nr, [cr[0], cr[1], cr[2] - eye]) >= 0) continue;
      final lit = vdot(nr, const [-0.35, -0.55, -0.76]).clamp(0.0, 1.0);
      final light = 0.45 + 0.55 * lit;
      final u = vnorm(vsub(solid.verts[solid.faces[i][0]], c));
      final v = vcross(u, n);
      final pts = [
        for (final k in solid.faces[i])
          Offset(vdot(vsub(solid.verts[k], c), u) * radius,
              vdot(vsub(solid.verts[k], c), v) * radius)
      ];
      final r = pts.map((p) => p.distance).reduce(math.max);
      final box = _inradius(pts) * 1.7;
      final facing = -nr[2];
      final glyph =
          showGlyphs && facing >= dieGlyphCosLimit && box >= dieGlyphMinSide
              ? box
              : 0.0;
      final basis = Matrix4(u[0], u[1], u[2], 0, v[0], v[1], v[2], 0, n[0],
          n[1], n[2], 0, c[0] * radius, c[1] * radius, c[2] * radius, 1);
      final matrix = (Matrix4.identity()..setEntry(3, 2, _perspective))
          .multiplied(model)
          .multiplied(basis)
          .multiplied(Matrix4.translationValues(-r, -r, 0));
      final face = unrolled && i == 0
          ? DieCubeFace(glyph: dieUnrolledMark(), color: faces[0].color)
          : faces[i % faces.length];
      final local = [for (final p in pts) p + Offset(r, r)];
      placed.add((
        cr[2],
        Positioned(
          left: size / 2,
          top: size / 2,
          child: Transform(
            transform: matrix,
            child: _Facet(
              side: 2 * r,
              points: local,
              face: face,
              skin: skin,
              light: light,
              glyphBox: glyph,
              front: landed && i == 0,
              muted: landed && i != 0,
            ),
          ),
        ),
      ));
    }
    placed.sort((a, b) => b.$1.compareTo(a.$1));
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [for (final p in placed) p.$2],
      ),
    );
  }
}

/// The turn that brings facet 0 square to the viewer, a corner up.
Matrix4 _rest(DieSolid s) {
  final c = s.centre(0);
  final n = _outward(s, 0, c);
  final u = vnorm(vsub(s.verts[s.faces[0][0]], c));
  final v = vcross(u, n);
  return Matrix4(u[0], v[0], -n[0], 0, u[1], v[1], -n[1], 0, u[2], v[2], -n[2],
      0, 0, 0, 0, 1);
}

/// Facet [i]'s unit normal, pointing out of the solid.
Vec3 _outward(DieSolid s, int i, Vec3 c) {
  final f = s.faces[i];
  var n = vnorm(vcross(
      vsub(s.verts[f[1]], s.verts[f[0]]), vsub(s.verts[f[2]], s.verts[f[0]])));
  if (vdot(n, c) < 0) n = [-n[0], -n[1], -n[2]];
  return n;
}

/// The radius of the circle a facet's corners (about its centre) leave room
/// for: the nearest edge.
double _inradius(List<Offset> pts) {
  var best = double.infinity;
  for (var i = 0; i < pts.length; i++) {
    final a = pts[i];
    final b = pts[(i + 1) % pts.length];
    final d = b - a;
    final dist = (a.dx * d.dy - a.dy * d.dx).abs() / d.distance;
    best = math.min(best, dist);
  }
  return best;
}

class _Facet extends StatelessWidget {
  const _Facet({
    required this.side,
    required this.points,
    required this.face,
    required this.skin,
    required this.light,
    required this.glyphBox,
    this.front = false,
    this.muted = false,
  });

  final double side;
  final List<Offset> points;
  final DieCubeFace face;
  final DieSkin skin;
  final double light;
  final double glyphBox;
  final bool front;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final fill =
        Color.alphaBlend(face.color.withValues(alpha: 0.28), skin.base);
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
              painter: _FacetPainter(points, fill, skin.edge,
                  muted ? 1 - light * 0.7 : 1 - light, front)),
          if (glyphBox > 0)
            Center(
              child: Opacity(
                opacity: 0.55 + 0.45 * light,
                child: SizedBox(
                  width: glyphBox,
                  height: glyphBox,
                  child: FittedBox(fit: BoxFit.contain, child: face.glyph),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FacetPainter extends CustomPainter {
  _FacetPainter(this.points, this.fill, this.edge, this.shade, this.front);

  final List<Offset> points;
  final Color fill;
  final Color edge;

  /// 0 (lit) to 1 (dark): the lamp's shade.
  final double shade;

  /// The facet the die landed on: a bright ring and a soft glow.
  final bool front;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
        path, Paint()..color = Colors.black.withValues(alpha: shade * 0.62));
    if (front) {
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.16)
            ..style = PaintingStyle.fill);
      canvas.drawPath(
          path,
          Paint()
            ..color = edge.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeJoin = StrokeJoin.round);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = front ? Color.lerp(edge, Colors.white, 0.45)! : edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = front ? 3.2 : 1.8
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_FacetPainter old) =>
      old.points != points ||
      old.fill != fill ||
      old.edge != edge ||
      old.shade != shade ||
      old.front != front;
}
