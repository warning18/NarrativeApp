// Snow on the Tower's interface, a proposal for the pictures (nothing in the
// game uses it yet): flakes of three sizes fall with a slow sway and a slight
// wind, most fall past, and along the top edge of each panel and button a soft
// drift builds up: smooth mounds, thick in the middle and thin at the corners,
// a one-pixel rim highlight, no dents. When a drift reaches its cap, a chunk
// breaks off at a random place, slides off the edge and falls in a small puff,
// and the drift builds again; the timing is irregular, so no two edges pulse
// together. One painter and a capped number of flakes, every frame a pure
// function of the time on screen.
//
// Reduce-motion: a static, light dusting, no flakes and no shedding.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import 'ink_palette.dart';

/// A top edge the snow rests on: from [a] (left) to [b] (right).
class SnowEdge {
  const SnowEdge(this.id, this.a, this.b);

  final int id;
  final Offset a, b;
}

/// The tallest a drift grows, in logical pixels above its edge.
const double snowCapHeight = 8;

double _hash(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// One shed: when, where along the edge (0 to 1) and how wide.
typedef _Shed = ({double at, double centre, double width});

/// The sheds of edge [id] up to [t] seconds: irregular cycles of 7 to 13 s
/// (longer in a light fall), the first one already under way.
List<_Shed> _sheds(int id, double t, double slow) {
  final out = <_Shed>[];
  var at = -_hash(id, 99) * 6 * slow;
  var k = 0;
  while (at < t + 1 && k < 12) {
    final d = (7 + 6 * _hash(id, k)) * slow;
    at += d;
    out.add((
      at: at,
      centre: 0.2 + 0.6 * _hash(id, k + 40),
      width: 0.26 + 0.14 * _hash(id, k + 80),
    ));
    k++;
  }
  return out;
}

/// The thickness of edge [id]'s drift at [u] (0 to 1 along it), [t] seconds in.
double snowThickness(int id, double u, double t,
    {double cap = snowCapHeight, double slow = 1}) {
  var reset = -_hash(id, 98) * 5 * slow; // the drift's start, a little before
  var shedding = 0.0;
  for (final s in _sheds(id, t, slow)) {
    final covers = (u - s.centre).abs() <= s.width / 2;
    if (!covers) continue;
    if (t >= s.at + 0.5) {
      reset = math.max(reset, s.at + 0.5);
    } else if (t >= s.at) {
      shedding = math.max(shedding, Curves.easeIn.transform((t - s.at) / 0.5));
    }
  }
  final tau = math.max(0.0, t - reset);
  final grow = 1 - math.exp(-tau / (3.8 * slow));
  final mound = math.pow(math.sin(math.pi * u.clamp(0.0, 1.0)), 0.55);
  final lumps = 1 + 0.12 * math.sin(u * 7 + id * 1.7);
  return cap * grow * mound * lumps * (1 - shedding);
}

class InkSnowfall extends StatelessWidget {
  const InkSnowfall({
    super.key,
    required this.edges,
    required this.time,
    this.light = false,
    this.reduceMotion = false,
  });

  final ValueListenable<List<SnowEdge>> edges;

  /// Seconds on screen.
  final ValueListenable<double> time;
  final bool light;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _SnowPainter(edges, time, light, reduceMotion),
          ),
        ),
      );
}

class _SnowPainter extends CustomPainter {
  _SnowPainter(this.edges, this.time, this.light, this.reduce)
      : super(repaint: Listenable.merge([edges, time]));

  final ValueListenable<List<SnowEdge>> edges;
  final ValueListenable<double> time;
  final bool light, reduce;

  Paint _px(Color c, [double a = 1]) => Paint()
    ..isAntiAlias = false
    ..color = c.withValues(alpha: a.clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final t = reduce ? 0.0 : time.value;
    final slow = light ? 1.4 : 1.0;
    final cap = light ? 5.5 : snowCapHeight;
    // The drifts first, then the flakes over them.
    for (final e in edges.value) {
      _drift(canvas, e, t, cap, slow);
    }
    if (!reduce) _flakes(canvas, size, t);
  }

  void _drift(Canvas canvas, SnowEdge e, double t, double cap, double slow) {
    final length = (e.b - e.a).distance;
    if (length < 12) return;
    final n = math.max(8, (length / 2).round());
    final top = <Offset>[];
    final base = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final u = i / n;
      final p = Offset.lerp(e.a, e.b, u)!;
      final h = reduce
          ? cap * 0.35 * math.pow(math.sin(math.pi * u), 0.55).toDouble()
          : snowThickness(e.id, u, t, cap: cap, slow: slow);
      base.add(Offset(p.dx.roundToDouble(), p.dy.roundToDouble()));
      top.add(Offset(p.dx.roundToDouble(), (p.dy - h).roundToDouble()));
    }
    final body = Path()..moveTo(base.first.dx, base.first.dy);
    for (final p in top) {
      body.lineTo(p.dx, p.dy);
    }
    for (final p in base.reversed) {
      body.lineTo(p.dx, p.dy);
    }
    body.close();
    canvas.drawPath(body, _px(inkPaper, 0.96));
    // The drift's foot, a shade, and the rim highlight along its top.
    final foot = Path();
    var started = false;
    for (var i = 0; i < top.length; i++) {
      final h = base[i].dy - top[i].dy;
      if (h < 2) continue;
      final p = Offset(base[i].dx, base[i].dy - 1);
      if (!started) {
        foot.moveTo(p.dx, p.dy);
        started = true;
      } else {
        foot.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
        foot,
        _px(inkGrey, 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    final rim = Path();
    started = false;
    for (final p in top) {
      if (!started) {
        rim.moveTo(p.dx, p.dy);
        started = true;
      } else {
        rim.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
        rim,
        _px(const Color(0xFFFFFFFF), 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    if (reduce) return;
    // The chunks that break off, and their puffs.
    for (final s in _sheds(e.id, t, slow)) {
      final q = t - s.at;
      if (q < 0 || q > 1.1) continue;
      final cx = s.centre;
      final from = Offset.lerp(e.a, e.b, cx)!;
      final dir = (cx < 0.5 ? -1.0 : 1.0);
      final slide = Curves.easeIn.transform((q / 0.5).clamp(0.0, 1.0));
      final fall = 0.5 * 520 * math.pow(math.max(0.0, q - 0.12), 2);
      final w = length * s.width;
      final h = cap * 0.9;
      canvas.save();
      canvas.translate(from.dx + dir * slide * w * 0.5, from.dy + fall);
      canvas.rotate(dir * slide * 0.35);
      final slab = Path()
        ..moveTo(-w / 2, 0)
        ..quadraticBezierTo(0, -h * 1.5, w / 2, 0)
        ..close();
      canvas.drawPath(
          slab, _px(inkPaper, 0.95 * (1 - ((q - 0.5) / 0.6).clamp(0.0, 1.0))));
      canvas.restore();
      // The puff where it lands.
      if (q > 0.38 && q < 1.1) {
        final k = (q - 0.38) / 0.72;
        final ground = Offset(from.dx + dir * w * 0.5, from.dy + 36);
        for (var i = 0; i < 9; i++) {
          final a = -math.pi * (0.1 + 0.8 * _hash(i, e.id + 3));
          final r = (6 + 16 * _hash(i, 5)) * k;
          final p = ground + Offset(math.cos(a) * r, math.sin(a) * r * 0.7);
          final sz = (3 - 2 * k).clamp(1.0, 3.0).roundToDouble();
          canvas.drawRect(
              Rect.fromLTWH(p.dx.roundToDouble(), p.dy.roundToDouble(), sz, sz),
              _px(inkPaper, 0.85 * (1 - k)));
        }
      }
    }
  }

  void _flakes(Canvas canvas, Size size, double t) {
    final n = light ? 28 : 70;
    for (var i = 0; i < n; i++) {
      final big = _hash(i, 1);
      final sz = big < 0.55 ? 1.0 : (big < 0.88 ? 2.0 : 3.0);
      final speed = 18 + 16 * sz + 14 * _hash(i, 2);
      final x0 = _hash(i, 3) * size.width;
      final y0 = _hash(i, 4) * size.height;
      final period = 3 + 3 * _hash(i, 5);
      final sway = (5 + 9 * _hash(i, 6)) * (sz == 1 ? 0.7 : 1);
      final x = x0 + sway * math.sin(t * 2 * math.pi / period + i) + 4 * t;
      final y = y0 + speed * t;
      final px = (x % size.width + size.width) % size.width;
      final py = y % size.height;
      canvas.drawRect(
          Rect.fromLTWH(px.roundToDouble(), py.roundToDouble(), sz, sz),
          _px(sz == 1 ? inkGrey : inkPaper, sz == 1 ? 0.7 : 0.9));
    }
  }

  @override
  bool shouldRepaint(_SnowPainter old) =>
      old.light != light || old.reduce != reduce;
}
