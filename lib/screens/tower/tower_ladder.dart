// The Tower's ladder (v1.847+, the-tower-designs.md direction B's idea kept
// inside A's look): 30 floors from the bottom (1) to the top (30), the floors
// climbed filled in gold, the floor the party stands on lit with its number,
// the wardens (5, 15, 25) wider and the bosses (10, 20, 30) widest, with
// their number beside them.
import 'package:flutter/material.dart';

import '../../data/tower/tower_tables.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.labelSmall;
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
                      ? Container(
                          key: const Key('tower_ladder_here'),
                          width: towerLadderWidth - 4,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ink.gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text('$n',
                              style: label?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.surface,
                                  height: 1)),
                        )
                      : Container(
                          width: isBoss(n)
                              ? towerLadderWidth - 4
                              : isWarden(n)
                                  ? 26
                                  : 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: n < floor
                                ? ink.gold.withValues(alpha: .55)
                                : ink.seam.withValues(alpha: .55),
                            border: isBoss(n)
                                ? Border.all(color: ink.blood, width: 1.2)
                                : null,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: isBoss(n)
                              ? Text('$n',
                                  style: label?.copyWith(
                                      color: scheme.onSurface, height: 1))
                              : null,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
