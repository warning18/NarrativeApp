// The Journey map's painters and road shapes (Maps' code): the roads,
// the relief, the reveal and the map growing in. Cut out of
// journey_screen.dart with no change.
part of '../journey_screen.dart';

/// The road from [from] up to [to]: leaving straight up, arriving from
/// straight below.
/// Where step [centre]'s road leaves the party's mark: on the side it
/// heads for (as _JourneyPainter draws it).
Offset _roadStart(Offset here, Offset centre, double width) {
  final lean = ((centre.dx - here.dx) / width * 1.6).clamp(
    -math.pi / 3,
    math.pi / 3,
  );
  return here +
      Offset(
        math.sin(lean) * _JourneyChartState._hereRadius,
        -math.cos(lean) * _JourneyChartState._hereRadius,
      );
}

/// The top [fraction] of the map, as it unrolls.
class _TopReveal extends CustomClipper<Rect> {
  const _TopReveal(this.fraction);
  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * fraction);

  @override
  bool shouldReclip(_TopReveal old) => old.fraction != fraction;
}

Path _roadPath(Offset from, Offset to) {
  final dy = (from.dy - to.dy).abs();
  return Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(
      from.dx,
      from.dy - dy * 0.45,
      to.dx,
      to.dy + dy * 0.45,
      to.dx,
      to.dy,
    );
}

/// The land: contour lines in the look's coast colour, the index line a
/// little stronger, a soft shade on the far side of each hilltop and a
/// small peak mark on the highest. Drawn a margin past the map's edges so
/// the land is there when the map moves with the party.
class _ReliefPainter extends CustomPainter {
  _ReliefPainter({
    required this.palette,
    required this.here,
    required this.shift,
    required this.seed,
  });

  final ChartPalette palette;
  final Offset here;
  final Offset shift;
  final int seed;

  static const double _margin = 320;

  double _height(double x, double y) =>
      reliefHeight(x - here.dx + shift.dx, y - here.dy + shift.dy, seed: seed);

  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTWH(
      -_margin,
      -_margin,
      size.width + _margin * 2,
      size.height + _margin * 2,
    );
    // Hills first: a shade to the south-east of each top.
    final peaks = reliefPeaks(area: area, height: _height);
    for (final peak in peaks) {
      final centre = peak + const Offset(16, 18);
      final shade = Rect.fromCircle(center: centre, radius: 70);
      canvas.drawCircle(
        centre,
        70,
        Paint()
          ..shader = RadialGradient(
            colors: [
              palette.fog.withValues(alpha: 0.32),
              palette.fog.withValues(alpha: 0),
            ],
          ).createShader(shade),
      );
    }
    // The contour lines, a shade stronger on the dark looks, whose coast
    // colour sits close to the land.
    final dark = palette.land.computeLuminance() < 0.2;
    final contour =
        dark ? Color.lerp(palette.coast, palette.label, 0.55)! : palette.coast;
    for (var l = 0; l < reliefLevels.length; l++) {
      final index = l == 2;
      final paint = Paint()
        ..color = contour.withValues(
          alpha: (index ? 0.6 : 0.34 + l * 0.05) * (dark ? 1.15 : 1),
        )
        ..strokeWidth = index ? 1.3 : 0.9
        ..strokeCap = StrokeCap.round;
      for (final (a, b) in reliefContour(
        area: area,
        level: reliefLevels[l],
        height: _height,
        cell: 14,
      )) {
        canvas.drawLine(a, b, paint);
      }
    }
    // A small peak on each hilltop, shaded on its eastern face.
    final line = Paint()
      ..color = palette.coast.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final face = Paint()..color = palette.coast.withValues(alpha: 0.35);
    for (final peak in peaks) {
      final top = peak + const Offset(0, -6);
      final left = peak + const Offset(-7, 5);
      final right = peak + const Offset(7, 5);
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..lineTo(right.dx, right.dy)
          ..lineTo(peak.dx + 1, right.dy)
          ..close(),
        face,
      );
      canvas.drawPath(
        Path()
          ..moveTo(left.dx, left.dy)
          ..lineTo(top.dx, top.dy)
          ..lineTo(right.dx, right.dy),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_ReliefPainter old) =>
      old.palette != palette ||
      old.here != here ||
      old.shift != shift ||
      old.seed != seed;
}

/// The roads over the land: the fog over what is not known yet and the ways
/// on.
class _JourneyPainter extends CustomPainter {
  _JourneyPainter({
    required this.palette,
    required this.here,
    required this.hereRadius,
    required this.stepRadius,
    required this.steps,
    required this.walking,
    required this.progress,
    this.reveals = const [],
    this.radial = false,
    this.roads,
  });

  /// The ways' roads through a city's streets (v1.203), from the party to
  /// each step, when the place has a plan; else each is a street or the
  /// road up the map.
  final List<Path>? roads;

  /// In a place (v1.181): the ways run out of the square every way, as
  /// streets, with no fog over the top.
  final bool radial;

  /// How much of each way's road has inked in (a new scene draws them out
  /// from the mark, one after the other); missing means all of it.
  final List<double> reveals;

  final ChartPalette palette;
  final Offset here;
  final double hereRadius;
  final double stepRadius;
  final List<({Offset centre, int row, bool locked, bool selected, bool moves})>
      steps;

  /// The step the party is walking to, and how far along it is.
  final int? walking;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Fog over the far side of the map.
    final fogRect = Rect.fromLTWH(-400, -400, size.width + 800, 490);
    if (!radial) {
      canvas.drawRect(
        fogRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.fog,
              palette.fog,
              palette.fog.withValues(alpha: 0),
            ],
            stops: const [0, 0.82, 1],
          ).createShader(fogRect),
      );
    }

    // The ways on: dashed, the chosen one drawn in full. Each leaves the
    // party's mark on the side it heads for, and the roads to the far
    // rows fade, so a town's many ways read as a fan rather than a knot.
    for (var s = 0; s < steps.length; s++) {
      final step = steps[s];
      // A way that keeps the party where it stands has no road to walk.
      if (!step.moves) continue;
      late final Offset start, end;
      if (radial) {
        final d = step.centre - here;
        final unit = d.distance == 0 ? const Offset(0, -1) : d / d.distance;
        start = here + unit * hereRadius;
        end = step.centre - unit * stepRadius;
      } else {
        final lean = ((step.centre.dx - here.dx) / size.width * 1.6).clamp(
          -math.pi / 3,
          math.pi / 3,
        );
        start = here +
            Offset(math.sin(lean) * hereRadius, -math.cos(lean) * hereRadius);
        end = step.centre.translate(0, stepRadius);
      }
      var path = roads != null && s < roads!.length
          ? _JourneyChartState._trimmed(roads![s], hereRadius, stepRadius)
          : radial
              ? placeStreet(start, end)
              : _roadPath(start, end);
      final reveal = s < reveals.length ? reveals[s] : 1.0;
      if (reveal <= 0) continue;
      if (reveal < 1) {
        final metric = path.computeMetrics().first;
        path = metric.extractPath(0, metric.length * reveal);
      }
      final fade = walking != null && walking != s ? 1 - progress * 0.8 : 1.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = step.selected ? 3 : 2
        ..color = step.selected
            ? palette.mark
            : step.locked
                ? palette.label.withValues(alpha: 0.4 * fade)
                : palette.ahead.withValues(
                    alpha:
                        (radial || step.row == 0 ? 1 : 0.75 / step.row) * fade,
                  );
      if (step.selected) {
        canvas.drawPath(path, paint);
      } else {
        _dashed(canvas, path, paint, dash: 6, gap: 6);
      }
    }
    // The road being walked, in the party's colour behind it.
    if (walking != null && walking! < steps.length && progress > 0) {
      final road = roads != null && walking! < roads!.length
          ? roads![walking!]
          : radial
              ? placeStreet(here, steps[walking!].centre)
              : _roadPath(here, steps[walking!].centre);
      for (final metric in road.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * progress),
          Paint()
            ..color = palette.mark
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  static void _dashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_JourneyPainter old) =>
      old.palette != palette ||
      old.here != here ||
      old.walking != walking ||
      old.progress != progress ||
      old.reveals.length != reveals.length ||
      [for (var i = 0; i < reveals.length; i++) old.reveals[i] != reveals[i]]
          .any((changed) => changed) ||
      old.radial != radial ||
      (old.roads == null) != (roads == null) ||
      old.steps.length != steps.length ||
      [for (var i = 0; i < steps.length; i++) old.steps[i] != steps[i]]
          .any((changed) => changed);
}

/// The streets growing out of the place as the ball is left (the dive): the
/// map comes up from four fifths of its size and out of the dark, over
/// [clock] (0 to 1).
class _GrowIn extends StatelessWidget {
  const _GrowIn({required this.clock, required this.child});

  final Animation<double> clock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: clock, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: t,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1).animate(t),
        child: child,
      ),
    );
  }
}
