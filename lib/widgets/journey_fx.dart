import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/climate.dart';
import '../data/journey_map.dart';

/// The weather drifting over the Journey map: ash over the burning Lower
/// City, Alster and the Spire, and what the sky brings (v1.204, see
/// climate.dart): rain, snow, dust off the dry lands, fog.
enum JourneyWeather { none, ash, rain, snow, dust, fog }

/// The chapter's own weather, as the story was first drawn: ash over the
/// burning chapters, rain over the drowned ones, snow over the frost.
JourneyWeather journeyWeatherFor(int chapter) => switch (chapter) {
      1 || 2 || 3 => JourneyWeather.ash,
      4 || 6 => JourneyWeather.rain,
      5 => JourneyWeather.snow,
      _ => JourneyWeather.none,
    };

/// The weather drawn over [chapter]'s map under [sky]: what the sky
/// brings when it brings something; under a clear or a plain cloudy sky,
/// the ash of a burning chapter still falls, and nothing else.
JourneyWeather journeyWeatherOf(WeatherKind? sky, int chapter) => switch (sky) {
      WeatherKind.rain => JourneyWeather.rain,
      WeatherKind.snow => JourneyWeather.snow,
      WeatherKind.dust => JourneyWeather.dust,
      WeatherKind.ash => JourneyWeather.ash,
      WeatherKind.fog => JourneyWeather.fog,
      _ => journeyWeatherFor(chapter) == JourneyWeather.ash
          ? JourneyWeather.ash
          : JourneyWeather.none,
    };

/// A chapter's weather over [size] at [t] seconds (ash, rain or snow),
/// drawn from time alone: the Journey map, the Story tab and the sea use it.
void paintJourneyWeather(Canvas canvas, Size size, double t,
    JourneyWeather weather, Color weatherColour,
    {int count = 26}) {
  if (weather == JourneyWeather.none) return;
  final paint = Paint()..color = weatherColour;
  if (weather == JourneyWeather.fog) {
    // Banks of fog drifting slowly across, soft-edged.
    final bank = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    for (var k = 0; k < 5; k++) {
      final y = (0.1 + _weatherHash(k) * 0.8) * size.height;
      final x =
          ((_weatherHash(k + 5) + t * 0.012 * (1 + _weatherHash(k + 9))) % 1.3 -
                  0.15) *
              size.width;
      bank.color = weatherColour.withValues(alpha: 0.16);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y),
              width: size.width * 0.55,
              height: 26 + _weatherHash(k + 2) * 20),
          bank);
    }
    return;
  }
  if (weather == JourneyWeather.dust) {
    // Dust streaming on the wind, left to right, in short streaks.
    for (var k = 0; k < count; k++) {
      final speed = 0.18 + _weatherHash(k) * 0.14;
      final phase = (t * speed + _weatherHash(k + 99)) % 1.0;
      final y =
          (_weatherHash(k + 7) + math.sin(t * 1.3 + k) * 0.01) * size.height;
      final x = phase * size.width;
      paint
        ..color =
            weatherColour.withValues(alpha: math.sin(math.pi * phase) * 0.7)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, y), Offset(x - 7, y + 0.6), paint);
    }
    return;
  }
  for (var k = 0; k < count; k++) {
    final speed = switch (weather) {
      JourneyWeather.rain => 1.6 + _weatherHash(k) * 0.6,
      JourneyWeather.snow => 0.18 + _weatherHash(k) * 0.12,
      _ => 0.12 + _weatherHash(k) * 0.1,
    };
    final phase =
        (t * speed / (size.height / 400) + _weatherHash(k + 99)) % 1.0;
    final drift = switch (weather) {
      JourneyWeather.rain => -0.25,
      JourneyWeather.snow => math.sin(t * 0.8 + k) * 0.04,
      _ => -0.12,
    };
    final x = (_weatherHash(k + 7) + drift * phase) % 1.0 * size.width;
    final y = phase * size.height;
    final alpha = math.sin(math.pi * phase) * 0.8;
    paint.color = weatherColour.withValues(alpha: alpha);
    if (weather == JourneyWeather.rain) {
      canvas.drawLine(
          Offset(x, y),
          Offset(x - 3, y + 10),
          paint
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round);
    } else {
      canvas.drawCircle(
          Offset(x, y), weather == JourneyWeather.snow ? 2 : 1.4, paint);
    }
  }
}

double _weatherHash(int n) {
  final x = math.sin(n * 12.9898) * 43758.5453;
  return x - x.floorToDouble();
}

/// One way on, as the effects see it.
class JourneyFxStep {
  const JourneyFxStep({
    required this.centre,
    required this.kind,
    required this.colour,
    required this.locked,
    required this.row,
  });

  final Offset centre;
  final JourneyStepKind kind;
  final Color colour;
  final bool locked;
  final int row;
}

/// A footprint left on the road walked, and when (in the chart's seconds).
class JourneyFootprint {
  const JourneyFootprint(this.at, this.born, this.angle);
  final Offset at;
  final double born;
  final double angle;
}

/// The Journey map's living layer, drawn over the roads and under the
/// steps' marks: what each step holds (a fight's heartbeat and embers, a
/// shop's glint, a rest's fireflies, a roll's glimmer, a voyage's
/// ripples, the main quest's beacon, the Void's motes), fog drifting over
/// the far ways, the chapter's weather, the party's mark breathing, the
/// picked road flowing toward its step, footprints and dust on a walk, a
/// die tumbling ahead of a roll and a shut way's red flash. Everything is
/// a function of [time] (seconds), so it costs no state per particle.
class JourneyFxPainter extends CustomPainter {
  JourneyFxPainter({
    required this.time,
    required this.steps,
    required this.here,
    required this.hereRadius,
    required this.stepRadius,
    required this.mark,
    required this.fog,
    required this.weather,
    required this.weatherColour,
    this.selectedRoad,
    this.selected,
    this.footprints = const [],
    this.footprintColour = Colors.white,
    this.dust,
    this.dice,
    this.diceColour = Colors.white,
    this.rattle,
    this.rattleColour = Colors.red,
  }) : super(repaint: time);

  final ValueNotifier<double> time;
  final List<JourneyFxStep> steps;
  final Offset here;
  final double hereRadius;
  final double stepRadius;
  final Color mark;
  final Color fog;
  final JourneyWeather weather;
  final Color weatherColour;

  /// The road to the picked step, which flows toward it.
  final Path? selectedRoad;
  final int? selected;

  final List<JourneyFootprint> footprints;
  final Color footprintColour;

  /// Where the walk ended, and when: a puff of dust.
  final (Offset, double)? dust;

  /// A die tumbling at this point (walking to a roll), turning with time.
  final Offset? dice;
  final Color diceColour;

  /// A shut way tapped: where, and when.
  final (Offset, double)? rattle;
  final Color rattleColour;

  static double _hash(int n) {
    final x = math.sin(n * 12.9898) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    _weather(canvas, size, t);
    _fogWisps(canvas, size, t);
    _markGlow(canvas, t);
    for (var i = 0; i < steps.length; i++) {
      if (!steps[i].locked) _ambient(canvas, steps[i], i, t);
    }
    _selection(canvas, t);
    _footprints(canvas, t);
    _dust(canvas, t);
    _dice(canvas, t);
    _rattle(canvas, t);
  }

  void _weather(Canvas canvas, Size size, double t) =>
      paintJourneyWeather(canvas, size, t, weather, weatherColour);

  void _fogWisps(Canvas canvas, Size size, double t) {
    // Over the far rows of a town's steps, and the top of any map.
    final farRow = steps.any((s) => s.row >= 1);
    final top = farRow
        ? steps
            .where((s) => s.row >= 1)
            .map((s) => s.centre.dy)
            .reduce(math.min)
        : 60.0;
    for (var j = 0; j < 3; j++) {
      final period = 11.0 + j * 3;
      final phase = ((t + j * 4) % period) / period;
      final cx = -0.3 * size.width + phase * 1.6 * size.width;
      final cy = top - 30 + j * 26;
      final alpha = math.sin(math.pi * phase) * (farRow ? 0.55 : 0.3);
      final rect =
          Rect.fromCenter(center: Offset(cx, cy), width: 260, height: 70);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(colors: [
            fog.withValues(alpha: alpha),
            fog.withValues(alpha: 0),
          ]).createShader(rect),
      );
    }
  }

  void _markGlow(Canvas canvas, double t) {
    final a = 0.18 + 0.14 * (0.5 + 0.5 * math.sin(t * 2.1));
    final rect = Rect.fromCircle(center: here, radius: hereRadius * 2.4);
    canvas.drawCircle(
      here,
      hereRadius * 2.4,
      Paint()
        ..shader = RadialGradient(colors: [
          mark.withValues(alpha: a),
          mark.withValues(alpha: 0),
        ]).createShader(rect),
    );
  }

  void _ambient(Canvas canvas, JourneyFxStep step, int i, double t) {
    final c = step.centre;
    final col = step.colour;
    final seed = i * 7;
    switch (step.kind) {
      case JourneyStepKind.fight:
      case JourneyStepKind.expedition:
        // A double heartbeat, and embers thrown off it.
        final beat = (t % 1.6) / 1.6;
        double pulse(double at) => math.exp(-math.pow((beat - at) * 14, 2));
        final s = 1 + 0.35 * pulse(0.12) + 0.28 * pulse(0.32);
        final r = stepRadius * 1.7 * s;
        final rect = Rect.fromCircle(center: c, radius: r);
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = RadialGradient(colors: [
              col.withValues(alpha: 0.28 + 0.3 * pulse(0.12)),
              col.withValues(alpha: 0),
            ]).createShader(rect),
        );
        for (var k = 0; k < 4; k++) {
          final p = ((t / 2) + k / 4 + _hash(seed + k) * 0.1) % 1.0;
          final pos = c +
              Offset((_hash(seed + k + 3) - 0.5) * 30 + p * 6,
                  -stepRadius - p * 46);
          canvas.drawRect(
            Rect.fromCenter(center: pos, width: 3, height: 3),
            Paint()
              ..color = const Color(0xFFE0762B)
                  .withValues(alpha: math.sin(math.pi * p)),
          );
        }
      case JourneyStepKind.shop:
      case JourneyStepKind.quest:
        // A glint now and then.
        for (var k = 0; k < 2; k++) {
          final p = ((t + k * 1.2 + _hash(seed + k)) % 2.4) / 2.4;
          if (p < 0.6 || p > 0.85) continue;
          final q = (p - 0.6) / 0.25;
          final s = math.sin(math.pi * q) * 7;
          final pos = c + Offset(k == 0 ? 17 : -18, k == 0 ? -19 : 12);
          _star(canvas, pos, s, col.withValues(alpha: math.sin(math.pi * q)),
              q * math.pi / 2);
        }
      case JourneyStepKind.rest:
        // Fireflies round it.
        for (var k = 0; k < 4; k++) {
          final a = t * (0.6 + k * 0.13) + k * 1.7;
          final pos = c +
              Offset(math.cos(a) * (stepRadius + 10 + k * 3),
                  math.sin(a * 1.3) * (stepRadius + 6));
          final glow = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * 3 + k * 2));
          canvas.drawCircle(
              pos,
              4,
              Paint()
                ..color =
                    const Color(0xFFD8F5A0).withValues(alpha: glow * 0.35));
          canvas.drawCircle(pos, 1.8,
              Paint()..color = const Color(0xFFD8F5A0).withValues(alpha: glow));
        }
      case JourneyStepKind.check:
      case JourneyStepKind.challenge:
        // A roll's glimmer.
        for (var k = 0; k < 3; k++) {
          final p = ((t + k * 0.8) % 2.4) / 2.4;
          if (p < 0.55 || p > 0.8) continue;
          final q = (p - 0.55) / 0.25;
          final ang = k * 2.1;
          final pos = c +
              Offset(math.cos(ang) * (stepRadius + 6),
                  math.sin(ang) * (stepRadius + 6));
          _star(canvas, pos, math.sin(math.pi * q) * 6,
              col.withValues(alpha: math.sin(math.pi * q)), q);
        }
      case JourneyStepKind.travel:
        // Rings of water spreading.
        for (var k = 0; k < 3; k++) {
          final p = ((t / 2.4) + k / 3) % 1.0;
          final rect = Rect.fromCenter(
              center: c.translate(0, stepRadius * 0.6),
              width: stepRadius * (1.4 + p * 2.2),
              height: stepRadius * (0.5 + p * 0.7));
          canvas.drawOval(
            rect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = col.withValues(alpha: (1 - p) * 0.8),
          );
        }
      case JourneyStepKind.mainQuest:
        // A column of gold, seen from anywhere on the map.
        final a = 0.3 + 0.25 * (0.5 + 0.5 * math.sin(t * 2.6));
        final w = stepRadius * (1.7 + 0.2 * math.sin(t * 2.6));
        final rect = Rect.fromLTWH(c.dx - w / 2, c.dy - 160, w, 160);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [col.withValues(alpha: a), col.withValues(alpha: 0)],
            ).createShader(rect),
        );
      case JourneyStepKind.ending:
        // The Void seeping up.
        for (var k = 0; k < 5; k++) {
          final p = ((t / 3) + k / 5) % 1.0;
          final pos = c +
              Offset((_hash(seed + k) - 0.5) * 26 + math.sin(p * 6 + k) * 6,
                  -stepRadius * 0.6 - p * 60);
          final alpha = math.sin(math.pi * p);
          canvas.drawCircle(
              pos, 5, Paint()..color = col.withValues(alpha: alpha * 0.25));
          canvas.drawCircle(
              pos, 2.4, Paint()..color = col.withValues(alpha: alpha));
        }
      case JourneyStepKind.road:
        break;
    }
  }

  void _selection(Canvas canvas, double t) {
    final road = selectedRoad;
    if (road != null) {
      // Ink flowing along the picked road, toward its step.
      final paint = Paint()
        ..color = mark
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final phase = (t * 36) % 24;
      for (final metric in road.computeMetrics()) {
        var d = phase - 24;
        while (d < metric.length) {
          final a = math.max(0.0, d), b = math.min(metric.length, d + 10);
          if (b > a) canvas.drawPath(metric.extractPath(a, b), paint);
          d += 24;
        }
      }
    }
    final i = selected;
    if (i != null && i < steps.length) {
      // A ring breathing out from it.
      for (var k = 0; k < 2; k++) {
        final p = ((t / 1.4) + k / 2) % 1.0;
        canvas.drawCircle(
          steps[i].centre,
          stepRadius * (1 + p * 1.1),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = mark.withValues(alpha: (1 - p) * 0.85),
        );
      }
    }
  }

  void _footprints(Canvas canvas, double t) {
    for (final f in footprints) {
      final age = t - f.born;
      if (age < 0 || age > 1.4) continue;
      final alpha = (1 - age / 1.4) * 0.9;
      canvas.save();
      canvas.translate(f.at.dx, f.at.dy);
      canvas.rotate(f.angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2, -3, 4, 6), const Radius.circular(2)),
        Paint()..color = footprintColour.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  void _dust(Canvas canvas, double t) {
    final d = dust;
    if (d == null) return;
    final age = t - d.$2;
    if (age < 0 || age > 0.8) return;
    final p = age / 0.8;
    for (var k = 0; k < 6; k++) {
      final a = k / 6 * math.pi * 2 + 0.4;
      final pos = d.$1 + Offset(math.cos(a), math.sin(a) * 0.6) * (8 + p * 26);
      canvas.drawCircle(
        pos,
        3 + p * 6,
        Paint()..color = footprintColour.withValues(alpha: (1 - p) * 0.45),
      );
    }
  }

  void _dice(Canvas canvas, double t) {
    final at = dice;
    if (at == null) return;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(t * 9);
    final rect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, -8, 16, 16), const Radius.circular(3));
    canvas.drawRRect(rect, Paint()..color = fog);
    canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = diceColour);
    final pip = Paint()..color = diceColour;
    canvas.drawCircle(const Offset(-3, -3), 1.6, pip);
    canvas.drawCircle(const Offset(3, 3), 1.6, pip);
    canvas.restore();
  }

  void _rattle(Canvas canvas, double t) {
    final r = rattle;
    if (r == null) return;
    final age = t - r.$2;
    if (age < 0 || age > 0.5) return;
    final alpha = math.sin(math.pi * age / 0.5);
    canvas.drawCircle(
      r.$1,
      stepRadius + 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = rattleColour.withValues(alpha: alpha * 0.9),
    );
  }

  static void _star(
      Canvas canvas, Offset at, double size, Color colour, double turn) {
    if (size <= 0.1) return;
    final path = Path();
    for (var k = 0; k < 8; k++) {
      final r = k.isEven ? size : size * 0.28;
      final a = turn + k * math.pi / 4;
      final p = at + Offset(math.cos(a) * r, math.sin(a) * r);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = colour);
  }

  /// Whether a rebuild must redraw (v1.209): only when what the layer
  /// draws has changed. The clock's ticks repaint it on their own (see
  /// the constructor's `repaint`), so a rebuild that hands it the same
  /// steps, mark, weather and moments redraws nothing: the Journey's
  /// idle frames cost no re-recording of this layer.
  @override
  bool shouldRepaint(covariant JourneyFxPainter old) =>
      !identical(time, old.time) ||
      here != old.here ||
      hereRadius != old.hereRadius ||
      stepRadius != old.stepRadius ||
      mark != old.mark ||
      fog != old.fog ||
      weather != old.weather ||
      weatherColour != old.weatherColour ||
      !identical(selectedRoad, old.selectedRoad) ||
      selected != old.selected ||
      footprintColour != old.footprintColour ||
      dust != old.dust ||
      dice != old.dice ||
      diceColour != old.diceColour ||
      rattle != old.rattle ||
      rattleColour != old.rattleColour ||
      !_sameSteps(steps, old.steps) ||
      !_samePrints(footprints, old.footprints);

  static bool _sameSteps(List<JourneyFxStep> a, List<JourneyFxStep> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x.centre != y.centre ||
          x.kind != y.kind ||
          x.colour != y.colour ||
          x.locked != y.locked ||
          x.row != y.row) {
        return false;
      }
    }
    return true;
  }

  static bool _samePrints(List<JourneyFootprint> a, List<JourneyFootprint> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x.at != y.at || x.born != y.born || x.angle != y.angle) return false;
    }
    return true;
  }
}

/// A shake and a red vignette going into a fight (see the Journey tab's
/// take): [t] runs 0 to 1 over the jolt.
class JourneyJoltPainter extends CustomPainter {
  const JourneyJoltPainter({required this.t, required this.colour});

  final double t;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final alpha = math.sin(math.pi * t) * 0.8;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.8,
          colors: [
            colour.withValues(alpha: 0),
            colour.withValues(alpha: alpha)
          ],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(JourneyJoltPainter old) =>
      old.t != t || old.colour != colour;
}

/// The new chapter's map burning open from the party's mark: [t] 0 to 1,
/// an ember ring at the edge of what shows.
class JourneyBurnPainter extends CustomPainter {
  const JourneyBurnPainter(
      {required this.t, required this.centre, required this.ember});

  final double t;
  final Offset centre;
  final Color ember;

  static double radiusFor(double t, Size size, Offset centre) {
    final far = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((p) => (p - centre).distance).reduce(math.max);
    return Curves.easeIn.transform(t.clamp(0.0, 1.0)) * far;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final r = radiusFor(t, size, centre);
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = ember.withValues(alpha: 0.9)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFFD08A),
    );
  }

  @override
  bool shouldRepaint(JourneyBurnPainter old) =>
      old.t != t || old.centre != centre;
}

/// Clips to the circle [JourneyBurnPainter] draws.
class JourneyBurnClipper extends CustomClipper<Path> {
  const JourneyBurnClipper({required this.t, required this.centre});

  final double t;
  final Offset centre;

  @override
  Path getClip(Size size) => Path()
    ..addOval(Rect.fromCircle(
        center: centre, radius: JourneyBurnPainter.radiusFor(t, size, centre)));

  @override
  bool shouldReclip(JourneyBurnClipper old) =>
      old.t != t || old.centre != centre;
}

/// Text coming out of the ink, top to bottom (the Journey tab's scene).
class InkReveal extends StatelessWidget {
  const InkReveal({super.key, required this.child, required this.animate});

  final Widget child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOut,
      child: child,
      builder: (context, t, child) {
        if (t >= 1) return child!;
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Colors.white, Colors.white, Colors.transparent],
            stops: [
              0,
              (t * 1.2 - 0.2).clamp(0.0, 1.0),
              (t * 1.2).clamp(0.0, 1.0)
            ],
          ).createShader(rect),
          child: Opacity(opacity: (0.35 + t).clamp(0.0, 1.0), child: child),
        );
      },
    );
  }
}
