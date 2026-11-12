// The Tower's ladder (v1.847+; v1.900 as a stair of arched windows): 30 floors
// from the bottom (1) to the top (30), a window lit gold for each floor
// climbed, the floor the party stands on glowing with its number, the
// wardens (5, 15, 25) wider and the bosses (10, 20, 30) widest and ringed in
// blood, with their number in them.
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/tower/tower_tables.dart';
import '../../theme/palette.dart';
import '../../theme/stitched_ink.dart';
import '../../widgets/head_avatar.dart';

/// The width the ladder takes.
const double towerLadderWidth = 40;

class TowerLadder extends StatefulWidget {
  const TowerLadder({super.key, required this.floor, this.jump});

  /// How the last event moved the run: from this floor to [floor] (a skip up,
  /// a fall down), drawn as an arrow beside the rail.
  final (int, int)? jump;

  /// The floor the party stands on (1 to 30). When it changes, the hero's
  /// head on the rail walks to the new notch (see [TowerLadderState]).
  final int floor;

  static bool isWarden(int n) => n % 10 == 5;
  static bool isBoss(int n) => n % 10 == 0;

  @override
  State<TowerLadder> createState() => TowerLadderState();
}

/// How long the head takes to climb to its notch.
const Duration towerStepDuration = Duration(milliseconds: 1000);

class TowerLadderState extends State<TowerLadder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _step =
      AnimationController(vsync: this, duration: towerStepDuration);
  late double _from = widget.floor.toDouble();
  late double _to = widget.floor.toDouble();

  /// The floor the head stands on now, between floors while it walks.
  double get headFloor =>
      _from + (_to - _from) * Curves.easeInOut.transform(_step.value);

  /// Puts the head on its notch at once (a tap, or reduced motion).
  void skip() {
    if (_step.isAnimating) _step.value = 1;
  }

  @override
  void didUpdateWidget(TowerLadder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.floor == widget.floor) return;
    final here = headFloor;
    _from = here;
    _to = widget.floor.toDouble();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _step.value = 1;
    } else {
      _step.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _step.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final label = Theme.of(context).textTheme.labelSmall;
    const night = Color(0xFF211E28);
    const dark = Palette.night8c;
    final floor = widget.floor;
    const isBoss = TowerLadder.isBoss;
    const isWarden = TowerLadder.isWarden;
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
        // The notch stood on shows no number of its own: the head's tag
        // above carries it.
        child: here
            ? const SizedBox.shrink()
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
    final jump = widget.jump;
    return Stack(children: [
      rail,
      if (jump != null)
        Positioned.fill(
            child: IgnorePointer(
                child: CustomPaint(
                    painter:
                        _JumpPainter(jump.$1, jump.$2, ink.gold, ink.blood)))),
      // The hero's head on the rail: it walks up (or down) to its notch.
      Positioned.fill(
        child: IgnorePointer(
          child: LayoutBuilder(builder: (context, box) {
            final row = box.maxHeight / towerTop;
            final size = min(row * 1.15, 26.0);
            return AnimatedBuilder(
              animation: _step,
              builder: (context, _) => Stack(children: [
                Positioned(
                  key: const Key('tower_ladder_head'),
                  left: (box.maxWidth - size) / 2,
                  top: (towerTop - headFloor) * row + row / 2 - size / 2,
                  width: size,
                  height: size,
                  child: HeadAvatar(id: 'hero', name: '', size: size),
                ),
                // The floor the head stands on, as a small gold tag above
                // it: the head covers the notch's own number.
                Positioned(
                  key: const Key('tower_ladder_number'),
                  left: 0,
                  right: 0,
                  top: max(0,
                      (towerTop - headFloor) * row + row / 2 - size / 2 - 15),
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: night.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text('${headFloor.round()}',
                            style: label?.copyWith(
                                fontFamily: InkFonts.prose,
                                fontWeight: FontWeight.w800,
                                color: ink.gold,
                                height: 1.2)),
                      ),
                    ),
                  ),
                ),
              ]),
            );
          }),
        ),
      ),
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
