// The floor under a dropped throw (dice_throw.dart's DiceThrowPlan.drop): each
// die's shadow on the stone, small and faint while it is high and growing and
// sharpening as it falls, and a puff of dust or snow at every contact. Drawn
// under the dice; a pure function of the throw's progress.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../screens/tower/ink/ink_palette.dart';
import 'dice_throw.dart';

class DiceGroundPainter extends CustomPainter {
  const DiceGroundPainter(this.plan, this.u);

  final DiceThrowPlan plan;

  /// The throw's progress, 0 to 1.
  final double u;

  static double _hash(int i, int salt) {
    final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    const seconds = diceDropMs / 1000;
    for (var i = 0; i < plan.count; i++) {
      final ground = plan.position(i, u);
      final r = plan.radiusOf(i);
      final lift = plan.lift(i, u);
      // Near the floor: 1; high above it: 0.
      final near = 1 - (lift / (r * 5)).clamp(0.0, 1.0);
      final k = 0.4 + 0.6 * near;
      final centre = ground + Offset(0, r * 0.8);
      void shadow(double scale, double alpha) {
        canvas.drawOval(
            Rect.fromCenter(
                center: centre, width: 2 * r * scale, height: r * 0.62 * scale),
            Paint()
              ..isAntiAlias = false
              ..color = const Color(0xFF000000).withValues(alpha: alpha));
      }

      // A soft wide shadow while it falls, a sharp small one near the floor.
      shadow(k * 1.3, 0.14 * near + 0.04);
      shadow(k, 0.12 + 0.34 * near);
      // The dust of each contact.
      final spots = plan.contacts[i];
      for (var c = 0; c < spots.length; c++) {
        final dt = (u - spots[c]) * seconds;
        if (dt < 0 || dt > 0.34) continue;
        final t = dt / 0.34;
        final n = c == 0 ? 10 : (c == 1 ? 6 : 4);
        for (var p = 0; p < n; p++) {
          final side = p.isEven ? -1.0 : 1.0;
          final speed = (46 + 80 * _hash(p, c + i * 7)) * (c == 0 ? 1.0 : 0.7);
          final x = side * speed * dt * (0.5 + 0.5 * _hash(p, 5));
          final y = -(26 + 30 * _hash(p, 9)) * dt + 110 * dt * dt;
          final s = (4 - 2 * t).roundToDouble().clamp(2.0, 4.0);
          final at = ground + Offset(x, r * 0.9 + y);
          canvas.drawRect(
              Rect.fromLTWH(at.dx.roundToDouble(), at.dy.roundToDouble(), s, s),
              Paint()
                ..isAntiAlias = false
                ..color = (p % 3 == 0 ? inkGrey : inkPaper)
                    .withValues(alpha: 0.85 * (1 - t)));
        }
      }
    }
  }

  @override
  bool shouldRepaint(DiceGroundPainter old) => old.u != u || old.plan != plan;
}
