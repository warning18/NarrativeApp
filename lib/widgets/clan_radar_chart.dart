// A clan's orientation as a small five-axis radar (Wave 7 D): what its gifts
// lean on, from clanRadarProvider (might, guard, mending, arcana, fortune),
// the strongest axis reaching the rim. Drawn in the clan's colour, for the
// clan offer's charter and the Clans screen's compass.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clan_radar.dart';
import '../l10n/app_strings.dart';
import '../providers/clan_radar_provider.dart';
import '../theme/stitched_ink.dart';

/// The label key of [axis].
String radarAxisKey(RadarAxis axis) => 'radar_axis_${axis.name}';

class ClanRadarChart extends ConsumerWidget {
  const ClanRadarChart({
    super.key,
    required this.factionId,
    required this.color,
    this.size = 112,
  });

  final String factionId;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radar = ref.watch(clanRadarProvider(factionId));
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    final labels = [
      for (final axis in RadarAxis.values) tr(ref, radarAxisKey(axis)),
    ];
    return Semantics(
      label: [
        for (final (i, axis) in RadarAxis.values.indexed)
          '${labels[i]} ${((radar.orientation[axis] ?? 0) * 100).round()}%',
      ].join(', '),
      child: SizedBox(
        key: Key('clan_radar_$factionId'),
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RadarPainter(
            values: [
              for (final axis in RadarAxis.values) radar.orientation[axis] ?? 0,
            ],
            labels: labels,
            color: color,
            grid: ink.seam,
            text: ink.ash,
            textStyle: theme.textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.grid,
    required this.text,
    required this.textStyle,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final Color grid;
  final Color text;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 24;
    Offset at(int i, double f) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      return c + Offset(math.cos(a), math.sin(a)) * (r * f);
    }

    final gridPaint = Paint()
      ..color = grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final f in const [0.5, 1.0]) {
      final ring = Path()..moveTo(at(0, f).dx, at(0, f).dy);
      for (var i = 1; i < n; i++) {
        ring.lineTo(at(i, f).dx, at(i, f).dy);
      }
      canvas.drawPath(ring..close(), gridPaint);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, at(i, 1), gridPaint);
    }
    final shape = Path();
    for (var i = 0; i < n; i++) {
      // A little floor, so an empty axis still reads as a corner.
      final p = at(i, 0.08 + 0.92 * values[i].clamp(0.0, 1.0));
      i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    canvas.drawPath(shape, Paint()..color = color.withValues(alpha: 0.32));
    canvas.drawPath(
        shape,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round);
    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(
            text: labels[i],
            style: (textStyle ?? const TextStyle()).copyWith(
                color: text, fontSize: 9, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final p = at(i, 1.0);
      final dir = p - c;
      // Pushed out from the rim along the spoke.
      final o = p + (dir / dir.distance) * (tp.height * 0.7 + 3);
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.values != values || old.color != color || old.labels != labels;
}
