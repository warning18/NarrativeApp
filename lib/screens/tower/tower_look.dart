// PROTOTYPE (UX-2, the Tower interface design, not for merge): which look the
// Tower's screens wear while the design is drawn. [none] is today's.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../widgets/fight_sprites.dart';

enum TowerLookOption { none, a, b }

/// Set by the picture test only.
TowerLookOption towerLook = TowerLookOption.none;

bool get towerLooked => towerLook != TowerLookOption.none;

/// A+C panel: a double ink line (an outer dark line, a gap, an inner seam)
/// with a bevel (a light top-left edge and a shaded bottom-right edge inside).
class BevelPanelPainter extends CustomPainter {
  BevelPanelPainter({
    required this.outer,
    required this.inner,
    required this.light,
    required this.shade,
    required this.radius,
  });

  final Color outer, inner, light, shade;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.drawRRect(
        r.deflate(0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = outer);
    final inset = r.deflate(3.5);
    canvas.drawRRect(
        inset,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = inner);
    // The bevel: two edges just inside the inner line.
    final b = inset.deflate(1.5);
    final top = Path()
      ..moveTo(b.left, b.bottom - radius)
      ..lineTo(b.left, b.top + radius)
      ..quadraticBezierTo(b.left, b.top, b.left + radius, b.top)
      ..lineTo(b.right - radius, b.top);
    final bottom = Path()
      ..moveTo(b.right, b.top + radius)
      ..lineTo(b.right, b.bottom - radius)
      ..quadraticBezierTo(b.right, b.bottom, b.right - radius, b.bottom)
      ..lineTo(b.left + radius, b.bottom);
    canvas.drawPath(
        top,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = light);
    canvas.drawPath(
        bottom,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = shade);
  }

  @override
  bool shouldRepaint(BevelPanelPainter old) => true;
}

/// A foe standing, for the proposed look B: its sprite, west-facing as drawn.
class TowerFoeFigure extends StatelessWidget {
  const TowerFoeFigure(this.enemyId, {super.key, this.size = 52});

  final String enemyId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final set = enemyFightSprite(enemyId);
    if (set == null) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: FightSpriteImages.loaded,
      builder: (context, _, __) {
        final image = FightSpriteImages.idleOf(set);
        return SizedBox(
          width: size,
          height: size,
          child: image == null
              ? null
              : CustomPaint(
                  painter: _FoePainter(image, set.frameWidth, set.frameHeight)),
        );
      },
    );
  }
}

class _FoePainter extends CustomPainter {
  _FoePainter(this.image, this.w, this.h);
  final ui.Image image;
  final int w, h;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false);
  @override
  bool shouldRepaint(_FoePainter old) => old.image != image;
}
