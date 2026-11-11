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
  const TowerLadder({super.key, required this.floor});

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
                    color: ink.gold.withValues(alpha: .7),
                    blurRadius: 9,
                  ),
                ]
              : null,
        ),
        child: here
            ? Text(
                '$n',
                style: label?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ink.gold,
                  height: 1,
                ),
              )
            : isBoss(n)
                ? Text(
                    '$n',
                    style: label?.copyWith(color: Colors.white70, height: 1),
                  )
                : Container(
                    width: w * 0.36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: lit ? ink.gold.withValues(alpha: .85) : dark,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ),
      );
    }

    return SizedBox(
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
                          key: const Key('tower_ladder_here'),
                          child: stone(n),
                        )
                      : stone(n),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
