// Snow on the Tower's interface (v2.10.17, UX-2): flakes of three sizes fall
// with a slow sway and a slight wind, most fall past, and along the top edge of
// each piece (panel, button, tab) a soft drift builds up: smooth mounds, thick
// in the middle and thin at the corners, a one-pixel rim highlight, no dents.
// When a drift reaches its cap, a chunk breaks off at a random place, slides off
// the edge and falls in a small puff, and the drift builds again; the timing is
// irregular, so no two edges pulse together. A tap on a piece (or a blow on a
// panel) knocks its snow off. One painter over the whole screen and a capped
// number of flakes; every frame is a pure function of the time on screen.
//
// The pieces register their top edge with the [SnowField] of their weather
// scope ([SnowPiece]); the painter reads each edge where the piece is at the
// moment it paints, so a drift follows a scrolling list.
//
// Reduce-motion: a static, light dusting, no flakes, no clock, no shedding.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ink_palette.dart';

/// A piece whose top edge the snow rests on (the weather piece).
abstract class SnowPiece {
  /// A stable number for this edge (its seed): its cycles differ from its
  /// neighbours'.
  int get snowId;

  /// The top edge in global coordinates, from the left end to the right, or
  /// null when the piece is not on screen or not current.
  (Offset, Offset)? snowEdge();

  /// The times (seconds on screen) at which this piece was knocked.
  List<double> get snowKnocks;
}

/// The snow of one weather scope: its pieces, its clock and its fall.
class SnowField {
  SnowField({required this.fall, required this.reduceMotion, double start = 0})
      : time = ValueNotifier<double>(start);

  /// How hard it falls, 0 to 1 (the Tower's band: 0.4, 0.7, 1).
  final double fall;
  final bool reduceMotion;

  /// Seconds on screen.
  final ValueNotifier<double> time;

  final Set<SnowPiece> pieces = {};

  /// How many pieces have a drift now (what the tests read).
  int get edgeCount => pieces.where((p) => p.snowEdge() != null).length;

  /// 0 (the lightest fall) to 1 (the heaviest).
  double get heaviness => ((fall - 0.3) / 0.7).clamp(0.0, 1.0);

  /// The tallest a drift grows, above its edge: 5.5 to 8 px.
  double get cap => 5.5 + 2.5 * heaviness;

  /// How much slower a light fall builds and sheds: 1.4 (light) to 1.
  double get slow => 1.4 - 0.4 * heaviness;

  /// How many flakes fall on a whole screen: 80 (light) to 140 (v2.10.39: a
  /// light fall had 28, a few specks a phone barely showed).
  int get flakes => (80 + 60 * heaviness).round();

  /// Whether the screen's overlay draws the flakes. A screen whose fighters
  /// stand over the snow (the fight) turns it off and draws the flakes itself,
  /// behind them, with [SnowFlakesLayer]; the drifts stay on the overlay.
  bool overlayFlakes = true;

  void dispose() => time.dispose();
}

double _hash(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// One shed: when, where along the edge (0 to 1) and how wide.
typedef _Shed = ({double at, double centre, double width});

/// The sheds of edge [id] up to [t] seconds: irregular cycles of 7 to 13 s
/// (longer in a light fall), the first one already under way, and the knocks.
List<_Shed> _sheds(int id, double t, double slow, List<double> knocks) {
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
  // A knock takes the whole edge's snow off.
  for (final at in knocks) {
    out.add((at: at, centre: 0.5, width: 1.3));
  }
  return out;
}

/// The thickness of edge [id]'s drift at [u] (0 to 1 along it), [t] seconds in.
double snowThickness(int id, double u, double t,
    {double cap = 8, double slow = 1, List<double> knocks = const []}) {
  var reset = -_hash(id, 98) * 5 * slow; // the drift's start, a little before
  var shedding = 0.0;
  for (final s in _sheds(id, t, slow, knocks)) {
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

/// The snow, drawn over the whole screen and never taking a touch. Put it
/// above the pieces (the weather scope does).
class SnowfallLayer extends StatefulWidget {
  const SnowfallLayer({super.key, required this.field});

  final SnowField field;

  @override
  State<SnowfallLayer> createState() => _SnowfallLayerState();
}

class _SnowfallLayerState extends State<SnowfallLayer> {
  final GlobalKey _key = GlobalKey(debugLabel: 'snowfall_layer');

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: _key,
            size: Size.infinite,
            painter: _SnowPainter(widget.field, _key),
          ),
        ),
      );
}

class _SnowPainter extends CustomPainter {
  _SnowPainter(this.field, this.layerKey) : super(repaint: field.time);

  final SnowField field;
  final GlobalKey layerKey;

  Paint _px(Color c, [double a = 1]) => Paint()
    ..isAntiAlias = false
    ..color = c.withValues(alpha: a.clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final layer = snowBox(layerKey);
    if (layer == null) return;
    final t = field.reduceMotion ? 0.0 : field.time.value;
    // The drifts first, then the flakes over them.
    for (final piece in field.pieces.toList()) {
      final edge = piece.snowEdge();
      if (edge == null) continue;
      final a = layer.globalToLocal(edge.$1);
      final b = layer.globalToLocal(edge.$2);
      if (b.dx < 0 || a.dx > size.width || b.dy < 0 || a.dy > size.height) {
        continue;
      }
      _drift(canvas, piece.snowId, a, b, t, piece.snowKnocks);
    }
    if (!field.reduceMotion && field.overlayFlakes) {
      paintSnowFlakes(canvas, size, t, field.flakes, 0);
    }
  }

  void _drift(Canvas canvas, int id, Offset ea, Offset eb, double t,
      List<double> knocks) {
    final cap = field.cap;
    final length = (eb - ea).distance;
    if (length < 12) return;
    final n = math.max(8, (length / 2).round());
    final top = <Offset>[];
    final base = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final u = i / n;
      final p = Offset.lerp(ea, eb, u)!;
      final h = field.reduceMotion
          ? cap * 0.35 * math.pow(math.sin(math.pi * u), 0.55).toDouble()
          : snowThickness(id, u, t, cap: cap, slow: field.slow, knocks: knocks);
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
      if (base[i].dy - top[i].dy < 2) continue;
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
    if (field.reduceMotion) return;
    // The chunks that break off, and their puffs.
    for (final s in _sheds(id, t, field.slow, knocks)) {
      final q = t - s.at;
      if (q < 0 || q > 1.1) continue;
      final centre = s.width > 1 ? 0.5 : s.centre;
      final from = Offset.lerp(ea, eb, centre)!;
      final dir = centre < 0.5 ? -1.0 : 1.0;
      final slide = Curves.easeIn.transform((q / 0.5).clamp(0.0, 1.0));
      final fall = 0.5 * 520 * math.pow(math.max(0.0, q - 0.12), 2);
      final w = length * math.min(s.width, 1.0);
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
      if (q > 0.38) {
        final k = (q - 0.38) / 0.72;
        final ground = Offset(from.dx + dir * w * 0.5, from.dy + 36);
        for (var i = 0; i < 9; i++) {
          final a = -math.pi * (0.1 + 0.8 * _hash(i, id + 3));
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

  @override
  bool shouldRepaint(_SnowPainter old) =>
      old.field != field || old.layerKey != layerKey;
}

/// [count] flakes over a [size] box [t] seconds in: four sizes (a grey speck,
/// then 2, 3 and 4 px of paper), each with its own speed and sway. [salt]
/// shifts the pattern so two boxes do not fall in step.
void paintSnowFlakes(Canvas canvas, Size size, double t, int count, int salt) {
  if (size.isEmpty) return;
  Paint px(Color c, double a) => Paint()
    ..isAntiAlias = false
    ..color = c.withValues(alpha: a);
  for (var n = 0; n < count; n++) {
    final i = n + salt * 977;
    final big = _hash(i, 1);
    final sz = big < 0.3
        ? 1.0
        : big < 0.62
            ? 2.0
            : big < 0.9
                ? 3.0
                : 4.0;
    final speed = 20 + 14 * sz + 14 * _hash(i, 2);
    final x0 = _hash(i, 3) * size.width;
    final y0 = _hash(i, 4) * size.height;
    final period = 3 + 3 * _hash(i, 5);
    final sway = (5 + 9 * _hash(i, 6)) * (sz == 1 ? 0.7 : 1);
    final x = x0 + sway * math.sin(t * 2 * math.pi / period + i) + 4 * t;
    final y = y0 + speed * t;
    final fx = (x % size.width + size.width) % size.width;
    final fy = y % size.height;
    canvas.drawRect(
        Rect.fromLTWH(fx.roundToDouble(), fy.roundToDouble(), sz, sz),
        px(sz == 1 ? inkGrey : inkPaper, sz == 1 ? 0.7 : 0.92));
  }
}

/// The flakes alone, over the box this widget fills: the fight draws them
/// inside each panel, between the picture and the figures, so they fall behind
/// the fighters. The count follows the box's area, the fall's heaviness the
/// scope's.
class SnowFlakesLayer extends StatelessWidget {
  const SnowFlakesLayer({super.key, required this.field, this.salt = 1});

  final SnowField field;
  final int salt;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _FlakesPainter(field, salt),
          ),
        ),
      );
}

class _FlakesPainter extends CustomPainter {
  _FlakesPainter(this.field, this.salt) : super(repaint: field.time);

  final SnowField field;
  final int salt;

  @override
  void paint(Canvas canvas, Size size) {
    if (field.reduceMotion) return;
    // The overlay's density, by area (a phone screen is about 350 000 px2).
    final n =
        (field.flakes * size.width * size.height / 350000).round().clamp(8, 90);
    paintSnowFlakes(canvas, size, field.time.value, n, salt);
  }

  @override
  bool shouldRepaint(_FlakesPainter old) => old.field != field;
}

/// The live drifts as a list (for tests): each edge's thickness at its middle.
List<double> snowMiddles(SnowField field) => [
      for (final p in field.pieces)
        if (p.snowEdge() != null)
          snowThickness(p.snowId, 0.5, field.time.value,
              cap: field.cap, slow: field.slow, knocks: p.snowKnocks),
    ];

/// The box under [key], or null when the element is gone or not laid out
/// (a layer torn down while its last frame is still painting).
RenderBox? snowBox(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx == null || !ctx.mounted) return null;
  try {
    final o = ctx.findRenderObject();
    return o is RenderBox && o.attached && o.hasSize ? o : null;
  } on FlutterError {
    return null;
  }
}
