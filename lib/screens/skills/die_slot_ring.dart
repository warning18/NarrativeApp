import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The largest a slot of the ring gets (a d4 to a d8 on a phone).
const double ringSlotMax = 96;

/// Below this a slot drops its name: the die card above tells the picked
/// face's name in full (a d12 or a d20 on a phone).
const double ringSlotCompact = 70;

const double _gap = 6;

/// Where face [i] of [n] sits on a ring of radius 1: the first at the top,
/// the rest clockwise.
Offset ringSpot(int i, int n) {
  final angle = -math.pi / 2 + 2 * math.pi * i / n;
  return Offset(math.cos(angle), math.sin(angle));
}

/// How far apart two neighbours on a ring of radius 1 are.
double _spread(int n) => 2 * math.sin(math.pi / n);

/// The side of one slot for [n] slots on a ring at most [width] wide: as
/// large as fits with [_gap] between neighbours, at most [ringSlotMax].
double ringSlotSide(int n, double width) {
  if (n <= 1) return math.min(ringSlotMax, width);
  final half = _spread(n) / 2;
  return ((width * half - _gap) / (1 + half)).clamp(28.0, ringSlotMax);
}

/// The radius of the ring's centres for [n] slots of [side]: neighbours
/// [_gap] apart, and room in the middle for the die's size and fill.
double ringRadius(int n, double side) {
  final apart = n <= 1 ? 0.0 : (side + _gap) / _spread(n);
  return math.max(apart, side / 2 + 44);
}

/// A die's faces as one ring of round slots, one per face, the first at the top
/// and the rest clockwise, as the faces of a real die go round it. The
/// middle shows [center] (the die's size and how many faces hold a skill).
class DieSlotRing extends StatelessWidget {
  const DieSlotRing({
    super.key,
    required this.count,
    required this.slot,
    required this.center,
  });

  /// The die's face count: every face is a slot.
  final int count;

  /// Face [index]'s round slot, [side] px across; [compact] when too small
  /// for a name.
  final Widget Function(int index, double side, bool compact) slot;
  final Widget center;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final width = math.min(box.maxWidth, 420.0);
      final side = ringSlotSide(count, width);
      final radius = ringRadius(count, side);
      final extent = math.min(width, 2 * radius + side);
      final mid = extent / 2;
      return Center(
        child: SizedBox(
          key: const Key('die_slot_ring'),
          width: extent,
          height: extent,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingPainter(
                    radius: radius,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              Positioned(
                left: mid - (radius - side / 2) + 4,
                top: mid - (radius - side / 2) + 4,
                width: 2 * (radius - side / 2) - 8,
                height: 2 * (radius - side / 2) - 8,
                child: Center(child: center),
              ),
              for (var i = 0; i < count; i++)
                Positioned(
                  left: mid + radius * ringSpot(i, count).dx - side / 2,
                  top: mid + radius * ringSpot(i, count).dy - side / 2,
                  width: side,
                  height: side,
                  child: slot(i, side, side < ringSlotCompact),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// The thin circle the slots sit on.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
        size.center(Offset.zero),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.radius != radius || old.color != color;
}
