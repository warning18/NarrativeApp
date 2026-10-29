// The dice that are not cubes (docs/proposals/dice-looks.md): a d4, d8, d10,
// d12, d20 and the coin drawn as flat-shaded polygons, one set of facets for
// each shape, the front facet carrying the face that rolled. It wears the
// same skin as the cube (stone, edge, the mark cut into the front facet, the
// light some give off) and, when the die is a clan's gift, the clan's banner.
//
// The roll is cheap on purpose: no real 3D, one painter of at most ten
// facets, a turn, a squeeze for the tumble and a squash at the bounce.
// Larger dice roll longer ([dieRollDuration]): a d20 shown large takes a
// moment to read, a d4 does not.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';
import 'die_art.dart';
import 'die_skins.dart';

/// The shapes of the family. The d6 is the cube of `Die3D`; it is here so a
/// still picture (the rail, the middle of the ring) can draw every size.
enum DieShape { coin, d4, d6, d8, d10, d12, d20 }

/// The shape of a die with [faces] faces: the real sizes (2, 4, 6, 8, 10, 12,
/// 20) and, for any other count, the next size up (a d7 reads as a d8).
DieShape dieShapeOf(int faces) {
  if (faces <= 2) return DieShape.coin;
  if (faces <= 4) return DieShape.d4;
  if (faces <= 6) return DieShape.d6;
  if (faces <= 8) return DieShape.d8;
  if (faces <= 10) return DieShape.d10;
  if (faces <= 12) return DieShape.d12;
  return DieShape.d20;
}

/// How long a die of [faces] faces rolls: the coin and the d4 are quick, the
/// d20 takes its time. A tap on the roll skips to the end (the widgets that
/// roll a die offer it).
Duration dieRollDuration(int faces) => switch (dieShapeOf(faces)) {
      DieShape.coin => const Duration(milliseconds: 600),
      DieShape.d4 => const Duration(milliseconds: 700),
      DieShape.d6 => const Duration(milliseconds: 900),
      DieShape.d8 => const Duration(milliseconds: 1000),
      DieShape.d10 => const Duration(milliseconds: 1150),
      DieShape.d12 => const Duration(milliseconds: 1300),
      DieShape.d20 => const Duration(milliseconds: 1500),
    };

/// The banner a clan's gift die wears on its front: the clan's colour.
class DieClan {
  const DieClan(this.id, this.color);

  final String id;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is DieClan && other.id == id && other.color == color;

  @override
  int get hashCode => Object.hash(id, color);
}

/// One facet of a shape: its corners in the unit square.
class _Facet {
  const _Facet(this.points);

  final List<Offset> points;

  Offset get centroid {
    var x = 0.0;
    var y = 0.0;
    for (final p in points) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / points.length, y / points.length);
  }
}

/// A shape's facets, the index of the one that faces the viewer, and where
/// the clan's banner hangs.
class _Solid {
  const _Solid(this.facets, this.front);

  final List<_Facet> facets;
  final int front;
}

List<Offset> _ring(int n, double radius, double start, [Offset? centre]) => [
      for (var i = 0; i < n; i++)
        Offset(
          (centre?.dx ?? 0.5) + radius * math.cos(start + 2 * math.pi * i / n),
          (centre?.dy ?? 0.52) + radius * math.sin(start + 2 * math.pi * i / n),
        ),
    ];

_Solid _build(DieShape shape) {
  switch (shape) {
    case DieShape.d4:
      const a = Offset(0.5, 0.04);
      const l = Offset(0.03, 0.9);
      const r = Offset(0.97, 0.9);
      const m = Offset(0.52, 0.66);
      return const _Solid([
        _Facet([a, l, m]),
        _Facet([a, m, r]),
        _Facet([l, m, r]),
      ], 2);
    case DieShape.d6:
      return const _Solid([
        _Facet([
          Offset(0.5, 0.04),
          Offset(0.93, 0.26),
          Offset(0.5, 0.48),
          Offset(0.07, 0.26)
        ]),
        _Facet([
          Offset(0.07, 0.26),
          Offset(0.5, 0.48),
          Offset(0.5, 0.96),
          Offset(0.07, 0.74)
        ]),
        _Facet([
          Offset(0.5, 0.48),
          Offset(0.93, 0.26),
          Offset(0.93, 0.74),
          Offset(0.5, 0.96)
        ]),
      ], 2);
    case DieShape.d8:
      const t = Offset(0.5, 0.02);
      const l = Offset(0.04, 0.5);
      const r = Offset(0.96, 0.5);
      const b = Offset(0.5, 0.98);
      const f = Offset(0.5, 0.6);
      return const _Solid([
        _Facet([t, l, f]),
        _Facet([t, f, r]),
        _Facet([l, b, f]),
        _Facet([f, b, r]),
      ], 3);
    case DieShape.d10:
      const t = Offset(0.5, 0.0);
      const l = Offset(0.1, 0.4);
      const r = Offset(0.9, 0.4);
      const b = Offset(0.5, 1.0);
      const m = Offset(0.5, 0.5);
      const kl = Offset(0.27, 0.72);
      const kr = Offset(0.73, 0.72);
      return const _Solid([
        _Facet([t, l, m]),
        _Facet([t, m, r]),
        _Facet([l, kl, m]),
        _Facet([kl, b, m]),
        _Facet([m, b, kr]),
        _Facet([m, kr, r]),
      ], 4);
    case DieShape.d12:
      final outer = _ring(5, 0.49, -math.pi / 2);
      final inner = _ring(5, 0.25, -math.pi / 2);
      return _Solid([
        _Facet(inner),
        for (var i = 0; i < 5; i++)
          _Facet([
            outer[i],
            outer[(i + 1) % 5],
            inner[(i + 1) % 5],
            inner[i],
          ]),
      ], 0);
    case DieShape.d20:
      final h = _ring(6, 0.5, -math.pi / 2);
      final i3 = _ring(3, 0.27, -math.pi / 2);
      return _Solid([
        _Facet(i3),
        for (var j = 0; j < 3; j++)
          _Facet([i3[j], h[2 * j + 1], i3[(j + 1) % 3]]),
        for (var j = 0; j < 3; j++) ...[
          _Facet([i3[j], h[(2 * j + 5) % 6], h[2 * j]]),
          _Facet([i3[j], h[2 * j], h[2 * j + 1]]),
        ],
      ], 0);
    case DieShape.coin:
      return const _Solid([], 0);
  }
}

/// The outermost points of a shape in the art's unit disc (centre
/// (0.5, 0.51), radius 0.49 of the die): where spikes and crowns go.
final Map<DieShape, List<Offset>> _corners = {};

List<Offset> _cornersOf(DieShape shape) => _corners.putIfAbsent(shape, () {
      final out = <Offset>[];
      for (final f in _solids[shape]!.facets) {
        for (final p in f.points) {
          final q = Offset((p.dx - 0.5) / 0.49, (p.dy - 0.51) / 0.49);
          if (q.distance > 0.82 && !out.any((o) => (o - q).distance < 0.1)) {
            out.add(q);
          }
        }
      }
      return out;
    });

final Map<DieShape, _Solid> _solids = {
  for (final s in DieShape.values) s: _build(s),
};

/// [c] lightened toward white by [k], or darkened toward black when [k] < 0.
Color _shade(Color c, double k) =>
    Color.lerp(c, k >= 0 ? Colors.white : Colors.black, k.abs().clamp(0, 1))!;

/// A die that is not a cube, [size] across.
///
/// [roll] is the roll's progress, 0 to 1 (the die is at rest at 1); null at
/// rest. [label] is what stands on the front facet once the die has settled.
class PolyDie extends StatelessWidget {
  const PolyDie({
    super.key,
    required this.shape,
    this.size = 56,
    this.skin,
    this.label,
    this.glyph,
    this.roll,
    this.progress,
    this.still = false,
    this.dim = false,
    this.clan,
    this.dieId,
    this.glowing = true,
  });

  final DieShape shape;
  final double size;

  /// The die's stone, edge, mark and glow; null for bone.
  final DieSkin? skin;

  /// The number (or short word) on the front facet, drawn in the die's
  /// edge colour.
  final String? label;

  /// A widget on the front facet in place of [label] (a skill's icon).
  final Widget? glyph;
  final Animation<double>? roll;

  /// The roll's progress when something else runs the clock (`Die3D`);
  /// null for at rest.
  final double? progress;

  /// Reduced motion: no tumble, whatever [roll] says.
  final bool still;
  final bool dim;
  final DieClan? clan;

  /// The die's id (dice.json key): its art is drawn over it (see die_art.dart).
  final String? dieId;

  /// Whether the die gives off its own light (a glow behind it). `Die3D`
  /// draws the glow itself and turns this off.
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    final skin = this.skin ?? boneSkin;
    final animation = roll;
    final tumbling = animation != null && !still;
    Widget body(double t) => _body(skin, t);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (glowing && skin.glow != null && !dim)
            Positioned(
              left: -size * 0.45,
              top: -size * 0.45,
              width: size * 1.9,
              height: size * 1.9,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      skin.glow!.withValues(alpha: 0.30),
                      skin.glow!.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
            ),
          Opacity(
            opacity: dim ? 0.55 : 1,
            child: tumbling
                ? AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) => body(animation.value),
                  )
                : body(progress ?? 1),
          ),
        ],
      ),
    );
  }

  Widget _body(DieSkin skin, double t) {
    final settled = t >= 0.78;
    final frontLabel = settled ? label : null;
    final painter = PolyDiePainter(
      shape: shape,
      skin: skin,
      t: t,
      label: frontLabel,
      clan: clan,
      dieId: dieId,
    );
    final spot = PolyDiePainter.frontSpot(shape);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              key: const ValueKey('poly_die'),
              painter: painter,
            ),
          ),
          if (glyph != null && settled)
            Positioned(
              left: (spot.dx - spot.side / 2) * size,
              top: (spot.dy - spot.side / 2) * size,
              width: spot.side * size,
              height: spot.side * size,
              child: FittedBox(fit: BoxFit.scaleDown, child: glyph),
            ),
        ],
      ),
    );
  }
}

/// Where the front facet's mark sits: its centre and the side of the square
/// the mark fits in, as fractions of the die's size.
typedef FrontSpot = ({double dx, double dy, double side});

class PolyDiePainter extends CustomPainter {
  const PolyDiePainter({
    required this.shape,
    required this.skin,
    required this.t,
    this.label,
    this.clan,
    this.dieId,
  });

  final DieShape shape;
  final DieSkin skin;

  /// The roll's progress (1 at rest).
  final double t;
  final String? label;
  final DieClan? clan;
  final String? dieId;

  static FrontSpot frontSpot(DieShape shape) {
    switch (shape) {
      case DieShape.coin:
        return (dx: 0.5, dy: 0.5, side: 0.5);
      case DieShape.d4:
        return (dx: 0.52, dy: 0.78, side: 0.26);
      case DieShape.d6:
        return (dx: 0.72, dy: 0.62, side: 0.3);
      case DieShape.d8:
        return (dx: 0.62, dy: 0.7, side: 0.26);
      case DieShape.d10:
        return (dx: 0.52, dy: 0.72, side: 0.22);
      case DieShape.d12:
        return (dx: 0.5, dy: 0.52, side: 0.34);
      case DieShape.d20:
        return (dx: 0.5, dy: 0.57, side: 0.26);
    }
  }

  /// The turn, the squeeze and the squash of the roll [t] of the way through.
  Matrix4 _motion(Size size) {
    final e = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final spin = (1 - e) * 2.5 * 2 * math.pi;
    final bounce =
        t > 0.7 && t < 0.86 ? math.sin((t - 0.7) / 0.16 * math.pi) * 0.08 : 0.0;
    var sx = 1 - 0.34 * math.sin(spin * 1.3).abs() * (1 - e);
    final sy = 1 - 0.22 * math.sin(spin * 0.9).abs() * (1 - e) - bounce;
    if (shape == DieShape.coin) {
      // Edge-on twice, then flat.
      sx = math.max(0.1, math.cos(spin * 1.6).abs()) * (1 - e) + e;
    }
    final m = Matrix4.identity()
      ..translateByDouble(size.width / 2, size.height * 0.5 + bounce * 40, 0, 1)
      ..rotateZ(spin * 0.35 * (shape == DieShape.coin ? 0.0 : 1.0))
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
    return m;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(_motion(size).storage);
    paintDieHalo(canvas, size, dieId);
    final unit = size.width;
    final line = (unit / 36).clamp(1.0, 2.4);
    Offset at(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = line
      ..color = skin.edge;
    if (shape == DieShape.coin) {
      _paintCoin(canvas, size, edge, line);
    } else {
      final solid = _solids[shape]!;
      final outline = Path();
      for (var i = 0; i < solid.facets.length; i++) {
        final f = solid.facets[i];
        final path = Path()
          ..addPolygon([for (final p in f.points) at(p)], true);
        final c = f.centroid;
        // The lamp is up and to the left: facets turned toward it are lit.
        var k = -0.62 * ((c.dx - 0.5) * 0.7 + (c.dy - 0.52) * 0.9);
        if (i == solid.front) k += 0.05;
        canvas.drawPath(path, Paint()..color = _shade(skin.base, k));
        if (i == solid.front) {
          canvas.save();
          canvas.clipPath(path);
          final box = path.getBounds();
          canvas.translate(box.left, box.top);
          DiePatternPainter(skin.pattern,
                  Color.lerp(skin.edge, skin.base, 0.25)!, 7 + shape.index)
              .paint(canvas, box.size);
          canvas.restore();
        }
        outline.addPath(path, Offset.zero);
        canvas.drawPath(path, edge..strokeWidth = line * 0.8);
      }
      canvas.drawPath(outline, edge..strokeWidth = line * 0.8);
      _paintOutline(canvas, size, solid, edge, line);
    }
    paintDieArt(canvas, size, dieId, skin, _cornersOf(shape));
    final text = label;
    if (text != null && text.isNotEmpty) {
      final spot = frontSpot(shape);
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: skin.edge,
            fontFamily: InkFonts.system,
            fontSize: spot.side * size.width * (text.length > 1 ? 0.95 : 1.15),
            fontWeight: FontWeight.w800,
            height: 1,
            shadows: [
              Shadow(
                  color: skin.base.withValues(alpha: 0.9),
                  blurRadius: size.width * 0.04),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
          canvas,
          Offset(spot.dx * size.width - painter.width / 2,
              spot.dy * size.height - painter.height / 2));
    }
    final mark = clan;
    if (mark != null) _paintBanner(canvas, size, mark);
    canvas.restore();
  }

  /// The silhouette, a little heavier than the inner edges.
  void _paintOutline(
      Canvas canvas, Size size, _Solid solid, Paint edge, double line) {
    final pts = <Offset>[];
    switch (shape) {
      case DieShape.d4:
        pts.addAll(
            const [Offset(0.5, 0.04), Offset(0.03, 0.9), Offset(0.97, 0.9)]);
      case DieShape.d6:
        pts.addAll(const [
          Offset(0.5, 0.04),
          Offset(0.93, 0.26),
          Offset(0.93, 0.74),
          Offset(0.5, 0.96),
          Offset(0.07, 0.74),
          Offset(0.07, 0.26)
        ]);
      case DieShape.d8:
        pts.addAll(const [
          Offset(0.5, 0.02),
          Offset(0.96, 0.5),
          Offset(0.5, 0.98),
          Offset(0.04, 0.5)
        ]);
      case DieShape.d10:
        pts.addAll(const [
          Offset(0.5, 0.0),
          Offset(0.9, 0.4),
          Offset(0.73, 0.72),
          Offset(0.5, 1.0),
          Offset(0.27, 0.72),
          Offset(0.1, 0.4)
        ]);
      case DieShape.d12:
        pts.addAll(_ring(5, 0.49, -math.pi / 2));
      case DieShape.d20:
        pts.addAll(_ring(6, 0.5, -math.pi / 2));
      case DieShape.coin:
        return;
    }
    canvas.drawPath(
        Path()
          ..addPolygon([
            for (final p in pts) Offset(p.dx * size.width, p.dy * size.height)
          ], true),
        edge..strokeWidth = line * 1.5);
  }

  void _paintCoin(Canvas canvas, Size size, Paint edge, double line) {
    final centre = size.center(Offset.zero);
    final r = size.width * 0.46;
    canvas.drawCircle(centre, r, Paint()..color = skin.base);
    canvas.drawCircle(
        centre, r * 0.78, Paint()..color = _shade(skin.base, 0.08));
    canvas.drawCircle(centre, r, edge..strokeWidth = line * 1.5);
    canvas.drawCircle(centre, r * 0.78, edge..strokeWidth = line * 0.7);
    // A crown cut into it.
    final w = r * 0.9;
    final h = r * 0.55;
    final crown = Path()
      ..moveTo(centre.dx - w / 2, centre.dy + h / 2)
      ..lineTo(centre.dx - w / 2, centre.dy - h / 4)
      ..lineTo(centre.dx - w / 4, centre.dy + h / 10)
      ..lineTo(centre.dx, centre.dy - h / 2)
      ..lineTo(centre.dx + w / 4, centre.dy + h / 10)
      ..lineTo(centre.dx + w / 2, centre.dy - h / 4)
      ..lineTo(centre.dx + w / 2, centre.dy + h / 2)
      ..close();
    canvas.drawPath(crown, Paint()..color = skin.edge.withValues(alpha: 0.85));
  }

  /// The clan's banner, hung from the die's upper right: a pole-less flag in
  /// the clan's colour with a swallow tail and a light notch.
  void _paintBanner(Canvas canvas, Size size, DieClan clan) {
    final w = size.width * 0.2;
    final h = size.height * 0.36;
    final x = size.width * 0.74;
    final y = size.height * -0.02;
    final flag = Path()
      ..moveTo(x, y)
      ..lineTo(x + w, y)
      ..lineTo(x + w, y + h)
      ..lineTo(x + w / 2, y + h * 0.8)
      ..lineTo(x, y + h)
      ..close();
    canvas.drawPath(flag, Paint()..color = clan.color);
    canvas.drawPath(
        flag,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, size.width / 40)
          ..strokeJoin = StrokeJoin.round
          ..color = _shade(clan.color, -0.45));
    final cx = x + w / 2;
    final cy = y + h * 0.38;
    final d = w * 0.22;
    canvas.drawPath(
        Path()
          ..moveTo(cx, cy - d)
          ..lineTo(cx + d, cy)
          ..lineTo(cx, cy + d)
          ..lineTo(cx - d, cy)
          ..close(),
        Paint()..color = _shade(clan.color, 0.7));
  }

  @override
  bool shouldRepaint(PolyDiePainter old) =>
      old.shape != shape ||
      old.skin != skin ||
      old.t != t ||
      old.label != label ||
      old.clan != clan ||
      old.dieId != dieId;
}
