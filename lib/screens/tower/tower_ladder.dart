// The Tower's ladder (v1.847+; v1.900 as a stair of arched windows): 30 floors
// from the bottom (1) to the top (30), a window lit gold for each floor
// climbed, the floor the party stands on glowing with its number, the
// wardens (5, 15, 25) wider and the bosses (10, 20, 30) widest and ringed in
// blood, with their number in them.
import 'package:flutter/material.dart';

import '../../data/tower/tower_tables.dart';
import '../../theme/palette.dart';
import '../../theme/stitched_ink.dart';

/// The width the ladder takes.
const double towerLadderWidth = 40;

class TowerLadder extends StatelessWidget {
  const TowerLadder({super.key, required this.floor, this.jump});

  /// How the last event moved the run: from this floor to [floor] (a skip up,
  /// a fall down), drawn as an arrow beside the rail.
  final (int, int)? jump;

  /// The floor the party stands on (1 to 30).
  final int floor;

  static bool isWarden(int n) => n % 10 == 5;
  static bool isBoss(int n) => n % 10 == 0;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final label = Theme.of(context).textTheme.labelSmall;
    const night = Color(0xFF211E28);
    const dark = Palette.night8c;
    Widget stone(int n) {
      final here = n == floor;
      final lit = n <= floor;
      final w = isBoss(n)
          ? towerLadderWidth - 4
          : isWarden(n)
              ? 28.0
              : 20.0;
      return Container(
        width: w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: night,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color: isBoss(n) ? ink.blood : dark, width: 1.2),
          boxShadow: here
              ? [
                  BoxShadow(
                      color: ink.gold.withValues(alpha: .7), blurRadius: 9)
                ]
              : null,
        ),
        child: here
            ? Text('$n',
                // The serif digits: the pixel face fills in at this size
                // (a 26 read as 88).
                style: label?.copyWith(
                    fontFamily: InkFonts.prose,
                    fontWeight: FontWeight.w800,
                    color: ink.gold,
                    height: 1))
            : isBoss(n)
                ? Text('$n',
                    style: label?.copyWith(color: Colors.white70, height: 1))
                : Container(
                    width: w * 0.36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: lit ? ink.gold.withValues(alpha: .85) : dark,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
      );
    }

    final rail = SizedBox(
      key: const Key('tower_ladder'),
      width: towerLadderWidth,
      child: Column(
        children: [
          for (var n = towerTop; n >= 1; n--)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Center(
                  child: n == floor
                      ? KeyedSubtree(
                          key: const Key('tower_ladder_here'), child: stone(n))
                      : stone(n),
                ),
              ),
            ),
        ],
      ),
    );
    final jump = this.jump;
    if (jump == null) return rail;
    return Stack(children: [
      rail,
      Positioned.fill(
          child: IgnorePointer(
              child: CustomPaint(
                  painter:
                      _JumpPainter(jump.$1, jump.$2, ink.gold, ink.blood)))),
    ]);
  }
}

/// An arrow along the rail from floor [from] to floor [to]: gold going up,
/// blood coming down, dashed, with its head on the floor the run lands on.
class _JumpPainter extends CustomPainter {
  _JumpPainter(this.from, this.to, this.up, this.down);

  final int from, to;
  final Color up, down;

  @override
  void paint(Canvas canvas, Size size) {
    final row = size.height / towerTop;
    double y(int n) => (towerTop - n) * row + row / 2;
    final color = to > from ? up : down;
    final x = size.width + 5;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final y0 = y(from), y1 = y(to);
    final dir = y1 > y0 ? 1.0 : -1.0;
    var yy = y0;
    while ((y1 - yy) * dir > 8) {
      canvas.drawLine(Offset(x, yy), Offset(x, yy + dir * 6), paint);
      yy += dir * 11;
    }
    final head = Path()
      ..moveTo(x, y1)
      ..lineTo(x - 5, y1 - dir * 9)
      ..lineTo(x + 5, y1 - dir * 9)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
    canvas.drawCircle(Offset(x, y0), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_JumpPainter old) =>
      old.from != from || old.to != to || old.up != up || old.down != down;
}
