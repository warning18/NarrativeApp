// The fight's field anomalies as an atmosphere over the whole fight (v2.10.40):
// each family (storm, ground, cold, heat, water, light) tints and moves the
// room: the Eclipse a violet dusk with a corona, a storm rain and a flash, the
// cold frost creeping in from the edges, heat an orange haze with embers, water
// a teal sheen with ripples, the ground dust and glowing cracks up the sides.
// Translucent and never taking a touch; it fades in on the omen at 30 % and
// stands at full strength while the anomaly is active. Reduced motion: one
// still frame. The fight screen draws it above the panels and the dice board
// and below the face row and the action buttons, which stay at full brightness.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import '../theme/palette.dart';

import '../combat/field_anomaly.dart' show AnomalyFamily;

double _h(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// The atmosphere of [family] at [level] (0.3 the omen, 1 active), over the
/// box it fills.
class AnomalyAtmosphere extends StatefulWidget {
  const AnomalyAtmosphere(
      {super.key, required this.family, required this.level});

  final AnomalyFamily family;
  final double level;

  @override
  State<AnomalyAtmosphere> createState() => _AnomalyAtmosphereState();
}

class _AnomalyAtmosphereState extends State<AnomalyAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 60));
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  bool _still = false;

  @override
  void initState() {
    super.initState();
    _clock.addListener(() => _time.value = _clock.value * 60);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.of(context).disableAnimations;
    if (still != _still || !_clock.isAnimating && !still) {
      _still = still;
      if (still) {
        _clock.stop();
        _time.value = 0;
      } else {
        _clock.repeat();
      }
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: const Key('anomaly_atmosphere'),
            size: Size.infinite,
            painter: _AtmospherePainter(widget.family, widget.level, _time),
          ),
        ),
      );
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter(this.family, this.level, this.time) : super(repaint: time);
  final AnomalyFamily family;
  final double level;

  /// Seconds on screen; 0 and never moving when motion is reduced.
  final ValueListenable<double> time;

  void _veil(Canvas c, Size s, Color color, double a) =>
      c.drawRect(Offset.zero & s, Paint()..color = color.withValues(alpha: a));

  void _vignette(Canvas c, Size s, Color color, double a, {double from = .45}) {
    final r = Rect.fromLTWH(0, 0, s.width, s.height);
    c.drawRect(
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.1),
            radius: 1.0,
            colors: [color.withValues(alpha: 0), color.withValues(alpha: a)],
            stops: [from, 1],
          ).createShader(r));
  }

  void _edge(Canvas c, Size s, Color color, double a, double depth) {
    for (final e in [
      (
        Alignment.topCenter,
        Alignment.bottomCenter,
        Rect.fromLTWH(0, 0, s.width, depth)
      ),
      (
        Alignment.bottomCenter,
        Alignment.topCenter,
        Rect.fromLTWH(0, s.height - depth, s.width, depth)
      ),
      (
        Alignment.centerLeft,
        Alignment.centerRight,
        Rect.fromLTWH(0, 0, depth, s.height)
      ),
      (
        Alignment.centerRight,
        Alignment.centerLeft,
        Rect.fromLTWH(s.width - depth, 0, depth, s.height)
      ),
    ]) {
      c.drawRect(
          e.$3,
          Paint()
            ..shader = LinearGradient(
              begin: e.$1,
              end: e.$2,
              colors: [color.withValues(alpha: a), color.withValues(alpha: 0)],
            ).createShader(e.$3));
    }
  }

  @override
  void paint(Canvas canvas, Size s) {
    final t = time.value;
    switch (family) {
      case AnomalyFamily.light:
        // The eclipse: the room dims to violet-black; a corona hangs at the top.
        _veil(canvas, s, const Color(0xFF0A0614), 0.28 * level);
        _vignette(canvas, s, const Color(0xFF140A2A), 0.42 * level, from: .6);
        final at = Offset(s.width * 0.5, -4);
        final r = Rect.fromCircle(center: at, radius: 120);
        canvas.drawCircle(
            at,
            120,
            Paint()
              ..shader = RadialGradient(colors: [
                Palette.veilNight.withValues(alpha: 0),
                const Color(0xFFBFB6FF).withValues(alpha: 0.55 * level),
                const Color(0xFFBFB6FF).withValues(alpha: 0),
              ], stops: const [
                0.4,
                0.52,
                1
              ]).createShader(r));
        canvas.drawCircle(at, 52,
            Paint()..color = Palette.veilNight.withValues(alpha: 0.95 * level));
      case AnomalyFamily.storm:
        _veil(canvas, s, Palette.deepBlue, 0.24 * level);
        _vignette(canvas, s, const Color(0xFF05080F), 0.4 * level, from: .55);
        final rain = Paint()
          ..color = const Color(0xFFCFE0F0).withValues(alpha: 0.32 * level)
          ..strokeWidth = 1.2;
        for (var i = 0; i < 120 * level; i++) {
          final len = 14 + 16 * _h(i, 3);
          final x =
              ((_h(i, 1) * s.width - t * 120) % s.width + s.width) % s.width;
          final y = (_h(i, 2) * s.height + t * 520) % s.height;
          canvas.drawLine(Offset(x, y), Offset(x - len * 0.28, y + len), rain);
        }
        // A flash: a pale wash and a bolt down the right side.
        // A flash now and then (static: always the bolt, faint).
        final flash = t == 0
            ? 1.0
            : math.pow(math.max(0.0, math.sin(t * 0.9 + 1)), 14).toDouble();
        _veil(canvas, s, const Color(0xFFEAF2FF), 0.07 * level * flash);
        final bolt = Path()
          ..moveTo(s.width * 0.86, 0)
          ..lineTo(s.width * 0.80, s.height * 0.10)
          ..lineTo(s.width * 0.85, s.height * 0.14)
          ..lineTo(s.width * 0.76, s.height * 0.30);
        canvas.drawPath(
            bolt,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = const Color(0xFFBFD4FF)
                  .withValues(alpha: 0.28 * level * flash)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawPath(
            bolt,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.white.withValues(alpha: 0.9 * level * flash));
      case AnomalyFamily.cold:
        _veil(canvas, s, const Color(0xFF9CC8E8), 0.08 * level);
        _edge(canvas, s, const Color(0xFFE4F4FF), 0.5 * level, 46);
        final ice = Paint()
          ..color = Colors.white.withValues(alpha: 0.75 * level)
          ..strokeWidth = 1.4;
        for (var i = 0; i < 46; i++) {
          // Crystals growing in from the edges.
          final side = i % 4;
          final u = _h(i, 5);
          final len = 8 + 22 * _h(i, 6);
          final p = switch (side) {
            0 => Offset(u * s.width, 0),
            1 => Offset(u * s.width, s.height),
            2 => Offset(0, u * s.height),
            _ => Offset(s.width, u * s.height),
          };
          final d = switch (side) {
            0 => const Offset(0, 1),
            1 => const Offset(0, -1),
            2 => const Offset(1, 0),
            _ => const Offset(-1, 0),
          };
          final tilt = (_h(i, 7) - 0.5) * 0.9;
          final dir = Offset(d.dx + tilt * d.dy, d.dy - tilt * d.dx);
          canvas.drawLine(p, p + dir * len, ice);
          canvas.drawLine(p + dir * len * 0.55,
              p + dir * len * 0.55 + Offset(-dir.dy, dir.dx) * 6, ice);
        }
      case AnomalyFamily.heat:
        _veil(canvas, s, const Color(0xFF3A0E05), 0.12 * level);
        final haze =
            Rect.fromLTWH(0, s.height * 0.35, s.width, s.height * 0.65);
        canvas.drawRect(
            haze,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFFFF7A2A).withValues(alpha: 0.3 * level),
                  const Color(0xFFFF7A2A).withValues(alpha: 0),
                ],
              ).createShader(haze));
        final shimmer = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFFFD9A0).withValues(alpha: 0.12 * level);
        for (var k = 0; k < 16; k++) {
          final y = s.height * (0.42 + k * 0.034);
          final p = Path()..moveTo(0, y);
          for (var x = 0.0; x <= s.width; x += 8) {
            p.lineTo(x, y + math.sin(x * 0.06 + k) * 2.6);
          }
          canvas.drawPath(p, shimmer);
        }
        for (var i = 0; i < 36 * level; i++) {
          final x = _h(i, 8) * s.width + math.sin(t + i) * 6;
          final span = s.height * 0.7;
          final y = s.height * 0.3 +
              ((_h(i, 9) * span - t * 26) % span + span) % span;
          canvas.drawRect(Rect.fromLTWH(x, y, 2, 2),
              Paint()..color = const Color(0xFFFFB04A).withValues(alpha: 0.85));
        }
      case AnomalyFamily.water:
        _veil(canvas, s, const Color(0xFF0C3A4A), 0.2 * level);
        _vignette(canvas, s, const Color(0xFF04202C), 0.4 * level);
        final band = Paint()
          ..color = Colors.white.withValues(alpha: 0.06 * level);
        for (var k = 0; k < 4; k++) {
          final x = s.width * (0.1 + 0.25 * k);
          final p = Path()
            ..moveTo(x, 0)
            ..lineTo(x + 46, 0)
            ..lineTo(x - 70, s.height)
            ..lineTo(x - 116, s.height)
            ..close();
          canvas.drawPath(p, band);
        }
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFFBFE8F2).withValues(alpha: 0.4 * level);
        for (var i = 0; i < 26; i++) {
          // (each ripple's strength fades as it widens)
          final at =
              Offset(_h(i, 10) * s.width, s.height * (0.3 + 0.6 * _h(i, 11)));
          final grow = t == 0 ? 0.5 : ((t * 0.5 + _h(i, 15)) % 1.0);
          final r = 2 + 12 * grow;
          canvas.drawOval(
              Rect.fromCenter(center: at, width: r * 2.4, height: r * 0.9),
              ring);
        }
        // A rising line of water at the foot, under the buttons' row.
        final wave = Path()..moveTo(0, s.height);
        for (var x = 0.0; x <= s.width; x += 6) {
          wave.lineTo(x, s.height * 0.8 + math.sin(x * 0.05) * 3);
        }
        wave
          ..lineTo(s.width, s.height)
          ..close();
        canvas.drawPath(
            wave,
            Paint()
              ..color =
                  const Color(0xFF2C7F96).withValues(alpha: 0.13 * level));
      case AnomalyFamily.ground:
        _veil(canvas, s, const Color(0xFF1A130C), 0.16 * level);
        _vignette(canvas, s, const Color(0xFF0B0805), 0.45 * level, from: .5);
        final dust =
            Rect.fromLTWH(0, s.height * 0.45, s.width, s.height * 0.55);
        canvas.drawRect(
            dust,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFFB89A6A).withValues(alpha: 0.32 * level),
                  const Color(0xFFB89A6A).withValues(alpha: 0),
                ],
              ).createShader(dust));
        // Cracks run up the two sides, never across the dice.
        for (final (seed, x0) in [
          (3, 0.05),
          (9, 0.95),
          (14, 0.2),
          (21, 0.82)
        ]) {
          var x = s.width * x0;
          var y = s.height;
          final p = Path()..moveTo(x, y);
          for (var k = 0; k < 6; k++) {
            x += (_h(seed + k, 2) - 0.5) * 36 + (x0 < 0.5 ? -4 : 4);
            y -= 34 + 26 * _h(seed + k, 3);
            p.lineTo(x.clamp(2.0, s.width - 2), y);
          }
          canvas.drawPath(
              p,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 6
                ..color = Palette.crackEmber.withValues(alpha: 0.28 * level)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          canvas.drawPath(
              p,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8
                ..color =
                    const Color(0xFFFFB46B).withValues(alpha: 0.85 * level));
        }
        for (var i = 0; i < 40 * level; i++) {
          canvas.drawRect(
              Rect.fromLTWH(_h(i, 13) * s.width,
                  s.height * (0.35 + 0.6 * _h(i, 14)), 2, 2),
              Paint()..color = const Color(0xFFD8C39A).withValues(alpha: 0.7));
        }
    }
  }

  @override
  bool shouldRepaint(_AtmospherePainter old) =>
      old.family != family || old.level != level;
}
