// Charts that make a set of numbers readable at a glance (v1.224): a radar
// of any number of axes with one or more shapes, a rose of petals for the
// elements, and the same elements as plain rows. Each corner carries its
// own label and value as text, so nothing needs a legend to be read.
import 'dart:math';

import 'package:flutter/material.dart';

/// One axis of a [RadarChart]: its short label, the value shown under it, an
/// optional small [sub] line (a change, in [subColor]) and its colour.
class RadarAxis {
  const RadarAxis({
    required this.label,
    this.value,
    this.color,
    this.sub,
    this.subColor,
  });

  final String label;
  final String? value;
  final Color? color;
  final String? sub;
  final Color? subColor;
}

/// One shape drawn over the rings.
class RadarLayer {
  const RadarLayer({
    required this.values,
    required this.color,
    this.fill = 0.25,
    this.dashed = false,
    this.width = 2.5,
    this.dots = true,
  });

  final List<double> values;
  final Color color;
  final double fill;
  final bool dashed;
  final double width;
  final bool dots;
}

/// The point at [index] of [count] axes, [radius] from [center], the first
/// straight up and the rest clockwise.
Offset radarPoint(Offset center, double radius, int index, int count) {
  final a = -pi / 2 + index * 2 * pi / count;
  return center + Offset(cos(a), sin(a)) * radius;
}

class RadarChart extends StatelessWidget {
  const RadarChart({
    super.key,
    required this.axes,
    required this.layers,
    required this.max,
    this.rings = 3,
    this.size = 320,
    this.semanticsLabel,
    this.compact = false,
  });

  /// A small radar (v1.266): a larger shape, its labels one line close to
  /// its corners, so it fits a card at about 170 px.
  final bool compact;

  final List<RadarAxis> axes;
  final List<RadarLayer> layers;

  /// The value at the outer ring.
  final double max;
  final int rings;
  final double size;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final fit = box.hasBoundedWidth ? min(size, box.maxWidth) : size;
      return _build(context, fit);
    });
  }

  Widget _build(BuildContext context, double size) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = size * (compact ? 0.30 : 0.28);
    final labelRadius = radius + (compact ? 12 : 21);
    final center = Offset(size / 2, size / 2);
    final n = axes.length;
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: SizedBox(
        width: size,
        height: size,
        child: ExcludeSemantics(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RadarPainter(
                    count: n,
                    layers: layers,
                    max: max,
                    rings: rings,
                    radius: radius,
                    gridColor: scheme.outlineVariant,
                  ),
                ),
              ),
              for (var i = 0; i < n; i++)
                _label(
                    theme, scheme, axes[i], i, n, center, labelRadius, compact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, ColorScheme scheme, RadarAxis axis, int i,
      int n, Offset center, double labelRadius, bool compact) {
    final at = radarPoint(center, labelRadius, i, n);
    final a = -pi / 2 + i * 2 * pi / n;
    final align = Offset(-0.5 + cos(a) * 0.5, -0.5 + sin(a) * 0.5);
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: FractionalTranslation(
        translation: align,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(axis.label,
                style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: compact ? 10.5 : 11.5,
                    letterSpacing: 0.4,
                    color:
                        axis.color ?? scheme.onSurface.withValues(alpha: 0.8))),
            if (axis.value != null)
              Text(axis.value!,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontSize: 16, color: scheme.onSurface)),
            if (axis.sub != null)
              Text(axis.sub!,
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: axis.subColor ?? const Color(0xFF6FD08C))),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.count,
    required this.layers,
    required this.max,
    required this.rings,
    required this.radius,
    required this.gridColor,
  });

  final int count;
  final List<RadarLayer> layers;
  final double max;
  final int rings;
  final double radius;
  final Color gridColor;

  Path _polygon(Offset c, List<double> values) {
    final path = Path();
    for (var i = 0; i < count; i++) {
      final v = (i < values.length ? values[i] : 0).clamp(0, max).toDouble();
      final p = radarPoint(c, radius * v / max, i, count);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor;
    for (var k = 1; k <= rings; k++) {
      final r = radius * k / rings;
      final path = Path();
      for (var i = 0; i < count; i++) {
        final p = radarPoint(c, r, i, count);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path,
          grid..color = gridColor.withValues(alpha: k == rings ? 1 : 0.6));
    }
    for (var i = 0; i < count; i++) {
      canvas.drawLine(c, radarPoint(c, radius, i, count),
          grid..color = gridColor.withValues(alpha: 0.7));
    }
    for (final layer in layers) {
      final path = _polygon(c, layer.values);
      if (layer.fill > 0) {
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.fill
              ..color = layer.color.withValues(alpha: layer.fill));
      }
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer.width
        ..strokeJoin = StrokeJoin.round
        ..color = layer.color;
      if (layer.dashed) {
        for (final metric in path.computeMetrics()) {
          var d = 0.0;
          while (d < metric.length) {
            canvas.drawPath(
                metric.extractPath(d, min(d + 6, metric.length)), stroke);
            d += 10;
          }
        }
      } else {
        canvas.drawPath(path, stroke);
      }
      if (layer.dots) {
        final dot = Paint()..color = layer.color;
        for (var i = 0; i < count; i++) {
          final v = (i < layer.values.length ? layer.values[i] : 0)
              .clamp(0, max)
              .toDouble();
          canvas.drawCircle(radarPoint(c, radius * v / max, i, count),
              layer.dashed ? 2.5 : 3.5, dot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.layers != layers ||
      old.max != max ||
      old.count != count ||
      old.radius != radius;
}

/// A rose of petals: petal [i] reaches out for [outer] points of its own
/// colour and a steel arc lies inside for [inner]; the labels sit around it.
class RoseChart extends StatelessWidget {
  const RoseChart({
    super.key,
    required this.axes,
    required this.outer,
    required this.inner,
    required this.max,
    required this.innerColor,
    this.size = 320,
    this.semanticsLabel,
  });

  final List<RadarAxis> axes;
  final List<double> outer;
  final List<double> inner;
  final double max;
  final Color innerColor;
  final double size;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final fit = box.hasBoundedWidth ? min(size, box.maxWidth) : size;
      return _build(context, fit);
    });
  }

  Widget _build(BuildContext context, double size) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = size * 0.28;
    final center = Offset(size / 2, size / 2);
    final n = axes.length;
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: SizedBox(
        width: size,
        height: size,
        child: ExcludeSemantics(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RosePainter(
                    colors: [for (final a in axes) a.color ?? scheme.primary],
                    outer: outer,
                    inner: inner,
                    max: max,
                    radius: radius,
                    innerColor: innerColor,
                    gridColor: scheme.outlineVariant,
                    holeColor: scheme.surface,
                  ),
                ),
              ),
              for (var i = 0; i < n; i++)
                _roseLabel(theme, scheme, axes[i], i, n, center, radius + 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roseLabel(ThemeData theme, ColorScheme scheme, RadarAxis axis, int i,
      int n, Offset center, double labelRadius) {
    final at = radarPoint(center, labelRadius, i, n);
    final a = -pi / 2 + i * 2 * pi / n;
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: FractionalTranslation(
        translation: Offset(-0.5 + cos(a) * 0.5, -0.5 + sin(a) * 0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(axis.label,
                style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 11.5,
                    letterSpacing: 0.4,
                    color: axis.color ?? scheme.onSurface)),
            if (axis.value != null)
              Text(axis.value!,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontSize: 15, color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _RosePainter extends CustomPainter {
  _RosePainter({
    required this.colors,
    required this.outer,
    required this.inner,
    required this.max,
    required this.radius,
    required this.innerColor,
    required this.gridColor,
    required this.holeColor,
  });

  final List<Color> colors;
  final List<double> outer;
  final List<double> inner;
  final double max;
  final double radius;
  final Color innerColor;
  final Color gridColor;
  final Color holeColor;

  static const double _hole = 0.22;

  Path _wedge(Offset c, double a0, double a1, double rIn, double rOut) {
    final path = Path();
    path.moveTo(c.dx + cos(a0) * rIn, c.dy + sin(a0) * rIn);
    path.arcTo(Rect.fromCircle(center: c, radius: rOut), a0, a1 - a0, false);
    path.arcTo(Rect.fromCircle(center: c, radius: rIn), a1, a0 - a1, false);
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final n = colors.length;
    final hole = radius * _hole;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor.withValues(alpha: 0.7);
    for (var k = 1; k <= 4; k++) {
      canvas.drawCircle(c, hole + (radius - hole) * k / 4, ring);
    }
    final step = 2 * pi / n;
    for (var i = 0; i < n; i++) {
      final mid = -pi / 2 + i * step;
      final a0 = mid - step * 0.39;
      final a1 = mid + step * 0.39;
      final o = (i < outer.length ? outer[i] : 0).clamp(0, max).toDouble();
      final r = (i < inner.length ? inner[i] : 0).clamp(0, max).toDouble();
      if (o > 0) {
        final reach = hole + (radius - hole) * o / max;
        final path = _wedge(c, a0, a1, hole, reach);
        canvas.drawPath(
            path, Paint()..color = colors[i].withValues(alpha: 0.75));
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = colors[i]);
      }
      if (r > 0) {
        final depth = hole * 0.9 * r / max;
        final path = _wedge(c, a0, a1, hole - depth, hole);
        canvas.drawPath(
            path, Paint()..color = innerColor.withValues(alpha: 0.7));
      }
    }
    canvas.drawCircle(c, hole * 0.55, Paint()..color = holeColor);
  }

  @override
  bool shouldRepaint(_RosePainter old) =>
      old.outer != outer || old.inner != inner || old.max != max;
}
