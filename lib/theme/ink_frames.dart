// The frames of the app's look (v1.901, the Art pack "final panels and
// buttons": A panels, C buttons), painted in code from art/pixellab-pilots/
// final/panels/spec.json: 1 art pixel = 2 dp, drawn without antialiasing.
//
// A panel is a double ink line: an outer dark line, an inner seam line 6 dp
// inside it, and a stitch dot in each corner. A button is a flat pixel frame
// with a bevel: a 2 dp outline, a light edge inside the top and left, a
// shade inside the bottom and right (swapped when pressed, none when
// disabled). The corner tokens stay: 4 dp for buttons and cards, 10 dp for
// the panels that had it.
import 'package:flutter/material.dart';

const double _px = 2; // dp per art pixel

/// The outline colours of the pack: the dark theme's and the parchment's.
const Color inkOutlineDark = Color(0xFF0E0D10);
const Color inkOutlineParchment = Color(0xFF231F1A);

/// The ink outline for a theme of [brightness].
Color inkOutlineFor(Brightness brightness) =>
    brightness == Brightness.dark ? inkOutlineDark : inkOutlineParchment;

/// The border of a panel: the double ink line with its corner stitches.
class InkPanelBorder extends ShapeBorder {
  const InkPanelBorder({
    this.radius = 4,
    required this.outer,
    required this.inner,
  });

  final double radius;

  /// The outer line and the inner (seam) line, with the stitches.
  final Color outer, inner;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(_px);

  RRect _rrect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect).deflate(_px));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    Paint line(double w, Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c
      ..isAntiAlias = false;
    final r = _rrect(rect);
    canvas.drawRRect(r.deflate(_px / 2), line(_px, outer));
    if (rect.shortestSide < 6 * _px + 8) return;
    // The inner line, 6 dp inside (3 art pixels), with a stitch in each corner.
    final inset = r.deflate(3 * _px + _px / 2);
    canvas.drawRRect(inset, line(_px, inner));
    final dot = Paint()
      ..color = inner
      ..isAntiAlias = false;
    const d = _px;
    for (final o in [
      Offset(rect.left + _px, rect.top + _px),
      Offset(rect.right - _px - d, rect.top + _px),
      Offset(rect.left + _px, rect.bottom - _px - d),
      Offset(rect.right - _px - d, rect.bottom - _px - d),
    ]) {
      canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, d, d), dot);
    }
  }

  @override
  ShapeBorder scale(double t) =>
      InkPanelBorder(radius: radius * t, outer: outer, inner: inner);
}

/// The border of a button: the flat pixel frame with a bevel.
class InkButtonBorder extends OutlinedBorder {
  const InkButtonBorder({
    this.radius = 4,
    required this.outline,
    this.pressed = false,
    this.flat = false,
    super.side = BorderSide.none,
  });

  final double radius;
  final Color outline;

  /// Pressed: the bevel swaps sides. [flat]: disabled, no bevel.
  final bool pressed, flat;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(_px);

  RRect _rrect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect).deflate(_px));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    Paint line(double w, Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c
      ..isAntiAlias = false;
    final r = _rrect(rect);
    final edge = side.style == BorderStyle.none ? outline : side.color;
    canvas.drawRRect(r.deflate(_px / 2), line(_px, edge));
    if (flat) return;
    final b = r.deflate(_px + _px / 2);
    final light = Colors.white.withValues(alpha: pressed ? .16 : .34);
    final shade = Colors.black.withValues(alpha: pressed ? .34 : .20);
    final rad = (radius - _px).clamp(0.0, 99.0);
    final top = Path()
      ..moveTo(b.left, b.bottom - rad)
      ..lineTo(b.left, b.top + rad)
      ..lineTo(b.left + rad, b.top)
      ..lineTo(b.right - rad, b.top);
    final bottom = Path()
      ..moveTo(b.right, b.top + rad)
      ..lineTo(b.right, b.bottom - rad)
      ..lineTo(b.right - rad, b.bottom)
      ..lineTo(b.left + rad, b.bottom);
    canvas.drawPath(top, line(_px, pressed ? shade : light));
    canvas.drawPath(bottom, line(_px, pressed ? light : shade));
  }

  @override
  OutlinedBorder copyWith({BorderSide? side}) => InkButtonBorder(
      radius: radius,
      outline: outline,
      pressed: pressed,
      flat: flat,
      side: side ?? this.side);

  @override
  ShapeBorder scale(double t) => InkButtonBorder(
      radius: radius * t,
      outline: outline,
      pressed: pressed,
      flat: flat,
      side: side.scale(t));
}

/// The shape of a button in each of its states, for a ButtonStyle.
WidgetStateProperty<OutlinedBorder?> inkButtonShape(Color outline,
        {double radius = 4}) =>
    WidgetStateProperty.resolveWith((states) => InkButtonBorder(
          radius: radius,
          outline: outline,
          pressed: states.contains(WidgetState.pressed),
          flat: states.contains(WidgetState.disabled),
        ));
