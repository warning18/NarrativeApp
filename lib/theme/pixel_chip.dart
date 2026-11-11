// The shape of the game's chips, tabs and tags (v1.908): a rectangle whose
// corners step like pixels (three steps of 2 dp, 1 art pixel = 2 dp), in place
// of the pill or the rounded rectangle. Drawn without antialiasing so the
// steps stay crisp, with the same border the chip had.
import 'package:flutter/material.dart';

class PixelChipBorder extends OutlinedBorder {
  const PixelChipBorder({super.side, this.step = 2, this.steps = 3});

  /// The size of one step, in dp, and how many there are at each corner.
  final double step;
  final int steps;

  Path _path(Rect rect) {
    // A short chip gets smaller corners: never more than a quarter of its
    // height in each step run.
    final c = (steps * step).clamp(0.0, rect.shortestSide / 4);
    final s = c / steps;
    final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
    final p = Path()..moveTo(l + c, t);
    p.lineTo(r - c, t);
    for (var i = 0; i < steps; i++) {
      p
        ..lineTo(r - c + (i + 1) * s, t + i * s)
        ..lineTo(r - c + (i + 1) * s, t + (i + 1) * s);
    }
    p.lineTo(r, b - c);
    for (var i = 0; i < steps; i++) {
      p
        ..lineTo(r - i * s, b - c + (i + 1) * s)
        ..lineTo(r - (i + 1) * s, b - c + (i + 1) * s);
    }
    p.lineTo(l + c, b);
    for (var i = 0; i < steps; i++) {
      p
        ..lineTo(l + c - (i + 1) * s, b - i * s)
        ..lineTo(l + c - (i + 1) * s, b - (i + 1) * s);
    }
    p.lineTo(l, t + c);
    for (var i = 0; i < steps; i++) {
      p
        ..lineTo(l + i * s, t + c - (i + 1) * s)
        ..lineTo(l + (i + 1) * s, t + c - (i + 1) * s);
    }
    return p..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
        _path(rect.deflate(side.width / 2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = side.width
          ..strokeJoin = StrokeJoin.miter
          ..color = side.color
          ..isAntiAlias = false);
  }

  @override
  PixelChipBorder copyWith({BorderSide? side}) =>
      PixelChipBorder(side: side ?? this.side, step: step, steps: steps);

  @override
  ShapeBorder scale(double t) =>
      PixelChipBorder(side: side.scale(t), step: step, steps: steps);
}
