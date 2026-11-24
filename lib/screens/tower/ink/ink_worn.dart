// Wear on an ink piece, from a seed (v2.1, UX-2): a tear on the right edge, a
// chipped corner, a folded corner, a burn mark, stains, ink splatter, a pin and
// a small tilt. [InkWorn] puts them on any child; the same [InkSeed] always
// gives the same look. Drawn in code; Art's masks and stains would replace the
// drawn ones. The marks lie over the piece but never change its size, and its
// label sits where it did.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../theme/palette.dart';
import 'ink_palette.dart';
import 'ink_seed.dart';

class InkWorn extends StatelessWidget {
  const InkWorn({
    super.key,
    required this.seed,
    required this.child,
    this.tear = false,
    this.tilt = true,
    this.marks = true,
    this.chip = true,
  });

  final InkSeed seed;
  final Widget child;

  /// A torn right edge (strips and tabs); a chip, if the seed has one, shows
  /// on every piece.
  final bool tear;

  /// The 1 to 3 degrees of tilt (not for a panel that holds a screen's worth).
  final bool tilt;

  final bool marks;

  /// Whether the seed's chipped corner cuts the piece (not a panel that
  /// carries a tab outside its box).
  final bool chip;

  @override
  Widget build(BuildContext context) {
    Widget w = child;
    if (marks) {
      w = Stack(clipBehavior: Clip.none, children: [
        w,
        Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: InkMarks(seed)))),
        if (seed.pin)
          Positioned(
              left: 4,
              top: 3,
              child: IgnorePointer(
                child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: seed.n % 4 == 0 ? inkRedDeep : inkGrey,
                        border: Border.all(color: inkBlack, width: 0.8))),
              )),
      ]);
    }
    if (tear || (chip && seed.chip)) {
      w = ClipPath(clipper: InkTear(seed, tear: tear, chip: chip), child: w);
    }
    return tilt ? Transform.rotate(angle: seed.tilt, child: w) : w;
  }
}

/// The silhouette: straight, with a seeded torn right edge and a chipped
/// corner when the seed has them.
class InkTear extends CustomClipper<Path> {
  InkTear(this.seed, {required this.tear, this.chip = true});
  final bool chip;
  final InkSeed seed;
  final bool tear;

  @override
  Path getClip(Size s) {
    final chipped = chip && seed.chip;
    final p = Path()..moveTo(0, 0);
    p.lineTo(s.width - (chipped ? 7 : 0), 0);
    if (chipped) p.lineTo(s.width, 7);
    if (tear) {
      final t = seed.teeth(6);
      final h = s.height / t.length;
      for (var i = 0; i < t.length; i++) {
        p.lineTo(s.width - t[i], h * i + h * 0.4);
        p.lineTo(s.width - t[(i + 2) % t.length] * 0.4, h * (i + 1));
      }
    } else {
      p.lineTo(s.width, s.height);
    }
    p.lineTo(0, s.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(InkTear old) =>
      old.seed != seed || old.tear != tear || old.chip != chip;
}

/// Stains, splatter, a burn and a folded corner, from the seed.
class InkMarks extends CustomPainter {
  InkMarks(this.seed);
  final InkSeed seed;

  @override
  void paint(Canvas canvas, Size s) {
    final r = math.Random(seed.n * 101 + 7);
    for (var i = 0; i < seed.stains; i++) {
      final c = Offset(r.nextDouble() * s.width, r.nextDouble() * s.height);
      canvas.drawCircle(c, 5 + r.nextDouble() * 9,
          Paint()..color = Palette.night28.withValues(alpha: 0.13));
    }
    for (var i = 0; i < seed.splatters; i++) {
      final c = Offset(r.nextDouble() * s.width, r.nextDouble() * s.height);
      canvas.drawCircle(
          c,
          0.6 + r.nextDouble() * 1.4,
          Paint()
            ..color =
                (i.isEven ? inkBlack : inkRedDeep).withValues(alpha: 0.55));
    }
    if (seed.burn) {
      final c = Offset(s.width, s.height * 0.8);
      canvas.drawCircle(
          c,
          14,
          Paint()
            ..shader = ui.Gradient.radial(c, 14, [
              Palette.night7.withValues(alpha: 0.67),
              Palette.night7.withValues(alpha: 0),
            ]));
    }
    if (seed.fold) {
      final p = Path()
        ..moveTo(s.width - 12, s.height)
        ..lineTo(s.width, s.height - 12)
        ..lineTo(s.width, s.height)
        ..close();
      canvas.drawPath(p, Paint()..color = inkBlack.withValues(alpha: 0.45));
      canvas.drawLine(
          Offset(s.width - 12, s.height),
          Offset(s.width, s.height - 12),
          Paint()
            ..color = inkPaper.withValues(alpha: 0.5)
            ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(InkMarks old) => old.seed != seed;
}
